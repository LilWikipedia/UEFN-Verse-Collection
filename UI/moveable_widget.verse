<#
    Made By PiEqualsThree 
    Subscribe to my channel or something idk 
    Youtube: https://www.youtube.com/channel/UCNkQPxZ4bhkIKaYWFpC1bSg
    Twitter: https://twitter.com/PiEqualsThreeVP
#>

using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }

moveable_widget := class<unique>:
    var<private> XStackBox : stack_box
    var<private> YStackBox : stack_box
    var<private> XBlock : color_block
    var<private> YBlock : color_block
    var<private> MoveableWidget : widget
    var<private> Size : vector2
    var<private> XPos<private> : int = 0
    var<private> YPos<private> : int = 0
    
    GetRootWidget<public>()<transacts> : stack_box = YStackBox
    # The widget that moves i.e. your image
    GetMovingWidget<public>()<transacts> : widget = MoveableWidget

    Hide<public>() : void =
        MoveableWidget.SetVisibility(widget_visibility.Hidden)

    Show<public>() : void =
        MoveableWidget.SetVisibility(widget_visibility.Visible)

    MoveX<public>(Units : int) : void =
        UnitsFloat : float = 1.0 * Units
        XBlock.SetDesiredSize(vector2{ X := XBlock.GetDesiredSize().X + UnitsFloat, Y := XBlock.GetDesiredSize().Y})
        set XPos += Units
        
    MoveY<public>(Units : int) : void =
        UnitsFloat : float = 1.0 * Units
        YBlock.SetDesiredSize(vector2{ X := YBlock.GetDesiredSize().X, Y := YBlock.GetDesiredSize().Y + UnitsFloat})
        set YPos += Units

    SetX<public>(In_XPos : int) : void =
        XBlock.SetDesiredSize(vector2{ X := 1.0 * In_XPos, Y := XBlock.GetDesiredSize().Y})
        set XPos = In_XPos

    SetY<public>(In_YPos : int) : void =
        YBlock.SetDesiredSize(vector2{ X := YBlock.GetDesiredSize().X, Y := 1.0 * In_YPos})
        set YPos = In_YPos

    SetTexture<public>(NewImage : texture) : void =
        if ( TextureBlock := texture_block[MoveableWidget]) then TextureBlock.SetImage(NewImage)

    SetOpacity<public>(InOpacity : float) : void =
        if ( TextureBlock := texture_block[MoveableWidget]) then TextureBlock.SetTint(color{})

    GetXPos<public>()<transacts> : int = XPos
    GetYPos<public>()<transacts> : int = YPos
    GetSize<public>()<transacts> : vector2i = vector2i{ X := Floor[Size.X] or 0, Y := Floor[Size.Y] or 0}

BuildMoveableWidget(MovingWidget : widget, WidgetSize : vector2, ?DebugMode : logic = false)<transacts> : moveable_widget =
    XBlock : color_block = color_block{ DefaultOpacity := DebugMode? and 0.5 or 0.0, DefaultDesiredSize := vector2{}, DefaultColor := NamedColors.Red}
    YBlock : color_block = color_block{ DefaultOpacity := DebugMode? and 0.5 or 0.0, DefaultDesiredSize := vector2{}, DefaultColor := NamedColors.Blue}
    XStackBox : stack_box = stack_box:
        Orientation := orientation.Horizontal
        Slots := array:
            stack_box_slot{ Widget := XBlock, HorizontalAlignment := horizontal_alignment.Left, VerticalAlignment := vertical_alignment.Fill }
            stack_box_slot{ Widget := MovingWidget}
    YStackBox : stack_box = stack_box:
        Orientation := orientation.Vertical
        Slots := array:
            stack_box_slot{ Widget := YBlock, VerticalAlignment := vertical_alignment.Top, HorizontalAlignment := horizontal_alignment.Fill }
            stack_box_slot{ Widget := XStackBox}

    return moveable_widget:
        XStackBox := XStackBox
        YStackBox := YStackBox
        XBlock := XBlock
        YBlock := YBlock
        MoveableWidget := MovingWidget
        Size := WidgetSize

BuildMoveableTextureWidget(Image : texture, Size : vector2, ?DebugMode : logic = false)<transacts> : moveable_widget =
    TextureBlock := texture_block{ DefaultImage := Image, DefaultDesiredSize := Size}
    XBlock : color_block = color_block{ DefaultOpacity := DebugMode? and 0.5 or 0.0, DefaultDesiredSize := vector2{}, DefaultColor := NamedColors.Red}
    YBlock : color_block = color_block{ DefaultOpacity := DebugMode? and 0.5 or 0.0, DefaultDesiredSize := vector2{}, DefaultColor := NamedColors.Blue}
    XStackBox : stack_box = stack_box:
        Orientation := orientation.Horizontal
        Slots := array:
            stack_box_slot{ Widget := XBlock, HorizontalAlignment := horizontal_alignment.Left, VerticalAlignment := vertical_alignment.Fill }
            stack_box_slot{ Widget := TextureBlock}
    YStackBox : stack_box = stack_box:
        Orientation := orientation.Vertical
        Slots := array:
            stack_box_slot{ Widget := YBlock, VerticalAlignment := vertical_alignment.Top, HorizontalAlignment := horizontal_alignment.Fill }
            stack_box_slot{ Widget := XStackBox}

    return moveable_widget:
        XStackBox := XStackBox
        YStackBox := YStackBox
        XBlock := XBlock
        YBlock := YBlock
        MoveableWidget := TextureBlock
        Size := Size
