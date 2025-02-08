<#
https://forums.unrealengine.com/t/quick-way-to-display-text-to-players-screen-from-verse-script/831948
#>

using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI}

dynamic_text_device := class(creative_device):    

    var _myIntValue:int = 0
    var _textWiget: text_block = text_block{DefaultTextColor:= color{R:=1.0, G:=1.0, B:=1.0}}

    OnBegin<override>()<suspends>:void=
        # set UI on a player
        var players:[]player = Self.GetPlayspace().GetPlayers()
        if (ValidPlayer := players[0]):
            AddUIToPlayer(ValidPlayer)

        Sleep(5.0)

        # change values, update UI
        set _myIntValue = 12345
        UpdateUI()

    AddUIToPlayer(Player:agent):void=
        if (PlayerUI := GetPlayerUI[player[Player]]):
            PlayerUI.AddWidget(CreateUI())

    CreateUI() : canvas =        
        UpdateUI()
        # align top center of screen
        ui : canvas = canvas:
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.0}, Maximum := vector2{X := 0.5, Y := 0.0} }
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.0}
                    SizeToContent := true
                    Widget := _textWiget

        return ui

    UpdateUI():void=
        _textWiget.SetText(SetDynamicText(_myIntValue))

    SetDynamicText<localizes>(IntValue:int) : message = "Dynamic text {IntValue}";