--
-- DESCRIPTION
--
-- @COMPANY GHGame
-- @AUTHOR zhengyanshuai
-- @DATE ${date} ${time}
-- @Notice 
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local InteractVM = require('CP0032305_GH.Script.viewmodel.ingame.communication.interact_vm')
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local ConstText = require("CP0032305_GH.Script.common.text_const")
local PicText = require("CP0032305_GH.Script.common.pic_const")

local PRESS_INVOKE_INTERVAL = 0.4       -- 持续按下的事件触发间隔
local GLOBAL_SPEED = 400
local MAX_SHOW_ITEM_COUNT = 5
local SCROLL_BOX_SIZE_X = 400
local SCROLL_BOX_SIZE_Y = 300
local MOUSE_ICON_POS_X = 47
local MOUSE_ICON_POS_Y = -39.5
local ITEM_SIZE_X = 370
local ITEM_SIZE_Y = 60
local TIMER_INTERVAL = 0.04             -- timer的时间间隔
local PANEL_POS_X = 164
local PANEL_POS_Y = -154
local SITUATION_MAX_SHOW_COUNT = 6 -- 二级交互
local SITUATION_COMMUNICATE_POS = {X = 380, Y = -50} -- 二级交互时的位置

local InputKeyDef = {}
InputKeyDef["One"] = 1
InputKeyDef["Two"] = 2
InputKeyDef["Three"] = 3
InputKeyDef["Four"] = 4
InputKeyDef["Five"] = 5
InputKeyDef["Six"] = 6


local ItemStateDef = {
    NotInit = 1,
    Initing = 2,
    Inited = 3,
    Removing = 4,
    Removed = 5,
}

local InteractType = {
    NORMAL = 1,
    MISSION = 2
}

---@class WBP_Interact_Pickup: WBP_Interact_Pickup_C
local M = Class(UIWindowBase)

---@param self WBP_Interact_Pickup
---@param bShow boolean
local function SetMouseVisible(self, bShow)
    if bShow then
        self.ComKey_Mouse:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.ComKey_Mouse:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

---@param Widget UUserWidget
local function UnbindAllEvent(Widget)
    Widget.ComBtn_Dialogue.OnClicked:Clear()
    Widget.ComBtn_Dialogue.OnHovered:Clear()
    Widget.ComBtn_Dialogue.OnPressed:Clear()
    Widget.ComBtn_Dialogue.OnReleased:Clear()
    Widget.ComBtn_Dialogue.OnUnhovered:Clear()
    Widget.ComBtn_Interact.OnClicked:Clear()
    Widget.ComBtn_Interact.OnHovered:Clear()
    Widget.ComBtn_Interact.OnPressed:Clear()
    Widget.ComBtn_Interact.OnReleased:Clear()
    Widget.ComBtn_Interact.OnUnhovered:Clear()
    Widget.ComBtn_Normal.OnClicked:Clear()
    Widget.ComBtn_Normal.OnHovered:Clear()
    Widget.ComBtn_Normal.OnPressed:Clear()
    Widget.ComBtn_Normal.OnReleased:Clear()
    Widget.ComBtn_Normal.OnUnhovered:Clear()
end

---@param Widget UUserWidget
---@param PosY number
local function SetWidgetTarPosY(Widget, PosY)
    Widget.ItemData.TargetItemPos.Y = PosY
end

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:OnConstruct()
    UIManager:RegisterReleasedKeyDelegate(self, self.OnReleasedKeyEvent)
end

function M:OnDestruct()
    UIManager:UnRegisterReleasedKeyDelegate(self)
end

function M:OnShow()
    self.IsSituation = false
    ---@type FTimerHandle
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, true)
end

function M:OnHide()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
    self:ResetUI()
    self.ComKey_Mouse.ImgBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) -- 还原这个
end

function M:TimerLoop()
    self:OnTick()
    
    -- item pos
    self:UpdateItemPos(TIMER_INTERVAL)
    -- item size
    -- scroll size
    self:UpdateScrollSize(TIMER_INTERVAL)
    -- scroll offset
    self:UpdateScrollOffset(TIMER_INTERVAL)
    -- fade
    self:RefreshBorderFade(TIMER_INTERVAL)
end

-- function M:Tick(MyGeometry, InDeltaTime)
--     self:OnTick()
-- end

-- Item入口
function M:UpdateParams(SelectionItems, InteractUIType, InteractItemType)
    if not SelectionItems or #SelectionItems < 1 then
        return
    end
    local ItemName = SelectionItems[1].GetSelectionTitle and SelectionItems[1]:GetSelectionTitle() or (SelectionItems[1].GetItemID and SelectionItems[1]:GetItemID() or ('null'))
    G.log:debug('zys', table.concat({'UpdateParams, count: ', #SelectionItems, ', uitype: ', InteractUIType, ', itemtype: ', InteractItemType, ', title: ', ItemName}))

    self:ResetUI()
    self.InteractUIType = InteractUIType
    self.InteractItemType = InteractItemType
    SetMouseVisible(self,  not self.InteractUIType == UIDef.InteractUIType.Dialogue)
    self:ClearItems()
    self:BuildList(SelectionItems)
    
    if #SelectionItems < self.Setting.MaxShowCount then
        self.TargetScrollSize.Y = self.TargetScrollSize.Y - (self.Setting.MaxShowCount - #SelectionItems) * ITEM_SIZE_Y
        self.CurScrollSize.Y = self.TargetScrollSize.Y
        UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox):SetSize(self.CurScrollSize)
    end
    if self.InteractItemType == UIDef.InteractUIType.Interact then
        if #SelectionItems <= 1 then
            self.ComKey_Mouse:SetVisibility(UE.ESlateVisibility.Hidden)
            SetMouseVisible(self, false)
        else
            SetMouseVisible(self, true)
        end
    end
end

---@public 作为情景交互的列表打开
---@param bIsDialogue boolean
---@param Count number 条目数量
function M:AsSituation(bIsDialogue, Count)
    G.log:debug("zys][pickup][显示流程", table.concat({"M:AsSituation() ", tostring(bIsDialogue), ' ', tostring(Count)}))
    -- 情景交互需要6个条目, 此处做从5条转到6条的流程
    -- 1.把一些静态项设置为新数值
    if not bIsDialogue then
        self.IsSituation = true
    end
    self.Setting.MaxShowCount = SITUATION_MAX_SHOW_COUNT
    self.Setting.ScrollSize.Y = self.Setting.ScrollSize.Y + ITEM_SIZE_Y
    -- 2.将交互列表框的大小修改为6条的大小
    self.TargetScrollSize.Y = self.Setting.ScrollSize.Y
    self.CurScrollSize.Y = self.Setting.ScrollSize.Y
    UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox):SetSize(self.CurScrollSize)
    self.Setting.PanelPos = {X = SITUATION_COMMUNICATE_POS.X, Y = SITUATION_COMMUNICATE_POS.Y}
    -- 新需求要求二级交互下交互列表居下布局
    local LimitCount = self.Setting.MaxShowCount - math.min(Count, self.Setting.MaxShowCount)
    self.Setting.PanelPos.Y = self.Setting.PanelPos.Y + LimitCount * ITEM_SIZE_Y

    UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.CvsInteract):SetPosition(UE.FVector2D(self.Setting.PanelPos.X, self.Setting.PanelPos.Y))
    UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.CvsMouse):SetPosition(UE.FVector2D(self.Setting.PanelPos.X, self.Setting.PanelPos.Y))
