require "UnLua"

local G = require("G")
local StateConflictData = require("common.data.state_conflict_data")
local SkillData = require("common.data.skill_list_data").data

local SkillObj = Class()

function SkillObj:ctor(InOwner, InSkillId)
    self.__TAG__ = "SkillObj"
    
    self.Owner = InOwner
    self.actor = self.Owner.actor
    self.AbilitySystemComponent = G.GetHiAbilitySystemComponent(self.Owner.actor)
    self.SkillDriver = self.Owner.SkillDriver

    self:InitFromData(InSkillId)
end

function SkillObj:InitFromData(InSkillId)
    self.SkillID = InSkillId
    self.SkillData = SkillData[self.SkillID]
    if not self.SkillData then
        G.log:error(self.__TAG__, "Skill id: %d not found in skill datatable.", self.SkillID)
        return
    end
    self.SkillName = self.SkillData["name"]
end

-- Get Gameplay ability CDO of skill.
function SkillObj:GetAbilityCDO()
    return self.Owner:FindAbilityFromSkillID(self.SkillID)
end

function SkillObj:GetSkillType()
    local AbilityCDO = self:GetAbilityCDO()
    return AbilityCDO.SkillType
end

-- Get Gameplay ability Instanced of CDO of skill.
-- return Ability, bIsInstanced
function SkillObj:GetAbility()
    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local SpecHandle = self.Owner:FindAbilitySpecHandleFromSkillID(self.SkillID)

    local GA, bInstanced = G.GetGameplayAbilityFromSpecHandle(ASC, SpecHandle)
    return GA, bInstanced
end

function SkillObj:FindAbilitySpecHandleFromID(InSkillID)
    return self.AbilitySystemComponent:FindAbilitySpecHandleFromInputID(InSkillID)
end

function SkillObj:SetMontageOffsetTime(StartOffsetTime)
    self.Owner:SendMessage("SetSkillOffsetTime", self.SkillID, StartOffsetTime)
end

-- Start skill and try run prefix process
--  1. Assist attack
--  2. Rush
-- If enabled AssistAttack Start is async, use ActivateCallback to get callback.
function SkillObj:Start(ActivateCallbackOwner, ActivateCallback)
    if not self:CanActivate() then
        return
    end
    self.ActivateCallbackOwner = ActivateCallbackOwner
    self.ActivateCallback = ActivateCallback

    -- First end zero gravity of prev skill.
    self.actor.ZeroGravityComponent:EndCurrentZeroGravity()

    self:EnterSkillState()

    local SkillAbilityCDO = self:GetAbilityCDO()
    local bSuccess = false
    if SkillAbilityCDO then
        bSuccess = SkillAbilityCDO:StartSkill(self.Owner, self.actor, self.SkillID, self, self._StartInternal)
    end
end

function SkillObj:_StartInternal(bCanceled)
    if bCanceled then
        self:EndSkillState()
        return
    end
    
    local SkillAbilityCDO = self:GetAbilityCDO()
    local bSuccess = false
    if SkillAbilityCDO then
        SkillAbilityCDO:PreStartSkill()
    
        bSuccess = self.AbilitySystemComponent:TryActivateAbilityByClass(SkillAbilityCDO.StaticClass(), true)
        G.log:debug(self.__TAG__, "Activate skill: %d result: %s", self.SkillID, bSuccess)
        if bSuccess then
            -- Check enable zero gravity.
            SkillAbilityCDO:AfterStartSkill()

            if self.ActivateCallback then
                self.ActivateCallback(self.ActivateCallbackOwner)
            end
        else
            self:EndSkillState()
        end
    end 
end

function SkillObj:CanActivate()
    local StateController = self.actor:_GetComponent("StateController", false)
    if StateController:InSkillState() then
        G.log:debug(self.__TAG__, "SkillID: %s already in skill state, cant activate", self.SkillID)
        return false
    end

    local GASpec = self.Owner:FindAbilitySpecFromSkillID(self.SkillID)
    if not GASpec then
        G.log:error(self.__TAG__, "SkillID: %s not found GA spec, cant activate", self.SkillID)
        return false
    end

    local AbilityCDO = GASpec.Ability
    if not AbilityCDO then
        G.log:error(self.__TAG__, "Ability CDO not exist for SkillID: %d, cant activate", self.SkillID)
        return false
    end

    local ASC = G.GetHiAbilitySystemComponent(self.actor)
    local FailTags = UE.FGameplayTagContainer()
    local CanActivate = AbilityCDO:CanActivateAbilityWithHandle(GASpec.Handle, ASC:GetAbilityActorInfo(), FailTags)
    if not CanActivate then
        G.log:debug(self.__TAG__, "Ability can not activate right now, SkillID: %d", self.SkillID)
        return false
    end

    return true
