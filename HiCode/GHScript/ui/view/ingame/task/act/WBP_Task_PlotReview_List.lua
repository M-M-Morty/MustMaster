--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Task_PlotReview_List : WBP_Task_PlotReview_List_C
---@field ListItemObject BP_TaskPreviewItem_C
---@field OwnerWidget WBP_Task_PlotReview

---@type WBP_Task_PlotReview_List
local WBP_Task_PlotReview_List = UnLua.Class()

local G = require("G")
local MissionActUtils = require("CP0032305_GH.Script.mission.mission_act_utils")

---Called when this entry is assigned a new item object to represent by the owning list view
---@param ListItemObject BP_TaskPreviewItem_C
---@return void
function WBP_Task_PlotReview_List:OnListItemObjectSet(ListItemObject)
    self.ListItemObject = ListItemObject
    self.OwnerWidget = ListItemObject.OwnerWidget
    local MissionID = ListItemObject.MissionID
    local MissionConfig = MissionActUtils.GetMissionConfig(MissionID)
    if MissionConfig == nil then
        G.log:warn("WBP_Task_PlotReview_List", "MissionConfig nil! MissionID: %d", MissionID)
    else
        self.Txt_SubList:SetText(MissionConfig.Name)
        self.Txt_SubList_Selected:SetText(MissionConfig.Name)
    end
    self.Switch_SubList:SetActiveWidgetIndex(0)
end

---Called when the selection state of the item represented by this entry changes.
---@param bIsSelected boolean
---@return void
function WBP_Task_PlotReview_List:BP_OnItemSelectionChanged(bIsSelected)
    if bIsSelected then
        self.Switch_SubList:SetActiveWidgetIndex(1)
    else
        self.Switch_SubList:SetActiveWidgetIndex(0)
    end
end

---@param self WBP_Task_PlotReview_List
local function OnClick(self)
    self.OwnerWidget:OnClickListItem(self.ListItemObject)
end

function WBP_Task_PlotReview_List:Construct()
    self.WBP_Btn_SubList.OnClicked:Add(self, OnClick)
end

function WBP_Task_PlotReview_List:Destruct()
    self.WBP_Btn_SubList.OnClicked:Remove(self, OnClick)
end

return WBP_Task_PlotReview_List
