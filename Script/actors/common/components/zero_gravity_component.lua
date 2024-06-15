require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local utils = require("common.utils")
local check_table = require("common.data.state_conflict_data")

local ZGComponent = Component(ComponentBase)
local decorator = ZGComponent.decorator

local InvalidHandle = -1

function ZGComponent:Initialize(...)
    Super(ZGComponent).Initialize(self, ...)
end

function ZGComponent:Start()
    Super(ZGComponent).Start(self)

    self.CharacterMovement = self.actor.CharacterMovement

    -- Continue zero gravity count by hit.
    self.OnHitContinueZGCount = 0
    self.LastOnHitZGTime = nil

    self.bJumpInAir = false
    self.bDelayEndZeroGravity = false

    self.IDGenerator = utils.IDGenerator()
    self.CurHandle = InvalidHandle
end

function ZGComponent:ReceiveBeginPlay()
    Super(ZGComponent).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("ZGComponent(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
end

function ZGComponent:Stop()
    Super(ZGComponent).Stop(self)
end

---EnterZeroGravity invoke must respect below rules:
---     1. for autonomous player, invoke on client.
---     2. for server controlled actor, invoke on server.
---Set actor enter zero gravity with specified time seconds, replicated.
---@param ZeroGravityTime number
---@param bOnHit boolean whether triggered by hit
---@param bIgnoreState boolean whether skip set state
---@return number Handle use to end zero gravity
decorator.message_receiver()
function ZGComponent:EnterZeroGravity(ZeroGravityTime, bOnHit, bIgnoreState)
    local Handle = InvalidHandle
    if not self.actor:HasCalcAuthority() then
        G.log:error(self.__TAG__, "Has no authority for invoke EnterZeroGravity")
        return Handle
    end

    Handle = self:TryEnterZeroGravity(ZeroGravityTime, bOnHit)
    if Handle == InvalidHandle then
        return Handle
    end

    -- If autonomous player, notify server.
    if self.actor:IsPlayerNotStandalone() then
        self:Server_EnterZeroGravity(ZeroGravityTime, bOnHit, Handle, bIgnoreState)
        self:OnEnterZeroGravity(ZeroGravityTime, bOnHit, Handle, bIgnoreState)
        return Handle
    end

    -- Server controlled actor (monster .etc.)
    if self.actor:IsServer() then
        self:Multicast_OnEnterZeroGravity(ZeroGravityTime, bOnHit, Handle, bIgnoreState)
    end

    return Handle
end

-- Main logic for check can enter zero gravity, and assign handle.
function ZGComponent:TryEnterZeroGravity(ZeroGravityTime, bOnHit)
    if bOnHit then
        if self:ExceedMaxContinueZGCount() then
            G.log:debug(self.__TAG__, "Reach max continue zg count, can not enter zero gravity.")
            return InvalidHandle
        end

        self:TryContinueOnHitZG()
    else
        self:ResetOnHitContinueZG()
    end

    if self.ZGTimer then
        self.actor:ClearAndInvalidateTimerHandle(self, self.ZGTimer)
    end
    if ZeroGravityTime > 0 then
        self.ZGTimer = self.actor:SetTimerDelegate({self, self.EndCurrentZeroGravity}, ZeroGravityTime, false)
        G.log:debug(self.__TAG__, "Enter zero gravity time: %f", ZeroGravityTime)
    else
        self:EndCurrentZeroGravity();
        G.log:debug(self.__TAG__, "Enter zero gravity without time limit, should manual invoke end.")
    end

    local Handle = self.IDGenerator()
    return Handle
end

function ZGComponent:Server_EnterZeroGravity_RPC(ZeroGravityTime, bOnHit, Handle, bIgnoreState)
    self:Multicast_OnEnterZeroGravity(ZeroGravityTime, bOnHit, Handle, bIgnoreState)
end

function ZGComponent:Multicast_OnEnterZeroGravity_RPC(ZeroGravityTime, bOnHit, Handle, bIgnoreState)
    if self.actor:IsPlayerNotStandalone() then
        return
    end

    self:OnEnterZeroGravity(ZeroGravityTime, bOnHit, Handle, bIgnoreState)
end

function ZGComponent:OnEnterZeroGravity(ZeroGravityTime, bOnHit, Handle, bIgnoreState)
    G.log:debug(self.__TAG__, "OnEnterZeroGravity time: %f, bOnHit: %s, Handle: %d", ZeroGravityTime, bOnHit, Handle)
    self.bOnHit = bOnHit
    self.actor:ClearVelocityAndAcceleration()
    -- TODO currently use MOVE_Flying for zero gravity. May be need change to MOVE_Falling when implement fly logic in future.
    -- Attention JumpInAir depends on this state.
    self.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Flying)
    self.bZeroGravity = true
    self.CurHandle = Handle

    if not bIgnoreState then
        self:SetZeroGravityState(true)
    end
end

---EndZeroGravity invoke must respect below rules:
-----     1. for autonomous player, invoke on client.
-----     2. for server controlled actor, invoke on server.
---@param Handle number
decorator.message_receiver()
function ZGComponent:EndZeroGravity(Handle)
    if not self.actor:HasCalcAuthority() then
        G.log:error(self.__TAG__, "Has no authority for invoke EndZeroGravity")
        return
    end

    if self.CurHandle == InvalidHandle or self.CurHandle ~= Handle then
        return
    end

    if self.actor:IsPlayerNotStandalone() then
        self:OnEndZeroGravity()
        self:Server_EndZeroGravity(Handle)
        return
    end

    if self.actor:IsServer() then
        self:Server_EndZeroGravity(Handle)
        return
    end
