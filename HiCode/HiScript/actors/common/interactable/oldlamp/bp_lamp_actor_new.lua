--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BP_LampActor_C

require "UnLua"
local G = require("G")
local GameState = require("common.gameframework.game_state.default")
local AimingMode = require("aiming_mode.AimingMode")
local utils = require("common.utils")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local BPConst = require("common.const.blueprint_const")
local InputModes = require("common.event_const").InputModes
local ActorBase = require("actors.common.interactable.base.interacted_item")
local ConstTextTable = require("common.data.const_text_data").data
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local M = Class(ActorBase)

local MADUKE_INPUT_TAG = "MADUKE_INPUT_TAG"

function M:Server_ReceiveDamage(PlayerActor, Damage, InteractLocation, bAttack)
    self.bPlayerStartAimingMode = not self.bPlayerStartAimingMode
    self.Overridden.Server_ReceiveDamage(self, PlayerActor, Damage, InteractLocation, bAttack)
end

function M:GetUIShowActors()
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    local bNotOk = false
    if Player then
        if Player.BattleStateComponent and Player.BattleStateComponent.InBattle then
            self.sUIPick = ConstTextTable.INTERACTION_INVALID_INBATTLE.Content
            self.bUseable = false
            bNotOk = true
        elseif Player.Vehicle ~= nil then
            --self.sUIPick = ConstTextTable.INTERACTION_INVALID_INVEHICLE.Content
            self.bUseable = false
            bNotOk = true
        end
    end

    if not bNotOk then
        self.sUIPick = ConstTextTable.INTERACTION_OPEN.Content
        self.bUseable = true
    end
    return {self}
end

---@param InvokerActor AActor
function M:DoClientInteractAction(InvokerActor)
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)

    if self.bStopAnimMode == nil then
        local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
        if GameState then
            if not GameState:PlayerStartAimingMode(Enum.E_AimingModeType.MaduKe) then
                return
            end
        end
    end
    self.bStopAnimMode = nil

    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    local InputComponent = Player:_GetComponent("BP_InputComponent", false)
    if InputComponent then
        local function LeftMouseClick(InputHandler, value)
            self:LogInfo("zsf", "LeftMouseClick %s %s %s", self.HitActorLocation, InputHandler, value)
            self.bClicking = value
            self:Event_PlayEffect(value)
            if value then
                AreaAbilityVM:SetCanExist(false)
                if self.HitActorLocation then
                    self:SetNextEffect(self.HitActorLocation)
                    self.NS_Next:SetActive(true, false);
                    self.NS_Next:SetHiddenInGame(false)
                end
            else
                AreaAbilityVM:SetCanExist(true)
                self.NS_Next:SetActive(false, false);
                self.NS_Next:SetHiddenInGame(true)
            end
            self:SendClientMessage("OnSwitchActivateState", value)
        end
        InputComponent:RegisterInputHandler(InputModes.Maduke, {Attack=LeftMouseClick})
    end
    Super(M).DoClientInteractAction(self, InvokerActor)
end

function M:OnRep_bPlayerStartAimingMode()
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)

    if not self:HasAuthority() and self.bPlayerStartAimingMode then
        local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
        if GameState then
            HiAudioFunctionLibrary.PlayAKAudio("Scn_Itm_Laser_Activate", self)
            local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
            if Player then
                Player:SendMessage("EnableAreaAbility", false)
                Player:SetActorHiddenInGame(true)
                AreaAbilityVM:SetCanExist(true)
            end
            local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
            local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
            local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)

            local function StopAimingMode()
                if not self:HasAuthority() then
                    local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
                    if GameState then
                        GameState:PlayerStopAimingMode()
                        HiAudioFunctionLibrary.PlayAKAudio("Scn_Itm_Laser_Down", self)
                        Player:SendMessage("EnableAreaAbility", true)
                        self:SetInteractable(Enum.E_InteractedItemStatus.Interactable)
                        local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
                        if Player then
                            Player:SetActorHiddenInGame(false)
                            AreaAbilityVM:CloseMadukPanel()
                            self.bStopAnimMode = true
                            self:DoClientInteractAction(Player)
                            local InputComponent = Player:_GetComponent("BP_InputComponent", false)
                            if InputComponent then
                                InputComponent:UnRegisterInputHandler(InputModes.Maduke)
                            end
                            local PlayerController = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
                            if PlayerController then
                                PlayerController:SendMessage("UnregisterIMC", MADUKE_INPUT_TAG)
                                --UIManager:RecoverShowAllHUD()
                            end
                        end
                    end
                    --self:SetInteractable(Enum.E_InteractedItemStatus.Interactable)
                end
            end
            AreaAbilityVM:OpenMadukPanel(nil, StopAimingMode)
            local PlayerController = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
            if PlayerController then
                --PlayerController:SendMessage("RegisterIMC", MADUKE_INPUT_TAG, {"",}, {"Default"})
                PlayerController:SendMessage("RegisterIMC", MADUKE_INPUT_TAG, {"AreaAbility",}, {""})
                --UIManager:HideAllHUD()
            end

            self:SetInteractable(Enum.E_InteractedItemStatus.UnInteractable)
            local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
            self:OnEndOverlap(nil, Player, nil, nil)
        end
    end
