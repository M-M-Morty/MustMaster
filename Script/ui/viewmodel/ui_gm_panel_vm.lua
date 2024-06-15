--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local mission_system_sample = require('CP0032305_GH.Script.system_simulator.mission_system.mission_system_sample')

---@class UIGMPanelTaskVM : ViewModelBase
local UIGMPanelTaskVM = Class(ViewModelBaseClass)

function UIGMPanelTaskVM:ctor()
    Super(UIGMPanelTaskVM).ctor(self)

    self.ItemText = self:CreateVMField('TaskTest')
    self.fnClickTabButton = function()
        self:RefreshData()
    end
end

function UIGMPanelTaskVM:OnReleaseViewModel()
end

function UIGMPanelTaskVM:RefreshData()
    local UIGMInstance = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_GMPanel.UIName)
    if UIGMInstance then
        self.NpcTestData = self:CreateNpcTestData()
        self.TaskTestData = self:CreateTaskTestData()

        local UIContent = UIGMInstance:FillTabFrame(
        '/Game/CP0032305_GH/UI/UMG/Ingame/GMPanel/TaskTest/WBP_GMPanel_TaskTest.WBP_GMPanel_TaskTest_C')
        if UIContent then
            UIContent:BindViewModelField(self.NpcTestData, self.TaskTestData)
        end
    end
end

-- 左侧对话入口
function UIGMPanelTaskVM:CreateNpcTestData()
    return self:CreateVMArrayField({
        { Title = '简单的对话序列', DialogueKey = 'DialogTest1' },
        { Title = '带选择的对话', DialogueKey = 'DialogTest2' },
        { Title = '弹幕界面测试', DialogueKey = 'UIBarrage'},
        { Title = '演职员表测试', DialogueKey = 'UIScreenCreditList'},
        { Title = '大招能量测试', DialogueKey = 'TestPower'},
        { Title = '情景对话测试', DialogueKey = 'Situation'},
    })
end

function UIGMPanelTaskVM:CreateTaskTestData()
    return self:CreateVMArrayField(mission_system_sample.MissionDataTable)
end

---@class UIGMPanelVM : ViewModelBase
local UIGMPanelVM = Class(ViewModelBaseClass)

