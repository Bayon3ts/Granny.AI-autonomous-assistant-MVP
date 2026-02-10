"""
LiveKit Token Server for Granny AI
Generates access tokens for Flutter clients to connect to LiveKit rooms
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from livekit import api
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv(dotenv_path=".env.local")

app = FastAPI(title="Granny Voice Token Server")

# Enable CORS for Flutter client
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# LiveKit configuration
LIVEKIT_API_KEY = os.getenv("LIVEKIT_API_KEY")
LIVEKIT_API_SECRET = os.getenv("LIVEKIT_API_SECRET")
LIVEKIT_URL = os.getenv("LIVEKIT_URL")

if not all([LIVEKIT_API_KEY, LIVEKIT_API_SECRET, LIVEKIT_URL]):
    raise ValueError("Missing LiveKit credentials in .env.local")


@app.get("/")
async def health_check():
    """Health check endpoint"""
    return {"status": "ok", "service": "granny-voice-token-server"}


@app.get("/session")
async def create_session():
    """
    Generate a LiveKit access token for a new voice session.
    Returns the token and WebSocket URL for the Flutter client.
    """
    try:
        # Use a FIXED room name so the agent knows where to join
        # The agent will automatically join this room when a participant connects
        room_name = "granny-room"  # ✅ Fixed name!
        
        # Generate unique participant identity for each user
        import uuid
        participant_identity = f"user-{uuid.uuid4().hex[:8]}"

        # Create access token with proper permissions
        token = api.AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET)
        token.with_identity(participant_identity)
        token.with_name("Granny User")
        token.with_grants(
            api.VideoGrants(
                room_join=True,
                room=room_name,
                can_publish=True,
                can_subscribe=True,
                can_publish_data=True,
                agent=True,
            )
        )

        # Generate JWT token
        jwt_token = token.to_jwt()

        return {
            "token": jwt_token,
            "url": LIVEKIT_URL,
            "room": room_name,
            "identity": participant_identity,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Token generation failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    
    print("🚀 Starting Granny Voice Token Server...")
    print(f"📡 LiveKit URL: {LIVEKIT_URL}")
    print("🔗 Server running at: http://localhost:8000")
    print("📝 Token endpoint: http://localhost:8000/session")
    print("🏠 Room name: granny-room")
    
    uvicorn.run(app, host="0.0.0.0", port=8000)