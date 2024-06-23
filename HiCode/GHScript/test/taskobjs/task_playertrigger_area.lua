--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local mission_widget_test = require('CP0032305_GH.Script.system_simulator.mission_system.mission_widget_test')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local utils = require("common.utils")

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
                    Widget:SetBubble('PlayerTest')  
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

            ---@class HudMessageCenter
            local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
            InteractItems[1] =
            {
                GetSelectionTitle = function()
                    return '队伍列表测试'
                end,
                SelectionAction = function()
                    local teamsList
                    -- 大招按钮相关配置
                    local SkillInfo = {skillID = 1000}
                    local teamsList1 = {}
                    teamsList1.SkillInfo = SkillInfo
                    teamsList1.AvatarName = "ShiWuYe"
                    teamsList1.AvatarCDtime = 5
                    teamsList1.DeadCDTime = 5
                    
                    local teamsList2 = {}
                    teamsList2.SkillInfo = SkillInfo
                    teamsList2.AvatarName = "WaLi"
                    teamsList2.AvatarCDtime = 10
                    teamsList2.DeadCDTime = 10
                    teamsList = {teamsList1, teamsList2}
                    HudMessageCenterVM:OpenSquadList(1,teamsList)
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[2] =
            {
                GetSelectionTitle = function()
                    return '选择'
                end,
                SelectionAction = function()
                    self.curTeamsListIndex = self.curTeamsListIndex or 1 
                    if self.curTeamsListIndex == 1 then
                        self.curTeamsListIndex = 2
                    else
                        self.curTeamsListIndex = 1
                    end
                    HudMessageCenterVM:SwitchPlayer(self.curTeamsListIndex)
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[3] =
            {
                GetSelectionTitle = function()
                    return '改变位置1的角色的血条'
                end,
                SelectionAction = function()
                    self.curTeamPlayerHealth = self.curTeamPlayerHealth or 100
                    self.curTeamPlayerHealth = self.curTeamPlayerHealth - 10
                    HudMessageCenterVM:OnSquadListRoleHealthChanged(1,self.curTeamPlayerHealth / 100)
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[4] =
            {
                GetSelectionTitle = function()
                    return '位置1的角色死一死'
                end,
                SelectionAction = function()
                    HudMessageCenterVM:OnSquadListRoleDead(1)
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[5] =
            {
                GetSelectionTitle = function()
                    return '消耗耐力条'
                end,
                SelectionAction = function()
                    self.staminaValue = self.staminaValue or 100 
                    HudMessageCenterVM:UpdateStamina(self.staminaValue,100)
                    self.staminaValue = self.staminaValue - 30
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[6] =
            {
                GetSelectionTitle = function()
                    return '区域能力_瞄准了'
                end,
                SelectionAction = function()
                    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
                    AreaAbilityVM:SetAimed(true)
                    AreaAbilityVM:EnterReplicatorAimState()
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[7] =
            {
                GetSelectionTitle = function()
                    return '区域能力_未瞄准'
                end,
                SelectionAction = function()
                    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
                    AreaAbilityVM:SetAimed(false)
                    AreaAbilityVM:EnterReplicatorNomalState()
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[8] =
            {
                GetSelectionTitle = function()
                    return '吸收区域能力_吸收'
                end,
                SelectionAction = function()
                    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
                    AreaAbilityVM:CloseCopyerPanel()
                    AreaAbilityVM:SetHasAreaAbility(true)
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[9] =
            {
                GetSelectionTitle = function()
                    return '使用区域能力_使用'
                end,
                SelectionAction = function()
                    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
                    AreaAbilityVM:CloseAreaAbilityPanel()
                    AreaAbilityVM:SetHasAreaAbility(false)
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[10] =
            {
                GetSelectionTitle = function()
                    return '打开马杜克灯'
                end,
                SelectionAction = function()
                    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
                    AreaAbilityVM:OpenMadukPanel()
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[11] =
            {
                GetSelectionTitle = function()
                    return '关闭马杜克灯'
                end,
                SelectionAction = function()
                    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
                    AreaAbilityVM:CloseMadukPanel()
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[12] =
            {
                GetSelectionTitle = function()
                    return '使用马杜克灯'
                end,
                SelectionAction = function()
                    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
                    AreaAbilityVM:CloseMadukPanel()
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[12] =
            {
                GetSelectionTitle = function()
                    return '瞄准'
                end,
                SelectionAction = function()
                    local ui = UIManager:OpenUI(UIDef.UIInfo.UI_ControlTips)
                    ui:SpecialOpen(" :k:::::::瞄准目标使用，或:右键:::::::对自己使用")
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[13] =
            {
                GetSelectionTitle = function()
                    return '瞄准'
                end,
                SelectionAction = function()
                    local ui = UIManager:OpenUI(UIDef.UIInfo.UI_ControlTips)
                    ui:SpecialOpen(" :::::::右键:瞄准目标使用，或::::::::对自己使用")
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractItems[14] = {
                GetSelectionTitle = function()
                    return 'Buff界面测试'
                end,
                SelectionAction = function()
                    local BuffVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.SkillBuffVM.UniqueName)
                    BuffVM:AddBuff(self:TestCreateGETag(), 'Ability.Buff.SuperSkill', '测试buff', 10, '这是一个测试buff,这是一个测试buff,这是一个测试buff,这是一个测试buff')
                    G.log:debug('zys','buff界面测试, 添加一个buff')
                    utils.DoDelay(UIManager.GameWorld, 10, function()
                        BuffVM:RemoveBuff(self:TestCreateGETag())
                        G.log:debug('zys', 'buff界面测试, 移除一个buff')
                    end)
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractVM:OpenInteractSelection(InteractItems)

            ---@type HudMessageCenter
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
