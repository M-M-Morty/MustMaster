--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")

---@class WBP_Firm_MapHeadline : WBP_Firm_MapHeadline_C

---@type WBP_Firm_MapHeadline_C
---@field bIsClicked boolean
local WBP_Firm_MapHeadline = Class(UIWindowBase)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

---@param self WBP_Firm_MapHeadline
---@return BP_FirmMapHeadLineItemObject_C
local function NewFirmMapHeadlineItemObject(self)
    local Path = PathUtil.getFullPathString(self.FirmMapHeadLineItemClass)
    local FirmMapHeadlineItemObject = LoadObject(Path)
    return NewObject(FirmMapHeadlineItemObject)
end

---@param self WBP_Firm_MapHeadline
local function OnClickedDropDownBox(self)
    local bIsClicked = not self.bIsClicked
    self.bIsClicked = bIsClicked
    if bIsClicked then
        self.Canvas_MapHeadline:SetVisibility(UE.ESlateVisibility.Visible)
        self:SetListInfoData()
    else
        self.Canvas_MapHeadline:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param HeadLineItem WBP_Firm_MapHeadline_Item
function WBP_Firm_MapHeadline:OnClickedSelectItem(HeadLineItem)
    self.Canvas_MapHeadline:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.bIsClicked = false
end

function WBP_Firm_MapHeadline:SetListInfoData()
    local Path = PathUtil.getFullPathString(self.FirmMapHeadLineItemClass)
    local FirmMapHeadlineItemObject = LoadObject(Path)
    local InMapHeadLineList = UE.TArray(FirmMapHeadlineItemObject)
    for i = 1, 4 do
        local FirmMapHeadLineItem = NewFirmMapHeadlineItemObject(self)
        FirmMapHeadLineItem.OwnerWidget = self
        InMapHeadLineList:Add(FirmMapHeadLineItem)
    end
    self.List_MapHeadline:BP_SetListItems(InMapHeadLineList)
end

function WBP_Firm_MapHeadline:Construct()
    self.bIsClicked = false
    self.WBP_CommonButton.OnClicked:Add(self, OnClickedDropDownBox)
end

function WBP_Firm_MapHeadline:Destruct()
    self.WBP_CommonButton.OnClicked:Remove(self, OnClickedDropDownBox)
end

--function M:Tick(MyGeometry, InDeltaTime)
--end

return WBP_Firm_MapHeadline
