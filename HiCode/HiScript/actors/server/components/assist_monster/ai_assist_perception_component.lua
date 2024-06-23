--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local BPConst = require("common.const.blueprint_const")
local G = require("G")

local AIAssistPerceptionComponent = Component(ComponentBase)
local decorator = AIAssistPerceptionComponent.decorator

local DefaultMaxZDis = 500

decorator.message_receiver()
function AIAssistPerceptionComponent:OnServerReady()
    if not self.actor.AISwitch then
        self.actor:RemoveBlueprintComponent(self)
        return
    end

    self:AddAIPerceptionCallback()
    self.LoseTargetCheckTimerHandler = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.LoseTargetCheckTimer}, 3, true)

    self.MaxZDis = self.MaxZDis or DefaultMaxZDis
end

decorator.message_receiver()
function AIAssistPerceptionComponent:OnClientReady()
    self.actor:RemoveBlueprintComponent(self)
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.LoseTargetCheckTimerHandler)
end


function AIAssistPerceptionComponent:AddAIPerceptionCallback()
    local AIPerception = self.actor:GetController().AIPerception
    AIPerception.OnTargetPerceptionUpdated:Add(self, self.OnPerceptionUpdate)
end

function AIAssistPerceptionComponent:DelAIPerceptionCallback()
    local AIPerception = self.actor:GetController().AIPerception
    AIPerception.OnTargetPerceptionUpdated:Remove(self, self.OnPerceptionUpdate)
end

function AIAssistPerceptionComponent:LoseTargetCheckTimer()
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(self.actor:GetController())
    local Target = BB:GetValueAsObject("TargetActor")
    if not Target then
        return
    end

    local SelfLocation = self.actor:K2_GetActorLocation()
    local TargetLocation = Target:K2_GetActorLocation()
    if self.actor:GetDistanceTo(Target) > self.OutBattleDis or math.abs(SelfLocation.Z - TargetLocation.Z) > self.MaxZDis then
        self:ForgetAll()
        BB:SetValueAsObject("TargetActor", nil)
    end
end

function AIAssistPerceptionComponent:OnPerceptionUpdate(Target, InStimulus)
    if self.TargetType == Enum.EAssistTargetType.Monster then
        local BPAMonsterClass = BPConst.GetMonsterClass()
        local entity = Target:Cast(BPAMonsterClass)
        if not entity then
            return
        end
    elseif self.TargetType == Enum.EAssistTargetType.Player then
        local BPACharacterBaseClass = BPConst.GetBPACharacterBaseClass()
        local entity = Target:Cast(BPACharacterBaseClass)
        if not entity then
            return
        end
    end

    if InStimulus.bSuccessfullySensed then
        -- 高度判断
        local SelfLocation = self.actor:K2_GetActorLocation()
        local TargetLocation = Target:K2_GetActorLocation()
        if math.abs(SelfLocation.Z - TargetLocation.Z) > self.MaxZDis then
            self:ForgetAll()
            return
        end
    end

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(self.actor:GetController())
    BB:SetValueAsObject("TargetActor", Target)
    --
end


function AIAssistPerceptionComponent:ForgetAll()
    local AIPerception = self.actor:GetController().AIPerception
    AIPerception:ForgetAll()
end

return AIAssistPerceptionComponent
