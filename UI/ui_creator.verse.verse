
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/UI }

#Twitter PeterGGs

#Use these functions to help create a UI system without as much work
#If you want to change the button type just replace it in the MakeButton canvas functions 
#Also create buttons of that type

#Credit to Cleverlike Studios for the example of how to place buttons 

ui_creator_device := class(creative_device):

    var MaybeMyUIPerPlayer:[player]?canvas = map{}

    OnBegin<override>()<suspends>:void=
        AllPlayers := GetPlayspace().GetPlayers() #gets an array of all players in the game
        for (PlayerInGame : AllPlayers): #loops through the array to apply the canvas to everyone
            Show1stCanvasPlayer(PlayerInGame) #How to show the first canvas

    
    Show1stCanvasPlayer(Player:player):void= #Shows the first canvas from a player
        RemoveCanvasPlayer(Player)
        NewCanvas := MakeCanvas1st()
        SetCanvas(NewCanvas, Player)

    Show1stCanvasTupple(tup:widget_message):void= #Shows the first canvas from a button click
        Player := tup.Player #Extracts the player from the widget_message
        RemoveCanvasPlayer(Player) #Removes the canvas
        NewCanvas := MakeCanvas1st() #Creates the canvas
        SetCanvas(NewCanvas, Player) #Applies the canvas to the player

    Button1stText1<localizes> : message = "Show 2nd Canvas" #How you set the text in a button
    Button1stText2<localizes> : message = "Exit"
    MakeCanvas1st():canvas= #function to create the 1st canvas
        Button1 := button_loud{DefaultText := Button1stText1} #How you apply the text and create a button
        Button2 := button_loud{DefaultText := Button1stText2}
        Button1.OnClick().Subscribe(Show2ndCanvas) #How you subscribe the button to trigger something
        Button2.OnClick().Subscribe(RemoveCanvasTupple) #This removes the canvas when button is clicked
        NewCanvas := Make2buttonCanvas(Button1, Button2) #Makes a 2 button canvas
        return NewCanvas

    Show2ndCanvas(tup:widget_message):void= #Shows the 2nd canvas from a button click
        Player := tup.Player
        RemoveCanvasPlayer(Player)
        NewCanvas := MakeCanvas2nd()
        SetCanvas(NewCanvas, Player)

    Button2ndText1<localizes> : message = "Show 1st Canvas"
    MakeCanvas2nd():canvas=
        Button1 := button_loud{DefaultText := Button2ndText1}
        Button1.OnClick().Subscribe(Show1stCanvasTupple) #Switches the canvas back to the 1st canvas
        NewCanvas := Make1buttonCanvas(Button1)
        return NewCanvas

    SetCanvas(NewCanvas:canvas, Player:player):void= #This function applies the canvas to the player
        if (PlayerUI := GetPlayerUI[Player]):
            if (MyUI := MaybeMyUIPerPlayer[Player]?):
                PlayerUI.RemoveWidget(MyUI)
                if (set MaybeMyUIPerPlayer[Player] = option{NewCanvas}) {}
            else:
                PlayerUI.AddWidget(NewCanvas, player_ui_slot{InputMode := ui_input_mode.All})
                if (set MaybeMyUIPerPlayer[Player] = option{NewCanvas}) {}
    
    Make1buttonCanvas(Button:button_loud):canvas=
        NewCanvas : canvas = canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.7}, Maximum:= vector2{X:=0.5, Y:=0.7} }
                    Offsets := margin{ Top:=0.0, Left:=0.0, Right:=0.0, Bottom := 0.0 }
                    Alignment := vector2{X:=0.5, Y:=0.5}
                    Widget := Button
        return NewCanvas

    Make2buttonCanvas(Button1:button_loud, Button2:button_loud):canvas=
        NewCanvas : canvas = canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.33, Y := 0.7}, Maximum:= vector2{X:=0.33, Y:=0.7} }
                    Offsets := margin{ Top:=0.0, Left:=0.0, Right:=0.0, Bottom := 0.0 }
                    Alignment := vector2{X:=0.5, Y:=0.5}
                    Widget := Button1
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.66, Y := 0.7}, Maximum:= vector2{X:=0.66, Y:=0.7} }
                    Offsets := margin{ Top:=0.0, Left:=0.0, Right:=0.0, Bottom := 0.0 }
                    Alignment := vector2{X:=0.5, Y:=0.5}
                    Widget := Button2
        return NewCanvas

    Make3buttonCanvas(Button1:button_loud, Button2:button_loud, Button3:button_loud):canvas=
        NewCanvas : canvas = canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.17, Y := 0.7}, Maximum:= vector2{X:=0.17, Y:=0.7} }
                    Offsets := margin{ Top:=0.0, Left:=0.0, Right:=0.0, Bottom := 0.0 }
                    Alignment := vector2{X:=0.5, Y:=0.5}
                    Widget := Button1
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.7}, Maximum:= vector2{X:=0.5, Y:=0.7} }
                    Offsets := margin{ Top:=0.0, Left:=0.0, Right:=0.0, Bottom := 0.0 }
                    Alignment := vector2{X:=0.5, Y:=0.5}
                    Widget := Button2
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.83, Y := 0.7}, Maximum:= vector2{X:=0.83, Y:=0.7} }
                    Offsets := margin{ Top:=0.0, Left:=0.0, Right:=0.0, Bottom := 0.0 }
                    Alignment := vector2{X:=0.5, Y:=0.5}
                    Widget := Button3
        return NewCanvas

    Make4buttonCanvas(Button1:button_loud, Button2:button_loud, Button3:button_loud, Button4:button_loud):canvas=
        NewCanvas : canvas = canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.17, Y := 0.5}, Maximum:= vector2{X:=0.17, Y:=0.5} }
                    Offsets := margin{ Top:=0.0, Left:=0.0, Right:=0.0, Bottom := 0.0 }
                    Alignment := vector2{X:=0.5, Y:=0.5}
                    Widget := Button1
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum:= vector2{X:=0.5, Y:=0.5} }
                    Offsets := margin{ Top:=0.0, Left:=0.0, Right:=0.0, Bottom := 0.0 }
                    Alignment := vector2{X:=0.5, Y:=0.5}
                    Widget := Button2
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.83, Y := 0.5}, Maximum:= vector2{X:=0.83, Y:=0.5} }
                    Offsets := margin{ Top:=0.0, Left:=0.0, Right:=0.0, Bottom := 0.0 }
                    Alignment := vector2{X:=0.5, Y:=0.5}
                    Widget := Button3
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.7}, Maximum:= vector2{X:=0.5, Y:=0.7} }
                    Offsets := margin{ Top:=0.0, Left:=0.0, Right:=0.0, Bottom := 0.0 }
                    Alignment := vector2{X:=0.5, Y:=0.5}
                    Widget := Button4
        return NewCanvas
    
    RemoveCanvasTupple(tup:widget_message):void= #removes the canvas on button click
        Player := tup.Player
        if (TmpPlayerUI := GetPlayerUI[player[Player]], TmpCanvas := MaybeMyUIPerPlayer[Player]?):
            TmpPlayerUI.RemoveWidget(TmpCanvas)
            if (set MaybeMyUIPerPlayer[player[Player]] = false):

    RemoveCanvasPlayer(Player:player):void= #removes the canvas from triggering player
        if (TmpPlayerUI := GetPlayerUI[player[Player]], TmpCanvas := MaybeMyUIPerPlayer[Player]?):
            TmpPlayerUI.RemoveWidget(TmpCanvas)
            if (set MaybeMyUIPerPlayer[player[Player]] = false):