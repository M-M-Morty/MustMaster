require "UnLua"
local utils = require("common.utils")

local G = require("G")


local NotifyState_DoSomethingWhenHitMesh = Class()

function NotifyState_DoSomethingWhenHitMesh:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
	local Owner = MeshComp:GetOwner()
    if Owner:IsClient() then
    	return true
    end

    Owner:SendMessage("BeginRecordWhenHitStatic")

    self.IsSpawnBegin = false

    return true
end

function NotifyState_DoSomethingWhenHitMesh:Received_NotifyTick(MeshComp, Animation, DeltaTime, EventReference)
	local Owner = MeshComp:GetOwner()
    if Owner:IsClient() then
    	return true
    end

    self:SpawnActorWhenHitMesh(Owner)

    -- TODO
    -- self:SpawnDecalWhenHitMesh()

    return true
end

function NotifyState_DoSomethingWhenHitMesh:Received_NotifyEnd(MeshComp, Animation, EventReference)
	local Owner = MeshComp:GetOwner()
    if Owner:IsClient() then
    	return true
    end

	local HitTransforms = Owner.HitStaticMeshComponent.HitTransforms
    if HitTransforms:Length() ~= 0 then
		self:SpawnActorOnLastHitLocation(Owner, HitTransforms:Get(HitTransforms:Length()))
		HitTransforms:Remove(HitTransforms:Length())
    end

    Owner:SendMessage("EndRecordWhenHitStatic")

	return true
end

function NotifyState_DoSomethingWhenHitMesh:SpawnActorWhenHitMesh(Owner)
	local HitTransforms = Owner.HitStaticMeshComponent.HitTransforms
    if HitTransforms:Length() == 0 then
    	return
    end

	-- G.log:debug("yj", "NotifyState_DoSomethingWhenHitMesh:SpawnActorWhenHitMesh %s", self.IsSpawnBegin)
	if not self.IsSpawnBegin then
		self:SpawnActorOnFirstHitLocation(Owner, HitTransforms:Get(1))
		HitTransforms:Remove(1)
	elseif HitTransforms:Length() > 1 then
		self:SpawnActorOnHitLocation(Owner, HitTransforms:Get(1))
		HitTransforms:Remove(1)
	end
end

function NotifyState_DoSomethingWhenHitMesh:SpawnActorOnFirstHitLocation(Owner, HitTransform)
	if not self.BeginActorConfig.ActorClass then
		return
	end

	self:SpawnActorOnLocation(Owner, HitTransform, self.BeginActorConfig)
	self.IsSpawnBegin = true

	local Location, _, _ = UE.UKismetMathLibrary.BreakTransform(HitTransform)
	self.LastSpawnLocation = Location
end

function NotifyState_DoSomethingWhenHitMesh:SpawnActorOnHitLocation(Owner, HitTransform)
	if not self.SpawnActorConfig.ActorClass then
		return
	end

	self:FillBySpawnActorConfig(Owner, HitTransform)

	self:SpawnActorOnLocation(Owner, HitTransform, self.SpawnActorConfig, "2")

	local Location, _, _ = UE.UKismetMathLibrary.BreakTransform(HitTransform)
	self.LastSpawnLocation = Location
end

function NotifyState_DoSomethingWhenHitMesh:SpawnActorOnLastHitLocation(Owner, HitTransform)
	if not self.EndActorConfig.ActorClass then
		return
	end

	self:FillBySpawnActorConfig(Owner, HitTransform)

	self:SpawnActorOnLocation(Owner, HitTransform, self.EndActorConfig, "3")
end

function NotifyState_DoSomethingWhenHitMesh:FillBySpawnActorConfig(Owner, HitTransform)
	if not self.SpawnActorConfig.ActorClass then
		return
	end

	local Location, Rotation, _ = UE.UKismetMathLibrary.BreakTransform(HitTransform)
	local DisToLastSpawnLocation = (Location - self.LastSpawnLocation):Size()
	if DisToLastSpawnLocation < self.SpawnDisInterval then
		return
	end

	local NormalForward = UE.UKismetMathLibrary.Normal(Location - self.LastSpawnLocation)

	for idx = 1, math.floor(DisToLastSpawnLocation / self.SpawnDisInterval) do
		local SpawnLocation = self.LastSpawnLocation + NormalForward * self.SpawnDisInterval * idx
		local TransformForFill = UE.UKismetMathLibrary.MakeTransform(SpawnLocation, Rotation, UE.FVector(1, 1, 1))
		self:SpawnActorOnLocation(Owner, TransformForFill, self.SpawnActorConfig, "1")
	end
end

function NotifyState_DoSomethingWhenHitMesh:SpawnActorOnLocation(Owner, HitTransform, HitSpawnActorConfig, flag)

	local Location, Rotation, _ = UE.UKismetMathLibrary.BreakTransform(HitTransform)

    local FinalRotation = Rotation + HitSpawnActorConfig.ActorRotationOffset
    local Transform = UE.UKismetMathLibrary.MakeTransform(Location, FinalRotation, HitSpawnActorConfig.ActorScale)
    local FinalLocation = UE.UKismetMathLibrary.TransformLocation(Transform, HitSpawnActorConfig.ActorLocationOffset)
    Transform = UE.UKismetMathLibrary.MakeTransform(FinalLocation, FinalRotation, HitSpawnActorConfig.ActorScale)

	G.log:debug("yj", "NotifyState_DoSomethingWhenHitMesh:SpawnActorOnLocation %s FinalLocation.%s Location.%s ActorClass.%s IsServer.%s", flag, FinalLocation, Location, G.GetDisplayName(HitSpawnActorConfig.ActorClass), Owner:IsServer())
	GameAPI.SpawnActor(Owner:GetWorld(), HitSpawnActorConfig.ActorClass, Transform, UE.FActorSpawnParameters(), {})
end

return NotifyState_DoSomethingWhenHitMesh