end

---`public`交互列表有新变动
function M:InteractListChange()
    if self.ListChanging == true then
        return false
    end
    self.ListChanging = true
    self:TryRequestQueueMem()
    return true
end

---`public`增加一个条目
function M:IncreaseItem(NewItemIndex, NewItemData)
    local ItemName = NewItemData.GetSelectionTitle and NewItemData:GetSelectionTitle() or (NewItemData.GetItemID and NewItemData:GetItemID() or ('null'))
    G.log:debug('zys', table.concat({'IncreaseItem, Index:%', NewItemIndex, ', Title: ', ItemName}))
    if self.Pause == true then
        return
    end
    local ItemInfo = self:BuildItemInfoByData(NewItemData, NewItemIndex)

    table.insert(self.PushQueue, ItemInfo)
    self:TryPushNewItem()

    -- 2023.11.24 当增添条目时将当前选择置顶
    if self.SelectItemIndex ~= 1 then
        local LastSelect = self.SelectItemIndex
        self.SelectItemIndex = 1
        self:RefreshItemSelectionByIndex(LastSelect)
        self:RefreshItemSelectionByIndex(self.SelectItemIndex)
        self.TargetScrollOffset = 0
    end

    return true
end

---`public`减少一个条目
function M:DecreaseItem(OldItemIndex)
    G.log:debug('zys', table.concat({'DecreaseItem, Index: ', OldItemIndex}))

    if self.Pause == true then
        return
    end
    if OldItemIndex > self.CvsList:GetChildrenCount() then
        return false
    end
    local Child = self.CvsList:GetChildAt(OldItemIndex - 1)
    if not Child then
        return false
    end
    Child.ItemData.Info.ItemState = ItemStateDef.Removing
    self:OnItemRemoving(Child.ItemData.ItemIndex)
    local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), Child, Child.DX_out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    PlayAnimProxy.Finished:Add(self, function()
        Child.ItemData.Info.ItemState = ItemStateDef.Removed
        if self.SelectItemIndex == OldItemIndex then
            local LastIndex = self.SelectItemIndex
            self.SelectItemIndex = OldItemIndex
            self:RefreshItemSelectionByIndex(LastIndex)
            self:SelectPrevItem()
        end
        Child:RemoveFromParent()
        if self.CvsList:GetChildrenCount() <= 1 then
            SetMouseVisible(self, false)
        else
            SetMouseVisible(self, true)
        end
        -- self:TryPushNewItem()
        self:RefreshItemSelectionByIndex(self.SelectItemIndex)
        self:TryRequestQueueMem()
    end)
    return true
end

---`public`指定当前选择
---@param Index number
function M:RawSetSelectionIndex(Index)
    -- local LastSelectIndex = self.SelectItemIndex
    self.SelectItemIndex = Index
    -- self:RefreshItemSelectionByIndex(Index)
    -- self:RefreshItemSelectionByIndex(LastSelectIndex)
end

---`private`
function M:TryRequestQueueMem()
    if self.ListChanging == true and self.Pause == false then
        ---@type InteractVM
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        if not InteractVM:RequestQueueMem() then
            self.ListChanging = false
            -- self:DebugAllChild("TryRequestQueueMem Finish", "")
        end
    end
end

---`tick refresh`

---`private`每帧遍历更新每个条目的位置
function M:UpdateItemPos(InDeltaTime)
    for i = 1, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        if Child.ItemData.CurItemPos.Y > Child.ItemData.TargetItemPos.Y then
            if (Child.ItemData.CurItemPos.Y - InDeltaTime * GLOBAL_SPEED) < Child.ItemData.TargetItemPos.Y then
                Child.ItemData.CurItemPos.Y = Child.ItemData.TargetItemPos.Y
            else
                Child.ItemData.CurItemPos.Y = Child.ItemData.CurItemPos.Y - InDeltaTime * GLOBAL_SPEED
            end
            UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(Child):SetPosition(Child.ItemData.CurItemPos)
        elseif Child.ItemData.TargetItemPos.Y > Child.ItemData.CurItemPos.Y then
            if (Child.ItemData.CurItemPos.Y + InDeltaTime * GLOBAL_SPEED) < Child.ItemData.CurItemPos.Y then
                Child.ItemData.CurItemPos.Y = Child.ItemData.TargetItemPos.Y
            else
                Child.ItemData.CurItemPos.Y= Child.ItemData.CurItemPos.Y + InDeltaTime * GLOBAL_SPEED
            end
            UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(Child):SetPosition(Child.ItemData.CurItemPos)
        end
    end
