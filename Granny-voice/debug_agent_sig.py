from livekit.agents import voice
import inspect

agent_cls = voice.Agent
print("Agent class:", agent_cls)
print("Init signature:", inspect.signature(agent_cls.__init__))
