#   * * * * * * * * * * * * * * * * * * * * * * * * *
#   * Script by: PiEqualsThree                      *
#   * Published on 17/04/2024                       *
#   * https://www.youtube.com/@piequalsthree3       *
#   * https://twitter.com/PiEqualsThreeVP           *
#   *                                               *    
#   *                                               *
#   * * * * * * * * * * * * * * * * * * * * * * * * *

using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }


rank_manager := class(creative_device):
    
    @editable       PlayerStatsManager : player_stats_manager = player_stats_manager{}
    @editable       UIManager : user_interface_manager = user_interface_manager{}
    @editable       Settings : rank_settings = rank_settings{}

    Init(Players : []player) : void =
        for ( Player : Players):
            InitializePlayerRank(Player)

    InitializePlayerRank(Player : player) : void =
        UIManager.InitRankUI(Player, PlayerStatsManager.GetPlayerStats(Player), Settings)

    HandleElimination(ElimResult : elimination_result) : void =
        EliminatedCharacter := ElimResult.EliminatedCharacter
        MaybeEliminatingCharacter := ElimResult.EliminatingCharacter
        # Player who was eliminated
        if ( Player := player[EliminatedCharacter.GetAgent[]]):
            UpdateEliminatedPlayerStats(Player)

        # Player who eliminated someone
        if:
            EliminatingCharacter := MaybeEliminatingCharacter?
            EliminatingCharacter <> EliminatedCharacter
            Agent := EliminatingCharacter.GetAgent[]
            Player := player[Agent]
        then:
            UpdateEliminatingPlayerStats(Player)


    UpdateEliminatingPlayerStats(Player : player) : void =
        PlayerStats := PlayerStatsManager.GetPlayerStats(Player)
        NewEliminations := PlayerStats.Eliminations + 1
        NewPoints := PlayerStats.Points + 1
        NewRank := CalculatePlayerRankUp(PlayerStats, NewPoints)
        NewStats := PlayerStatsManager.UpdateStats(Player, NewEliminations, NewPoints, NewRank)
        if ( NewStats.Rank <> PlayerStats.Rank):
            UIManager.UpdateRank(Player, NewStats, Settings)
        else:
            UIManager.UpdateProgress(Player, NewStats, Settings)


    UpdateEliminatedPlayerStats(Player : player) : void = 
        PlayerStats := PlayerStatsManager.GetPlayerStats(Player)
        NewPoints := PlayerStats.Points - 1 >= 0 and PlayerStats.Points - 1 or 0
        NewEliminations := PlayerStats.Eliminations
        NewRank := CalculatePlayerRankDown(PlayerStats, NewPoints)
        NewStats := PlayerStatsManager.UpdateStats(Player, NewEliminations, NewPoints, NewRank)
        if ( NewStats.Rank <> PlayerStats.Rank):
            UIManager.UpdateRank(Player, NewStats, Settings)
        else:
            UIManager.UpdateProgress(Player, NewStats, Settings)
            
    CalculatePlayerRankUp(OldStats : player_stats, NewPoints : int) : int =
        CurrentRankIndex := OldStats.Rank
        if ( NextRank := Settings.Ranks[CurrentRankIndex + 1]):
            if ( NewPoints >= NextRank.PointsNeeded):
                Print("Ranked up!")
                return CurrentRankIndex + 1

        return CurrentRankIndex

    CalculatePlayerRankDown(OldStats : player_stats, NewPoints : int) : int =
        CurrentRankIndex := OldStats.Rank 
        if ( CurrentRank := Settings.Ranks[CurrentRankIndex]):
            if ( NewPoints < CurrentRank.PointsNeeded):
                return CurrentRankIndex - 1
        CurrentRankIndex
        




    

rank := class<concrete>:
    @editable       Name : string = "Rank"
    @editable       PointsNeeded : int = 0
    @editable       ForegroundColor : color = color{}
    @editable       BackgroundColor : color = color{}
    @editable       ImageSize : vector2 = vector2{X := 80.0, Y := 70.0}

using { MyTextures.Ranks}
rank_settings := class<concrete>:
    @editable       Ranks : []rank = array{}
    Images : []texture = array:
        Unranked
        Bronze
        Silver
        Gold
        Champion
