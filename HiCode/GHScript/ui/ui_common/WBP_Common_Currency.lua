--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class CurrencyData
---@field ExcelID integer
---@field bShowAddButton boolean

---@class WBP_Common_Currency : WBP_Common_Currency_C

---@type WBP_Common_Currency_C
local WBP_Common_Currency = UnLua.Class()

local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")

---@param self WBP_Common_Currency
---@return BP_CommonCurrencyItemObject_C
local function NewCurrencyItemObject(self)
    local Path = PathUtil.getFullPathString(self.CommonCurrencyItemClass)
    local CommonCurrencyItemObject = LoadObject(Path)
    return NewObject(CommonCurrencyItemObject)
end

---@param CurrencyDatas CurrencyData[]
function WBP_Common_Currency:SetCurrencyDatas(CurrencyDatas)
    local Path = PathUtil.getFullPathString(self.CommonCurrencyItemClass)
    local CommonCurrencyItemObject = LoadObject(Path)
    local InListItems = UE.TArray(CommonCurrencyItemObject)
    for i = 1, #CurrencyDatas do
        local CurrencyItem = NewCurrencyItemObject(self)
        CurrencyItem.ExcelID = CurrencyDatas[i].ExcelID
        CurrencyItem.ShowAddButton = CurrencyDatas[i].bShowAddButton
        CurrencyItem.bDark = self.bDark
        InListItems:Add(CurrencyItem)
    end
    self.ListView_Currency:BP_SetListItems(InListItems)
end

---需要父Window调用播放，建议在OnShow调用
function WBP_Common_Currency:PlayInAnim()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

---需要父Window调用播放，建议在父Window播放DX_Out的时候播放
---UUserWidget:OnAnimationStarted(Animation)可以在父Window Override这个接口，判断Animation是否为DX_Out
function WBP_Common_Currency:PlayOutAnim()
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

return WBP_Common_Currency