function UIGMPanelVM:ctor()
    Super(UIGMPanelVM).ctor(self)

    self.ToggleSwitcherIndex = self:CreateVMField(0)
    self.TabListData = self:CreateVMArrayField(
        {
            UIGMPanelTaskVM.new(),
            {
                ItemText = 'Ver 8.29.0',
                fnClickTabButton = function()
                    -- 测试开启关闭等待功能时序1
                    -- UIManager:CloseUIByName(UIDef.UIInfo.UI_TaskMain.UIName, true)
                    -- UIManager:OpenUI(UIDef.UIInfo.UI_TaskMain)

                    -- 测试开启关闭等待功能时序2
                    -- UIManager:CloseOtherAndOpenUI(UIDef.UIInfo.UI_TaskMain.UIName, {'UI_MainInterfaceHUD'})
                    -- local wnd1 = UIManager:OpenUI(UIDef.UIInfo.UI_TaskMain)
                    -- UIManager:CloseUIByName(UIDef.UIInfo.UI_TaskMain.UIName)
                    -- UIManager:CloseUIByName(UIDef.UIInfo.UI_TaskMain.UIName, true)
                    -- local wnd2 = UIManager:OpenUI(UIDef.UIInfo.UI_TaskMain)
                    -- UIManager:OpenUI(UIDef.UIInfo.UI_TaskMain)
                    -- UIManager:CloseUIByName(UIDef.UIInfo.UI_TaskMain.UIName)
                    -- UIManager:OpenUI(UIDef.UIInfo.UI_TaskMain)
                    -- print('bbbbbbbbbbbbbbbb', wnd1, wnd2)
                    -- UIManager:OpenUI(UIDef.UIInfo.UI_TaskMain)
                    -- UIManager:OpenUI(UIDef.UIInfo.UI_TaskMain)
                end,
            },
            --[[
            {
                ItemText = 'MissionTracking',
                fnClickTabButton = function()
                    local UIMissionTrack = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MissionTrack.UIName)
                    if UIMissionTrack then
                        UIManager:CloseUI(UIMissionTrack)
                    else
                        UIManager:OpenUI(UIDef.UIInfo.UI_MissionTrack)
                    end
                end,
            },
            --]]
            -- {
            --     ItemText = 'communicationDemo',
            --     fnClickTabButton = function()
            --         local UICommunication = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_CommunicationMain.UIName)
            --         if UICommunication then
            --             UIManager:CloseUI(UICommunication)
            --         else
            --             UIManager:OpenUI(UIDef.UIInfo.UI_CommunicationMain)
            --         end
            --     end,
            -- },
            -- {
            --     ItemText = 'communicationNPCDemo',
            --     fnClickTabButton = function()
            --         local UICommunication = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_CommunicationNPC.UIName)
            --         if UICommunication then
            --             UIManager:CloseUI(UICommunication)
            --         else
            --             UIManager:OpenUI(UIDef.UIInfo.UI_CommunicationNPC)
            --         end
            --     end,
            -- },
            ----[[
            -- {
            --     ItemText = 'MvvmDemo',
            --     fnClickTabButton = function()
            --         local UIMvvmDemo = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_MVVMDemo.UIName)
            --         if UIMvvmDemo then
            --             UIManager:CloseUI(UIMvvmDemo)
            --         else
            --             UIManager:OpenUI(UIDef.UIInfo.UI_MVVMDemo)
            --         end
            --     end,
            -- },
            --]]
            {
                ItemText = 'UI隐藏',
                fnClickTabButton = function()
                    UIManager:HideAllHUD()
                end,
            },
            {
                ItemText = 'UI打开',
                fnClickTabButton = function()
                    ---@type WBP_HUD_MainInterface
                    UIManager:RecoverShowAllHUD()
                end,
            },
            {
                ItemText = '人物技能',
                fnClickTabButton = function()
                    local limit = 20
                    if not self.Cur then
                        self.Cur = 18
                    end
                    self.Cur = (self.Cur + 2) % 21
                    local Owner = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
                    Owner.BP_PlayerStaminaWidget:UpdateStamina(self.Cur, limit)
                end,
            },
            {
                ItemText = '进入事务所',
                fnClickTabButton = function()
                    local t = require("t")
                    t.TeleInOffice()
                end,
            },
            {
                ItemText = '退出事务所',
                fnClickTabButton = function()
                    local t = require("t")
                    t.TeleOutOffice()
                end,
            },
            {
                ItemText = '显示特殊互动键',
                fnClickTabButton = function()
                    ---@type WBP_HUD_MainInterface
                    local UIInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_SkillState.UIName)
                    if UIInstance then
                        UIInstance:UpdateInteractionSpecial(true)
                    end
                end,
            },
            {
                ItemText = '隐藏特殊互动键',
                fnClickTabButton = function()
                    ---@type WBP_HUD_MainInterface
                    local UIInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_SkillState.UIName)
                    if UIInstance then
                        UIInstance:UpdateInteractionSpecial(false)
                    end
                end,
            },
            {
                ItemText = '显示瞄准互动键',
                fnClickTabButton = function()
                    ---@type WBP_HUD_MainInterface
                    local UIInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_SkillState.UIName)
                    if UIInstance then
                        UIInstance:UpdateInteractionMirror(true)
                    end
                end,
            },
            {
                ItemText = '隐藏瞄准互动键',
                fnClickTabButton = function()
                    ---@type WBP_HUD_MainInterface
                    local UIInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_SkillState.UIName)
                    if UIInstance then
                        UIInstance:UpdateInteractionMirror(false)
                    end
                end,
            },
            {
                ItemText = '播放主界面入场动画',
                fnClickTabButton = function()
                    ---@type WBP_HUD_MainInterface
                    local UIInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
                    if UIInstance then
                        UIInstance:PlayInOutAnim(true)
                    end
                end,
            },
            {
                ItemText = '播放主界面出场动画',
                fnClickTabButton = function()
                    ---@type WBP_HUD_MainInterface
                    local UIInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
                    if UIInstance then
                        UIInstance:PlayInOutAnim(false)
                    end
                end,
            },
            {
                ItemText = '目标NPC执行一下测试',
                fnClickTabButton = function()
                    local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
                    local Pawn = G.GetPlayerCharacter(UIManager.GameWorld, 0)
                    local TargetActors = UE.TArray(UE.AActor)
                    UE.UGameplayStatics.GetAllActorsOfClass(UIManager.GameWorld,
                        FunctionUtil:IndexRes('BPA_GH_MonsterBase_C'), TargetActors)
                    local Distance, NearestObj = nil, nil
                    for i, obj in pairs(TargetActors) do
                        local dist = obj:GetDistanceTo(Pawn)
                        if (not Distance) or (dist < Distance) then
                            Distance = dist
                            NearestObj = obj
                        end
                    end
                    if NearestObj and NearestObj.ClientRPC then
                        local UIPreview = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_PreviewAnimation.UIName)
                        if UIPreview then
                            UIPreview:CloseMyself()
                        elseif NearestObj:GetPreviewTag() and Distance < 1000 then
                            UIManager:OpenUI(UIDef.UIInfo.UI_PreviewAnimation, NearestObj)
                        elseif not NearestObj:GetPreviewTag() then
                            NearestObj:ClientRPC('serverExecuteCmd', 'testGE')
                        end
                    end
                end,
            },
        }
    )
end

function UIGMPanelVM:OnReleaseViewModel()
    for v in self.TabListData:Items_Iterator() do
        v:ReleaseVMObj()
    end
end

return UIGMPanelVM