end

---`private`每帧更新容器尺寸
function M:UpdateScrollSize(InDeltaTime)
    if self.CurScrollSize.Y > self.TargetScrollSize.Y then
        if (self.CurScrollSize.Y - InDeltaTime * GLOBAL_SPEED) < self.TargetScrollSize.Y then
            self.CurScrollSize.Y = self.TargetScrollSize.Y
        else
            self.CurScrollSize.Y = self.CurScrollSize.Y - InDeltaTime * GLOBAL_SPEED
        end
        if self.CurScrollSize.Y <= 10 then
            self.CurScrollSize.Y = 10
        end
        UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox):SetSize(self.CurScrollSize)
    elseif self.CurScrollSize.Y < self.TargetScrollSize.Y then
        if (self.CurScrollSize.Y + InDeltaTime * GLOBAL_SPEED) > self.TargetScrollSize.Y then
            self.CurScrollSize.Y = self.TargetScrollSize.Y
        else
            self.CurScrollSize.Y = self.CurScrollSize.Y + InDeltaTime * GLOBAL_SPEED
        end
        UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox):SetSize(self.CurScrollSize)
    end
end

---`private`每帧更新滑动条的偏移
function M:UpdateScrollOffset(InDeltaTime)
    if self.CurScrollOffset > self.TargetScrollOffset then
        if (self.CurScrollOffset - InDeltaTime * GLOBAL_SPEED) < self.TargetScrollOffset then
            self.CurScrollOffset = self.TargetScrollOffset
        else
            self.CurScrollOffset = self.CurScrollOffset - InDeltaTime * GLOBAL_SPEED
        end
        self.ScrollBox:SetScrollOffset(self.CurScrollOffset)
    elseif self.CurScrollOffset < self.TargetScrollOffset then
        if (self.CurScrollOffset + InDeltaTime * GLOBAL_SPEED) > self.TargetScrollOffset then
            self.CurScrollOffset = self.TargetScrollOffset
        else
            self.CurScrollOffset = self.CurScrollOffset + InDeltaTime * GLOBAL_SPEED
        end
        self.ScrollBox:SetScrollOffset(self.CurScrollOffset)
    end
end

---`private`交互列表顶部和底部的渐隐效果
function M:RefreshBorderFade(InDeltaTime)
    if self.TargetScrollSize.Y + 10 >= self.Setting.ScrollSize.Y then
        -- 顶部
        local ShowIndex = self:CalcItemShowIndexByIndex(1)
        if ShowIndex < 0 then
            self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('Power2', 5)
        else
            self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('Power2', 0)
        end
        -- 底部
        ShowIndex = self:CalcItemShowIndexByIndex(self.CvsList:GetChildrenCount())
        if ShowIndex + 1 > self.Setting.MaxShowCount then
            self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('Power1', 5)
        else
            self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('Power1', 0)
        end
    end
end

---`init`

---`private`重置这个界面,重置所有成员变量
function M:ResetUI()
    self.Pause = false -- 关闭
    self.PressDuration = -1 -- 用户当前已经按压F的时长
    self.SelectItemIndex = 1 -- 当前选中索引
    -- 配置
    self.Setting = {
        ScrollSize = {X = SCROLL_BOX_SIZE_X, Y = SCROLL_BOX_SIZE_Y},
        MaxShowCount = MAX_SHOW_ITEM_COUNT,
        PanelPos = {X = PANEL_POS_X, Y = PANEL_POS_Y}, -- 交互列表的位置, 做NPC情景交互会用到
    }
    self.TargetScrollSize = UE.FVector2D(self.Setting.ScrollSize.X, self.Setting.ScrollSize.Y)
    self.CurScrollSize = UE.FVector2D(self.Setting.ScrollSize.X, self.Setting.ScrollSize.Y)
    self.TargetScrollOffset = 0
    self.CurScrollOffset = 0                                                       -- 
    self.InteractItemType = InteractVM.InteractItemType.Once                      -- 
    -- self.InteractUIType                                                         -- 
    self.PushQueue = {}                                                            -- 给增添用的, 后面会都换成这种
    self.ListChanging = false

    self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('Power1', 0)
    self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('Power2', 0)
    self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('progress', 10)
    self.RetainerBox:GetEffectMaterial():SetScalarParameterValue('Rotation', 90)
    self.ComKey_Mouse.ImgBg:SetVisibility(UE.ESlateVisibility.Hidden)
    self.ScrollBox:SetScrollOffset(self.TargetScrollOffset)
    SetMouseVisible(self, true)
    self.ComKey_Mouse.KeyNormal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox):SetSize(self.TargetScrollSize)
    UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.CvsInteract):SetPosition(UE.FVector2D(self.Setting.PanelPos.X, self.Setting.PanelPos.Y))
    UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.CvsMouse):SetPosition(UE.FVector2D(self.Setting.PanelPos.X, self.Setting.PanelPos.Y))
end

---`private`根据传入数据列表,初始化构建交互列表
function M:BuildList(DataList)
    for i = 1, #DataList do
        local ItemInfo = self:BuildItemInfoByData(DataList[i], i)
        self:AddNewItem(ItemInfo)
    end

    self:NewItemInAnim()
    -- self:RefreshItemSelectionByIndex(1)

    -- self:DebugAllChild("BuildList Finish", "")
end

