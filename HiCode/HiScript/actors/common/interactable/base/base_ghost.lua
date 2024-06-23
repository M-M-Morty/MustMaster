--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/05/15
--

---@type

require "UnLua"
local G = require("G")
local ActorBase = require("actors.common.interactable.base.base_character")
local EdUtils = require("common.utils.ed_utils")
local SubsystemUtils = require("common.utils.subsystem_utils")
local BPConst = require("common.const.blueprint_const")
local utils = require("common.utils")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

---@param index 移动到路点的 index 位置
---@param InWayPointID 移动到路点的 ID, BP_WayPoint实例通过 GetEditorID() 方法获取
---@param trigger_by_mission 是否通过任务触发
---@overridder
function M:TriggerAtWayPointIndex(index, InWayPointID, trigger_by_mission)
    if self.NPCMoveViaPoint then
        local function trigger_cb(WayPointID)
            self.NPCMoveViaPoint:SetWayPointID(InWayPointID)
            if trigger_by_mission then
                self.NPCMoveViaPoint:SetMoveType(Enum.E_NPCMoveType.TriggerByMission)
            end
            local iIndexModeAdd = 1
            if self.NPCMoveViaPoint.iCurIndex >= index then
                iIndexModeAdd = -1
            end
            self.NPCMoveViaPoint.bTriggerByUser = true
            self.NPCMoveViaPoint.iIndexModeAdd = iIndexModeAdd
            self.NPCMoveViaPoint.GotoIndex = index-iIndexModeAdd
            self.NPCMoveViaPoint:TriggerAtWayPointIndex(self, index-iIndexModeAdd)
        end
        -- 可能只是没有设置 WayPointID 而已
        trigger_cb(self.NPCMoveViaPoint.WayPointID)
        self.NPCMoveViaPoint.AfterInitWayPoint_CB = trigger_cb
    end
end

function M:ChildReadyNotify(ActorId)
    if self.NPCMoveViaPoint then
        self.NPCMoveViaPoint:ChildReadyNotify(ActorId)
    end
end

return M