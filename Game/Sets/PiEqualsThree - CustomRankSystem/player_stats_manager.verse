#   * * * * * * * * * * * * * * * * * * * * * * * * *
#   * Script by: PiEqualsThree                      *
#   * Published on 17/04/2024                       *
#   * https://www.youtube.com/@piequalsthree3       *
#   * https://twitter.com/PiEqualsThreeVP           *
#   *                                               *    
#   *                                               *
#   * * * * * * * * * * * * * * * * * * * * * * * * *
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }


var PlayerStatsMap : weak_map(player, player_stats) = map{}
# A Verse-authored creative device that can be placed in a level
player_stats_manager := class(creative_device):

    Init(Players : []player) : void =
        for ( Player : Players):
            InitializePlayersStats(Player)

    InitializePlayersStats(Player : player) : void =
        if ( PlayerStatsMap[Player]):
            Print("Stast already exist for this player!")
        else:
            if ( set PlayerStatsMap[Player] = player_stats{}):
                Print("created new stast!")
            
    GetPlayerStats(Player : player) : player_stats =
        PlayerStatsMap[Player] or player_stats{}

    UpdateStats(Player : player, NewEliminations : int, NewPoints : int, NewRank : int) : player_stats =
        UpdatedStats := UpdatePlayerStats(NewEliminations, NewPoints, NewRank)
        if ( set PlayerStatsMap[Player] = UpdatedStats):
            Print("Updated player stats!")
            Print("Eliminations: {UpdatedStats.Eliminations}")
            Print("Points: {UpdatedStats.Points}")
            Print("Rank: {UpdatedStats.Rank}")
        return UpdatedStats

UpdatePlayerStats<constructor>(Eliminations : int, Points : int, Rank : int) := player_stats:
    Eliminations := Eliminations
    Points := Points
    Rank := Rank

player_stats := class<persistable><final>:
    Eliminations : int = 0
    Points : int = 0
    Rank : int = 0
