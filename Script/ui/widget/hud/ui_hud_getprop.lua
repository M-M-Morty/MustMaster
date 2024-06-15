--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ItemDef = require("CP0032305_GH.Script.item.ItemDef")

---@type WBP_HUD_GetProp_C
local WBP_HUD_GetProp = Class(UIWindowBase)

local NORMAL_ITEM_INTERVAL = 0.07 -- 普通物品提示的出现间隔
local NORMAL_ITEM_DURATION = 2    -- 普通物品提示的持续时间
local MAX_NORMAL_ITEM_DISPLAY = 3 -- 普通物品同时显示的最大数量
local NEW_ITEM_DURATION = 3       -- 新物品提示的持续时间
local PROP_ITEM_PIXEL_SIZEY = 41  -- 每个Item所占像素值, 此项由UMG排版的Pos,SizeY,Padding,EntrySpace求和而来
local ROLL_SPEED = 400            -- 条目滚动速度, 此项需配合动画播放时长和速度
local TIMER_INTERVAL = 0.04             -- timer的时间间隔

--function WBP_HUD_GetProp:Initialize(Initializer)
--end

--function WBP_HUD_GetProp:PreConstruct(IsDesignTime)
--end

function WBP_HUD_GetProp:OnClickNewItem()
    local ClickPropItem = self.WBP_HUD_GetProp_NewItem.WBP_PropItem.PropItem
    if ClickPropItem and ClickPropItem.ID then
        local ItemConfig = ItemUtil.GetItemConfigByExcelID(ClickPropItem.ID)
        if ItemConfig then
            if ItemUtil.GetItemTabIndex(ClickPropItem.ID) > 0 then
                ---@type WBP_Knapsack_Main
                local WBPKnapsackMain = UIManager:OpenUI(UIDef.UIInfo.UI_Knapsack_Main)
                WBPKnapsackMain:ChooseItemByExcelID(ClickPropItem.ID)
            end
        end
    end
end

function WBP_HUD_GetProp:OnConstruct()
    self.NormalItemQueue = {}
    self.WaitEnqueueTime = 0

    self.NewItemQueue = {}
    self.CurrentNewItem = nil

    self:InitWidget()
    self:BuildWidgetProxy()
    self:InitViewModel()
    self.WBP_HUD_GetProp_NewItem.WBP_PropItem.ButtonProp.OnClicked:Add(self, self.OnClickNewItem)
end

function WBP_HUD_GetProp:OnDestruct()
    self.WBP_HUD_GetProp_NewItem.WBP_PropItem.ButtonProp.OnClicked:Remove(self, self.OnClickNewItem)
end

function WBP_HUD_GetProp:InitWidget()
    self.WBP_HUD_GetProp_NewItem:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function WBP_HUD_GetProp:BuildWidgetProxy()
    ---@type UListViewProxy
    self.List_GetPropsProxy = WidgetProxys:CreateWidgetProxy(self.List_GetProps)
end

function WBP_HUD_GetProp:InitViewModel()
end

function WBP_HUD_GetProp:OnShow()
    self.CurScrollBoxOffset = 0
    self.TargetScrollBoxOffset = 0
    self.CurScrollBoxSizeY = 160
    self.TargetScrollBoxSizeY = 160
    self.OutCount = 0
    self.ScrollBoxSize = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox):GetSize()

    ---@type FTimerHandle
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, true)
end

function WBP_HUD_GetProp:OnHide()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
end

function WBP_HUD_GetProp:TimerLoop()
    self:UpdateShowNewItem(TIMER_INTERVAL)
    self:UpdateShowNormalItem(TIMER_INTERVAL)
    self:UpdateScollBox(TIMER_INTERVAL)
end

-- function WBP_HUD_GetProp:Tick(MyGeometry, InDeltaTime)
--     self:UpdateShowNewItem(InDeltaTime)
--     self:UpdateShowNormalItem(InDeltaTime)
--     self:UpdateScollBox(InDeltaTime)
-- end

function WBP_HUD_GetProp:PushNewItemList(NewItemList)
    if not NewItemList then
        return
    end

    for _, NewItem in ipairs(NewItemList) do
        local elm = {}
        elm.Item = NewItem
        elm.PassedTime = 0
        table.insert(self.NewItemQueue, elm)
    end
end

