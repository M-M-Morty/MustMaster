local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local  ButtonTable =require('CP0032305_GH.Script.ui.view.ingame.OfficeDecorate.ButtonTable')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local Item = 
{
{1,2},
{1,2,3},
{1,2,3},
{1,2,3},
{1,2,3},
{1,2,3},
}
local SetUP_UI = Class(UIWindowBase)
function SetUP_UI:Init()
    local PurchasedProxys = WidgetProxys:CreateWidgetProxy(self.List_Purchased)
    PurchasedProxys:SetListItems(Item)
    self.WBP_Common_TopContent.CommonButton_Close.Button.OnClicked:Add(self,self.OnCloseSetUP_UI)
end
function SetUP_UI:OnCloseSetUP_UI()
    local UIInfo = UIDef.UIInfo.UI_OfficeDecorateMainUI
    ButtonTable:ShowUI(UIInfo,self)
end

function SetUP_UI:OnDestruct()
    self.WBP_Common_TopContent.CommonButton_Close.Button.OnClicked:Remove(self,self.OnCloseSetUP_UI)
end
return SetUP_UI