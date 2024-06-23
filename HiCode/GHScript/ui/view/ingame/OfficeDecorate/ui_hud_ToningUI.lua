local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local  ButtonTable =require('CP0032305_GH.Script.ui.view.ingame.OfficeDecorate.ButtonTable')
local ToningUI = Class(UIWindowBase)

function  ToningUI:Init()
    self.WBP_Btn_Confirm.Button.OnClicked:Add(self,self.AffirmAlterStae)
    self.WBP_Common_TextSwitcher.WBP_Common_TextSwitcher_Item_01.WBP_Btn_TextSwitcher_Item.Button.OnClicked:Add(self,self.SetTextSwitcherOn)
    self.WBP_Common_TextSwitcher.WBP_Common_TextSwitcher_Item_02.WBP_Btn_TextSwitcher_Item.Button.OnClicked:Add(self,self.SetTextSwitcherOff)
    self.WBP_Common_RightPopupWindow.WBP_Common_TopContent.CommonButton_Close.Button.OnClicked:Add(self,self.OnCloseUIClicked)
    self.WBP_Btn_ReturnToDefault.Button.OnClicked:Add(self,self.ReturnToDefault)
    self.WBP_FirmRenovation_PanchromaticAxial_01.Img_PanchromaticAxial_02_A:SetColorAndOpacity(UE.FLinearColor(0,0,0,1))
    self.DecorationVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DecorationMainVM.UniqueName)
    self:UpdateComponentItem(self)
    self.DecorationVM.RegMessageChanged(self,self.SetColorSquare,self.Tile_ColorSquare)
    self.DecorationVM.RegMessageChanged(self,self.UpdateComponentItem,self.List_ColorRound)
    self.DecorationVM.RegMessageChanged(self,self.SetColorSquare,self.Canvas_SwatchesItem)
    self:SetTextSwitcherOff()
    local CanvasSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.WBP_FirmRenovation_PanchromaticAxial_01)
    local CanvasPosition = CanvasSlot:GetPosition()
    self.WBP_FirmRenovation_PanchromaticAxial_01.CanvasPositionY = CanvasPosition.Y
    self.WBP_FirmRenovation_PanchromaticAxial_02.CanvasPositionY = CanvasPosition.Y
    self.WBP_FirmRenovation_PanchromaticAxial_01:Init()
    self.WBP_FirmRenovation_PanchromaticAxial_02:Init()
    self.DecorationVM:RegHSVDate(self.WBP_FirmRenovation_Panchromatic,{Value = 0,Key ='H',Parent = self ,Callback = self.ChangePanchromatic})
    self.DecorationVM:RegHSVDate(self.WBP_FirmRenovation_PanchromaticAxial_02,{Value = 1,Key ='S',Parent = self ,Callback = self.ChangePanchromatic})
    self.DecorationVM:RegHSVDate(self.WBP_FirmRenovation_PanchromaticAxial_01,{Value = 1,Key ='V',Parent = self ,Callback = self.ChangePanchromatic})
    self:SetSwatches()
end

function ToningUI:OnDestruct()
    self.WBP_Btn_Confirm.Button.OnClicked:Remove(self,self.AffirmAlterStae)
    self.WBP_Btn_ReturnToDefault.Button.OnClicked:Remove(self,self.ReturnToDefault)
    self.WBP_Common_TextSwitcher.WBP_Common_TextSwitcher_Item_01.WBP_Btn_TextSwitcher_Item.Button.OnClicked:Remove(self,self.SetTextSwitcherOn)
    self.WBP_Common_TextSwitcher.WBP_Common_TextSwitcher_Item_02.WBP_Btn_TextSwitcher_Item.Button.OnClicked:Remove(self,self.SetTextSwitcherOff)
    self.WBP_Common_RightPopupWindow.WBP_Common_TopContent.CommonButton_Close.Button.OnClicked:Remove(self,self.CloseToningUI)
    self.Center = nil
    self.DecorationVM.UnRegMessageChanged(self.List_ColorRound)
    self.DecorationVM.UnRegMessageChanged(self.Tile_ColorSquare)
    self.DecorationVM:UnRegHSVDate(self.WBP_FirmRenovation_Panchromatic)
    self.DecorationVM:UnRegHSVDate(self.WBP_FirmRenovation_PanchromaticAxial_02)
    self.DecorationVM:UnRegHSVDate(self.WBP_FirmRenovation_PanchromaticAxial_02)
    
end

function  ToningUI:CloseToningUI()
    local UIInfo = UIDef.UIInfo.UI_AdjustingTheInterface
    ButtonTable:ShowUI(UIInfo,self)
end

function ToningUI:OnCloseUIClicked()
    self:CloseToningUI()
end

function ToningUI:ReturnToDefault()
    self.DecorationVM:ResetFittingColor()
    self:UpdateComponentItem()
end

