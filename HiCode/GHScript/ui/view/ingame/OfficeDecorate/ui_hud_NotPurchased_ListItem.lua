local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

local NotPurchasedListItem = Class(UIWindowBase)
function NotPurchasedListItem:OnListItemObjectSet(ListItemObject)
    self.WBP_Btn_ListItem.Button.OnClicked:Add(self,self.SetSelectedState)
    self.WBP_Common_QuantitySelection.WBP_Btn_Subtract.Button.OnClicked:Add(self,self.SubQuantity)
    self.WBP_Common_QuantitySelection.WBP_Btn_Add.Button.OnClicked:Add(self,self.AddQuantity)
    
end

function NotPurchasedListItem:SetSelectedState()
    local bIsClicked = not self.bIsClicked
    self.bIsClicked = bIsClicked
    if bIsClicked then
        self.Switch_ListItem:SetActiveWidgetIndex(1)
    else
        self.Switch_ListItem:SetActiveWidgetIndex(0)
    end
end

function NotPurchasedListItem:SubQuantity()
end
function  NotPurchasedListItem:AddQuantity()
end

function NotPurchasedListItem:OnDestruct()
    self.WBP_Btn_ListItem.Button.OnClicked:Remove(self,self.SetSelectedState)
    self.WBP_Common_QuantitySelection.WBP_Btn_Subtract.Button.OnClicked:Remove(self,self.SubQuantity)
    self.WBP_Common_QuantitySelection.WBP_Btn_Add.Button.OnClicked:Remove(self,self.AddQuantity)
end
return NotPurchasedListItem