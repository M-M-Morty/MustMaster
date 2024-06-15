--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local t = require("t")
local Character = require("actors.common.Character")
local Loader = require("actors.client.AsyncLoaderManager")
local BPConst = require("common.const.blueprint_const")
local SubsystemUtils = require("common.utils.subsystem_utils")
local utils = require("common.utils")

--@class BP_PlayerCharacter
local Avatar = Class(Character)

Avatar.__all_client_components__ = {
    StateController = "actors.client.components.state_controller_component",
    WeaponMgr = "actors.client.components.weapon_mgr",
    VisibilityComponent = "actors.client.components.visibility_component",
    TrailingComponent = "actors.client.components.trailing_component",
}

Avatar.__all_server_components__ = {
    WeaponMgrServer = "actors.server.components.weapon_mgr",
    MovementComponentServer = "actors.server.components.movement_component",
}


function Avatar:Initialize(...)
    Super(Avatar).Initialize(self, ...)
    self.IsServerReceivePossessed = false
    self.IsClientReqState = false

    -- TODO handle ReceiveBeginPlay and OnRep_PlayerState execute order not ensure problem.
    self.bBeginPlay = false
    self.bPlayerState = false

    -- Use to handle switch player, avoid duplicate init.
    self.bServerInited = false
    self.bClientInited = false
end

-- function Avatar:UserConstructionScript()
-- end

--TODO 替换成IsInstance标准实现
function Avatar:IsAvatar()
    return true
end

function Avatar:BP_PreInitializeComponents()
    -- attributeSet init must before component init
    if self:HasAuthority() then
        self.AbilitySystemComponent:SetIsReplicated(true)
        self.AbilitySystemComponent:SetReplicationMode(UE.EGameplayEffectReplicationMode.Mixed)
        self:InitAttributeSet()
    end
end

function Avatar:_AddScriptComponent(explicit_from_client, explicit_from_server)
    -- G.log:debug("yj", "Avatar:_AddScriptComponent explicit_from_client.%s, explicit_from_server.%s", explicit_from_client, explicit_from_server)
    if explicit_from_client or explicit_from_server then
        if explicit_from_client then
            self:_AddClientComponent()
        end

        if explicit_from_server then
            self:_AddServerComponent()
        end

    else
        if self:IsClient() or UE.UKismetSystemLibrary.IsStandalone(self) then
            self:_AddClientComponent()
        end

        if self:IsServer() or UE.UKismetSystemLibrary.IsStandalone(self) then
            self:_AddServerComponent()
        end
    end
end

function Avatar:_AddClientComponent()
    if self.bAddClientComponent == true then
        return
    end

    self.bAddClientComponent = true

    self:AddScriptComponent("WeaponMgr", true)
    self:AddScriptComponent("VisibilityComponent", true)
    self:AddScriptComponent("TrailingComponent", false)
end

function Avatar:_AddServerComponent()
    if self.bAddServerComponent == true then
        return
    end
    
    self.bAddServerComponent = true
    self:AddScriptComponent("WeaponMgrServer", true)
    self:AddScriptComponent("MovementComponentServer", true)
    
end

function Avatar:OnBecomeAvatar()
end

function Avatar:OnBecomePlayer()
    self:AddScriptComponent("StateController", true)

    self:SendMessage("OnBecomePlayer")
end

function Avatar:OnBecomeStandalone()
    local standalone = UE.UKismetSystemLibrary.IsStandalone(self)
    G.log:info("hycoldrain", "BP_PlayerCharacter:ReceiveBeginPlay() %s ", tostring(standalone))
    if standalone then
        self:BP_OnRep_PlayerState()
    end    
end

function Avatar:OnRep_bVisibleOnServer()
    self:K2_GetRootComponent():SetVisibility(self.bVisibleOnServer, true)
    if self.bVisibleOnServer then
        self:SendMessage("InitWeaponVisibility")
    end
end

