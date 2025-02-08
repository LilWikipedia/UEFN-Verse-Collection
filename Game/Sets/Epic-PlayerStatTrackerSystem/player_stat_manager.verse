using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

    # Represents an abstract stat to update using RecordPlayerStat.
    # The class has the unique specifier to make instances of the class comparable.
    # The class has the computes specifier to be able to instantiate it at module-scope.
    # The class has the abstract specifier so it cannot be instantiated directly, and
    # requires subclasses to implement any non-initialized functions, like DebugString().
stat_type := class<computes><unique><abstract>:
    DebugString():string

    # This example uses instances of stat_type subclasses instead of the enum type
    # so you can add more stat_types after the initial published version of the project.    
StatType := module:

    score_stat<public> := class<computes><unique>(stat_type):
        DebugString<override>():string = "Score"

    win_stat<public> := class<computes><unique>(stat_type):
        DebugString<override>():string = "Win"

    loss_stat<public> := class<computes><unique>(stat_type):
        DebugString<override>():string = "Loss"

    # Instances of each stat_type you can use in your experience
    Score<public>:score_stat = score_stat{}
    Win<public>:win_stat = win_stat{}
    Loss<public>:loss_stat = loss_stat{}

    # Manages and updates player_stat_tables for each player.
player_stats_manager := class():

        # Return the player_stats_table for the provided Agent.
        GetPlayerStats(Agent:agent)<decides><transacts>:player_stats_table=
            var PlayerStats:player_stats_table = player_stats_table{}
            if:
                Player := player[Agent]
                PlayerStatsTable := PlayerStatsMap[Player]
                set PlayerStats = MakePlayerStatsTable(PlayerStatsTable)
            PlayerStats

        # Initialize stats for all current players.
        InitializeAllPlayers(Players:[]player):void =
            for (Player : Players):
                InitializePlayer(Player)

        # Initialize stats for the given player.
        InitializePlayer(Player:player):void=
            if:
                not PlayerStatsMap[Player]
                set PlayerStatsMap[Player] = player_stats_table{}

        # Update the given stat for the given player by creating a new
        # player_stats_table and setting it in the PlayerStatsMap.
        RecordPlayerStat(Agent:agent, Stat:stat_type, ?Wins:int = 0):void=
            if:
                Player := player[Agent]
                PlayerStatsTable := PlayerStatsMap[Player]
                if(Stat = StatType.Score):
                    WinStat := PlayerStatsTable.Wins

                    # Create a new player_stats_table with the updated score,
                    # then set that table in the PlayerStatsMap.
                    set PlayerStatsMap[Player] = player_stats_table:
                        MakePlayerStatsTable<constructor>(PlayerStatsTable)
                        Wins := MakeUpdatedPlayerStat(WinStat, Wins)

                else if(Stat = StatType.Win):
                    WinsStat := PlayerStatsTable.Wins

                    # Create a new player_stats_table with the updated wins,
                    # then set that table in the PlayerStatsMap.
                    set PlayerStatsMap[Player] = player_stats_table:
                        MakePlayerStatsTable<constructor>(PlayerStatsTable)
                        Wins := MakeUpdatedPlayerStat(WinsStat, WinsStat.CurrentValue+1)

                else if(Stat = StatType.Loss):
                    LossesStat := PlayerStatsTable.Losses

                    # Create a new player_stats_table with the updated losses,
                    # then set that table in the PlayerStatsMap.
                    set PlayerStatsMap[Player] = player_stats_table:
                        MakePlayerStatsTable<constructor>(PlayerStatsTable)
                        Losses := MakeUpdatedPlayerStat(LossesStat, LossesStat.CurrentValue+1)