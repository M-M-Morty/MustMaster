--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")

---@class ANS_BeamEffect
local M = Class()

-- function M:Received_NotifyBegin(MeshComp, Animation, TotalDuration)
-- end

function M:Received_NotifyTick(MeshComp, Animation, FrameDeltaTime)
    local NiagaraComponent = self:GetSpawnedEffect(MeshComp)
    --G.log:debug("hycoldrain", "ANS_BeamEffect Received_NotifyTick  %s  %s", tostring(MeshComp), tostring(NiagaraComponent))
    if NiagaraComponent and NiagaraComponent:IsValid() then
        local SocketLocation = MeshComp:GetSocketLocation(self.SName)
        local Xoffset = UE.UKismetMathLibrary.RandomFloatInRange(0.0 - self.RandomValue, self.RandomValue)
        local Yoffset = UE.UKismetMathLibrary.RandomFloatInRange(0.0 - self.RandomValue, self.RandomValue)
        SocketLocation.X = SocketLocation.X + Xoffset
        SocketLocation.Y = SocketLocation.Y + Yoffset
        NiagaraComponent:SetVariableVec3(self.NiagaraVaiableName, SocketLocation)

       --if self.Debugline then
       --    local DebugLocation = MeshComp:GetSocketLocation("thumb_02_l")
       --    UE.UKismetSystemLibrary.DrawDebugline(MeshComp, DebugLocation, SocketLocation, UE.FLinearColor(1.0, 0.0, 0.0), 0.5, 1.0)
       --end
    end
    return true
end

-- function M:Received_NotifyEnd(MeshComp, Animation)
-- end

return M