end

function SkillObj:IsNormalSkill()
    local AbilityCDO = self:GetAbilityCDO()
    local SkillType = AbilityCDO.SkillType
    return SkillUtils.IsNormalSkill(SkillType) or SkillUtils.IsInAirNormalSkill(SkillType)
end

function SkillObj:IsSuperSkill()
    local AbilityCDO = self:GetAbilityCDO()
    local SkillType = AbilityCDO.SkillType
    return SkillUtils.IsSuperSkill(SkillType)
end

function SkillObj:IsAssistSkill()
    local AbilityCDO = self:GetAbilityCDO()
    local SkillType = AbilityCDO.SkillType
    return SkillUtils.IsAssistManagerSkill(SkillType)
end

function SkillObj:IsRushStateSkill()
    local AbilityCDO = self:GetAbilityCDO()
    local SkillType = AbilityCDO.SkillType
    return SkillUtils.IsRushSkill(SkillType) or SkillUtils.IsFallAttackSkill(SkillType)
end

-- Whether skill GA running.
function SkillObj:IsRunning()
    local Spec = self.Owner:FindAbilitySpecFromSkillID(self.SkillID)
    return UE.UHiGASLibrary.IsAbilityActive(Spec)
end


function SkillObj:Cancel()
    -- Handle when invoke cancel during rush, first cancel rush and set skill is canceled.
    if self.bInRush then
        self.Owner:SendMessage("EndRushInPreSkill", self.SkillID)
    end
    --self.bCanceled = true

    local Handle = self.Owner:FindAbilitySpecHandleFromSkillID(self.SkillID)
    if Handle.Handle ~= -1 then
        self.AbilitySystemComponent:BP_CancelAbilityHandle(Handle)
    end

    self:EndSkillState()
end

function SkillObj:OnEndAbility()
    G.log:info(self.__TAG__, "OnEndAbility, SkillID: %d", self.SkillID)
    self:EndSkillState()
end

-- When enter skill process include assist attack and lock attack, try stop current montage (from locomotion .etc.) and clear velocity.
function SkillObj:EnterSkillState()
    G.log:info(self.__TAG__, "SkillObj enter skill state, SkillID: %d", self.SkillID)
    self.bInSkillState = true

    -- Stop JumpAssistCheck
    self.actor.JumpInAirComponent:StopJump()

    -- Stop 3c action (climb end montage .etc.)
    self.actor:GetLocomotionComponent():Replicated_StopMontageGroup("MovementActionGroup")

    local AbilityCDO = self:GetAbilityCDO()
    if AbilityCDO.bMovable then
        self.Owner:SendMessage("EnterState", StateConflictData.State_SkillMovable)
    elseif self:IsNormalSkill() then
        self.Owner:SendMessage("EnterState", StateConflictData.State_SkillNormal)
    elseif self:IsSuperSkill() then
        self.Owner:SendMessage("EnterState", StateConflictData.State_SuperSkill)
    elseif self:IsAssistSkill() then
        -- 怪谈技能不属于真正的技能，不占用状态机
    elseif self:IsRushStateSkill() then
        self.Owner:SendMessage("EnterState", StateConflictData.State_Rush)
        self.Owner:SendMessage("EnterState", StateConflictData.State_Skill)
    else
        self.Owner:SendMessage("EnterState", StateConflictData.State_Skill)
    end
end

function SkillObj:EndSkillState()
    if not self.bInSkillState then
        return
    end
    self.bInSkillState = false

    G.log:info(self.__TAG__, "SkillObj end skill state, SkillID: %d", self.SkillID)

    local AbilityCDO = self:GetAbilityCDO()
    if AbilityCDO.bMovable then
        self.Owner:SendMessage("EndState", StateConflictData.State_SkillMovable)
    elseif self:IsNormalSkill() then
        self.Owner:SendMessage("EndState", StateConflictData.State_SkillNormal)
    elseif self:IsSuperSkill() then
        self.Owner:SendMessage("EndState", StateConflictData.State_SuperSkill)
    elseif self:IsAssistSkill() then
        -- 怪谈技能不属于真正的技能，不占用状态机
    elseif self:IsRushStateSkill() then
        self.Owner:SendMessage("EndState", StateConflictData.State_Rush)
        self.Owner:SendMessage("EndState", StateConflictData.State_Skill)
    else
        self.Owner:SendMessage("EndState", StateConflictData.State_Skill)
    end
end


return SkillObj
