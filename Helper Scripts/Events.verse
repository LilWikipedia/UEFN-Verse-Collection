# Events 
# https://dev.epicgames.com/documentation/en-us/uefn/verse-api/versedotorg/verse/event/event

# Subscribing to an event
EliminationManager.EliminatedEvent.Subscribe(OnCreatureEliminated);

# Declaring an event
CountdownEndedEvent<public> : event() = event(){}
# With parameter
CountdownEndedEvent<public> : event(float) = event(float){}

# Waiting for an event from another object
loop:
    Obj.CountdownEndedEvent.Await();
    Print("Event happened, nw do something and then wait again")

# Triggering the event in the main object
CountdownEndedEvent.Signal();

# Waiting for an event and adding one to a counter
loop:
    EliminationManager.EliminatedEvent().Await();
    set Count += 1;


# Generic class which you can set up to wait on multiple events
# and return the event that does occur and its payload.
# When you instantiate the class, you define the payload type you want.

SharedWaiter:shared_waiter(int) = shared_waiter(int){}

shared_waiter<public>(payload:type) := class(awaitable(payload)):
    # Single custom event to wait and signal on
    SharedEvent<internal>:event(payload) = event(payload){}
        
    # Wait on the custom shared event. Result is the associated payload.
    Await<override>()<suspends>:payload=
        SharedEvent.Await()

    # Add the event to wait on and the payload associated with the event if it occurs
    AddAwaitable<public>(Awaitable:awaitable(t), Payload:payload where t:type):void=
        spawn{AwaitFirstSignal(Awaitable, Payload)}
    
    # Race between the multiple events. First event to occur signals the shared event
    # and cancels the wait for any remaining events that are still waiting to occur.
    AwaitFirstSignal<internal>(Awaitable:awaitable(t), Payload:payload where t:type)<suspends>:void=
        race:
            SharedEvent.Await()
            block:
                Awaitable.Await()
                SharedEvent.Signal(Payload)


# Usage example (when subscribing to an event that returns an agent)
wrapp_event_add_param:=module:

    OnBegin<override>()<suspends>:void=
                    
        ButtonDevice.InteractedWithEvent.SubscribeAgent(OnButtonInteract, "Hello!")
            
    OnButtonInteract(Agent : agent, Text : string) : void =
        Print("Button interacted with {Text}!")
                    

# Usage example (when subscribing to an event that returns tuple(), aka an empty tuple)
    
    OnBegin<override>()<suspends>:void=
        CampfireDevice.CampfirePulseEvent.SubscribeEmpty(OnCampfirePulse, 90210)
            
    OnCampfirePulse(Number : int) : void =
        Print("Campfire pulse had {Number}!")
            

# Wrapper Utilities

(Listenable : listenable(agent)).SubscribeAgent(OutputFunc : tuple(agent, t)->void, ExtraData : t where t:type) : cancelable =
    Wrapper := wrapper_agent(t){ExtraData := ExtraData, OutputFunc := OutputFunc}
    Listenable.Subscribe(Wrapper.InputFunc)

wrapper_agent(t : type) := class():
    ExtraData : t;
    OutputFunc : tuple(agent, t) -> void
    InputFunc(Agent : agent):void = OutputFunc(Agent, ExtraData)

(Listenable : listenable(tuple())).SubscribeEmpty(OutputFunc : t -> void, ExtraData : t where t:type) : cancelable =
    Wrapper := wrapper_empty(t) {ExtraData := ExtraData, OutputFunc := OutputFunc}
    Listenable.Subscribe(Wrapper.InputFunc)

wrapper_empty(t : type) := class():
    ExtraData : t;
    OutputFunc : t -> void
    InputFunc():void = OutputFunc(ExtraData)