---`private`单个条目,用外部获取的数据,构建界面显示需要的数据
function M:BuildItemInfoByData(Data, Index)
    local ItemInfo = {}
    ItemInfo.Info = {}
    ItemInfo.Info.Title = ""
    if Data.GetSelectionTitle then
        ItemInfo.Info.Title = Data:GetSelectionTitle()
    end
    if Data.Prefix then
        ItemInfo.Info.Title = Data.Prefix .. ItemInfo.Info.Title
    end
    ItemInfo.Info.Icon = ''
    if Data.GetDisplayIconPath then
        ItemInfo.Info.Icon = Data:GetDisplayIconPath()
        if ItemInfo.Info.Icon and ItemInfo.Info.Icon ~= '' and ItemInfo.Info.Icon ~= ' ' then
            ItemInfo.Info.IconResourceObject = PicText.GetPicResource(ItemInfo.Info.Icon)
        end
    end

    ItemInfo.Info.ItemState = ItemStateDef.NotInit
    ItemInfo.Info.bIsMissionType = false
    ItemInfo.Info.Type = -1
    if Data.GetType then
        ItemInfo.Info.Type = Data:GetType()
        ItemInfo.Info.bIsMissionType = Data:GetType() == Enum.Enum_InteractType.Mission
    end
    ItemInfo.Info.Actor = '0'
    if Data.GetActor then
        ItemInfo.Info.Actor = tostring(Data:GetActor())
    end
    ItemInfo.Info.Usable = true
    if Data.GetUsable then
        ItemInfo.Info.Usable = Data:GetUsable()
    end
    if type(ItemInfo.Info.Usable) ~= 'boolean' then
        ItemInfo.Info.Usable = true
    end
    
    ItemInfo.Info.Quality = -1
    if Data.GetQuality then
        ItemInfo.Info.Quality = Data:GetQuality()
    end

    if Data.GetItemID and Data:GetItemID() ~= nil and Data:GetItemID() > 0 then
        ItemInfo.Info.ItemID = Data:GetItemID()
        ---@type ItemConfig
        local ItemConfig = ItemUtil.GetItemConfigByExcelID(Data:GetItemID())
        ItemInfo.Info.Title = ConstText.GetConstText(ItemConfig.name)
        ItemInfo.Info.Quality = ItemConfig.quality
        ItemInfo.Info.IconResourceObject = PicText.GetPicResource(ItemConfig.icon_reference)
    end

    ItemInfo.ItemIndex = Index
    ItemInfo.MainUI = self
    ItemInfo.TargetItemPos = UE.FVector2D(0, 0) -- outside
    ItemInfo.CurItemPos = UE.FVector2D(0, 0)
    ItemInfo.TargetItemSize = UE.FVector2D(ITEM_SIZE_X, ITEM_SIZE_Y) -- inside
    ItemInfo.CurItemSize = UE.FVector2D(ITEM_SIZE_X, ITEM_SIZE_Y)
    return ItemInfo
end

---`private`
function M:TryPushNewItem()
    local bHasOtherState = false
    for i = 1, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        if Child.ItemData.Info.ItemState ~= ItemStateDef.Inited then
            bHasOtherState = true
        end
    end
    if bHasOtherState or #self.PushQueue < 1 then
        return
    end

    local ItemInfo = self.PushQueue[1]
    table.remove(self.PushQueue, 1)
    self:AddNewItem(ItemInfo)
    local InsertIndex = ItemInfo.ItemIndex
    ItemInfo.ItemIndex = self.CvsList:GetChildrenCount()

    if self.CvsList:GetChildrenCount() <= 1 then
        SetMouseVisible(self,false)
    else
        SetMouseVisible(self, true)
    end
    
    local tmpInfo = nil
    local LastChild = self.CvsList:GetChildAt(self.CvsList:GetChildrenCount() - 1)
    for i = InsertIndex, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        tmpInfo = Child.ItemData.Info
        Child.ItemData.Info = LastChild.ItemData.Info
        LastChild.ItemData.Info = tmpInfo
        self:InitItemWidget(Child, InsertIndex == Child.ItemData.ItemIndex and false or true)
        self:RefreshItemContent(Child)
    end
    if self.SelectItemIndex >= InsertIndex then
        self.SelectItemIndex = self.SelectItemIndex + 1
        self:RefreshItemSelectionByIndex(self.SelectItemIndex - 1)
        self:RefreshItemSelectionByIndex(self.SelectItemIndex)
    end
    if self.SelectItemIndex > self.CvsList:GetChildrenCount() then
        self.SelectItemIndex = 1
    end
    self:NewItemInAnim()
    local ValidCount = self:CalcValidCountByRange(1, self.CvsList:GetChildrenCount())
    self.TargetScrollSize.Y = (ValidCount > 5 and 5 or ValidCount) * ITEM_SIZE_Y
    local ReplacedChild = self.CvsList:GetChildAt(InsertIndex)
    if ReplacedChild then
        ReplacedChild.ItemData.CurItemPos = UE.FVector2D(ReplacedChild.ItemData.TargetItemPos.X, ReplacedChild.ItemData.TargetItemPos.Y - 60)
        UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(ReplacedChild):SetPosition(ReplacedChild.ItemData.CurItemPos)
    else

    end
end

