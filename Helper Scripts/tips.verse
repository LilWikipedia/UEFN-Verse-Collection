
######################################################################################################################
######################################################################################################################
######################################################################################################################
<# Optionals: The following is an example of using an option type to save a reference to a spawned player and, when a player is spawned, to have the trigger device react #>


my_device := class<concrete>(creative_device):
    var SavedPlayer : ?player = false # unset optional value
 
    @editable
    PlayerSpawn : player_spawner_device = player_spawner_device{}
 
    @editable
    Trigger : trigger_device = trigger_device{}
 
    OnBegin<override>() : void =
        PlayerSpawn.PlayerSpawnedEvent.Subscribe(OnPlayerSpawned)
 
    OnPlayerSpawned(Player : player) : void =
        set SavedPlayer = option{Player}
        if (TriggerPlayer := SavedPlayer?): 
            Trigger.Trigger(TriggerPlayer)


######################################################################################################################
######################################################################################################################
######################################################################################################################


Get All Fortnite Characters and Call Methods on Them
This snippet shows two functions, `GetFirstFortniteCharacter[]` and `GetAllFortniteCharacters()`, which return a single `fort_character` or all `fort_character`s. The snippet also shows methods that can be called on `fort_character` objects.


using { /Verse.org/Simulation }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/Diagnostics }


fort_character_manager_device := class(creative_device):


    OnBegin<override>()<suspends>:void=
        if (FirstFortniteCharacter:fort_character = GetFirstFortniteCharacter[]):
            FirstFortniteCharacter.Damage(42.0)
            Print("First Character damaged!")
       
        Sleep(3.0)


        AllFortniteCharacters:[]fort_character = GetAllFortniteCharacters()
        for (FortniteCharacter : AllFortniteCharacters):
            FortniteCharacter.Heal(20.0)
            Print("All Characters healed!")
            Sleep(3.0)
            FortniteCharacter.Hide()
            Print("All Characters hidden.")
            Sleep(3.0)
            FortniteCharacter.Show()
            Print("All Characters Shown.")
            Sleep(3.0)
            FortniteCharacter.SetShield(50.0)
            Print("All Characters shield set to 50.0")

    # Get only the first fort_character object on an island
    GetFirstFortniteCharacter()<transacts><decides>:fort_character=
        # Get a reference to the playspace, the container for an entire experience.
        Playspace : fort_playspace = GetPlayspace()
        # Get all players within the playspace.
        AllPlayers : []player = Playspace.GetPlayers()
        # Get the first player in the array of all players.
        # If there's only one player in the experience, this will be that player.
        Player : player = AllPlayers[0]
        # Get the fort_character object associated with the player and return it.
        FortniteCharacter : fort_character = Player.GetFortCharacter[]
        return FortniteCharacter

    # Get an array of all the fort_character objects on an island
    GetAllFortniteCharacters():[]fort_character=
        AllPlayers:[]player = GetPlayspace().GetPlayers()
        for (Player : AllPlayers, Character := Player.GetFortCharacter[]):
            Character


######################################################################################################################
######################################################################################################################
######################################################################################################################


# Error: This invocation calls a function that has the 'decides' effect, which is not allowed by its context.(3512)
# Solution: 
if (NewPosition := SideChestsPositions[Index]):
  # do something with NewPosition
  Print("NewPosition: " + NewPosition);

######################################################################################################################
######################################################################################################################
######################################################################################################################

# Arrays - https://dev.epicgames.com/documentation/en-us/uefn/array-in-verse

# Adding an item to an array
set SideChestsPositions += array{Position};

# Go over an array
for (Index -> Spawner : CreatureSpawners):
  # do something with Spawner
  Spawner.Disable();

for (Spawner : CreatureSpawners):
  Spawner.Disable();

# Get a random element from an array
Index := GetRandomInt(0, CreatureSpawners.Length);

# Remove element form array - https://forums.unrealengine.com/t/how-to-remove-an-item-at-index-from-an-array-in-verse/833744
var MyDeviceArray:[]creative_device = array{}

if (NewArray := MyDeviceArray.RemoveElement[0]):
    set MyDeviceArray = NewArray

######################################################################################################################
######################################################################################################################
######################################################################################################################

# For loop

for (i := 1..BankCoinsIncrement):
  Tracker.Increment(Agent);

######################################################################################################################
######################################################################################################################
######################################################################################################################

# Int with float calculation

NewStoreLevel : int = Int[Score * 1.0 / 20.0];

# Float to Int

if:
  IntTime := Int[Time]

######################################################################################################################
######################################################################################################################
######################################################################################################################

#enum

Value := enum_type.Value1;

######################################################################################################################
######################################################################################################################
######################################################################################################################

# Maps - https://dev.epicgames.com/documentation/en-us/uefn/map-in-verse

# Declaration

WordCount : [string]int = map{"apple" => 0, "apple" => 1, "apple" => 2};
var CanvasMap:[player]canvas = map{};

# Adding an item to a map
set CanvasMap = ConcatenateMaps(CanvasMap, map{Player => Canvas});

# Recall
if (Canvas := CanvasMap[Player]):
  PlayerUI.RemoveWidget(Canvas);

# Removes an element from the given map and returns a new map without that element
RemoveKeyFromMap(ExampleMap:[player]canvas, ElementToRemove:player):[player]canvas=
  var NewMap:[player]canvas = map{}
  # Concatenate Keys from ExampleMap into NewMap, excluding ElementToRemove
  for (Key -> Value : ExampleMap, Key <> ElementToRemove):
      set NewMap = ConcatenateMaps(NewMap, map{Key => Value})
  return NewMap

######################################################################################################################
######################################################################################################################
######################################################################################################################

# Events - https://dev.epicgames.com/documentation/en-us/uefn/verse-api/versedotorg/verse/event/event

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

######################################################################################################################
######################################################################################################################
######################################################################################################################

# HUD

# Display the name of the player in a message
# Source: https://forums.unrealengine.com/t/how-to-get-the-display-name-of-a-player/840455

RewardMessage<localizes>(RoundNum:int):message = "Round #{RoundNum} complete! Get your reward  {playername}!";

######################################################################################################################
######################################################################################################################
######################################################################################################################

# Functions
# Default function parameters ?

# Global / singletons
var GlobalAudioQueue:weak_map(session, audio_queue) = map{}

AudioQueuePlay(Player: agent, AudioPlayer: audio_player_device, Duration: float): void=
  if (AudioQueue := GlobalAudioQueue[GetSession()]):
    AudioQueue.Play(Player, AudioPlayer, Duration)
  else:
    AudioQueue := audio_queue{};
    if (set GlobalAudioQueue[GetSession()] = AudioQueue){}
    AudioQueue.Play(Player, AudioPlayer, Duration)

######################################################################################################################
######################################################################################################################
######################################################################################################################
