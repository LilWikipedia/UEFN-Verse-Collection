# Arrays
# https://dev.epicgames.com/documentation/en-us/uefn/array-in-verse
# https://forums.unrealengine.com/t/how-to-remove-an-item-at-index-from-an-array-in-verse/833744

# Adding an item to an array
set SideChestsPositions += array{Position};


# Go over an array
for (Index -> Spawner : CreatureSpawners):
# do something with Spawner
    Spawner.Disable();
for (Spawner : CreatureSpawners):
    Spawner.Disable();

# Get a random element from an array
Index := GetRandomInt(0, CreatureSpawners.Length);

# Remove element form array
var MyDeviceArray:[]creative_device = array{}

if (NewArray := MyDeviceArray.RemoveElement[0]):
    set MyDeviceArray = NewArray