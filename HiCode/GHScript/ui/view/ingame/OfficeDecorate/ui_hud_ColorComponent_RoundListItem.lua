local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

local ColorComponent_RoundListItem = Class(UIWindowBase)

function ColorComponent_RoundListItem:OnListItemObjectSet(ItemObject)
    local ItemValue = ItemObject.ItemValue
    local BelongComp= ItemValue.ComponentName
    local Color = ItemValue.Color
    local Target = ItemValue.Target
    local Parent = ItemValue.Parent
    self:SetBelongComponent(BelongComp)
    self:SetShowColor(Color)
    self:SetTarget(Target)
    self:SetParent(Parent)
    self.WBP_Common_ColorComponent_Round:RefreshSelected()
end
function ColorComponent_RoundListItem:SetShowColor(Color)
    self.WBP_Common_ColorComponent_Round:SetShowColor(Color)
end

function ColorComponent_RoundListItem:SetBelongComponent(BelongComp)
    self.WBP_Common_ColorComponent_Round:SetBelongComponent(BelongComp)
end
function ColorComponent_RoundListItem:SetTarget(Target)
    self.WBP_Common_ColorComponent_Round:SetTarget(Target)
end
function ColorComponent_RoundListItem:SetParent(Parent)
    self.WBP_Common_ColorComponent_Round:SetParent(Parent)
end

function ColorComponent_RoundListItem:OnDestruct()
    
end

return ColorComponent_RoundListItem