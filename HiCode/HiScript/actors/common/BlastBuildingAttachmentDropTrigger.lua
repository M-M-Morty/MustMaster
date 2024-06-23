--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BP_BlastBuildingAttachmentDropTrigger_C

require "UnLua"
local G = require("G")

local Actor = require("common.actor")

local BlastBuildingAttachmentDropTrigger = Class(Actor)

function BlastBuildingAttachmentDropTrigger:ReceiveBeginPlay()
    self.CollisionComponent.OnComponentBeginOverlap:Add(self, self.OnCollisionBeginOverlap)
    --self.CollisionComponent.OnComponentEndOverlap:Add(self, self.OnCollisionEndOverlap)
    self.OverlapCounter = 0
end

function BlastBuildingAttachmentDropTrigger:OnCollisionBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    G.log:debug("BlastBuildingAttachmentDropTrigger", "OnCollisionBeginOverlap %s ", self.ReferenceActors:Length())
    if self.OverlapCounter < 1 then        
        for Ind = 1, self.ReferenceActors:Length() do
            local Actor = self.ReferenceActors:Get(Ind)
            if Actor and Actor:IsValid() then
                Actor:SendMessage("OnActorDropEvent")                        
            end
        end
        self.OverlapCounter = self.OverlapCounter + 1
    end    
end

function BlastBuildingAttachmentDropTrigger:OnCollisionEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if self:IsValid() then
        self:Destroy()
    end
end


return RegisterActor(BlastBuildingAttachmentDropTrigger)
