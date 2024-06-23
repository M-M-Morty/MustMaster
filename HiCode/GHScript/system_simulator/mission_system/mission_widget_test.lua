
local MissionWidgetTest = {}

local MissionSystem = require("CP0032305_GH.Script.system_simulator.mission_system.mission_system_sample")
local MissionWidgets = require("CP0032305_GH.Script.system_simulator.mission_system.mission_widget_sample")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')


local WorldContextObject = nil

function WaitForSeconds(InDuration)
    UE.UKismetSystemLibrary.Delay(WorldContextObject, InDuration)
end

function SafeResume(co, ...)
    local result, value = coroutine.resume(co, ...)
    if (result == false) then
        print("Lua Error:" .. debug.traceback(co, value))
    end
    return result, value
end

-- 任务追踪Widget测试 --------------------------------------------------------------------------------------------------------------
---@param Widget MissionTrackWidgetSample
function MissionWidgetTest:MissionTrack_TestCase1(ContextObject)

    WorldContextObject = ContextObject

    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)

    TaskMainVM:AcceptTask(10000)
    TaskMainVM:AcceptTask(20000)
    local Mission10000 = TaskMainVM:GetUIMissionNode(10000).MissionObject

    ---@type MissionSystemModule
    local MisssionSystemModule = TaskMainVM.MissionSystemModule

    -- 这些注册的回调逻辑已经实现在HudTrackingMission内，应该不需要定制了？
    -- Widget:RegisterUntrackCallback(function()
    -- end)
    -- Widget:RegisterAutoTrackCallback(function()
    -- end)
    -- Widget:RegisterMissionFinishCallback(function()
    -- end)

    function func()
        print("MissionTrack_TestCase1 start")
        TaskMainVM:BindMission(Mission10000, true) -- 绑定任务
        WaitForSeconds(1.0)

        Mission10000.bTracking = true
        -- TaskMainVM.HudTrackingMission:OnMissionTracked() -- 主动追踪
        WaitForSeconds(2.0)
        
        -- 使用MisssionSystemModule回调方式是期望的正常逻辑流程
        -- 使用HudTrackingMission回调方式是UI测试流程

        Mission10000.MissionEventDesc = "测试任务10000 任务节点描述 update"
        --HudTrackingMission:OnMissionProgressUpdate()                  -- 更新进度
        MisssionSystemModule:OnMissionProgressUpdate(Mission10000)      -- 逻辑通知
        print("QAQ", "Update MissionEventDesc")
        WaitForSeconds(5.0)

        Mission10000.MissionEventDesc = "QQQQQQQQQQQ update"
        Mission10000.MissionEventDetailDesc = "测试任务10000 任务节点详细描述 QAQAQAQQAQAQ"
        --HudTrackingMission:OnMissionProgressUpdate()                  -- 更新进度
        MisssionSystemModule:OnMissionProgressUpdate(Mission10000)      -- 逻辑通知
        print("QAQ", "Update     and MissionEventDetailDesc")
        WaitForSeconds(2.0)
        
        Mission10000.MissionEventDesc = "111111 MissionEventDesc 1111111"
        Mission10000.MissionEventDetailDesc = "2222222222 MissionEventDetailDesc 22222222222"
        --HudTrackingMission:OnMissionProgressUpdate()                  -- 更新进度
        MisssionSystemModule:OnMissionProgressUpdate(Mission10000)      -- 逻辑通知
        print("QAQ", "Update 111111 MissionEventDesc 1111111")

        WaitForSeconds(2.0)
        Mission10000.bArriveMissionArea = false
        Mission10000.MissionDistance = 40
        --HudTrackingMission:OnMissionDistanceUpdate() -- 更新距离
        MisssionSystemModule:OnMissionDistanceUpdate(Mission10000)
        print("QAQ", "Update MissionDistance")
        
        WaitForSeconds(2.0)
        Mission10000.bArriveMissionArea = true
        Mission10000.MissionDistance = 0
        --HudTrackingMission:OnMissionDistanceUpdate() -- 更新距离
        MisssionSystemModule:OnMissionDistanceUpdate(Mission10000)
        print("QAQ", "Update MissionDistance")
        
        -- WaitForSeconds(2.0)
        -- HudTrackingMission:OnMissionFinish() -- 完成任务
        -- MisssionSystemModule:OnMissionFinish(Mission10000)

        local bAutoBranch = true
        if bAutoBranch then
            -- 如果任务列表中还有任务且能被追踪，会自动追踪
        else
            WaitForSeconds(2.0)
            TaskMainVM:UnbindMission()          -- 解绑任务
            print("MissionTrack_TestCase1 finish")
        end



        
    end
    local co = coroutine.create(func)
    SafeResume(co)
