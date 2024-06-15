
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

local ui_common_rightpropupbase = Class(UIWindowBase)

function ui_common_rightpropupbase:Init(titleText, bShowCloseBtn)
    self.Txt_Title:SetText(titleText)
    if bShowCloseBtn then
        self.WBP_Common_TopContent.CommonButton_Close:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.WBP_Common_TopContent.CommonButton_Close:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

return ui_common_rightpropupbase
