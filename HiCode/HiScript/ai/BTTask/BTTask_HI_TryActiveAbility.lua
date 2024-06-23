require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")
local SkillData = require("common.data.monster_skillid_table").data

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_TryActiveAbility = Class(BTTask_Base)

function BTTask_TryActiveAbility:Execute(Controller, Pawn)
    if not self.SkillClass then
        -- return self:Execute_Old(Controller, Pawn)
        G.log:error("yj", "BTTask_TryActiveAbility:Execute SkillClass empty: \n %s", Controller:GetBTDebugInfo())
        assert(false)
    else
        return self:Execute_New(Controller, Pawn)
    end
end

function BTTask_TryActiveAbility:Tick(Controller, Pawn, DeltaSeconds)
    if not self.SkillClass then
        -- return self:Tick_Old(Controller, Pawn, DeltaSeconds)
        G.log:error("yj", "BTTask_TryActiveAbility:Tick SkillClass empty: \n %s", Controller:GetBTDebugInfo())
        assert(false)
    else
        return self:Tick_New(Controller, Pawn, DeltaSeconds)
    end
end

function BTTask_TryActiveAbility:Execute_New(Controller, Pawn)
    if not self.SkillClass then
        G.log:error("yj", "BTTask_TryActiveAbility SkillClass nil")
        assert(false)
    end

    local ASC = G.GetHiAbilitySystemComponent(Pawn)
    local AbilityHandle = ASC:FindAbilitySpecHandleFromClass(self.SkillClass)

    G.log:debug("yjj", "BTTask_TryActiveAbility:Execute_New AbilityHandle.%s SkillClass.%s", AbilityHandle.Handle, self.SkillClass)
    if AbilityHandle.Handle == -1 then

        Pawn.StaticSkillID = Pawn.StaticSkillID + 1

        local UserData = utils.MakeUserData()
        UserData.SkillID = Pawn.StaticSkillID
        Pawn.SkillComponent:GiveAbility(self.SkillClass, -1, UserData)
    end

    AbilityHandle = ASC:FindAbilitySpecHandleFromClass(self.SkillClass)
    local AbilitySpec = SkillUtils.FindAbilitySpecFromHandle(ASC, AbilityHandle)
    local AbilityCDO = AbilitySpec.Ability
    if not AbilityCDO.bCanActivateInAir and ASC:HasGameplayTag(self.InAirTag) then
        return
    end

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local TargetActor = BB:GetValueAsObject("TargetActor")
    if TargetActor then
        Pawn.SkillComponent:SetSkillTarget(AbilitySpec.UserData.SkillID, TargetActor, TargetActor:GetTransform(), true)
    end
    
    Pawn.SkillInUse = AbilitySpec.UserData.SkillID
    Pawn:SendMessage("BeforeTryActiveAbility")

    AbilitySpec.Ability.ComboBeginSection = self.ComboBeginSection
    AbilitySpec.Ability.bPlayMontageForCombo = self.bCanFinishInAdvance or (self.ComboBeginSection ~= "None" and self.ComboBeginSection ~= nil)

    Pawn:GetAbilitySystemComponent():BP_TryActivateAbilityByHandle(AbilityHandle, true)
    Controller:StopMovement()

    G.log:debug("GABaseBase", "BTTask_TryActiveAbility %s, Montage.%s BeginSection.%s bCanFinishInAdvance.%s", 
        AbilitySpec.UserData.SkillID, G.GetDisplayName(AbilitySpec.Ability.MontageToPlay), self.ComboBeginSection, self.bCanFinishInAdvance)
end

function BTTask_TryActiveAbility:Tick_New(Controller, Pawn, DeltaSeconds)

    local ASC = G.GetHiAbilitySystemComponent(Pawn)
    local AbilityHandle = ASC:FindAbilitySpecHandleFromClass(self.SkillClass)
    local AbilitySpec = SkillUtils.FindAbilitySpecFromHandle(ASC, AbilityHandle)
    -- G.log:debug("yj", "AbilityHandle.IsActive.%s", UE.UHiGASLibrary.IsAbilityActive(AbilitySpec))

    if not UE.UHiGASLibrary.IsAbilityActive(AbilitySpec) then
        Pawn:SendMessage("AfterTryActiveAbility")
        return ai_utils.BTTask_Succeeded
    end
end

function BTTask_TryActiveAbility:CanBreak(Controller, Pawn)
    -- bCanFinishInAdvance为false表示播完一个技能蒙太奇
    -- bCanFinishInAdvance为true则用于连招，配合bCanBreakCurBTNode使用
    local Ret = self.bCanFinishInAdvance and Pawn:GetAIServerComponent().bCanBreakCurBTNode
    Pawn:SendMessage("SetCurBTNodeBreak", false)
    return Ret
end

function BTTask_TryActiveAbility:OnBreak(Controller, Pawn)
    Pawn:SendMessage("StopSkill")
end

return BTTask_TryActiveAbility
