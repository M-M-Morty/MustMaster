--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')


---@class FirmMapAnchorData
---@field TempId integer
---@field AnchorItem WBP_Firm_MarkerPoints
---@field SelectIconIndex string
---@field PositionX number
---@field PositionY number
---@field AnchorName string
---@field bIsChecked boolean

---@class FirmMarkerData
---@field PicKey string
---@field bIsChecked boolean
---@field TotalNum integer
---@field CheckedNum integer
---@field SelectIconIndex string
---@field PositionX number
---@field PositionY number
---@field AnchorName string




---@class WBP_Firm_Import_Popup : WBP_Firm_Import_Popup_C
---@field MarkerPointsItems table<number,FirmMapAnchorData>
---@field MultipleSelectionIndex table<string,FirmMarkerData>
---@field FirmMapWidget WBP_Firm_Map



---@type WBP_Firm_Import_Popup_C
local WBP_Firm_Import_Popup = Class(UIWindowBase)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end
---@param self WBP_Firm_Import_Popup
local function OnClickCloseMedPopup(self)
    UIManager:CloseUI(self, true)
end

---@param self WBP_Firm_Import_Popup
local function OnClickConfirmBtn(self)
    UIManager:CloseUI(self, true)
    ---@type WBP_Firm_SelectImportAnchor
    local FirmSelectImportAnchor = UIManager:OpenUI(UIDef.UIInfo.UI_Firm_SelectImportAnchor)
    FirmSelectImportAnchor:GetsFimMapIncomingData(self.FirmMapWidget,self.MarkerPointsItems,self.MultipleSelectionIndex)
end


---@param FirmMapWidget WBP_Firm_SidePopupWindow
---@param MapData FirmMapData
---@param MarkerData FirmMarkerData
function WBP_Firm_Import_Popup:GetsIncomingData(FirmMapWidget,MapData,MarkerData)
    self.FirmMapWidget = FirmMapWidget
    self.MarkerPointsItems = MapData
    self.MultipleSelectionIndex = MarkerData
end
function WBP_Firm_Import_Popup:Construct()
    self.WBP_Common_Popup_Medium.WBP_MedPopupClose.OnClicked:Add(self, OnClickCloseMedPopup)
    self.WBP_ComBtn_MedDefine.OnClicked:Add(self, OnClickConfirmBtn)
end

function WBP_Firm_Import_Popup:Destruct()
    self.WBP_Common_Popup_Medium.WBP_MedPopupClose.OnClicked:Remove(self, OnClickCloseMedPopup)
    self.WBP_ComBtn_MedDefine.OnClicked:Remove(self, OnClickConfirmBtn)
end

--function M:Tick(MyGeometry, InDeltaTime)
--end

return WBP_Firm_Import_Popup
