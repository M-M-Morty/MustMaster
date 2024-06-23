--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@type WBP_PropItem_C
local UIPropItem = Class(UIWidgetListItemBase)

--function UIPropItem:Initialize(Initializer)
--end

--function UIPropItem:PreConstruct(IsDesignTime)
--end

function UIPropItem:OnConstruct()
    self:InitWidget()
    self:BuildWidgetProxy()
end

function UIPropItem:SetItemData(PropItem, bShowNumber)
    self.PropItem = PropItem
    local Quality = PropItem.Quality
    if PropItem.ID then
        local ItemConfig = ItemUtil.GetItemConfigByExcelID(PropItem.ID)
        if ItemConfig == nil then
            error("This data is invalid")
        else
            PicConst.SetImageBrush( self.Img_PropIcon, ItemConfig.icon_reference)
            Quality = ItemConfig.quality
        end

    else
        if PropItem.IconResourceObject then
            self.Img_PropIcon:SetBrushResourceObject(PropItem.IconResourceObject)
        elseif PropItem.IconPath then
            self.Image_IconProxy:SetImageTexturePath(PropItem.IconPath)
        end
    end
    local QualityConfig = ItemUtil.GetItemQualityConfig(Quality)
    PicConst.SetImageBrush(self.Image_Bg, QualityConfig.icon_reference_small)
    
    self.Text_Num:SetText(tostring(PropItem.Number))
    if not bShowNumber and PropItem.Number <= 1 then
        self.Text_Num:SetText("")
    end

    ---锁定状态默认不开启
    self:SetLockedState(false)
end

function UIPropItem:SetLockedState(bLocked)
    if bLocked then
        self.Canvas_NotUnlocked:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Canvas_NotUnlocked:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param ListItemObject UICommonItemObj_C
function UIPropItem:OnListItemObjectSet(ListItemObject)

    ---@type PropItemClass
    local PropItem = ListItemObject.ItemValue
    self:SetItemData(PropItem)
    self.ButtonProp.OnClicked:Add(self, self.ClickItem)
end

--function UITaskDescItem:Tick(MyGeometry, InDeltaTime)
--end

function UIPropItem:InitWidget()
end

function UIPropItem:BuildWidgetProxy()
    -- <<< auto gen proxy by editor begin >>>

    ---@type UImageProxy
    self.Image_IconProxy = WidgetProxys:CreateWidgetProxy(self.Img_PropIcon)
    ---@type UImageProxy
    self.Image_BgProxy = WidgetProxys:CreateWidgetProxy(self.Image_Bg)

    -- <<< auto gen proxy by editor end >>>
end

function UIPropItem:ClickItem()
    if self.PropItem.ID > 0 then
        local WBPCommonPropTips = UIManager:OpenUI(UIDef.UIInfo.UI_Common_PropTips_Main)
        WBPCommonPropTips:SetRewardTipsByExcelID(self.PropItem.ID, self.PropItem.Number)
    end
end

return UIPropItem
