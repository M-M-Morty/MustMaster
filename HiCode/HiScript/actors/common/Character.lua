require "UnLua"

local G = require("G")

local character_table = require("common.data.hero_initial_data")
local SkillUtils = require("common.skill_utils")
local BPConst = require("common.const.blueprint_const")

local Actor = require("common.actor")

local Character = Class(Actor)
local MAX_FLOOR_DIS = 20
local MIN_AIR_BATTLE_DIS = 300

local TargetInterpSpeed = 0
local ActorInterpSpeed = 150

function Character:Initialize(...)
    Super(Character).Initialize(self, ...)

    self.animation_values = {}
end

function Character:InitAttributeSet()
    if self.AttributeComponent then
        local AttributeSetClasses = self.AttributeComponent.AttributeSetClasses
        for Ind = 1, AttributeSetClasses:Length() do
            local CurAttributeSet = NewObject(AttributeSetClasses:Get(Ind), self)
            self:AddAttributeSet(CurAttributeSet)
        end
    end
end

function Character:ReceiveBeginPlay()
    Super(Character).ReceiveBeginPlay(self)
    G.log:info("devin", "Character:ReceiveBeginPlay %s %s", tostring(self), tostring(self.CharType))

    -- if self.Mesh.AnimClass == nil then
    --     assert(false, string.format("%s AnimClass is nil", self:GetDisplayName()))
    -- end

    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    self.MutableActorComponent = self:GetComponentByClass(MutableActorComponentClass)
end

function Character:GetCharData()
    return character_table.data[self.CharType]
end

function Character:IsDead()
    if self.LifeTimeComponent then
        return self.LifeTimeComponent.bDead
    end
    return false
end

function Character:SetDead(bDead)
    if self.LifeTimeComponent then
        self.LifeTimeComponent.bDead = bDead
    end
end

function Character:IsGrounded()
    return self.AppearanceComponent:GetMovementState() == UE.EHiMovementState.Grounded
end

function Character:IsInAir()
    return self.AppearanceComponent:GetMovementState() == UE.EHiMovementState.InAir
end

function Character:IsMonster()
    return self.CharIdentity == Enum.Enum_CharIdentity.Monster
end

function Character:IsPlayerSide()
    return self.CharIdentity == Enum.Enum_CharIdentity.Avatar
end

function Character:SetLock(LockComponent,Enabled,LockUI)
    if Enabled then
        if LockComponent ~= self.LastLockComponent then
            G.log:debug("santi", "Lock target component: %s", G.GetDisplayName(LockComponent))
            self.LastLockComponent = LockComponent
            if LockUI then
                local LockWidget = UE.UWidgetBlueprintLibrary.Create(self,LockUI,nil)
                local ScreenPos = UE.FVector2D()
                local PlayerController = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
                UE.UWidgetLayoutLibrary.ProjectWorldLocationToWidgetPosition(PlayerController, LockComponent:K2_GetComponentLocation(), ScreenPos, false)
                LockWidget:SetPositionInViewport(ScreenPos, false)

                self.LockWidgetComponent = NewObject(UE.UWidgetComponent, self)
                self.LockWidgetComponent:SetWidget(LockWidget)
                self.LockWidgetComponent:SetWidgetSpace(UE.EWidgetSpace.Screen)
                -- Must manually register component.
                UE.UHiUtilsFunctionLibrary.RegisterComponent(self.LockWidgetComponent)
                self.LockWidgetComponent:K2_AttachToComponent(LockComponent, "", UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget)
            end
        end
    else
        if self.LockWidgetComponent then
            self.LockWidgetComponent:K2_DetachFromComponent()
            UE.UHiUtilsFunctionLibrary.DestroyComponent(self.LockWidgetComponent)
        end
        if self.LastLockComponent then
            G.log:debug("santi", "Unlock target component: %s", G.GetDisplayName(self.LastLockComponent))
            self.LastLockComponent = nil
        end
    end

    self:SendMessage("BeSelected", Enabled)
end

