require "UnLua"

local G = require("G")
local utils = require("common.utils")

local BTService_SetBuildingsCanBlast = Class()

-- 设置建筑物可破碎
-- BuildingNames - 被设置的建筑物名称
function BTService_SetBuildingsCanBlast:ReceiveActivation(Controller)
    local Pawn = Controller:GetInstigator()
    G.log:debug("yj", "BTService_SetBuildingsCanBlast ReceiveActivation", G.GetDisplayName(Pawn))
    
    local BuildingActors = GameAPI.GetActorsWithTags(Pawn, self.BuildingTags)
    for idx, BuildingActor in pairs(BuildingActors) do
        G.log:debug("yj", "BTService_SetBuildingsCanBlast  ---------------- %s", G.GetDisplayName(BuildingActor))
        BuildingActor.bCanBlast = true
    end
end


return BTService_SetBuildingsCanBlast
