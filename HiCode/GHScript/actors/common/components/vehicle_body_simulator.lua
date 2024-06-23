--
-- @COMPANY GHGame
-- @AUTHOR lizhi
-- 模拟车辆模型贴合起伏表面
--
-- 参数说明
-- SpringHookean										悬架弹簧的胡克系数
-- SpringLinearDamping									线性阻尼
-- SpringAngularDamping									旋转阻尼
-- SpringLength											悬架弹簧长度
-- MinLocalOffsetZLimit, MaxLocalOffsetZLimit			模拟结果与逻辑位置的Clamp范围
-- RotationLimit										模拟结果与逻辑旋转的Clamp范围
-- WheelPoints											轮子的位置
-- SimPhysicsGravity									模拟重力的数值


local G = require('G')

---@param Matrix FMatrix
---@param Vector FVector
---@return FVector
function Mat3x3_Mul_Vector(Matrix, Vector)
    local Vec4 = UE.UKismetMathLibrary.Matrix_TransformVector(Matrix, Vector)
	return UE.FVector(Vec4.X, Vec4.Y, Vec4.Z)
end

---@param Matrix FMatrix
---@param Vector FVector
---@return FMatrix
function CalculateWorldInertiaTensorInverse(Orientation, InverseInertiaTensorLocal)
    local M00, M01, M02 = Orientation.XPlane.X, Orientation.XPlane.Y, Orientation.XPlane.Z
    local M10, M11, M12 = Orientation.YPlane.X, Orientation.YPlane.Y, Orientation.YPlane.Z
    local M20, M21, M22 = Orientation.ZPlane.X, Orientation.ZPlane.Y, Orientation.ZPlane.Z

	local outInverseInertiaTensorWorld = UE.FMatrix()
    outInverseInertiaTensorWorld.XPlane.X = M00 * InverseInertiaTensorLocal.X
	outInverseInertiaTensorWorld.XPlane.Y = M10 * InverseInertiaTensorLocal.X
	outInverseInertiaTensorWorld.XPlane.Z = M20 * InverseInertiaTensorLocal.X
	outInverseInertiaTensorWorld.XPlane.W = 0

	outInverseInertiaTensorWorld.YPlane.X = M01 * InverseInertiaTensorLocal.Y
	outInverseInertiaTensorWorld.YPlane.Y = M11 * InverseInertiaTensorLocal.Y
	outInverseInertiaTensorWorld.YPlane.Z = M21 * InverseInertiaTensorLocal.Y
	outInverseInertiaTensorWorld.YPlane.W = 0

	outInverseInertiaTensorWorld.ZPlane.X = M02 * InverseInertiaTensorLocal.Z
	outInverseInertiaTensorWorld.ZPlane.Y = M12 * InverseInertiaTensorLocal.Z
	outInverseInertiaTensorWorld.ZPlane.Z = M22 * InverseInertiaTensorLocal.Z
	outInverseInertiaTensorWorld.ZPlane.W = 0

	outInverseInertiaTensorWorld.WPlane.X = 0
	outInverseInertiaTensorWorld.WPlane.Y = 0
	outInverseInertiaTensorWorld.WPlane.Z = 0
	outInverseInertiaTensorWorld.WPlane.W = 1

    return UE.UKismetMathLibrary.Multiply_MatrixMatrix(Orientation, outInverseInertiaTensorWorld)
end

---@param Quaternion FQuat
---@return FMatrix
function GetQuaternionMatrix(Quaternion)
    local x, y, z, w = Quaternion.X, Quaternion.Y, Quaternion.Z, Quaternion.W
    local x2, y2, z2 = x + x, y + y, z + z
    local xx, xy, xz = x * x2, x * y2, x * z2
    local yy, yz, zz = y * y2, y * z2, z * z2
    local wx, wy, wz = w * x2, w * y2, w * z2
	
	local Matrix = UE.FMatrix()
    Matrix.XPlane.X = 1.0 - (yy + zz)
	Matrix.XPlane.Y = xy + wz
	Matrix.XPlane.Z = xz - wy
	Matrix.XPlane.W = 0.0

	Matrix.YPlane.X = xy - wz
	Matrix.YPlane.Y = 1.0 - (xx + zz)
	Matrix.YPlane.Z = yz + wx
	Matrix.YPlane.W = 0.0

	Matrix.ZPlane.X = xz + wy
	Matrix.ZPlane.Y = yz - wx
	Matrix.ZPlane.Z = 1.0 - (xx + yy)
	Matrix.ZPlane.W = 0.0

	Matrix.WPlane.X = 0.0
	Matrix.WPlane.Y = 0.0
	Matrix.WPlane.Z = 0.0
	Matrix.WPlane.W = 1.0

	return Matrix
