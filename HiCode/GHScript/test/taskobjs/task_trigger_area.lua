--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local mission_widget_test = require('CP0032305_GH.Script.system_simulator.mission_system.mission_widget_test')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@type BP_TaskTriggerArea_C
local M = Class()

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function M:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)

    if not self:HasAuthority() then
        self.Cylinder.OnComponentBeginOverlap:Add(self, self.Cylinder_OnComponentBeginOverlap)
        self.Cylinder.OnComponentEndOverlap:Add(self, self.Cylinder_OnComponentEndOverlap)
        ---@type WBP_HeadInfo_C
        local HeadWidget = self.BP_BillBoardWidget:GetWidget()
        if HeadWidget then
            HeadWidget:SetOnConstructDelegate(function(Widget)
                if Widget.WBP_TypeWriter and Widget.SetBubble then
                    Widget:SetBubble('新手指引结束后在这里接取任务')  
                    Widget:SetNpcHudDuration(2)
                end
            end)
        end
    end
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param OtherBodyIndex integer
---@param bFromSweep boolean
---@param SweepResult FHitResult
function M:Cylinder_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not self:HasAuthority() then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        if InteractVM then
            local InteractItems = {}
            InteractItems[1] =
            {
                GetSelectionTitle = function()
                    return '任务追踪测试一'
                end,
                SelectionAction = function()
                    mission_widget_test:MissionTrack_TestCase1(self)
                end,
                GetDisplayIconPath = function()
                end,
                GetType = function()
                    return 1
                end,
                GetType = function()
                    return 2            -- MISSION
                end,
            }
            InteractItems[2] =
            {
                GetSelectionTitle = function()
                    return '任务追踪测试二'
                end,
                SelectionAction = function()
                    mission_widget_test:MissionTrack_TestCase2(self)
                end,
                GetDisplayIconPath = function()
                end,
                GetType = function()
                    return 1
                end,
                GetType = function()
                    return 2            -- MISSION
                end,
            }
            InteractItems[3] =
            {
                GetSelectionTitle = function()
                    return '任务指针测试'
                end,
                SelectionAction = function()
                    mission_widget_test:MissionArrow_TestCase3(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[4] =
            {
                GetSelectionTitle = function()
                    return '章节解锁测试'
                end,
                SelectionAction = function()
                    mission_widget_test:MissionFinishWidget_TestCase1(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[5] =
            {
                GetSelectionTitle = function()
                    return 'HUD物品提示测试'
                end,
                SelectionAction = function()
                    mission_widget_test:ItemDisplayListWidget_TestCase1(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[6] =
            {
                GetSelectionTitle = function()
                    return 'HUD消息测试1'
                end,
                SelectionAction = function()
                    mission_widget_test:HudMessage_TestCase1(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[7] =
            {
                GetSelectionTitle = function()
                    return '新手指引测试'
                end,
                SelectionAction = function()
                    mission_widget_test:Guide_TestCase1(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[8] =
            {
                GetSelectionTitle = function()
                    return 'TimerDispaly测试'
                end,
                SelectionAction = function()
                    mission_widget_test:MissionTimerDisplay_TestCase1(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[9] =
            {
                GetSelectionTitle = function()
                    return '召唤boss血条'
                end,
                SelectionAction = function()
                    self.bosshp = UIManager:OpenUI(UIDef.UIInfo.UI_BossHP,100,100,100,100,"test")
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[10] =
            {
                GetSelectionTitle = function()
                    return '普通攻击'
                end,
                SelectionAction = function()
                    local data = {Type = "normalAttack",num = 20}
                    self.bosshp:ChangeBossHP(data)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[11] =
            {
                GetSelectionTitle = function()
                    return '特殊攻击'
                end,
                SelectionAction = function()
                    local data = {Type = "specialAttack",num = 20}
                    self.bosshp:ChangeBossHP(data)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[12] =
            {
                GetSelectionTitle = function()
                    return '回血'
                end,
                SelectionAction = function()
                    local data = {Type = "bossAddHealth",num = 20}
                    self.bosshp:ChangeBossHP(data)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[13] =
            {
                GetSelectionTitle = function()
                    return '护盾攻击'
                end,
                SelectionAction = function()
                    local data = {Type = "shieldAttack",num = 20}
                    self.bosshp:ChangeBossHP(data)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[14] =
            {
                GetSelectionTitle = function()
                    return '护盾恢复'
                end,
                SelectionAction = function()
                    local data = {Type = "shieldRecover",shield = 20}
                    self.bosshp:ChangeBossHP(data)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[15] =
            {
                GetSelectionTitle = function()
                    return '伤害指针测试'
                end,
                SelectionAction = function()
                    mission_widget_test:MissionArrow_TestCase_QAQ(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[16] =
            {
                GetSelectionTitle = function()
                    return '移除伤害指针测试'
                end,
                SelectionAction = function()
                    mission_widget_test:MissionArrow_RemoveTestCase_QAQ(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[17] =
            {
                GetSelectionTitle = function()
                    return '巴别塔指针测试'
                end,
                SelectionAction = function()
                    mission_widget_test:MissionArrow_TestCase_Babieta(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[18] =
            {
                GetSelectionTitle = function()
                    return '过场黑幕测试'
                end,
                SelectionAction = function()
                    mission_widget_test:BLackCurtainWidget_TestCase1(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[19] =
            {
                GetSelectionTitle = function()
                    return '二级任务完成提示'
                end,
                SelectionAction = function()
                    mission_widget_test:SecondTaskCompletedWidget_TestCase1(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[20] =
            {
                GetSelectionTitle = function()
                    return '摇出卡片提示'
                end,
                SelectionAction = function()
                    mission_widget_test:InteractionJarWidget_TestCase1(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,

            }
            InteractItems[21] =
            {
                GetSelectionTitle = function()
                    return '纯剧情'
                end,
                SelectionAction = function()
                    mission_widget_test:PlotTextWidget_TestCase1(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,

            }
            InteractItems[22] =
            {
                GetSelectionTitle = function()
                    return '获得遥控器'
                end,
                SelectionAction = function()
                    mission_widget_test:EmitterWidget_TestCase1(self)
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,

            }
            InteractItems[23] =
            {
                GetSelectionTitle = function()
                    return '预弹幕'
                end,
                SelectionAction = function()
                    mission_widget_test:PreBarrage_TestCase1()
                end,
                GetType = function()
                    return 1
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractVM:OpenInteractSelectionForPickup(InteractItems)

            local InputDef = require('CP0032305_GH.Script.common.input_define')
            ---@type HudMessageCenter
            local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
            -- HudMessageCenterVM:ShowControlTips('查看HUD消息测试2', InputDef.Keys.E, function()
            --     mission_widget_test:HudMessage_TestCase2(self)
            -- end)
            HudMessageCenterVM:ShowControlTips('查看HUD消息测试2', InputDef.Keys.SpaceBar, function()
                mission_widget_test:HudMessage_TestCase2(self)
            end)
        end
    end
end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param OtherBodyIndex integer
function M:Cylinder_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if not self:HasAuthority() then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        if InteractVM then
            InteractVM:CloseInteractSelection()

            ---@type HudMessageCenter
            local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
            HudMessageCenterVM:HideControlTips()
            
        end
    end
end


return M
