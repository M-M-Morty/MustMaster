--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')

---@type WBP_HeadInfo_C
local M = Class(UIWidgetBase)

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:OnConstruct()
    if self:GetOwningLocalPlayer() then
        ---@type UTextBlockProxy
        self.TitleProxy = WidgetProxys:CreateWidgetProxy(self.Title)

        ---@type UImageProxy
        self.IconProxy = WidgetProxys:CreateWidgetProxy(self.Icon)

        if self.OnConstructDelegate then
            self.OnConstructDelegate(self)
        end
    end
end

-- function M:Tick(MyGeometry, InDeltaTime)
-- end

function M:SetOnConstructDelegate(fnDelegate)
    self.OnConstructDelegate = fnDelegate
end

return M
