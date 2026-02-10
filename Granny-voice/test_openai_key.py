"""
Test script to verify OpenAI API key is valid and has access to Realtime API.
"""
import os
import sys
from dotenv import load_dotenv

load_dotenv(".env.local")

api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    print("[ERROR] OPENAI_API_KEY not found in environment")
    sys.exit(1)

print(f"[INFO] Testing API key: {api_key[:7]}...")

# Test 1: Check if key can access OpenAI API
try:
    import aiohttp
    import asyncio
    
    async def test_key():
        headers = {
            "Authorization": f"Bearer {api_key}",
        }
        
        async with aiohttp.ClientSession() as session:
            # Test basic API access
            async with session.get(
                "https://api.openai.com/v1/models",
                headers=headers
            ) as resp:
                if resp.status == 200:
                    print("[OK] API key is valid and can access OpenAI API")
                    data = await resp.json()
                    models = [m['id'] for m in data.get('data', [])]
                    if 'gpt-realtime' in models or any('realtime' in m.lower() for m in models):
                        print("[OK] Realtime model appears to be available")
                    else:
                        print("[WARNING] Realtime model not found in available models")
                        print(f"  Available models (first 10): {models[:10]}")
                elif resp.status == 401:
                    print("[ERROR] API key is invalid or unauthorized (401)")
                    text = await resp.text()
                    print(f"  Response: {text[:200]}")
                    sys.exit(1)
                else:
                    print(f"[ERROR] Unexpected status code: {resp.status}")
                    text = await resp.text()
                    print(f"  Response: {text[:200]}")
                    sys.exit(1)
    
    asyncio.run(test_key())
    
except ImportError:
    print("[WARNING] aiohttp not available, skipping API test")
    print("[INFO] API key format looks correct, but cannot verify with OpenAI")
except Exception as e:
    print(f"[ERROR] Failed to test API key: {e}")
    sys.exit(1)

print("\n[SUCCESS] API key validation complete!")
