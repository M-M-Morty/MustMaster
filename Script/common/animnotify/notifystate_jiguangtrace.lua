require "UnLua"
local utils = require("common.utils")

local G = require("G")

local check_table = require("common.data.state_conflict_data")


local NotifyState_JiGuangTrace = Class()

function NotifyState_JiGuangTrace:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    if Owner:IsClient() then
    	Owner.HitEffectAttached = false
    	return true
    end

    self.FrameCount = 0

    -- local Controller = Owner:GetController()
    -- local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    -- local Target = BB:GetValueAsObject("TargetActor")
    -- local OwnerLocation = Owner:GetBoneLocation(self.StartPosBoneName)
    -- local EndLocation = Target:K2_GetActorLocation()
    -- local Rotation = UE.UKismetMathLibrary.Conv_VectorToRotator(EndLocation - OwnerLocation)
    
    local Rotation = Owner:K2_GetActorRotation()

    self.StartRotation = UE.FRotator(self.StartPitch, Rotation.Yaw, 0)

    self:CreateProjectForApplyGE(Owner)

    return true
end

function NotifyState_JiGuangTrace:Received_NotifyTick(MeshComp, Animation, DeltaTime, EventReference)
    local Owner = MeshComp:GetOwner()
    if Owner:IsClient() then
		if not Owner.HitEffectAttached then
			Owner.HitEffectAttached = self:AttachHitEffectToProjectile(MeshComp)
		else
			self:UpdateJiGuangLocation(MeshComp)
		end
    	return true
    end

    self.FrameCount = self.FrameCount + 1

    -- Follow Target
    -- local Controller = Owner:GetController()
    -- local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    -- local Target = BB:GetValueAsObject("TargetActor")
    -- local OwnerLocation = Owner:GetBoneLocation(self.StartPosBoneName)
    -- local EndLocation = Target:K2_GetActorLocation()
    -- local Rotation = UE.UKismetMathLibrary.Conv_VectorToRotator(EndLocation - OwnerLocation)
    -- self.StartRotation.Yaw = Rotation.Yaw

    local StartLocation = Owner:GetBoneLocation(self.StartPosBoneName)
    local EndLocation = UE.FVector()

    local UseBoneRotation = false
    if not UseBoneRotation then
	    local Forward = UE.UKismetMathLibrary.Conv_RotatorToVector(self.StartRotation)
		EndLocation = StartLocation + UE.UKismetMathLibrary.Normal(Forward) * self.JiGuangLength
	else
	    local BoneTransform = Owner:GetBoneTransform(self.StartPosBoneName)
		local BoneLocation, BoneRotation, _ = UE.UKismetMathLibrary.BreakTransform(BoneTransform)
		BoneRotation = BoneRotation + self.RotationOffset
		-- G.log:debug("yj", "BoneRotation.X.%s BoneRotation.Y.%s, BoneRotation.Z.%s BoneRotation.%s", BoneRotation.X, BoneRotation.Y, BoneRotation.Z, BoneRotation)

	    local Forward = UE.UKismetMathLibrary.Conv_RotatorToVector(BoneRotation)
		EndLocation = StartLocation + UE.UKismetMathLibrary.Normal(Forward) * self.JiGuangLength
	end

    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.WorldStatic)

    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(Owner)

    local HitResult = UE.FHitResult()
 	local IsHit = UE.UKismetSystemLibrary.LineTraceSingleForObjects(Owner, StartLocation, EndLocation, ObjectTypes, false, ActorsToIgnore, UE.EDrawDebugTrace.None, HitResult, true)
 	if IsHit then
		EndLocation = UE.FVector(HitResult.ImpactPoint.X, HitResult.ImpactPoint.Y, HitResult.ImpactPoint.Z)
	end

    if self.FrameCount % self.TickIntervalFrame == 0 then
		--post akevent
		if HitResult.Component and HitResult.Component:GetOwner() then
			self.ProjectileActor:SendClientMessage("OnCollideActor", HitResult.Component:GetOwner(), HitResult.ImpactPoint)
		end
		self.ProjectileActor:SendClientMessage("OnRecieveCollideUpdate", StartLocation, EndLocation, HitResult.ImpactPoint)
		
	    local HitResults = UE.TArray(UE.FHitResult)
	    self:JiGuangOverlap(Owner, StartLocation, EndLocation, HitResults)
	    -- G.log:debug("yj", "NotifyState_JiGuangTrace ExecCalcForHits %s", HitResults:Length())
	    if HitResults:Length() > 0 then
	 		self.ProjectileActor:SendMessage("ExecCalcForHits", HitResults, nil, false, false)
	    end
    end

    if not UseBoneRotation then
	 	self.StartRotation.Pitch = self.StartRotation.Pitch + self.TurnSpeed * DeltaTime
 		self.StartRotation.Pitch = math.min(0, self.StartRotation.Pitch)
 	end

 	if IsHit then
 		-- HitEffect是Attach在Sphere上面的，单独改ProjectileActor的话，Sphere的位置不变...
		self.ProjectileActor:K2_SetActorLocation(EndLocation, false, nil, true)
		self.ProjectileActor.Sphere:K2_SetWorldLocation(EndLocation, false, nil, true)
	end

    return true
