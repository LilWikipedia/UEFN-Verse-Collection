# Maps - https://dev.epicgames.com/documentation/en-us/uefn/map-in-verse

# Declaration
WordCount : [string]int = map{"apple" => 0, "apple" => 1, "apple" => 2};
var CanvasMap:[player]canvas = map{};

# Adding an item to a map
set CanvasMap = ConcatenateMaps(CanvasMap, map{Player => Canvas});

# Recall
if (Canvas := CanvasMap[Player]):
    PlayerUI.RemoveWidget(Canvas);

# Removes an element from the given map and returns a new map without that element
RemoveKeyFromMap(ExampleMap:[player]canvas, ElementToRemove:player):[player]canvas=
    var NewMap:[player]canvas = map{}
# Concatenate Keys from ExampleMap into NewMap, excluding ElementToRemove
    for (Key -> Value : ExampleMap, Key <> ElementToRemove):
        set NewMap = ConcatenateMaps(NewMap, map{Key => Value})
    return NewMap

# Alternative Usage

RemoveKeyFromMap(ExampleMap:[string]int, ElementToRemove:string):[string]int=
    var NewMap:[string]int = map{}
# Concatenate Keys from ExampleMap into NewMap, excluding ElementToRemove
    for (Key -> Value : ExampleMap, Key <> ElementToRemove):
        set NewMap = ConcatenateMaps(NewMap, map{Key => Value})
    return NewMap
