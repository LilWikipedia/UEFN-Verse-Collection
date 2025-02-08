using { /Fortnite.com/Devices }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation }
event_tag := class(tag){}
event_device := class(creative_device):
    Event<public>:event() = event(){}
    Emit<public>():void=
        Event.Signal()
pub_sub_device := class(creative_device):
    #@editable # alternative to using event_tag:
    #Emits:event_device = event_device{}
    Subscribe(TaggedDevice:event_device)<suspends>:void=
        TaggedDevice.Event.Await()
        spawn{Subscribe(TaggedDevice)} #if retriggerable
        Print("Hello, event")
    OnBegin<override>()<suspends>:void=
        All := GetCreativeObjectsWithTag(event_tag{})
        for (Tagged : All, TaggedDevice := event_device[Tagged]):
            spawn{Subscribe(TaggedDevice)} # subscribe example
            TaggedDevice.Emit()            # publish example