end

---@param Widget MissionTrackWidgetSample
function MissionWidgetTest:MissionTrack_TestCase2(ContextObject)

    WorldContextObject = ContextObject

    ---@type TaskMainVM
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)

    TaskMainVM:AcceptTask(10000)
    TaskMainVM:AcceptTask(20000)
    local Mission10000 = TaskMainVM:GetUIMissionNode(10000).MissionObject
    local Mission20000 = TaskMainVM:GetUIMissionNode(10000).MissionObject
    
    ---@type MissionSystemModule
    local MisssionSystemModule = TaskMainVM.MissionSystemModule

    -- 这些注册的回调逻辑已经实现在HudTrackingMission内，应该不需要定制了？
    -- Widget:RegisterUntrackCallback(function()
    --     Widget.UnbindMission()
    -- end)
    -- Widget:RegisterAutoTrackCallback(function()
    --     Mission10000.bTracking = true
    --     Widget:TrackMission()
    -- end)
    -- Widget:RegisterMissionFinishCallback(function()
    -- end)

    function func()
        print("MissionTrack_TestCase2 start")

        TaskMainVM:BindMission(Mission10000, true) -- Bind Mission
        WaitForSeconds(4.0) -- 等待超时触发AutoTrack

        -- 使用MisssionSystemModule回调方式是期望的正常逻辑流程
        -- 使用HudTrackingMission回调方式是UI测试流程
        --HudTrackingMission:OnMissionFinish()
        MisssionSystemModule:OnMissionFinish(Mission10000)
        WaitForSeconds(2.0)

        TaskMainVM:UnbindMission() -- 播放任务完成动效时主动切换任务
        TaskMainVM:BindMission(Mission20000, false)
        WaitForSeconds(4.0)

        print("MissionTrack_TestCase2 finish")
    end
    local co = coroutine.create(func)
    SafeResume(co)
end

-- 任务指针Widget测试 --------------------------------------------------------------------------------------------------------------
function MissionWidgetTest:MissionArrow_TestCase3(ContextObject)
    local ActorClass = UE.UClass.Load('/Game/Developers/CP0032305_GH/Test/TaskObjs/BP_TaskVolume.BP_TaskVolume_C')
    local OutActors = UE.UGameplayStatics.GetAllActorsOfClass(ContextObject, ActorClass)
    if OutActors:Length() > 0 then
        local TrackActor = OutActors:Get(1)
        TrackActor:HudTrackRandomItem_Task()
    end
end

-- 伤害指针测试 --------------------------------------------------------------------------------------------------------------
function MissionWidgetTest:MissionArrow_TestCase_QAQ(ContextObject)
    local ActorClass = UE.UClass.Load('/Game/Developers/CP0032305_GH/Test/TaskObjs/BP_TaskVolume.BP_TaskVolume_C')
    local OutActors = UE.UGameplayStatics.GetAllActorsOfClass(ContextObject, ActorClass)
    if OutActors:Length() > 0 then
        local TrackActor = OutActors:Get(1)
        TrackActor:HudTrackRandomItem_Hurt()
    end
end

-- 移除伤害指针测试 --------------------------------------------------------------------------------------------------------------
function MissionWidgetTest:MissionArrow_RemoveTestCase_QAQ(ContextObject)
    local ActorClass = UE.UClass.Load('/Game/Developers/CP0032305_GH/Test/TaskObjs/BP_TaskVolume.BP_TaskVolume_C')
    local OutActors = UE.UGameplayStatics.GetAllActorsOfClass(ContextObject, ActorClass)
    if OutActors:Length() > 0 then
        local TrackActor = OutActors:Get(1)
        TrackActor:HudTrackRandomItem_HurtRemove()
    end
