local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

local ColorComponent_Square = Class(UIWindowBase)

function ColorComponent_Square:OnListItemObjectSet(ItemObject)
    local ItemValue = ItemObject.ItemValue
    self.Target = ItemValue.Target
    self.BelongComponent = ItemValue.ComponentName
    local Color = ItemValue.Color
    self:SetShowColor(Color)
    local Parent = ItemValue.Parent
    self:SetParent(Parent)
    
end

function ColorComponent_Square:OnConstruct()
    self.WBP_Btn_ColorSquare.Button.OnClicked:Add(self,self.OnButtonClicked)
end
function ColorComponent_Square:SetShowColor(Color)
    self.Img_Color_Square:SetColorAndOpacity(Color)
    self.CurrentColor = Color
end

function ColorComponent_Square:SetParent(Parent)
    self.Parent = Parent
end

function ColorComponent_Square:OnButtonClicked()
    local DecorationVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DecorationMainVM.UniqueName)
    DecorationVM:SetSkinMessage(DecorationVM:GetSelectedActor(),DecorationVM:GetSelectedSkin(),DecorationVM:GetSelectedComponent(), self.CurrentColor)
    DecorationVM.NotifyMessageChanged(self.Parent,self.Target)
    DecorationVM:SetChangeColor()
end
function ColorComponent_Square:OnDestruct()
    self.WBP_Btn_ColorSquare.Button.OnClicked:Remove(self,self.OnButtonClicked)
    self.Target = nil
    self.CurrentColor = nil
    self.Parent = nil
end
return ColorComponent_Square