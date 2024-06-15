local G = require("G")
local check_table = require("common.data.state_conflict_data")

local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local AirComboComponent = Component(ComponentBase)

local decorator = AirComboComponent.decorator


function AirComboComponent:Initialize(...)
    Super(AirComboComponent).Initialize(self, ...)
    self.TargetHoldEndTime = nil
end

decorator.message_receiver()
function AirComboComponent:OnGAAirTreadActivate()
	if self.actor:IsClient() then
		return
	end

	-- 空中踩踏
	self:AirTread_Begin()
end


decorator.message_receiver()
function AirComboComponent:OnGAAirEmbraceActivate()
	if self.actor:IsClient() then
		return
	end

	-- 空中抱摔
	self:AirEmbrace_Begin()
end

decorator.message_receiver()
function AirComboComponent:OnReceiveTick(DeltaSeconds)
	if self.actor:IsClient() then
		return
	end

	self:OnAirTreadTick(DeltaSeconds)

	self:OnAirEmbraceTick(DeltaSeconds)
end

function AirComboComponent:OnAirTreadTick(DeltaSeconds)
	if self.AirTreadTarget == nil then
		return
	end

	if self.actor:IsOnFloor() then
		return
	end

	local NowMs = G.GetNowTimestampMs()
	if self.TargetHoldEndTime < NowMs then
		self:AirTread_End()
	end
end

function AirComboComponent:AirTread_Begin(DeltaSeconds)
	self.AirTreadTarget = self:GetNearestTarget()
	if self.AirTreadTarget == nil then
		return
	end

	local SelfLocation = self.actor:K2_GetActorLocation()
	local SelfRotation = self.actor:K2_GetActorRotation()

	local TargetLocation = self.AirTreadTarget:K2_GetActorLocation()
	local Normal = UE.UKismetMathLibrary.Normal(UE.UKismetMathLibrary.Conv_RotatorToVector(SelfRotation))
	self.AirTreadTarget:K2_SetActorLocation(SelfLocation + Normal * 100, false, nil, true)
	local FowardWithoutZ = UE.FVector(SelfLocation.X, SelfLocation.Y, 0) - UE.FVector(TargetLocation.X, TargetLocation.Y, 0)
	self.AirTreadTarget:K2_SetActorRotation(UE.UKismetMathLibrary.Conv_VectorToRotator(FowardWithoutZ), true)

	self.ZGHandle = self.actor.ZeroGravityComponent:EnterZeroGravity(10, false)
	self.TargetZGHandle = self.AirTreadTarget.ZeroGravityComponent:EnterZeroGravity(10, false)

	self.TargetHoldEndTime = G.GetNowTimestampMs() + 100
end

function AirComboComponent:AirTread_End()
	self.actor.ZeroGravityComponent:EndZeroGravity(self.ZGHandle)
	self.AirTreadTarget.ZeroGravityComponent:EndZeroGravity(self.TargetZGHandle)

    self.actor:LaunchCharacter(UE.FVector(0, 0, 1500), true, true)
    self.AirTreadTarget:LaunchCharacter(UE.FVector(0, 0, -5000), true, true)
    self.AirTreadTarget = nil
end

function AirComboComponent:OnAirEmbraceTick()
	if self.AirEmbraceTarget == nil then
		return
	end

	if self.actor:IsOnFloor() then
		self:AirEmbrace_End()
		return
	end
end