function Avatar:SetVisibility_RepNotify(Visible,PropagateToChildren)
    self:K2_GetRootComponent():SetVisibility(Visible, PropagateToChildren)
    if self:IsServer() then
        self.bVisibleOnServer=Visible
    end
end
 
function Avatar:ReceiveBeginPlay()
    Super(Avatar).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("Avatar(actor: %s, server: %s)", G.GetObjectName(self), self:IsServer())
    self:_AddScriptComponent(false, false)

    self.bBeginPlay = true
    if self:IsServer() then
        -- 服务器 Avatar (不一定是 Player) ready
        self:SendMessage("OnServerAvatarReady")

        -- 检测 Player ready
        self:CheckServerPlayerReady()
    else
        -- 客户端 Avatar (不一定是 Player) ready.
        self:SendMessage("OnClientAvatarReady")

        -- 检测 Player ready
        self:CheckClientPlayerReady()
    end

    -- Wait Components BeginPlay
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.PostBeginPlay}, 0.01, false)

    if self:IsClient() then
        if self.bSwitchPlayer then            
            self:K2_GetRootComponent():SetVisibility(false, true)
        end
        local Controller = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
        Controller:Server_OnPlayerClientCreate(self)
    end


    self:SetVisibility_RepNotify(self.bVisibleOnServer,true)


end

function Avatar:PostBeginPlay()
    self:SendMessage("PostBeginPlay")
end

function Avatar:ReceiveTick(DeltaSeconds)
    Super(Avatar).ReceiveTick(self, DeltaSeconds)

    self:SendMessage("OnReceiveTick", DeltaSeconds)

    -- FIXME(hangyuewang): MissionAvatarComponent迁移到PlayerState临时处理，CP代码修改完后删除下面代码
    if not self.MissionAvatarComponent then
        local PlayeState = UE.UGameplayStatics.GetPlayerState(G.GameInstance:GetWorld(), 0)
        if PlayeState then
            self.MissionAvatarComponent = PlayeState.MissionAvatarComponent
        end
    end

end

function Avatar:ReceiveEndPlay(ReceiveEndPlay)
    Super(Avatar).ReceiveEndPlay(self, ReceiveEndPlay)
    G.log:info("hycoldrain", "BP_PlayerCharacter:ReceiveEndPlay() %s", self:IsClient())
end

function Avatar:Client_SendMessage_RPC(MsgName)
    self:SendMessage(MsgName)
end

function Avatar:K2_UpdateCustomMovement(DeltaTime)
    self:SendMessage("UpdateCustomMovement", DeltaTime)
end

function Avatar:K2_OnMovementModeChanged(PrevMovementMode, NewMovementMode, PreCustomMode, NewCustomMode)
    --G.log:debug("Avatar", "K2_OnMovementModeChanged pre: (%d, %d), new: (%d, %d), IsServer: %s", PrevMovementMode, PreCustomMode, NewMovementMode, NewCustomMode, self:IsServer())
    self:SendMessage("OnMovementModeChanged", PrevMovementMode, NewMovementMode, PreCustomMode, NewCustomMode)
end

--run on server
function Avatar:ReceivePossessed()
    G.log:info("devin", "Avatar:ReceivePossessed() %s IsClient.%s", tostring(self), self:IsClient())

    self:_AddScriptComponent(false, true)

    local standalone = UE.UKismetSystemLibrary.IsStandalone(self)
    if standalone then
        self:OnBecomeStandalone()
    end

    self.bPossessed = true
    self:CheckServerPlayerReady()
end

-- server 端 player 同时收到 BeginPlay 和 Possess 事件后，处于 ready 状态
function Avatar:CheckServerPlayerReady()
    if not self.bBeginPlay or not self.bPossessed then
        return
    end

    G.log:debug(self.__TAG__, "OnServerReady")
    self:SendMessage("OnServerReady")

    self:RemoveCommonAttributeSet()
    self:AddCommonAttributeSet()
    if not self.bServerInited then
        self:InitCommonAttributeSet()
        self.bServerInited = true
    end

    if self.OnPossessedInBP then
        self:OnPossessedInBP()
    end

    self:SendMessage("PostReceivePossessed")

    t.OnServerAvararCreate(self)