end


-- 宝箱指针测试 --------------------------------------------------------------------------------------------------------------
function MissionWidgetTest:MissionArrow_TestCase_TreasureBox(ContextObject)
    local ActorClass = UE.UClass.Load('/Game/Developers/CP0032305_GH/Test/TaskObjs/BP_TaskVolume.BP_TaskVolume_C')
    local OutActors = UE.UGameplayStatics.GetAllActorsOfClass(ContextObject, ActorClass)
    if OutActors:Length() > 0 then
        local TrackActor = OutActors:Get(1)
        TrackActor:HudTrackRandomItem_TreasureBox()
    end
end

-- 巴别塔指针测试 --------------------------------------------------------------------------------------------------------------
function MissionWidgetTest:MissionArrow_TestCase_Babieta(ContextObject)
    local ActorClass = UE.UClass.Load('/Game/Developers/CP0032305_GH/Test/TaskObjs/BP_TaskVolume.BP_TaskVolume_C')
    local OutActors = UE.UGameplayStatics.GetAllActorsOfClass(ContextObject, ActorClass)
    if OutActors:Length() > 0 then
        local TrackActor = OutActors:Get(1)
        TrackActor:HudTrackRandomItem_Babieta()
    end
end

-- 任务指针Widget测试 --------------------------------------------------------------------------------------------------------------
---@param Widget MissionArrowWidgetSample
function MissionWidgetTest:MissionArrow_TestCase1(Widget)

    function func()
        print("MissionArrow_TestCase1 start")
        local Position = UE.FVector2D()
        Position.X = 640
        Position.Y = 360
        Widget:SetPositionInScreen(Position) -- 设置屏幕坐标
        Widget:ShowArrow(1.02) -- 显示方向箭头，并设置朝向
        Widget:SetDistance(450) -- 设置距离
        WaitForSeconds(3.0)
        Widget:SetDistance(0) -- 设置距离为0
        WaitForSeconds(2.0)
        Widget:HideArrow()  -- 隐藏方向箭头
        print("MissionArrow_TestCase1 finish")
    end
    local co = coroutine.create(func)
    SafeResume(co)
end

---@param Widget NpcTopWidgetSample
function MissionWidgetTest:MissionArrow_TestCase2(Widget)
    Widget:RegisterSelfTalkingEndCallback(function()
    end)
    function func()
        print("MissionArrow_TestCase2 start")
        Widget:ShowArrow(true)
        WaitForSeconds(1.0)
        Widget:DisplaySelfTalking("测试任务碎碎念气泡") -- 播放碎碎念内容
        WaitForSeconds(3.0)
        Widget:DisplaySelfTalking("测试任务碎碎念气泡测试任务碎碎念气泡测试任务碎碎念气泡") -- 播放长的碎碎念内容
        WaitForSeconds(3.0)
        Widget:ShowArrow(false)

        print("MissionArrow_TestCase2 finish")
    end
    local co = coroutine.create(func)
    SafeResume(co)
end

-- 互动区Widget测试 ----------------------------------------------------------------------------------------------------------------
---@param Widget MissionInteractAreaWidgetSample
function MissionWidgetTest:MissionInteractArea_TestCase1(Widget)
    function func()
        print("MissionInteractArea_TestCase1 start")
        Widget:RegisterInteractItemPressedCallback(function()
        end)
        local ShortItems = MissionSystem:GetShortInteractItems()
        Widget:SetInteractItems(ShortItems) -- 设置交互ItemList，数量小于等于4
        WaitForSeconds(5.0)
        local LongItems = MissionSystem:GetLongInteractItems()
        Widget:SetInteractItems(LongItems) -- 设置交互ItemList，数量大于4
        print("MissionInteractArea_TestCase1 finish")
    end
    local co = coroutine.create(func)
    SafeResume(co)
end

