--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local GA_GH_CommonBase = require('CP0032305_GH.Script.skill.ability.GA_GH_CommonBase')

---@type GA_Snail_Skill_Turret_C
local GA_Snail_Skill_Turret_C = Class(GA_GH_CommonBase)


function GA_Snail_Skill_Turret_C:GetPlayload(Payload)
    if not Payload then
        return
    end
    local tarActor = Payload.Target or self:GetSkillTarget()
    local count
    if Payload.OptionalObject then
        count = tonumber(Payload.OptionalObject.FireCount)
    end
    if count and count > 0 then
        self.TotalLoopCount = count
    else
        self.TotalLoopCount = self:GetClass():GetDefaultObject().TotalLoopCount
    end
    self:SetTurretTarget(tarActor)
    self.CurrentLoopCount = 0
end

function GA_Snail_Skill_Turret_C:SetTurretTarget(tarActor)
    if not tarActor then
        return
    end
    local selfActor = self:GetAvatarActorFromActorInfo()
    selfActor:SetTurretYawTar(tarActor)
    selfActor:SetTurretReachCB(function() self:ApplyFire() end)
end
function GA_Snail_Skill_Turret_C:ResetTurret()
    local selfActor = self:GetAvatarActorFromActorInfo()
    selfActor:SetTurretYawTar(0)
    selfActor:SetTurretReachCB(nil)
end
function GA_Snail_Skill_Turret_C:ApplyFire()
    local selfActor = self:GetAvatarActorFromActorInfo()
    local tag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.Ability.Turret.start')
    local Payload = UE.FGameplayEventData()
    Payload.EventTag = tag
    Payload.Instigator = selfActor
    UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(selfActor, tag, Payload)
end

function GA_Snail_Skill_Turret_C:K2_OnEndAbility(bWasCancelled)
    Super(GA_Snail_Skill_Turret_C).K2_OnEndAbility(self, bWasCancelled)
    self.Overridden.K2_OnEndAbility(self, bWasCancelled)
end

return GA_Snail_Skill_Turret_C

