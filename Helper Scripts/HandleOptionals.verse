# ############################################### #
# #     _     _                         ######### #
# #  \_|_) o | |                           ###### #
# #    |     | |                             #### #
# #   _|   | |/                                 # #
# #  (/\___|_|__/   _                           # #
# #  (_|   |   |_o | | o           | o          # #
# #    |   |   |   | |     _  _  __|    __,     # #
# #    |   |   | | |/_)| |/ \|/ /  | | /  |     # #
# #     \_/ \_/  |_| \_|_|__/|__\_/|_|_\_/|_/   # #
# ####                  /|                    ### #                 
# ####################  \|  ##################### #

# How to handle using an optional

# The following is an example of using an option type to 
# save a reference to a spawned player and, when a player 
# is spawned, to have the trigger device react.

# https://dev.epicgames.com/documentation/en-us/uefn/option-in-verse

my_device := class<concrete>(creative_device):
    var SavedPlayer : ?player = false # unset optional value
 
    @editable
    PlayerSpawn : player_spawner_device = player_spawner_device{}
 
    @editable
    Trigger : trigger_device = trigger_device{}
 
    OnBegin<override>() : void =
        PlayerSpawn.PlayerSpawnedEvent.Subscribe(OnPlayerSpawned)
 
    OnPlayerSpawned(Player : player) : void =
        set SavedPlayer = option{Player} # use
        if (TriggerPlayer := SavedPlayer?): 
            Trigger.Trigger(TriggerPlayer)