end

function M:ReceiveDamageOnMulticast(PlayerActor, InteractLocation, bAttack)
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    PlayerActor:SendMessage("BreakSkill")
    if self.bPlayerStartAimingMode then
        PlayerActor:SendMessage("OnBeginNoHit", self)
    else
        PlayerActor:SendMessage("OnEndNoHit", self)
    end
    if self:HasAuthority() then
        local MissionComponentClass = BPConst.GetMissionComponentClass()
        local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
        local MissionComponent = PlayerController:GetComponentByClass(MissionComponentClass)
        if MissionComponent ~= nil then
            local PlayerHolderLocation = self.PlayerHolder:K2_GetComponentLocation()
            local ActorRotation = Player:K2_GetActorRotation()
            MissionComponent:TeleportPlayer(PlayerHolderLocation, ActorRotation)
        end
        self:Event_Lighting()
    end
end

function M:Event_Lighting()
    self.NSLightState = true
    self.NSLightingActive = true
    self.delayLightOn = 0.68
    self.swingExpire = 99999
    --self:SetInteractable(Enum.E_InteractedItemStatus.UnInteractable)
end

function M:OnRep_NSLightState()
    --self:Event_PlayEffect(self.NSLightState)
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    self.ignoreEditorID = {}
end

function M:Destructible()
end

function M:DoAttack()
    if not self.bClicking then
        self.NS_BeAttack_Low:SetActive(false, false)
        self.NS_BeAttack:SetActive(false, false)
        return
    end
    local E_AttackTarget = {
        NONE=0,
        OTHER=1,
        MADUKE=2,
    }
    local vEndPos = self.vEndPos
    if not self.curItem then
        self.HitActorLocation = vEndPos
        self.AttackTarget = E_AttackTarget.NONE
    else
        if not self.curItem then
            self.HitActorLocation = vEndPos
            self.AttackTarget = E_AttackTarget.NONE
        else
            local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint,
                Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName,
                HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(self.curItem)
            if HitActor then
                self.HitActorLocation = Location
                if HitActor.bMaduke then
                    self.AttackTarget = E_AttackTarget.MADUKE
                    -- 告诉server， 那里受击了
                    local localPlayerActor = G.GetPlayerCharacter(self, 0)
                    if localPlayerActor and HitActor.DoClientInteractActionWithLocation then
                        --self:LogInfo("zsf", "%s %s", localPlayerActor, self.HitActorLocation)
                       HitActor:DoClientInteractActionWithLocation(localPlayerActor, 1.0, self.HitActorLocation)
                    end
                else
                    self.AttackTarget = E_AttackTarget.OTHER
                end
            else
                self.AttackTarget = E_AttackTarget.NONE
                self.HitActorLocation = vEndPos
            end
            self:SendClientMessage("OnCollideActor", HitActor, self.HitActorLocation)
        end
    end
    if not self.HitActorLocation then
       return
    end
    self.NS_Next:SetActive(true, false);
    self.NS_Next:SetHiddenInGame(false)
    self.NS_Next:SetVariablePosition('vEndPos', self.HitActorLocation);
    local HitResult = UE.FHitResult()
    if self.bClicking then
        if self.AttackTarget == E_AttackTarget.OTHER or self.AttackTarget == E_AttackTarget.NONE then
            self.NS_BeAttack_Low:K2_SetWorldLocation(self.HitActorLocation, false, HitResult, false)
            self.NS_BeAttack_Low:SetActive(true, false)
            self.NS_BeAttack:SetActive(false, false)
        else
            self:Destructible()
            self.NS_BeAttack_Low:SetActive(false, false)
            self.NS_BeAttack:K2_SetWorldLocation(self.HitActorLocation, false, HitResult, false)
            self.NS_BeAttack:SetActive(true, false)
        end
    end
