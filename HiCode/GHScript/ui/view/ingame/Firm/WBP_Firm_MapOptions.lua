--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

---@type WBP_Firm_MapOptions_C
local WBP_Firm_MapOptions = Class(UIWindowBase)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

-- function M:Construct()
-- end

--function M:Tick(MyGeometry, InDeltaTime)
--end
---@param self WBP_Firm_MapOptions_C
---@return BP_FirmMapOptionsObject_C
local function CreateOptionsItem(self)
    local Path = PathUtil.getFullPathString(self.FirmMapOptionsClass)
    local MapOptionsItemObject = LoadObject(Path)
    return NewObject(MapOptionsItemObject)
end

---@param OverlapFloat WBP_FirmMapLabel[]
---@param Parent WBP_Firm_Map
function WBP_Firm_MapOptions:ShowFloatOptionsData(OverlapFloat, Parent)
    local Path = PathUtil.getFullPathString(self.FirmMapOptionsClass)
    local MapOptionsItemObject = LoadObject(Path)
    local OptionInitListItem = UE.TArray(MapOptionsItemObject)
    for i = 1, #OverlapFloat do
        local InitListItem = CreateOptionsItem(self)
        InitListItem.LabelUI = OverlapFloat[i]
        InitListItem.FirmMapUI = Parent
        InitListItem.IsFloat = true
        OptionInitListItem:Add(InitListItem)
    end
    self.List_MapOptions:BP_SetListItems(OptionInitListItem)
end

---@param CloseLabels WBP_FirmMapLabel[]
---@param Parent WBP_Firm_Map
function WBP_Firm_MapOptions:ShowLabelOptionsData(CloseLabels, Parent)
    local Path = PathUtil.getFullPathString(self.FirmMapOptionsClass)
    local MapOptionsItemObject = LoadObject(Path)
    local OptionInitListItem = UE.TArray(MapOptionsItemObject)
    for i = 1, #CloseLabels do
        local InitListItem = CreateOptionsItem(self)
        InitListItem.LabelUI = CloseLabels[i]
        InitListItem.FirmMapUI = Parent
        OptionInitListItem:Add(InitListItem)
    end
    self.List_MapOptions:BP_SetListItems(OptionInitListItem)
end

return WBP_Firm_MapOptions
