local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')
local ComponentBase = require("common.componentbase")

local UI3DComponent = Class(ComponentBase)


function UI3DComponent:ReceiveBeginPlay()
    Super(UI3DComponent).ReceiveBeginPlay(self)
    UIManager:Add3DUIComponent(self)
    self.bHidden3DUI = false
end

function UI3DComponent:HiddenComponent()
    self.bHidden3DUI = true
    self:SetVisibility(false)
end

function UI3DComponent:ShowComponent()
    self.bHidden3DUI = false
    self:SetVisibility(true)
end
return UI3DComponent
