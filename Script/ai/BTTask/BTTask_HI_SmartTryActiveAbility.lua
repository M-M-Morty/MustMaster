require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_SmartTryActiveAbility = Class(BTTask_Base)
local BTTask_MoveToTarget = require("ai.BTTask.BTTask_HI_MoveToTarget")
local BTTask_TryActiveAbility = require("ai.BTTask.BTTask_HI_TryActiveAbility")


function BTTask_SmartTryActiveAbility:Execute(Controller, Pawn)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    if nil == Target then
        G.log:error("yj", "BTTask_SmartTryActiveAbility Target nil")
        return ai_utils.BTTask_Failed
    end

    local SkillRNG = Pawn:GetAIServerComponent().SkillRNG

    local TotalNum = 0
    for idx = 1, SkillRNG:Length() do
        local Ele = SkillRNG:Get(idx)
        TotalNum = TotalNum + Ele.Weight
    end

    local RandNum = math.random(0, TotalNum)
    for idx = 1, SkillRNG:Length() do
        local Ele = SkillRNG:Get(idx)
        RandNum = RandNum - Ele.Weight
        if RandNum <= 0 then
            self.RandomEle = Ele
            break
        end
    end

    self.MoveInstance = nil
    self.SkillInstance = nil

    if Pawn:GetDistanceTo(Target) > self.RandomEle.ActivateDistance then
        self.MoveInstance = self:GenIns_MoveToTarget(Controller, Pawn)
    else
        self.SkillInstance = self:GenIns_UseSkill(Controller, Pawn)
    end

    self.PursueTime = 0.0

    if self.MoveInstance ~= nil then
        return self.MoveInstance:Execute(Controller, Pawn)
    else
        return self.SkillInstance:Execute(Controller, Pawn)
    end
end

function BTTask_SmartTryActiveAbility:Tick(Controller, Pawn, DeltaSeconds)
    local ret = nil
    if self.MoveInstance ~= nil then
        ret = self.MoveInstance:Tick(Controller, Pawn, DeltaSeconds)
        if ret == ai_utils.BTTask_Succeeded then
            self.MoveInstance = nil
            self.SkillInstance = self:GenIns_UseSkill(Controller, Pawn)
            ret = self.SkillInstance:Execute(Controller, Pawn)
        else
            self.PursueTime = self.PursueTime + DeltaSeconds
            if self.PursueTime > self.MaxPursueTime then
                return ai_utils.BTTask_Failed
            end
        end
    elseif self.SkillInstance ~= nil then
        ret = self.SkillInstance:Tick(Controller, Pawn, DeltaSeconds)
    end

    return ret
end

function BTTask_SmartTryActiveAbility:GenIns_MoveToTarget(Controller, Pawn)
    local TaskInstance = BTTask_MoveToTarget.new()
    TaskInstance.Tolerance = self.RandomEle.ActivateDistance * 0.9
    TaskInstance.IgnoreZ = true
    return TaskInstance
end

function BTTask_SmartTryActiveAbility:GenIns_UseSkill(Controller, Pawn)
    local TaskInstance = BTTask_TryActiveAbility.new()
    TaskInstance.SkillClass = self.RandomEle.SkillClass
    return TaskInstance
end

function BTTask_SmartTryActiveAbility:OnFinish(Controller, Pawn, Succeeded)
    -- Pawn:SendMessage("ReturnBattleSignal")
end

function BTTask_SmartTryActiveAbility:OnSwitch(Controller, Pawn)
    -- Pawn:SendMessage("ReturnBattleSignal")
end

function BTTask_SmartTryActiveAbility:OnBreak(Controller, Pawn)
    -- Pawn:SendMessage("ReturnBattleSignal")
end


return BTTask_SmartTryActiveAbility