---`private`遍历,找到一个未初始化的控件,播放进入动画
function M:NewItemInAnim()
    for i = 1, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        if Child.ItemData.Info.ItemState == ItemStateDef.NotInit then
            Child.ItemData.Info.ItemState = ItemStateDef.Initing
            Child:PlayAnimation(Child.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
            local ShowIndex = self:CalcItemShowIndexByIndex(i)
            if ShowIndex >= 0 and ShowIndex < self.Setting.MaxShowCount then
                self.Pause = true
            else
                self.Pause = false
            end
            return true
        end
    end
    self.Pause = false
    return false
end

---`private`CreateWidget,赋予控件显示信息数据包,初始化控件transform
function M:AddNewItem(ItemInfo)
    local Widget = UE.UWidgetBlueprintLibrary.Create(self, UIManager:ClassRes("ChatSelectionItem"))
    local Count = self.CvsList:GetChildrenCount()

    Widget.ItemData = ItemInfo
    self:RefreshItemContent(Widget)
    self:InitItemWidget(Widget, false)
    self.CvsList:AddChildToCanvas(Widget)
    SetWidgetTarPosY(Widget, Count * ITEM_SIZE_Y)
    Widget.ItemData.CurItemPos.Y = Count * ITEM_SIZE_Y
    UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(Widget):SetPosition(Widget.ItemData.TargetItemPos)
    UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(Widget):SetSize(Widget.ItemData.TargetItemSize)
end

---`input action`

---`private`执行一键拾取
function M:ContinuousInvokeInteractAction()
    -- 2023/9/27需求在一键的时候关掉鼠标图标和F图标
    -- self.ComKey_Mouse:SetVisibility(UE.ESlateVisibility.Hidden)
    local ValidCount = self:CalcValidCountByRange(1, self.CvsList:GetChildrenCount())
    local WillRemoveCount = 0
    for i = 1, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        if Child.ItemData.Info.Type == Enum.Enum_InteractType.DropItem then
            local ShowIndex = self:CalcItemShowIndexByIndex(Child.ItemData.ItemIndex)
            if ShowIndex >= 0 and ShowIndex < self.Setting.MaxShowCount then
                WillRemoveCount = WillRemoveCount + 1
            end
        end
    end
    if WillRemoveCount < 1 then
        return false
    end

    local DivideCount = math.floor(WillRemoveCount <= 5 and WillRemoveCount / 2 or self.Setting.MaxShowCount / 2)
    local bSelectionRemoved = false
    local ValidIndex = 1
    local RemoveCount = 0
    self.Pause = true
    
    ---@type InteractVM
    local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
    InteractVM:ContinuousInvokePickup()
    for i = 1, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        if Child.ItemData.Info.Type == Enum.Enum_InteractType.DropItem then
            Child.WBP_Common_PCkey:SetVisibility(UE.ESlateVisibility.Hidden)
            if Child.ItemData.ItemIndex == self.SelectItemIndex then
                bSelectionRemoved = true
            end
            local ShowIndex = self:CalcItemShowIndexByIndex(Child.ItemData.ItemIndex)
            Child.ItemData.Info.ItemState = ItemStateDef.Removing
            RemoveCount = RemoveCount + 1
            if ShowIndex >= 0 and ShowIndex < self.Setting.MaxShowCount then
                -- 需求一键拾取时上半和下半向中间收缩
                if ShowIndex < DivideCount then -- 上半
                    local offsetY = math.abs(ITEM_SIZE_Y * math.abs(DivideCount - ShowIndex) * 0.8)
                    SetWidgetTarPosY(Child, Child.ItemData.TargetItemPos.Y + offsetY)
                elseif ShowIndex > DivideCount then -- 下半
                    local offsetY = math.abs(ITEM_SIZE_Y * math.abs(ShowIndex - DivideCount) * 0.8)
                    SetWidgetTarPosY(Child, Child.ItemData.TargetItemPos.Y - offsetY)
                end
                local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), Child, Child.DX_out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
                PlayAnimProxy.Finished:Add(self, function()
                    Child.ItemData.Info.ItemState = ItemStateDef.Removed
                    self:ContinuousPickupFinish()
                    Child:RemoveFromParent()
                end)
            else
                Child.WidgetSwitcher_Chat:SetRenderOpacity(0)
            end
        else
            local LastIndex = Child.ItemData.ItemIndex
            Child.ItemData.ItemIndex = ValidIndex
            ValidIndex = ValidIndex + 1
            if bSelectionRemoved then
                self.SelectItemIndex = Child.ItemData.ItemIndex
                bSelectionRemoved = false
            end
            if self.SelectItemIndex == LastIndex then
                self.SelectItemIndex = Child.ItemData.ItemIndex
            end
            SetWidgetTarPosY(Child, ((ValidIndex - 2) > 5 and 5 or (ValidIndex - 2)) * ITEM_SIZE_Y)
        end
    end
    if RemoveCount < self.CvsList:GetChildrenCount() then
        self.TargetScrollSize.Y = (ValidIndex - 1) * ITEM_SIZE_Y
    else
        SetMouseVisible(self, false)
    end
    self.TargetScrollOffset = 0
    if RemoveCount == 0 then
        self.Pause = false
    end

    HiAudioFunctionLibrary.PlayAKAudio("Play_UI_General_PickUp", self)
end

function M:ContinuousPickupFinish()
    local ValidCount = self:CalcValidCountByRange(1, self.CvsList:GetChildrenCount())
    if ValidCount < 1 then
        ---@type InteractVM
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        InteractVM:CloseInteractSelection()
    end
    self.Pause = false
    for i = 1, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        if Child then
            if Child.ItemData.Info.ItemState == ItemStateDef.Removing or Child.ItemData.Info.ItemState == ItemStateDef.Removed then
                Child:RemoveFromParent()
            end
        end
    end
    self:RefreshItemSelectionByIndex(self.SelectItemIndex)
end

function M:OnScroll(Val)
    if self.Pause == true then
        return
    end
    if Val < 0 then
        self:SelectPrevItem()
    else
        self:SelectNextItem()
    end
end

function M:OnPickupCanceled()
    if self.Pause == true then
        return
    end
    self:InvokeItemAction(self.SelectItemIndex)
end

function M:OnReleasedKeyEvent(KeyName)
    if InputKeyDef[KeyName] then
        self:OnNumRelessed(InputKeyDef[KeyName])
    end
end

function M:OnNumRelessed(Key)
    G.log:debug("zys][pickup", table.concat({"OnNumRelessed Key: ", tostring(Key)}))
    if self.Pause or not self.IsSituation then
        return
    end
    local ShowIndex = -1
    for i = 1, self.CvsList:GetChildrenCount() do
        if self:CalcItemShowIndexByIndex(i) == 0 then
            ShowIndex = i
            break
        end
    end
    G.log:debug("zys][pickup", table.concat({"OnNumRelessed Value: ", tostring(Key + ShowIndex - 1)}))
    if not (ShowIndex < 0) then
        self:InvokeItemAction(Key + ShowIndex - 1)
    end
end

function M:OnPickupCompleted()
    if self.Pause == true and not self.InteractItemType == InteractVM.InteractItemType.Once then
        return
    end
    self:ContinuousInvokeInteractAction()
end

