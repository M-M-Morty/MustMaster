require "UnLua"
local G = require("G")

local SequencerBlueprintInstance = Class()


function SequencerBlueprintInstance:OnSequenceTrackPlayed(AnimatedObject, SourceActor)

    local TimeDilationActor = HiBlueprintFunctionLibrary.GetTimeDilationActor(self)
    G.log:warn("devin", "SequencerBlueprintInstance:OnSequenceTrackPlayed")

    if TimeDilationActor and SourceActor and AnimatedObject then
        TimeDilationActor:AddCustomTimeDilationObject(SourceActor, AnimatedObject)
    end
end

return SequencerBlueprintInstance