-- 物品展示 ----------------------------------------------------------------------------------------------------------------------
---@param Widget ItemDisplayListWidgetSample
function MissionWidgetTest:ItemDisplayListWidget_TestCase1(ContextObject)

    WorldContextObject = ContextObject

    function func()
        print("ItemDisplayListWidget_TestCase1 start")
        local Items = MissionSystem:CreateItemList(5)

        ---@type HudMessageCenter
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        HudMessageCenterVM:PushItemList(Items)

        Items = MissionSystem:CreateItemList(2)
        HudMessageCenterVM:PushNewItemList(Items)
        HudMessageCenterVM:PushSpecItemList(Items)

        Items = MissionSystem:CreateItemList(2)
        HudMessageCenterVM:PushItemList(Items)
        HudMessageCenterVM:PushNewItemList(Items)

        print("ItemDisplayListWidget_TestCase1 finish")
    end
    local co = coroutine.create(func)
    SafeResume(co)
end

-- 任务章节解锁完成提示 ------------------------------------------------------------------------------------------------------------
---@param Widget MissionFinishWidgetSample
function MissionWidgetTest:MissionFinishWidget_TestCase1(ContextObject)

    WorldContextObject = ContextObject

    function func()
        print("MissionFinishWidget_TestCase1 start")

        local FinishInfo = MissionSystem:CreateMissionFinishInfo("第一章", "章节名称", "123456", "已开启","UI_NoAtlas_Img_zhangjie")
        
        ---@type HudMessageCenter
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        HudMessageCenterVM:ShowChapterDisplay(FinishInfo)
    
        WaitForSeconds(4.0)

        FinishInfo = MissionSystem:CreateMissionFinishInfo("第一章", "章节名称", "123456", "已结束")
        HudMessageCenterVM:ShowChapterDisplay(FinishInfo)

        WaitForSeconds(4.0)

        print("MissionFinishWidget_TestCase1 finish")
    end
    local co = coroutine.create(func)
    SafeResume(co)
end

-- HUD消息测试1 ------------------------------------------------------------------------------------------------------------
---@param Widget MissionFinishWidgetSample
function MissionWidgetTest:HudMessage_TestCase1(ContextObject)

    WorldContextObject = ContextObject

    ---@type HudMessageCenter
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)

    function func()
        print("HudMessage_TestCase1 start")

        HudMessageCenterVM:AddCommonTips('第一条通用提示', 2.0)
        HudMessageCenterVM:AddCommonTips('第二条通用提示', 2.0)

        HudMessageCenterVM:AddImportantTips('<n>提示</><h>第一条重要文字</><n>，字数限制三十个字三十个字三十个字三十个字</>', 3.0)

        WaitForSeconds(1.0)
        HudMessageCenterVM:AddCommonTips('第三条通用提示', 2.0)
        HudMessageCenterVM:AddImportantTips('<n>提示</><h>第二条重要文字</><n>，字数限制三十个字三十个字三十个字三十个字</>', 3.0)

        WaitForSeconds(3.0)
        HudMessageCenterVM:AddCommonTips('第四条通用提示', 2.0)
        HudMessageCenterVM:AddImportantTips('<n>提示</><h>第三条重要文字</><n>，字数限制三十个字三十个字三十个字三十个字</>', 3.0)
        HudMessageCenterVM:AddImportantTips('<n>提示</><h>第四条重要文字</><n>，字数限制三十个字三十个字三十个字三十个字</>', 3.0)

        print("MissionFinishWidget_TestCase1 finish")
    end
    local co = coroutine.create(func)
    SafeResume(co)
end

-- HUD消息测试2 ------------------------------------------------------------------------------------------------------------
---@param Widget MissionFinishWidgetSample
function MissionWidgetTest:HudMessage_TestCase2(ContextObject)

    WorldContextObject = ContextObject

    ---@type HudMessageCenter
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)

    function func()
        print("HudMessage_TestCase2 start")

        HudMessageCenterVM:SetBattleResult(true)
        WaitForSeconds(3.0)
        HudMessageCenterVM:SetBattleResult(false)

        print("MissionFinishWidget_TestCase2 finish")
    end
    local co = coroutine.create(func)
    SafeResume(co)
end

