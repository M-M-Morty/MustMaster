--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local BrgVM = require('CP0032305_GH.Script.viewmodel.ingame.hud.barrage_vm')

local RESOLUTION_RATIO = {X = 1920, Y = 1080}   -- 分辨率

local TIMER_INTERVAL = 0.05                     -- timer的时间间隔

local VERTICAL_INTERVAL = 20                    -- 竖直弹幕的上下像素间隔

---@class UI_Barrage: WBP_Barrage_C
---@field TaskExecChainChain 弹幕任务处理链
local UI_Barrage = Class(UIWindowBase)

---@enum EBrgStyle
---@field First 第一幕
---@field Second 第二幕
---@field Third 第三幕
---@field Forth 第四幕
UI_Barrage.EBrgStyle = {
    First = 1,
    Second = 2,
    Third = 3,
    Fourth = 4,
}

---`brief` 创建一个竖直的画布分行管理器
---@param LayerName string 层名
---@param Height number 每个弹幕的高度
---@param Interval number 间隔单位
---@param bMutex boolean 是否同行互斥
---@param bOrder boolean 是否按照顺序向下排列
---@return Mgr
local function CreateVerticalMgr(LayerName, Height, Interval, bMutex, bOrder)
    ---@class Mgr
    ---@field LayerName string
    ---@field Height number
    ---@field Interval number
    ---@field bMutex boolean
    local Mgr = {
        LayerName = LayerName or nil,
        Height = Height or nil,
        Interval = Interval or 20,
        bMutex = bMutex or false,
        bOrder = bOrder or true,
        BrgList = {},
        VerticalMgrIdx = 1,
    }
    ---@param Height number 高度
    ---@return boolean
    function Mgr:SetBrgHeight(Height)
        if not self.Height then
            self.Height = Height
            return true
        end
        return false
    end
    ---@param Size UE.FVector2D
    ---@return VerticalBrgItem
    function Mgr:AddNewBrg(Size)
        ---@class VerticalBrgItem
        ---@field PosY number
        ---@field Height number
        ---@field ID number
        local VerticalBrgItem = {
            PosY = 0,
            Height = Size.Y,
            ID = self.VerticalMgrIdx
        }
        self.VerticalMgrIdx = self.VerticalMgrIdx + 1
        for i = 1, #self.BrgList do
            local PrePos = self.BrgList[i].PosY + self.BrgList[i].Height + self.Interval
            local NextPos = self.BrgList[i + 1] and self.BrgList[i + 1].PosY or (RESOLUTION_RATIO.Y)
            if (NextPos - PrePos) >= Size.Y then
                VerticalBrgItem.PosY = PrePos
                table.insert(self.BrgList, i + 1,VerticalBrgItem)
                return VerticalBrgItem
            end
        end
        if #self.BrgList > 0 and (self.BrgList[1].PosY) > (Size.Y + self.Interval) then
            table.insert(self.BrgList, 1,VerticalBrgItem)
        end
        if #self.BrgList == 0 then
            VerticalBrgItem.PosY = 20
            table.insert(self.BrgList, VerticalBrgItem)
            return VerticalBrgItem
        else
            return nil
        end
    end
    function Mgr:RemoveBrg(ID)
        for i = 1, #self.BrgList do
            if self.BrgList[i].ID == ID then
                table.remove(self.BrgList, i)
                return true
            end
        end
        return false
    end
    return Mgr
end

---`brief` 创建一个弹幕任务
---@param self UI_Barrage
---@param InTask table
local function CreateBrgTask(self, InTask)
    local Task = {}
    Task.Delay = InTask.Delay or 0
    Task.CurDelay = 0
    Task.Interval = InTask.Interval or 0.05
    Task.CurInterval = Task.Interval -- 运行时当前出现间隔
    Task.ArrLmdFn = InTask.ArrLmdFn
    Task.Content = InTask.Content
    Task.Layer = InTask.LayerName
    Task.Style = InTask.Style
    Task.Frequency = InTask.Frequency or 1
    Task.MaxCount = InTask.MaxCount or 20
    Task.BrgDuration = InTask.BrgDuration or 2
    Task.Motion = InTask.Motion
    Task.CreateIdx = 1 -- 弹幕的创建索引
    Task.Speed = InTask.Speed
    Task.EndTime = InTask.EndTime
    Task.TaskID = self.TaskID
    self.TaskID = self.TaskID + 1
    if Task.Motion == BrgVM.EBrgMotion.Vertical then
        Task.VerticalMgr = CreateVerticalMgr(InTask.LayerName, nil, VERTICAL_INTERVAL, true, true)
    end
    table.insert(self.TaskExecChain, Task)
end

