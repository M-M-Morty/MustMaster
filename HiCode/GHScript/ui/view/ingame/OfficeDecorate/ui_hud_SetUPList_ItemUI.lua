local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

local SetUPList_ItemUI = Class(UIWindowBase)
function SetUPList_ItemUI:OnListItemObjectSet(ListItemObject)
end
function SetUPList_ItemUI:OnConstruct()
    self.WBP_Common_OnOff.WBP_Btn_OnOff.Button.OnClicked:Add(self,self.CutButtonState)
    local Button = self.WBP_Common_OnOff
    if self.ButtonPosition ==nil then
        self.ButtonPosition = Button.Img_OnOffDot.Slot:GetPosition()
    end
    self:CutButtonState()
end 
function SetUPList_ItemUI:CutButtonState()
    local Button = self.WBP_Common_OnOff
    if self.bButtonState  then
        Button.Img_On:SetVisibility(UE.ESlateVisibility.Hidden)
        Button.Img_OnOffDot.Slot:SetPosition(UE.FVector2D(self.ButtonPosition.X*-1,self.ButtonPosition.Y))
        self.bButtonState =false
    else
        Button.Img_On:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        Button.Img_OnOffDot.Slot:SetPosition(self.ButtonPosition)
        self.bButtonState =true
    end
end
function SetUPList_ItemUI:OnDestruct()
    self.WBP_Common_OnOff.WBP_Btn_OnOff.Button.OnClicked:Remove(self,self.CutButtonState)
end
return SetUPList_ItemUI