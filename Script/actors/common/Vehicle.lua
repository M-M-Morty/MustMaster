require "UnLua"

local Monster = require("actors.common.Monster")

local Vehicle = Class(Monster)
local G = require("G")
Vehicle.__all_client_components__ = Monster.__all_client_components__

Vehicle.__all_server_components__ = Monster.__all_server_components__


function Vehicle:Initialize(...)
    Super(Vehicle).Initialize(self, ...)
    self.RemoteVehicle = nil
end

function Vehicle:SetRemoteVehicle(Vehicle)
    self.RemoteVehicle = Vehicle
    self.RemoteVehicle.mesh:SetVisibility(false)
    self.RemoteVehicle.CharacterMovement.UpdatedComponent:SetVisibility(false)
    self.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(Vehicle, true)
    Vehicle.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(self, true)
end

function Vehicle:ReceiveBeginPlay()
    Super(Vehicle).ReceiveBeginPlay(self)
    G.log:info_obj(self, "Vehicle", "ReceiveBeginPlay %s, %s, %s",G.GetObjectName(self), self:GetLocalRole(), self:GetRemoteRole() )
end

function Vehicle:K2_UpdateCustomMovement(DeltaTime)
    self:SendMessage("UpdateCustomMovement", DeltaTime)
end


function Vehicle:CheckClientReady()
    if not self.bBeginPlay then
        return
    end
    self:SendMessage("OnClientReady")
    --t.OnClientMonsterCreate(self)
end

function Vehicle:CheckServerReady()
    if not self.bBeginPlay then
        return
    end
    self:SendMessage("OnServerReady")
    --t.OnServerMonsterCreate(self)
end

return RegisterActor(Vehicle)