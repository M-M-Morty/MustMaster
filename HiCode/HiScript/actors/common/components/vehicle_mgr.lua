local G = require("G")

local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local Vehicle = require("actors.common.Vehicle")
local vehicle_data = require("common.data.vehicle_data").data

local VehicleMgr = Component(ComponentBase)

local decorator = VehicleMgr.decorator

function VehicleMgr:Start()
    Super(VehicleMgr).Start(self)
    self.vehicles = {}
    self.vehicle_id = 0
end

function VehicleMgr:Stop()
    Super(VehicleMgr).Stop(self)
    self:DestroyVehicle()
end

decorator.message_receiver()
function VehicleMgr:PostBeginPlay()
end

function VehicleMgr:CreateVehicle(vehicle_id)
    self:DestroyVehicle()
    local vehicle_info = self:GetVehicleData(vehicle_id)
    local World = self.actor:GetWorld()
    if not World then
        return
    end
    local VehicleClass = UE.UClass.Load(vehicle_info.item_path)
    local VehicleActor = GameAPI.SpawnActor(self.actor:GetWorld(), VehicleClass, self.actor:GetTransform(), UE.FActorSpawnParameters(), {})
    VehicleActor.mesh:SetVisibility(true)
    VehicleActor.Mgr = self
    self.vehicles[vehicle_id] = VehicleActor
    self.actor.Vehicle = VehicleActor
    return VehicleActor
end

function VehicleMgr:DestroyVehicle()
    for v_id, v_actor in pairs(self.vehicles) do
        v_actor:K2_DestroyActor()
    end
    self.vehicles={}
    self.actor.Vehicle = nil
end

function VehicleMgr:GetVehicleData(vehicle_id)
    return {
        name = "»¬°å",
        item_path = "/Game/Character/Prop/Skateboard/Blueprint/BPA_Skateboard.BPA_Skateboard_C",
    }
end

return VehicleMgr


