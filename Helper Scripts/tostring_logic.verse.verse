(Value : logic).ToString<public>() : string =
  if (Value?):
      return "true"
  return "false"

# usage

IsVisible := false
Print("{IsVisible.ToString()}")