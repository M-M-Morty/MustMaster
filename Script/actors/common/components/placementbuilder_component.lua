require "UnLua"

local G = require("G")
local BuildingUtils = require("common.building_system_utils")

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local InputModes = require("common.event_const").InputModes


local PlacementBuilderComponent = Component(ComponentBase)

local decorator = PlacementBuilderComponent.decorator


function PlacementBuilderComponent:Start()
    Super(PlacementBuilderComponent).Start(self)    
    G.log:info("hycoldrain", "PlacementBuilderComponent:ReceiveBeginPla")
    self:ReadfromDataTable(self.DataTable)
    if self.actor:IsPlayer() then
        self.CameraCharactor = nil
    end
end

function PlacementBuilderComponent:Stop()
    Super(PlacementBuilderComponent).Stop(self)    
    if self.actor:IsPlayer() then
        --G.log:debug("hybuild", "PlacementBuilderComponent:Stop ......")
        self:InactiveBuildingSystem()
    end   
end

function PlacementBuilderComponent:ActiveBuildingSystem()
    if self.actor:IsPlayer() then
        --G.log:debug("hybuild", "PlacementBuilderComponent:ActiveBuildingSystem.....")
        self:SendMessage("RegisterInputHandler", InputModes.NormalBuilder, self)
        local BuilderSubsystem = BuildingUtils.GetSubSystem()
        BuilderSubsystem:ShowBuildUI(true, self.actor)
        self:LaunchBuildMode()
    end
end

function PlacementBuilderComponent:InactiveBuildingSystem()
    if self.actor:IsPlayer() then
        --G.log:debug("hybuild", "PlacementBuilderComponent:InactiveBuildingSystem ......")
        self:SendMessage("UnRegisterInputHandler", InputModes.NormalBuilder)
        local BuilderSubsystem = BuildingUtils.GetSubSystem()
        BuilderSubsystem:ShowBuildUI(false, self.actor)
        self:StopBuildMode()
        self:DisableBuildingSystem()         
    end
end

function PlacementBuilderComponent:Attack(bPress)
    --G.log:debug("hybuild", "PlacementBuilderComponent:Attack %s", tostring(bPress))
    if bPress then
        self:MousePress()
    else
        self:MouseRelease()
    end
end


function PlacementBuilderComponent:OnTargetArmLengthChanged(Value)    
    --G.log:debug("hybuild", "PlacementBuilderComponent:OnTargetArmLengthChanged %s", tostring(Value))
    self:SetTargetActorTraceDistance(self.TraceStartDistance, Value * 1.5)
    self:SetGizmoTraceDistance(self.TraceStartDistance, Value * 1.5)
    self:SetGizmoScale(Value/1000.0)
end

function PlacementBuilderComponent:BeforeUnposses()
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
	--self.actor.CapsuleComponent:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
	--self.actor.Mesh:SetGenerateOverlapEvents(false)
	--self.actor:SetActorHiddenInGame(true)
	--if not self.actor:IsClient() then
		-- TODO
	    -- self.SwitchPlayerDestroyTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self.actor, self.actor.K2_DestroyActor}, 360, false)
	--else
	--	self.actor.CharacterMovement.NetworkSmoothingMode = UE.ENetworkSmoothingMode.Disabled
	--end
end

-- message_receivers
decorator.message_receiver()
function PlacementBuilderComponent:Event_ExitBuildingSystem()
    self:InactiveBuildingSystem()
end

decorator.message_receiver()
function PlacementBuilderComponent:Event_TargetActorChangeMesh()
    self:TargetActorChangeMesh()
end

decorator.message_receiver()
function PlacementBuilderComponent:Event_LaunchBuildMode()
    self:LaunchBuildMode()
end

decorator.message_receiver()
function PlacementBuilderComponent:Event_RotateTargetActor()
    self:RotateTargetActor()
end


--rpc run on client
function PlacementBuilderComponent:EnableBuildingSystem_RPC(bNeedCamera)
    if bNeedCamera then
        self:SpawnCameraAndPossess()
        self:BeforeUnposses()
    else
        self:ActiveBuildingSystem()
    end
end

--rpc run on server
function PlacementBuilderComponent:SpawnCameraAndPossess_RPC()
    --G.log:debug("hybuild", "PlacementBuilderComponent:Start..... %s, %s", tostring(self.actor:GetLocalRole()), tostring(UE.ENetRole.ROLE_Authority))       
    local BuilderSubsystem = BuildingUtils.GetSubSystem()    
   
    BuilderSubsystem:SpawnCameraCharactor(self.actor:GetWorld(), self.actor:GetTransform())
    self:BeforeUnposses()    
    BuilderSubsystem:PossesToCamera(self.actor)
end

function PlacementBuilderComponent:DisableBuildingSystem_RPC()
    --G.log:debug("hybuild", "PlacementBuilderComponent:DisableBuildingSystem_RPC.....")
    local BuilderSubsystem = BuildingUtils.GetSubSystem()
    BuilderSubsystem:PossesBackPlayer()
end

return PlacementBuilderComponent
