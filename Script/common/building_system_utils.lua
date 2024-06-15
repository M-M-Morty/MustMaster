require "UnLua"
local G = require("G")

BS_Utils = {}

function BS_Utils:GetSubSystem()
    local ManagerClass = UE.UClass.Load("/Game/Blueprints/BuildingSystem/BP_BuilderSubsystem.BP_BuilderSubsystem_C")
    local BuilderSubsystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(G.GameInstance:GetWorld(), ManagerClass)        
    --G.log:info("hycoldrain", "UIBuildingSystem:OnClicked_Btn_Esc  %s", tostring(BuilderSubsystem))
    return BuilderSubsystem
end

return BS_Utils
