local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local G = require("G")
local check_table = require("common.data.state_conflict_data")

local AimComponent = Component(ComponentBase)

local decorator = AimComponent.decorator

decorator.message_receiver()
function AimComponent:PostBeginPlay()
    if self.AimGA then
        self.actor.SkillComponent:GiveAbility(self.AimGA, 0)
    end
end

function AimComponent:EnterOrLeaveAimMode(AimMontage)
	-- Call from Mahonin BP
	if not self.actor:IsClient() then
		return
	end

	if self.actor.AppearanceComponent:GetRotationMode() ~= UE.EHiRotationMode.Aiming then
		self.actor.AppearanceComponent:AimAction(true)
		-- self.actor:PlayAnimMontage(AimMontage)
		self:SendMessage("CreateReticleActor", self.ReticleClass)
		self:SendMessage("EnterState", check_table.State_Aim)
	else
		self.actor.AppearanceComponent:AimAction(false)
		-- self.actor:Replicated_StopAnimMontage()
		self:SendMessage("DestroyReticleActor")
		self:SendMessage("EndState", check_table.State_Aim)
	end
end

decorator.message_receiver()
function AimComponent:CreateReticleActor(ReticleClass)
	if not self.actor:IsClient() then
		return
	end

    if self.actor:IsClient() and not self.ReticleActor and ReticleClass then
	    self.ReticleActor = self.actor:GetWorld():SpawnActor(ReticleClass, self.actor:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self, self)
	end
end

decorator.message_receiver()
function AimComponent:DestroyReticleActor()
	if not self.actor:IsClient() then
		return
	end

    if self.ReticleActor then
	    self.ReticleActor.Widget.Widget:RemoveFromViewport()
		self.ReticleActor:K2_DestroyActor()
		self.ReticleActor = nil
    end
end

decorator.message_receiver()
function AimComponent:OnReceiveTick(DeltaSeconds)
	if not self.actor:IsClient() or not self.actor:IsPlayer() then
		return
	end

	if self:InAimState() then
		-- Run on Client
		local CameraRotation = self.actor:GetCameraRotation()
		self.actor.AppearanceComponent:SmoothActorRotation(CameraRotation, 200, 0, DeltaSeconds)

		self:UpdateReticleActorLocation()
	end

	-- local NowMs = G.GetNowTimestampMs()
	-- if self.bNeedSyncCamera and (self.LastSyncMs == nil or NowMs - self.LastSyncMs > self.SyncFrequency * 1000) then
	-- 	-- G.log:debug("yj", "AimComponent:ReceiveTick bNeedSyncCamera")
 --    	self:SendMessage("SyncCameraLocationAndRotationToServer")
	-- 	self.LastSyncMs = NowMs
	-- end
end

-- decorator.message_receiver()
-- function AimComponent:StartSyncCameraInfoToServer()
-- 	self.bNeedSyncCamera = true
-- end

-- decorator.message_receiver()
-- function AimComponent:EndSyncCameraInfoToServer()
-- 	self.bNeedSyncCamera = false
-- end

function AimComponent:UpdateReticleActorLocation()
	if not self.ReticleActor then
		return
	end

    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(self.actor)

    local OriginLocation = UE.UKismetMathLibrary.TransformLocation(self.actor:GetTransform(), UE.FVector(50, 0, 50))  -- 右肩向前80cm的位置，差不多是枪口了
	local OriginRotation = self.actor:GetCameraRotation()
	local TargetLocation = OriginLocation + UE.UKismetMathLibrary.Conv_RotatorToVector(OriginRotation) * 20000 -- 200m

    local Hits = UE.TArray(UE.FHitResult)
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.ObjectTypeQuery1)
    ObjectTypes:Add(UE.EObjectTypeQuery.ObjectTypeQuery3)
    UE.UKismetSystemLibrary.LineTraceMultiForObjects(self.actor, OriginLocation, TargetLocation, ObjectTypes, true, ActorsToIgnore, 1, Hits, true)

	-- local OriginLocation1 = self.actor:GetCameraLocation()
	-- local OriginRotation1 = self.actor:GetCameraRotation()
	-- local TargetLocation1 = OriginLocation1 + UE.UKismetMathLibrary.Conv_RotatorToVector(OriginRotation1) * 20000 -- 200m
 	-- UE.UKismetSystemLibrary.LineTraceMultiForObjects(self.actor, OriginLocation1, TargetLocation1, ObjectTypes, true, ActorsToIgnore, 1, Hits, true)

 --    local Dis1 = UE.UKismetMathLibrary.Vector_Distance(OriginLocation, OriginLocation1)
 --    local Dis2 = UE.UKismetMathLibrary.Vector_Distance(TargetLocation, TargetLocation1)
 --    G.log:debug("yj", "dis compare %s - %s", Dis1, Dis2)

    -- G.log:debug("yj", "TargetActorConfirm:UpdateReticleActorLocation %s", Hits:Length())
    local Color = UE.FLinearColor(1.0, 1.0, 1.0)
    if Hits:Length() > 0 then
    	local Owner = Hits[1].Component:GetOwner()
	    if Owner.IsMonster and Owner:IsMonster() then
		    Color = UE.FLinearColor(1.0, 0, 0)
	    end
	    self.ReticleActor:K2_SetActorLocation(Hits[1].ImpactPoint, false, nil, true)
	else
	    self.ReticleActor:K2_SetActorLocation(TargetLocation, false, nil, true)
	end

	self.ReticleActor.Widget.Widget:SetColorAndOpacity(Color)
end

decorator.message_receiver()
function AimComponent:Attack(InPressed)
	-- G.log:debug("yj", "AimComponent:Attack InPressed.%s AimGA.%s InAimState.%s", InPressed, self.AimGA, self:InAimState())
	if not self.AimGA or not self:InAimState() then
		return
	end

    local ASC = self.actor:GetASC()
    if InPressed then
    	-- self:SendMessage("SyncCameraLocationAndRotationToServer")
    	ASC:TryActivateAbilityByClass(self.AimGA)
    else
    	ASC:TargetConfirm()
		self.actor:Replicated_StopAnimMontage()
		self.actor:PlayAnimMontage(self.AimThrowMontage, 1.0, "Throw")
    end
end

function AimComponent:InAimState()
	local StateController = self.actor:_GetComponent("StateController", false)
    return StateController and StateController.state_machine:CheckState(check_table.State_Aim)
end

-- decorator.message_receiver()
-- function AimComponent:SyncCameraLocationAndRotationToServer()
-- 	if not self.actor:IsClient() then
-- 		return
-- 	end

-- 	self:Server_SyncCameraLocationAndRotation(self.actor:GetCameraLocation(), self.actor:GetCameraRotation())
-- end

-- function AimComponent:Server_SyncCameraLocationAndRotation_RPC(Location, Rotation)
--     -- 服务端的CameraRotation是空值，需要主动从客户端同步过来
--     self.actor.CameraLocation = Location
--     self.actor.CameraRotation = Rotation
-- end

decorator.message_receiver()
function AimComponent:SyncLockTargetToServer(TargetLockComponent)
	if not self.actor:IsClient() then
		return
	end

	-- sync lock target to server
    if TargetLockComponent then
		self:Server_SyncLockTarget(TargetLockComponent:GetOwner())
	else
		self:Server_SyncLockTarget(nil)
	end
end

function AimComponent:Server_SyncLockTarget_RPC(LockTarget)
	self.actor.LockTarget = LockTarget
	self:SendMessage("SyncLockTarget", LockTarget)
end


return AimComponent
