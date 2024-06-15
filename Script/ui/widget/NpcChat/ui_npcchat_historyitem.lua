--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local Actor = require("common.actor")
local M = Component(ComponentBase)

function M:InitViewModel(historyItemVM)
    local itemType = historyItemVM.WS_ItemType:GetFieldValue()
    if itemType == 0 then
        self:SetTargetItemActive(true)
        self:SetMineItemActive(false)
        self:SetMissionItemActive(false)
        self:SetTimeItemActive(false)

        self:GetTargetItemComponent():InitItem(historyItemVM)
    elseif itemType == 1 then
        self:SetTargetItemActive(false)
        self:SetMineItemActive(true)
        self:SetMissionItemActive(false)
        self:SetTimeItemActive(false)
        self:GetMineItemComponent():InitItem(historyItemVM)
    elseif itemType == 2 then
        self:SetTargetItemActive(false)
        self:SetMineItemActive(false)
        self:SetMissionItemActive(false)
        self:SetTimeItemActive(true)
        self:GetTimeItemComponent():InitItem(historyItemVM)
    else
        self:SetTargetItemActive(false)
        self:SetMineItemActive(false)
        self:SetMissionItemActive(true)
        self:SetTimeItemActive(false)
        self:GetMissionItemComponent():InitItem(historyItemVM)
    end
end

return M