function WBP_HUD_GetProp:UpdateShowNewItem(DeltaTime)
    if self.CurrentNewItem then
        self.CurrentNewItem.PassedTime = self.CurrentNewItem.PassedTime + DeltaTime
        if self.CurrentNewItem.PassedTime > NEW_ITEM_DURATION then
            self.WBP_HUD_GetProp_NewItem:PlayAnimation(self.DX_out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
            self.CurrentNewItem = nil
        end
    else
        if #self.NewItemQueue > 0 then
            self.CurrentNewItem = self.NewItemQueue[1]
            table.remove(self.NewItemQueue, 1)
            local CurrentItem = self.CurrentNewItem.Item
            self.WBP_HUD_GetProp_NewItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

            self.WBP_HUD_GetProp_NewItem:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)

            local PropItem = self.WBP_HUD_GetProp_NewItem.WBP_PropItem
            if CurrentItem.Quality == ItemDef.Quality.ORANGE then
                PropItem:PlayAnimation(PropItem.DX_ImportantItemGetOrange, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0,
                    false)
                PropItem:PlayAnimation(PropItem.DX_NewItemGetOrange, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
            else
                PropItem:PlayAnimation(PropItem.DX_ImportantItemGetOrange, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
                PropItem:StopAnimation(PropItem.DX_ImportantItemGetOrange)
            end
            self.WBP_HUD_GetProp_NewItem.Text_Name:SetText(CurrentItem.Name)
            self.WBP_HUD_GetProp_NewItem.WBP_PropItem:SetItemData(CurrentItem)

            local ItemQualityConfig = ItemUtil.GetItemQualityConfig(CurrentItem.Quality)
            PicConst.SetImageBrush(self.WBP_HUD_GetProp_NewItem.Image_Bg, ItemQualityConfig.new_get_bg)
            self:PlayAnimation(self.NewItemFadeOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
        end
    end
end

function WBP_HUD_GetProp:PushNormalItemList(NormalItemList)
    if not NormalItemList then
        return
    end

    for _, NormalItem in ipairs(NormalItemList) do
        local elm = {}
        elm.Item = NormalItem
        elm.Duration = NORMAL_ITEM_DURATION

        table.insert(self.NormalItemQueue, elm)
    end
end

function WBP_HUD_GetProp:UpdateShowNormalItem(DeltaTime)
    local ItemValues = self.List_GetPropsProxy:GetListItems()
    for idx, elm in ipairs(ItemValues) do
        if elm.bFadeOutEnd then
            if idx > self.OutCount then
                self.OutCount = idx
                self.TargetScrollBoxOffset = self.OutCount * PROP_ITEM_PIXEL_SIZEY
                break
            end
        end
    end
    self.TargetScrollBoxSizeY = math.min(MAX_NORMAL_ITEM_DISPLAY, #ItemValues - self.OutCount) * PROP_ITEM_PIXEL_SIZEY

    local ListItemNum = self.List_GetPropsProxy:GetNumItems()
    if #self.NormalItemQueue == 0 then
        if ListItemNum > 0 and ListItemNum == self.OutCount then
            self.List_GetProps:ClearListItems()
            self.TargetScrollBoxOffset = 0
            self.TargetScrollBoxSizeY = 0
            self.OutCount = 0
        end
        return
    end

    local bEnqueueNormalItemList = false
    if ListItemNum == 0 then
        bEnqueueNormalItemList = true
    else
        if ListItemNum - self.OutCount < MAX_NORMAL_ITEM_DISPLAY then
            self.WaitEnqueueTime = self.WaitEnqueueTime + DeltaTime
            if self.WaitEnqueueTime > NORMAL_ITEM_INTERVAL then
                self.WaitEnqueueTime = 0
                bEnqueueNormalItemList = true
            end
        end
    end

    if bEnqueueNormalItemList then
        local EnqueueItem = self.NormalItemQueue[1]
        table.remove(self.NormalItemQueue, 1)
        self.List_GetPropsProxy:AddItem(EnqueueItem)
    end
end

function WBP_HUD_GetProp:UpdateScollBox(DeltaTime)
    if self.CurScrollBoxSizeY < self.TargetScrollBoxSizeY then
        self.CurScrollBoxSizeY = self.TargetScrollBoxSizeY
        UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox):SetSize(UE.FVector2D(self.ScrollBoxSize.X, self.CurScrollBoxSizeY))
    elseif self.CurScrollBoxSizeY > self.TargetScrollBoxSizeY then
        self.CurScrollBoxSizeY = math.max(0, self.CurScrollBoxSizeY - DeltaTime * ROLL_SPEED)
        UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox):SetSize(UE.FVector2D(self.ScrollBoxSize.X, self.CurScrollBoxSizeY))
    end

    if self.CurScrollBoxOffset < self.TargetScrollBoxOffset then
        self.CurScrollBoxOffset = self.CurScrollBoxOffset + DeltaTime * ROLL_SPEED
        self.ScrollBox:SetScrollOffset(self.CurScrollBoxOffset)
    elseif self.CurScrollBoxOffset > self.TargetScrollBoxOffset then
        self.CurScrollBoxOffset = self.TargetScrollBoxOffset
        self.ScrollBox:SetScrollOffset(self.CurScrollBoxOffset)
    end
end

return WBP_HUD_GetProp
