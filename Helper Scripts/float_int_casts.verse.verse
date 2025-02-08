Float(Number : int)<varies>:float=
  return Number * 1.0

operator'+'(I:int, F:float):float=
  return I * 1.0 + F

operator'+'(F:float, I:int):float=
  return F + I * 1.0

operator'-'(I:int, F:float):float=
  return I * 1.0 - F

operator'-'(F:float, I:int):float=
  return F - I * 1.0

operator'/'(I:int, F:float):float=
  return I * 1.0 / F

operator'/'(F:float, I:int):float=
  return F / (I * 1.0)