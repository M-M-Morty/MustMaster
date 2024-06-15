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

local BlastBuildingActor = Class(Actor)


function BlastBuildingActor:ReceiveBeginPlay()    
    Super(BlastBuildingActor).ReceiveBeginPlay(self)
    for i = 1, self.AttachmentActors:Length() do
        local AttachmentActor = self.AttachmentActors:Get(i)
        if AttachmentActor and AttachmentActor:IsValid() then
            --G.log:debug("hycoldrain", "ReceiveBeginPlay %s   %s", G.GetDisplayName(AttachmentActor),  AttachmentActor)             
            AttachmentActor:SendMessage("AddBlastEventListener", self.StartBlastDelegate)         
        end        
    end

    self.__TAG__ = string.format("BlastBuildingActor(%s, server: %s)", G.GetObjectName(self), self:IsServer())
end

function BlastBuildingActor:ReceiveEndPlay()    
    Super(BlastBuildingActor).ReceiveEndPlay(self)
    for i = 1, self.AttachmentActors:Length() do
        local AttachmentActor = self.AttachmentActors:Get(i)
        if AttachmentActor and AttachmentActor:IsValid() then
            --G.log:debug("hycoldrain", "ReceiveEndPlay %s ", G.GetDisplayName(AttachmentActor))                
            AttachmentActor:SendMessage("RemoveBlastEventListener", self.StartBlastDelegate)   
        end        
    end
end

--[[
    Implement BPI_Destructible interface.
]]
function BlastBuildingActor:OnHit(Instigator, Causer, Hit, Durability, RemainDurability)
    G.log:debug(self.__TAG__, "OnHit instigator: %s, Causer: %s, Durability: %f, Remain: %f", G.GetObjectName(Instigator), G.GetObjectName(Causer), Durability, RemainDurability)
end

function BlastBuildingActor:OnBreak(Instigator, Causer, Hit, Durability)
    local HitFS = self.DestructComponent.HitFS

    if HitFS then
        self.bBreak = true
        if self.InteractionComponent then
            self.InteractionComponent:SetInteractable(false)
        end

        G.log:debug(self.__TAG__, "OnBreak instigator: %s, Causer: %s, Durability: %f, HitFS: %s, HitPoint: %s", G.GetObjectName(Instigator), G.GetObjectName(Causer), Durability, HitFS, Hit.ImpactPoint)
        if self.bCanBlast and self.Collapse then
            self:Collapse(Hit.Component)
        end

        if self.bCanBlast then            
            if self.BreakAkEvent and self.BreakAkEvent:IsValid() then                
                local PostEventAtLocationAsyncNode =  UE.UPostEventAtLocationAsync.PostEventAtLocationAsync(Hit.Component, self.BreakAkEvent, Hit.ImpactPoint, UE.FRotator(0, 0, 0))
                PostEventAtLocationAsyncNode:Activate()                
            end            
        end

    end
end


return RegisterActor(BlastBuildingActor)
