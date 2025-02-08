
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation/Tags }

# Derive from the `tag` class in the Verse.org/Simulation/Tags module to create a new gameplay tag.
enemySpawnerTag := class(tag){}

# A Verse-authored creative device that can be placed in a level
enemy_wave_spawner := class(creative_device):

    ## Use a button device to start the game
    @editable
    ButtonDevice : button_device = button_device{}

    ## List is populated by tagged objects
    var CreatureSpawners : []creature_placer_device = array{}

    ## Used for tracking kills
    @editable
    ElimMGR :elimination_manager_device = elimination_manager_device{}

    ## --- Game Logic
    _gameActive : logic = false

    var totalEnemiesKilled : int = 0
    var roundEnemiesKilled : int = 0

    var currentWave : int = 0

    var waveKilledGoal : int = 10

    ## ------

    OnBegin<override>()<suspends>:void=
        Sleep(0.0)
        Setup()

    ## Do Game Setup.
    # Reset variables to 0, find tagged objects, listen to Managers
    Setup(): void=
        set roundEnemiesKilled = 0
        set totalEnemiesKilled = 0

        # Listen to button event
        ButtonDevice.InteractedWithEvent.Subscribe(OnButtonInteractedWith)
        # Setup Managers
        ManagerSetup()
    
    # Call to start the game
    Start(): void=
        SpawnWave()
    
    # Called when linked button device is pressed
    OnButtonInteractedWith(InPlayer:agent): void=
        Start()

    ## Starts a new wave.
    # Set Current wave, find target number of mobs to spawn
    SpawnWave(): void=
        # Get ALL of our creature spawners
        GetCreatureSpawners()

        set currentWave = currentWave + 1
        Print("Wave {currentWave} starting!")

        set roundEnemiesKilled = 0

        set waveKilledGoal = waveKilledGoal * 2

        ClearCreatures()
        # Loop from 0 -> our kill goal
        for (x := 0..waveKilledGoal):
            # Get random int to retrieve a "random" one of our spawners
            var i : int := GetRandomInt(0, CreatureSpawners.Length)
            #Retrieve that spawner from our list
            if (spwnr := CreatureSpawners[i]):
                #Spawn from that spawner
                spwnr.Spawn()
                
                #remove spawner from list to make sure we don't try to spawn at the same spawner twice.
                if (TempArray := CreatureSpawners.RemoveElement[i]):
                    set CreatureSpawners = TempArray
    
    #Despawn all creatures
    ClearCreatures():void=
        for (spwnr : CreatureSpawners):
            spwnr.Despawn()

    # Subscribe to fiend eliminated event
    ManagerSetup():void=
        ElimMGR.EliminatedEvent.Subscribe(OnFiendKilled)

    # Searches for our tagged items and assigns them to our CreatureSpawners List
    GetCreatureSpawners(): void=
        # Clear the existing array of spawners
        set CreatureSpawners = array{}

        FoundItems := GetCreativeObjectsWithTag(enemySpawnerTag{})

        for (found : FoundItems):
            if (spwner := creature_placer_device[found]):
                set CreatureSpawners = CreatureSpawners + array{spwner}

        Print("Total Creature Spawners: {CreatureSpawners.Length}")

    # Called when a fiend is killed.
    OnFiendKilled(inAgent:agent):void=
        # increment total enemies and round enemies
        set totalEnemiesKilled = totalEnemiesKilled + 1
        set roundEnemiesKilled = roundEnemiesKilled + 1

        Print("{totalEnemiesKilled} Total Fiends Killed!")
        Print("{waveKilledGoal - roundEnemiesKilled} Until the next round!")

        #Check if we've reached our round goal, spawn next wave if so
        if (roundEnemiesKilled = waveKilledGoal):
            SpawnWave()