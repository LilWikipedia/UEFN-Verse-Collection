using { /Fortnite.com/Devices }
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