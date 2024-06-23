--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local BlueprintConst = require("CP0032305_GH.Script.common.blueprint_const")
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ItemUtil = require("common.item.ItemUtil")
local PicText = require("CP0032305_GH.Script.common.pic_const")
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIEventDef = require('CP0032305_GH.Script.ui.ui_event.ui_event_def')
local UIEventContainer = require('CP0032305_GH.Script.ui.ui_event.ui_wait_event_container')
local UIWaitController = require('CP0032305_GH.Script.ui.ui_event.ui_wait_controller')
local FirmUtil = require("CP0032305_GH.Script.ui.view.ingame.Firm.FirmUtil")

---@class WBP_HUD_MainInterface : WBP_HUD_MainInterface_C

---@type WBP_HUD_MainInterface_C
---@field MissionData MissionObject
local WBP_HUD_MainInterface = Class(UIWindowBase)

---@param self WBP_HUD_MainInterface
---@param bShow boolean
local function UpdateVisitorSlate(self, bShow)
    self.Cvs_VisitorStatus:SetVisibility(bShow and UE.ESlateVisibility.SelfHitTestInvisible or
        UE.ESlateVisibility.Collapsed)
end

---@param self WBP_HUD_MainInterface
local function OnClickRenovation(self)
    G.log:debug("gh_ui_MainHUD", "<<<<<<OnClickRenovation...")
end

---@param self WBP_HUD_MainInterface
local function OnClickCallingCard(self)
    G.log:debug("gh_ui_MainHUD", "<<<<<<OnClickCallingCard...")
end

---@param self WBP_HUD_MainInterface
local function OnClickActivity(self)
    G.log:debug("gh_ui_MainHUD", "<<<<<<OnClickActivity...")
end

---@param self WBP_HUD_MainInterface
local function OnClickBP(self)
    G.log:debug("gh_ui_MainHUD", "<<<<<<OnClickBP...")
end

---@param self WBP_HUD_MainInterface
local function OnClickShop(self)
    G.log:debug("gh_ui_MainHUD", "<<<<<<OnClickShop...")
end

---@param self WBP_HUD_MainInterface
local function OnClickKnapasck(self)
    UIManager:OpenUI(UIDef.UIInfo.UI_Knapsack_Main2)
end

---@param self WBP_HUD_MainInterface
local function OnClickRole(self)
    G.log:debug("gh_ui_MainHUD", "<<<<<<OnClickRole...")
end

---@param self WBP_HUD_MainInterface
local function OnClickTask(self)
    UIManager:OpenUI(UIDef.UIInfo.UI_TaskMain)
end

---@param self WBP_HUD_MainInterface
local function OnClickMultiplayer(self)
    G.log:debug("gh_ui_mainhud", "<<<<<<OnClickMultiplayer...")
end

---@param self WBP_HUD_MainInterface
local function OnClickWegame(self)
    G.log:debug("gh_ui_mainhud", "<<<<<<OnClickWegame...")
end

---@param self WBP_HUD_MainInterface
local function OnClickMore(self)
    G.log:debug("gh_ui_mainhud", "<<<<<<OnClickMore...")
end

---@param self WBP_HUD_MainInterface
local function OnClickAttra(self)
    G.log:debug("gh_ui_mainhud", "<<<<<<OnClickAttra...")
end

-- ---@param self WBP_HUD_MainInterface
-- local function OnClickChat(self)
--     G.log:debug("gh_ui_mainhud", "<<<<<<OnClickChat...")
-- end

---@param self WBP_HUD_MainInterface
local function OnClickAction(self)
    G.log:debug("gh_ui_mainhud", "<<<<<<OnClickAction...")
end

---@param self WBP_HUD_MainInterface
local function OnClickProp(self)
    G.log:debug('zys', '<<<<<<OnClickProp...')
    local Player = G.GetPlayerCharacter(UIManager.GameWorld, 0)
    Player:SendMessage("OpenAreaAbilityPanel")
end
---@param self WBP_HUD_MainInterface
local function OnClickScan(self)
    G.log:debug('zys', '<<<<<<OnClickScan...')
    local Player = G.GetPlayerCharacter(UIManager.GameWorld, 0)
    Player:SendMessage("OpenAreaAbilityPanel")
