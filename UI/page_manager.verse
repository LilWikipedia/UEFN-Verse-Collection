# by appiemasterr
# https://x.com/appiemasterr


using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors/NamedColors }
using { /Verse.org/Colors }

# Converts string to message
StringToMessage<localizes>(S : string) : message = "{S}"

page_manager := class(creative_device):

    # Button for creating user interface
    @editable
    CreateUIBtn : button_device = button_device{}

    # Array that contains all pages
    @editable
    AllPages : []tutorial_page = array{}

    OnBegin<override>()<suspends>:void=
        # spawning async func, so it runs in the background
        spawn{AwaitCreatePageUIButtonPress()}

    # Waiting for button press
    AwaitCreatePageUIButtonPress()<suspends>:void=
        # Looping everytime button gets pressed
        loop:
            Agent := CreateUIBtn.InteractedWithEvent.Await()
            # Creating instance of the system
            PageSystemIntance := page_system{AllPages := AllPages}
            PageSystemIntance.Init()
            # Creating UI for the player
            PageSystemIntance.CreatePageUI(Agent)

page_system := class:

    AllPages : []tutorial_page = array{}

    var ButtonForPage : [text_button_base]overlay = map{}

    var CurrentPageShown : overlay = overlay{}

    CloseMessage<localizes>:message = "❌"

    var MaybePageCanvas : ?canvas = false

    SpacingAroundButtons : float = 50.0

    Init():void=
        # Looping through all pages and making a button for each of them and making that button the key inside of a map.
        for(Page : AllPages):
            Button := button_regular{}
            Button.SetText(StringToMessage(Page.PageTitle))
            Button.OnClick().Subscribe(OnPageClick)
            PageOverlay := Page.MakePage()
            if(set ButtonForPage[Button] = PageOverlay){}   

    # When someone navigates to another page, this method gets fired
    OnPageClick(WM : widget_message):void=
        # Hiding old page
        CurrentPageShown.SetVisibility(widget_visibility.Collapsed)
        if(PageToShow := ButtonForPage[WM.Source]):
            # Showing new page
            PageToShow.SetVisibility(widget_visibility.Visible)
            set CurrentPageShown = PageToShow
            

    # Creating UI
    CreatePageUI(Agent : agent):void=
        if(PlayerUI := GetPlayerUI[player[Agent]]):
            PageCanvas := GetPageCanvas()
            # Making it visible first so it appears quicker (doesnt work idk why )
            PageCanvas.SetVisibility(widget_visibility.Hidden)
            PageCanvas.SetVisibility(widget_visibility.Visible)
            PlayerUI.AddWidget(GetPageCanvas(), player_ui_slot{InputMode := ui_input_mode.All})

    # Removing UI
    RemoveUI(WM : widget_message):void=
        if(PlayerUI := GetPlayerUI[WM.Player], PageCanvas := MaybePageCanvas?):
            # Making it invisible first so it appears quicker
            PageCanvas.SetVisibility(widget_visibility.Hidden)
            PlayerUI.RemoveWidget(PageCanvas)


    # Making canvas
    GetPageCanvas():canvas=
        CloseButton : button_loud = button_loud{DefaultText := CloseMessage}
        CloseButton.OnClick().Subscribe(RemoveUI)
        # All navigation buttons will be put inside of here
        AllButtonStackbox := stack_box{Orientation := orientation.Vertical}
        # Adding all buttons to the stackbox with some spacing above and below
        for(Button -> PageOverlay : ButtonForPage):
            AllButtonStackbox.AddWidget(
                stack_box_slot:
                    Widget := Button
                    Padding := margin{Top := 10.0, Bottom := 10.0}
            )
        # Overlay that contains the nav button stackbox and other markup
        AllButtonsOverlay := overlay:
            Slots := array:
                overlay_slot:
                    Widget := color_block{DefaultColor := MakeColorFromHex("A795FFFF")}
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                overlay_slot:
                    Widget := AllButtonStackbox
                    Padding := margin{Top := SpacingAroundButtons, Right := SpacingAroundButtons, Left := SpacingAroundButtons, Bottom:= SpacingAroundButtons}
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                overlay_slot:
                    Widget := color_block{DefaultColor := White, DefaultDesiredSize := vector2{X := 2.086804, Y := 773.735352}}
                    HorizontalAlignment := horizontal_alignment.Right
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Right := -200.0}
        # Overlay that contains everything on the ui, hence the name
        WrapperOverlay := overlay:
            Slots := array:
                overlay_slot:
                    Widget := color_block{DefaultColor := MakeColorFromHex("0C272BFF")}
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                overlay_slot:
                    Widget :=AllButtonsOverlay
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 150.0}
                overlay_slot:
                    Widget :=CloseButton
                    HorizontalAlignment := horizontal_alignment.Right
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Top := 10.0, Right := 10.0}
        # Adding all the pages beforehand, and then collapsing them
        for(SinglePage : ButtonForPage):
            SinglePage.SetVisibility(widget_visibility.Collapsed)
            WrapperOverlay.AddWidget(
                overlay_slot:
                    Widget := SinglePage
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 250.0}
            )
        # Showing the first page only
        if(FirstPage := AllPages[0].CurrentPage):
            set CurrentPageShown = FirstPage
            FirstPage.SetVisibility(widget_visibility.Visible)
        Canvas := canvas:
            Slots := array:
                canvas_slot:
                    Widget := WrapperOverlay
                    # Making the overlay wrap the entire screen
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X:= 1.0, Y := 1.0}}
        set MaybePageCanvas = option{Canvas}
        return Canvas


# Singular page
page := interface:
    Init():void
    MakePage():overlay

tutorial_page := class<concrete>(page):

    @editable
    PageTitle : string = ""

    @editable
    AllSentences : []string = array{}

    @editable
    Backgroundcolor : color = color{}

    var CurrentPage : overlay = overlay{}

    Init<override>():void= return

    # Makes a page with the information that was given when constructing the object
    MakePage<override>():overlay=
        #  a vertical stackbox containing all the sentences, then looping through the sentences and adding them to the stackbox
        SentencesStackbox := stack_box{Orientation := orientation.Vertical}
        for(Sentence : AllSentences):
            SentencesStackbox.AddWidget(
                stack_box_slot:
                    Widget := text_block{DefaultText := StringToMessage(Sentence), DefaultTextColor := White}
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Bottom := 2.0}
                )
        ThePage := overlay:
            Slots := array:
                overlay_slot:
                    Widget := color_block{DefaultColor := Backgroundcolor}
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                overlay_slot:
                    Widget := SentencesStackbox
                    Padding := margin{Top := 78.0, Right := 78.0, Left := 78.0, Bottom:= 78.0}
        set CurrentPage = ThePage
        return ThePage