---@param self UI_Barrage
---@param BrgIdx number 弹幕唯一索引
---@param CvsLayer UCanvasPanel 层级画布
---@param Text string 内容文本
---@param Style EBrgStyle 弹幕样式
---@param Motion EBrgMotion 运动方式
---@param Speed number 弹幕初始速度(非滚动弹幕则无效)
---@param Pos UE.FVector2D 出现位置(滚动弹幕则X分量无效)
---@param Duration number 弹幕持续时间(滚动弹幕则无效)
---@param Task table
---@return UE.FVector2D
local function CreateBrg(self, BrgIdx, CvsLayer, Text, Style, Motion, Speed, Pos, Duration, Task)
    local Widget = UE.UWidgetBlueprintLibrary.Create(self, self.ClassBrg)
    CvsLayer:AddChildToCanvas(Widget)
    Widget.InitBrg(Widget, BrgIdx, Text, Style, Motion, Speed, Pos, Duration, Task, self)
    return Widget:GetBrgSize(), Widget
end

---@param self UI_Barrage
---@param Task table
---@return boolean
local function ExecCreateBrg(self, Task)
    if Task.Frequency > 0 and Task.CreateIdx < #Task.Content then
        if Task.CurInterval > 0 then
            Task.CurInterval = Task.CurInterval - TIMER_INTERVAL
        else
            local cvs =  self[Task.Layer]
            local pos
            if Task.Motion == BrgVM.EBrgMotion.Vertical then
                pos = nil
            elseif Task.Motion == BrgVM.EBrgMotion.Roll then
                pos = UE.FVector2D(0, math.random(20,1060))
            elseif Task.Motion == BrgVM.EBrgMotion.Boom then
                pos = UE.FVector2D(math.random(20, RESOLUTION_RATIO.X - 20), math.random(20, RESOLUTION_RATIO.Y - 20))
            end
            local Size, Widget = CreateBrg(self, self.BrgIdx, cvs, Task.Content[Task.CreateIdx], Task.Style, Task.Motion, Task.Speed, pos, Task.BrgDuration, Task)
            local Result = false
            if Task.Motion == BrgVM.EBrgMotion.Vertical then
                local VerticalInfo = Task.VerticalMgr:AddNewBrg(Size)
                if VerticalInfo then
                    Widget:InitVertical(VerticalInfo)
                    Widget:SetPos(UE.FVector2D(RESOLUTION_RATIO.X / 2, VerticalInfo.PosY))
                    Result = true
                end
            elseif Task.Motion == BrgVM.EBrgMotion.Roll or Task.Motion == BrgVM.EBrgMotion.Boom then
                Result = true
            end
            if Result then
                self.BrgIdx = self.BrgIdx + 1
                Task.CreateIdx = Task.CreateIdx + 1
            end
            if not (Task.CreateIdx < #Task.Content) then
                Task.Frequency = Task.Frequency - 1
                Task.CreateIdx = 1
            end
            Task.CurInterval = Task.Interval
        end
    end
end


--function UI_Barrage:Initialize(Initializer)
--end

--function UI_Barrage:PreConstruct(IsDesignTime)
--end

function UI_Barrage:OnConstruct()
    G.log:debug("zys", 'UI_Barrage:Construct()')
    self.TaskExecChain = {}
    self.BrgIdx = 1
    self.TaskID = 1
end

-- function UI_Barrage:Tick(MyGeometry, InDeltaTime)
-- end

function UI_Barrage:OnShow()
    local ViewportSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
    ---@type FTimerHandle
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, true)
end

function UI_Barrage:OnHide()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
end
function UI_Barrage:TimerLoop()
    for _, Task in ipairs(self.TaskExecChain) do
        if Task.Delay > Task.CurDelay then
            Task.CurDelay = Task.CurDelay + TIMER_INTERVAL
        else
            if Task.EndTime then
                Task.EndTime = Task.EndTime - TIMER_INTERVAL
            end
            if not Task.EndTime or Task.EndTime > 0 then -- end后不生成
                local time = ((Task.Interval - TIMER_INTERVAL) <= 0) and math.floor(TIMER_INTERVAL / Task.Interval) or 1
                for i = 1, time do
                    ExecCreateBrg(self, Task)
                end
                for _, Item in ipairs(Task.ArrLmdFn) do
                    if Item.Delay > 0 then
                        Item.Delay = Item.Delay - TIMER_INTERVAL
                    elseif Item.Fn then
                        Item.Fn(self, Task)
                        Item.Fn = nil
                    end
                end
            end
        end
    end
end