end

--放置按钮
local function OnClickPlace(self)
    -- G.log:debug('zys', '<<<<<<OnClickScan...')
    -- local Player = G.GetPlayerCharacter(UIManager.GameWorld, 0)
    -- Player:SendMessage("OpenCopyerPanel")
end

---@param self WBP_HUD_MainInterface
---@param bEnterFirm boolean 是否进入事务所
local function UpdateFirmUI(self, bEnterFirm)
    G.log:debug("gh_ui_mainhud", "WBP_HUD_MainInterface:UpdateFirmUI>>>bEnterFirm=%s", bEnterFirm)
    if bEnterFirm then
        self.Cvs_IconRenovation:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Cvs_IconCallingCard:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Cvs_IconRenovation:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Cvs_IconCallingCard:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    local SquadListUI = self.WBP_HUD_SquadList
    if SquadListUI then
        SquadListUI:UpdateUIFirmMode(bEnterFirm)
    else
        G.log:debug("gh_ui_mainhud", "Error! SquadListUI is nil")
    end
end

---@param self WBP_HUD_MainInterface
---@param AreaType Enum.Enum_AreaType 区域的类型
local function OnAreaTypeChange(self, AreaType)
    G.log:debug("gh_ui_mainhud", "WBP_HUD_MainInterface:OnAreaTypeChange>>>AreaType=%d, %s", AreaType,
        AreaType == Enum.Enum_AreaType.Office)
    if AreaType == Enum.Enum_AreaType.Office then
        --- 进入事务所
        UpdateFirmUI(self, true)
    else
        --- 退出事务所
        UpdateFirmUI(self, false)
    end
end

--- 监听区域改变
---@param self WBP_HUD_MainInterface
local function BindAreaTypeChange(self)
    G.log:debug("gh_ui_mainhud", "WBP_HUD_MainInterface:BindAreaTypeChange()>>>World=%s", G.GameInstance:GetWorld())
    local PlayerState = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0)
    if PlayerState == nil then
        G.log:debug("gh_ui_mainhud", ">>>Get PlayerState is nil, Try again")
        --- 延迟一下，再重新尝试获取
        UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, BindAreaTypeChange }, 0.5, false)
        return
    end

    if PlayerState.OnAreaTypeChange then
        PlayerState.OnAreaTypeChange:Add(self, OnAreaTypeChange)
    end
end

---@param self WBP_HUD_MainInterface
local function InitUI(self)
    self:UpdateUIFirmSystemEnter(false)
    self:UpdateUIFirmGuest(false)
end

---@param self WBP_HUD_MainInterface
local function InitAreaAbility(self)
    self.WBP_HUD_PlayerHP_Item.Switcher_Use:SetActiveWidgetIndex(1)
end

---@param self WBP_HUD_MainInterface
---@param ActionValue boolean
---@param ElapsedSeconeds number
---@param TriggeredSeconds number
local function OnPressedKeyEvent(self, ActionValue, ElapsedSeconeds, TriggeredSeconds)

end

---@param self WBP_HUD_MainInterface
---@param ActionValue boolean
---@param ElapsedSeconeds number
---@param TriggeredSeconds number
local function OnReleasedKeyEvent(self, ActionValue, ElapsedSeconeds, TriggeredSeconds)
end



