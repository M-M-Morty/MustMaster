local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

local IconButton = Class(UIWindowBase)

function IconButton:OnListItemObjectSet(ItemObject)
    local ItemObject = ItemObject.ItemValue
    self.Parent = ItemObject.Parent
    self.Function = ItemObject.Function
    if self.Parent ~=nil and self.Function then
        self.WBP_Btn_IconButton.Button.OnClicked:Add(self.Parent,self.Function)
    end
    if self.ItemObject.Icon ~= nil then
        self.Icon_Function:SetBrushResourceObject(self.ItemObject.Icon)
    end
    if self.ItemObject.CallbackIndex ~= nil then
        local Text =string.format(self.ItemObject.CallbackIndex)
        self.WBP_Common_PCkey:SetPCkeyText('Normal','Text',Text)
    end
    self:ShowAboveText(false)
    self:ShowBelowText(false)
end

function IconButton:OnDestruct()
    if self.Parent ~=nil and self.Function then
        self.WBP_Btn_IconButton.Button.OnClicked:Remove(self.Parent,self.Function)
        self.Parent = nil
        self.Function = nil
    end
end

function IconButton:ShowAboveText(bIsShow)
    if bIsShow then
        self.Canvas_FunctionText:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self.Canvas_FunctionText:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

function IconButton:ShowBelowText(bIsShow)
    if bIsShow then
        self.Txt_AutoSave:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self.Txt_AutoSave:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end
return IconButton