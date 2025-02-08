using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

ffa_shuffle_teams_device := class(creative_device):
    @editable
    Button:button_device = button_device{}

    # Selects a new team for every existing player.
    # Each player will be assigned to another team different from their original one.
    # This is meant to be used in a Free For All game.
    ShuffleTeams<public>():void= 
        TeamCollection := GetPlayspace().GetTeamCollection()
        Players := GetPlayspace().GetPlayers()

        # The algorithm starts by shuffling the teams in random order.
        # Teams is a variable because we'll remove a team each time we assign a player to it.
        # There's one player per team in a FFA, so once a player is assigned a team, the team isn't 
        # available anymore.
        var Teams:[]team = Shuffle(TeamCollection.GetTeams())
        
        # For each Player, we try to find a new team.
        # We save the Player's Team so we can check against any new potential team.
        for (Index -> Player:Players, Team := TeamCollection.GetTeam[Player]):
            # Since the teams are in random order. We can just pick the first team that doesn't match the current Player's team (Team).
            var FoundTeam:?team = false # FoundTeam is used to save the first team found.

            # Iterate all remaining teams.
            # We save the first team that's different from the Player's Team and stop further iterations.
            # Further iterations don't execute because we check if we haven't found a team yet.
            # FoundTeam? fails when no team has been found yet (option = false). not fail = succeed -> Yes, iterate.
            # Once FoundTeam contains a valid team, FoundTeam? succeeds -> not success = fail -> No, don't iterate. 
            for (TeamIndex -> TestTeam:Teams, Team <> TestTeam, not FoundTeam?):
                set FoundTeam = option{TestTeam} # Found a team, save it.
            
            # Now we can try and add the Player to the team we've found. 
            if:
                NewTeam := FoundTeam?
                TeamCollection.AddToTeam[Player, NewTeam]
                # Remove the team from the list of available teams to assign players to.
                set Teams = Teams.RemoveFirstElement[NewTeam]
            then:
                # Since we're going through each player in order, when no errors occur we should see increasing indices,
                # with no gaps in-between.
                Print("Reassigned team for Player {Index}")
    
    OnButtonInteracted<private>(Agent:agent):void= 
        ShuffleTeams()

    OnBegin<override>()<suspends>:void=
        Button.InteractedWithEvent.Subscribe(OnButtonInteracted)
        ShuffleTeams()