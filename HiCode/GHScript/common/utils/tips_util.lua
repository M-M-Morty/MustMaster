local _M = {}

local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local ConstText = require("CP0032305_GH.Script.common.text_const")

---@param TipsContentKey string
function _M.ShowCommonTips(TipsContentKey, Duration)
    ---@type HudMessageCenter
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    local Msg = ConstText.GetConstText(TipsContentKey)
    if Msg == "" then
        Msg = TipsContentKey
    end
    local RealDuration = Duration or 2
    HudMessageCenterVM:AddCommonTips(Msg, RealDuration)
end

---@param TipsContentKey string
function _M.ShowImportantTips(TipsContentKey, Duration)
    ---@type HudMessageCenter
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    local Msg = ConstText.GetConstText(TipsContentKey)
    if Msg == "" then
        Msg = TipsContentKey
    end
    local RealDuration = Duration or 2
    HudMessageCenterVM:AddImportantTips(Msg, RealDuration)
end

return _M
