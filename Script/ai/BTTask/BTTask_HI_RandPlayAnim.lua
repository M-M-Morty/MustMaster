require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_RandPlayAnim = Class(BTTask_Base)
local BTTask_PlayAnim = require("ai.BTTask.BTTask_HI_PlayAnim")


-- 群体AI执行命令
function BTTask_RandPlayAnim:Execute(Controller, Pawn)

    local AnimArray = Pawn:GetAIServerComponent().IdleAnimations
    if not self.ChooseIdleAnim then
        AnimArray = Pawn:GetAIServerComponent().ProvokeAnimations
    end

    local TotalNum = 0
    for idx = 1, AnimArray:Length() do
        local Ele = AnimArray:Get(idx)
        TotalNum = TotalNum + Ele.Weight
    end

    local AnimEle = nil
    local RandNum = math.random(0, TotalNum)
    for idx = 1, AnimArray:Length() do
        AnimEle = AnimArray:Get(idx)
        RandNum = RandNum - AnimEle.Weight
        if RandNum <= 0 then
            break
        end
    end

    -- G.log:error("yj", "BTTask_RandPlayAnim:Execute %s %s", Pawn:GetDisplayName(), G.GetDisplayName(AnimEle.Montage))

    self.AnimInstance = BTTask_PlayAnim.new()
    self.AnimInstance.Montage = AnimEle.Montage
    self.AnimInstance.MaxPlayDuration = 0.0
    self.AnimInstance.PlayRate = 1.0
    self.AnimInstance.SectionName = "Default"
    return self.AnimInstance:Execute(Controller, Pawn)
end

function BTTask_RandPlayAnim:Tick(Controller, Pawn, DeltaSeconds)
    return self.AnimInstance:Tick(Controller, Pawn, DeltaSeconds)
end


return BTTask_RandPlayAnim
