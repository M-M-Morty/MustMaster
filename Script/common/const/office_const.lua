local _M = {}

-- 临时数据
_M.OfficeWalkInLocation = UE.FVector(50.0, 0.0, 0.0)
_M.OfficeWalkInRotation = UE.UKismetMathLibrary.MakeRotator(0, 0, 0)

-- 临时数据
_M.OfficeWalkOutLocation = UE.FVector(-1820, -677, 91)
_M.OfficeWalkOutRotation = UE.UKismetMathLibrary.MakeRotator(0, 0, 68)

_M.OfficeTeleportPointActorID = 20062001

return _M