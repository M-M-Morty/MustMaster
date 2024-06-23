require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local VisibilityComponent = Component(ComponentBase)

local decorator = VisibilityComponent.decorator


function VisibilityComponent:Initialize(...)
    Super(VisibilityComponent).Initialize(self, ...)
    self.ActorVisibleStack = {}    
end

decorator.message_receiver()
function VisibilityComponent:SetVisibility(InVisible)
    G.log:debug("hycoldrain", "SetVisibility %s", tostring(InVisible))
    local Mesh = self.actor.Mesh
    if Mesh and Mesh:IsValid() then
        Mesh:SetVisibility(InVisible, true)
    end
end

return VisibilityComponent