-- 对话内容 -------------------------------------------------------------------------------------------------------------------------
---@param Widget DialogueWidgetSample
function MissionWidgetTest:DialogueWidget_TestCase1(Widget)
    function func()
        print("DialogueWidget_TestCase1 start")
        Widget:RegisterFinishCallback(function ()
        end)
        Widget:StartDialogue(MissionSystem:CreateDialogue())
        WaitForSeconds(2.0)
        print("DialogueWidget_TestCase1 finish")
    end
    local co = coroutine.create(func)
    SafeResume(co)
end
-- 倒计时界面 ------------------------------------------------------------------------------------------------------------------------------
function MissionWidgetTest:MissionTimerDisplay_TestCase1(ContextObject)
    WorldContextObject = ContextObject
    ---@type HudMessageCenter
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    function func()
        HudMessageCenterVM:ShowTimerDisplay(10, function(bCancelled)
            print("MissionTimerDisplay_TestCase1 finish1111111111111111111111111111111111", bCancelled)
        end)

        WaitForSeconds(2.0)

        -- HudMessageCenterVM:CancelTimerDisplay()
    end
    local co = coroutine.create(func)
    SafeResume(co)
end


-- 任务界面 ------------------------------------------------------------------------------------------------------------------------------
---@param Widget MissionListWidgetSample
function MissionWidgetTest:MissionListWidget_TestCase1(Widget)
    function func()
        print("MissionListWidget_TestCase1 start")
        Widget:RegisterTrackCallback(function(MissionObject)
        end)
        Widget:RegisterUntrackCallback(function(MissionObject)
        end)
        Widget:SetMissionList(MissionSystem:CreateMissionList())
        WaitForSeconds(2.0)
        print("MissionListWidget_TestCase1 finish")
    end
    local co = coroutine.create(func)
    SafeResume(co)
end

-- 新手指引 ------------------------------------------------------------------------------------------------------------------------------
---@param Widget GuideWidgetSample
function MissionWidgetTest:Guide_TestCase1(ContextObject)
    function func()
        WorldContextObject = ContextObject
        local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
        local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    
        local UIObject = UIManager:OpenUI(UIDef.UIInfo.UI_GuideMain)
    
        function func()
            print("MissionFinishWidget_TestCase1 start")
            local GuideInfo = {}
            for i = 1, 4 do
                table.insert(GuideInfo, {
                    ItemName = '神机元素之力' .. '-' .. i,
                    Content = '会话の内容1行32文字<name>特殊文本</><n>会话の内容1行32文字</><n>会话の内容1行32文字</><name>特殊文本</><n>会话の内容1行32文字</><n>会话の内容1行32文字</><name>特殊文本</><n>会话の内容1行32文字</><n>会话の内容1行32文字</><name>特殊文本</><n>会话の内容1行32文字</>',
                    ImagePath = '/Game/CP0032305_GH/UI/Texture/Common/NoAtlas/Bg_xinshouyindao_03.Bg_xinshouyindao_03'
                })
            end
            UIObject:SetGuideContent(GuideInfo)
    
            -- WaitForSeconds(2.0)
            -- UIManager:CloseUI(UIObject)
            print("MissionFinishWidget_TestCase1 finish")
        end
        local co = coroutine.create(func)
        SafeResume(co)
    end
    local co = coroutine.create(func)
    SafeResume(co)
end

-- 过场黑幕 ------------------------------------------------------------------------------------------------------------
---@param Widget MissionFinishWidgetSample
function MissionWidgetTest:BLackCurtainWidget_TestCase1()
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    local InText="离开了遗落<BlackCurtain>的气象装置，急匆匆赶</>回了村庄。离开了遗落<name>的气象装置，急匆匆赶</>回了村庄。离开了遗落<name>的气象装置，急匆匆赶</>回了村庄。离开了遗落<name>的气象装置，急匆匆赶</>回了村庄。离开了遗落<name>的气象装置，急匆匆赶</>回了村庄。离开了遗落<name>的气象装置，急匆匆赶</>回了村庄。"
    --\n离开了遗落<name>的气象装置，急匆匆赶</>回了村庄。\n离开了遗落的气象装置，急匆匆赶回了村庄。\n离开了遗落<name>的气象装置，急匆匆赶</>回了村庄。\n离开了遗落<name>的气象装置，急匆匆赶</>回了村庄。\n离开了遗落的气象装置，急匆匆赶回了村庄。
        HudMessageCenterVM:ShowSubtitleBlackWidget(InText)
    
        end


