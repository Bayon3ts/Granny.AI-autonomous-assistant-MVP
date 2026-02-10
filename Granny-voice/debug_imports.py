import livekit.agents
import inspect

print("livekit.agents file:", livekit.agents.__file__)
print("Contents of livekit.agents:", dir(livekit.agents))

try:
    from livekit.agents import pipeline
    print("Pipeline module found:", pipeline)
    print("Pipeline contents:", dir(pipeline))
except ImportError as e:
    print("ImportError importing pipeline:", e)

try:
    from livekit.agents import VoicePipelineAgent
    print("VoicePipelineAgent found directly in agents")
except ImportError:
    print("VoicePipelineAgent NOT found directly in agents")
