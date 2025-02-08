using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters}
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Teams }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters}
using { /UnrealEngine.com/Temporary/UI}
using { /Fortnite.com/UI}
using { /Verse.org/Colors/NamedColors}
using { /Verse.org/Colors}
using { /Verse.org/Random }
using {BeFu}
using{GameManagementHost}


# See _ _ _ for how to build using this verse device.

# A Verse-authored creative device that can be placed in a level

#█▀▀ █▀█ █▀▀ █▀▄ █ ▀█▀ █▀ ▀
#█▄▄ █▀▄ ██▄ █▄▀ █ ░█░ ▄█ ▄


<#  ████████╗░██████╗░█████╗░██████╗░  ░░░░██╗  ████████╗░██████╗░█████╗░██████╗░██████╗░██╗░░░██╗
    ╚══██╔══╝██╔════╝██╔══██╗██╔══██╗  ░░░██╔╝  ╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗╚██╗░██╔╝
    ░░░██║░░░╚█████╗░███████║██████╔╝  ░░██╔╝░  ░░░██║░░░╚█████╗░███████║██████╔╝██████╔╝░╚████╔╝░
    ░░░██║░░░░╚═══██╗██╔══██║██╔══██╗  ░██╔╝░░  ░░░██║░░░░╚═══██╗██╔══██║██╔══██╗██╔══██╗░░╚██╔╝░░
    ░░░██║░░░██████╔╝██║░░██║██║░░██║  ██╔╝░░░  ░░░██║░░░██████╔╝██║░░██║██║░░██║██║░░██║░░░██║░░░
    ░░░╚═╝░░░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝  ╚═╝░░░░  ░░░╚═╝░░░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░
                           Copyright: IN EULA AGREEMENT
                                DO NOT REDISTRIBUTE
                     Youtube Channel: Youtube.com/@TsarShorts                                   #> 
InitializePlayer<public>(Player:player):void=
    for(i := 100..1):
        if:
            not PlayerStatsMap[Player]
            set PlayerStatsMap[Player] = player_stats_table{}
        then:
            Print("initing player")
        else:
            Print("Player had stats setup | FAILED")
 # Return the player_stats_table for the provided Agent.
GetPlayerStats(Agent:agent)<decides><transacts>:player_stats_table=
     var ReturnPlayerStats:player_stats_table = player_stats_table{}
     if:
         Player := player[Agent]
         PlayerStatsTable := PlayerStatsMap[Player]
         set ReturnPlayerStats = MakePlayerStatsTable(PlayerStatsTable)
    ReturnPlayerStats

stat_type := class<computes><unique><abstract>:
    DebugString():string

StatType:=module:
    maingold_stat<public>:=class<computes><unique>(stat_type):
        DebugString<override>():string="Score"
    coindex_stat<public>:=class<computes><unique>(stat_type):
        DebugString<override>():string="Coin Dex"

    MainGold<public>:maingold_stat = maingold_stat{}
    CoinDex<public>:coindex_stat = coindex_stat{}
 # Update the given stat for the given player by creating a new
 # player_stats_table and setting it in the PlayerStatsMap.






# Tracks different persistable stats for each player.
player_stats_table := class<final><persistable>:
    # The version of the current stats table.
    Version:int = 0

    # The MainGold a player reached.
    MainGold:player_stat = player_stat{}

    # Player Associated Curencies
    CoinDex: playercoindex_stat = playercoindex_stat{}

MakePlayerStatsTable<constructor>(OldTable:player_stats_table)<transacts> := player_stats_table:
     Version := OldTable.Version
     MainGold := OldTable.MainGold
     CoinDex := OldTable.CoinDex

var PlayerStatsMap:weak_map(player, player_stats_table) = map{}
 # A persistable stat that persists across play sessions.

playercoindex_stat := class<final><persistable>:
    AssociatedCurrencies: [int]int = map{}

    UpdateMapValue(OldStats:[int]int, CurrencyID:int, CurrencyValue:int)<transacts>:[int]int ={
        var ReturnedStats: [int]int = OldStats
        if(set ReturnedStats[CurrencyID] = CurrencyValue){}
        return ReturnedStats
    }
player_stat := class<final><persistable>:
    # The current value of the player's stat.
    CurrentValue:int = 0

    # The highest value achieved so far.
    HighestValue:int = 0

    SetHighestValue(NewValue:int)<transacts>:int=
        if:
            NewValue > HighestValue
        then:
            NewValue
        else:
            HighestValue
MakeUpdatedPlayerStat<constructor>(OldStats:player_stat, NewValue:int)<transacts>:=player_stat:
    CurrentValue:=NewValue
    HighestValue := OldStats.SetHighestValue(NewValue)
MakeUpdatedASCStat<constructor>(OldStats:playercoindex_stat, CurrencyID:int, CurrencyValue:int)<transacts>:=
    playercoindex_stat:
        AssociatedCurrencies:= OldStats.UpdateMapValue(OldStats.AssociatedCurrencies, CurrencyID, CurrencyValue)


PlayerStats := class<public><unique><concrete>(): #A unique class availible for use on a player by player basis
    var AssociatedCurrencies: [int]int = map{} #Key is the ID, second is the Value.
    var HasCurreny: logic = {false}
    var OwnsBase:logic=false

SessionSavingClass:=class<concrete>():
     @editable var SaveFirstCurrencyValue:logic=true
     @editable var SaveAllCurrencyValues:logic=false

