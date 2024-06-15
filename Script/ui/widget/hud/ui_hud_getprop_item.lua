--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local ItemDef = require("CP0032305_GH.Script.item.ItemDef")
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local PicConst = require("CP0032305_GH.Script.common.pic_const")

---@type WBP_HUD_GetProp_GetPropList_Item_C
local WBP_HUD_GetProp_Item = Class(UIWidgetListItemBase)

--function WBP_HUD_GetProp_Item:Initialize(Initializer)
--end

--function WBP_HUD_GetProp_Item:PreConstruct(IsDesignTime)
--end

function WBP_HUD_GetProp_Item:OnConstruct()
    self.Image_IconProxy = WidgetProxys:CreateWidgetProxy(self.Image_Icon)
end

function WBP_HUD_GetProp_Item:DXEventShowEnd()
    self.ItemValue.bFadeOutEnd = true
end

-- function WBP_HUD_GetProp_Item:Tick(MyGeometry, InDeltaTime)
-- end

function WBP_HUD_GetProp_Item:OnListItemObjectSet(ListItemObject)
    self.ItemValue = ListItemObject.ItemValue
    self.ItemValue.bFadeOutEnd = false
    self.ItemValue.PassedTime = 0
    if self.ItemValue.Item.IconResourceObject then
        self.Image_Icon:SetBrushResourceObject(self.ItemValue.Item.IconResourceObject)
    elseif self.ItemValue.Item.IconPath then
        self.Image_IconProxy:SetImageTexturePath(self.ItemValue.Item.IconPath)
    end
    self.Text_ItemName:SetText(self.ItemValue.Item.Name)
    self.Text_Number:SetText(self.ItemValue.Item.Number)
    self.ItemPanel:SetRenderOpacity(0)

    local ItemQualityConfig = ItemUtil.GetItemQualityConfig(self.ItemValue.Item.Quality)
    PicConst.SetImageBrush(self.ImageBg, ItemQualityConfig.normal_get_bg)

    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    if self.ItemValue.Item.Quality == ItemDef.Quality.ORANGE then
        self:PlayAnimation(self.DX_ItemGetOrange, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end
end

return WBP_HUD_GetProp_Item