end

function NotifyState_JiGuangTrace:Received_NotifyEnd(MeshComp, Animation, EventReference)
	if self.ProjectileActor and self.ProjectileActor:IsValid() then
		self.ProjectileActor:K2_DestroyActor()
	end

	if self.NiagaraComponent_L then
	    self.NiagaraComponent_L:SetAsset(nil)
	end

	if self.NiagaraComponent_R then
	    self.NiagaraComponent_R:SetAsset(nil)
	end

	return true
end

function NotifyState_JiGuangTrace:CreateProjectForApplyGE(Owner)
	if not Owner.SkillInUse then
		return
	end

	local SpawnTransform = Owner:GetTransform()
    self.ProjectileActor = UE.UGameplayStatics.BeginDeferredActorSpawnFromClass(Owner, self.ProjectileClass, SpawnTransform)
    self.ProjectileActor.Spec.CalcCountLimit = 999
    self.ProjectileActor.Spec.CalcTargetLimit = 999
    -- self.ProjectileActor.CalcFrameInterval = 999999 -- disable ExecCalcInPeriod
 	self.ProjectileActor.Spec.CalcRangeType = Enum.Enum_CalcRangeType.Rect
    self.ProjectileActor.SourceActor = Owner
    self.ProjectileActor.KnockInfo = self:ConstructEventData(false)

    UE.UGameplayStatics.FinishSpawningActor(self.ProjectileActor, SpawnTransform)

    local ASC = G.GetHiAbilitySystemComponent(Owner)
    local AbilitySpec = SkillUtils.FindAbilitySpecFromSkillID(ASC, Owner.SkillInUse)
    -- AbilitySpec.Ability:MakeEffectContainerSpecByTag(self.EventTag, AbilitySpec.Ability:GetAbilityLevel(), UE.FHiGameplayEffectContainer(), self.ProjectileActor.GameplayEffectsHandle)

	local FoundContainer = AbilitySpec.Ability.EffectContainerMap:Find(self.EventTag)
	for Idx = 1, FoundContainer.TargetGameplayEffectClasses:Length() do
		local EffectClass = FoundContainer.TargetGameplayEffectClasses:Get(Idx)
		local Level = AbilitySpec.Ability:GetAbilityLevel()
		local NewHandle = ASC:MakeOutgoingSpec(EffectClass, Level, UE.FGameplayEffectContextHandle())
		self.ProjectileActor.GameplayEffectsHandle:Add(NewHandle)
	end
end

function NotifyState_JiGuangTrace:AttachHitEffectToProjectile(MeshComp)
	if not self.ProjectileActor or not self.ProjectileActor:IsValid() then
		return false
	end

    local Owner = MeshComp:GetOwner()
    local NiagaraComponent = Owner.NiagaraSlotComponent:GetNextValidNiagaraComponent()
    NiagaraComponent:SetAsset(self.NiagaraAsset_Hit)
    NiagaraComponent:ReinitializeSystem()
    NiagaraComponent:K2_AttachToComponent(self.ProjectileActor.Sphere, "", UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepWorld)
    NiagaraComponent:K2_SetRelativeLocationAndRotation(self.LocationOffset, self.RotationOffset, false, nil, true)

 	G.log:error("yj", "NotifyState_JiGuangTrace:AttachHitEffectToProjectile Name.%s", self.ProjectileActor.Sphere:K2_GetComponentLocation())

    self.NiagaraComponent_L = Owner.NiagaraSlotComponent:GetNextValidNiagaraComponent()
    self.NiagaraComponent_L:SetAsset(self.NiagaraAsset_L)
    self.NiagaraComponent_L:ReinitializeSystem()

    self.NiagaraComponent_R = Owner.NiagaraSlotComponent:GetNextValidNiagaraComponent()
    self.NiagaraComponent_R:SetAsset(self.NiagaraAsset_R)
    self.NiagaraComponent_R:ReinitializeSystem()

    self:UpdateJiGuangLocation(MeshComp)

    return true
