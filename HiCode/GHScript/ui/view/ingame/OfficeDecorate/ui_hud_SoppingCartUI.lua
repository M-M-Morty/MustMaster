
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local ButtonTable =require('CP0032305_GH.Script.ui.view.ingame.OfficeDecorate.ButtonTable')
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')

local ShoppingCartUI = Class(UIWindowBase)

local QuitText = "ITEM_MINIGAME_SCQUIT_TEXT"
local TitleText = "ITEM_USE_TITILE"



local function OnListViewScrolled(self, OffsetInitems, ListView, RetaBox)
    local showUp = FunctionUtil:FloatZero(OffsetInitems)
    local showDown = true
    local EntryWidgets = ListView:GetDisplayedEntryWidgets()
    local widget = EntryWidgets:Get(1)
    if widget then
        local WidgetGeometry = widget:GetCachedGeometry()
        local ListLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(WidgetGeometry)
        local ContainerSize = RetaBox.Slot:GetSize()
        local Total = ListView:GetNumItems()
        local itemCount = ContainerSize.Y / ListLocalSize.Y
        showDown = (OffsetInitems + 0.1) > (Total - itemCount)
    end

    local EffectMaterial = RetaBox:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", showDown and 1.6 or 0)
    EffectMaterial:SetScalarParameterValue("Power2", showUp and 1.6 or 0)
end


local function OnNotPurchasedScrolled(self, OffsetInitems, DistanceRemaining)
    OnListViewScrolled(self,OffsetInitems,self.List_NotPurchased,self.RetaBox_NotPurchased_FadeOut)
end

function ShoppingCartUI:Init(Data)
    if Data ~= nil then
        self.Initiator = Data.Initiator
        self.Owner = Data.Owner
    end
    self.bCheckAll = true
    self.WBP_Common_RightPopupWindow.Txt_Title:SetText('未购买项')
    self.DecorationMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DecorationMainVM.UniqueName)
    self.BuysItems = {}
    self:CutPurchasedUI()
    self.WBP_Btn_Manage.Button.OnClicked:Add(self,self.CutPurchasedUI)
    self.WBP_Btn_Return.Button.OnClicked:Add(self,self.CutPurchasedUI)
    self.WBP_Btn_Confirm.Button.OnClicked:Add(self,self.BuysArticle)
    self.WBP_ComBtn_CheckBox.WBP_Btn_CheckBox.Button.OnClicked:Add(self,self.CheckAll)
    self.WBP_Common_RightPopupWindow.WBP_Common_TopContent.CommonButton_Close.Button.OnClicked:Add(self,self.OnCloseShoppingCartUI)
    self.ShoppingCartProxy = WidgetProxys:CreateWidgetProxy(self.List_ShoppingCartManagement)
    self.NotPurchasedProxy = WidgetProxys:CreateWidgetProxy(self.List_NotPurchased)
    self.AllChildNotPurchased = {}
    self:ChangeShopCarList()
    self.List_NotPurchased.BP_OnListViewScrolled:Add(self, OnNotPurchasedScrolled)
end

function ShoppingCartUI:CutPurchasedUI()
    if self.bPurchased  then
        self.Switcher_Purchased:SetActiveWidgetIndex(1)
        self.bPurchased = false
    else
        self.Switcher_Purchased:SetActiveWidgetIndex(0)
        self.bPurchased = true
    end
end
function ShoppingCartUI:OnCloseShoppingCartUI()
    if self.Initiator == 'MainInterfaceHUD' then
        self.DecorationMainVM: SetInitialState(true)
    end
    self.DecorationMainVM:SetCameraFocusTo()
    local UIInfo = UIDef.UIInfo.UI_OfficeDecorateMainUI
    ButtonTable:ShowUI(UIInfo,self)
end

function ShoppingCartUI:OnDestruct()
    self.WBP_Btn_Manage.Button.OnClicked:Remove(self,self.CutPurchasedUI)
    self.WBP_Btn_Return.Button.OnClicked:Remove(self,self.CutPurchasedUI)
    self.WBP_Common_RightPopupWindow.WBP_Common_TopContent.CommonButton_Close.Button.OnClicked:Remove(self,self.OnCloseShoppingCartUI)
    self.AllChildNotPurchased = nil
    self.BuysItems = nil
    self.bCheckAll = nil
end

function ShoppingCartUI:ChangeShopCarList()
    local tbShop = self.DecorationMainVM:GetShopCarList()
    if tbShop == nil then
        return
    end
    local pf_less = function(a, b)
        if a.Skin ~= b.Skin then
            return a.Skin < b.Skin
        else
            return (a.Color and 1 or 0) < (b.Color and 1 or 0)
        end
    end
    table.sort(tbShop, pf_less)
    self.tbShopItem = {}
    for i, v in pairs(tbShop) do
        if v.Color then
            v.ID = self.DecorationMainVM:GetSkinRelatedItem(v.Skin)
            --v.IconPath | IconResourceObject
        else
            v.ID = self.DecorationMainVM:GetSkinRelatedItem(v.Skin)
        end
        v.Identify = i;
        v.Number = v.Count or 1
        v.Quality = 1
        v.Ower = self
        table.insert(self.tbShopItem, v)
    end

    self.NotPurchasedProxy:SetListItems(self.tbShopItem)
    self.ShoppingCartProxy:SetListItems(self.tbShopItem)
