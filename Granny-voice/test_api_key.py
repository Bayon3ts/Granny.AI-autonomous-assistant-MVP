import os
from dotenv import load_dotenv
import openai

load_dotenv(".env.local")

client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

try:
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": "Say hello!"}],
        max_tokens=10
    )
    print("✅ API key is valid!")
    print(f"Response: {response.choices[0].message.content}")
except Exception as e:
    print(f"❌ API key error: {e}")