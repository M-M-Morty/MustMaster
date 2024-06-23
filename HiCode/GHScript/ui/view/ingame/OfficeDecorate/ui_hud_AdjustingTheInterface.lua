local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local AdjustingTheInterface = Class(UIWindowBase)
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local  ButtonTable =require('CP0032305_GH.Script.ui.view.ingame.OfficeDecorate.ButtonTable')


local function HintCancel(self)
    ButtonTable:ShowUI(nil,self)
end

local function HintCommit(self)
    local DecorationVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DecorationMainVM.UniqueName)
    local UIInfo = UIDef.UIInfo.UI_OfficeDecorateMainUI
    ButtonTable:ShowUI(nil,self.ParentUI)
    DecorationVM:SetChangeColor(DecorationVM:GetSelectedActor(),DecorationVM:GetSelectedSkin(),'Default')
    ButtonTable:ShowUI(UIInfo,self)
end

function AdjustingTheInterface:Init(InbIsSelected)
    self.DecorationVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DecorationMainVM.UniqueName)
    local bIsSelected = nil
    
    if InbIsSelected then
        bIsSelected ='Selected'
    else
        bIsSelected = 'Default'
    end
    self:InitialData(bIsSelected,"HomeDecor_Furnitures_0")
    self.WBP_Common_TopContent.CommonButton_Close.Button.OnClicked:Add(self,self.OnCloseAdjustingUIClicked)
    self.WBP_Btn_Adjust.Button.OnClicked:Add(self,self.ShowToningUI)
    self.DecorationVM.RegMessageChanged(self,self.OnColorRound,self.List_ColorRound)
    self.DecorationVM:SetChangeColor()
end


function AdjustingTheInterface:InitialData(IsbDefault,ActorID)
    local tbList  = self.DecorationVM:GetSkinList(ActorID)
    local SkinMessage = {}
    for Skin, v in pairs(tbList) do
        local config, runtime = self.DecorationVM:GetSkinData(ActorID, Skin)
        --[[
        runtime.Unlocked --是否锁
        runtime.Owned --是否已拥有
        config.UnlockItemlD --解锁道具ID
        config.UnlockItemNum --解锁道具数量
        config.Icon --TODO
        config.Name --TODO
        config.Index --SkinID
        #config.CompName = { ... } #config.CompName 部件名称数量
        ]]
        local Message = self.DecorationVM:GetSkinMessage(ActorID,Skin)
        if Message == nil then
            Message = {}
            local ExistColors =runtime.ExistColors
            for partidx = 1, #config.CompName do
                local color = ExistColors[partidx][1]
                self.DecorationVM:SetSkinMessage(ActorID,Skin,config.CompName[partidx],color,true,'Default')
                table.insert(Message,{ComponentName = config.CompName[partidx],Color = color,AlterState = true})
            end
        end
        table.insert(SkinMessage,{ActorID = ActorID,SkinName = Skin,UnlockItemNum = config.UnlockItemNum,SkinMessages = Message,Target = self.List_ColorRound,Parent = self})
    end
    if IsbDefault == 'Default' then
        self.DecorationVM:SetSelectedActor(ActorID)
        self.DecorationVM:SetSelectedSkin(SkinMessage[1].SkinName)
        self.DecorationVM:SetSelectedComponent(SkinMessage[1].SkinMessages.ComponentName)
    end
    local ColorSquarePorxys =  WidgetProxys:CreateWidgetProxy(self.Tile_SkinIcon)
    ColorSquarePorxys:SetListItems(SkinMessage)
    local SelecteSkinMessage = self.DecorationVM:GetSkinMessage(self.DecorationVM:GetSelectedActor(),self.DecorationVM:GetSelectedSkin())
    self:OnColorRound(SelecteSkinMessage)
end

function AdjustingTheInterface:SetSkinModule(SkinModule,Row,Column)
    self.Skin_UniformGridPanel:AddChildToUniformGrid(SkinModule,Row,Column)
end

function AdjustingTheInterface.OnColorRound(self,ColorItem)
    local PurchasedProxys = WidgetProxys:CreateWidgetProxy(self.List_ColorRound)
    PurchasedProxys:SetListItems(ColorItem)
end

function AdjustingTheInterface:OnCloseAdjustingUIClicked()
    local bAlterStae = self.DecorationVM:GetIsSkinAlterStae()
    if bAlterStae then
        local UIInfo = UIDef.UIInfo.UI_OfficeDecorateMainUI
        ButtonTable:ShowUI(UIInfo,self)
    else
        local InitializeDate = {}
        InitializeDate.Cancel = HintCancel
        InitializeDate.Commit = HintCommit
        InitializeDate.ParentUI = self
        InitializeDate.Execute = 1
        local UIInfo = UIDef.UIInfo.UI_HintUI
        ButtonTable:ShowUI(UIInfo,nil,false,InitializeDate)
    end
end

function AdjustingTheInterface:ShowToningUI()
    local UIInfo = UIDef.UIInfo.UI_Toning
    ButtonTable:ShowUI(UIInfo,self)
end

function AdjustingTheInterface:OnDestruct()
    self.WBP_Common_TopContent.CommonButton_Close.Button.OnClicked:Remove(self,self.OnCloseAdjustingUIClicked)
    self.WBP_Btn_Adjust.Button.OnClicked:Remove(self,self.ShowToningUI)
    self.DecorationVM = nil
    self.DecorationVM.UnRegMessageChanged(self.List_ColorRound)
end


return AdjustingTheInterface