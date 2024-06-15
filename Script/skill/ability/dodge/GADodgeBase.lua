--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local GAMulti = require("skill.ability.GAMulti")
local check_table = require("common.data.state_conflict_data")

---@type GA_DodgeBase_C
local M = Class(GAMulti)

---@type UAnimMontage
function M:GetPlayMontage() end

---@type BPA_AvatarBase_C
function M:GetOwner()
    local OwnerActor = self:GetOwningActorFromActorInfo()
    return OwnerActor
end


function M:K2_GetCostGameplayEffect()
    local Cost = self.CostGameplayEffectClass
    local Actor = self:GetOwner()
    if Actor:IsOnFloor() then
        if self.GroundCost then Cost = self.GroundCost end
    else
        if self.AirCost then Cost = self.AirCost end
    end
    if Cost then
        return Cost:GetDefaultObject()
    else 
        return nil
    end
end

function M:HandleActivateAbility()
    Super(M).HandleActivateAbility(self)
    self.Montage = self:GetDodgeMontage()
    -- G.log:info("yb", "start handle dodge ability")
    if not self.Montage then self:K2_EndAbility() end

    local StateController = self.OwnerActor:_GetComponent("StateController", false)
    if StateController then
        self.OwnerActor:SendMessage("EnterState", check_table.State_Dodge)
    end

    if self.OwnerActor.BuffComponent:HasPreAttackBuff() and not self.OwnerActor.TimeDilationComponent.bWitchTime then
        self.OwnerActor.BuffComponent:RemovePreAttackBuff()
        if self.OwnerActor:IsServer() then
            self.OwnerActor.DodgeComponent:Multicast_OnExtremeDodge()
        else
            -- 这个逻辑迁移到了AN_CastAssistSkill释放
            -- local SkillComponent = self.OwnerActor.SkillComponent
            -- if SkillComponent then 
            --     SkillComponent:AssistSkill()
            -- end
        end
        -- 给角色上一个可以释放怪谈槽技能的Tag， 怪谈技能通过键位触发
        --utils.AddGamePlayTags(self.OwnerActor, {"Ability.Buff.AssistSkill",})
    end
    -- 方便测试极限闪避用的
    -- utils.AddGamePlayTags(self.OwnerActor, {"Ability.Buff.AssistSkill",})
    G.log:info("yb", "play dodge montage anim", tostring(self.Montage:GetName()))

    if self.OwnerActor:IsClient() and self.OwnerActor.DodgeComponent then
        self.OwnerActor.DodgeComponent:PlayerBeginDodge()
    end

    local PlayTask = UE.UAbilityTask_PlayMontageAndWait
                         .CreatePlayMontageAndWaitProxy(self, "", self.Montage,
                                                        1.0, nil, true, 1.0)
    PlayTask.OnCompleted:Add(self, self.OnMontageCompleted)
    PlayTask.OnBlendOut:Add(self, self.OnMontageBlendOut)
    PlayTask.OnInterrupted:Add(self, self.OnMontageInterrupted)
    PlayTask.OnCancelled:Add(self, self.OnMontageCancelled)
    PlayTask:ReadyForActivation()
    self:AddTaskRefer(PlayTask)
end

function M:OnExtremeDodge()
    -- G.log:debug("DodgeComponent", "OnExtremeDodge actor: %s IsServer: %s",
    --             G.GetObjectName(self.OwnerActor), self.OwnerActor:IsServer())
    local TimeDilationActor = HiBlueprintFunctionLibrary.GetTimeDilationActor(
                                  self.OwnerActor)
    local GameState = UE.UGameplayStatics.GetGameState(
                          self.OwnerActor:GetWorld())
    if TimeDilationActor and GameState then
        TimeDilationActor:StartWitchTimeEx(GameState.WitchTimeTimeScale,
                                           GameState.WitchTimeDuration,
                                           self.OwnerActor)
    end
end

function M:OnMontageCompleted()
    G.log:info("yb", "montage finish")
    self:K2_EndAbility()
 end

function M:OnMontageCancelled() 
    G.log:info("yb", "montage cancel")
    self:K2_EndAbility() 
end

function M:OnMontageInterrupted()
    G.log:info("yb", "montage finish")
    self:K2_EndAbility()
end

function M:OnMontageBlendOut()
    G.log:info("yb", "montage blend out")
    self:K2_EndAbility()
 end    

function M:K2_OnEndAbility()
    --self.OwnerActor:SendMessage("EndState", check_table.State_Dodge)
    local StateController = self.OwnerActor:_GetComponent("StateController", false)
    if StateController then
        self.OwnerActor:SendMessage("EndState", check_table.State_Dodge, false)
        self.OwnerActor:SendMessage("EndState", check_table.State_DodgeTail, false)
    end
    if self.OwnerActor.DodgeComponent then
        self.OwnerActor.DodgeComponent:OnDodgeMontageEnd()
        if self.OwnerActor:IsServer() then
            --G.log:info("yb", "Multicast_EndDodge")
            if self.Montage then
                self.OwnerActor:Multicast_StopMontage(self.Montage)
                self.Montage = nil
            end
        end
    end
    -- 回收角色可以释放怪谈槽技能的Tag, 怪谈技能通过键位触发
    --utils.RemoveGameplayTags(self.OwnerActor, {"Ability.Buff.AssistSkill", })
    Super(M).K2_OnEndAbility(self)
end

---@return UAnimMontage
function M:GetDodgeMontage()
    local Component = self.OwnerActor.DodgeComponent;
    if not Component then
        return nil
    end
    local DodgeAnimMontage = nil
    local NeedInit = false
    local InitRotation = UE.FQuat()
    local DirectionVector = Component:GetDirectionVector()

    if DirectionVector:SizeSquared() > 0.5 then
        NeedInit = true
        InitRotation = UE.UKismetMathLibrary.Conv_VectorToQuaternion(
                           DirectionVector)
    end
    if NeedInit and InitRotation:SizeSquared() > G.EPS then
        if self.OwnerActor:IsOnFloor() then
            DodgeAnimMontage = Component.Ground_DodgeMontage
        else
            DodgeAnimMontage = Component.Air_DodgeMontage
        end
    else
        if self.OwnerActor:IsOnFloor() then
            DodgeAnimMontage = Component.Ground_DodgeBackMontage
        else
            DodgeAnimMontage = Component.Air_DodgeMontage
        end
    end
    -- G.log:info("yb", "GADodgeClass %s", tostring(GADodgeClass))
    return DodgeAnimMontage
end

function M:ClearSpeed() 
end

return M
