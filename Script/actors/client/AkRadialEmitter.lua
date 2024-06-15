--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local Actor = require("common.actor")

---@type BP_AkRadialEmitter_C
local AkRadialEmitter = Class(Actor)

function AkRadialEmitter:ReceiveBeginPlay()
    if self:IsClient() then
        local ExternalSources = UE.TArray(UE.FAkExternalSourceInfo)
        self.AkComponent:PostAssociatedAkEvent(0, nil, ExternalSources)
    end
end

function AkRadialEmitter:DebugDraw()
    local Location = self:K2_GetActorLocation()
    -- debug draw inner shpere
    local inner = self.AkComponent.innerRadius
    UE.UKismetSystemLibrary.DrawDebugSphere(self, Location, inner, 12, UE.FLinearColor(0.2, 1, 0.2), 10000.0, 5.0)

    -- debug draw outter shpere
    local outter = self.AkComponent.outerRadius
    UE.UKismetSystemLibrary.DrawDebugSphere(self, Location, outter, 12, UE.FLinearColor(1, 0.2, 0.5), 10000.0, 5.0)

    -- debug draw Attenuation shpere
    local Attenuation = self.AkComponent:GetAttenuationRadius()
    UE.UKismetSystemLibrary.DrawDebugSphere(self, Location, Attenuation, 12, UE.FLinearColor(0.1, 0.1, 1), 10000.0, 5.0)

end

return RegisterActor(AkRadialEmitter)