function Character:FindAbilitySpecHandleFromSkillID(SkillID)
    local AbilitySystemComponent = G.GetHiAbilitySystemComponent(self)
    return SkillUtils.FindAbilitySpecHandleFromSkillID(AbilitySystemComponent, SkillID)
end

function Character:TryActiveAbilityBySkillID(SkillID)
    local AbilityHandle = self:FindAbilitySpecHandleFromSkillID(SkillID)
    if AbilityHandle then
        local AbilitySystemComponent = G.GetHiAbilitySystemComponent(self)
        AbilitySystemComponent:BP_TryActivateAbilityByHandle(AbilityHandle, true)
    end
end

-- TODO Each time invoke will do trace check. Performance consumption.
-- Use Component FWalkableSlopeOverride to config whether walkable.
function Character:IsOnFloor()
    local CurrentFloor = UE.FFindFloorResult()
    self.CharacterMovement:K2_FindFloor(self:K2_GetActorLocation(), CurrentFloor)
    return CurrentFloor.bBlockingHit and CurrentFloor.bWalkableFloor and CurrentFloor.FloorDist <= MAX_FLOOR_DIS, CurrentFloor.FloorDist, CurrentFloor.HitResult
end

-- In air battle will have a more tolerant height check.
function Character:IsAirBattle()
    local CurrentFloor = UE.FFindFloorResult()
     self.CharacterMovement:K2_ComputeFloorDist(self:K2_GetActorLocation(), MIN_AIR_BATTLE_DIS, MIN_AIR_BATTLE_DIS, self.CapsuleComponent:GetScaledCapsuleRadius(), CurrentFloor)
    return not CurrentFloor.bBlockingHit or not CurrentFloor.bWalkableFloor or CurrentFloor.FloorDist > MIN_AIR_BATTLE_DIS
end

function Character:Replicated_ClearVelocityAndAcceleration()
    self:ClearVelocityAndAcceleration()
    if not self:IsStandalone() then
        self:Server_ClearVelocityAndAcceleration()
    end
end

function Character:ClearVelocityAndAcceleration()
    local CharacterMovement = self.CharacterMovement
    CharacterMovement.Acceleration = UE.FVector(0, 0, 0)
    CharacterMovement.bHasRequestedVelocity = false
    CharacterMovement.RequestedVelocity = UE.FVector(0, 0, 0)
    CharacterMovement.Velocity = UE.FVector(0, 0, 0)
    self.ControlInputVector = UE.FVector(0, 0, 0)
end

function Character:Server_ClearVelocityAndAcceleration_RPC()
    self:ClearVelocityAndAcceleration()
end

function Character:UseStateMachine()
    return self.CharIdentity == Enum.Enum_CharIdentity.Avatar
end

function Character:IsPlayerComp()
    return self.CharIdentity == Enum.Enum_CharIdentity.Avatar
end

function Character:RegisterGameplayTagCB(TagName, EventType, CbName)
    local Tag = UE.UHiGASLibrary.RequestGameplayTag(TagName)
    local AbilityAsync = UE.UAbilityAsync_WaitGameplayTagChanged.WaitGameplayTagChangedToActor(self, Tag, EventType)
    AbilityAsync.OnChanged = {self, self[CbName]}
    AbilityAsync:Activate()

    -- self.AbilityAsync is a blueprint attribute
    self.AbilityAsync:Add(AbilityAsync)

    return self.AbilityAsync:Length()
end

function Character:UnRegisterGameplayTagCB(idx)
    self.AbilityAsync[idx]:EndAction()
    self.AbilityAsync:Remove(idx)
end

function Character:HasTenacity()
    local CurrentTenacity = self:GetTenacityCurrentValue()
    return CurrentTenacity > 0
end

function Character:GetTenacityCurrentValue()
    local ASC = G.GetHiAbilitySystemComponent(self)
    local TenacityAttr = ASC:FindAttributeByName(SkillUtils.AttrNames.Tenacity)
    local AttributeSet = ASC:GetAttributeSet(TenacityAttr.AttributeOwner)
    return AttributeSet.Tenacity.CurrentValue
end

function Character:GetHealthCurrentValue()
    local ASC = G.GetHiAbilitySystemComponent(self)
    local HealthAttr = ASC:FindAttributeByName(SkillUtils.AttrNames.Health)
    local AttributeSet = ASC:GetAttributeSet(HealthAttr.AttributeOwner)
    return AttributeSet.Health.CurrentValue
end

function Character:GetMaxHealthCurrentValue()
    local ASC = G.GetHiAbilitySystemComponent(self)
    local MaxHealthAttr = ASC:FindAttributeByName(SkillUtils.AttrNames.MaxHealth)
    local AttributeSet = ASC:GetAttributeSet(MaxHealthAttr.AttributeOwner)
    return AttributeSet.MaxHealth.CurrentValue
end

function Character:GetSuperPowerCurrentValue()
    local ASC = G.GetHiAbilitySystemComponent(self)
    local SuperPowerAttr = ASC:FindAttributeByName(SkillUtils.AttrNames.SuperPower)
    local AttributeSet = ASC:GetAttributeSet(SuperPowerAttr.AttributeOwner)
    return AttributeSet.SuperPower.CurrentValue
end

function Character:GetMaxSuperPowerCurrentValue()
    local ASC = G.GetHiAbilitySystemComponent(self)
    local MaxSuperPowerAttr = ASC:FindAttributeByName(SkillUtils.AttrNames.MaxSuperPower)
    local AttributeSet = ASC:GetAttributeSet(MaxSuperPowerAttr.AttributeOwner)
    return AttributeSet.MaxSuperPower.CurrentValue
end

function Character:GetAnimationVariable(VariableName)
    return self.animation_values[VariableName]
end

function Character:SetAnimationVariable(VariableName, value)
    self.animation_values[VariableName] = value
end

function Character:ResetPose(bSmooth)
    G.log:debug("Character", "Reset pose to zero pitch and roll")
    local CurRotation = self:K2_GetActorRotation()
    if UE.UKismetMathLibrary.NearlyEqual_FloatFloat(CurRotation.Pitch, 0) and UE.UKismetMathLibrary.NearlyEqual_FloatFloat(CurRotation.Roll, 0) then
        return
    end
    CurRotation.Pitch = 0
    CurRotation.Roll = 0

    local CustomSmoothContext = UE.FCustomSmoothContext()
    CustomSmoothContext.TargetInterpSpeed = TargetInterpSpeed
    CustomSmoothContext.ActorInterpSpeed = ActorInterpSpeed

    self:GetLocomotionComponent():SetCharacterRotation(CurRotation, bSmooth, CustomSmoothContext)
    self:GetLocomotionComponent():Server_SetCharacterRotation(CurRotation, bSmooth, CustomSmoothContext)
end

--初始化身上所有组件的WalkableSlope,设置为不可行走表面
function Character:InitWalkableSlope()
    local CapsuleComp = self.CapsuleComponent
    if not CapsuleComp then return end
    local Comps = UE.TArray(UE.USceneComponent)
    UE.USceneComponent.GetChildrenComponents(CapsuleComp,true,Comps)
    Comps:AddUnique(CapsuleComp)
    for idx = 1, Comps:Length() do
        local Comp = Comps:Get(idx)
        if Comp:Cast(UE.UPrimitiveComponent) then
            local WalkableSlopeOverride = UE.FWalkableSlopeOverride()
            WalkableSlopeOverride.WalkableSlopeBehavior = UE.EWalkableSlopeBehavior.WalkableSlope_Unwalkable
            UE.UPrimitiveComponent.SetWalkableSlopeOverride(Comp,WalkableSlopeOverride)
        end
    end
end

function Character:Broadcast_Message(Message)
    self:SendMessage(Message)
end

function Character:Destroy()
    Super(Character).Destroy(self)
    
    --for i = 1, self.AbilityAsync:Length() do
    --    self.AbilityAsync[i]:EndAction()
    --end        
end

return Character
