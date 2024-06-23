local G = require('G')
local MissionConst = require('Script.mission.mission_const')

---@class IconUtil
local IconUtil = {}

---@param SwitcherName UWidgetSwitcher
---@param TaskType number
---@param state number
function IconUtil:SetTaskIcon(SwitcherName, TaskType, state)
    SwitcherName.Task_Icon_Switcher:SetActiveWidgetIndex(TaskType)
    if TaskType == MissionConst.EMissionType.Main then -- 主线
        SwitcherName.Task_Icon_MainMission:SetActiveWidgetIndex(state)
    elseif TaskType == MissionConst.EMissionType.Activity then -- 活动
        SwitcherName.Task_Icon_Activity:SetActiveWidgetIndex(state)
    elseif TaskType == MissionConst.EMissionType.Daily then -- 日常
        SwitcherName.Task_Icon_Daily:SetActiveWidgetIndex(state)
    elseif TaskType == MissionConst.EMissionType.Guide then -- 引导
        SwitcherName.Task_Icon_Guide:SetActiveWidgetIndex(state)
    end
end

return IconUtil