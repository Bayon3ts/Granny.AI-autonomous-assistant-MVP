"""
Granny Voice Agent - LiveKit Agents v1.3.x
==========================================
A hardened voice agent with OpenAI TTS primary and ElevenLabs fallback.

Features:
- Modern v1.x AgentServer and AgentSession architecture
- FallbackTTS with stream buffering for reliable failover
- Comprehensive logging for speech verification
- Self-test mode (GRANNY_SELF_TEST=1)
- Forced fallback testing (GRANNY_FORCE_FALLBACK=1)
"""

import logging
import os
import asyncio
from typing import AsyncIterable, List, Union
from dataclasses import dataclass

from dotenv import load_dotenv
from livekit import agents, rtc
from livekit.agents import (
    Agent,
    AgentServer,
    AgentSession,
    JobContext,
    JobProcess,
    WorkerOptions,
    cli,
    tts,
    llm,
)
from livekit.plugins import openai, deepgram, silero, elevenlabs

load_dotenv(".env.local", override=True)

# =============================================================================
# DEBUG: Verify API key is loaded correctly
# =============================================================================
_openai_key = os.getenv("OPENAI_API_KEY", "")
print("=" * 80)
print("🔍 OPENAI API KEY DEBUG CHECK")
print("=" * 80)
if _openai_key:
    print(f"✅ Key loaded: {_openai_key[:15]}...{_openai_key[-10:]} (length: {len(_openai_key)})")
    print(f"✅ Key starts with: {_openai_key[:8]}")
    print(f"✅ Key ends with: ...{_openai_key[-8:]}")
else:
    print("❌ NO KEY LOADED!")
    raise RuntimeError("OPENAI_API_KEY is not set!")
print("=" * 80)
print()

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("granny-voice")
logger.setLevel(logging.DEBUG)

# =============================================================================
# ENVIRONMENT FLAGS
# =============================================================================
SELF_TEST_MODE = os.getenv("GRANNY_SELF_TEST", "0") == "1"
FORCE_FALLBACK = os.getenv("GRANNY_FORCE_FALLBACK", "0") == "1"


# =============================================================================
# FALLBACK TTS WITH STREAM BUFFERING
# =============================================================================
class FallbackTTS(tts.TTS):
    """
    A TTS wrapper that provides automatic failover from primary to fallback.
    
    Key features:
    - Buffers incoming text stream to allow replay on fallback
    - Comprehensive logging for debugging
    - Tracks audio frame emission for verification
    """
    
    def __init__(
        self, 
        primary_tts: tts.TTS, 
        fallback_tts: tts.TTS,
        force_primary_failure: bool = False
    ):
        super().__init__(
            capabilities=primary_tts.capabilities,
            sample_rate=primary_tts.sample_rate,
            num_channels=primary_tts.num_channels,
        )
        self._primary = primary_tts
        self._fallback = fallback_tts
        self._force_failure = force_primary_failure
        self._audio_frame_count = 0
        self._active_provider = "none"
        
        logger.info(f"FallbackTTS initialized:")
        logger.info(f"  Primary: {type(primary_tts).__module__}.{type(primary_tts).__name__}")
        logger.info(f"  Fallback: {type(fallback_tts).__module__}.{type(fallback_tts).__name__}")
        logger.info(f"  Force fallback mode: {force_primary_failure}")

    def synthesize(self, text: str, **kwargs) -> tts.ChunkedStream:
        """Handle non-streaming synthesis."""
        logger.info(f"[TTS] synthesize() called with text length: {len(text)}")
        return self._synthesize_with_fallback(text, **kwargs)
    
    def _synthesize_with_fallback(self, text: str, **kwargs) -> tts.ChunkedStream:
        """Wrapper for synthesize that handles fallback."""
        if self._force_failure:
            logger.warning("[TTS] Force fallback enabled - using fallback TTS directly")
            self._active_provider = "fallback"
            return self._fallback.synthesize(text, **kwargs)
        
        try:
            self._active_provider = "primary"
            return self._primary.synthesize(text, **kwargs)
        except Exception as e:
            logger.error(f"[TTS] Primary synthesize failed: {e}")
            self._active_provider = "fallback"
            return self._fallback.synthesize(text, **kwargs)

    def stream(self, text: str, **kwargs) -> tts.SynthesizeStream:
        """
        Stream TTS with automatic fallback.
        
        This method returns a SynthesizeStream that handles failover internally.
        """
        logger.info(f"[TTS] stream() called - starting synthesis")
        logger.debug(f"[TTS] Input text preview: {str(text)[:100]}...")
        
        if self._force_failure:
            logger.warning("[TTS] FORCE_FALLBACK enabled - bypassing primary TTS")
            self._active_provider = "fallback"
            return self._create_logged_stream(self._fallback.stream(text, **kwargs), "fallback")
        
        self._active_provider = "primary"
        return FallbackSynthesizeStream(
            primary_tts=self._primary,
            fallback_tts=self._fallback,
            text=text,
            kwargs=kwargs,
        )
    
    def _create_logged_stream(
        self, 
        stream: tts.SynthesizeStream, 
        provider_name: str
    ) -> tts.SynthesizeStream:
        """Wrap a stream with logging."""
        return LoggedSynthesizeStream(stream, provider_name)
    
    @property
    def audio_frame_count(self) -> int:
        """Returns total audio frames emitted (for verification)."""
        return self._audio_frame_count
    
    @property
    def active_provider(self) -> str:
        """Returns which TTS provider is currently active."""
        return self._active_provider


