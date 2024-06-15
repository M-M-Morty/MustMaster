local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local G = require('G')

---@type BP_ShakespeareSubtitleWidget_C
local UICommunicationShakeSpeareWidget = Class(UIWindowBase)

function UICommunicationShakeSpeareWidget:SetSubtitleStrings(subtitle)
    self.ContentText:SetText(subtitle)
end

function UICommunicationShakeSpeareWidget:SetTalkerNameStrings(name)
    self.Text_Target:SetText(name)
end

function UICommunicationShakeSpeareWidget:StartShowFlowWidget()
    G.log:info("UICommunicationShakeSpeareWidget", "StartShowFlowWidget")
    UIManager:SetOverridenInputMode(UIManager.OverridenInputMode.UIOnly, false)
    UIManager:HideAllHUD()
end

function UICommunicationShakeSpeareWidget:StopShowFlowWidget()
    G.log:info("UICommunicationShakeSpeareWidget", "StopShowFlowWidget")
    UIManager:SetOverridenInputMode('')
    UIManager:RecoverShowAllHUD()
end

return UICommunicationShakeSpeareWidget
