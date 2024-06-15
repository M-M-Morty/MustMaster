-- Multi stage ga, first ga trigger qte buff, then trigger second ga.

local G = require("G")
local GAPlayerBase = require("skill.ability.GAPlayerBase")

local GAMultiStage = Class(GAPlayerBase)

function GAMultiStage:Initialize()
    self.bOnLandRegistered = false

    self.__TAG__ = string.format("(%s)", G.GetObjectName(self))
end

function GAMultiStage:K2_ActivateAbility()
    Super(GAMultiStage).K2_ActivateAbility(self)

    self:SetDisabled(true)

    if not self.bOnLandRegistered then
        self.OwnerActor.SkillComponent:RegisterOnLandCallback(self, self.OnLand)
        self.bOnLandRegistered = true
    end
end

--- Get current stage of ability
---@return (boolean, number) -- (bHasBuff, SkillID)
function GAMultiStage:GetCurrentStageAbility()
    local bCanTrigger, BuffAbilityID, BuffTag = self:CanTriggerBuffAbility(self.BuffTag)
    return bCanTrigger, BuffAbilityID
end

function GAMultiStage:GetTriggerBuffLeftTimeAndDuration()
    return self:GetTriggerBuffAbilityRemainingAndDuration(self.BuffTag)
end

function GAMultiStage:OnBuffRemoved(Tag)
    if not UE.UBlueprintGameplayTagLibrary.EqualEqual_GameplayTag(Tag, self.BuffTag) then
        return
    end

    G.log:debug(self.__TAG__, "OnBuffRemoved")
    self:BeginCD()
end

function GAMultiStage:OnLand()
    G.log:debug(self.__TAG__, "OnLand")
    -- local OwnerActor = self:GetAvatarActorFromActorInfo()
    -- local ASC = G.GetHiAbilitySystemComponent(OwnerActor)

    -- local Tags = UE.FGameplayTagContainer()
    -- Tags.GameplayTags:Add(self.BuffTag)
    -- ASC:RemoveActiveEffectsWithTags(Tags)
end

function GAMultiStage:BeginCD()
    self:SetDisabled(false)
    local IsServer =self:IsServer()
    G.log:debug(self.__TAG__, "GAMultiStage %s ResetCD, IsServer: %s.", G.GetDisplayName(self), IsServer)
    self:ResetCD()
end

function GAMultiStage:ResetCD()
    --self:K2_CommitAbilityCooldown(false, true)
    self:ResetAbilityCD()
end

function GAMultiStage:HandleEndAbility(bWasCancelled)
    Super(GAMultiStage).HandleEndAbility(self, bWasCancelled)

    self:SetDisabled(false)
end

function GAMultiStage:CanCalc()
    return self:K2_HasAuthority()
end

return GAMultiStage