end

---EndZeroGravity invoke must respect below rules:
-----     1. for autonomous player, invoke on client.
-----     2. for server controlled actor, invoke on server.
decorator.message_receiver()
function ZGComponent:EndCurrentZeroGravity()
    self:EndZeroGravity(self.CurHandle)
end

function ZGComponent:Server_EndZeroGravity_RPC(Handle)
    self:Multicast_OnEndZeroGravity()
end

function ZGComponent:Multicast_OnEndZeroGravity_RPC()
    if self.actor:IsPlayerNotStandalone() then
        return
    end

    if self.ZGTimer then
        self.actor:ClearAndInvalidateTimerHandle(self.actor, self.ZGTimer)
        self.ZGTimer = nil
    end

    self:OnEndZeroGravity()
end

function ZGComponent:OnEndZeroGravity()
    self.bZeroGravity = false

    if not self.bJumpInAir then
        if self.actor:IsOnFloor() then
            self.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
        else
            self:SendMessage("OnEndZeroGravity")
            self.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
        end
    else
        self.bDelayEndZeroGravity = true
    end

    G.log:debug(self.__TAG__, "OnEndZeroGravity, Handle: %d", self.CurHandle)

    self:SetZeroGravityState(false)
    self.CurHandle = InvalidHandle
end

decorator.message_receiver()
function ZGComponent:BreakZeroGravityAttack(reason)
    self:EndZeroGravity()
end

function ZGComponent:ResetOnHitContinueZG()
    self.OnHitContinueZGCount = 0
    self.LastOnHitZGTime = nil
end

-- Try continue zero gravity by on hit.
function ZGComponent:TryContinueOnHitZG()
    local Now = UE.UKismetMathLibrary.Now()
    if not self.LastOnHitZGTime
            or utils.GetSecondsElapsed(self.LastOnHitZGTime, Now) > self.ContinueTimeInterval then
        self.OnHitContinueZGCount = 1
        self.LastOnHitZGTime = Now
    else
        self.OnHitContinueZGCount = self.OnHitContinueZGCount + 1
        self.LastOnHitZGTime = Now
    end

    if self:ExceedMaxContinueZGCount() then
        G.log:debug(self.__TAG__, "Actor: %s enter hit falling.", G.GetObjectName(self.actor))
        self:SetHitFalling(true)
    end
end

function ZGComponent:ExceedMaxContinueZGCount()
    local bExceed = self.ContinueMaxCount > 0 and self.OnHitContinueZGCount >= self.ContinueMaxCount
    if bExceed then
        G.log:debug(self.__TAG__, "ExceedMaxContinueZGCount current: %d, max: %d", self.OnHitContinueZGCount, self.ContinueMaxCount)
    end

    return bExceed
end

decorator.message_receiver()
function ZGComponent:OnLand()
    if self.actor:IsServer() then
        self:ResetOnHitContinueZG()
        if not self.actor.bHitFalling then
            return
        end

        self:SetHitFalling(false)
    end
end

decorator.message_receiver()
function ZGComponent:OnBeginJumpInAir()
    self.bJumpInAir = true
end

decorator.message_receiver()
function ZGComponent:OnEndJumpInAir()
    self.bJumpInAir = false
    if self.bDelayEndZeroGravity and self.CharacterMovement.MovementMode ~= UE.EMovementMode.MOVE_Custom then
        if self.actor:IsOnFloor() then
            self.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
        else
            self.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
        end
    end
end

function ZGComponent:SetZeroGravityState(bZeroGravity)
    if self.actor:IsPlayer() then
        self.actor.CharacterStateManager.ZeroGravity = bZeroGravity
    end

    if self.actor:UseStateMachine() then
        if self.bOnHit then
            if bZeroGravity then
                self:SendMessage("EnterState", check_table.State_HitZeroGravity)
            else
                self:SendMessage("EndState", check_table.State_HitZeroGravity)
            end
        else
            if bZeroGravity then
                self:SendMessage("EnterState", check_table.State_AttackZeroGravity)
            else
                self:SendMessage("EndState", check_table.State_AttackZeroGravity)
            end
        end
    else
        self:SendMessage("OnZeroGravity", bZeroGravity)
    end
end

function ZGComponent:SetHitFalling(bHitFalling)
    self:OnHitFalling(bHitFalling)

    if not self.actor:IsStandalone() then
        self:Client_OnHitFalling(bHitFalling)
    end
end

function ZGComponent:Client_OnHitFalling_RPC(bHitFalling)
    self:OnHitFalling(bHitFalling)
end

function ZGComponent:OnHitFalling(bHitFalling)
    G.log:debug(self.__TAG__, "OnHitFalling: %s", bHitFalling)
    self.actor.bHitFalling = bHitFalling

    if self.actor:UseStateMachine() then
        if bHitFalling then
            self:SendMessage("EnterState", check_table.State_HitFalling)
        else
            self:SendMessage("EndState", check_table.State_HitFalling)
        end
    else
        self:SendMessage("OnHitFalling", bHitFalling)
    end
end

function ZGComponent:IsInZeroGravity()
    return self.bZeroGravity
end

return ZGComponent