function WBP_HUD_MainInterface:Construct()
    --- 需要延迟一下，确保能正确获得PlayerState
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, BindAreaTypeChange }, 0.5, false)

    --- 系统功能按钮
    self.WBP_IconRenovation.Button.OnClicked:Add(self, OnClickRenovation)
    self.WBP_IconCallingCard.Button.OnClicked:Add(self, OnClickCallingCard)
    self.WBP_IconActivity.Button.OnClicked:Add(self, OnClickActivity)
    self.WBP_IconBP.Button.OnClicked:Add(self, OnClickBP)
    self.WBP_IconShop.Button.OnClicked:Add(self, OnClickShop)
    self.WBP_IconKnapasck.Button.OnClicked:Add(self, OnClickKnapasck)
    self.WBP_IconRole.Button.OnClicked:Add(self, OnClickRole)
    self.WBP_Task.Button.OnClicked:Add(self, OnClickTask)

    --- 平台入口
    self.WBP_Btn_Multiplayer.Button.OnClicked:Add(self, OnClickMultiplayer)
    self.WBP_Btn_Wegame.Button.OnClicked:Add(self, OnClickWegame)
    self.WBP_Btn_More.Button.OnClicked:Add(self, OnClickMore)

    self.WBP_Btn_Attra.Button.OnClicked:Add(self, OnClickAttra)

    --- 聊天动作
    -- self.WBP_Button_Chat.Button.OnClicked:Add(self, OnClickChat)
    self.WBP_Button_Action.Button.OnClicked:Add(self, OnClickAction)
    
    self.WBP_HUD_SkillState.AreaPower_Action_Button.WBP_ComBtn_Skill.Button.OnClicked:Add(self, OnClickScan)
    --self.WBP_HUD_PlayerHP_Item.WBP_ComBtn_Prop.Button.OnClicked:Add(self, OnClickProp)
    self.WBP_HUD_SkillState.Place_Action_Button.WBP_ComBtn_Skill.OnClicked:Add(self, OnClickPlace)

    InitUI(self)
    InitAreaAbility(self)
    FirmUtil.RegMissionChanged(self,self.OnMissionChanged)

    local LayerName = UIDef.UILayer[self.UIInfo.UILayerIdent + 1] or ''

    UIManager.UINotifier:BindNotification(UIEventDef["Hidden"..LayerName], self, self.OnHide)
    UIManager.UINotifier:BindNotification(UIEventDef["Visible"..LayerName], self, self.OnShow)
    ---滑板默认关闭
    self.WBP_HUD_PlayerHP_Item:EnterVehicleState(false)
end

function WBP_HUD_MainInterface:OnShow()
    self:StopAnimationsAndLatentActions()

    self:SetAreaAbilityIcon()
    UIManager:RegisterPressedKeyDelegate(self, OnPressedKeyEvent)
    UIManager:RegisterReleasedKeyDelegate(self, OnReleasedKeyEvent)
    self:PlayInOutAnim(true)
    self.WBP_HUD_SkillState:OnShow()
    self.WBP_HUD_Task_Track:OnShow()
    self:OnControllerShow()
end

function WBP_HUD_MainInterface:OnControllerShow()
    local controller = UE.UGameplayStatics.GetPlayerController(self, 0)
    controller.ControllerUIComponent:TryShowTeamListUI(self.WBP_HUD_SquadList)
    local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    Player.UIComponent:ShowPlayerHp(self.WBP_HUD_PlayerHP_Item)
    Player.UIComponent:InitPowerVal()
end

function WBP_HUD_MainInterface:OnHide()
    self:StopAnimationsAndLatentActions()

    UIManager:UnRegisterPressedKeyDelegate(self)
    UIManager:UnRegisterReleasedKeyDelegate(self)
    self:PlayInOutAnim(false)
    self.WBP_HUD_SkillState:OnHide()
    self.WBP_HUD_Task_Track:OnHide()
end