end

-- function Avatar:M_Pressed()
    
--     G.log:info("[lz]", "press key m, for debug, %s", self)
--     function OnLoadCallback(obj)
--         G.log:info("lz", "on load callback in avatar %s", obj)
--     end
--     --Loader:AsyncLoadActor('/Game/Test/TransportBetweenMapsDemo/Loading.Loading', OnLoadCallback)
--     Loader:TestLoaderChangeActorMaterial()

-- end

--run on client
function Avatar:BP_OnRep_PlayerState()
    Super(Avatar).BP_OnRep_PlayerState(self)

    -- 换角色时，旧角色的 PlayerState 为空
    if not self.PlayerState then
        self.bPlayerState = false
        return
    end

    -- 从上一份代码翻译过来的实现
    if not self.IsClientReqState then
        self.IsClientReqState = true

        self:_AddScriptComponent(true, false)

        self.Overridden.BP_OnRep_PlayerState(self)

        self:OnBecomeAvatar()
        if self:IsPlayer() then
            self:OnBecomePlayer()
        end
    end

    self.bPlayerState = true
    self:CheckClientPlayerReady()
end

---Add common attributes from PlayerState, need duplicate add to trigger SpawnedAttributes replication from server when switch player.
function Avatar:AddCommonAttributeSet()
    local PS = self.PlayerState
    local CommonAttrs = PS.AttributeSets
    for Ind = 1, CommonAttrs:Length() do
        local AttrSet = CommonAttrs:Get(Ind)
        if AttrSet then
            G.log:debug("Avatar", "Add common attribute set: %s, IsServer: %s", G.GetObjectName(AttrSet), self:IsServer())
            self:AddAttributeSet(AttrSet)
        else
            G.log:error("Avatar", "Add common attribute set is nil.")
        end
    end
end

function Avatar:RemoveCommonAttributeSet()
    local PS = self.PlayerState
    local CommonAttrs = PS.AttributeSets
    for Ind = 1, CommonAttrs:Length() do
        local AttrSet = CommonAttrs:Get(Ind)
        AttrSet:BP_SetOwningActor(PS)
        G.log:debug("Avatar", "Remove common attribute set: %s, IsServer: %s", G.GetObjectName(AttrSet), self:IsServer())
        self:RemoveAttributeSet(AttrSet)
    end
end

---Init common attributes on PlayerState, only need init first time.
function Avatar:InitCommonAttributeSet()
    local PS = self.PlayerState
    -- Init common attributes in PlayerState when first possess.
    if not PS.bAttributeInited and PS.InitGE then
        G.log:debug("Avatar", "Init common attributes use ge: %s", G.GetObjectName(PS.InitGE))
        PS.bAttributeInited = true
        G.GetHiAbilitySystemComponent(self):BP_ApplyGameplayEffectToSelf(PS.InitGE, 0.0, nil)
    end
end

-- 客户端 player 同时收到 BeginPlay 和 PlayerState 后触发 ready 状态.
function Avatar:CheckClientPlayerReady()
    if not self.bBeginPlay or not self.bPlayerState then
        return
    end

    G.log:debug("Avatar", "OnClientReady")

    if not self.bClientInited then
        -- Write logic need avoid duplicate init when switch player.
        self.bClientInited = true

        self:SendMessage("OnClientReady")

        t.OnClientAvararCreate(self)
    end

    self:SendMessage("OnClientPlayerReady")
    self:AddCommonAttributeSet()
end

function Avatar:ClientOnRep_ActivateAbilities()
    self:SendMessage("ClientOnRep_ActivateAbilities")
end

function Avatar:SetCollisionEnabled(NewType)
    utils.SetActorCollisionEnabled(self, NewType)
end

function Avatar:SetCapsuleCollisionEnabled(NewType)
    utils.SetCapsuleCollisionEnabled(self, NewType)
end