class LoggedSynthesizeStream(tts.SynthesizeStream):
    """A wrapper that logs audio frame emission."""
    
    def __init__(self, inner_stream: tts.SynthesizeStream, provider_name: str):
        self._inner = inner_stream
        self._provider = provider_name
        self._frame_count = 0
    
    async def __anext__(self) -> tts.SynthesizedAudio:
        try:
            audio = await self._inner.__anext__()
            self._frame_count += 1
            if self._frame_count == 1:
                logger.info(f"[TTS:{self._provider}] ✅ First audio frame emitted!")
            if self._frame_count % 50 == 0:
                logger.debug(f"[TTS:{self._provider}] Emitted {self._frame_count} audio frames")
            return audio
        except StopAsyncIteration:
            logger.info(f"[TTS:{self._provider}] Stream complete. Total frames: {self._frame_count}")
            raise
    
    def __aiter__(self):
        return self
    
    def push_text(self, text: str) -> None:
        self._inner.push_text(text)
    
    def mark_segment_end(self) -> None:
        self._inner.mark_segment_end()
    
    async def aclose(self) -> None:
        await self._inner.aclose()


class FallbackSynthesizeStream(tts.SynthesizeStream):
    """
    A SynthesizeStream that attempts primary TTS first, 
    then falls back to secondary on failure.
    
    Buffers pushed text to allow replay on fallback.
    """
    
    def __init__(
        self, 
        primary_tts: tts.TTS, 
        fallback_tts: tts.TTS,
        text: str,
        kwargs: dict = None,
    ):
        self._primary = primary_tts
        self._fallback = fallback_tts
        self._text = text
        self._kwargs = kwargs or {}
        self._text_buffer: List[str] = []
        self._segment_ended = False
        self._current_stream: tts.SynthesizeStream = None
        self._using_fallback = False
        self._frame_count = 0
        self._initialized = False
        self._exhausted = False
    
    def push_text(self, text: str) -> None:
        """Buffer text for potential replay on fallback."""
        self._text_buffer.append(text)
        if self._current_stream:
            self._current_stream.push_text(text)
    
    def mark_segment_end(self) -> None:
        """Mark end of text segment."""
        self._segment_ended = True
        if self._current_stream:
            self._current_stream.mark_segment_end()
    
    async def _initialize_stream(self) -> None:
        """Initialize the primary stream, switch to fallback on error."""
        if self._initialized:
            return
        
        self._initialized = True
        
        try:
            logger.info("[TTS] Initializing primary TTS stream (OpenAI)...")
            self._current_stream = self._primary.stream(self._text, **self._kwargs)
            
            # Replay any buffered text
            for text in self._text_buffer:
                self._current_stream.push_text(text)
            if self._segment_ended:
                self._current_stream.mark_segment_end()
                
            logger.info("[TTS] Primary TTS stream initialized successfully")
            
        except Exception as e:
            logger.error(f"[TTS] Primary TTS initialization failed: {e}")
            await self._switch_to_fallback()
    
    async def _switch_to_fallback(self) -> None:
        """Switch to fallback TTS, replaying buffered text."""
        logger.warning("[TTS] Switching to fallback TTS (ElevenLabs)...")
        self._using_fallback = True
        
        try:
            self._current_stream = self._fallback.stream(self._text, **self._kwargs)
            
            # Replay all buffered text
            for text in self._text_buffer:
                self._current_stream.push_text(text)
            if self._segment_ended:
                self._current_stream.mark_segment_end()
                
            logger.info("[TTS] ✅ Fallback TTS stream initialized successfully")
            
        except Exception as e:
            logger.critical(f"[TTS] ❌ CRITICAL: Fallback TTS also failed: {e}")
            raise RuntimeError(f"Both TTS providers failed. Primary and fallback unavailable.") from e
    
    async def __anext__(self) -> tts.SynthesizedAudio:
        if self._exhausted:
            raise StopAsyncIteration
        
        await self._initialize_stream()
        
        try:
            audio = await self._current_stream.__anext__()
            self._frame_count += 1
            
            provider = "fallback" if self._using_fallback else "primary"
            if self._frame_count == 1:
                logger.info(f"[TTS:{provider}] ✅ First audio frame emitted!")
            if self._frame_count % 50 == 0:
                logger.debug(f"[TTS:{provider}] Emitted {self._frame_count} audio frames")
            
            return audio
            
        except StopAsyncIteration:
            provider = "fallback" if self._using_fallback else "primary"
            logger.info(f"[TTS:{provider}] Stream complete. Total frames: {self._frame_count}")
            self._exhausted = True
            raise
            
        except Exception as e:
            if not self._using_fallback:
                logger.error(f"[TTS] Primary stream error during iteration: {e}")
                await self._switch_to_fallback()
                # Try again with fallback
                return await self.__anext__()
            else:
                logger.critical(f"[TTS] Fallback stream error: {e}")
                raise
    
    def __aiter__(self):
        return self
    
    async def aclose(self) -> None:
        if self._current_stream:
            await self._current_stream.aclose()


