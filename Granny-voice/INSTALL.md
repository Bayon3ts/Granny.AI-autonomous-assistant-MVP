# Installation Instructions

## Prerequisites

- Python 3.10 or higher
- `uv` package manager (recommended) or `pip`

## Step-by-Step Installation

### 1. Install UV (if not already installed)

```bash
# Windows (PowerShell)
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# Or use pip
pip install uv
```

### 2. Navigate to Project Directory

```bash
cd c:\Users\Bayonet\StudioProjects\granny_autonoumus\Granny-voice
```

### 3. Install Dependencies

```bash
# This will create a virtual environment and install all packages
uv sync
```

This installs:
- `livekit-agents` - Core LiveKit agent framework
- `livekit-plugins-deepgram` - Streaming STT
- `livekit-plugins-openai` - Streaming LLM
- `livekit-plugins-elevenlabs` - Streaming TTS
- `livekit-plugins-silero` - Voice Activity Detection
- `python-dotenv` - Environment variable management

### 4. Get API Keys

#### Deepgram (Streaming STT)

1. Go to https://console.deepgram.com/
2. Sign up for free account
3. Navigate to "API Keys"
4. Create new key
5. Copy the key

**Free Tier**: 45,000 minutes/month

#### ElevenLabs (Streaming TTS)

1. Go to https://elevenlabs.io/
2. Sign up for free account
3. Navigate to "Profile" → "API Keys"
4. Copy your API key

**Free Tier**: 10,000 characters/month

### 5. Configure Environment Variables

Edit `.env.local`:

```bash
# Already configured
LIVEKIT_API_KEY="APIzRc8W6K39pzb"
LIVEKIT_API_SECRET="VF8BNPs5ueApxuqx1CoOOtkL7Fiogf4gA7irE8YK3fuA"
LIVEKIT_URL="wss://granny-loiw83ha.livekit.cloud"
OPENAI_API_KEY="sk-proj-..."

# Add these
DEEPGRAM_API_KEY="paste_your_deepgram_key_here"
ELEVENLABS_API_KEY="paste_your_elevenlabs_key_here"
```

### 6. Verify Installation

```bash
# Test agent startup
uv run agent.py dev
```

You should see:
```
🚀 Granny Agent starting...
✅ Connected to room: ...
```

Press `Ctrl+C` to stop.

```bash
# Test token server
uv run server.py
```

You should see:
```
🚀 Starting Granny Voice Token Server...
📡 LiveKit URL: wss://granny-loiw83ha.livekit.cloud
🔗 Server running at: http://localhost:8000
```

### 7. Test Token Generation

In another terminal:

```bash
curl http://localhost:8000/session
```

Should return JSON with `token`, `url`, `room`, and `identity`.

## Running the System

### Terminal 1: Start Agent

```bash
cd c:\Users\Bayonet\StudioProjects\granny_autonoumus\Granny-voice
uv run agent.py dev
```

### Terminal 2: Start Token Server

```bash
cd c:\Users\Bayonet\StudioProjects\granny_autonoumus\Granny-voice
uv run server.py
```

### Terminal 3: Run Flutter App

```bash
cd c:\Users\Bayonet\StudioProjects\granny_autonoumus
flutter run
```

## Troubleshooting Installation

### `uv` command not found

```bash
# Add to PATH or use full path
pip install uv
```

### Dependencies fail to install

```bash
# Clear cache and reinstall
uv cache clean
uv sync --reinstall
```

### Python version error

```bash
# Check Python version
python --version

# Should be 3.10 or higher
# If not, install Python 3.10+ from python.org
```

### Import errors when running

```bash
# Ensure you're using uv run
uv run agent.py dev

# NOT just:
python agent.py  # This won't use the virtual environment
```

## Next Steps

Once installed, see [README.md](README.md) for:
- Testing the full pipeline
- Customization options
- Production deployment
- Troubleshooting guide
