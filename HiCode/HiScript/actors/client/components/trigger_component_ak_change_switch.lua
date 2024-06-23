--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

---@type BP_AkComponent_C

local TriggerComponentAkChangeSwitch = Component(ComponentBase)

function TriggerComponentAkChangeSwitch:FilterClientPlayer(InActor)
    G.log:debug("hycoldrain", "TriggerComponentAkChangeSwitch:FilterClientPlayer %s ", G.GetDisplayName(self.actor))
    local bClientPlayer = InActor:IsClient() and InActor:IsPlayer() 
    return self.actor:IsTargetActorValidToNotify(InActor) and (bClientPlayer or UE.UKismetSystemLibrary.IsStandalone(InActor))
end


function TriggerComponentAkChangeSwitch:ReviceComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)    
    if OtherActor and OtherActor:IsValid() then      
        if self:FilterClientPlayer(OtherActor) then  
            local GameState = UE.UGameplayStatics.GetGameState(OtherActor)
            if GameState then                        
                --G.log:info("[hycoldrain]", "TriggerComponentAkChangeSwitch:ReviceComponentBeginOverlap--- [%s], [%s]", G.GetDisplayName(self.BGM), G.GetDisplayName(GameState))         
                GameState:SendClientMessage("Event_PlayBackgroundDataAsset", self.BGM)
                GameState:SendClientMessage("Event_PlayBackgroundDataAsset", self.AmbientSound)            
            end                
        end
    end
end

function TriggerComponentAkChangeSwitch:ReviceComponentEndOverlap(OverlappedComp, OtherActor, OtherComp, OtherBodyIndex)    
    if OtherActor and OtherActor:IsValid() then 
        if self:FilterClientPlayer(OtherActor) then
            --G.log:debug("hycoldrain", "ReviceComponentEndOverlap %s   %s ", G.GetDisplayName(self.AttachParent), G.GetDisplayName(self.AttachParent.BGM))    
            if self.AttachParent and self.AttachParent:IsValid() then                
                if self:FilterClientPlayer(OtherActor) then  
                    local GameState = UE.UGameplayStatics.GetGameState(OtherActor)
                    if GameState then                  
                        GameState:SendClientMessage("Event_PlayBackgroundDataAsset", self.AttachParent.BGM)
                        GameState:SendClientMessage("Event_PlayBackgroundDataAsset", self.AttachParent.AmbientSound)           
                    end
                end
            end                     
        end
    end
end

return TriggerComponentAkChangeSwitch