-- 二级任务完成提示 ------------------------------------------------------------------------------------------------------------
---@param Widget MissionFinishWidgetSample
function MissionWidgetTest:SecondTaskCompletedWidget_TestCase1()
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    local MissionText="拿到第一把钥匙"
        HudMessageCenterVM:ShowSecondTaskCompleted(MissionText)
           
        end

-- 罐子摇出卡片提示 ------------------------------------------------------------------------------------------------------------
---@param Widget MissionFinishWidgetSample
function MissionWidgetTest:InteractionJarWidget_TestCase1()
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    local ObjectInfo="电话卡"
    local TextID=1018
    HudMessageCenterVM:ShowInteractionJar(ObjectInfo,TextID)   
end

-- 纯剧情 ------------------------------------------------------------------------------------------------------------
---@param Widget MissionFinishWidgetSample
function MissionWidgetTest:PlotTextWidget_TestCase1()
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    local InText="墓碑上又出现文字"
    HudMessageCenterVM:ShowSubtitleWidget(InText)
end

-- 组装遥控器完成提示------------------------------------------------------------------------------------------------------------
---@param Widget MissionFinishWidgetSample
function MissionWidgetTest:EmitterWidget_TestCase1()
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    local ObjectInfo="装有电池的遥控器"
    local InText="搞定了，看着是可以使用了。。。"
    local ImagePath="/Game/CP0032305_GH/UI/Texture/Interaction/Noatlas/T_Interaction_Img_CallingCard02_A.T_Interaction_Img_CallingCard02_A"
    local bShowTopTip=true
    local CallBack=function()
        --随便打开一个UI测试回调逻辑
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        local InText="离开了遗落的气象装置，急匆匆赶回了村庄。"
            HudMessageCenterVM:ShowSubtitleBlackWidget(InText)
    end
    HudMessageCenterVM:ShowInteractionEmitter(ObjectInfo,InText,ImagePath)
end

-- 预弹幕------------------------------------------------------------------------------------------------------------
---@param Widget MissionFinishWidgetSample
function MissionWidgetTest:PreBarrage_TestCase1()
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    local FirstFinishTime=5.3 local SecondStartTime=4 local SecondFinishTime=7 local ThirdStartTime=7 local ThirdFinishTime=9.3 local ForthStartTime=9.3 local ForthFinishTime=14.1
    local FirstInterval=0.7 local SecondInterval=0.3 local ThirdInterval=0.3 local ForthInterval=0.1
    HudMessageCenterVM:ShowPreBarrage(FirstFinishTime,SecondStartTime,SecondFinishTime,ThirdStartTime,ThirdFinishTime,ForthStartTime,ForthFinishTime,FirstInterval,SecondInterval,ThirdInterval,ForthInterval)
end

function MissionWidgetTest:RunTestCase(Object)
    MissionSystem:Initialize()
    WorldContextObject = Object
    -- self:MissionTrack_TestCase1(MissionWidgets.MissionTrackWidget)
    -- self:MissionTrack_TestCase2(MissionWidgets.MissionTrackWidget)
    self:MissionArrow_TestCase1(MissionWidgets.MissionArrowWidget)
    self:MissionArrow_TestCase2(MissionWidgets.NpcTopWidget)
    -- self:MissionInteractArea_TestCase1(MissionWidgets.MissionInteractAreaWidget)
    -- self:ItemDisplayListWidget_TestCase1(MissionWidgets.ItemListDisplayWidget)
    -- self:MissionFinishWidget_TestCase1(MissionWidgets.MissionFinishWidget)
    -- self:DialogueWidget_TestCase1(MissionWidgets.DialogueWidget)
    -- self:MissionListWidget_TestCase1(MissionWidgets.MissionListWidget)
end
-- t = require("ui.mission_system.mission_widget_test")
-- t:RunTestCase(p)

return MissionWidgetTest
