require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_PlayAnim = Class(BTTask_Base)


function BTTask_PlayAnim:Execute(Controller, Pawn)
    Pawn.LocomotionComponent:Server_PlayMontage(self.Montage, self.PlayRate)
    Pawn.LocomotionComponent:Server_MontageJumpToSection(self.SectionName, self.Montage)

    if self.MaxPlayDuration > 0.000001 then
        utils.DoDelay(Pawn, self.MaxPlayDuration, function() self.bMontagePlayEnd = true end)
    end
end

function BTTask_PlayAnim:Tick(Controller, Pawn, DeltaSeconds)
    local AnimInstance = Pawn.Mesh:GetAnimInstance()
    if not AnimInstance:Montage_IsPlaying(self.Montage) then
        return ai_utils.BTTask_Succeeded
    end

    if self.bMontagePlayEnd then
        if self.bStopMontage then
            Pawn.LocomotionComponent:Server_StopMontage(self.Montage, 0.5)
        end
        self.bMontagePlayEnd = false
        return ai_utils.BTTask_Succeeded
    end
end

function BTTask_PlayAnim:OnSwitch(Controller, Pawn)
    Pawn.LocomotionComponent:Server_StopMontage(self.Montage, 0.5)
end

return BTTask_PlayAnim
