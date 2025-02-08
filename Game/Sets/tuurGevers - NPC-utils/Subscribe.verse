using { /Verse.org/Concurrency }
using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Assets }
using { /Fortnite.com/Devices/CreativeAnimation }

custom_cancelable<public> := class:
    var Canceled : logic = false

    CancelEvent : event() = event(){}

    Cancel():void=
        set Canceled = true
        CancelEvent.Signal()

custom_subscribable<public>(t:type)<computes> := class<public>(awaitable(t)):

    InnerEvent : event(t) = event(t){}

    Subscribe(Callback:type {__(:t):void}):custom_cancelable=
        Cancelable := custom_cancelable{}
        spawn{_WaitForEvent(Callback, Cancelable)}

        Cancelable

    _WaitForEvent(Callback:type {__(:t):void}, Cancelable: custom_cancelable)<suspends>:void=
        race:
            # Wait for payload to be sent
            loop:
                Payload := InnerEvent.Await()

                # Just in case
                if(not Cancelable.Canceled?):
                    Callback(Payload)
                else:
                    break # Just in case

            # Cancelable got canceled
            Cancelable.CancelEvent.Await()

    
    Signal<public>(Payload:t):void =
        InnerEvent.Signal(Payload)

    Await<override>()<suspends>:t=
        InnerEvent.Await()

CustomSubscribe := class:
    var TrackedProps: []creative_prop =array{}
    var Trigger:logic =false

    Subscribe(Prop:creative_prop):void=
        set TrackedProps += array{Prop}

    Cancel():void=
        set Trigger = true

    StartUpdate(TrackingProp:creative_prop)<suspends>:void=
        loop:
            Sleep(0.1)
            if(TrackingProp.GetTransform().Scale.Z=2.0):
                for(Prop:TrackedProps):
                    Prop.Dispose()
            if(Trigger = true):
                break

Test()<suspends>:void=
    Prop1 := creative_prop{}
    Prop2 := creative_prop{}
    Prop3 := creative_prop{}

    Sub := CustomSubscribe{}
    Sub.Subscribe(Prop1)
    Sub.Subscribe(Prop2)
    Sub.Subscribe(Prop3)

    spawn{Sub.StartUpdate(Prop1)}

    Sleep(1.0)
    Sub.Cancel()   
    