# =============================================================================
# STARTUP VALIDATION
# =============================================================================
def _validate_keys() -> dict:
    """
    Defensive startup check for API keys.
    Returns a dict with key availability status.
    """
    openai_key = os.getenv("OPENAI_API_KEY", "").strip()
    elevenlabs_key = (os.getenv("ELEVEN_API_KEY") or os.getenv("ELEVENLABS_API_KEY", "")).strip()
    deepgram_key = os.getenv("DEEPGRAM_API_KEY", "").strip()
    
    status = {
        "openai": bool(openai_key),
        "elevenlabs": bool(elevenlabs_key),
        "deepgram": bool(deepgram_key),
    }
    
    logger.info("=" * 60)
    logger.info("API KEY VALIDATION")
    logger.info("=" * 60)
    
    # Log key details for debugging
    if openai_key:
        logger.info(f"  ✅ OPENAI_API_KEY: present")
        logger.info(f"     → Starts with: {openai_key[:10]}...")
        logger.info(f"     → Length: {len(openai_key)} characters")
        logger.info(f"     → Ends with: ...{openai_key[-10:]}")
    else:
        logger.error(f"  ❌ OPENAI_API_KEY: MISSING")
        
    if elevenlabs_key:
        logger.info(f"  ✅ ELEVENLABS_API_KEY: present")
    else:
        logger.warning(f"  ⚠️  ELEVENLABS_API_KEY: MISSING")
        
    if deepgram_key:
        logger.info(f"  ✅ DEEPGRAM_API_KEY: present")
    else:
        logger.warning(f"  ⚠️  DEEPGRAM_API_KEY: MISSING")
    
    if not status["openai"]:
        logger.error("❌ CRITICAL: OpenAI API key missing - TTS/LLM will fail")
        raise RuntimeError("OPENAI_API_KEY is required but not set!")
    
    if not status["elevenlabs"]:
        logger.warning("⚠️  ElevenLabs API key missing - Fallback TTS unavailable")
    
    logger.info("=" * 60)
    return status


