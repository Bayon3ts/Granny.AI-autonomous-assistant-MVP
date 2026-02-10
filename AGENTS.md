# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Granny.AI is a voice-enabled companion app for seniors, consisting of two main components:
- **Flutter mobile app** (`lib/`) - Cross-platform UI targeting Android/iOS with real-time voice interaction
- **Python voice agent** (`Granny-voice/`) - LiveKit-based streaming voice pipeline using Deepgram STT, OpenAI LLM, and ElevenLabs TTS

## Build & Run Commands

### Flutter App
```bash
# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

### Python Voice Agent (from `Granny-voice/` directory)
```bash
# Install dependencies (uses uv package manager)
uv sync

# Start the LiveKit voice agent
uv run agent.py dev

# Start the token server (separate terminal)
uv run server.py

# Run self-test for TTS verification
GRANNY_SELF_TEST=1 uv run agent.py dev

# Force fallback TTS testing
GRANNY_FORCE_FALLBACK=1 uv run agent.py dev
```

## Architecture

### Client-Server Voice Flow
```
Flutter App (VoiceSessionService)
    ↓ HTTP GET /session
Token Server (server.py) → generates LiveKit JWT
    ↓ returns {token, url, room}
Flutter App
    ↓ WebRTC connection via livekit_client
LiveKit Room ("granny-room")
    ↓ audio streams
Python Agent (agent.py)
    ├─ Silero VAD (voice activity detection)
    ├─ Deepgram STT (streaming transcription)
    ├─ OpenAI GPT-4o-mini (LLM responses)
    └─ FallbackTTS: OpenAI TTS → ElevenLabs fallback
    ↓ synthesized audio
Flutter App (plays via RemoteAudioTrack)
```

### Flutter App Structure
- `lib/main.dart` - App entry, checks `onboarding_complete` preference to route to OnboardingScreen or DashboardScreen
- `lib/screens/dashboard_screen.dart` - Main UI with voice orb, connects/disconnects voice sessions via FAB
- `lib/screens/onboarding_screen.dart` - First-run setup collecting user name, DOB, emergency contact
- `lib/services/voice_session_service.dart` - LiveKit room connection, token fetching, audio track handling
- `lib/widgets/glowing_orb.dart` - Animated orb widget indicating listening/speaking state

### Voice Agent Structure
- `Granny-voice/agent.py` - VoicePipelineAgent with FallbackTTS wrapper for resilient TTS (OpenAI primary, ElevenLabs backup)
- `Granny-voice/server.py` - FastAPI server generating LiveKit access tokens at `/session` endpoint

### Key Integration Points
- **Token endpoint**: The Flutter app fetches tokens from the Python server. The endpoint URL is hardcoded in `voice_session_service.dart` (line 8-9). For local development with Android emulator, use `http://10.0.2.2:8000/session`
- **Room name**: Fixed as `"granny-room"` - both agent and server use this
- **Environment variables**: All API keys live in `Granny-voice/.env.local` (LIVEKIT_*, OPENAI_API_KEY, DEEPGRAM_API_KEY, ELEVENLABS_API_KEY)

## Code Conventions

### Flutter
- Uses Google Fonts (Poppins) via `google_fonts` package
- Brand color: `Color(0xFF6D74E4)` (purple/indigo)
- Large touch targets and font sizes for senior accessibility
- State management via StatefulWidget (no external state management library)

### Python Agent
- Comprehensive emoji-prefixed logging (🚀, ✅, ❌, 🎤, etc.)
- FallbackTTS class buffers text stream to allow replay on TTS provider failover
- Event handlers log speech states for debugging (`agent_speech_started`, `user_speech_started`, etc.)

## Testing

### Flutter
```bash
flutter test                           # Run all tests
flutter test test/widget_test.dart     # Run single test file
```

### Voice Agent
```bash
# Verify token generation
curl http://localhost:8000/session

# Verify TTS pipeline
GRANNY_SELF_TEST=1 uv run agent.py dev
```

## Notes for Development
- The voice session stays connected until user explicitly taps "End Call" - don't disconnect in dispose()
- When testing on physical Android device, update the token endpoint URL to your machine's LAN IP
- The agent uses a fixed room name so it auto-joins when participants connect
