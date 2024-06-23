--
-- @COMPANY GHGame
-- @AUTHOR xuminjie
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
local hero_data = require("common.data.hero_initial_data").data

---@class UISquadList : WBP_HUD_SquadList_C
---@field bShowTeam boolean

local HPLENGTH

---@type WBP_HUD_SquadList_C
local UISquadList = Class(UIWindowBase)

---@param self UISquadList
local function ShowTeamList(self, bShowTeam)
    self.bShowTeam = bShowTeam
    if bShowTeam then
        self.Cvs_SquadList:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Cvs_SquadList:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@return boolean 是否显示队伍状态
function UISquadList:IsShowTeam()
    return self.bShowTeam
end

--- 切换按钮显示状态
---@param self UISquadList
---@param bShowRanks boolean
local function SwitchButtonState(self, bShowRanks)
    self.ShowRanks = bShowRanks
    if bShowRanks then
        self.ActivateButtonIndex = 0
        ShowTeamList(self, false)
    else
        self.ActivateButtonIndex = 1
        ShowTeamList(self, true)
    end

    self.Switch_RanksPlayer_Normal:SetActiveWidgetIndex(self.ActivateButtonIndex)

    if not self:IsAnimationPlaying(self.DX_SwitchMode) then
        self:PlayAnimationForward(self.DX_SwitchMode, 1.0, true)
    end
end

--- 切换玩家的显示状态
---@param self UISquadList
---@param bToMainPlayer boolean
local function SwitchPlayerState(self, bToMainPlayer)
    local Avatar = UE.UGameplayStatics.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    if not Avatar then
        print("Error! Avatar is nil")
        return
    end

    local ControllerSwitchPlayerComponent = Avatar.PlayerState:GetPlayerController().ControllerSwitchPlayerComponent
    if bToMainPlayer then
        ControllerSwitchPlayerComponent:Server_SwitchToMainPlayer()
    else
        ControllerSwitchPlayerComponent:Server_SwitchBackFromMainPlayer()
    end
end

--- 点击角色按钮切换到队伍
function UISquadList:OnClickRoleButton()
    SwitchButtonState(self, true)
    SwitchPlayerState(self, true)
end

--- 点击队伍按钮切换到角色
function UISquadList:OnClickRanksButton()
    SwitchButtonState(self, false)
    SwitchPlayerState(self, false)
end

---@param self UISquadList
local function OnHoveredButton(self)
    self.Cvs_RanksPlayer_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.ActivateButtonIndex == 0 then
        self.Text_Role:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Text_Ranks:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Text_Role:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Text_Ranks:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---@param self UISquadList
local function OnUnhoveredButton(self)
    self.Cvs_RanksPlayer_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
end

---@param self UISquadList
---@param KeyName string
local function OnPressedKeyEvent(self, KeyName)
    if KeyName == InputDef.Keys.Five then
        if not self.ShowFirmMode then
            return
        end

        --if self.bShowRanks then
        --    OnClickRanksButton(self)
        --else
        --    OnClickRoleButton(self)
        --end
    end
end

--function UISquadList:Initialize(Initializer)
--end

--function UISquadList:PreConstruct(IsDesignTime)
--end

function UISquadList:OnConstruct()
    self.Btn_Role.OnClicked:Add(self, self.OnClickRoleButton)
    self.Btn_Role.OnHovered:Add(self, OnHoveredButton)
    self.Btn_Role.OnUnhovered:Add(self, OnUnhoveredButton)
    self.Btn_Ranks.OnClicked:Add(self, self.OnClickRanksButton)
    self.Btn_Ranks.OnHovered:Add(self, OnHoveredButton)
    self.Btn_Ranks.OnUnhovered:Add(self, OnUnhoveredButton)

    UIManager:RegisterPressedKeyDelegate(self, OnPressedKeyEvent)

    -- self.Switch_Functions:SetActiveWidgetIndex(1)
    ---@type UIWidgetField
    self.OnMaxPowerValChangedField = self:CreateUserWidgetField(self.OnMaxPowerValChanged)
    ---@type UIWidgetField
    self.OnPowerValChangedField = self:CreateUserWidgetField(self.OnPowerValChanged)

    ---@type PlayerSkillVM
    local VM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.PlayerSkillVM.UniqueName)
    ViewModelBinder:BindViewModel(self.OnMaxPowerValChangedField, VM.MaxPowerField, ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.OnPowerValChangedField, VM.PowerField, ViewModelBinder.BindWayToWidget)
    -- self:BindToAnimationFinished(self.DX_EnergyTankProgress,{self, self.AnimaEnd})
    -- self:BindToAnimationFinished(self.DX_EnergyTankProgress_R,{self, self.AnimaEnd})
end

function UISquadList:OnDestruct()
    self.Btn_Role.OnClicked:Remove(self, self.OnClickRoleButton)
    self.Btn_Role.OnHovered:Remove(self, OnHoveredButton)
    self.Btn_Role.OnUnhovered:Remove(self, OnUnhoveredButton)
    self.Btn_Ranks.OnClicked:Remove(self, self.OnClickRanksButton)
    self.Btn_Ranks.OnHovered:Remove(self, OnHoveredButton)
    self.Btn_Ranks.OnUnhovered:Remove(self, OnUnhoveredButton)

    UIManager:UnRegisterPressedKeyDelegate(self)
