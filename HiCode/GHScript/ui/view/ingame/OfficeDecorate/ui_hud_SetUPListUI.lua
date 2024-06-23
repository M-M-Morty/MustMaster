local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')


local SetUPListUI = Class(UIWindowBase)

function SetUPListUI:OnListItemObjectSet(ListItemObject)
    local PurchasedProxys = WidgetProxys:CreateWidgetProxy(self.List_SetUpList)
    PurchasedProxys:SetListItems(ListItemObject.ItemValue)
end
return SetUPListUI