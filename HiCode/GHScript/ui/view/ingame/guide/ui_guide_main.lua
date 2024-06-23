--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@type WBP_Guide_MainUI_C
local WBP_Guide_MainUI = Class(UIWindowBase)

--function WBP_Guide_MainUI:Initialize(Initializer)
--end

--function WBP_Guide_MainUI:PreConstruct(IsDesignTime)
--end

function WBP_Guide_MainUI:OnConstruct()
    self:InitWidget()
    self:BuildWidgetProxy()
    self:InitViewModel()
end

function WBP_Guide_MainUI:OnCreate()
    self.GuideList = {}
    self.CurGuideIdx = 1
end

function WBP_Guide_MainUI:OnShow()
    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_Guide_MainUI:OnHide()
end

function WBP_Guide_MainUI:InitWidget()
    self.Button_PrePage.OnClicked:Add(self, self.OnButton_PrePageOnClicked)
    self.Button_NextPage.OnClicked:Add(self, self.Button_NextPageOnClicked)
    self.Button_Close:SetVisibility(UE.ESlateVisibility.Hidden)
    self.WBP_Common_TopContent.Canvas_TopLeft:SetVisibility(UE.ESlateVisibility.Hidden)
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, self.Button_CloseOnClicked)
end

function WBP_Guide_MainUI:BuildWidgetProxy()
    ---@type UImageProxy
    self.Image_PageProxy = WidgetProxys:CreateWidgetProxy(self.Image_Page)
    -- ---@type UTileViewProxy
    -- self.TileView_CircleProxy = WidgetProxys:CreateWidgetProxy(self.TileView_Circle)
end

function WBP_Guide_MainUI:InitViewModel()
end

function WBP_Guide_MainUI:SetGuideContent(data)
    self.GuideList = data
    self.CurGuideIdx = 1
    self:OnPageChanged(self.CurGuideIdx)

    self.Button_PrePage:SetVisibility(#data > 1 and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    self.Button_NextPage:SetVisibility(#data > 1 and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
end

---@type Page number
function WBP_Guide_MainUI:OnPageChanged(Page)
    local Item = self.GuideList[Page]
    self.Text_PageIndex:SetText(Page .. '/' .. #self.GuideList)
    self.Text_Target:SetText(Item.ItemName)
    self.Text_Content:SetText(Item.Content)
    self.Image_PageProxy:SetImageTexturePath(Item.ImagePath)
    -- local List = {}
    -- for i = 1, #self.GuideList do
    --     table.insert(List, Page == i and true or false)
    -- end
    -- self.TileView_CircleProxy:SetListItems(List)
    self.WBP_Common_PagePoints.WBP_Common_PagePoint5:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WBP_Common_PagePoints.WBP_Common_PagePoint6:SetVisibility(UE.ESlateVisibility.Collapsed)
    for i = 1, #self.GuideList do
        if Page == i then
            self.WBP_Common_PagePoints['WBP_Common_PagePoint' .. i].Image_Circle_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.WBP_Common_PagePoints['WBP_Common_PagePoint' .. i].Image_Circle_Selected:SetVisibility(UE.ESlateVisibility.Hidden)
        end
        -- self.WBP_Common_PagePoints['WBP_Common_PagePoint' .. i].Image_Circle_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        
    end
    self.Button_PrePage:SetIsEnabled(Page > 1 and true or false)
    self.Button_NextPage:SetIsEnabled(Page < #self.GuideList and true or false)
end

--- `brief` PageUp
function WBP_Guide_MainUI:OnButton_PrePageOnClicked()
    if self.CurGuideIdx <= 1 then
        return
    end
    self.CurGuideIdx = self.CurGuideIdx - 1
    self:OnPageChanged(self.CurGuideIdx)
end

--- `brief` PageDown
function WBP_Guide_MainUI:Button_NextPageOnClicked()
    if self.CurGuideIdx > #self.GuideList - 1 then
        return
    end
    self.CurGuideIdx = self.CurGuideIdx + 1
    self:OnPageChanged(self.CurGuideIdx)
end

function WBP_Guide_MainUI:Button_CloseOnClicked()
    self:PlayAnimation(self.DX_out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

--function WBP_Guide_MainUI:Tick(MyGeometry, InDeltaTime)
--end
function WBP_Guide_MainUI:DXOutEndEvent()
    self:CloseMyself()
end
return WBP_Guide_MainUI
