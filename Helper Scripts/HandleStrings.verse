# Strings


(Value : logic).ToString<public>() : string =
    if (Value?):
        return "true"
    return "false"

(Value: string).ToMessage<localizes>() : message = "{Value}"

(Translation:vector3).ToString<public>():string = 
    return "V3 ~ X: {Translation.X}, Y: {Translation.Y}, Z: {Translation.Z}"

(Rotation:rotation).ToString<public>():string = 
    return "Rot2V3: {Rotation.GetAxis()}"

(Transform:transform).ToString<public>():string = 
    return "Transform ~ Translation: {Transform.Translation.ToString()}, Rotation: {Transform.Rotation.ToString()}, Scale: {Transform.Scale.ToString()}"

MakeMessageFromString<localizes>(Text: string): message = "{Text}"

# Returns Number converted to a string, truncated to Decimals places.
ToTruncatedString<public>(Number:float, Decimals:int):[]char=
    var Str:[]char = ToString(Number)
    if:
        DotIndex := Str.Find['.']
        StopIndex := if (Decimals > 0) then Min(DotIndex+Decimals+1,Str.Length) else DotIndex
        Tmp := Str.Slice[0, StopIndex] 
        set Str = Tmp
    Str