end

-- 模拟，不需要动态数值
local ConstBodyMass = 1.0
local ConstBodyMassInv = 1.0
local ConstLocalInertiaTensor = UE.FVector(1666.667, 1666.667, 1666.667)
local ConstLocalInvInertiaTensor = UE.FVector(1.0 / ConstLocalInertiaTensor.X, 1.0 / ConstLocalInertiaTensor.Y, 1.0 / ConstLocalInertiaTensor.Z)

---@type BP_VehicleBodySimulator_C
local VehicleBodySimulator = UnLua.Class()


-- function VehicleBodySimulator:Initialize(Initializer)
-- end

function VehicleBodySimulator:ReceiveBeginPlay()

    self.Overridden.ReceiveBeginPlay(self)

	self.OwnerActor = self:GetOwner()
	self.bSimulateBody = UE.UKismetSystemLibrary.IsStandalone(self) or not self.OwnerActor:HasAuthority()

    if self.bSimulateBody then
        self.SpringLength = math.abs(self.SpringLength)

        local AttachedComponent = self:GetAttachParent()
        if AttachedComponent then
            self.RigidComponent = AttachedComponent:Cast(UE.UPrimitiveComponent)
        end

		self.DefaultLocalYaw = 0.0
        if self.RigidComponent then
            self.BaseLinearDamping = self.RigidComponent:GetLinearDamping()
            self.BaseAngularDamping = self.RigidComponent:GetAngularDamping()

			local AttachSocket = self:GetAttachSocketName()
			if self.RigidComponent:Cast(UE.USkeletalMeshComponent) and AttachSocket ~= 'None' then
				self.bUsingBoneUpdate = true
				self.AttachSocket = AttachSocket
				self.OriginVisibilityBasedAnimTickOption = self.RigidComponent.VisibilityBasedAnimTickOption
				self.RigidComponent.VisibilityBasedAnimTickOption = UE.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
			else
				self.bUsingBoneUpdate = false
				self.DefaultLocalYaw = self.RigidComponent:K2_GetComponentRotation().Yaw
			end
        end

        self.MovementComponent = self.OwnerActor:GetMovementComponent()
        self.MaxSimPhysicsTimeInterval = 1 / 30

        self.ExternalForces = UE.FVector(0,0,0)
        self.ExternalTorques = UE.FVector(0,0,0)

        self.FakeLinearVelocity = UE.FVector(0,0,0)
        self.FakeAngularVelocity = UE.FVector(0,0,0)
    end
end

-- function VehicleBodySimulator:ReceiveEndPlay()
-- end

function VehicleBodySimulator:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)
    if self.bSimulateBody then
        if not self.bManualTick then
            self:ManualTick(DeltaSeconds)
        end
    end
end

