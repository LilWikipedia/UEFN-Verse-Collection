# author unknown

subtitle_device := class(creative_device):
    
        @editable
        SubtitleText: []subtitle_text = array{}
    
        @editable
        SubtitlePosition: position = position{}
    
        @editable
        StartSubtitleTrigger: trigger_device = trigger_device{}
    
        @editable
        EndEventTrigger: trigger_device = trigger_device{}
    
        var GlobalData: global_data = global_data{}
        var IsPlayingSubtitle: logic = false
    
        HalfChar: string = "QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm1234567890-^\\@[;:],./!\"#$%&'()=~|`\{\}+*\<\>?_ "
    
        JapaneseTextSizeX: float = 0.006
        EnglishTextSizeX: float = 0.01
        JapaneseTextSizeY: float = 0.032
        EnglishTextSizeY: float = 0.032
    
        Setup():void=
            StartSubtitleTrigger.TriggeredEvent.Subscribe(OnStart)
    
        GetTextSize(STextInfo: subtitle_text):void=
     
            var MaxTextSizeX: float = 0.0
            var SumTextSizeY: float = 0.0
     
            for(Text: STextInfo.LineText):
     
                SizeX := GetTextSizeX(Text.Text)
                if(SizeX > MaxTextSizeX):
                    set MaxTextSizeX = SizeX
     
                SizeY := GetTextSizeY(Text.Text)
                set Text.LineHeight = SizeY
                set SumTextSizeY += SizeY
                
            set STextInfo.TextSizeX = MaxTextSizeX
            set STextInfo.TextSizeY = SumTextSizeY
     
        GetTextSizeX(String: string):float=
            var TextSize: float = 0.0
     
            for(Character : String):
                if(HalfChar.Find[Character]):
                    set TextSize += EnglishTextSizeX
                else:
                    set TextSize += JapaneseTextSizeX
     
            return TextSize
     
        GetTextSizeY(String: string):float=
            var TextSize: float = 0.0
     
            for(Character : String):
                if(HalfChar.Find[Character]):
                    set TextSize = EnglishTextSizeY
                else:
                    set TextSize = JapaneseTextSizeY
     
            return TextSize
    
        StartSubtitle(Agent: agent)<suspends>:void=
            if:
                not GlobalData.WidgetPerAgent[Agent], set GlobalData.WidgetPerAgent[Agent] = main_widget:
                    MaxHP := GlobalData.HPBar.MaxHP
                    BasePosition := GlobalData.HPBar.Position
                    SizePosition := GlobalData.HPBar.Size
                    OutlineSize := GlobalData.HPBar.OutlineSize
                    GlobalData := Self.GlobalData
                    PrevHP := GlobalData.HPBar.MaxHP
                    DamageEffectAmount := GlobalData.HPBar.DamageEffectAmount
                    HPBarBG := color_block{DefaultColor := MakeColorFromHex(GlobalData.HPBar.BackgroundColor)}
                    HPBarOutline := color_block{DefaultColor := MakeColorFromHex(GlobalData.HPBar.OutlineColor)}
                    HPBarBaseColor := color_block{DefaultColor := MakeColorFromHex(GlobalData.HPBar.BarColor)}
                    HPBarDamagedColor := color_block{DefaultColor := MakeColorFromHex(GlobalData.HPBar.DamageEffectColor)}
                    HPBarText := text_block{DefaultTextColor := MakeColorFromHex(GlobalData.HPBar.HPTextColor), DefaultJustification := text_justification.Center}
            if(WClass := GlobalData.WidgetPerAgent[Agent]):
                race:
                    block:
                        set WClass.IsDisplaySubtitle = true
                        for(STextInfo : SubtitleText):
    
                            set WClass.NowText = STextInfo
                            set WClass.NowTextPosition = Self.SubtitlePosition
    
                            GetTextSize(STextInfo)
                            WClass.UpdateUI(Agent)
                            STextInfo.Sound.Play(Agent)
                            Sleep(STextInfo.DisplayTime)
                        set WClass.NowText = subtitle_text{}
                        set WClass.IsDisplaySubtitle = false
                        WClass.UpdateUI(Agent)
                        EndEventTrigger.Trigger(Agent)
                    StartSubtitleTrigger.TriggeredEvent.Await()
    
        OnStart(MaybeAgent: ?agent):void=
            AllPlayers := GetPlayspace().GetPlayers()
            for(Player : AllPlayers):
                spawn{StartSubtitle(Player)}
    
    subtitle_text := class<concrete>:
        @editable
        LineText: []line_text = array{}
    
        @editable
        DisplayTime: float = 0.0
    
        @editable
        Sound: audio_player_device = audio_player_device{}
    
        var TextSizeX: float = 0.0
        var TextSizeY: float = 0.0
    
    line_text := class<concrete>:
        @editable
        Text: string = array{}
    
        var LineHeight: float = 0.0
    
    hp_bar := class<concrete>:
        @editable
        MaxHP: float = 0.0
    
        @editable
        Position: position = position{X := 0.5, Y := 0.1}
    
        @editable
        Size: position = position{X := 0.5, Y := 0.1}
    
        @editable
        OutlineSize: float = 0.01
    
        @editable
        HPTextColor: string = "FFFFFF"
    
        @editable
        BackgroundColor: string = "000000"
    
        @editable
        OutlineColor: string = "f0f8ff"
    
        @editable
        BarColor: string = "008000"
    
        @editable
        DamageEffectColor: string = "ff4500"
    
        @editable
        DamageEffectAmount: float = 100.0
    
        @editable
        EnableHPBarTrigger: trigger_device = trigger_device{}
    
        @editable
        DisableHPBarTrigger: trigger_device = trigger_device{}
    
        @editable
        ResetHPBarTrigger: trigger_device = trigger_device{}
    
        @editable
        ElimEvent: trigger_device = trigger_device{}
    
    position := class<concrete>:
        @editable
        X: type{_X:float where _X >= 0.0, _X <= 1.0} = 0.0
    
        @editable
        Y: type{_X:float where _X >= 0.0, _X <= 1.0} = 0.0
    
    global_data := class:
        var HPBar: hp_bar = hp_bar{}
    
        var NowHP: float = 0.0
    
        var WidgetPerAgent: [agent]main_widget = map{}
    
    damage_info := class<concrete>:
        @editable
        DamageAmount: float = 0.0
    
        @editable
        DamageTrigger: trigger_device = trigger_device{}
    
    main_widget := class:
    
        HPBarBG: color_block
        HPBarOutline: color_block
        HPBarBaseColor: color_block
        HPBarDamagedColor: color_block
        HPBarText: text_block
    
        var MaxHP: float
    
        BasePosition: position
        SizePosition: position
        OutlineSize: float
        DamageEffectAmount: float
    
        GlobalData: global_data
    
        var PrevHP: float = 0.0
    
        var NowText: subtitle_text = subtitle_text{}
        var NowTextPosition: position = position{}
    
        var NowTextBlock: []tuple(text_block, float) = array{}
    
        var IsDisplaySubtitle: logic = false
        var IsDisplayHPBar: logic = false
    
        var IsUpdating: logic = false
    
        var NowCanvas: ?canvas = false
    
        StringToMessage<localizes>(String: string):message="{String}"
    
        UpdateUI(Agent: agent)<suspends>:void=
            RemoveUI(Agent)
    
            HPBarText.SetText(StringToMessage("{ToTruncatedString(GlobalData.NowHP, 0)} / {ToTruncatedString(MaxHP, 0)}"))
            
            set NowTextBlock = for(Text : NowText.LineText):
                TextBlock := text_block{DefaultText := StringToMessage(Text.Text), DefaultTextColor := NamedColors.White}
                (TextBlock, Text.LineHeight)
     
            if(Player := player[Agent], PlayerUI := GetPlayerUI[Player]):
                var PrevCanvasSlots: []canvas_slot = array{}
    
                if(IsDisplaySubtitle?):
                    set PrevCanvasSlots += CreateSubtitle()
                if(IsDisplayHPBar?):
                    set PrevCanvasSlots += CreateHPBar()
    
                Canvas := canvas:
                    Slots :=  PrevCanvasSlots
    
                PlayerUI.AddWidget(Canvas)
                set NowCanvas = option{Canvas}
    
                spawn{UpdatePrevHP(Agent)}
    
        UpdatePrevHP(Agent: agent)<suspends>:void=
            if(IsUpdating?):
                return
    
            set IsUpdating = true
            loop:
                Diff := GlobalData.NowHP - PrevHP
                if(Diff >= 0.0):
                    set PrevHP = GlobalData.NowHP
                    set IsUpdating = false
                    break
                else if(Value := Int[(Diff / DamageEffectAmount)]):
                    set PrevHP += Value*1.0
                UpdateUI(Agent)
                Sleep(0.0)
        
        RemoveUI(Agent: agent):void=
            if(Player := player[Agent], PlayerUI := GetPlayerUI[Player], Canvas := NowCanvas?):
                PlayerUI.RemoveWidget(Canvas)
                set NowCanvas = false
    
        CreateHPBar():[]canvas_slot=
            if(GlobalData.NowHP <= 0.0):
                set GlobalData.NowHP = 0.0
            if(PrevHP <= 0.0):
                set PrevHP = 0.0
    
            var NowPercent: float = GlobalData.NowHP / MaxHP
            if(GlobalData.NowHP <= 0.0):
                set NowPercent = 0.0
    
    
            NowPercentPosition: float = Lerp(BasePosition.X - SizePosition.X / 2.0, BasePosition.X + SizePosition.X / 2.0, NowPercent)
            
            var PrevPercent: float = PrevHP / MaxHP
            if(PrevHP <= 0.0):
                set PrevPercent = 0.0
            PrevPercentPosition: float = Lerp(BasePosition.X - SizePosition.X / 2.0, BasePosition.X + SizePosition.X / 2.0, PrevPercent)
    
            var CanvasSlots: []canvas_slot = array{}
    
            set CanvasSlots += array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := BasePosition.X, Y := BasePosition.Y} - (vector2{X := SizePosition.X, Y := SizePosition.Y} / 2.0) - vector2{X := OutlineSize, Y := OutlineSize}, Maximum := vector2{X := BasePosition.X, Y := BasePosition.Y} + (vector2{X := SizePosition.X, Y := SizePosition.Y} / 2.0) + vector2{X := OutlineSize, Y := OutlineSize}}
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                    Widget := HPBarOutline
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := BasePosition.X, Y := BasePosition.Y} - (vector2{X := SizePosition.X, Y := SizePosition.Y} / 2.0), Maximum := vector2{X := BasePosition.X, Y := BasePosition.Y} + (vector2{X := SizePosition.X, Y := SizePosition.Y} / 2.0)}
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                    Widget := HPBarBG
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := BasePosition.X, Y := BasePosition.Y} - (vector2{X := SizePosition.X, Y := SizePosition.Y} / 2.0), Maximum := vector2{Y := BasePosition.Y} + vector2{Y := (SizePosition.Y / 2.0), X := PrevPercentPosition}}
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := false
                    Widget := HPBarDamagedColor
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := BasePosition.X, Y := BasePosition.Y} - (vector2{X := SizePosition.X, Y := SizePosition.Y} / 2.0), Maximum := vector2{Y := BasePosition.Y} +  vector2{Y := (SizePosition.Y / 2.0), X:= NowPercentPosition}}
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := false
                    Widget := HPBarBaseColor
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := BasePosition.X, Y := BasePosition.Y},  Maximum := vector2{X := BasePosition.X, Y := BasePosition.Y}}
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := false
                    Widget := HPBarText
    
            
            CanvasSlots
                
        CreateSubtitle():[]canvas_slot=
            Background: color_block = color_block{DefaultOpacity := 0.75, DefaultColor := NamedColors.Black}
    
            var NowLineHeight: float = 0.0
            for(Text: NowText.LineText):
                set NowLineHeight += Text.LineHeight
    
            var CanvasSlots: []canvas_slot = array{}
    
            set CanvasSlots += array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := NowTextPosition.X, Y := NowTextPosition.Y} - vector2{X := (NowText.TextSizeX / 2.0) + 0.01, Y := NowText.TextSizeY + 0.03}, Maximum := vector2{X := NowTextPosition.X, Y := NowTextPosition.Y} + vector2{X := (NowText.TextSizeX / 2.0) + 0.01}}
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                    Widget := Background
    
            for(Index -> TextBlock : NowTextBlock):
                set CanvasSlots += array:
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := NowTextPosition.X, Y := NowTextPosition.Y} - vector2{Y := NowLineHeight}, Maximum := vector2{X := NowTextPosition.X, Y := NowTextPosition.Y} - vector2{Y := NowLineHeight}}
                        Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        SizeToContent := true
                        Widget := TextBlock(0)
        
                set NowLineHeight -= if(Value := NowText.LineText[Index].LineHeight). Value else. 0.0
    
            CanvasSlots