Team:=class<concrete>():
    var Players: []player = array{}
    var Claimed:logic=false
    var Owner: ?player = false
    var CashToClaim:int=0
    AddPlayer(Player:player):void={if(not Players.Find[Player]){set Players += array{Player}}else{Print("This player was already apart of that team")}}
    @editable var TeamName: string = "My New Team"
    @editable Currencies: []string = array{"My Currency"}
    @editable BuyableProps: []BuyItem = array{}
    @editable Damageables: []DamageableClass = array{}
    @editable Sellables: []SellableClass = array{}
    @editable Conveyors: []ConveyerLine = array{}
    @editable Conditionals:[]ConditionalClass=array{}
    @editable BaseSetup: Setup = Setup{}
    @editable Defaults: Default = Default{}
    @editable SessionSavingSettings: SessionSavingClass = SessionSavingClass{}
DamageableClass:=class<concrete>(BuyItem):
    @editable BreakDetector: trigger_device = trigger_device{}
    @editable GrantEvent: item_granter_device = item_granter_device{}
SellableClass:=class<concrete>(BuyItem):
    @editable ConditionalReciept: conditional_button_device = conditional_button_device{}
ConditionalClass:=class<concrete>():
    @editable var Future:string="This is still in development."
DebugOddsClass:=class<concrete>():
    @editable var DebugOccurence:?float={option{95.0}} 
Setup:=struct<concrete>():
    @editable BaseClaimer: volume_device = volume_device{} #Volume that claims the base.
    @editable CashClaimer: volume_device = volume_device{} #Volume that claims the cash.
Default:=struct<concrete>():
    @editable DefaultBuyCurrencyID: int = {1}
    @editable DefaultGrantCurrencyID: int = {1}
    @editable DefaultGrantPerInteval: int = {1}
    @editable DefaultGrantIntveral: float = {1.0}
BuyItemEnumeration:=class<concrete>():
    var Type: Parents = Parents.Prop
    var ConveyorDex: ?ConveyerLine = false
    var SellableDex: ?SellableClass = false
    var DamageableDex: ?DamageableClass = false
BuyItem:=class<concrete><unique>(BuyItemEnumeration):
    var Bought:logic=false
    @editable Name: string = "My Buyable"
    @editable ItemPrice: int = 100
    @editable overrideBuyCurrencyID: ?int = false
    @editable overrideGrantCurrencyID: ?int = false
    @editable overrideGrantPerInteval: ?int = false
    @editable overrideGrantInverval: ?float = false
    @editable Signal: trigger_device = trigger_device{}
    @editable Buyanim: Animations = Animations.EaseDown
    @editable BuyZone: volume_device = volume_device{} #Volume that purchases the item
    @editable VFXAttributes: VFXAttributeClass = VFXAttributeClass{}
    @editable Props: []creative_prop = array{}
    @editable ParentChildMap: []Child = array{Child{ParentType:=Parents.Prop, Children := array{}}}
HudSys:=class<concrete>():
    @editable Slot1:Slot1C=Slot1C{}
    @editable Slot2:Slot2C=Slot2C{}
    @editable Slot3:Slot3C=Slot3C{}


Slot1C:=struct<concrete>():
    @editable Slot1ID:?int=option{1}
    @editable Slot1BC:color=color{R:=256.0, G:=256.0, B:=256.0}
    @editable Slot1TC:color=color{}
    @editable Slot1AC:color=color{}
Slot2C:=struct<concrete>():
    @editable Slot2ID:?int=option{0}
    @editable Slot2BC:color=color{R:=256.0, G:=256.0, B:=256.0}
    @editable Slot2TC:color=color{}
    @editable Slot2AC:color=color{}
Slot3C:=struct<concrete>():
    @editable Slot3ID:?int=option{2}
    @editable Slot3BC:color=color{R:=256.0, G:=256.0, B:=256.0}
    @editable Slot3TC:color=color{}
    @editable Slot3AC:color=color{}
VFXAttributeClass:=class<concrete><public>(){
    @editable var PrePurchaseVFX:[]vfx_spawner_device = array{};
    @editable var OnPurchaseVFX:[]vfx_spawner_device = array{}}
ConveyerLine:=class<concrete><public>(BuyItem):
    @editable var MiniMetersSecondWithNoWeight: float = {100.0} #0.5+(12.5/(0+25))=
    @editable ConveyorType: ConveyorTypeEnum = ConveyorTypeEnum.TickVary_Based_spawn
    # ADD END OF CONVEYOR OFFSET

    var PlankList: []creative_prop = array{}
    var StartConveyor : vector3 = vector3{}
    @editable Droppers: []DropperItem = array{}
    @editable var EndConveyor : vector3 = vector3{}
ConveyorTypeEnum:=enum:
    TickVary_Based_spawn
    Concurrency_Based_spawn
    OAA_NEGTOPOSXONLY
    Lerp_NEGTOPOSXONLY
CoordinateType:=enum:
    X_Coordinate_RangefNo
    Y_Coordinate_Range
AbsoulteDirectionEnum:=enum:
    Negative_To_Positive
    Positive_To_Negative

DropperItem:=class<concrete><unique><public>(BuyItem):

    @editable DroppedPropONCONVEYOR: creative_prop = creative_prop{}
    @editable DroppedPropSpawnEndPoint: creative_prop_asset = DefaultCreativePropAsset
    @editable Weight_Lbs: float = 100.0
    @editable StartHeight:float=50.0
    @editable DropInterval: float = 10.0
    @editable CashOnExit: int = 0
    @editable CashOnExitID: int = 0
    var DroppedPropResetLocation:vector3 = vector3{}
    var IsActive:logic=false
    
    
Child:=class<concrete>():
    @editable ParentType:Parents = Parents.Prop
    @editable DropperParentConveyorIDs: []?int = array{}
    @editable Children: []int = array{}
    
Parents:=enum:
    Prop
    Dropper
    Computer
    Conveyor
    Damageable
    Sellable
Currency:=struct<concrete>():
    @editable Currencylist: []string = array{"My Currency"}
Animations:=enum:
    EaseDown