--- 播放界面的入场出场动画
---@param bIn boolean 是否是界面入场动画
function WBP_HUD_MainInterface:PlayInOutAnim(bIn)
    ---@type UWidgetAnimation
    local CurAnim = bIn and self.DX_In or self.DX_Out
    self:PlayAnimation(CurAnim, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

---@param bShowFirmSystemEnter boolean 是否显示事务所功能入口
function WBP_HUD_MainInterface:UpdateUIFirmSystemEnter(bShowFirmSystemEnter)
    UpdateFirmUI(self, bShowFirmSystemEnter)
end

---@param bEnterFirmGuest boolean 是否以访客状态进入他人事务所
function WBP_HUD_MainInterface:UpdateUIFirmGuest(bEnterFirmGuest)
    UpdateVisitorSlate(self, bEnterFirmGuest)
end

---更新道具icon接口
---TODO 需要确定具体的道具使用需求之后在细化接口
---@param ItemUniqueID integer 道具唯一ID
function WBP_HUD_MainInterface:UpdateUseItemIconByUniqueID(ItemUniqueID)
    ---@type ItemConfig
    local ItemConfig = ItemUtil.GetItemManager(self):GetItemConfigByUniqueID(ItemUniqueID)
    PicText.SetImageBrush(self.Img_ItemIcon, ItemConfig.icon_reference)
end

---@param Mission MissionObject
function WBP_HUD_MainInterface:OnMissionChanged(Mission)
    local missionType = type(Mission)
    if missionType == "table" then
        self.MissionData = Mission
        self.WBP_HUD_MiniMap:ReceiveMissionData(self.MissionData)
    elseif missionType == "number" then
        self.WBP_HUD_MiniMap:RemoveMissionUI()
    end
end

function WBP_HUD_MainInterface:Tick(MyGeometry, InDeltaTime)
end

function WBP_HUD_MainInterface:Destruct()
    local PlayerState = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0)
    if PlayerState and PlayerState.OnAreaTypeChange then
        PlayerState.OnAreaTypeChange:Remove(self, OnAreaTypeChange)
    end

    self.WBP_IconRenovation.Button.OnClicked:Remove(self, OnClickRenovation)
    self.WBP_IconCallingCard.Button.OnClicked:Remove(self, OnClickCallingCard)
    self.WBP_IconActivity.Button.OnClicked:Remove(self, OnClickActivity)
    self.WBP_IconBP.Button.OnClicked:Remove(self, OnClickBP)
    self.WBP_IconShop.Button.OnClicked:Remove(self, OnClickShop)
    self.WBP_IconKnapasck.Button.OnClicked:Remove(self, OnClickKnapasck)
    self.WBP_IconRole.Button.OnClicked:Remove(self, OnClickRole)
    self.WBP_Btn_Multiplayer.Button.OnClicked:Remove(self, OnClickMultiplayer)
    self.WBP_Btn_Wegame.Button.OnClicked:Remove(self, OnClickWegame)
    self.WBP_Btn_More.Button.OnClicked:Remove(self, OnClickMore)
    self.WBP_Btn_Attra.Button.OnClicked:Remove(self, OnClickAttra)
    -- self.WBP_Button_Chat.Button.OnClicked:Remove(self, OnClickChat)
    self.WBP_Button_Action.Button.OnClicked:Remove(self, OnClickAction)
    --self.WBP_HUD_PlayerHP_Item.WBP_ComBtn_Scan.Button.OnClicked:Remove(self, OnClickScan)
    --self.WBP_HUD_PlayerHP_Item.WBP_ComBtn_Prop.Button.OnClicked:Remove(self, OnClickProp)
    self.WBP_HUD_SkillState.Place_Action_Button.WBP_ComBtn_Skill.OnClicked:Remove(self, OnClickPlace)
    self.WBP_Task.Button.OnClicked:Remove(self, OnClickTask)

    FirmUtil.UnRegMissionChanged(self,self.OnMissionChanged)

    UIManager.UINotifier:UnbindAllNotification(self)
end

---@param Usable boolean 复制器可用性
function WBP_HUD_MainInterface:SetAreaCopyerUsable(Usable)
    -- self.WBP_HUD_PlayerHP_Item.WBP_ComBtn_Scan:SetVisibility(Usable and UE.ESlateVisibility.Visible or UE.ESlateVisibility.HitTestInvisible)
    --self.Cvs_Img_Replicator:SetRenderOpacity(Usable and 1 or 0.4)
    --self.WBP_Common_PCkey_3:SetRenderOpacity(Usable and 1 or 0.4)
end

---区域能力图标
function WBP_HUD_MainInterface:SetAreaAbilityIcon(picKey)
    self.WBP_HUD_SkillState:SetAreaAbilityIcon(picKey)
end

---@param Used boolean 区域能力使用中
function WBP_HUD_MainInterface:SetAreaAbilityUsing(Used)
    -- self.WBP_HUD_PlayerHP_Item.Cvs_Prop:SetRenderOpacity(Used and 0.4 or 1)
    -- self.WBP_HUD_PlayerHP_Item.WBP_ComBtn_Prop:SetVisibility(Used and UE.ESlateVisibility.HitTestInvisible or
    -- UE.ESlateVisibility.Visible)
end

---`brief`重新绑定主界面左侧复制器按钮回调
---@param fnCB function
function WBP_HUD_MainInterface:BindCopyerBtnCB(fnCB)
    self.CopyerBtnCB = fnCB
end

