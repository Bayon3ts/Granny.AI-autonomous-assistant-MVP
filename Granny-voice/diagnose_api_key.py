"""
OpenAI API Key Tester
=====================
Tests if your OpenAI API key is valid and working.
"""

import os
from dotenv import load_dotenv

# Force reload .env.local with override
print("🔄 Loading .env.local...")
load_dotenv(".env.local", override=True)

api_key = os.getenv("OPENAI_API_KEY")

print("=" * 60)
print("🔑 OPENAI API KEY CHECK")
print("=" * 60)

if not api_key:
    print("❌ No API key found!")
    print("   Make sure OPENAI_API_KEY is set in .env.local")
    exit(1)

print(f"✅ API key loaded")
print(f"   Length: {len(api_key)} characters")
print(f"   Starts with: {api_key[:7]}...")
print(f"   Ends with: ...{api_key[-4:]}")

# Check if it's the old problematic key
if api_key.endswith("It8A"):
    print("\n⚠️  WARNING: This looks like the OLD/INVALID key!")
    print("   You need to update .env.local with a NEW key from OpenAI")
    print("   Then restart your terminal/IDE and try again")
    exit(1)

print("\n🧪 Testing API key with OpenAI...")

try:
    import openai
    
    client = openai.OpenAI(api_key=api_key)
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": "Say hello!"}],
        max_tokens=10
    )
    
    print("=" * 60)
    print("✅ SUCCESS! API key is valid and working!")
    print("=" * 60)
    print(f"Response: {response.choices[0].message.content}")
    print("\n🎉 You're ready to run your agent!")
    
except openai.AuthenticationError as e:
    print("=" * 60)
    print("❌ AUTHENTICATION FAILED")
    print("=" * 60)
    print(f"Error: {e}")
    print("\n🔧 This means your API key is INVALID")
    print("\nSteps to fix:")
    print("1. Go to: https://platform.openai.com/account/api-keys")
    print("2. Create a NEW API key")
    print("3. Copy it")
    print("4. Update .env.local with: OPENAI_API_KEY=sk-proj-your-new-key")
    print("5. Restart your terminal/IDE")
    print("6. Run this test again")
    exit(1)
    
except Exception as e:
    print("=" * 60)
    print("❌ ERROR")
    print("=" * 60)
    print(f"Error: {e}")
    exit(1)