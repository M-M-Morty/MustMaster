-- Charge GA.
local G = require("G")
local GASequence = require("skill.ability.GASequence")
local GAPika_Vehicle = Class(GASequence)


function GAPika_Vehicle:InitBindings()
    local function _MakeActorArray(Actor)
        local Arr = UE.TArray(UE.AActor)
        Arr:Add(Actor)
        return Arr
    end

    local Owner = self:GetAvatarActorFromActorInfo()
    -- G.log:debug("yj", "GAPika_Vehicle:InitBindings Owner.%s Driver.%s", Owner, self:GetDriver())

    local Bindings = UE.TArray(UE.FAbilityTaskSequenceBindings)

    local VehicleBinding = UE.FAbilityTaskSequenceBindings()
    VehicleBinding.BindingTag = "Vehicle"
    VehicleBinding.Actors = _MakeActorArray(Owner)
    Bindings:Add(VehicleBinding)

    local DriverBinding = UE.FAbilityTaskSequenceBindings()
    DriverBinding.BindingTag = "Driver"
    DriverBinding.Actors = _MakeActorArray(self:GetDriver())
    Bindings:Add(DriverBinding)

    return Bindings
end

function GAPika_Vehicle:GetDriver()
    local Vehicle = self:GetAvatarActorFromActorInfo()
    if Vehicle.VehicleComponent then
        return Vehicle.VehicleComponent.Passengers:Get(1)
    end
end

return GAPika_Vehicle
