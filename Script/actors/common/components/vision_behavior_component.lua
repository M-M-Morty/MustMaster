-- 视觉关卡
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local G = require("G")
local utils = require("common.utils")
local vision_behavior_table = require("common.data.vision_behavior_table")

local VisionBehaviorComponent = Component(ComponentBase)

local decorator = VisionBehaviorComponent.decorator


function VisionBehaviorComponent:Initialize(...)
    Super(VisionBehaviorComponent).Initialize(self, ...)
    self.LastTriggerID = nil
    self.NextTriggerTimer = {}
end

decorator.message_receiver()
function VisionBehaviorComponent:OnReceiveTick(DeltaSeconds)
	if not self.actor:IsClient() or not self.actor:IsPlayer() then
		return
	end

	for BehaviorID, _ in pairs(vision_behavior_table.data) do
		local Location = self.actor:K2_GetActorLocation()
		local CameraRotation = self.actor:GetCameraRotation()
		if self:CanTriggerVisionBehavior(BehaviorID, Location, CameraRotation) then
			self.LastTriggerID = nil
			if self.LastTriggerID ~= BehaviorID then
				-- G.log:debug("yj", "VisionBehaviorComponent:Server_TriggerVisionBehavior #######.%s", BehaviorID)
				self:Server_TriggerVisionBehavior(BehaviorID, CameraRotation)
				self.LastTriggerID = BehaviorID
			end
		end

	end
end

function VisionBehaviorComponent:CanTriggerVisionBehavior(BehaviorID, Location, CameraRotation)
	local BehaviorData = vision_behavior_table.data[BehaviorID]

	-- Location Check
	local ReqLocation = BehaviorData.pos_require
	if math.abs(ReqLocation[1] - Location.X) > ReqLocation[4] then
		return false
	end

	if math.abs(ReqLocation[2] - Location.Y) > ReqLocation[4] then
		return false
	end
	
	if math.abs(ReqLocation[3] - Location.Z) > ReqLocation[4] then
		return false
	end

	-- Rotation Check
    -- Rotation经过rpc传一次，负的角度会转成正的，所以全部转成正角度来计算
	local ReqRotation = BehaviorData.rot_require
	if math.abs(utils.D_N2P(ReqRotation[1]) - utils.D_N2P(CameraRotation.Pitch)) > ReqRotation[4] then
		return false
	end

	if math.abs(utils.D_N2P(ReqRotation[2]) - utils.D_N2P(CameraRotation.Yaw)) > ReqRotation[4] then
		return false
	end

	if math.abs(utils.D_N2P(ReqRotation[3]) - utils.D_N2P(CameraRotation.Roll)) > ReqRotation[4] then
		return false
	end

	-- G.log:debug("yj", "VisionBehaviorComponent:CanTriggerVisionBehavior CameraRotation.%s ReqRotation.%s", CameraRotation, table.concat(ReqRotation, ", "))

	return true
end

function VisionBehaviorComponent:Server_TriggerVisionBehavior_RPC(BehaviorID, CameraRotation)

	-- G.log:debug("yj", "VisionBehaviorComponent:Server_TriggerVisionBehavior_RPC %s CameraRotation.%s", BehaviorID, CameraRotation)
	-- Server Check
	local Location = self.actor:K2_GetActorLocation()
	if not self:CanTriggerVisionBehavior(BehaviorID, Location, CameraRotation) then
		return
	end

	-- p:Server_TriggerVisionBehavior(1, nil)

	local Now = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
	if self.NextTriggerTimer[BehaviorID] ~= nil and self.NextTriggerTimer[BehaviorID] > Now then
		return
	end

	-- G.log:debug("yj", "VisionBehaviorComponent:Server_TriggerVisionBehavior_RPC %s CameraRotation.%s", BehaviorID, CameraRotation)

	local BehaviorData = vision_behavior_table.data[BehaviorID]
   	local MonsterClass = UE.UClass.Load(BehaviorData.monster_path)
   	self.actor:GetWorld():SpawnActor(MonsterClass, self.actor:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self, self)

   	self.NextTriggerTimer[BehaviorID] = Now + 2
end


return VisionBehaviorComponent
