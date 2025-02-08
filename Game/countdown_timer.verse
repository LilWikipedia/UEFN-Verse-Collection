using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }
using { /Fortnite.com/UI }

MakeCountdownTimer<constructor><public>(MaxTime : float, InPlayer : agent) := countdown_timer:
    RemainingTime := MaxTime
    MaybePlayerUI := option{GetPlayerUI[player[InPlayer]]} 

countdown_timer := class:
    <# This block runs for each instance of the countdown_timer class.
    We can setup the canvas once here. #>
    block:
        set Canvas = canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors:
                        Minimum := vector2{X := 0.4, Y := 0.3}
                        Maximum := vector2{X := 0.6, Y := 0.3}
                    Alignment := vector2{X := 0.5, Y := 0.5 }
                    Offsets := margin{Top := 0.0, Left := 0.0, Bottom := 0.0, Right := 0.0}
                    SizeToContent := true
                    Widget := RemainingTimeTextBlock 
                canvas_slot:
                    Anchors := anchors:
                        Minimum := vector2{X := 0.4, Y := 0.3}
                        Maximum := vector2{X := 0.6, Y := 0.3}
                    Alignment := vector2{X := 0.0, Y := 1.0}
                    Offsets := margin{Top := 0.0, Right := 0.0}
                    SizeToContent := true
                    Widget := AddedTimeTextBlock

    CountdownEndedEvent<public> : event(float) = event(float){}

    StartCountdown<public>() : void =
        if (PlayerUI := MaybePlayerUI?):
            PlayerUI.AddWidget(Canvas)

            # Update the UI when we start the timer to see the initial RemainingTime on screen
            UpdateUI()
            spawn:
                RunCountdown()

    AddRemainingTime<public>(Time : float) : void =
        set RemainingTime += Time
        # Immediately update UI for better player feedback when time is added.
        UpdateUI()

        # Fire a simple callout to show the time being added.
        spawn:
            AddedTimeCallout(Time)

    MaybePlayerUI<internal> : ?player_ui = false
    var RemainingTime<internal> : float = 0.0
    RemainingTimeTextBlock<private> : text_block = text_block{} 
    AddedTimeTextBlock<private> : text_block = text_block{}
    RemainingTimeText<localizes><private>(CurrentRemainingTime : int) : message = "{CurrentRemainingTime}"
    AddedTimeText<localizes><private>(AddedTime : int) : message = " +{AddedTime}!"
    var Canvas<private> : canvas = canvas{}
    var TotalTime<private> : float = 0.0
    # The timer "precision": how often, in seconds, it ticks.
    TimerTickPeriod<private> : float = 1.0

    RunCountdown<private>()<suspends> : void =
        # We loop with the TimerTickPeriod.
        # The UI is also updated each time.
        loop:
            Sleep(TimerTickPeriod)
            set TotalTime += TimerTickPeriod
            set RemainingTime -= TimerTickPeriod
            UpdateUI()

            # Timer End
            if (RemainingTime <= 0.0):
                
                Canvas.RemoveWidget(RemainingTimeTextBlock)

                 if (UI := MaybePlayerUI?):
                     UI.RemoveWidget(Canvas)

                CountdownEndedEvent.Signal(TotalTime)
                break

    AddedTimeCallout<private>(Time : float)<suspends> : void =
        if:
            PlayerUI := MaybePlayerUI?
            IntTime := Int[Time]
        then:
            AddedTimeTextBlock.SetVisibility(widget_visibility.Visible)
            AddedTimeTextBlock.SetText(AddedTimeText(IntTime))
            Sleep(2.0)
            AddedTimeTextBlock.SetVisibility(widget_visibility.Hidden)
    
    UpdateUI<private>() : void =
        if (IntTime := Int[RemainingTime]):
            RemainingTimeTextBlock.SetText(RemainingTimeText(IntTime))