---`private`操作触发交互条目, 判断条目当前显示状态可触发, 先回调, 再执行条目显示效果
function M:InvokeItemAction(ItemIndex)
    if self.Pause == true then
        return
    end
    local Child = self.CvsList:GetChildAt(ItemIndex - 1)
    if not Child or Child.ItemData.Info.ItemState > ItemStateDef.Inited or Child.ItemData.Info.Usable == false then
        return
    end

    if Child.ItemData.Info.Type == Enum.Enum_InteractType.DropItem then
        Child.ItemData.Info.ItemState = ItemStateDef.Removing
    end

    if self.InteractUIType == UIDef.InteractUIType.Dialogue and not self.IsSituation  then
        ---@type DialogueVM
        local DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
        if DialogueVM then
            -- DialogueVM:DialogSelect(ItemIndex)
            DialogueVM:NextDialogueStep(ItemIndex)
        end
        return
    end

    if Child.ItemData.Info.Type ~= Enum.Enum_InteractType.DropItem then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        InteractVM:InteractSelect(Child.ItemData.ItemIndex)
        return
    end
    self:OnItemRemoving(Child.ItemData.ItemIndex)
    ---@type InteractVM
    local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
    InteractVM:InteractSelect(Child.ItemData.ItemIndex, true)

    local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), Child, Child.DX_out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    PlayAnimProxy.Finished:Add(self, function()
        Child.ItemData.Info.ItemState = ItemStateDef.Removed
        local LastSelectIndex = self.SelectItemIndex
        self.SelectItemIndex = ItemIndex
        Child:RemoveFromParent()
        local NextChild = self.CvsList:GetChildAt(self.SelectItemIndex - 1)
        if not NextChild or NextChild.ItemData.Info.Usable == false then
            G.log:debug("zys", "出现需要处理的条目不可用")
            -- 向下寻找可用条目
            local FindIndex = 0
            for i = self.SelectItemIndex, self.CvsList:GetChildrenCount() do
                local FindChild = self.CvsList:GetChildAt(i - 1)
                if FindChild and FindChild.ItemData.Info.Usable then
                    FindIndex = FindChild.ItemData.ItemIndex
                    break
                end
            end
            if FindIndex <= 0 then
                -- 下面没有就向上寻找
                for i = 1, self.SelectItemIndex do
                    local FindChild = self.CvsList:GetChildAt(self.SelectItemIndex - i)
                    if FindChild and FindChild.ItemData.Info.Usable then
                        FindIndex = self.SelectItemIndex - i + 1
                        break
                    end
                end
            end
            if FindIndex > 0 then
                self.SelectItemIndex = FindIndex
            end
            G.log:debug("zys", table.concat({'新条目: ', FindIndex}))
        end
        self:RefreshItemSelectionByIndex(LastSelectIndex)
        self:RefreshItemSelectionByIndex(self.SelectItemIndex)
    end)
end

---`private`当有条目移出时, 寻找上一个和下一个有效项, 判断当前条目以移动小鼠标和整体居中和是否关闭界面
function M:OnItemRemoving(ItemIndex)
    for i = ItemIndex + 1, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        Child.ItemData.ItemIndex = Child.ItemData.ItemIndex - 1
    end
    local PrevValidCount = 0
    local NextValidCount = 0
    for i = 1, ItemIndex do
        local Child = self.CvsList:GetChildAt(i - 1)
        if Child then
            if Child.ItemData.Info.ItemState ~= ItemStateDef.Removing and Child.ItemData.Info.ItemState ~= ItemStateDef.Removed then
                PrevValidCount = PrevValidCount + 1
            end
        end
    end
    for i = ItemIndex + 1, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        if Child then
            SetWidgetTarPosY(Child, Child.ItemData.TargetItemPos.Y - ITEM_SIZE_Y)
            if Child.ItemData.Info.ItemState ~= ItemStateDef.Removing and Child.ItemData.Info.ItemState ~= ItemStateDef.Removed then
                NextValidCount = NextValidCount + 1
            end
        end
    end

    if ((PrevValidCount + NextValidCount) == 1) and self.ListChanging == false then
        SetMouseVisible(self, false)
    end
    if self.InteractItemType == InteractVM.InteractItemType.Mutex then
        self.Pause = true
        InteractVM:CloseInteractSelection()
    end

    if NextValidCount < 1 then
        self.TargetScrollOffset = math.max(0, self.TargetScrollOffset - ITEM_SIZE_Y)
        local Child = self.CvsList:GetChildAt(ItemIndex - 1)
        SetWidgetTarPosY(Child, Child.ItemData.TargetItemPos.Y - ITEM_SIZE_Y)
    end

    local NotUsableCount = 0
    for i = 1, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        if Child.ItemData.Info.Usable == false then
            NotUsableCount = NotUsableCount  + 1
        end
    end

    if ((PrevValidCount + NextValidCount - NotUsableCount) < 1) and self.ListChanging == false then
        self.Pause = true
        InteractVM:CloseInteractSelection()
    elseif (PrevValidCount + NextValidCount) < self.Setting.MaxShowCount then
        self.TargetScrollSize.Y = (PrevValidCount + NextValidCount) * ITEM_SIZE_Y
    else
        self.TargetScrollSize.Y = self.Setting.MaxShowCount * ITEM_SIZE_Y
    end
end

---`current selection`

