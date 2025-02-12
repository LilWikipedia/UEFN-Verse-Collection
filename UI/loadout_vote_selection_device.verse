#   * * * * * * * * * * * * * * * * * * * * * * * * *
#   * Script by: PiEqualsThree                      *
#   * Published on 1/30/2024                        *
#   * https://www.youtube.com/@piequalsthree3       *
#   * https://twitter.com/PiEqualsThreeVP           *
#   *                                               *    
#   *                                               *
#   * * * * * * * * * * * * * * * * * * * * * * * * *


using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }

StringToText<localizes>(String : string) : message = "{String}"

loadout_vote_selection_device := class(creative_device):
  
    @editable       StartTrigger : trigger_device = trigger_device{}
    @editable       Columns : type{_X : int where _X > 1, _X < 6} = 3
    @editable       VotingTime : type{ _X : int where _X >= 3, _X <= 30} = 10
    @editable       Loadouts : []loadout = array{}
    @editable       UISettings : ui_settings = ui_settings{}

    var LoadoutToCurrentVotes : [loadout]int = map{}
    var MaxVotes : int = 0
    var CurrentVotes : int = 0
    var ImageSize : vector2 = vector2{}
    var RowsToUse : int = 1
    # PUT YOUR TEXTURES HERE, IN THE ORDER OF LAYOUT!! :D
    Textures : []texture = array:
        <# TexturePath #>
        <# TexturePath #>
    
    VoteEndedEvent<private> : event() = event(){} # Signaled when voting period has ended
    PlayerSelectionEvent<private> : event(button_selection_result) = event(button_selection_result){} # Signaled when player has made their selection

    OnBegin<override>()<suspends> : void =
        loop:
            StartTrigger.TriggeredEvent.Await()
            InitLoadoutSelection(GetPlayspace().GetPlayers())
            
    # Call this to begin the loadout selection phase
    InitLoadoutSelection<public>(Players : []player)<suspends> : void =
        Sleep(0.0)
        set RowsToUse = Ceil[1.0 * Loadouts.Length /  (1.0 * Columns)] or 4
        set ImageSize = (560.0 / (1.0 * RowsToUse)) * vector2{ X := 1.0, Y := 1.0}
        set MaxVotes = Players.Length
        set CurrentVotes = 0
        for (Loadout : Loadouts, set LoadoutToCurrentVotes[Loadout] = 0) {} <# Reset Loadout Votes #>
        
        for ( Player : Players):
            spawn{ PresentSelectionUI(Player) }
        VoteEndedEvent.Await()
        WinningLoadout := CalculateMostVotedLoadout()
        for ( Player : Players):
            WinningLoadout.ItemGranter.GrantItem(Player)

    # Present the Loadout UI voting screen to a player
    PresentSelectionUI<private>(Player : player)<suspends> : void =
        var SelectionButtons : []button_loud = array{}
        # Create our selection buttons with the respective loadout name
        for ( Loadout : Loadouts):
            set SelectionButtons += array:
                button_loud:
                    DefaultText := StringToText("0")
            
        if ( PlayerUI := GetPlayerUI[Player]):
            var TimeRemaining : int = int[VotingTime] or 10
            TimerTextBlock := MakeTextBlock("Choose your vote!: {TimeRemaining}", UISettings.TimerTextColor, UISettings.TimerTextShadowColor, vector2{ X := 4.0, Y := 4.0})
            # Voting Timer
            branch:
                loop:
                    Sleep(1.0)
                    set TimeRemaining -= 1
                    TimerTextBlock.SetText(StringToText("Choose your vote!: {TimeRemaining}"))
                    if (TimeRemaining <= 0) then VoteEndedEvent.Signal()
            Canvas : canvas = canvas:
                Slots := array:
                    canvas_slot:
                        Widget := ConstructMainUI(SelectionButtons, TimerTextBlock)
                        Offsets := margin{ Left := 960.0, Top := 50.0}
                        Alignment := vector2{ X := 0.5, Y := 0.0}
            PlayerUI.AddWidget(Canvas, player_ui_slot{ InputMode := ui_input_mode.All})
            
            LoadoutButtonPressedEvent : event() = event(){} # Used for signaling when this individual player has made their selection
            for ( Index->Button : SelectionButtons, Loadout := Loadouts[Index]) { spawn{Button.AwaitSelection(Loadout, Index, LoadoutButtonPressedEvent)}}

            race:
                block:
                    VoteEndedEvent.Await()
                loop:
                    SelectionResult := PlayerSelectionEvent.Await()
                    if ( Player = SelectionResult.Player):
                        LoadoutButtonPressedEvent.Signal() # Signal when this player made their selection
                    if ( Loadout := Loadouts[SelectionResult.Index], Votes := LoadoutToCurrentVotes[Loadout], ButtonToUpdate := SelectionButtons[SelectionResult.Index]):
                        
                        ButtonToUpdate.SetText(StringToText("{Votes}"))
                   
            Sleep(1.0)
            PlayerUI.RemoveWidget(Canvas)

    # Constructs the loadout selection layout UI in a grid like fashion based on rows and cols
    ConstructMainUI<private>(Buttons : []text_button_base, TimerTextBlock : text_block) : stack_box =
        MainStackBox := stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot{Widget := TimerTextBlock, HorizontalAlignment := horizontal_alignment.Center}
        RowStackBoxes : []stack_box = for ( I := 0..RowsToUse - 1) {stack_box{Orientation := orientation.Horizontal}} # Creates stack boxes depending on number of rows to be used
        var CurrentRowToUse : int = 0
        for ( Index->Button : Buttons, Loadout := Loadouts[Index], StackBox := RowStackBoxes[CurrentRowToUse]):
            StackBox.AddWidget(
                stack_box_slot:
                    Widget := ConstructLoadoutStackBox(Index, Button, Loadout.Name )
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{ Left := ImageSize.X * 0.075 , Right := ImageSize.X * 0.075}
            )
            
            if ( Mod[Index, Columns] = Columns - 1):
                set CurrentRowToUse += 1 # Change rows when exceeding maximum columns in a single row

        for ( RowStackBox : RowStackBoxes):
            MainStackBox.AddWidget(
                stack_box_slot:
                    Widget := RowStackBox
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{ Top := ImageSize.X * 0.04, Bottom := ImageSize.X * 0.04}
            )
        return MainStackBox

    # Constructs a single loadout UI slot containing name, image, and button
    ConstructLoadoutStackBox(Index : int, Button : text_button_base, LoadoutName : string) : stack_box = 
        stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                # Loadout Name / Text
                stack_box_slot:
                    Widget := MakeTextBlock(LoadoutName, UISettings.LoadoutTextColor, UISettings.LoadoutTextShadowColor, vector2{ X := 4.0, Y := 4.0})
                    HorizontalAlignment := horizontal_alignment.Center
                # Image
                stack_box_slot:
                    Widget := overlay:
                        Slots := array:
                            overlay_slot: <# Border #>
                                Widget := color_block{ DefaultDesiredSize := ImageSize, DefaultColor := UISettings.BorderColor}
                            overlay_slot:
                                Widget := color_block{ DefaultDesiredSize := ImageSize * 0.9, DefaultColor := UISettings.BackgroundColor, DefaultOpacity := if (UISettings.UseBorder?) then 1.0 else 0.0}
                            overlay_slot:
                                Widget := GetImageWidget(Index)
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Bottom := ImageSize.X * 0.025}
                # Selection Button
                stack_box_slot:
                    Widget := Button
                    HorizontalAlignment := horizontal_alignment.Fill
                    Distribution := option{10.0}


    # Waits for a button to be clicked, signals player selection event
    (Button : text_button_base).AwaitSelection(Loadout : loadout, ButtonIndex : int, SelectionMadeEvent : event())<suspends> : void =
        race:
            block:
                SelectionMadeEvent.Await()
                return
            block:
                WidgetMessage := Button.OnClick().Await()
                if ( set LoadoutToCurrentVotes[Loadout] += 1) {}
                PlayerSelectionEvent.Signal(button_selection_result{ Player := WidgetMessage.Player, Index := ButtonIndex})
                
            block:
                Time := 1.0 * int[VotingTime] or 10.0
                Sleep(Time)
                return
        set CurrentVotes += 1
        if ( CurrentVotes >= MaxVotes ) then VoteEndedEvent.Signal()  

    # Calculates loadout to use
    CalculateMostVotedLoadout() : loadout =
        var GreatestVote : int = 0
        var WinningLoadout : loadout = loadout{}
        for ( Loadout->Vote : LoadoutToCurrentVotes):
            if ( Vote > GreatestVote) :
                set GreatestVote = Vote
                set WinningLoadout = Loadout
            if ( Vote = GreatestVote, GetRandomInt(1,2) = 1):
                set WinningLoadout = Loadout
        return WinningLoadout

    # Returns an image if any exists, otherwise returns a blank color block
    GetImageWidget(Index : int) : widget =
        if ( Texture := Textures[Index]):
            return texture_block:
                DefaultImage := Texture
                DefaultDesiredSize := 0.9 * ImageSize
        else:
            return color_block:
                DefaultColor := UISettings.BackgroundColor
                DefaultDesiredSize := 0.9 * ImageSize

    # Makes a text block with the provided arguments
    MakeTextBlock(Text : string, Color : color, ShadowColor : color, ShadowOffset : vector2) : text_block =
        NewTextBlock := text_block:
            DefaultText := StringToText(Text)
            DefaultTextColor := Color
            DefaultShadowColor := ShadowColor
            DefaultShadowOffset := option{ ShadowOffset }
        NewTextBlock.SetShadowOpacity(1.0)
        return NewTextBlock
        
loadout := class<concrete><unique>:
    @editable       Name : string = "Loadout"
    @editable       ItemGranter : item_granter_device = item_granter_device{}

button_selection_result := struct:
    Player : player
    Index : int

ui_settings := class<concrete>:
    @editable       UseBorder : logic = true
    @editable       BackgroundColor : color = NamedColors.Black
    @editable       BorderColor : color = NamedColors.White
    @editable       TimerTextColor : color = NamedColors.White
    @editable       TimerTextShadowColor : color = NamedColors.Black
    @editable       LoadoutTextColor : color = NamedColors.White
    @editable       LoadoutTextShadowColor : color = NamedColors.Black
