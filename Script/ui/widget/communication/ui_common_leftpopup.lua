
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')

---@type WBP_Common_LeftPopupWindow_C
local ui_common_leftpropup = Class(UIWindowBase)

function ui_common_leftpropup:OnConstruct()
    self.List_PropProxy = WidgetProxys:CreateWidgetProxy(self.List_Prop)
    self.listitems = {}
end

function ui_common_leftpropup:InitWidget(title, bShowCloseBtn)
    self.Img_PropListBg.WBP_Common_TopContent.CommonButton_Close:SetVisibility(bShowCloseBtn)
    self.Img_PropListBg.Txt_Title:SetText(title)
end

function ui_common_leftpropup:LoadItemList(items)
    self.List_Prop:ClearListItems()
    for id, item in pairs(items) do
        self.List_PropProxy:AddItem(item)
    end
end

function ui_common_leftpropup:AddListItem(item)
    self.listitems[item.itemData.itemId] = item
end

function  ui_common_leftpropup:RefreshItem(itemData)
    for id, item in pairs(self.listitems) do
        if itemData.itemId == id then
            item:SetItem(itemData)
        end
    end
end

function  ui_common_leftpropup:PlayOutAnim()
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function  ui_common_leftpropup:PlayInAnim()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

return ui_common_leftpropup
