--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local BaseNode = require("audio.statemachine.BaseNode")

---@type State_PlayGBM_C
local State_PlayGBM = Class(BaseNode)

function State_PlayGBM:OnStateUpdate(DeltaSeconds)    
    local Blackboard = self:GetBlackBoard()
    if Blackboard then        
        if Blackboard.bAmbientSoundDirty then            
            Blackboard.bAmbientSoundDirty = false
            if not Blackboard.bStopAmbientSound then
                self:PlayAmbientSound(Blackboard.AmbientSound)
            else
                self:StopAmbientSound(Blackboard.AmbientSound)
            end
        end

        if Blackboard.bBGMDirty then
            G.log:info("hycoldrain", "State_PlayGBM:OnStateUpdate  ")
            Blackboard.bBGMDirty = false
            if not Blackboard.bStopBGM then
                self:PlayBackgroundMusic(Blackboard.BGM)
            else
                self:StopBackgroundMusic(Blackboard.BGM)
            end
        end
    end
end

function State_PlayGBM:PlayAmbientSound(AmbientSound)        
    G.log:info("hycoldrain", "State_PlayGBM:OnStateUpdate   play AmbientSound DataAsset  %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(AmbientSound))   
    local GameState = self:GetContext()
    if GameState then                                        
        GameState:SendClientMessage("Event_PlayBackgroundDataAsset", AmbientSound)            
    end  
end

function State_PlayGBM:StopAmbientSound(AmbientSound)
    local GameState = self:GetContext()
    if GameState then                                        
        GameState:SendClientMessage("Event_StopBackgroundDataAsset", AmbientSound)            
    end
end

function State_PlayGBM:PlayBackgroundMusic(BGM)    
    G.log:info("hycoldrain", "State_PlayGBM:OnStateUpdate  Play Background Music DataAsset   %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(BGM))   
    local GameState = self:GetContext()
    if GameState then                                        
        GameState:SendClientMessage("Event_PlayBackgroundDataAsset", BGM)            
    end   
end

function State_PlayGBM:StopBackgroundMusic(BGM)
    local GameState = self:GetContext()
    if GameState then                                        
        GameState:SendClientMessage("Event_StopBackgroundDataAsset", BGM)            
    end
end


function State_PlayGBM:OnStateEnd()
    if self:IsEndState() then
        G.log:info("hycoldrain", " State_PlayGBM:OnStateEnd()    %s", self:GetNodeName())   

        local Blackboard = self:GetBlackBoard()
        if Blackboard then
            self:StopBackgroundMusic(Blackboard.BGM)        
            self:StopAmbientSound(Blackboard.AmbientSound)           
        end      
    end
end

return State_PlayGBM