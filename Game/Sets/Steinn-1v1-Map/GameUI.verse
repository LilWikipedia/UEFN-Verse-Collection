using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/FortPlayerUtilities }
using { /Fortnite.com/UI }
using { /Verse.org/Colors }
using { /Verse.org/Colors/NamedColors }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { GameManagerModule }

GameUIModule := module:
    log_ui := class(log_channel){}

    # Contains different health style
    health_type := enum:
        Shield
        Health

    AllShields:health_type =  health_type.Shield
    BalancedHealth:health_type =  health_type.Health

    # Manages players' health
    healthmanager<public> := class:
        var HealthType<private>:health_type = health_type.Shield
        var TotalHealth<private>:float = 184.5

        SetHealth(Health:float):void =
            set TotalHealth = Health

        SetHealthType(Type:health_type):void =
            set HealthType = Type

        # Changes all players health
        ChangeHealth(Players:[]player):void = 
            for:
                Player:Players
                FortCharacter := Player.GetFortCharacter[]
            do:
                if(HealthType = AllShields):
                    FortCharacter.SetMaxHealth(1.0)
                    FortCharacter.SetMaxShield(TotalHealth - 1.0)
                else:
                    FortCharacter.SetMaxHealth(100.0)
                    FortCharacter.SetMaxShield(TotalHealth - 100.0)
                    Print("Balanced")

    ui_list_node := class<unique>:
        var Next:?ui_list_node = false
        var Previous:?ui_list_node = false
        CurrentUI:canvas = canvas{}

    # Manages the main menu order
    ui_linked_list := class:
        # Main Menu
        Head:ui_list_node
        # The current Page the player is on
        var CurrentNode:ui_list_node := ui_list_node{}

        TraverseList()<transacts>:void =
            if(Current := CurrentNode.Next?):
                set CurrentNode = Current

        BacktrackList()<transacts>:void =
            if(Current := CurrentNode.Previous?):
                set CurrentNode = Current

        # Adds a new Node to list and sets CurrentNode to it
        Advance(Node:ui_list_node)<transacts>:void =
            set Node.Previous = option{CurrentNode}
            set CurrentNode.Next = option{Node}
            TraverseList()
        
        # Removes CurrentNode and sets it to previous Node
        Recede()<transacts>:void =
            BacktrackList()
            set CurrentNode.Next = false

    # Constructor for UI Linked List
    CreateUIList<constructor>(Node:ui_list_node)<transacts>:=
        ui_linked_list:
            Head := Node
            CurrentNode := Node

    Speed := struct<concrete>:
        @editable
        SpeedType:string = ""
        @editable
        Speeds:[]string = array{}

    ColorBlock := struct<concrete>:
        @editable
        Color:string = "0077BE80"
        @editable
        Opacity:type{x:float where x >= 0.0, x <= 1.0} = 0.9
        @editable
        Size:vector2 = vector2{X := 800.0, Y := 1080.0}

    Game_UI_Manager<public> := class(creative_device):
        Logger:log = log{Channel:=log_ui}

        @editable
        SpawnPads:[]player_spawner_device = array{}
        @editable 
        MenuButton:button_device = button_device{}
        @editable 
        Endgame:end_game_device = end_game_device{}
        @editable
        SpectatorManager:class_and_team_selector_device = class_and_team_selector_device{}
        @editable
        SlowSpeedMessage:[]elimination_feed_device = array{}
        @editable
        NormalSpeedMessage:elimination_feed_device = elimination_feed_device{}
        @editable
        FastSpeedMessage:[]elimination_feed_device = array{}
        @editable
        SlowCinematics:[]cinematic_sequence_device = array{}
        @editable
        NormalCinematics:cinematic_sequence_device = cinematic_sequence_device{}
        @editable
        FastCinematics:[]cinematic_sequence_device = array{}
        @editable
        MapSpeeds:[]Speed = array:
            Speed{SpeedType:="Slow"}, Speed{SpeedType:="Normal"}, Speed{SpeedType:="Fast"}, Speed{SpeedType:="Back"}
        @editable
        MenuColor:ColorBlock = ColorBlock{}

        # Button texts for the Main Menu Buttons
        MenuButtonNames:[]string = array:
            "Map Speed", "Health", "Spectate", "Restart", "Cancel"
        # Array of Max healths allowed in game
        MaxHealths:[]float = array{184.5, 200.0}
        Anchor:anchors = anchors{Minimum := vector2{X := 0.4, Y := 0.2}, Maximum := vector2{X := 0.4, Y := 0.2}}
        HUDElements:[]hud_element_identifier = array:
            player_hud_identifier_all{}
            creative_hud_identifier_all{}
            hud_identifier_world_resource_wood{}
            hud_identifier_world_resource_stone{}
            hud_identifier_world_resource_metal{}
            hud_identifier_world_resource_permanite{}
            hud_identifier_world_resource_gold_currency{}
            hud_identifier_world_resource_ingredient{}

        # Arrays of interactable UI Buttons
        var MainMenuButtons:[]button_regular = array{}
        var MapSpeedButtons:[]button_regular = array{}
        var HealthButtons:[]button_regular = array{}
        var RestartButtons:[]button_regular = array{}
        var SpectateButtons:[]button_regular = array{}
        var AllShieldsButtons:[]button_regular = array{}
        var BalancedHealthButtons:[]button_regular = array{}
        var CustomHealthButtons:[]button_regular = array{}
        var SlowSpeedButtons:[]button_regular = array{}
        var FastSpeedButtons:[]button_regular = array{}

        var CustomHealthSliders:[]slider_regular = array{}

        # Menu Nodes, each representing a page in the mainmenu
        var MainMenuNode:ui_list_node = ui_list_node{}
        var MapSpeedMenuNode:ui_list_node = ui_list_node{}
        var HealthMenuNode:ui_list_node = ui_list_node{}
        var SpectateMenuNode:ui_list_node = ui_list_node{}
        var RestartMenuNode:ui_list_node = ui_list_node{}
        var AllShieldsMenuNode:ui_list_node = ui_list_node{}
        var BalancedHealthMenuNode:ui_list_node = ui_list_node{}
        var CustomHealthMenuNode:ui_list_node = ui_list_node{}
        var SlowSpeedMenuNode:ui_list_node = ui_list_node{}
        var FastSpeedMenuNode:ui_list_node = ui_list_node{}

        # Background for the menu
        var Background:canvas = canvas{}
        # A map of Nodes(Pages) with the ui buttons on the pages
        var MenuNodeMap:[ui_list_node][]button_regular = map{}
        # Number of players in the 1v1 zone
        var NumberOfPlayersInZone:int = 0
        # A map that assigns Map Menu to Player - Used for getting the map menu UI in order to remove it
        var MaybeMapMenuUI:[player]?ui_linked_list = map{}
        # Number of players in the map excluding spectators
        var AllPlayers<public>:[]player = array{}
        # Instance of a class that manages player health
        var HealthManager<public>:healthmanager = healthmanager{}
        # An array of ui slots for all players
        var PlayerScoreSlots:[]stack_box_slot = array{}
        # A map of players with ther scores
        var PlayerScores<public>:[player]int = map{}
        # The current cinematic sequence device running
        var CurrentCinematic:cinematic_sequence_device = cinematic_sequence_device{}
        # The canvas for the 1v1 timer
        var TimerCanvas:canvas = canvas{}

        
        OnBegin<override>()<suspends>:void =
            InitializePlayers()
            InitializeSpawnPads()
            InitializeUIButtons()
            InitializeMapMenu()
            MenuButton.InteractedWithEvent.Subscribe(OnMenuButtonPressed)


        # Hides HUD for Player. (Not working properly according to epic since it affects all players)
        HideHud(Player:player):void = {}
            # if(PlayerUI := GetPlayerUI[Player]):
            #     PlayerUI.HideHUDElements(HUDElements)
        
        # Shows HUD for Player. (Not working properly according to epic since it affects all players)
        ShowHud(Player:player):void =
            if(PlayerUI := GetPlayerUI[Player]):
                PlayerUI.ShowHUDElements(HUDElements)

        # Stops any previous Speed cinematic playing and plays assigned cinematic
        Play(Cinematic:cinematic_sequence_device):void =
            CurrentCinematic.Stop()
            set CurrentCinematic = Cinematic
            CurrentCinematic.Play()
            
        # Initialize Spawnpads
        InitializeSpawnPads():void =
            for(SpawnPad:SpawnPads):
                SpawnPad.SpawnedEvent.Subscribe(OnPlayerSpawned)

        # Changes player health when player spawns
        OnPlayerSpawned(Agent:agent):void =
            if:
                Player := player[Agent]
                FortCharacter := Player.GetFortCharacter[]
                ShieldSlider := CustomHealthSliders[0]
                HealthSlider := CustomHealthSliders[1]
            then:
                FortCharacter.SetMaxShield(ShieldSlider.GetValue())
                FortCharacter.SetMaxHealth(HealthSlider.GetValue())
            
        # Returns the UI of the Player's current Node
        GetMenuUI(Player:player)<transacts><decides>:canvas =
            var UI:canvas = canvas{}
            if:
                List := MaybeMapMenuUI[Player]?
                Node := List.CurrentNode
            then:
                set UI = Node.CurrentUI
            return UI
        
        # Assigns all players excluding spectators to an array
        InitializePlayers():void = 
            set AllPlayers =
                for:
                    Player:GetPlayspace().GetPlayers()
                    not Player.IsSpectator[]
                do:
                    Player
            HealthManager.ChangeHealth(AllPlayers)

        # Initializes all Menu Nodes and assigns ui buttons to them
        InitializeMapMenu():void =
            set Background = ColorBlockCanvas()
            set MainMenuNode =
                ui_list_node:
                    CurrentUI := MainMenu()
            set MapSpeedMenuNode =
                ui_list_node:
                    Previous := option{MainMenuNode}
                    CurrentUI := MapSpeedMenu()
            set HealthMenuNode =
                ui_list_node:
                    Previous := option{MainMenuNode}
                    CurrentUI := HealthMenu()
            set SpectateMenuNode =
                ui_list_node:
                    CurrentUI := SpectateMenu()
            set RestartMenuNode =
                ui_list_node:
                    CurrentUI := RestartMenu()
            set AllShieldsMenuNode =
                ui_list_node:
                    CurrentUI := AllShieldsMenu()
            set BalancedHealthMenuNode =
                ui_list_node:
                    CurrentUI := BalancedHealthMenu()
            set CustomHealthMenuNode =
                ui_list_node:
                    CurrentUI := CustomHealthMenu()
            set SlowSpeedMenuNode =
                ui_list_node:
                    CurrentUI := SlowSpeedMenu()
            set FastSpeedMenuNode =
                ui_list_node:
                    CurrentUI := FastSpeedMenu()
            if:
                set MenuNodeMap[MainMenuNode] = MainMenuButtons
                set MenuNodeMap[MapSpeedMenuNode] = MapSpeedButtons
                set MenuNodeMap[HealthMenuNode] = HealthButtons
                set MenuNodeMap[SpectateMenuNode] = SpectateButtons
                set MenuNodeMap[RestartMenuNode] = RestartButtons
                set MenuNodeMap[AllShieldsMenuNode] = AllShieldsButtons
                set MenuNodeMap[BalancedHealthMenuNode] = BalancedHealthButtons
                set MenuNodeMap[CustomHealthMenuNode] = CustomHealthButtons
                set MenuNodeMap[SlowSpeedMenuNode] = SlowSpeedButtons
                set MenuNodeMap[FastSpeedMenuNode] = FastSpeedButtons

        
        # Creates a color block canvas
        ColorBlockCanvas():canvas =
            canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                        #Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := texture_block:
                            DefaultImage := MainMenu_Background
                            DefaultDesiredSize := vector2{X := 1920.0, Y := 1080.0}
                        # Widget := color_block:
                        #     DefaultColor := MakeColorFromHex(MenuColor.Color)
                        #     DefaultOpacity := MenuColor.Opacity
                        #     DefaultDesiredSize := MenuColor.Size
                        

        # Returns the main menu canvas
        MainMenu():canvas =
            canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := Anchor
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText := ToMessage("MAIN MENU")
                            DefaultTextColor := White
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        # Arrange the UI Buttons in a stack box
                        Widget := stack_box:
                                Orientation := orientation.Vertical
                                Slots := 
                                    for(Button:MainMenuButtons):
                                        stack_box_slot:
                                            Padding := margin{Bottom := 10.0}
                                            Widget := Button
        # Returns the map speed menu canvas
        MapSpeedMenu():canvas =
            canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := Anchor
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText := ToMessage("MAP SPEED MENU")
                            DefaultTextColor := White
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        # Arrange the UI Buttons in a stack box
                        Widget := stack_box:
                            Orientation := orientation.Vertical
                            Slots := 
                                for(Button:MapSpeedButtons):
                                    stack_box_slot:
                                        Padding := margin{Bottom := 10.0}
                                        Widget := Button
        # Returns the health menu canvas                      
        HealthMenu():canvas =
            canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := Anchor
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText := ToMessage("HEALTH MENU")
                            DefaultTextColor := White
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.4, Y := 0.3}, Maximum := vector2{X := 0.4, Y := 0.3}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := stack_box:
                            Orientation := orientation.Vertical
                            Slots := array:
                                stack_box_slot:
                                    Widget := text_block:
                                        DefaultText := ToMessage("All Shields - 1 Health")
                                        DefaultTextColor := White
                                stack_box_slot:
                                    Widget := text_block:
                                        DefaultText := ToMessage("Balanced - 100 Health")
                                        DefaultTextColor := White
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        # Arrange the UI Buttons in a stack box
                        Widget := stack_box:
                            Orientation := orientation.Vertical
                            Slots := 
                                for(Button:HealthButtons):
                                    stack_box_slot:
                                        Padding := margin{Bottom := 10.0}
                                        Widget := Button

        # Returns the Spectate menu canvas
        SpectateMenu():canvas =
            canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.3}, Maximum := vector2{X := 0.5, Y := 0.3}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText := ToMessage("SPECTATE MENU")
                            DefaultTextColor := White
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.4}, Maximum := vector2{X := 0.5, Y := 0.4}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText:=ToMessage("Switch to spectate?")
                            DefaultTextColor := Red
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        # Arrange the UI Buttons in a stack box
                        Widget := stack_box:
                            Orientation := orientation.Horizontal
                            Slots := 
                                for(Button:SpectateButtons):
                                    stack_box_slot:
                                        Padding := margin{Left := 50.0, Right := 50.0}
                                        Widget := Button
        
        # Returns the Restart menu canvas
        RestartMenu():canvas =
            canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.3}, Maximum := vector2{X := 0.5, Y := 0.3}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText := ToMessage("RESTART MENU")
                            DefaultTextColor := White
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.4}, Maximum := vector2{X := 0.5, Y := 0.4}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText:=ToMessage("Restart Map?")
                            DefaultTextColor := Red
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        # Arrange the UI Buttons in a stack box
                        Widget := stack_box:
                            Orientation := orientation.Horizontal
                            Slots := 
                                for(Button:RestartButtons):
                                    stack_box_slot:
                                        Padding := margin{Left := 50.0, Right := 50.0}
                                        Widget := Button

        # Returns the AllShields menu canvas
        AllShieldsMenu(): canvas = 
            canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := Anchor
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText := ToMessage("ALL SHIELDS MENU")
                            DefaultTextColor := White
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        # Arrange the UI Buttons in a stack box
                        Widget := stack_box:
                            Orientation := orientation.Vertical
                            Slots := 
                                for(Button:AllShieldsButtons):
                                    stack_box_slot:
                                        Padding := margin{Top := 10.0}
                                        Widget := Button
        
        # Returns the Balanced Health menu canvas
        BalancedHealthMenu(): canvas =
            canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := Anchor
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText := ToMessage("BALANCED HEALTH MENU")
                            DefaultTextColor := White
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        # Arrange the UI Buttons in a stack box
                        Widget := stack_box:
                            Orientation := orientation.Vertical
                            Slots := 
                                for(Button:BalancedHealthButtons):
                                    stack_box_slot:
                                        Padding := margin{Top := 10.0}
                                        Widget := Button
        
        # Returns the Balanced Health menu canvas
        CustomHealthMenu(): canvas =
            CreateUISliders()
            canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := Anchor
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText := ToMessage("CUSTOM HEALTH MENU")
                            DefaultTextColor := White
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.4, Y := 0.54}, Maximum := vector2{X := 0.4, Y := 0.54}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := stack_box:
                            Orientation := orientation.Vertical
                            Slots := array:
                                stack_box_slot:
                                    Widget := text_block:
                                        DefaultText := ToMessage("Shields:")
                                        DefaultTextColor := Blue
                                stack_box_slot:
                                    Padding := margin{Top := 40.0}
                                    Widget := text_block:
                                        DefaultText := ToMessage("Health:")
                                        DefaultTextColor := LimeGreen
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := stack_box:
                            Orientation := orientation.Vertical
                            Slots :=
                                for(Slider:CustomHealthSliders):
                                    stack_box_slot:
                                        Padding := margin{Top := 50.0}
                                        Widget := Slider
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.7}, Maximum := vector2{X := 0.5, Y := 0.7}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        # Arrange the UI Buttons in a stack box
                        Widget := stack_box:
                            Orientation := orientation.Horizontal
                            Slots := 
                                for(Button:CustomHealthButtons):
                                    stack_box_slot:
                                        Padding := margin{Left := 25.0, Right := 25.0}
                                        Widget := Button
                                    
        
        # Returns the Slow Speed menu canvas
        SlowSpeedMenu():canvas =
            canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := Anchor
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText := ToMessage("SLOW SPEED MENU")
                            DefaultTextColor := White
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        # Arrange the UI Buttons in a stack box
                        Widget := stack_box:
                            Orientation := orientation.Vertical
                            Slots := 
                                for(Button:SlowSpeedButtons):
                                    stack_box_slot:
                                        Padding := margin{Top := 10.0}
                                        Widget := Button
       
        # Returns the Fast Speed menu canvas
        FastSpeedMenu():canvas =
            canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := Anchor
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText := ToMessage("FAST SPEED MENU")
                            DefaultTextColor := White
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        # Arrange the UI Buttons in a stack box
                        Widget := stack_box:
                            Orientation := orientation.Vertical
                            Slots := 
                                for(Button:FastSpeedButtons):
                                    stack_box_slot:
                                        Padding := margin{Top := 10.0}
                                        Widget := Button

        # Creates UI Sliders
        CreateUISliders():void =
            if:
                Player := AllPlayers[0]
                FortCharacter := Player.GetFortCharacter[]
            then:
                set CustomHealthSliders = array:
                    slider_regular:
                        DefaultValue := FortCharacter.GetMaxShield()
                        # if minvalue is 0.0, player's can't get shield back with setmaxshield or setshield for some reason even
                        DefaultMinValue := 1.0
                        DefaultMaxValue := 200.0
                        DefaultStepSize := 0.5
                    slider_regular:
                        DefaultValue := FortCharacter.GetMaxHealth()
                        DefaultMinValue := 1.0
                        DefaultMaxValue := 200.0
                        DefaultStepSize := 0.5

        # Initializes all UI buttons
        InitializeUIButtons():void =
            # Create and subscribe Buttons
            # A tuple of []button_regulars is passed into the subscribe function
            # The tuple contains MenuUIButtons, MapSpeedButtons, etc.
            SubscribeUIButtons(
                (set MainMenuButtons = 
                    for(Text:MenuButtonNames):
                        Button := button_regular{DefaultText:=ToMessage(Text)}
                ),
                (set MapSpeedButtons =
                    for(MapSpeed:MapSpeeds):
                        Text := MapSpeed.SpeedType
                        Button := button_regular{DefaultText:=ToMessage(Text)}
                ),
                (set HealthButtons = array:
                    button_regular{DefaultText:=ToMessage("All Shields")}
                    button_regular{DefaultText:=ToMessage("Balanced")}
                    button_regular{DefaultText:=ToMessage("Custom")}
                    button_regular{DefaultText:=ToMessage("Back")}
                ),
                (set AllShieldsButtons = array:
                    button_regular{DefaultText:=ToMessage("185")}
                    button_regular{DefaultText:=ToMessage("200")}
                    button_regular{DefaultText:=ToMessage("Back")}
                ),
                (set BalancedHealthButtons = array:
                    button_regular{DefaultText:=ToMessage("185")}
                    button_regular{DefaultText:=ToMessage("200")}
                    button_regular{DefaultText:=ToMessage("Back")}
                ),
                (set CustomHealthButtons = array:
                    button_regular{DefaultText:=ToMessage("Okay")}
                    button_regular{DefaultText:=ToMessage("Back")}
                ),
                (set RestartButtons = array:
                    button_regular{DefaultText:=ToMessage("Yes")}
                    button_regular{DefaultText:=ToMessage("No")}
                ),
                (set SpectateButtons = array:
                    button_regular{DefaultText:=ToMessage("Yes")}
                    button_regular{DefaultText:=ToMessage("No")}
                ),
                (set SlowSpeedButtons =
                    for(Text:MapSpeeds[0].Speeds):
                        Button := button_regular{DefaultText:=ToMessage(Text)}
                ),
                (set FastSpeedButtons =
                    for(Text:MapSpeeds[2].Speeds):
                        Button := button_regular{DefaultText:=ToMessage(Text)}
                )
            )
        
        # Subscribes UI Buttons
        SubscribeUIButtons(ButtonGroup:[][]button_regular):void =
            for(Buttons:ButtonGroup, Button:Buttons):
                Button.OnClick().Subscribe(OnClickingButton)     

        # Gets the Button, Player and Menu UI, then proceeds to the function of the ui button
        OnClickingButton(Message:widget_message):void =
            if:
                Player := Message.Player
                ClickedButton := text_button_base[Message.Source]
                MenuUI := GetMenuUI[Player]
            then:
                Print("UI button clicked")
                HandleUIButtonClick(ClickedButton, Player, MenuUI)
        
        # Handles the actions of each UI Button
        HandleUIButtonClick(ClickedButton:text_button_base, Player:player, MenuUI:canvas):void =
            if:
                PlayerUI := GetPlayerUI[Player]
            then:
                # Remove current Widget before showing another one
                PlayerUI.RemoveWidget(MenuUI)

                # Check if UI button is from main menu
                if(ClickedButton = MainMenuButtons[0]):
                    Print("Clicked on Map Menu")
                    OpenMenu(Player, MapSpeedMenuNode)
                else if(ClickedButton = MainMenuButtons[1]):
                    Print("Clicked on Health")
                    OpenMenu(Player, HealthMenuNode)
                else if(ClickedButton = MainMenuButtons[2]):
                    Print("Clicked on Spectate")
                    OpenMenu(Player, SpectateMenuNode)
                else if(ClickedButton = MainMenuButtons[3]):
                    Print("Clicked on Restart")
                    OpenMenu(Player, RestartMenuNode)
                else if(ClickedButton = MainMenuButtons[MainMenuButtons.Length - 1]):
                    Print("Clicked on Cancel")
                    RemoveMapMenuUI(Player)

                # Check if UI button is from Map Speed menu
                else if(ClickedButton = MapSpeedButtons[0]):
                    Print("Clicked on Slow Speed")
                    OpenMenu(Player, SlowSpeedMenuNode)
                else if(ClickedButton = MapSpeedButtons[1]):
                    Print("Clicked on Normal Speed")
                    Play(NormalCinematics)
                    NormalSpeedMessage.Activate(Player)
                    RemoveMapMenuUI(Player)
                else if(ClickedButton = MapSpeedButtons[2]):
                    Print("Clicked on Fast Speed")
                    OpenMenu(Player, FastSpeedMenuNode)
                else if:
                        ClickedButton = MapSpeedButtons[MapSpeedButtons.Length - 1]
                        MaybeMapMenuUI[Player]?.Recede()
                then:
                    Print("Clicked on Back")
                    OpenUI(Player)

                # Check if UI button is from Health menu
                else if(ClickedButton = HealthButtons[0]):
                    Print("Clicked on AllShields")
                    OpenMenu(Player, AllShieldsMenuNode)
                else if(ClickedButton = HealthButtons[1]):
                    Print("Clicked on Balanced Health")
                    OpenMenu(Player, BalancedHealthMenuNode)
                else if(ClickedButton = HealthButtons[2]):
                    Print("Clicked on Custom")
                    # Cutom Health Page has to be recreated on every click 
                    # to modify the slider default valueto current max health and shield
                    set CustomHealthMenuNode =
                        ui_list_node:
                            CurrentUI := CustomHealthMenu()
                    OpenMenu(Player, CustomHealthMenuNode)
                else if:
                    ClickedButton = HealthButtons[HealthButtons.Length - 1]
                    MaybeMapMenuUI[Player]?.Recede()
                then:
                    Print("Clicked on Back")
                    OpenUI(Player)

                # Check if UI button is from Spectate menu
                else if(ClickedButton = SpectateButtons[0]):
                    Print("Clicked on Yes")
                    SpectatorManager.ChangeClass(Player)
                    if(FortCharacter := Player.GetFortCharacter[]):
                        RemoveMapMenuUI(Player)
                        FortCharacter.Damage(Inf)
                else if(ClickedButton = SpectateButtons[1]):
                    Print("Clicked on No")
                    RemoveMapMenuUI(Player)

                # Check if UI button is from Restart menu
                else if(ClickedButton = RestartButtons[0]):
                    Print("Clicked on Yes")
                    RemoveMapMenuUI(Player)
                    Endgame.Activate(Player)
                else if(ClickedButton = RestartButtons[1]):
                    Print("Clicked on No")
                    RemoveMapMenuUI(Player)

                else:
                    var Index:int = 0
                    # Check if UI button is from AllShields menu
                    for(Button:AllShieldsButtons):
                        if(Button = ClickedButton):
                            Print("Clicked a button on AllShield")
                            if:
                                Button = AllShieldsButtons[AllShieldsButtons.Length - 1]
                                MaybeMapMenuUI[Player]?.Recede()
                            then:
                                Print("Clicked on Back")
                                OpenUI(Player)
                            else:
                                if(Health := MaxHealths[Index]):
                                    HealthManager.SetHealth(Health)
                                    HealthManager.SetHealthType(AllShields)
                                    HealthManager.ChangeHealth(AllPlayers)
                                    CreateUISliders()
                                    RemoveMapMenuUI(Player)
                            return
                        set Index += 1

                    # Check if UI button is from Balanced Health menu
                    set Index = 0
                    for(Button:BalancedHealthButtons):
                        if(Button = ClickedButton):
                            Print("Clicked a button on Balanced")
                            if:
                                Button = BalancedHealthButtons[BalancedHealthButtons.Length - 1]
                                MaybeMapMenuUI[Player]?.Recede()
                            then:
                                Print("Clicked on Back")
                                OpenUI(Player)
                            else:
                                if(Health := MaxHealths[Index]):
                                    HealthManager.SetHealth(Health)
                                    HealthManager.SetHealthType(BalancedHealth)
                                    HealthManager.ChangeHealth(AllPlayers)
                                    CreateUISliders()
                                    RemoveMapMenuUI(Player)
                            return
                        set Index += 1

                    # Check if UI button is from Custom Health menu
                    set Index = 0
                    for(Button:CustomHealthButtons):
                        if(Button = ClickedButton):
                            Print("Clicked a button on Custom")
                            if:
                                Button = CustomHealthButtons[CustomHealthButtons.Length - 1]
                                MaybeMapMenuUI[Player]?.Recede()
                            then:
                                Print("Clicked on Back")
                                OpenUI(Player)
                            else:
                                Print("Clicked on Okay")
                                # Set the healths and shields of all players to the values on the sliders
                                for:
                                    InPlayer:AllPlayers
                                    FortCharacter := InPlayer.GetFortCharacter[]
                                    ShieldSlider := CustomHealthSliders[0]
                                    HealthSlider := CustomHealthSliders[1]
                                do:
                                    FortCharacter.SetMaxShield(ShieldSlider.GetValue())
                                    FortCharacter.SetMaxHealth(HealthSlider.GetValue())
                                    RemoveMapMenuUI(Player)
                            return
                        set Index += 1

                    # Check if UI button is from Slow Speed menu
                    set Index = 0
                    for(Button:SlowSpeedButtons):
                        if(Button = ClickedButton):
                            if:
                                Button = SlowSpeedButtons[SlowSpeedButtons.Length - 1]
                                MaybeMapMenuUI[Player]?.Recede()
                            then:
                                Print("Clicked on Back")
                                OpenUI(Player)
                            else:
                                if:
                                    Cinematic := SlowCinematics[Index]
                                    SpeedMessage := SlowSpeedMessage[Index]
                                then:
                                    SpeedMessage.Activate(Player)
                                    Play(Cinematic)
                                    RemoveMapMenuUI(Player)
                            return
                        set Index += 1

                    # Check if UI button is from Fast Speed menu
                    set Index = 0
                    for(Button:FastSpeedButtons):
                        if(Button = ClickedButton):
                            if:
                                Button = FastSpeedButtons[FastSpeedButtons.Length - 1]
                                MaybeMapMenuUI[Player]?.Recede()
                            then:
                                Print("Clicked on Back")
                                OpenUI(Player)
                            else:
                                if:
                                    Cinematic := FastCinematics[Index]
                                    SpeedMessage := FastSpeedMessage[Index]
                                then:
                                    SpeedMessage.Activate(Player)
                                    Play(Cinematic)
                                    RemoveMapMenuUI(Player)
                            return
                        set Index += 1

        # Removes the Menu List assigned to player.
        # Means Player shouldn't have a UI anymore and can move freely
        RemoveMapMenuUI(Player:player):void =
            if:
                PlayerUI := GetPlayerUI[Player]
                set MaybeMapMenuUI[Player] = false
            then:
                PlayerUI.RemoveWidget(Background)
                ShowHud(Player)
                Print("Removed Menu from Player Map{}")
            
        # Moves Adds a node to the UI Linked list before showing the node(page)
        OpenMenu(Player:player, Node:ui_list_node):void =
            if:
                List := MaybeMapMenuUI[Player]?
                List.Advance(Node)
                set MaybeMapMenuUI[Player] = option{List}
            Print("Showing Menu")
            OpenUI(Player)

        # Shows the UI on the Current Node
        OpenUI(Player:player):void =
            if:
                PlayerUI := GetPlayerUI[Player]
                UI := GetMenuUI[Player]
            then:
                PlayerUI.AddWidget(UI, player_ui_slot{InputMode:=ui_input_mode.All})
        
        # Shows a max height message
        DisplayMaxHeightMessage<public>(Player:player)<suspends>:void = 
            Canvas := canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.2}, Maximum := vector2{X := 0.5, Y := 0.2}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := text_block:
                            DefaultText := ToMessage("MAX HEIGHT!")
                            DefaultTextColor := Red
            if(PlayerUI := GetPlayerUI[Player]):
                PlayerUI.AddWidget(Canvas)
                Print("Added Max Height Widget")
                Sleep(3.0)
                PlayerUI.RemoveWidget(Canvas)
                Print("Removed Max Height Widget") 

        # Initializes the menu button
        OnMenuButtonPressed(Agent:agent):void =
            if:
                Player := player[Agent]
                PlayerUI := GetPlayerUI[Player]
                MapMenuList := CreateUIList(MainMenuNode)
                set MaybeMapMenuUI[Player] = option{MapMenuList}
            then:
                Print("Added Menu List to Player Map")
                # For some reason, canvas and widgets are removed from player when another player triggers the function. 
                # Basically transfers the widgets to the new triggering player
                PlayerUI.AddWidget(Background)
                HideHud(Player)
                OpenUI(Player)
                
        # Show player name as a message
        PlayerName<localizes>(Agent:agent):message = "{Agent}"
        # Convert string to message
        ToMessage<localizes><public>(Text:string):message = "{Text}"
        # Convert Agent and string to message in this format
        ToMessage<localizes>(Agent:agent, Text:string):message = "{Agent} {Text}"