end

function NotifyState_JiGuangTrace:UpdateJiGuangLocation(MeshComp)
	local StartPos_L = MeshComp:GetSocketLocation(self.Socket_L)
	local StartPos_R = MeshComp:GetSocketLocation(self.Socket_R)
	local EndPos = self.ProjectileActor:K2_GetActorLocation()

	-- G.log:debug("yj", "NotifyState_JiGuangTrace:UpdateJiGuangLocation L.%s R.%s End.%s", StartPos_L, StartPos_R, EndPos)

    self.NiagaraComponent_L:SetNiagaraVariableVec3("vStartPos", StartPos_L)
    self.NiagaraComponent_L:SetNiagaraVariableVec3("vEndPos", EndPos)

    self.NiagaraComponent_R:SetNiagaraVariableVec3("vStartPos", StartPos_R)
    self.NiagaraComponent_R:SetNiagaraVariableVec3("vEndPos", EndPos)
end

function NotifyState_JiGuangTrace:JiGuangOverlap(Owner, StartLocation, EndLocation, OutHitResults)
	local Forward = UE.UKismetMathLibrary.Subtract_VectorVector(EndLocation, StartLocation)
	local ForwardWithoutZ = UE.FVector(Forward.X, Forward.Y, 0)

	local RightForward = UE.UKismetMathLibrary.Cross_VectorVector(ForwardWithoutZ, Forward)
	local UpForward = UE.UKismetMathLibrary.Cross_VectorVector(Forward, RightForward)

	local NegRightForward = UE.UKismetMathLibrary.Cross_VectorVector(Forward, ForwardWithoutZ)
	local NegUpForward = UE.UKismetMathLibrary.Cross_VectorVector(RightForward, Forward)

	local StartPoints, EndPoints = {}, {}
	StartPoints[#StartPoints+1] = StartLocation
	EndPoints[#EndPoints+1] = EndLocation

	local Length_Gap, Width_Gap = 50, 100

	local idx = 1
	while Length_Gap * (idx - 1) < self.ProjectileActor.Spec.Length / 2 do
		StartPoints[#StartPoints+1] = StartLocation + UE.UKismetMathLibrary.Normal(RightForward) * Length_Gap * idx 
		EndPoints[#EndPoints+1] 	  = EndLocation   + UE.UKismetMathLibrary.Normal(RightForward) * Length_Gap * idx 
		StartPoints[#StartPoints+1] = StartLocation + UE.UKismetMathLibrary.Normal(NegRightForward) * Length_Gap * idx 
		EndPoints[#EndPoints+1] 	  = EndLocation   + UE.UKismetMathLibrary.Normal(NegRightForward) * Length_Gap * idx 
		idx = idx + 1
	end
	
	idx = 1
	while Width_Gap * (idx - 1) < self.ProjectileActor.Spec.HalfWidth do
		StartPoints[#StartPoints+1] = StartLocation + UE.UKismetMathLibrary.Normal(UpForward) * Width_Gap * idx 
		EndPoints[#EndPoints+1] 	  = EndLocation   + UE.UKismetMathLibrary.Normal(UpForward) * Width_Gap * idx 
		StartPoints[#StartPoints+1] = StartLocation + UE.UKismetMathLibrary.Normal(NegUpForward) * Width_Gap * idx 
		EndPoints[#EndPoints+1] 	  = EndLocation   + UE.UKismetMathLibrary.Normal(NegUpForward) * Width_Gap * idx 
		idx = idx + 1
	end

	local bDebug = self.ProjectileActor.bDebug

	-- if bDebug then
	--  	UE.UKismetSystemLibrary.DrawDebugSphere(Owner:GetWorld(), StartLocation, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 60)
	-- 	UE.UKismetSystemLibrary.DrawDebugLine(Owner:GetWorld(), StartLocation1, StartLocation2, UE.FLinearColor.White, 60)
	-- 	UE.UKismetSystemLibrary.DrawDebugLine(Owner:GetWorld(), StartLocation4, StartLocation4, UE.FLinearColor.White, 60)

	--  	UE.UKismetSystemLibrary.DrawDebugSphere(Owner:GetWorld(), StartLocation1, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 60)
	--  	UE.UKismetSystemLibrary.DrawDebugSphere(Owner:GetWorld(), StartLocation2, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 60)
	--  	UE.UKismetSystemLibrary.DrawDebugSphere(Owner:GetWorld(), StartLocation3, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 60)
	--  	UE.UKismetSystemLibrary.DrawDebugSphere(Owner:GetWorld(), StartLocation4, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 60)

	--  	UE.UKismetSystemLibrary.DrawDebugSphere(Owner:GetWorld(), EndLocation, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 60)
	-- 	UE.UKismetSystemLibrary.DrawDebugLine(Owner:GetWorld(), EndLocation1, EndLocation2, UE.FLinearColor.White, 60)
	-- 	UE.UKismetSystemLibrary.DrawDebugLine(Owner:GetWorld(), EndLocation3, EndLocation4, UE.FLinearColor.White, 60)

	--  	UE.UKismetSystemLibrary.DrawDebugSphere(Owner:GetWorld(), EndLocation1, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 60)
	--  	UE.UKismetSystemLibrary.DrawDebugSphere(Owner:GetWorld(), EndLocation2, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 60)
	--  	UE.UKismetSystemLibrary.DrawDebugSphere(Owner:GetWorld(), EndLocation3, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 60)
	--  	UE.UKismetSystemLibrary.DrawDebugSphere(Owner:GetWorld(), EndLocation4, 5, 20, UE.FLinearColor(1, 0.1, 0.1, 1), 60)

	-- 	UE.UKismetSystemLibrary.DrawDebugLine(Owner:GetWorld(), StartLocation, EndLocation, UE.FLinearColor.White, 60)
	-- 	UE.UKismetSystemLibrary.DrawDebugLine(Owner:GetWorld(), StartLocation1, EndLocation1, UE.FLinearColor.White, 60)
	-- 	UE.UKismetSystemLibrary.DrawDebugLine(Owner:GetWorld(), StartLocation2, EndLocation2, UE.FLinearColor.White, 60)
	-- 	UE.UKismetSystemLibrary.DrawDebugLine(Owner:GetWorld(), StartLocation3, EndLocation3, UE.FLinearColor.White, 60)
	-- 	UE.UKismetSystemLibrary.DrawDebugLine(Owner:GetWorld(), StartLocation4, EndLocation4, UE.FLinearColor.White, 60)
	-- end

	local function _MergeHitActors(HitResults, HitActors, OutHitResults)
		for Idx = 1, HitResults:Length() do
			local HitResult = HitResults:Get(Idx)
	        local CurActor = HitResult.Component:GetOwner()
			if not HitActors:Contains(CurActor) then
				HitActors:Add(CurActor)
				OutHitResults:Add(HitResult)
			end
		end
	end

    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    -- ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
    ObjectTypes:Add(UE.EObjectTypeQuery.PhysicsBody)

    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(Owner)

    local DebugType = UE.EDrawDebugTrace.None
    if bDebug then
    	DebugType = UE.EDrawDebugTrace.ForOneFrame
    end

 	local HitActors_RepeatCheck = UE.TArray(UE.AActor)
    for idx = 1, #StartPoints do
    	local HitResult = UE.TArray(UE.FHitResult)
	 	UE.UKismetSystemLibrary.LineTraceMultiForObjects(Owner, StartPoints[idx], EndPoints[idx], ObjectTypes, false, ActorsToIgnore, DebugType, HitResult, true)
 		_MergeHitActors(HitResult, HitActors_RepeatCheck, OutHitResults)
    end
end

return NotifyState_JiGuangTrace