function VehicleBodySimulator:SimulateBody(DeltaTime)

	local pointNum = self.WheelPoints:Num()
	if pointNum <= 0 then
		return
    end

    local SignOfGravity = UE.UKismetMathLibrary.SignOfFloat(self.SimPhysicsGravity)
    local MyWorldTransform = self:K2_GetComponentToWorld()
	self.PointsUnderFloor = 0
    for pointIndex = 1, pointNum do
		local isUnderFloor = false
        local pointV3 = self.WheelPoints:Get(pointIndex)
		local worldPointV3 = UE.UKismetMathLibrary.TransformLocation(MyWorldTransform, pointV3)
		local FlootHeight = self:GetFloorHeight(worldPointV3)

		local SignedRadius = SignOfGravity * self.SpringLength
        if FlootHeight > worldPointV3.Z + SignedRadius then

			self.PointsUnderFloor = self.PointsUnderFloor + 1
			isUnderFloor = true

			local LengthMultiplier = (FlootHeight - (worldPointV3.Z + SignedRadius)) / (self.SpringLength * 2)
			LengthMultiplier = UE.UKismetMathLibrary.FClamp(LengthMultiplier, 0, 2)

			-- force formula: (Volume(Mass) * SpringHookean * -Gravity) / Total Points * LengthMultiplier
			local ForceZ = ConstBodyMass * self.SpringHookean * -self.SimPhysicsGravity / pointNum * LengthMultiplier

			-- Add force for this point
			self:ApplyForceAtPosition(UE.FVector(0, 0, ForceZ), worldPointV3)
        else
            -- Add Gravity Torques for this point
			-- self:ApplyTorquesAtPosition(UE.FVector(0, 0, self.SimPhysicsGravity), worldPointV3)
		end

		if self.bDrawDebugPoints then
            -- Blue color under floor, other is yellow 
            local DebugColor = isUnderFloor and UE.FLinearColor(0, 0.2, 0.7, 0.8) or UE.FLinearColor(0.8, 0.7, 0.2, 0.8)
            UE.UKismetSystemLibrary.DrawDebugSphere(self, worldPointV3, self.SpringLength, 8, DebugColor)
        end
	end

	self:UpdateFakePhysicsVelocity(DeltaTime)

	local linDampingFactor = self.BaseLinearDamping + self.SpringLinearDamping * self.PointsUnderFloor / pointNum
	local angDampingFactor = self.BaseAngularDamping + self.SpringAngularDamping * self.PointsUnderFloor / pointNum
	-- Apply the velocity damping
	-- Damping force : F_c = -c' * v (c=damping factor)
	-- Differential Equation      : m * dv/dt = -c' * v
	--                              => dv/dt = -c * v (with c=c'/m)
	--                              => dv/dt + c * v = 0
	-- Solution      : v(t) = v0 * e^(-c * t)
	--                 => v(t + dt) = v0 * e^(-c(t + dt))
	--                              = v0 * e^(-c * t) * e^(-c * dt)
	--                              = v(t) * e^(-c * dt)
	--                 => v2 = v1 * e^(-c * dt)
	-- Using Padé's approximation of the exponential function:
	-- Reference: https://mathworld.wolfram.com/PadeApproximant.html
	--                   e^x ~ 1 / (1 - x)
	--                      => e^(-c * dt) ~ 1 / (1 + c * dt)
	--                      => v2 = v1 * 1 / (1 + c * dt)
	-- Update damping based on number of underfloor test points
	local linearDamping = 1.0 / (1.0 + linDampingFactor * DeltaTime)
	local angularDamping = 1.0 / (1.0 + angDampingFactor * DeltaTime)

	self.FakeLinearVelocity = self.FakeLinearVelocity * linearDamping
	self.FakeAngularVelocity = self.FakeAngularVelocity * angularDamping

	if self.bUsingBoneUpdate then
		self:UpdateFakePhysicsBody_Bone(self.AttachSocket, DeltaTime)
	else
		self:UpdateFakePhysicsBody_Component(DeltaTime)
	end
end

function VehicleBodySimulator:UpdateFakePhysicsVelocity(DeltaTime)

    local Rotation = self.RigidComponent:K2_GetComponentRotation()
    local Quaternion = UE.UKismetMathLibrary.Conv_RotatorToQuaternion(Rotation)
	
	local QuatMatrix = GetQuaternionMatrix(Quaternion)
	local WorldInvInertiaTensor = CalculateWorldInertiaTensorInverse(QuatMatrix, ConstLocalInvInertiaTensor)

	local LinearLockAxisFactors = UE.FVector(1,1,1)
	local AngularLockAxisFactors = UE.FVector(1,1,1)

	-- Integrate the external force to get the new velocity of the body
	self.FakeLinearVelocity = self.FakeLinearVelocity + LinearLockAxisFactors * self.ExternalForces * (DeltaTime * ConstBodyMassInv)
	self.FakeAngularVelocity = self.FakeAngularVelocity + AngularLockAxisFactors * Mat3x3_Mul_Vector(WorldInvInertiaTensor, self.ExternalTorques) * DeltaTime

	-- Apply gravity force
    local pointNum = self.WheelPoints:Num()
    local GravityScale = pointNum - self.PointsUnderFloor
    GravityScale = UE.UKismetMathLibrary.FClamp(GravityScale, 1, pointNum)

	self.FakeLinearVelocity = self.FakeLinearVelocity + UE.FVector(0, 0, GravityScale * self.SimPhysicsGravity) * DeltaTime

	self.ExternalForces = UE.FVector(0,0,0)
	self.ExternalTorques = UE.FVector(0,0,0)
end

function VehicleBodySimulator:UpdateFakePhysicsBody_Component(DeltaTime)
	-- Get current position and orientation of the body
    local ownerTransform = self:GetOwner():GetTransform()               ---@type FTransform
    local worldTransform = self.RigidComponent:K2_GetComponentToWorld() ---@type FTransform
	local currentOrientation = worldTransform.Rotation
	local currentLocation = worldTransform.Translation

	-- Update the new constrained position and orientation of the body
	local deltaLocation = self.FakeLinearVelocity * DeltaTime
    local destLocation = currentLocation + deltaLocation
    local localDestLocation = ownerTransform:InverseTransformPosition(destLocation)
    localDestLocation.Z = UE.UKismetMathLibrary.FClamp(localDestLocation.Z, self.MinLocalOffsetZLimit, self.MaxLocalOffsetZLimit)
	localDestLocation.X, localDestLocation.Y = 0, 0
    destLocation = ownerTransform:TransformPosition(localDestLocation)

    local newOrientation = currentOrientation + UE.FQuat(self.FakeAngularVelocity.X, self.FakeAngularVelocity.Y, self.FakeAngularVelocity.Z, 0) * currentOrientation * 0.5 * DeltaTime
	local localOrientation = ownerTransform:InverseTransformRotation(newOrientation)
	local localRot = localOrientation:ToRotator()---@type FRotator
	localRot.Yaw = self.DefaultLocalYaw
    localRot.Pitch = UE.UKismetMathLibrary.FClamp(localRot.Pitch, -self.RotationLimit.X, self.RotationLimit.X)
    localRot.Roll = UE.UKismetMathLibrary.FClamp(localRot.Roll, -self.RotationLimit.Z, self.RotationLimit.Z)

    local destOrientation = UE.UKismetMathLibrary.TransformRotation(ownerTransform, localRot)
    self.RigidComponent:K2_SetWorldLocationAndRotation(destLocation, destOrientation, false, nil, true)
end

-- 在CS模式下变更Component的坐标会导致移动时模型抖动
-- 使用在ABP中修改RootBoneIK的方式解决此问题
function VehicleBodySimulator:UpdateFakePhysicsBody_Bone(BoneName, DeltaTime)
	-- Get current position and orientation of the body root bone
	local worldTransform = self.RigidComponent:K2_GetComponentToWorld() ---@type FTransform
	local boneWorldTransform = self.RigidComponent:GetSocketTransform(BoneName) ---@type FTransform

	local currentOrientation = boneWorldTransform.Rotation
	local currentLocation = boneWorldTransform.Translation

	-- Update the new constrained position and orientation of the body
	local deltaLocation = self.FakeLinearVelocity * DeltaTime
    local destLocation = currentLocation + deltaLocation
    local localDestLocation = worldTransform:InverseTransformPosition(destLocation)
    localDestLocation.Z = UE.UKismetMathLibrary.FClamp(localDestLocation.Z, self.MinLocalOffsetZLimit, self.MaxLocalOffsetZLimit)
	localDestLocation.X, localDestLocation.Y = 0, 0
	self.RootBoneLocation = localDestLocation

    local newOrientation = currentOrientation + UE.FQuat(self.FakeAngularVelocity.X, self.FakeAngularVelocity.Y, self.FakeAngularVelocity.Z, 0) * currentOrientation * 0.5 * DeltaTime
	local localOrientation = worldTransform:InverseTransformRotation(newOrientation)
	local localRot = localOrientation:ToRotator()---@type FRotator
	localRot.Yaw = self.DefaultLocalYaw
    localRot.Pitch = UE.UKismetMathLibrary.FClamp(localRot.Pitch, -self.RotationLimit.X, self.RotationLimit.X)
    localRot.Roll = UE.UKismetMathLibrary.FClamp(localRot.Roll, -self.RotationLimit.Z, self.RotationLimit.Z)
	self.RootBoneRotation = localRot
end

function VehicleBodySimulator:GetFloorHeight(WorldLocation)

    local OwnerActorLocation = self.OwnerActor:K2_GetActorLocation()
    local TraceStart, TraceEnd

    if WorldLocation.Z > OwnerActorLocation.Z then
        TraceStart = UE.FVector(WorldLocation.X, WorldLocation.Y, WorldLocation.Z)
        TraceEnd = UE.FVector(WorldLocation.X, WorldLocation.Y, OwnerActorLocation.Z - 300)
    else
        TraceStart = UE.FVector(WorldLocation.X, WorldLocation.Y, OwnerActorLocation.Z)
        TraceEnd = UE.FVector(WorldLocation.X, WorldLocation.Y, WorldLocation.Z - 300)
    end

    local HitResult = UE.FHitResult()
    local ActorsToIgnore = {}

    -- UE.UKismetSystemLibrary.LineTraceSingle(self.OwnerActor, TraceStart, TraceEnd, UE.ETraceTypeQuery.Visibility, false, ActorsToIgnore, UE.EDrawDebugTrace.None, HitResult, true)
	UE.UKismetSystemLibrary.LineTraceSingleByProfile(self.OwnerActor, TraceStart, TraceEnd, 'Mesh', false, ActorsToIgnore, UE.EDrawDebugTrace.None, HitResult, true)
    --if self.MovementComponent:IsWalkable(HitResult) then
    if HitResult.bBlockingHit and HitResult.Component and HitResult.Component:CanCharacterStepUp(self.OwnerActor) then
		return HitResult.ImpactPoint.Z
    end
	return -100000000.0
end

function VehicleBodySimulator:ClearForcesAndVelocity()
    self.ExternalForces = UE.FVector(0,0,0)
	self.ExternalTorques = UE.FVector(0,0,0)

	self.FakeLinearVelocity = UE.FVector(0,0,0)
	self.FakeAngularVelocity = UE.FVector(0,0,0)

	if self.bUsingBoneUpdate then
		self.RigidComponent.VisibilityBasedAnimTickOption = self.OriginVisibilityBasedAnimTickOption
	end
end

function VehicleBodySimulator:ApplyForceAtPosition(WorldForce, WorldPosition)
	-- Add the force
	self.ExternalForces = self.ExternalForces + WorldForce

    self:ApplyTorquesAtPosition(WorldForce, WorldPosition)
end

function VehicleBodySimulator:ApplyTorquesAtPosition(WorldForce, WorldPosition)

	-- Add the torque
    local worldCompLocation = self.RigidComponent:K2_GetComponentLocation()
    self.ExternalTorques = self.ExternalTorques + UE.UKismetMathLibrary.Cross_VectorVector(WorldPosition - worldCompLocation, WorldForce)
end

function VehicleBodySimulator:ManualTick(DeltaTime)

    if not self.bSimulateBody then
        return
    end
	
    if not self:IsActive() or not self.MovementComponent or not self.RigidComponent or self.RigidComponent:IsAnySimulatingPhysics() then
        self:ClearForcesAndVelocity()
        return
    end

    if not self.MovementComponent:IsWalking() then
        self:ClearForcesAndVelocity()
        local OwnerVelocity = self.OwnerActor:GetVelocity()
        self.FakeLinearVelocity = UE.FVector(0,0,OwnerVelocity.Z)
        return
    end

    if self.WheelPoints:Num() > 0 then
        local ClampedDeltaTime = UE.UKismetMathLibrary.FClamp(DeltaTime, 0, self.MaxSimPhysicsTimeInterval)
        self:SimulateBody(ClampedDeltaTime)
    end
end

return VehicleBodySimulator