# =============================================================================
# TEST OPENAI CONNECTION
# =============================================================================
async def _test_openai_connection():
    """Test that OpenAI API key actually works."""
    logger.info("=" * 60)
    logger.info("🧪 TESTING OPENAI API CONNECTION")
    logger.info("=" * 60)
    
    try:
        import openai as openai_lib
        client = openai_lib.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        
        logger.info("Sending test request to OpenAI...")
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": "Say 'test successful' and nothing else"}],
            max_tokens=10
        )
        
        result = response.choices[0].message.content
        logger.info(f"✅ OpenAI API TEST PASSED!")
        logger.info(f"   Response: {result}")
        logger.info("=" * 60)
        return True
        
    except Exception as e:
        logger.error(f"❌ OpenAI API TEST FAILED: {e}")
        logger.error("=" * 60)
        raise RuntimeError(f"OpenAI API key is invalid or connection failed: {e}")


# =============================================================================
# SELF-TEST MODE
# =============================================================================
async def run_self_test():
    """
    Minimal self-test to verify TTS pipeline works.
    Activated by GRANNY_SELF_TEST=1 environment variable.
    """
    logger.info("=" * 60)
    logger.info("🧪 GRANNY SELF-TEST MODE")
    logger.info("=" * 60)
    
    # Validate keys
    _validate_keys()
    
    # Test OpenAI connection
    await _test_openai_connection()
    
    # Initialize TTS
    logger.info("Initializing TTS providers...")
    openai_tts = openai.TTS(voice="alloy")
    
    # Handle both ELEVEN_API_KEY and ELEVENLABS_API_KEY
    elevenlabs_key = os.getenv("ELEVEN_API_KEY") or os.getenv("ELEVENLABS_API_KEY")
    if elevenlabs_key:
        eleven_tts = elevenlabs.TTS(api_key=elevenlabs_key)
    else:
        eleven_tts = openai_tts
        logger.warning("No ElevenLabs key - using OpenAI for both primary and fallback")
    
    tts_provider = FallbackTTS(
        primary_tts=openai_tts,
        fallback_tts=eleven_tts,
        force_primary_failure=FORCE_FALLBACK,
    )
    
    # Test synthesis
    test_text = "Hello! This is Granny performing a self-test. Can you hear me?"
    logger.info(f"Testing TTS with: '{test_text}'")
    
    frame_count = 0
    total_bytes = 0
    
    try:
        stream = tts_provider.stream(test_text)
        stream.mark_segment_end()
        
        async for audio in stream:
            frame_count += 1
            if hasattr(audio, 'data'):
                total_bytes += len(audio.data)
            if frame_count == 1:
                logger.info("✅ First audio frame received!")
        
        await stream.aclose()
        
    except Exception as e:
        logger.error(f"❌ Self-test FAILED: {e}")
        return False
    
    logger.info("=" * 60)
    logger.info("📊 SELF-TEST RESULTS")
    logger.info("=" * 60)
    logger.info(f"  Audio frames produced: {frame_count}")
    logger.info(f"  Total audio bytes: {total_bytes}")
    logger.info(f"  Active provider: {tts_provider.active_provider}")
    
    if frame_count > 0:
        logger.info("✅ SELF-TEST PASSED: TTS is working!")
        return True
    else:
        logger.error("❌ SELF-TEST FAILED: No audio frames produced!")
        return False


# =============================================================================
# GRANNY AGENT (v1.x)
# =============================================================================
class GrannyAgent(Agent):
    """
    Granny voice assistant using the new v1.x Agent API.
    
    This agent subclass allows us to use lifecycle hooks and
    customize behavior while leveraging the new architecture.
    """
    
    def __init__(self):
        super().__init__(
            instructions=(
                "You are Granny, a helpful, curious, and friendly voice AI assistant. "
                "You eagerly assist users with their questions. "
                "Your responses are concise, natural, and warm. "
                "Avoid complex formatting, asterisks, or emojis. "
                "Speak as if you're having a natural conversation."
            )
        )
        logger.info("GrannyAgent initialized")
    
    async def on_enter(self):
        """
        Called when the agent enters/starts.
        This is where we send the initial greeting.
        """
        logger.info("[AGENT] on_enter() called - sending greeting")
        await self.session.generate_reply(
            instructions="Greet the user warmly and offer your assistance."
        )


# =============================================================================
# AGENT SERVER SETUP (v1.x)
# =============================================================================
server = AgentServer()


