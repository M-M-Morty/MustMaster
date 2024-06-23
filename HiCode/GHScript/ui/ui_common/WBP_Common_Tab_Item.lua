--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class TabColorParam
---@field UnselectIconColor FLinearColor
---@field SelectIconColor FLinearColor
---@field HoverIconColor FLinearColor
---@field HoverTextColor FSlateColor
---@field HoverTextBgColor FLinearColor
---@field SelectImage UPaperSprite

---@class WBP_Common_Tab_Item : WBP_Common_Tab_Item_C
---@field OwnerWidget WBP_Common_Tab
---@field Index integer
---@field bIsHovered boolean
---@field TabColorParam TabColorParam

---@type WBP_Common_Tab_Item_C
local WBP_Common_Tab_Item = UnLua.Class()

local ConstText = require("CP0032305_GH.Script.common.text_const")
local ConstPic = require("CP0032305_GH.Script.common.pic_const")

---@param self WBP_Common_Tab_Item
local function ResetTabColorParams(self)
    self.TabColorParam = {}
    if self.OwnerWidget.bIsDark then
        self.TabColorParam.UnselectIconColor = self.DarkImageUnselectLinearColor
        self.TabColorParam.SelectIconColor = self.DarkImageSelectLinearColor
        self.TabColorParam.HoverIconColor = self.DarkImageHoverLinearColor
        self.TabColorParam.HoverTextColor = self.DarkHoverTextSlateColor
        self.TabColorParam.HoverTextBgColor = self.DarkHoverTextBgLinearColor
        self.TabColorParam.SelectImage = self.DarkSelectImage
    else
        self.TabColorParam.UnselectIconColor = self.LightImageUnselectLinearColor
        self.TabColorParam.SelectIconColor = self.LightImageSelectLinearColor
        self.TabColorParam.HoverIconColor = self.LightImageHoverLinearColor
        self.TabColorParam.HoverTextColor = self.LightHoverTextSlateColor
        self.TabColorParam.HoverTextBgColor = self.LightHoverTextBgLinearColor
        self.TabColorParam.SelectImage = self.LightSelectImage
    end
end

---@param self WBP_Common_Tab_Item
local function RefreshState(self, bSelected)
    if self.Index == self.OwnerWidget.SelectedIndex then
        self.Img_TabIcon_Pressed:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        -- self.Img_TabIcon_Pressed:SetBrushResourceObject(self.TabColorParam.SelectImage)
        self.Cvs_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Img_TabIcon:SetColorAndOpacity(self.TabColorParam.SelectIconColor)
        if bSelected then
            UE.UAkGameplayStatics.PostEvent(self.SwitchTabAkAudioEvent, UE.UGameplayStatics.GetPlayerPawn(self, 0), nil, nil, true)
            self:PlayAnimation(self.DX_Select, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
        end
    elseif self.bIsHovered then
        self.Img_TabIcon_Pressed:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Img_TabIcon:SetColorAndOpacity(self.TabColorParam.HoverIconColor)
        self.Cvs_Hover:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.BorderTextBg:SetBrushColor(self.TabColorParam.HoverTextBgColor)
        self.Text_IconName:SetColorAndOpacity(self.TabColorParam.HoverTextColor)
    else
        self.Img_TabIcon_Pressed:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Cvs_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Img_TabIcon:SetColorAndOpacity(self.TabColorParam.UnselectIconColor)
    end
end

---@param self WBP_Common_Tab_Item
local function OnClickButton(self)
    self.OwnerWidget:SelectTab(self.Index)
end

---@param self WBP_Common_Tab_Item
local function OnHoveredButton(self)
    self.bIsHovered = true
    RefreshState(self)
end

---@param self WBP_Common_Tab_Item
local function OnUnhoveredButton(self)
    self.bIsHovered = false
    RefreshState(self)
end

---@param self WBP_Common_Tab_Item
---@param Index integer
local function OnSelectedTab(self, Index)
    RefreshState(self, true)
end

---@param self WBP_Common_Tab_Item
---@param bHasRedDot boolean
local function ShowRedDot(self, bHasRedDot)
    if bHasRedDot then
        self.WBP_Common_RedDot:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.WBP_Common_RedDot:ShowRedDot()
    else
        self.WBP_Common_RedDot:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self WBP_Common_Tab_Item
---@param Index integer
---@param bHasRedDot boolean
local function OnRedDotChanged(self, Index, bHasRedDot)
    if self.Index == Index then
        ShowRedDot(self, bHasRedDot)
    end
end

---Called when this entry is assigned a new item object to represent by the owning list view
---@param ListItemObject BP_CommonTabItemObject_C
---@return void
function WBP_Common_Tab_Item:OnListItemObjectSet(ListItemObject)
    ---@type WBP_Common_Tab
    self.OwnerWidget = ListItemObject.OwnerWidget
    self.Index = ListItemObject.Index

    ResetTabColorParams(self)
    self.Switch_TabIconState:SetActiveWidgetIndex(ListItemObject.StyleKey or 0)
    ConstPic.SetImageBrush(self.Img_TabIcon, ListItemObject.PicKey)
    local Name = ConstText.GetConstText(ListItemObject.NameKey)
    self.Text_IconName:SetText(Name)

    ShowRedDot(self, ListItemObject.bHasRedDot)

    self.OwnerWidget:RegOnSelectTab(self, OnSelectedTab)
    self.OwnerWidget:RegOnRedDotChanged(self, OnRedDotChanged)


    RefreshState(self)
end

function WBP_Common_Tab_Item:Construct()
    self.bIsHovered = false
    self.Btn_TabIcon.OnClicked:Add(self, OnClickButton)
    self.Btn_TabIcon.OnHovered:Add(self, OnHoveredButton)
    self.Btn_TabIcon.OnUnhovered:Add(self, OnUnhoveredButton)
end

function WBP_Common_Tab_Item:Destruct()
    self.Btn_TabIcon.OnClicked:Remove(self, OnClickButton)
    self.Btn_TabIcon.OnHovered:Remove(self, OnHoveredButton)
    self.Btn_TabIcon.OnUnhovered:Remove(self, OnUnhoveredButton)
    self.OwnerWidget:UnRegOnSelectTab(self, OnSelectedTab)
    self.OwnerWidget:UnRegOnRedDotChanged(self, OnRedDotChanged)
end

return WBP_Common_Tab_Item