end

function M:DoLineTrace()
    -- 做下射线检测
    if self:HasAuthority() then
        return
    end
    --if not self.bClicking then
    --    self:SetMadukLampWidget(nil, nil, nil)
    --    return
    --end
    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    if not CameraManager then
        return
    end
    local StartLocation = CameraManager:GetCameraLocation()
    local ForwardVector = CameraManager.TransformComponent:GetForwardVector()
    local EndLocation = UE.UKismetMathLibrary.Multiply_VectorFloat(ForwardVector, self.fAttackLen) + StartLocation

    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.WorldStatic)
    ObjectTypes:Add(UE.EObjectTypeQuery.Destructible)
    ObjectTypes:Add(UE.EObjectTypeQuery.WorldDynamic)
    ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(self)
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    ActorsToIgnore:Add(Player)
    local tbAttachedActors = Player:GetAttachedActors()
    for Ind=1,tbAttachedActors:Length() do
        local AttachedActor = tbAttachedActors:Get(Ind)
        ActorsToIgnore:Add(AttachedActor)
    end
    if self.ignoreEditorID then
        for _,EditorId in ipairs(self.ignoreEditorID) do
            local Actor = self:GetEditorActor(EditorId)
            if Actor then
                ActorsToIgnore:Add(Actor)
            end
        end
    end
    local HitResult = UE.FHitResult()
    local IsHit = UE.UKismetSystemLibrary.LineTraceSingleForObjects(self:GetWorld(), StartLocation, EndLocation, ObjectTypes, false, ActorsToIgnore, UE.EDrawDebugTrace.None, HitResult, true)
    if IsHit then
        local bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint,
                Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, BoneName,
                HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd = UE.UGameplayStatics.BreakHitResult(HitResult)
        -- 未点击时; 有个瞄准红色的状态
        self:SetMadukLampWidget(HitResult, HitActor, EndLocation)
        if HitActor.GetEditorID then
            local EditorID = HitActor:GetEditorID()
            if EditorID then
                EditorID = tostring(EditorID)
                local PreEditorID = EditorID:sub(1,5)
                local black_list = {20000, 20055}
                for _,ID in ipairs(black_list) do
                    if tostring(ID) == PreEditorID then
                        table.insert(self.ignoreEditorID, EditorID)
                    end
                end
            end
        end
    else
        self:SetMadukLampWidget(HitResult, nil, EndLocation)
    end
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)

    if self.bClicking then
        AreaAbilityVM:EnterMadukLampFocusState()
    else
        AreaAbilityVM:EnterMadukLampUnFocusState()
    end
    self:SendClientMessage("OnRecieveCollideUpdate", StartLocation, EndLocation, HitResult.ImpactPoint)
end

function M:SetMadukLampWidget(HitResult, HitActor, EndLocation)
    self.curItem = HitResult
    self.vEndPos = EndLocation
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local AreaAbilityVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.AreaAbilityVM.UniqueName)

    if HitActor and HitActor.bMaduke then
        AreaAbilityVM:EnterMadukLampAimState()
    else
        AreaAbilityVM:EnterMadukLampNomalState()
    end
end

function M:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    self:Client_RemoveInitationScreenUI()
    Super(M).OnBeginOverlap(self, OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
end

function M:ReceiveTick(DeltaSeconds)
    if not self.bPlayerStartAimingMode then
        return
    end
    self:DoLineTrace()
    Super(M).ReceiveTick(self, DeltaSeconds)
    if self:HasAuthority() then
        return
    end
    self:DoAttack()
end

return M