---`brief`重新绑定主界面右侧区域能力按钮回调
---@param fnCB function
function WBP_HUD_MainInterface:BindAreaAbilityBtnCB(fnCB)
    self.AreaAbilityBtnCB = fnCB
end

---`brief`角色刷新回调
---@param NewCharType number 新角色
---@param OldCharType number 旧角色
---@param Index number 队伍列表索引
function WBP_HUD_MainInterface:OnSwitchPlayer(NewCharType, OldCharType,Index)
    self.WBP_HUD_SkillState:OnSwitchPlayer(NewCharType, OldCharType)
    self.WBP_HUD_SquadList:SwitchPlayer(Index)
end

---`brief`刷新技能界面
function WBP_HUD_MainInterface:RefreshSkillPanel()
    self.WBP_HUD_SkillState:TimerLoop()
end

function WBP_HUD_MainInterface:OnOpenKnapsackUIAction()
    UIManager:OpenUI(UIDef.UIInfo.UI_Knapsack_Main2)
end

function WBP_HUD_MainInterface:OnOpenMapUIAction()
    local UIFirmMap =  UIManager:OpenUI(UIDef.UIInfo.UI_FirmMap)
    UIFirmMap.WBP_Firm_Content:GetMiniMap(self.WBP_HUD_MiniMap)
    if self.MissionData then
        UIFirmMap:TransferMissionData(self.MissionData)
    end
end

function WBP_HUD_MainInterface:OpenMissionMainUI()
    local UITaskMain = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_TaskMain.UIName)
    if not UITaskMain then
        UIManager:OpenUI(UIDef.UIInfo.UI_TaskMain)
    end
end

function WBP_HUD_MainInterface:ClickMissionTrack()
    if self.WBP_HUD_Task_Track then
        self.WBP_HUD_Task_Track:ClickMissionTrack()
    end
end

---@return boolean 是否显示队伍状态
function WBP_HUD_MainInterface:IsShowTeam()
    return self.WBP_HUD_SquadList:IsShowTeam()
end

function WBP_HUD_MainInterface:OpenAreaAbility()
    local Player = G.GetPlayerCharacter(UIManager.GameWorld, 0)
    Player:SendMessage("OpenAreaAbilityPanel")
end

function WBP_HUD_MainInterface:OpenCopyAbility()
    local Player = G.GetPlayerCharacter(UIManager.GameWorld, 0)
    Player:SendMessage("OpenCopyerPanel")
end

function WBP_HUD_MainInterface:CloseAreaAbility()
    local skillUI = self.WBP_HUD_SkillState
    if skillUI.SkillState then
        if skillUI.SkillState == skillUI.SkillStateDef.Skill then
        elseif skillUI.SkillState == skillUI.SkillStateDef.Copyer then
            local Player = G.GetPlayerCharacter(UIManager.GameWorld, 0)
            Player:SendMessage("CloseCopyerPanel")
        elseif skillUI.SkillState == skillUI.SkillStateDef.AreaAbility then
            local Player = G.GetPlayerCharacter(UIManager.GameWorld, 0)
            Player:SendMessage("CloseAreaAbilityPanel")
        elseif skillUI.SkillState == skillUI.SkillStateDef.Maduk then
            if not skillUI.canExist then
                return
            end
            if skillUI.MadukCloseBtnCB then
                skillUI.MadukCloseBtnCB()
            end
            local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)
            AreaAbilityVM:CloseMadukPanel()
        end
    end
end

--显隐主界面的放置按钮
function WBP_HUD_MainInterface:ShowPlacingBtn(bShow)
    self.WBP_HUD_SkillState:ShowPlacingBtn(bShow)
end

---进入滑板状态切换
function WBP_HUD_MainInterface:VehicleStateChange(bSingle)
    self.WBP_HUD_SkillState:VehicleStateChange(bSingle)
    self.WBP_HUD_PlayerHP_Item:EnterVehicleState(true)
end

---关闭滑板ui,显示区域能力
function WBP_HUD_MainInterface:CloseVehicleUI()
    self.WBP_HUD_SkillState:CloseVehicleUI()
    self.WBP_HUD_PlayerHP_Item:EnterVehicleState(false)
end

return WBP_HUD_MainInterface