function Avatar:SetWeaponCollisionEnabled(NewType)
    self:SendMessage("SetEquipCollisionEnabled", NewType)
end

---@param Attribute FGameplayAttribute
---@param NewValue
---@param OldValue
---@param Spec FGameplayEffectSpec source gameplay effect spec.
function Avatar:OnAttributeChanged(Attribute, NewValue, OldValue, Spec)
    G.log:debug(self.__TAG__, "OnAttributeChanged: %s, New: %f, Old: %f", Attribute.AttributeName, NewValue, OldValue)
    local AttributeName = Attribute.AttributeName
    local MessageTopic = "On"..AttributeName.."Changed"
    self:SendMessage(MessageTopic, NewValue, OldValue, Attribute, Spec)
end

function Avatar:Kick_Pressed()
    self:SendMessage("Kick_Pressed")
end

function Avatar:Rush_Pressed()
    self:SendMessage("Rush_Pressed")
end

function Avatar:Dodge_Pressed()
    self:SendMessage("Dodge_Pressed")
end

function Avatar:SwitchFight_Pressed()
    self:SendMessage("SwitchFight_Pressed")
end

function Avatar:GetCameraLocation()
    if not self.PlayerState then
        return UE.FVector(0, 0, 0)
    end

    local PlayerController = self.PlayerState:GetPlayerController()
    return PlayerController.PlayerCameraManager:GetCameraLocation()
end

function Avatar:GetCameraRotation()
    if not self.PlayerState then
        return UE.FRotator(0, 0, 0)
    end

    local PlayerController = self.PlayerState:GetPlayerController()
    return PlayerController.PlayerCameraManager:GetCameraRotation()
end

function Avatar:GetLockTarget()
    if self:IsClient() then
        local LockComponent = self.actor.SkillDriver:GetLockComponent()
        if LockComponent then
            return LockComponent:GetOwner()
        end
    else
        return self.LockTarget
    end
end

function Avatar:GetName()
    return "Avatar"
end

function Avatar:GM_ClearAllActiveStates()
    self:SendMessage("GM_ClearAllActiveStates")
end

function Avatar:GetASC()
    return self:GetAbilitySystemComponent()
end

function Avatar:GetASCOwnerActor()
    return self
end

function Avatar:SendControllerMessage(method_name, ...)
    local PlayerController = self.PlayerState:GetPlayerController()
    PlayerController:SendMessage(method_name, ...)
end

function Avatar:Multicast_SetCollisionEnabled_RPC(NewType)
    self:SetCollisionEnabled(NewType)
end

function Avatar:ReceiveMoveBlockedBy(HitResult)
    self:SendMessage("ReceiveMoveBlockedBy", HitResult)
end

function Avatar:GetSkillWithStandComponent(is_server)
    return self:_GetComponent("SkillWithStandComponent", is_server)
end

function Avatar:GetVehicleMgr()
    return self.VehicleMgr
end

function Avatar:DoConsoleCmd(Cmd)
    --G.log:warn("yj", "Avatar[%s]:DoConsoleCmd [%s] IsClient.%s", self:GetDisplayName(), Cmd, self:IsClient())

    if not self:IsClient() then
        -- 黑科技，确保在多人模式下执行server cmd时的t._ps是对的
        -- 这个黑科技在非单独DS模式下有问题，非单独DS模式下不同的client好像会对应到同一个server，导致无法设置正确的t._ps
        t.Setps(self)
    end

    -- print(p:GetDisplayName())
    -- print(ps:GetDisplayName())

    local PlayerController = self.PlayerState:GetPlayerController()
    PlayerController:LuaConsoleCommand(Cmd, true)
end

-- function Avatar:MoveForward(value)
--     G.log:debug("devin", "Avatar:MoveForward: %f", value)
-- end

--function Avatar:ReceiveEndPlay()
--end

--function Avatar:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function Avatar:ReceiveActorBeginOverlap(OtherActor)
--end

--function Avatar:ReceiveActorEndOverlap(OtherActor)
--end

return RegisterActor(Avatar)
