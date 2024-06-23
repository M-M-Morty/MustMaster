--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local json = require("thirdparty.json")
local MissionActionBase = require("mission.mission_action.mission_action_base")
local BPConst = require("common.const.blueprint_const")
local TimeUtil = require("common.utils.time_utils")

---@type BP_MissionAction_ChangeHour_C
local MissionActionChangeHour = Class(MissionActionBase)

function MissionActionChangeHour:OnActive()
    Super(MissionActionChangeHour).OnActive(self)
    self:RunActionOnActorByTag("HiGamePlayer", self:GenerateActionParam())
end

function MissionActionChangeHour:GenerateActionParam()
    local Param = {
        TargetHour = self.TargetHour
    }
    return json.encode(Param)
end

function MissionActionChangeHour:Run(PlayerState, ActionParamStr)
    Super(MissionActionChangeHour).Run(self, PlayerState, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    self.TargetHour = Param.TargetHour
    local GameState = UE.UGameplayStatics.GetGameState(PlayerState)
    local GameTimeComponent = GameState.GameTimeComponent
    local CurMinutes = GameTimeComponent:GetMinuteOfDay()
    -- 计算要增加多少分钟
    local RemainMinutes = (self.TargetHour * TimeUtil.MINUTES_PER_HOUR + TimeUtil.MINUTES_PER_DAY - CurMinutes) % TimeUtil.MINUTES_PER_DAY
    GameTimeComponent:AddMinutes(RemainMinutes)
end

function MissionActionChangeHour:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

return MissionActionChangeHour
