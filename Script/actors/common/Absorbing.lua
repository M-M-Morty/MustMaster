require "UnLua"

local G = require("G")

local ActorBase = require("actors.common.interactable.base.base_item")

local Absorbing = Class(ActorBase)

function Absorbing:Initialize(...)
    Super(Absorbing).Initialize(self, ...)
    self.ItemAborbed = "ItemAbsorbed"
end


function Absorbing:AllChildReadyServer()
    local ID = self:GetActorIdSingle(self.ItemAborbed)
    local Actor = self:GetEditorActor(ID)
    self.ChildActorID = ID
    if Actor then
        Actor:MakeMainActor(self)
        self[self.ItemAborbed] = UE.FSoftObjectPtr(Actor)
    end
    Super(Absorbing).AllChildReadyServer(self)
end

function Absorbing:AllChildReadyClient()
    local ID = self:GetActorIdSingle(self.ItemAborbed)
    local Actor = self:GetEditorActor(ID)
    self.ChildActorID = ID
    if Actor then
        Actor:MakeMainActor(self)
        self[self.ItemAborbed] = UE.FSoftObjectPtr(Actor)
    end
    Super(Absorbing).AllChildReadyClient(self)
end

return Absorbing
