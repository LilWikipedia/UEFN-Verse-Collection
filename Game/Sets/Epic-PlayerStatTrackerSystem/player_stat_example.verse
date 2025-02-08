using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/FortPlayerUtilities }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }


player_stats_example := class(creative_device):

    @editable
    ScorePointsButton:button_device = button_device{}
    # Displays the player's Score, High Score, Wins, and Losses
    @editable
    StatsBillboard:billboard_device = billboard_device{}
    # Resets the player's score and award them a win or a loss
    # depending if their current score is greater than WinScore.
    @editable
    CheckWinButton:button_device = button_device{}
    # The score players need to reach to be awarded a win after
    # the CheckWinButton is activated.
    @editable
    WinScore:int = 10
    # Manages and updates stats for each player.
    PlayerStatsManager:player_stats_manager = player_stats_manager{}
    # Displays a player's stats on a billboard.
    StatsMessage<localizes>(Wins:int, Losses:int):message = "Stats:\n  Wins: {Wins}\n  Losses: {Losses}"

    # Retrieves the stats of the given player and displays their stats
    # on the StatsBillboard.
    UpdateStatsBillboard(Agent:agent):void=
        if:
            # Get the current stats of the given agent.
            CurrentPlayerStats := PlayerStatsManager.GetPlayerStats[Agent]
        then:
            StatsBillboard.SetText(
                StatsMessage(
                    Wins:=CurrentPlayerStats.Wins.CurrentValue,
                    Losses:=CurrentPlayerStats.Losses.CurrentValue
                )
            )

    # Adds to the given player's score and updates both their stats table
    # in PlayerStatsManager and the billboard in the level.
    AddScore(Agent:agent):void=
        if:
            CurrentPlayerStats := PlayerStatsManager.GetPlayerStats[Agent]
            CurrentScore := CurrentPlayerStats.Wins.CurrentValue
        then:
            PlayerStatsManager.RecordPlayerStat(Agent, StatType.Win, ?Wins := CurrentScore + 1)
            UpdateStatsBillboard(Agent)

            # Awards a player a win or a loss when they interact
            # with the CheckWinButton.
    CheckWin(Agent:agent):void=
        if:
            PlayerStats := PlayerStatsManager.GetPlayerStats[Agent]
            CurrentScore := PlayerStats.Wins.CurrentValue
            CurrentScore > WinScore
        then:
            PlayerStatsManager.RecordPlayerStat(Agent, StatType.Win)
        else:
            PlayerStatsManager.RecordPlayerStat(Agent, StatType.Loss)

        # Reset the player's score by recording their score stat as 0.
        PlayerStatsManager.RecordPlayerStat(Agent, StatType.Win, ?Wins := 0)
        UpdateStatsBillboard(Agent)

        
    OnBegin<override>()<suspends>:void=
        # Register Button Events
        ScorePointsButton.InteractedWithEvent.Subscribe(AddScore)
        CheckWinButton.InteractedWithEvent.Subscribe(CheckWin)
        Players := GetPlayspace().GetPlayers()

        # Initialize player stats
        PlayerStatsManager.InitializeAllPlayers(Players)