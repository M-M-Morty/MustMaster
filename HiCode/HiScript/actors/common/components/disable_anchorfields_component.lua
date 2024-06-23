--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")


---@type BP_DisableAnthorComponent_C
local DisableAnchorfieldsComponent = Component(ComponentBase)
local decorator = DisableAnchorfieldsComponent.decorator



decorator.message_receiver()
function DisableAnchorfieldsComponent:AddBlastEventListener(BlastDelegate)
    if BlastDelegate then       
        BlastDelegate:Add(self, self.OnStartBlastHappen)        
    end
end

decorator.message_receiver()
function DisableAnchorfieldsComponent:RemoveBlastEventListener(BlastDelegate)
    if BlastDelegate then    
        BlastDelegate:Remove(self, self.OnStartBlastHappen)    
    end
end

decorator.message_receiver()
function DisableAnchorfieldsComponent:OnActorDropEvent()
    self:RemoveAnchorFieldFromOwner()
    self:SetGeometryCollectionDynamicState()
end


function DisableAnchorfieldsComponent:OnStartBlastHappen()
    self:OnActorDropEvent()
end


function DisableAnchorfieldsComponent:RemoveAnchorFieldFromOwner()
    local gc = self.actor.GeometryCollectionComponent
    if gc then        
        for i = 1, gc.InitializationFields:Length() do
            local FieldSystemActor = gc.InitializationFields:Get(i)
            if FieldSystemActor and FieldSystemActor:IsValid() then
                FieldSystemActor:K2_DestroyActor()
            end            
        end
        gc.InitializationFields:Clear()
    end
end


function DisableAnchorfieldsComponent:SetGeometryCollectionDynamicState()
    local gc = self.actor.GeometryCollectionComponent
    if gc then
        local Location = gc:K2_GetComponentLocation()
        local Radius = 500.0
        gc:ApplyKinematicField(Radius, Location)
    end
end


return DisableAnchorfieldsComponent