function ToningUI:OnColorRound(ColorItem)
    local ColorRoundProxys = WidgetProxys:CreateWidgetProxy(self.List_ColorRound)
    ColorRoundProxys:SetListItems(ColorItem)
end

function ToningUI.UpdateComponentItem(self)
    local ActorID = self.DecorationVM:GetSelectedActor()
    local info = self.DecorationVM:GetCurrentDecoration(ActorID)
    local skin = self.DecorationVM:GetDecorationSkin(info)
    local CompMessage = self.DecorationVM:GetCompMessage(skin,self,self.List_ColorRound)
    self:OnColorRound(CompMessage)
    local SquareMessage = self.DecorationVM:CreateSquareMessage(skin, self,self.Tile_ColorSquare)
    self:OnColorSquare(SquareMessage)
    
    local ColorItems = self.DecorationVM:GetCurrentSkinCompColor()
    local Color = ColorItems[self.DecorationVM:GetSelectedComponent()]
    self:SetColorSquare(Color)
    self.WBP_Common_RightPopupWindow.Txt_Title:SetText(skin)
end

function ToningUI:AffirmAlterStae()
    local ColorSquare = self.WBP_FirmRenovation_ColorInputBox.WBP_Common_ColorComponent_Square
    local CurrentColor = ColorSquare:GetCurrentColor()
    local ColorItem = self.DecorationVM:GetCurrentSkinCompColor()
    local OldColor = ColorItem[self.DecorationVM:GetSelectedComponent()]
    local bChangeColor = false
    for k, ColorValue in pairs(CurrentColor) do
        if not FunctionUtil:FloatEqual(OldColor[k], ColorValue) and k ~='A' then
            bChangeColor = true
        end
    end
    if bChangeColor then
        self.DecorationVM:SelectedFittingColor(CurrentColor)
    end
    self:CloseToningUI()
end

function ToningUI:OnColorSquare(ColorItem)
    local ColorSquarePorxys =  WidgetProxys:CreateWidgetProxy(self.Tile_ColorSquare)
    ColorSquarePorxys:SetListItems(ColorItem)
end

function ToningUI:SetTextSwitcherOn()
    self.bTextSwitcher = true
    self:CutColourDisk()
end

function ToningUI:SetTextSwitcherOff()
    self.bTextSwitcher = false
    self:CutColourDisk()
end

function ToningUI:CutColourDisk()
    if self.bTextSwitcher == true then
        self:SetPanchormSelect(self.WBP_Common_TextSwitcher.WBP_Common_TextSwitcher_Item_01)
        self.Switcher_Purchased:SetActiveWidgetIndex(0)
    else
        self:SetPanchormSelect(self.WBP_Common_TextSwitcher.WBP_Common_TextSwitcher_Item_02)
        self.Switcher_Purchased:SetActiveWidgetIndex(1)
    end
end

function ToningUI.ChangePanchromatic(self,Table)
    
    local FLinearColor = UE.UKismetMathLibrary.HSVToRGB(Table.H,Table.S,Table.V,1)
    local ProspectColor = UE.UKismetMathLibrary.HSVToRGB(Table.H, 1, 1, 1)
    self.WBP_FirmRenovation_PanchromaticAxial_02:ProspectColor(ProspectColor)
    self.WBP_FirmRenovation_PanchromaticAxial_01:ProspectColor(ProspectColor)
    local Color = {R =FLinearColor.R*255 ,G = FLinearColor.G * 255 , B = FLinearColor.B * 255 ,A=FLinearColor.A*255}
    self:SetColorSquare(Color)
end

function ToningUI.SetColorSquare(self,Color)
    local ColorSquare = self.WBP_FirmRenovation_ColorInputBox.WBP_Common_ColorComponent_Square
    ColorSquare:SetShowColor(Color)
end

function ToningUI:SetSwatches()
    local AllChaildern = self.Canvas_SwatchesItem:GetAllChildren()
    local Defaults = self.DecorationVM:DefaultSwatches()
    if Defaults == nil then
        return
    end
    local ColorItem = Defaults.ColorItem
    for i = 1, AllChaildern:Length(), 1 do
       local Chaildern = AllChaildern:Get(i)
       Chaildern:ChangeColor(ColorItem[i])
       Chaildern.Parent = self
       Chaildern.Traget = self.Canvas_SwatchesItem
    end

end

function ToningUI:SetPanchormSelect(Widget)
    local TextSwitcher01 = self.WBP_Common_TextSwitcher.WBP_Common_TextSwitcher_Item_01
    local selectFirst = (Widget == TextSwitcher01)
    self.WBP_Common_TextSwitcher.WBP_Common_TextSwitcher_Item_01.Switch_Text:SetActiveWidgetIndex(selectFirst and 1 or 0)
    self.WBP_Common_TextSwitcher.WBP_Common_TextSwitcher_Item_02.Switch_Text:SetActiveWidgetIndex(selectFirst and 0 or 1)
end
return ToningUI