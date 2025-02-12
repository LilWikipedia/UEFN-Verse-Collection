#   * * * * * * * * * * * * * * * * * * * * * * * * *
#   * Script by: PiEqualsThree                      *
#   * Published on 17/04/2024                       *
#   * https://www.youtube.com/@piequalsthree3       *
#   * https://twitter.com/PiEqualsThreeVP           *
#   *                                               *    
#   *                                               *
#   * * * * * * * * * * * * * * * * * * * * * * * * *
using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { MyTextures.Ranks }

user_interface_manager := class(creative_device):
  
    var PlayerWidgetsMap : [player]player_widgets = map{}

    Init(Players : []player) : void =
        for ( Player : Players):
            InitializePlayerUI(Player)


    InitializePlayerUI(Player : player) : void =
        Canvas : canvas = canvas{}
        ProgressBar : custom_progress_bar = custom_progress_bar:
            Width := 300.0
            Height := 30.0
        ProgressBar.Init()
        CanvasSlot := canvas_slot:
            Widget := ProgressBar.GetRootWidget()
            Anchors := anchors{Minimum := vector2{X :=0.0,Y:=1.0}, Maximum := vector2{X:=0.0, Y := 1.0}}
            Offsets := margin{Left := 115.0, Top := -265.0}
        Canvas.AddWidget(CanvasSlot)
        PlayerWidgets := player_widgets:
            Canvas := Canvas
            ProgressBar := ProgressBar

        if ( set PlayerWidgetsMap[Player] = PlayerWidgets, PlayerUI := GetPlayerUI[Player]):
            PlayerUI.AddWidget(Canvas)

    InitRankUI(Player : player, PlayerStats : player_stats, RankSettings : rank_settings) : void =
        UpdateRank(Player, PlayerStats, RankSettings)

    UpdateRank(Player : player, PlayerStats : player_stats, RankSettings : rank_settings) : void =
        RankIndex := PlayerStats.Rank
        if (Widgets := PlayerWidgetsMap[Player], NewRank := RankSettings.Ranks[RankIndex], Image := RankSettings.Images[RankIndex]):
            Widgets.ProgressBar.SetForegroundColor(NewRank.ForegroundColor)
            Widgets.ProgressBar.SetBackgroundColor(NewRank.BackgroundColor)
            Widgets.ProgressBar.SetRankText(NewRank.Name)
            Widgets.ProgressBar.SetImage(Image, NewRank.ImageSize)
            UpdateProgress(Player, PlayerStats, RankSettings)

    UpdateProgress(Player : player, PlayerStats : player_stats, RankSettings : rank_settings) : void =
        RankIndex := PlayerStats.Rank
        if ( Widgets := PlayerWidgetsMap[Player], CurrentRank := RankSettings.Ranks[RankIndex]):
            if ( NextRank := RankSettings.Ranks[RankIndex + 1]):
                Progress := 1.0 * (PlayerStats.Points - CurrentRank.PointsNeeded) / (1.0 * (NextRank.PointsNeeded - CurrentRank.PointsNeeded))
                ProgressText := "{PlayerStats.Points} / {NextRank.PointsNeeded}"
                Widgets.ProgressBar.SetProgress(Progress, ProgressText)
            else:
                Progress := 1.0
                ProgressText := "{PlayerStats.Points}"
                Widgets.ProgressBar.SetProgress(Progress, ProgressText)
    

player_widgets := struct:
    Canvas : canvas
    ProgressBar : custom_progress_bar

custom_progress_bar := class:
    Width : float
    Height : float

    RankTextureBlock : texture_block = texture_block{DefaultImage := Unranked}
    ColorBlockForeground : color_block = color_block{}
    ColorBlockBackground : color_block = color_block{}
    RankTextBlock : text_block = text_block{DefaultTextColor := NamedColors.White}
    ProgressTextBlock : text_block = text_block{DefaultTextColor := NamedColors.White}

    var RootWidget : widget = color_block{}

    Init() : void =
        ColorBlockForeground.SetDesiredSize(vector2{X := Width, Y := Height})
        ColorBlockBackground.SetDesiredSize(vector2{X := Width, Y := Height})
        set RootWidget = overlay:
            Slots := array:
                overlay_slot:
                    Widget := RankTextureBlock
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Right := 195.0}
                overlay_slot:
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array:
                            stack_box_slot:
                                Widget := RankTextBlock
                                HorizontalAlignment := horizontal_alignment.Center
                            stack_box_slot:
                                Widget := overlay:
                                    Slots := array:
                                        overlay_slot:
                                            Widget := ColorBlockBackground
                                            HorizontalAlignment := horizontal_alignment.Left
                                        overlay_slot:
                                            Widget := ColorBlockForeground
                                            HorizontalAlignment := horizontal_alignment.Left
                                        overlay_slot:
                                            Widget := ProgressTextBlock
                                            HorizontalAlignment := horizontal_alignment.Center

    
    SetProgress(InProgress : float, ProgressText : string) : void =
        var NewProgress : float = 0.0
        if ( InProgress > 1.0) then set NewProgress = 1.0
        else if ( InProgress < 0.0) then set NewProgress = 0.0
        else set NewProgress = InProgress

        NewWidth := NewProgress * Width
        ColorBlockForeground.SetDesiredSize(vector2{X:=NewWidth, Y := Height})
        SetProgressText(ProgressText)

    GetRootWidget() : widget = RootWidget
    SetForegroundColor(Color : color) : void = ColorBlockForeground.SetColor(Color)                      
    SetBackgroundColor(Color : color) : void = ColorBlockBackground.SetColor(Color)  
    SetRankText(String : string) : void = RankTextBlock.SetText(StringToMessage(String)) 
    SetProgressText(String : string) : void = ProgressTextBlock.SetText(StringToMessage(String))                   
    SetImage(NewImage : texture, NewSize : vector2) : void =
        RankTextureBlock.SetImage(NewImage)
        RankTextureBlock.SetDesiredSize(NewSize)

StringToMessage<localizes>(String : string) : message = "{String}"

MyTextures<public> := module:
    Ranks<public> := module:
