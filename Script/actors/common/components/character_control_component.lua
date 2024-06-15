local G = require("G")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")

local CharacterControl = Component(ComponentBase)

local decorator = CharacterControl.decorator

local check_table = require("common.data.state_conflict_data")
local InputModes = require("common.event_const").InputModes

local StanceType = UE.EHiStance
local NinjaLiveClass = UE.UClass.Load("/Game/FluidNinjaLive/NinjaLive.NinjaLive_C")

function CharacterControl:Start()
    Super(CharacterControl).Start(self)
    
    if self.actor.AppearanceComponent then
	    self.actor.AppearanceComponent.OnLandDelegate:Add(self, self.OnLand)
        self.actor.AppearanceComponent.IsMovingChangedDelegate:Add(self, self.OnMoveStateChanged)
	end

    self.actor.CapsuleComponent.OnComponentHit:Add(self, self.OnComponentHit)
    ------- AirWall -----------
    self.bHitAirWall = false
    self.bAirWallToDisable = false
    self.lastAirWallPos = UE.FVector(0.0, 0.0, 0.0)
    ------- AirWall -----------

end

function CharacterControl:Stop()
    Super(CharacterControl).Stop(self)

    if self.actor.AppearanceComponent then
	    self.actor.AppearanceComponent.OnLandDelegate:Remove(self, self.OnLand)
        self.actor.AppearanceComponent.IsMovingChangedDelegate:Remove(self, self.OnMoveStateChanged)
	end

    self:SendMessage("UnRegisterInputHandler", InputModes.Normal)

    self.actor.CapsuleComponent.OnComponentHit:Remove(self, self.OnComponentHit)
end

function CharacterControl:OnComponentHit(HitComponent, OtherActor, OtherComp, NormalImpulse, Hit)
    local DisplayName = G.GetDisplayName(OtherActor)
    local AirWall_Name = "BP_AirWall" 
    if DisplayName:sub(0, AirWall_Name:len()) == AirWall_Name then
        local ImpactPoint = Hit.ImpactPoint
        local ImpactNormal = Hit.ImpactNormal
        ImpactNormal:Normalize()
        local distance = UE.UKismetMathLibrary.Vector_Distance(ImpactPoint, self.lastAirWallPos)
        if distance > 10 then
            self.bHitAirWall = false
            self.bAirWallToDisable = false
        end
        self.lastAirWallPos = UE.FVector(ImpactPoint.x, ImpactPoint.y, ImpactPoint.z)
        local World = self.actor:GetWorld()
        local Start = UE.UKismetMathLibrary.Add_VectorVector(ImpactPoint, UE.UKismetMathLibrary.Multiply_VectorVector(ImpactNormal, UE.UKismetMathLibrary.Conv_FloatToVector(100.0)))
        local End = UE.UKismetMathLibrary.Add_VectorVector(ImpactPoint, UE.UKismetMathLibrary.Multiply_VectorVector(ImpactNormal, UE.UKismetMathLibrary.Conv_FloatToVector(-1000)))
        local ActorsToIgnore = UE.TArray(UE.AActor)
        ActorsToIgnore:Add(self.actor)
        local OutHit = UE.FHitResult()
        local ReturnValue = UE.UKismetSystemLibrary.LineTraceSingle(World, Start, End, 
                UE.ETraceTypeQuery.FluidTrace, true, ActorsToIgnore, UE.EDrawDebugTrace.None, OutHit, true,
                UE.FLinearColor(1, 0, 0, 1), UE.FLinearColor(0, 1, 0, 1), 20)
        local HitActor = OutHit.HitObjectHandle.Actor
        local UV = UE.FVector2D()
        local ReturnValue = UE.UGameplayStatics.FindCollisionUV(OutHit, 0, UV)
        local NinjaLive = HitActor:Cast(NinjaLiveClass)
        if NinjaLive then
            if self.bHitAirWall then
                NinjaLive["Set Hit UV"](NinjaLive, UV)
                self.bAirWallToDisable = true
                utils.DoDelay(World, 1.0, 
                    function() 
                        if self.bAirWallToDisable then
                            NinjaLive["Set Mouse Input"](NinjaLive, false, UE.FVector2D())
                        end
                    end)
            else
                NinjaLive["Set Mouse Input"](NinjaLive, false, UV)
                NinjaLive["Set Mouse Input"](NinjaLive, true, UV)
                self.bHitAirWall = true
            end
        end
    end
end

decorator.message_receiver()
function CharacterControl:OnClientReady()
    self:SendMessage("RegisterInputHandler", InputModes.Normal, self)
end

function CharacterControl:OnMoveStateChanged(isMoving)
    --G.log:info("lizhao", "OnMoveStateChanged %s", tostring(isMoving))
    
    if not isMoving then
        self:SendMessage("EnterIdle")
    end
end

function CharacterControl:OnLand()
    --G.log:info("hycoldrain", "OnLand  %s", tostring(self.Object))
    if self.actor:IsPlayer() then
        self:SendMessage("EndState", check_table.State_InAir, true)
        self:SendMessage("EndState", check_table.State_Jump)
    end

    self:SendMessage("OnLand")
end

decorator.require_check_action(check_table.Action_Move)
function CharacterControl:MoveForward(value)
    -- G.log:debug("lizhao", "CharacterControl:MoveForward %f", value)
    self.actor.Overridden.ForwardMovementAction(self.actor, value)
end

decorator.message_receiver()
decorator.require_check_action(check_table.Action_Idle)
function CharacterControl:EnterIdle()
    --G.log:info("lizhao", "CharacterControl:EnterIdle")
end

decorator.require_check_action(check_table.Action_Move)
function CharacterControl:MoveRight(value)
     --G.log:error("lizhao", "CharacterControl:MoveRight %f", value)
    self.actor.Overridden.RightMovementAction(self.actor, value)
end

decorator.message_receiver()
function CharacterControl:SwitchFightStance()
    local GetStance = self.actor.GetDesiredStance
    local SetStance = self.actor.SetDesiredStance
    if self.actor:IsStandalone() then
        GetStance = self.actor.GetStance
        SetStance = self.actor.SetStance
    end

    local DesiredStance = GetStance(self.actor)
    if DesiredStance ~= StanceType.Fighting then
        SetStance(self.actor, StanceType.Fighting)
    elseif self.LastStance == nil then
        SetStance(self.actor, StanceType.Standing)
    else
        SetStance(self.actor, self.LastStance)
    end

    self.LastStance = DesiredStance

    --G.log:info("lizhao", "SetStance %s", tostring(self.LastStance))     
end

decorator.message_receiver()
function CharacterControl:OnHealthChanged(NewValue, OldValue)
    if NewValue <= 0.0 then
        -- TODO dead animation.
    end
end

decorator.message_receiver()
decorator.require_check_action(check_table.Action_Aiming_Mode)
function CharacterControl:StartAimingMode(AimingModeType)
    local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
    if GameState then
        GameState:CreateAimingMode(AimingModeType)
    end
end

decorator.message_receiver()
function CharacterControl:StopAimingMode(AimingModeType)
    local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
    if GameState then
        GameState:DestroyAimingMode(AimingModeType)
    end
    self:SendMessage("EndState", check_table.State_Aiming_Mode)
end

decorator.message_receiver()
function CharacterControl:BreakAimingMode(reason)
    local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
    if GameState then
        GameState:DestroyAimingMode()
    end
end

decorator.message_receiver()
decorator.require_check_action(check_table.Action_Lock_Mode)
function CharacterControl:StartLockMode()
    local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
    if GameState then
        GameState.bLockMode = true
    end
end

decorator.message_receiver()
function CharacterControl:StopLockMode()
    local GameState = UE.UGameplayStatics.GetGameState(self:GetWorld())
    if GameState then
        GameState.bLockMode = false
    end
    self:SendMessage("EndState", check_table.State_Lock_Mode)
end

return CharacterControl