function AirComboComponent:AirEmbrace_Begin()
	self.AirEmbraceTarget = self:GetNearestTarget()
	if self.AirEmbraceTarget == nil then
		return
	end

	local SelfLocation = self.actor:K2_GetActorLocation()
	local SelfRotation = self.actor:K2_GetActorRotation()

	local TargetLocation = self.AirEmbraceTarget:K2_GetActorLocation()
	local Normal = UE.UKismetMathLibrary.Normal(UE.UKismetMathLibrary.Conv_RotatorToVector(SelfRotation))
	self.AirEmbraceTarget:K2_SetActorLocation(SelfLocation + Normal * 100, false, nil, true)
	local FowardWithoutZ = UE.FVector(SelfLocation.X, SelfLocation.Y, 0) - UE.FVector(TargetLocation.X, TargetLocation.Y, 0)
	self.AirEmbraceTarget:K2_SetActorRotation(UE.UKismetMathLibrary.Conv_VectorToRotator(FowardWithoutZ) + UE.FRotator(0, 0, 180), true)

    self.actor:LaunchCharacter(UE.FVector(0, 0, -1200), true, true)
    self.AirEmbraceTarget:LaunchCharacter(UE.FVector(0, 0, -1800), true, true)
end

function AirComboComponent:AirEmbrace_End()	
	local TargetRotation = self.AirEmbraceTarget:K2_GetActorRotation()
    self.AirEmbraceTarget:K2_SetActorRotation(TargetRotation + UE.FRotator(0, 0, -180), true)
    self.AirEmbraceTarget = nil

    self:AirEmbrace_KnockFly()
    self.actor:Client_SendMessage("AirEmbrace_KnockFly")
end

decorator.message_receiver()
function AirComboComponent:AirEmbrace_KnockFly()
    KnockParams = {}
    KnockParams.Causer = self.actor

    local SkillKnock = nil
	AirEmbraceTarget = self:GetNearestTarget()
    if not self.actor:IsClient() then
	    SkillKnock = AirEmbraceTarget:_GetComponent("SkillKnockServer", true)
    else
	    SkillKnock = AirEmbraceTarget:_GetComponent("SkillKnock", false)
    end

    SkillKnock:BeginKnockFly(KnockParams)
    self:KnockBackOther(AirEmbraceTarget)
end

function AirComboComponent:KnockBackOther(ExcludeActor)
    local TargetActors = UE.TArray(UE.AHiCharacter)
    UE.UGameplayStatics.GetAllActorsOfClass(self.actor:GetWorld(), UE.AHiCharacter, TargetActors)

    for i = 1, TargetActors:Length() do
        local Target = TargetActors[i]
        if Target == ExcludeActor or Target == self.actor then
        	goto continue
        end

        local Dis = UE.UKismetMathLibrary.Vector_Distance(self.actor:K2_GetActorLocation(), Target:K2_GetActorLocation())
        if Dis > 500 then
        	goto continue
        end

		Target:K2_SetActorRotation(UE.UKismetMathLibrary.Conv_VectorToRotator(self.actor:K2_GetActorLocation() - Target:K2_GetActorLocation()), true)

        KnockParams = {}
        KnockParams.Causer = self.actor
        KnockParams.KnockInfo = {}
        KnockParams.KnockInfo.KnockDisScale = UE.FVector(1, 1, 1)

	    if not self.actor:IsClient() then
		    SkillKnock = Target:_GetComponent("SkillKnockServer", true)
	    else
		    SkillKnock = Target:_GetComponent("SkillKnock", false)
	    end
        SkillKnock:DoKnockBack(KnockParams)

        ::continue::
    end
end

function AirComboComponent:GetNearestTarget()
    local TargetActors = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(self.actor:GetWorld(), UE.AActor, TargetActors)

    local Ret, MinDis = nil, nil
    for i = 1, TargetActors:Length() do
        local Target = TargetActors[i]
        if Target and Target ~= self.actor and Target.CharIdentity == Enum.Enum_CharIdentity.Monster then
        	local Dis = UE.UKismetMathLibrary.Vector_Distance(self.actor:K2_GetActorLocation(), Target:K2_GetActorLocation())
        	if Dis > 500 then
        		goto continue
        	end

        	if MinDis == nil then
        		Ret, MinDis = Target, Dis
        		goto continue
        	end

        	if Dis < MinDis then
        		Ret, MinDis = Target, Dis
        	end
        end

        ::continue::
    end

    return Ret
end


return AirComboComponent