---`brief` 本次弹幕需求的接口
function UI_Barrage:SetBrgSequence(Stag1, Stag2, Stag3, Stag4)
    CreateBrgTask(self, 0, 0.05, {}, Stag1, "Layer_1", BrgVM.EBrgStyle.First,2, nil, nil, BrgVM.EBrgMotion.Roll, 0.7)
    CreateBrgTask(self, 3, 0.05, {
        {
            Delay = 4,
            Fn = function(self, Task)
                for i = 1, self['Layer_2']:GetChildrenCount() do
                    local widget = self['Layer_2']:GetChildAt(i - 1)
                    if widget then
                        widget:ChangeRollAnimSpeed(1.5)
                    end
                end
                Task.Speed = 1.5
            end, 
            Desc = '延迟加速',
        }
    }, Stag2, "Layer_2", BrgVM.EBrgStyle.Second, 5, nil, nil, BrgVM.EBrgMotion.Roll, 1)
    CreateBrgTask(self, 8, 0.05, {}, Stag3, "Layer_3", BrgVM.EBrgStyle.Third, 10, nil, 2, BrgVM.EBrgMotion.Vertical, 1)
    CreateBrgTask(self, 12, 0.003, {}, Stag4, "Layer_4", BrgVM.EBrgStyle.Fourth, 100, nil, 6, BrgVM.EBrgMotion.Boom, 1)
end

---@param Stag1 BarrageStage
---@param Stag2 BarrageStage
---@param Stag3 BarrageStage
---@param Stag4 BarrageStage
function UI_Barrage:CreateBossBrgSequence(Stag1, Stag2, Stag3, Stag4)
    local Task1 = {
        Delay = Stag1.Delay or 0,
        Interval = Stag1.Interval or 0.05,
        ArrLmdFn = {},
        Content = Stag1.Content or {''},
        LayerName = 'Layer_1',
        Style = BrgVM.EBrgStyle.First,
        Frequency = Stag1.Frequency or 2,
        MaxCount = Stag1.MaxCount or nil,
        BrgDuration = Stag1.LifeTime or 2,
        Motion = BrgVM.EBrgMotion.Roll,
        Speed = 0.7,
        EndTime = Stag1.EndTime,
    }
    CreateBrgTask(self, Task1)
    local Task2 = {
        Delay = Stag2.Delay or 3,
        Interval = Stag2.Interval or 0.05,
        ArrLmdFn = {
            Delay = 4,
            Fn = function(self, Task)
                for i = 1, self['Layer_2']:GetChildrenCount() do
                    local widget = self['Layer_2']:GetChildAt(i - 1)
                    if widget then
                        widget:ChangeRollAnimSpeed(1.5)
                    end
                end
                Task.Speed = 1.5
            end, 
            Desc = '延迟加速',
        },
        Content = Stag2.Content or {''},
        LayerName = 'Layer_2',
        Style = BrgVM.EBrgStyle.Second,
        Frequency = Stag2.Frequency or 5,
        MaxCount = Stag2.MaxCount or nil,
        BrgDuration = Stag2.LifeTime or 2,
        Motion = BrgVM.EBrgMotion.Roll,
        Speed = 0.7,
        EndTime = Stag2.EndTime,
    }
    CreateBrgTask(self, Task2)
    local Task3 = {
        Delay = Stag3.Delay or 8,
        Interval = Stag3.Interval or 0.05,
        ArrLmdFn = {},
        Content = Stag3.Content or {''},
        LayerName = 'Layer_3',
        Style = BrgVM.EBrgStyle.Third,
        Frequency = Stag3.Frequency or 10,
        MaxCount = Stag3.MaxCount or nil,
        BrgDuration = Stag3.LifeTime or 2,
        Motion = BrgVM.EBrgMotion.Vertical,
        Speed = 1,
        EndTime = Stag3.EndTime,
    }
    CreateBrgTask(self, Task3)
    local Task4 = {
        Delay = Stag4.Delay or 12,
        Interval = Stag4.Interval or 0.003,
        ArrLmdFn = {},
        Content = Stag4.Content or {''},
        LayerName = 'Layer_4',
        Style = BrgVM.EBrgStyle.Fourth,
        Frequency = Stag4.Frequency or 100,
        MaxCount = Stag4.MaxCount or nil,
        BrgDuration = Stag4.LifeTime or 6,
        Motion = BrgVM.EBrgMotion.Boom,
        Speed = 1,
        EndTime = Stag4.EndTime,
    }
    CreateBrgTask(self, Task4)
end

function UI_Barrage:QueryCloseUI()
    local count = self.Layer_1:GetChildrenCount() + self.Layer_2:GetChildrenCount() + self.Layer_3:GetChildrenCount() + self.Layer_4:GetChildrenCount()
    -- print('zys UI_Barrage:QueryCloseUI()', count)
    if count <= 1 then
        BrgVM:CloseBrgWnd()
    end
end

return UI_Barrage