@server.rtc_session()
async def entrypoint(ctx: JobContext):
    """
    Main agent entrypoint for LiveKit v1.x.
    
    Flow:
    1. Validate API keys
    2. Test OpenAI connection
    3. Connect to LiveKit room
    4. Initialize all providers (STT, LLM, TTS, VAD)
    5. Create AgentSession
    6. Start session with GrannyAgent
    """
    logger.info("=" * 60)
    logger.info("🚀 GRANNY VOICE AGENT STARTING (v1.x)")
    logger.info("=" * 60)
    
    # 1. Validation
    _validate_keys()
    
    # 2. Test OpenAI connection
    await _test_openai_connection()
    
    # 3. Connect to Room
    logger.info("Connecting to LiveKit room...")
    await ctx.connect(auto_subscribe=agents.AutoSubscribe.AUDIO_ONLY)
    logger.info(f"✅ Connected to room: {ctx.room.name}")
    
    # 4. Initialize Plugins
    logger.info("Initializing plugins...")
    
    # STT - Deepgram
    stt_provider = deepgram.STT()
    logger.info("  ✅ STT: Deepgram")
    
    # LLM - OpenAI
    llm_provider = openai.LLM(model="gpt-4o-mini")
    logger.info("  ✅ LLM: OpenAI gpt-4o-mini")
    
    # TTS - OpenAI with ElevenLabs fallback
    openai_tts = openai.TTS(voice="alloy")
    
    # ElevenLabs expects ELEVEN_API_KEY, not ELEVENLABS_API_KEY
    # Pass the API key explicitly to handle both naming conventions
    elevenlabs_key = os.getenv("ELEVEN_API_KEY") or os.getenv("ELEVENLABS_API_KEY")
    if elevenlabs_key:
        eleven_tts = elevenlabs.TTS(api_key=elevenlabs_key)
    else:
        # Create a dummy TTS that will fail gracefully if used
        eleven_tts = openai_tts  # Use OpenAI as both primary and fallback
        logger.warning("⚠️  No ElevenLabs API key found - using OpenAI TTS for both primary and fallback")
    
    tts_provider = FallbackTTS(
        primary_tts=openai_tts,
        fallback_tts=eleven_tts,
        force_primary_failure=FORCE_FALLBACK,
    )
    logger.info("  ✅ TTS: OpenAI (primary) + ElevenLabs (fallback)")
    
    # VAD - Silero
    vad_provider = silero.VAD.load()
    logger.info("  ✅ VAD: Silero")
    
    # 5. Create AgentSession (v1.x)
    logger.info("Creating AgentSession...")
    session = AgentSession(
        vad=vad_provider,
        stt=stt_provider,
        llm=llm_provider,
        tts=tts_provider,
    )
    
    # 6. Event handlers for debugging
    @session.on("agent_speech_started")
    def on_speech_started(ev):
        logger.info("[SESSION] 🎤 Agent speech started - TTS is producing audio")
    
    @session.on("agent_speech_committed")
    def on_speech_committed(ev):
        logger.info("[SESSION] 🎤 Agent speech committed")
    
    @session.on("user_speech_started")
    def on_user_speech_started(ev):
        logger.info("[SESSION] 👂 User started speaking")
    
    @session.on("user_speech_committed")
    def on_user_speech_committed(ev):
        transcript = ev.user_transcript if hasattr(ev, 'user_transcript') else "N/A"
        logger.info(f"[SESSION] 👂 User speech committed: {transcript}")
    
    @session.on("agent_state_changed")
    def on_state_changed(ev):
        # AgentStateChangedEvent doesn't have a 'state' attribute in v1.x
        logger.info(f"[SESSION] 🔄 Agent state changed")
    
    # 7. Start the session with GrannyAgent
    logger.info("Starting session with GrannyAgent...")
    await session.start(
        room=ctx.room,
        agent=GrannyAgent(),
    )
    logger.info("✅ Session started")
    
    # Keep session running
    logger.info("=" * 60)
    logger.info("🟢 GRANNY IS LIVE AND LISTENING")
    logger.info("=" * 60)


# =============================================================================
# MAIN
# =============================================================================
if __name__ == "__main__":
    if SELF_TEST_MODE:
        # Run self-test instead of full agent
        success = asyncio.run(run_self_test())
        exit(0 if success else 1)
    else:
        # Normal agent startup using v1.x API
        cli.run_app(server)