---`private`当前选中项,显示按键F和白边框
function M:RefreshItemSelectionByIndex(ItemIndex)
    if not ItemIndex then
        return
    end
    local ItemWidget = self.CvsList:GetChildAt(ItemIndex - 1)
    if not ItemWidget or ItemWidget == nil or not ItemWidget.ItemData then
        return
    end
    if ItemWidget.ItemData.ItemIndex == self.SelectItemIndex then
        ItemWidget.WidgetSwitcher_Interact:SetActiveWidgetIndex(0)
        if self.InteractUIType == UIDef.InteractUIType.Interact then
            ItemWidget.WBP_Common_PCkey:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
        -- ItemWidget:PlayAnimation(ItemWidget.DX_xuanting_Loop, 0, 0, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    else
        ItemWidget.WidgetSwitcher_Interact:SetActiveWidgetIndex(1)
        ItemWidget.WBP_Common_PCkey:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

---`private`选择当前选择条目的上一条
function M:SelectPrevItem()
    local Count = self.CvsList:GetChildrenCount()
    local CurIndex = self.SelectItemIndex

    local TargetIndex = CurIndex
    for i = 0, CurIndex - 1 do
        local Child = self.CvsList:GetChildAt(CurIndex - 1 - i)
        if Child then
            if Child.ItemData.Info.ItemState == ItemStateDef.Inited and Child.ItemData.ItemIndex ~= CurIndex and Child.ItemData.Info.Usable ~= false then
                TargetIndex = Child.ItemData.ItemIndex
                break
            end
        end
    end
    if TargetIndex == CurIndex then
        -- TODO 已经无perv
    end
    local TargetShowIndex = self:CalcItemShowIndexByIndex(TargetIndex)
    if TargetShowIndex < 0 then
        self.TargetScrollOffset = math.max(0, self.TargetScrollOffset - ITEM_SIZE_Y)
    end
    self.SelectItemIndex = TargetIndex
    self:RefreshItemSelectionByIndex(TargetIndex)
    self:RefreshItemSelectionByIndex(CurIndex)
    return CurIndex == TargetIndex and false or true
end

---`private`选择当前选择条目的下一条
function M:SelectNextItem()
    local Count = self.CvsList:GetChildrenCount()
    local CurIndex = self.SelectItemIndex

    local TargetIndex = CurIndex
    for i = CurIndex - 1, Count do
        local Child = self.CvsList:GetChildAt(i)
        if not Child then
            return false
        end
        if (Child.ItemData.Info.ItemState == ItemStateDef.Inited or Child.ItemData.Info.ItemState == ItemStateDef.Initing) and Child.ItemData.ItemIndex ~= CurIndex and Child.ItemData.Info.Usable ~= false then
            TargetIndex = Child.ItemData.ItemIndex
            break
        end
    end
    if TargetIndex == CurIndex then
        -- TODO 已经无next
    end
    local TargetShowIndex = self:CalcItemShowIndexByIndex(TargetIndex)
    if TargetShowIndex > 4 then
        self.TargetScrollOffset = math.max(0, self.TargetScrollOffset + ITEM_SIZE_Y)   
    end
    self.SelectItemIndex = TargetIndex
    self:RefreshItemSelectionByIndex(TargetIndex)
    self:RefreshItemSelectionByIndex(CurIndex)
    return CurIndex == TargetIndex and false or true
end

---`util method`

---`private`计算传入条目索引的显示位置,以当前显示中的第一个条目为0,上面未显示的为负
function M:CalcItemShowIndexByIndex(ItemIndex)
    local Offset = self.CurScrollOffset
    local AddOffset = 0
    for i = 1, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        if Child.ItemData.ItemIndex == ItemIndex then
            break
        end
        -- if Child.ItemData.Info.ItemState == ItemStateDef.Inited then
            AddOffset = AddOffset + ITEM_SIZE_Y
        -- end
    end
    local ShowIndex = math.floor((AddOffset - Offset) / ITEM_SIZE_Y)
    return ShowIndex
end

---`private`计算范围内的有效条目(未被移除的)
function M:CalcValidCountByRange(BeginItemIndex, EndItemIndex)
    local Count = 0
    for i = BeginItemIndex, EndItemIndex do
        local Child = self.CvsList:GetChildAt(i - 1)
        if Child.ItemData.Info.ItemState ~= ItemStateDef.Removed and Child.ItemData.Info.ItemState ~= ItemStateDef.Removing then
            Count = Count + 1
        end
    end
    return Count
end

---`item style`

---`private`初始化条目的控件,根据交互类型switch样式,设置条目图标和按键图标,添加条目的button事件
function M:InitItemWidget(ItemWidget, bFirst)
    if self.InteractUIType == UIDef.InteractUIType.Interact then
        ItemWidget.WBP_Common_PCkey:SetTextColor('Light_Default')
        ItemWidget.WBP_Common_PCkey:SetVisibility(UE.ESlateVisibility.Hidden)
        ItemWidget.light:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    elseif self.InteractUIType == UIDef.InteractUIType.Dialogue then
        ItemWidget.WBP_Common_PCkey:SetVisibility(UE.ESlateVisibility.Hidden)
        ItemWidget.light:SetVisibility(UE.ESlateVisibility.Hidden)
    end

    ItemWidget.Icon_DialogueProxy = WidgetProxys:CreateWidgetProxy(ItemWidget.Icon_Dialogue)
    ItemWidget.Icon_NormalProxy = WidgetProxys:CreateWidgetProxy(ItemWidget.Icon_Normal)
    ItemWidget.Icon_InteractProxy = WidgetProxys:CreateWidgetProxy(ItemWidget.Icon_Interact)

    if ItemWidget.ItemData.Info.IconResourceObject then
        UnLua.LogWarn("zys pic obj", ItemWidget.ItemData.Info.IconResourceObject)
        local PicResourceObject = ItemWidget.ItemData.Info.IconResourceObject
        ItemWidget.Icon_Normal:SetBrushResourceObject(PicResourceObject)
        ItemWidget.Icon_Interact:SetBrushResourceObject(PicResourceObject)
    else
        local IconPath = (ItemWidget.ItemData.Info.Icon and #ItemWidget.ItemData.Info.Icon > 0) and ItemWidget.ItemData.Info.Icon or self.Default_Dialogue_Icon
        ItemWidget.Icon_NormalProxy:SetImageTexturePath(IconPath)
        ItemWidget.Icon_InteractProxy:SetImageTexturePath(IconPath)
    end

    ItemWidget.Icon_Keyboard:SetVisibility(UE.ESlateVisibility.Hidden)
    ItemWidget.Text_Key:SetVisibility(UE.ESlateVisibility.Hidden)
    ItemWidget.WidgetSwitcher_Chat:SetRenderOpacity(not bFirst and 0 or 1)
    ItemWidget.WidgetSwitcher_Chat:SetActiveWidgetIndex(1)
    ItemWidget.WidgetSwitcher_Interact:SetActiveWidgetIndex(1)

    ItemWidget.Text_Content_1:SetRenderOpacity((ItemWidget.ItemData.Info.Usable == false) and 0.5 or 1)
    ItemWidget.Text_Content_2:SetRenderOpacity((ItemWidget.ItemData.Info.Usable == false) and 0.5 or 1)
    ItemWidget.Text_Content_3:SetRenderOpacity((ItemWidget.ItemData.Info.Usable == false) and 0.5 or 1)
    ItemWidget.Icon_Normal:SetRenderOpacity((ItemWidget.ItemData.Info.Usable == false) and 0.5 or 1)
    ItemWidget.Icon_Interact:SetRenderOpacity((ItemWidget.ItemData.Info.Usable == false) and 0.5 or 1)
    ItemWidget.Icon_Dialogue:SetRenderOpacity((ItemWidget.ItemData.Info.Usable == false) and 0.5 or 1)

    if ItemWidget.ItemData.Info.Usable == false then

        return
    end
    UnbindAllEvent(ItemWidget)
    ItemWidget.ComBtn_Dialogue.OnClicked:Add(self, function()
        local ItemIndex = ItemWidget.ItemData.ItemIndex
        self:InvokeItemAction(ItemIndex)
    end)
    ItemWidget.ComBtn_Interact.OnClicked:Add(self, function()
        local ItemIndex = ItemWidget.ItemData.ItemIndex
        self:InvokeItemAction(ItemIndex)
    end)
    ItemWidget.ComBtn_Normal.OnClicked:Add(self, function()
        local ItemIndex = ItemWidget.ItemData.ItemIndex
        self:InvokeItemAction(ItemIndex)
    end)
    ItemWidget.ComBtn_Dialogue.OnHovered:Add(self, function()
        local LastIndex = self.SelectItemIndex
        self.SelectItemIndex = ItemWidget.ItemData.ItemIndex
        self:RefreshItemSelectionByIndex(LastIndex)
        self:RefreshItemSelectionByIndex(ItemWidget.ItemData.ItemIndex)
    end)
    ItemWidget.ComBtn_Interact.OnHovered:Add(self, function()
        local LastIndex = self.SelectItemIndex
        self.SelectItemIndex = ItemWidget.ItemData.ItemIndex
        self:RefreshItemSelectionByIndex(LastIndex)
        self:RefreshItemSelectionByIndex(ItemWidget.ItemData.ItemIndex)
    end)
    ItemWidget.ComBtn_Normal.OnHovered:Add(self, function()
        local LastIndex = self.SelectItemIndex
        self.SelectItemIndex = ItemWidget.ItemData.ItemIndex
        self:RefreshItemSelectionByIndex(LastIndex)
        self:RefreshItemSelectionByIndex(ItemWidget.ItemData.ItemIndex)
    end)
end

---`private`设置条目信息, 仅样式和标题
---@param ItemWidget WBP_CommunicationMainUI_ChatSelection_Item_C
function M:RefreshItemContent(ItemWidget)
    ItemWidget.Text_Content_1:SetText(ItemWidget.ItemData.Info.Title)
    ItemWidget.Text_Content_2:SetText(ItemWidget.ItemData.Info.Title)
    ItemWidget.Text_Content_3:SetText(ItemWidget.ItemData.Info.Title)

    if ItemWidget.ItemData.Info.bIsMissionType then
        ItemWidget.Text_Content_1:SetColorAndOpacity(ItemWidget.MissionColor)
        ItemWidget.Text_Content_2:SetColorAndOpacity(ItemWidget.MissionColor)
        ItemWidget.Text_Content_3:SetColorAndOpacity(ItemWidget.MissionColor)
    else
        local Quality = ItemWidget.ItemData.Info.Quality
        if Quality ~= nil and Quality > 0 then
            local Color = ItemUtil.GetItemQualitySlateColor(Quality)
            ItemWidget.Text_Content_1:SetColorAndOpacity(Color)
            ItemWidget.Text_Content_2:SetColorAndOpacity(Color)
            ItemWidget.Text_Content_3:SetColorAndOpacity(Color)
        else
            ItemWidget.Text_Content_1:SetColorAndOpacity(ItemWidget.DefaultColor)
            ItemWidget.Text_Content_2:SetColorAndOpacity(ItemWidget.DefaultColor)
            ItemWidget.Text_Content_3:SetColorAndOpacity(ItemWidget.DefaultColor)
        end
    end
end

---`other`

function M:ClearItems()
    self.CvsList:ClearChildren()
end

---`private`条目控件进入动画播放的回调, 调整条目状态, 播放下一个条目进入动画
function M:OnItemIn(ItemIndex)
    local Child = self.CvsList:GetChildAt(ItemIndex - 1)
    Child.ItemData.Info.ItemState = ItemStateDef.Inited
    self:RefreshItemSelectionByIndex(self.SelectItemIndex)
    self:NewItemInAnim()
    self:TryRequestQueueMem()
    self:TryPushNewItem()
end

function M:DebugAllChild(FrontStr, EndStr)
    local FrontStr = FrontStr and FrontStr or ''
    local EndStr = EndStr and EndStr or ''
    local LogStr = ''
    LogStr = table.concat({'ui ', FrontStr, ', 当前显示item:    '})
    for i = 1, self.CvsList:GetChildrenCount() do
        local Child = self.CvsList:GetChildAt(i - 1)
        LogStr = table.concat({LogStr, 'ITEM_', i, ',', Child.ItemData.Info.Title, ',', (Child.ItemData.Info.Type and Child.ItemData.Info.Type or 'nil'), Child.ItemData.Info.Actor, ';      '})
    end
    -- for i = 1, math.ceil(#LogStr % 300) do
    --     LogStr = string.sub(LogStr, 1, i * 300) .. '\n' .. string.sub(LogStr, (i * 300) + 1)
    -- end
    G.log:debug('zys', table.concat({LogStr, '; 结束:', EndStr}))
end

return M
