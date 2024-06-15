require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_RandPlayAnim = Class(BTTask_Base)
local BTTask_PlayAnim = require("ai.BTTask.BTTask_HI_PlayAnim")


-- 播放初始化动作
function BTTask_RandPlayAnim:Execute(Controller, Pawn)

    local AnimMontage = Pawn:GetAIServerComponent().InitAnimation
    self.AnimInstance = BTTask_PlayAnim.new()
    self.AnimInstance.Montage = AnimMontage
    self.AnimInstance.MaxPlayDuration = 0.0
    self.AnimInstance.PlayRate = 1.0
    self.AnimInstance.SectionName = "Default"
    return self.AnimInstance:Execute(Controller, Pawn)
end

function BTTask_RandPlayAnim:Tick(Controller, Pawn, DeltaSeconds)
    return self.AnimInstance:Tick(Controller, Pawn, DeltaSeconds)
end


return BTTask_RandPlayAnim
