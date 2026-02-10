"""
Helper script to check if environment variables are properly configured.
Run this before starting the agent to verify your setup.
"""
import os
from pathlib import Path
from dotenv import load_dotenv

print("=" * 60)
print("Environment Configuration Checker")
print("=" * 60)

# Check if .env.local exists
env_file = Path(".env.local")
if env_file.exists():
    print(f"[OK] Found .env.local file at: {env_file.absolute()}")
else:
    print(f"[ERROR] .env.local file NOT FOUND at: {env_file.absolute()}")
    print(f"  Expected location: {Path.cwd() / '.env.local'}")
    print("\n  Please create .env.local with the following content:")
    print("  OPENAI_API_KEY=sk-your-api-key-here")
    print("  LIVEKIT_URL=wss://your-livekit-url")
    print("  LIVEKIT_API_KEY=your-livekit-api-key")
    print("  LIVEKIT_API_SECRET=your-livekit-api-secret")
    exit(1)

# Load environment variables
load_dotenv(".env.local")

# Check OpenAI API Key
openai_key = os.getenv("OPENAI_API_KEY")
if openai_key:
    if openai_key.startswith("sk-"):
        masked_key = f"{openai_key[:7]}{'*' * (len(openai_key) - 10)}{openai_key[-3:]}"
        print(f"[OK] OPENAI_API_KEY is set: {masked_key}")
    else:
        print(f"[ERROR] OPENAI_API_KEY has invalid format (should start with 'sk-')")
        print(f"  Current value starts with: {openai_key[:10]}...")
        exit(1)
else:
    print("[ERROR] OPENAI_API_KEY is NOT SET")
    print("  Add this to your .env.local file:")
    print("  OPENAI_API_KEY=sk-your-api-key-here")
    exit(1)

# Check LiveKit variables (optional but recommended)
livekit_url = os.getenv("LIVEKIT_URL")
livekit_key = os.getenv("LIVEKIT_API_KEY")
livekit_secret = os.getenv("LIVEKIT_API_SECRET")

if livekit_url and livekit_key and livekit_secret:
    print(f"[OK] LIVEKIT_URL is set: {livekit_url}")
    print(f"[OK] LIVEKIT_API_KEY is set: {livekit_key[:10]}...")
    print(f"[OK] LIVEKIT_API_SECRET is set: {'*' * len(livekit_secret)}")
else:
    print("[WARNING] LiveKit variables are not all set (optional for agent, required for server)")

print("\n" + "=" * 60)
print("[SUCCESS] All required environment variables are configured!")
print("=" * 60)
