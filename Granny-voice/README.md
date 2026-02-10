# Granny AI - Real-Time Voice Agent

Production-ready streaming voice agent using LiveKit, Deepgram STT, OpenAI LLM, and ElevenLabs TTS.

## 🎯 Architecture

```
Flutter Client (Android)
    ↓ WebRTC Audio Stream
LiveKit Room
    ↓
Python Agent (Continuous Loop)
    ├─ Silero VAD (Voice Activity Detection)
    ├─ Deepgram STT (Streaming Speech-to-Text)
    ├─ OpenAI GPT-4 (Streaming LLM)
    └─ ElevenLabs TTS (Streaming Text-to-Speech)
    ↓ WebRTC Audio Stream
Flutter Client (Android)
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd Granny-voice

# Install uv if you don't have it
pip install uv

# Install all dependencies
uv sync
```

### 2. Configure API Keys

Edit `.env.local` and add your API keys:

```bash
# LiveKit (already configured)
LIVEKIT_API_KEY="APIzRc8W6K39pzb"
LIVEKIT_API_SECRET="VF8BNPs5ueApxuqx1CoOOtkL7Fiogf4gA7irE8YK3fuA"
LIVEKIT_URL="wss://granny-loiw83ha.livekit.cloud"

# OpenAI (already configured)
OPENAI_API_KEY="sk-proj-..."

# Deepgram - Get free key at https://console.deepgram.com/
DEEPGRAM_API_KEY="your_deepgram_api_key_here"

# ElevenLabs - Get free key at https://elevenlabs.io/
ELEVENLABS_API_KEY="your_elevenlabs_api_key_here"
```

**Get Free API Keys:**
- **Deepgram**: https://console.deepgram.com/ (45,000 minutes/month free)
- **ElevenLabs**: https://elevenlabs.io/ (10,000 characters/month free)

### 3. Run the Agent

```bash
# Start the LiveKit agent (in one terminal)
uv run agent.py dev

# Start the token server (in another terminal)
uv run server.py
```

You should see:
```
🚀 Granny Agent starting...
✅ Connected to room: ...
🎙️ Voice assistant started and listening...
```

### 4. Test from Flutter

Update the Flutter client endpoint in `lib/services/voice_session_service.dart`:

```dart
// For local testing
static const String _tokenEndpoint = 'http://10.0.2.2:8000/session';  // Android Emulator
// OR
static const String _tokenEndpoint = 'http://YOUR_LOCAL_IP:8000/session';  // Physical device
```

Then run your Flutter app and tap "Start Session".

## 📱 Testing the Full Pipeline

1. **Start Agent**: `uv run agent.py dev`
2. **Start Server**: `uv run server.py`
3. **Launch Flutter App** on Android
4. **Tap "Start Session"**
5. **Speak**: "Hello Granny"
6. **Verify**:
   - ✅ You see partial transcripts as you speak (Deepgram streaming)
   - ✅ Granny responds quickly (OpenAI streaming)
   - ✅ Audio plays smoothly (ElevenLabs streaming)
   - ✅ Session stays connected (continuous loop)
   - ✅ Can have multi-turn conversation without reconnecting

## 🔧 Troubleshooting

### Agent won't start

**Error**: `ModuleNotFoundError: No module named 'livekit'`
```bash
# Reinstall dependencies
uv sync --reinstall
```

**Error**: `Missing API key`
- Check `.env.local` has all required keys
- Ensure no extra quotes or spaces

### Agent connects but no audio

**Check**:
1. Microphone permissions granted in Flutter app
2. Agent logs show "Participant joined"
3. Flutter client successfully fetched token from server

### Deepgram/ElevenLabs errors

**Error**: `401 Unauthorized`
- Verify API keys are correct in `.env.local`
- Check you haven't exceeded free tier limits

**Error**: `Connection timeout`
- Check internet connection
- Verify firewall isn't blocking API requests

### Session disconnects immediately

**Check agent logs**:
```bash
uv run agent.py dev
# Look for error messages
```

**Common causes**:
- Invalid LiveKit credentials
- Token server not running
- Network connectivity issues

## 🎨 Customization

### Change Granny's Voice

Edit `agent.py`:

```python
tts=elevenlabs.TTS(
    model_id="eleven_turbo_v2_5",
    voice="Rachel",  # Try: "Bella", "Charlotte", "Sarah"
),
```

Available voices: https://elevenlabs.io/voice-library

### Adjust Response Speed

Edit `agent.py`:

```python
llm=openai.LLM(
    model="gpt-4o",
    temperature=0.7,  # Lower = more focused, Higher = more creative
),
```

### Change STT Language

Edit `agent.py`:

```python
stt=deepgram.STT(
    model="nova-2-general",
    language="en-US",  # Try: "es", "fr", "de", etc.
),
```

## 📊 Monitoring

### Agent Logs

```bash
uv run agent.py dev
```

Look for:
- `✅ Connected to room` - Agent connected successfully
- `👤 Participant joined` - User connected
- `🎙️ Voice assistant started` - Pipeline running
- `✨ Granny is ready` - Ready for conversation

### Server Logs

```bash
uv run server.py
```

Each token request shows:
```
INFO: 127.0.0.1:xxxxx - "GET /session HTTP/1.1" 200 OK
```

## 🔐 Production Deployment

### Using ngrok (for testing)

```bash
# Terminal 1: Start server
uv run server.py

# Terminal 2: Expose server
ngrok http 8000

# Update Flutter client with ngrok URL
# https://xxxxx.ngrok-free.app/session
```

### Using Cloud Hosting

Deploy `server.py` to:
- **Railway**: https://railway.app/
- **Render**: https://render.com/
- **Fly.io**: https://fly.io/

Update Flutter client with your production URL.

## 📝 API Usage & Costs

### Free Tiers

- **Deepgram**: 45,000 minutes/month (~750 hours)
- **ElevenLabs**: 10,000 characters/month (~5-10 minutes of speech)
- **OpenAI GPT-4**: Pay-per-use (~$0.01 per conversation)

### Monitoring Usage

- **Deepgram**: https://console.deepgram.com/
- **ElevenLabs**: https://elevenlabs.io/usage
- **OpenAI**: https://platform.openai.com/usage

## 🐛 Debug Mode

Enable verbose logging:

```python
# In agent.py, add at top:
import logging
logging.basicConfig(level=logging.DEBUG)
```

## 📚 Documentation

- **LiveKit Agents**: https://docs.livekit.io/agents/
- **Deepgram**: https://developers.deepgram.com/
- **ElevenLabs**: https://elevenlabs.io/docs/
- **OpenAI**: https://platform.openai.com/docs/

## ✅ Success Criteria

Your agent is working correctly when:

1. ✅ Agent starts without errors: `uv run agent.py dev`
2. ✅ Server generates tokens: `curl http://localhost:8000/session`
3. ✅ Flutter app connects to room
4. ✅ You speak and see partial transcripts
5. ✅ Granny responds with audio
6. ✅ Conversation continues for 5+ minutes without disconnects
7. ✅ Agent survives 30+ seconds of silence
8. ✅ Can interrupt Granny mid-sentence

## 🆘 Support

If you encounter issues:

1. Check agent logs for errors
2. Verify all API keys are valid
3. Test each component separately:
   - Token generation: `curl http://localhost:8000/session`
   - Agent startup: `uv run agent.py dev`
4. Check API usage limits haven't been exceeded
5. Ensure network connectivity to all services
