from livekit.agents import voice
import inspect

print("voice module:", voice)
print("Contents:", dir(voice))

for name, obj in inspect.getmembers(voice):
    if inspect.isclass(obj):
        print("Class:", name)