end
function ShoppingCartUI:BuysArticle()

    local bAdequate = true
    local CurrencyStateTable = self:IsCurrencyAdequate()
    local Differences = {}
    for CurrencyID, Data in pairs(CurrencyStateTable) do
        if not Data.State then
            bAdequate = Data.State
            table.insert(Differences,{Currency = CurrencyID ,Difference= Data.Difference})
        end
    end
    if bAdequate then
        self:NormalBuy()
    else
        self:AbmormalBuy(Differences)
    end
end

function ShoppingCartUI:ShowAlllPrice()
    local AllPrice = 0
    for k, Item in pairs(self.BuysItems) do
        AllPrice = AllPrice + Item.Price.Count * (Item.Count or 1)
    end
    self.Txt_CheckPrompt:SetText(#self.BuysItems)
    self.Txt_Currency_02:SetText(AllPrice)
end

function ShoppingCartUI:RemoveArticle(Item)
    self.DecorationMainVM:RemoveShopCarItems({Item})
    self:ChangeShopCarList()
end

function ShoppingCartUI:CheckAll()
    self.bCheckAll = not self.bCheckAll
    if self.bCheckAll then
        self.WBP_ComBtn_CheckBox.Switch_Check:SetActiveWidgetIndex(0)
    else
        self:NotCheckAll()
    end
    for _, ChildNotPurchased in ipairs(self.AllChildNotPurchased) do
        ChildNotPurchased:SetSelectedState(self.bCheckAll)
    end
    
end

function ShoppingCartUI:NotCheckAll()
    self.bCheckAll = false
    self.WBP_ComBtn_CheckBox.Switch_Check:SetActiveWidgetIndex(1)
end

function ShoppingCartUI:Item()
    
end

function ShoppingCartUI:IsCurrencyAdequate()
    local CurrencyAdequate = {}
    local t = {}
    for k, Item in pairs(self.BuysItems) do
        local PriceID = Item.Price.ID 
        local c = Item.Price.Count * (Item.Count or 1)
        if PriceID ~= nil then
            t[PriceID] = (t[PriceID] or 0) + c
        end
        
    end
    for CurrencyID, Count in pairs(t) do
        local ItemManager = ItemUtil.GetItemManager(self)
        local CurrencyCount = ItemManager:GetItemCountByExcelID(CurrencyID)
        if CurrencyCount < Count then
            CurrencyAdequate[CurrencyID] = {State = false,Difference = Count - CurrencyCount}
        else
            CurrencyAdequate[CurrencyID] = {State = true}
        end
    end
    return CurrencyAdequate
end

function ShoppingCartUI:NormalBuy() ---货币充足
    self.DecorationMainVM:BuyShopCarItems(self.BuysItems)
    self.BuysItems = {}
    if self.Initiator ~= nil  then
        if self.Initiator == 'ShopItem'  then
            self:ChangeShopCarList()
        elseif self.Initiator == 'OfficeMainUI' then
            UIManager:CloseUIImmediately(self.Owner,true)
            self.DecorationMainVM:SetCameraFocusTo()
            local UIInfo = UIDef.UIInfo.UI_MainInterfaceHUD
            ButtonTable:ShowUI(UIInfo,self)
        elseif self.Initiator == 'MainInterfaceHUD' then
            self:OnCloseShoppingCartUI()
        end
    else
        self:OnCloseShoppingCartUI()
    end
end


function ShoppingCartUI:AbmormalBuy(Differences) ---第一次弹窗
    local bAdequate = nil
    local CurrencyID = nil ---代币ID
    
    local Price = 0
    for i, v in ipairs(Differences) do ---TODO需换为货币转代币
        Price = Price + v.Difference
        if CurrencyID == nil then
            CurrencyID = v.Currency
        end
    end
    local ItemManager = ItemUtil.GetItemManager(self)
    local CurrencyCount = ItemManager:GetItemCountByExcelID(CurrencyID)
    bAdequate = Price < (CurrencyCount or 0)
    local CommitCallback 
    local Title 
    local Quit
    if bAdequate then ---代币是否充足
        CommitCallback = self.ConversionCurrency
        Title = TitleText
        Quit = QuitText
    else
        CommitCallback = self.IsOpenShopPopup
        Title = TitleText
        Quit = QuitText
    end
    self:OpenPopup(Title,Quit,CommitCallback)
end


function ShoppingCartUI:IsOpenShopPopup() ---第二次弹窗(跳转商城)
    local PopUpInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_Common_SecondTextConfirm.UIName)
    UIManager:CloseUI(PopUpInstance,true)
    self:OpenPopup(TitleText,QuitText,function ()
        ---跳转商城
    end)
end


function ShoppingCartUI:ConversionCurrency() ---第二次弹窗(兑换货币)
    local PopUpInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_Common_SecondTextConfirm.UIName)
    UIManager:CloseUI(PopUpInstance,true)
    self:OpenPopup(TitleText,QuitText,function ()
        ---兑换货币
    end)
end

function ShoppingCartUI:OpenPopup(TitleText,QuitText,CommitCallback)
    self.PopUpInstance = UIManager:OpenUI(UIDef.UIInfo.UI_Common_SecondTextConfirm)
    self.PopUpInstance:SetTitleAndContent(TitleText,QuitText)
    if CommitCallback ~= nil then
        self.PopUpInstance.WBP_Common_Popup_Small:BindCommitCallBack(self, CommitCallback)
    end
end


return ShoppingCartUI