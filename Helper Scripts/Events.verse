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