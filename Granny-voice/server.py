import os
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from livekit import api
from dotenv import load_dotenv

load_dotenv(".env.local")

app = FastAPI()

# Enable CORS for local Flutter dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/session")
async def get_session():
    # 1. Get keys
    url = os.getenv("LIVEKIT_URL")
    api_key = os.getenv("LIVEKIT_API_KEY")
    api_secret = os.getenv("LIVEKIT_API_SECRET")

    if not url or not api_key or not api_secret:
        return {"error": "Missing environment variables"}

    # 2. Create room name (unique per user or session?)
    # For prototype, we can use a hardcoded room or generate one.
    room_name = "granny-room-1"
    
    # 3. Create Token for the USER (Flutter)
    participant_identity = f"user-{os.urandom(4).hex()}"
    participant_name = "Bayo"

    token = api.AccessToken(api_key, api_secret) \
        .with_identity(participant_identity) \
        .with_name(participant_name) \
        .with_grants(api.VideoGrants(
            room_join=True,
            room=room_name,
            can_publish=True,
            can_subscribe=True,
        ))

    return {
        "room": room_name,
        "token": token.to_jwt(),
        "url": url,
        "details": "Granny Voice Agent Ready"
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
