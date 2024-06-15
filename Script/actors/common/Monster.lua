require "UnLua"

local G = require("G")
local SkillUtils = require("common.skill_utils")
local utils = require("common.utils")

local Character = require("actors.common.Character")
local monster_data = require("common.data.monster_initial_data")

local Monster = Class(Character)

Monster.__all_client_components__ = {
}

Monster.__all_server_components__ = {
    WeaponMgrServer = "actors.server.components.weapon_mgr",
    EquipComponentServer = "actors.common.components.equip_component",
    -- OutBalanceServer = "actors.server.components.monster.out_balance_component",
}

function Monster:Initialize(...)
    Super(Monster).Initialize(self, ...)

    self.bBeginPlay = false
    self.bPossessed = false
    self.bRepController = false
end

-- function Monster:UserConstructionScript()
-- end

function Monster:BP_PreInitializeComponents()
    -- attributeSet init must before component init
    if self:HasAuthority() then
        self.AbilitySystemComponent:SetIsReplicated(true)
        self.AbilitySystemComponent:SetReplicationMode(UE.EGameplayEffectReplicationMode.Mixed)
        self:InitAttributeSet()
    end

    self:PostActorConstruction()
end

function Monster:PostActorConstruction()
    -- G.log:debug("yj", "Monster:PostActorConstruction IsServer.%s IsClient.%s IsStandalone.%s", self:IsServer(), self:IsClient(), UE.UKismetSystemLibrary.IsStandalone(self))
    -- if not UE.UHiUtilsFunctionLibrary.IsWorldStartup(self) then
    --     -- 非预置的Actor
    --     self:_AddScriptComponent(false, false)
    -- end
end

function Monster:_AddScriptComponent(explicit_from_client, explicit_from_server)
    -- Script Comonent的添加遵循尽早原则
    -- 对于非预置的actor，调用_AddScriptComponent的时机为PostActorConstruction
    -- 但对于预置的actor，不能在PostActorConstruction中调用_AddScriptComponent（因为在启动阶段服务端的网络模式是Standalone，IsServer的判断是不准确的）
    -- 再加上平时测试会用到Standalone模式，所以添加以下三个时机来补充处理
    -- 1.ReceivePossessed(服务端)
    -- 2.ReceiveBeginPlay(双端)
    -- 3.OnRep_Controller(客户端)

    -- 在devin的要求下，注释了PostActorConstruction的逻辑

    -- G.log:debug("yj", "Monster:_AddScriptComponent explicit_from_client.%s, explicit_from_server.%s", explicit_from_client, explicit_from_server)
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

function Monster:_AddClientComponent()
    if self.bAddClientComponent == true then
        return
    end

    self.bAddClientComponent = true
end

function Monster:_AddServerComponent()
    if self.bAddServerComponent == true then
        return
    end
    self.bAddServerComponent = true

    self:AddScriptComponent("WeaponMgrServer", true)
    self:AddScriptComponent("EquipComponentServer", true)
    -- self:AddScriptComponent("OutBalanceServer", true)
end

function Monster:ReceiveBeginPlay()
    Super(Monster).ReceiveBeginPlay(self)

    self:_AddScriptComponent(false, false)

    self.bBeginPlay = true
    if self:IsServer() then
        self:SendMessage("OnServerMonsterReady")

        self:CheckServerReady()
    else
        self:SendMessage("OnClientMonsterReady")

        self:CheckClientReady()
    end

    -- Wait Components BeginPlay
    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.PostBeginPlay}, 0.01, false)
    self:InitWalkableSlope()    --初始化身上所有组件的WalkableSlope
end

function Monster:PostBeginPlay()
    self:SendMessage("PostBeginPlay")
end

function Monster:ReceiveTick(DeltaSeconds)
    Super(Monster).ReceiveTick(self, DeltaSeconds)

    self:SendMessage("OnReceiveTick", DeltaSeconds)

    if self.BP_ReceiveTick then
        self:BP_ReceiveTick()
    end
end

-- Run on server
function Monster:ReceivePossessed(InNewController)
    self:_AddScriptComponent(false, true)

    self.bPossessed = true
    self.CurrentController = InNewController
    self:CheckServerReady()
end

-- Check both BeginPlay and Possessed, this handle Blueprint component register in ReceiveBeginPlay not receive send message.
function Monster:CheckServerReady()
    if not self.bBeginPlay or not self.bPossessed then
        return
    end

    self:SendMessage("OnServerReady")
    self:SendMessage("PostReceivePossessed")

    if self.MonsterType == Enum.Enum_MonsterType.Boss then
        G.BossServer = self
    end
end

function Monster:OnAttributeChanged(Attribute, NewValue, OldValue, Spec)
    G.log:debug("santi", "Monster OnAttributeChanged: %s, new: %f, old: %f, IsServer: %s", Attribute.AttributeName, NewValue, OldValue, self:IsServer())
    local AttributeName = Attribute.AttributeName
    local MessageTopic = "On"..AttributeName.."Changed"
    self:SendMessage(MessageTopic, NewValue, OldValue, Attribute, Spec)
end

function Monster:K2_OnMovementModeChanged(PrevMovementMode, NewMovementMode, PreCustomMode, NewCustomMode)
    self:SendMessage("OnMovementModeChanged", PrevMovementMode, NewMovementMode, PreCustomMode, NewCustomMode)
end

-- Run on client
function Monster:BP_OnRep_Controller()
    -- Client ReceiveBeginPlay和BP_OnRep_Controller的调用时序是不固定的
    self:_AddScriptComponent(true, false)

    self.bRepController = true
    self:CheckClientReady()
end

function Monster:CheckClientReady()
    if not self.bBeginPlay or not self.bRepController then
        return
    end

    self:SendMessage("OnClientReady")

    if self.MonsterType == Enum.Enum_MonsterType.Boss then
        G.BossClient = self
    end
end

function Monster:K2_UpdateCustomMovement(DeltaTime)
    self:SendMessage("UpdateCustomMovement", DeltaTime)
end

function Monster:ClientOnRep_ActivateAbilities()
    self:SendMessage("ClientOnRep_ActivateAbilities")
end

function Monster:ReceiveDestroyed()
    -- 这里不要再SendMessage了，Destroy之后component已经收不到Message了
    if self.MonsterType == Enum.Enum_MonsterType.Boss then
        if self:IsServer() then
            G.BossServer = nil
        else
            G.BossClient = nil
        end
    end
end

function Monster:SetCollisionEnabled(NewType)
    utils.SetActorCollisionEnabled(self, NewType)
end

function Monster:GetASC()
    return self:GetAbilitySystemComponent()
end

function Monster:GetASCOwnerActor()
    return self
end

function Monster:GetCharData()
    return monster_data.data[self.CharType]
end

function Monster:Multicast_SetCollisionEnabled_RPC(NewType)
    self:SetCollisionEnabled(NewType)
end

function Monster:GetAIServerComponent()
    return self:_GetComponent("AIComp", true)
end

function Monster:GetSkillWithStandComponent(is_server)
    return self:_GetComponent("SkillWithStandComponent", is_server)
end

return RegisterActor(Monster)
