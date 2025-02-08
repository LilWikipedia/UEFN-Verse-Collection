using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }

using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Random }

using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/UI }

tick_rate_device := class(creative_device):

    TickRateText<localizes><private>(TickRateString : string) : message = {"{TickRateString} TPS"}

    TickRateTextBlock<private> : text_block = text_block:
        DefaultTextColor := NamedColors.White
        DefaultJustification := text_justification.Right
        
    var AverageTickRate : float = 0.0

    GraphMaker<private> : graph_maker = graph_maker {NumBars := 30}
    Canvas<private> : canvas = canvas{}
            
    OnBegin<override>()<suspends>:void =

        GraphMaker.Init()

        LabelSlot := canvas_slot:
            Anchors := anchors:
                Minimum := vector2{X := 1.0, Y := 1.0}
                Maximum := vector2{X := 1.0, Y := 1.0}
            Alignment := vector2{X := 1.0, Y := 1.0 }
            Offsets := margin{Left := -195.0, Top := -8.0}
            Widget := TickRateTextBlock

        GraphSlot := canvas_slot:
            Anchors := anchors:
                Minimum := vector2{X := 1.0, Y := 1.0}
                Maximum := vector2{X := 1.0, Y := 1.0}
            Alignment := vector2{X := 1.0, Y := 1.0 }
            Offsets := margin {Left := -10.0, Top := -10.0, Right := 170.0, Bottom := 40.0}
            SizeToContent := false
            Widget := GraphMaker.Canvas

        Canvas.AddWidget(LabelSlot)
        Canvas.AddWidget(GraphSlot)

        if:
            FirstPlayer := GetPlayspace().GetPlayers()[0]
            PlayerUI := GetPlayerUI[FirstPlayer]
        then:
            PlayerUI.AddWidget(Canvas)

        var PreviousTime : float = GetSimulationElapsedTime()

        loop:
            Sleep(0.0)
            CurrentTime := GetSimulationElapsedTime()
            DeltaTime := CurrentTime - PreviousTime
            set PreviousTime = CurrentTime

            TickRate := 1.0 / DeltaTime
            #TickRate := GetRandomFloat(0.0,30.0) # use this to test the graph

            set AverageTickRate += (TickRate - AverageTickRate) / 3.0 # smooth it out so the text doesn't flicker distractingly as much
            TickRateTextBlock.SetText(TickRateText(GetRoundedString(AverageTickRate,2)))
            
            BarPercent := TickRate/30.0
            GraphMaker.PushValue(BarPercent)

    GetRoundedString<private>(Input : float, NumDigitsAfterDecimal : int) : string =
        if:
            Multiplier := Pow(10.0, NumDigitsAfterDecimal * 1.0)
            RoundedValue := float[Round[Input*Multiplier]*1.0] / Multiplier
            BeforeDecimal := Floor[RoundedValue]
            AfterDecimal := Abs(Round[(RoundedValue - BeforeDecimal*1.0)*Multiplier])
            var AfterDecimalString : string = ToString(AfterDecimal)

            #pad the number after the decimal with leading zeroes
            for (It := 0..(NumDigitsAfterDecimal-AfterDecimalString.Length-1)):
                set AfterDecimalString = array{'0'} + AfterDecimalString
        then:
            "{BeforeDecimal}.{AfterDecimalString}"
        else:
            ToString(Input)
    

graph_maker := class:

    NumBars : int   
    Canvas : canvas = canvas{}

    var ColorBlocks<private> : []color_block = array{}
    var Values : []float = array{}

    BackgroundSlot : canvas_slot = canvas_slot:
        Widget := color_block:
            DefaultColor := NamedColors.White
            DefaultOpacity := 0.3
        Anchors := anchors:
            Minimum := vector2{X := 0.0, Y := 0.0}
            Maximum := vector2{X := 1.0, Y := 1.0}

    Init() : void =
        Canvas.AddWidget(BackgroundSlot)

        for(B := 0..NumBars-1):
            set Values += array {0.0} #default the bar to all zeroes
            set ColorBlocks += array:
                ColorBlock : color_block = color_block:
                    DefaultColor := NamedColors.White
                    DefaultOpacity := 0.8

        RedrawAllBars()

    # shift all the values down by one and then replace the last value
    PushValue(Value : float) : void = 
        for:
            B := 0..NumBars-2
            set Values[B] = Values[B+1]
        do:
            RedrawBar(B)
            
        if(set Values[NumBars-1] = Value) then RedrawBar(NumBars-1) 
        
    
    SetValue(Index : int, Value : float) : void = 
        if (set Values[Index] = Value) then RedrawBar(Index)     
    
    RedrawAllBars() : void = 
        for (B := 0..NumBars-1) do RedrawBar(B)
        
    RedrawBar(Index : int): void = 
        BarWidth := 1.0 / (1.0*NumBars) 
        
        if:
            ColorBlock := ColorBlocks[Index]
            Value := Values[Index]
        then:
            # we do Value*Value for blue so that the transition color tends to be more orange
            ColorBlock.SetColor(color {R := 1.0, G := Lerp(0.0,1.0,Value), B := Lerp(0.0,1.0,Value*Value)})

            # we create a new slot each time because they are immutable and we need to change the anchors
            # and also they are structs so it's a pretty lightweight operation anyway
            NewSlot := canvas_slot: 
                Widget := ColorBlock
                Anchors := anchors:
                    Minimum := vector2{X := Index*BarWidth + 0.0, Y := 1.0-Clamp(Value,0.0,1.0)}
                    Maximum := vector2{X := Index*BarWidth + BarWidth, Y := 1.0}
                SizeToContent := false

            # we need to add a slot, but being re-added also forces the ColorBlock color to actually update
            # the first time we run this, the widget won't actually be on the canvas, but that's fine, RemoveWidget() can't fail
            Canvas.RemoveWidget(ColorBlock)
            Canvas.AddWidget(NewSlot)