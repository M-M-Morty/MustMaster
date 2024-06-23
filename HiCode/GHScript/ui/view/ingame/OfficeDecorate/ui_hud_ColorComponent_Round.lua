local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local ColorComponent_Round = Class(UIWindowBase)



function ColorComponent_Round:OnListItemObjectSet(ItemObject)
   
    local ItemValue = ItemObject.ItemValue
    local BelongComp = ItemValue.ComponentName
    local Target = ItemValue.Target
    local Parent = ItemValue.Parent
    self:SetButtnType(ItemValue.ButtonType)
    self.Item = ItemObject.ItemValue
    self:SetBelongComponent(ItemValue.Component)
    self:SetTarget(Target)
    self:SetParent(Parent)
    self:SetShowColor()
    self:RefreshSelected()
end
function ColorComponent_Round:OnConstruct()
    self.WBP_Btn_ColorRound.Button.OnClicked:Add(self,self.OnButtonClicked)
end

function ColorComponent_Round:RefreshSelected()
    local SelectID = self.DecorationVM:GetSelectedComponent()
    if self.BelongComponent == SelectID then
        self.Img_ColourRound_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Img_ColourRound_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function ColorComponent_Round:SetShowColor()
    if self.DecorationVM ==nil then
        local DecorationVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DecorationMainVM.UniqueName)
        self.DecorationVM = DecorationVM
    end
    local ColorItems = self.DecorationVM:GetCurrentSkinCompColor()
    local Color = ColorItems[self.BelongComponent] or {R = 255,G = 255,B = 255,A = 255}
    
    local ColorA = Color.A
    if Color.A <= 0 then
        ColorA =255
    end
    self.Img_ColorRound:SetColorAndOpacity(UE.FLinearColor(Color.R/255,Color.G/255,Color.B/255,ColorA/255))
    self.CurrentColor = Color
    
end
function ColorComponent_Round:SetBelongComponent(BelongComp)
    self.BelongComponent = BelongComp
end
function ColorComponent_Round:SetTarget(Target)
   self.Target = Target
end

function ColorComponent_Round:SetParent(Parent)
    self.Parent = Parent
end

function ColorComponent_Round:SetButtnType(ButtonType)
    self.ButtonType = ButtonType
end

function ColorComponent_Round:OnButtonClicked ()
    if self.ButtonType == 'SkinButton' then
        return
    end
    if self.DecorationVM ==nil then
        local DecorationVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DecorationMainVM.UniqueName)
        self.DecorationVM = DecorationVM
    end
    self.DecorationVM:SetSelectedComponent(self.BelongComponent)
    if self.Parent ~=nil and self.Parent.UpdateComponentItem ~= nil then
        self.Parent:UpdateComponentItem()
    end
end

function ColorComponent_Round:OnDestruct()
    self.WBP_Btn_ColorRound.Button.OnClicked:Remove(self,self.OnButtonClicked)
    self.CurrentColor = nil
    self.Target = nil
    self.Parent = nil
end



return ColorComponent_Round