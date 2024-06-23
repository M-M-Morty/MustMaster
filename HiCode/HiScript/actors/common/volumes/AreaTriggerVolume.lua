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
local TriggerVolumeEventManager = require("actors.common.volumes.TriggerVolumeEventManager")

---@type BP_AreaTriggerVolume_C
local AreaTriggerVolume = Class(Actor)

function AreaTriggerVolume:Initialize(...)
    Super(AreaTriggerVolume).Initialize(self, ...)
    self.bBeginPlay = false
    self.bEndPlay = false
    self.bPlayerInSide = false
    self.OverlapBeforeActorReady = {}
end


function AreaTriggerVolume:ReceiveBeginPlay()
    Super(AreaTriggerVolume).ReceiveBeginPlay(self)   
    self.bBeginPlay = true
    self.bEndPlay = false
    self.bPlayerInSide = false
    --G.log:info("[hycoldrain]", "AreaTriggerVolume:ReceiveBeginPlay-- [%s] [%s]",  G.GetDisplayName(self), #self.OverlapBeforeActorReady)
    for _, OverlapEventFunction in ipairs(self.OverlapBeforeActorReady) do
        OverlapEventFunction()
    end
end

function AreaTriggerVolume:ReceiveEndPlay(Reason)    
    --G.log:info("[hycoldrain]", "AreaTriggerVolume:ReceiveEndPlay-- [%s] [%s] [%s]",  G.GetDisplayName(self), G.GetDisplayName(G.GetPlayerCharacter(self, 0)), tostring(self.bPlayerInSided))
    if self.bPlayerInSide then
        local CurPlayer = G.GetPlayerCharacter(self, 0)
        TriggerVolumeEventManager:PlayerEndOverlap(self, CurPlayer)
    end
    self.bEndPlay = true
    self.bBeginPlay = false
    self.bPlayerInSide = false
    Super(AreaTriggerVolume).ReceiveEndPlay(self, Reason)    
end


function AreaTriggerVolume:FilterClientPlayer(InActor)
    local bClientActor = not UE.UKismetSystemLibrary.IsServer(InActor)      
    local isFrontPlayer  = InActor:IsPlayer() and InActor:GetLocalRole() == UE.ENetRole.ROLE_AutonomousProxy
    return isFrontPlayer and (bClientActor or UE.UKismetSystemLibrary.IsStandalone(InActor))
end


function AreaTriggerVolume:ReceiveActorBeginOverlap(OtherActor)
    --G.log:info("[hycoldrain]", "AreaTriggerVolume:OnEnter--- [%s] [%s] isReady:[%s]", G.GetDisplayName(self), G.GetDisplayName(OtherActor), self.bBeginPlay)
    local function _BeginOverlap()
        if OtherActor and OtherActor:IsValid() then
            if self:FilterClientPlayer(OtherActor) then
                self.bPlayerInSide = true
                TriggerVolumeEventManager:PlayerBeginOverlap(self, OtherActor)                
            end
        end
    end
    
    if self.bBeginPlay then
        _BeginOverlap()
    else
        table.insert(self.OverlapBeforeActorReady, _BeginOverlap)
    end
end

function AreaTriggerVolume:ReceiveActorEndOverlap(OtherActor)
    --G.log:info("[hycoldrain]", "AreaTriggerVolume:OnLeave--- [%s], [%s], is end play[%s]", G.GetDisplayName(self), G.GetDisplayName(OtherActor), tostring(self.bEndPlay))
    if not self.bEndPlay then
        if OtherActor and OtherActor:IsValid() then
            if self:FilterClientPlayer(OtherActor) then          
                --self:SendMessage("OnPlayerLeaveTrigger", OtherActor)      
                self.bPlayerInSide = false    
                TriggerVolumeEventManager:PlayerEndOverlap(self, OtherActor)
            end
        end
    end
end

return RegisterActor(AreaTriggerVolume)
