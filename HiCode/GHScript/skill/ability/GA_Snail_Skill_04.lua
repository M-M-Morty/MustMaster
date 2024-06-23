--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local GA_GH_CommonBase = require('CP0032305_GH.Script.skill.ability.GA_GH_CommonBase')

---@type GA_Snail_Skill_04_C
local GA_Snail_Skill_04_C = Class(GA_GH_CommonBase)

function GA_Snail_Skill_04_C:StartAction()
    self.move_stoped = false
    self.start_action_time = UE.UGameplayStatics.GetTimeSeconds(self)
end
function GA_Snail_Skill_04_C:TickAction()
    if self.move_stoped then
        return
    end

    local selfActor = self:GetAvatarActorFromActorInfo()
    local tarActor = self.skillTarget
    local selfRotation = selfActor:K2_GetActorRotation()
    local lookAt = self:GetAvatarLookat(selfActor, tarActor)
    local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(selfRotation, lookAt)
    local current = UE.UGameplayStatics.GetTimeSeconds(self)
    if math.abs(deltaRot.Yaw) < self.DELTA_STOP or current - self.start_action_time > self.ACTION_TIMEOUT then
        self:EndAction()

        local tag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.Common.a')
        local Payload = UE.FGameplayEventData()
        Payload.EventTag = tag
        Payload.Instigator = selfActor
        self:SendGameplayEvent(tag, Payload)
    else
        local selfYaw = selfRotation.Yaw
        local tarYaw = lookAt.Yaw
        selfRotation.Yaw = UE.UKismetMathLibrary.ClampAngle(tarYaw, selfYaw - self.DELTA_TICK, selfYaw + self.DELTA_TICK)
        selfActor:K2_SetActorRotation(selfRotation, true)
    end
end
function GA_Snail_Skill_04_C:EndAction()
    if self.move_stoped then
        return
    end
    self.move_stoped = true
end

--重写这个方法，改为背向方式
function GA_Snail_Skill_04_C:GetAvatarLookat(selfActor, tarActor)
    return UE.UKismetMathLibrary.FindLookAtRotation(tarActor:K2_GetActorLocation(), selfActor:K2_GetActorLocation())
end


return GA_Snail_Skill_04_C

