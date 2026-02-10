# 🚀 Granny AI - Quick Reference

## Start the System

```bash
# Terminal 1: Agent
cd c:\Users\Bayonet\StudioProjects\granny_autonoumus\Granny-voice
uv run agent.py dev

# Terminal 2: Server
cd c:\Users\Bayonet\StudioProjects\granny_autonoumus\Granny-voice
uv run server.py

# Terminal 3: Flutter
cd c:\Users\Bayonet\StudioProjects\granny_autonoumus
flutter run
```

## Required API Keys

Add to `.env.local`:

```bash
# Get at: https://console.deepgram.com/
DEEPGRAM_API_KEY="your_key_here"

# Get at: https://elevenlabs.io/
ELEVENLABS_API_KEY="your_key_here"
```

## Architecture Flow

```
Mic → LiveKit → VAD → Deepgram STT → OpenAI LLM → ElevenLabs TTS → Speaker
      (WebRTC)  (Silero) (Streaming)   (Streaming)   (Streaming)
```

## Latency: ~400-600ms

## Files Created

- `agent.py` - Main voice agent
- `server.py` - Token generation server
- `pyproject.toml` - Dependencies
- `.env.local` - API keys (updated)
- `README.md` - Full documentation
- `INSTALL.md` - Installation guide
- `EXPLANATION.md` - Technical deep-dive
- `quickstart.ps1` - Automation script

## Success Checklist

- [ ] Get Deepgram API key
- [ ] Get ElevenLabs API key
- [ ] Add keys to `.env.local`
- [ ] Run `uv sync`
- [ ] Start agent: `uv run agent.py dev`
- [ ] Start server: `uv run server.py`
- [ ] Update Flutter endpoint to `http://10.0.2.2:8000/session`
- [ ] Test: Speak → See transcript → Hear response

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Agent won't start | Run `uv sync` |
| Missing API key error | Check `.env.local` |
| No audio | Check mic permissions |
| 401 Unauthorized | Verify API keys |
| Connection timeout | Check internet |

## Customization

**Change voice** (agent.py line 37):
```python
voice="Rachel"  # Try: "Bella", "Charlotte", "Sarah"
```

**Change language** (agent.py line 32):
```python
language="en-US"  # Try: "es", "fr", "de"
```

**Adjust personality** (agent.py line 47):
```python
content="""You are Granny..."""
```

## Free Tier Limits

- Deepgram: 45,000 min/month
- ElevenLabs: 10,000 chars/month
- OpenAI: Pay-per-use (~$0.01/conversation)

## Documentation

- Quick Start: `README.md`
- Installation: `INSTALL.md`
- Technical: `EXPLANATION.md`
- This Guide: `QUICKREF.md`

## Support

Check agent logs for errors:
```bash
uv run agent.py dev
# Look for 🚀 ✅ 👤 🎙️ ✨ emojis
```

Test token generation:
```bash
curl http://localhost:8000/session
```

## Next Steps

1. Get API keys (Deepgram + ElevenLabs)
2. Add to `.env.local`
3. Start agent and server
4. Test with Flutter app
5. Enjoy real-time conversations!