end

---@param bShowFirmMode boolean 是否进入事务所模式
function UISquadList:UpdateUIFirmMode(bShowFirmMode)
    self.ShowFirmMode = bShowFirmMode
    if bShowFirmMode then
        self.Switch_Functions:SetActiveWidgetIndex(0)
        OnUnhoveredButton(self)
        SwitchButtonState(self, true)
        self.Cvs_RoleAndRanks:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        ShowTeamList(self, false)
    else
        -- self.Switch_Functions:SetActiveWidgetIndex(1)
        self.Cvs_RoleAndRanks:SetVisibility(UE.ESlateVisibility.Collapsed)
        ShowTeamList(self, true)
    end
end

--- 播放界面的入场出场动画·
---@param bIn boolean 是否是界面入场动画
function UISquadList:PlayInOutAnim(bIn)
    ---@type UWidgetAnimation
    local CurAnim = bIn and self.DX_In or self.DX_Out
    self:PlayAnimation(CurAnim, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UISquadList:OnShow(Index, CurSwitchCD, actor)
    self:PlayInOutAnim(true)
    self:UpdateUIFirmMode(true)
    self.ShowFirmMode = false
    ShowTeamList(self, false)

    self.switchCD = CurSwitchCD or 5
    self.actor = actor
    local controller = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    self.teamInfo = controller.ControllerSwitchPlayerComponent.TeamInfo
    self.AvatarNum = self.teamInfo:Length()
    if self.AvatarNum == 0 then
        self:Close()
        return
    end
    if self.AvatarNum > 4 then
        G.log:debug("UISquadList", "UISquadList, characterDataList Count: %f, ", self.AvatarNum)
        return
    end

    for i = 1, 4 do
        if self.AvatarNum >= i then
            self["WBP_HUD_SquadList_Item_" .. tostring(i)]:Init(i, self.actor)
            self["WBP_HUD_SquadList_Item_" .. tostring(i)]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self["WBP_HUD_SquadList_Item_" .. tostring(i)]:NotBeSelect(false)
        else
            self["WBP_HUD_SquadList_Item_" .. tostring(i)]:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    self.curItem = self["WBP_HUD_SquadList_Item_" .. tostring(Index)]
    self.curItem:BeSelect()
    self.IsOnShow = true
end

function UISquadList:OnHide()
    self:PlayInOutAnim(false)
end

function UISquadList:Tick(MyGeometry, InDeltaTime)
    if not self.IsOnShow then
        return
    end
    for i = 1, self.AvatarNum do
        local characterData = self.teamInfo:Get(i)
        if not characterData then
            return
        end
        self["WBP_HUD_SquadList_Item_" .. tostring(i)]:SquadItemUpdate(InDeltaTime)
    end
end

function UISquadList:SwitchPlayer(Index)
    if self.AvatarNum < Index then
        G.log:debug("SwitchPlayer", "AvatarNum < Index, New: %f", Index)
        return
    end
    if Index == 0 then
        return
    end
    for i = 1, self.AvatarNum do
        local item = self["WBP_HUD_SquadList_Item_" .. tostring(i)]
        if i == Index then
            item:BeSelect()
        else
            item:NotBeSelect(true)
            if not item.isDead then
                item.durCDTime = self.switchCD
            end
        end
    end
end

function UISquadList:UpdateSuperSkillState()

end

function UISquadList:OnSquadListRoleHealthChanged(Index, CurPercent)
    if self.AvatarNum < Index then
        G.log:debug("OnSquadListRoleHealthChanged", "AvatarNum < Index, New: %f, Old: %f", Index)
        return
    end
    self["WBP_HUD_SquadList_Item_" .. tostring(Index)]:RoleHealthChanged(CurPercent)
end

function UISquadList:OnSquadListRoleDead(Index)
    if self.AvatarNum < Index then
        G.log:debug("OnSquadListRoleHealthChanged", "AvatarNum < Index, New: %f, Old: %f", Index)
        return
    end
    self["WBP_HUD_SquadList_Item_" .. tostring(Index)]:RoleDead()
end

function UISquadList:Close()
    self:CloseMyself()
end

---@private VM field的回调
function UISquadList:OnPowerValChanged(Data)
    if not self.MaxPower or not Data then
        return
    end
    if not self.Power then
        self.Power = 0
    end
    if Data < self.MaxPower then
        self:StopAnimation(self.DX_EnergyTankFull)
    end
    self:StopAnimation(self.DX_EnergyTankProgress)
    self:StopAnimation(self.DX_EnergyTankProgress_R)
    local Start = self.Power / 100
    local End = Data / 100
    G.log:debug("zys", table.concat({'power anim start ', Start, ' ', End}))
    if Start < End then
        self:PlayAnimationTimeRange(self.DX_EnergyTankProgress, Start, End, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    else
        self:PlayAnimationTimeRange(self.DX_EnergyTankProgress_R, 1 - Start, 1 - End, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    end
    self.Power = Data
end

function UISquadList:AnimaEnd()
    if self.Power >= self.MaxPower then
        self:PlayAnimation(self.DX_EnergyTankFull, 0, 0, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    else
        self:StopAnimation(self.DX_EnergyTankFull)
    end
end
    

---@private VM field的回调
function UISquadList:OnMaxPowerValChanged(Data)
    self.MaxPower = Data
end

return UISquadList
