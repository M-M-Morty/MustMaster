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
local utils = require("common.utils")

---@type BGMComponent_C
local BGMComponent = Component(ComponentBase)
local decorator = BGMComponent.decorator

decorator.message_receiver()
function BGMComponent:OnPlayerEnterTrigger(InActor)        
    if InActor:IsClient() and InActor:IsPlayer() then           
        local GameState = UE.UGameplayStatics.GetGameState(InActor)
        if GameState then                                    
            if GameState. bBeginPlay then
                G.log:info("[hycoldrain]", "BGMComponent:OnPlayerEnterTrigger--- [%s], [%s]", G.GetDisplayName(self.BGM), G.GetDisplayName(GameState)) 
                GameState:SendClientMessage("SetBGM", self.BGM, false)
                GameState:SendClientMessage("SetAmbientSound", self.AmbientSound, false)            
            else
                -- bind delegate
                G.log:info("[hycoldrain]", "BGMComponent: bind delegate--- [%s], [%s]", G.GetDisplayName(self.BGM), G.GetDisplayName(GameState)) 
                GameState.BeginPlayDelegate:Add(self, self.SetBackgroundMusicWhenBeginPlay)
            end
        end        
    end
end

function BGMComponent:SetBackgroundMusicWhenBeginPlay(InGameState)
    InGameState:SendClientMessage("SetBGM", self.BGM, false)
    InGameState:SendClientMessage("SetAmbientSound", self.AmbientSound, false)     
    InGameState.BeginPlayDelegate:Remove(self, self.SetBackgroundMusicWhenBeginPlay)       
end


decorator.message_receiver()
function BGMComponent:OnPlayerLeaveTrigger(InActor)  
    if InActor:IsClient() and InActor:IsPlayer() then           
        local GameState = UE.UGameplayStatics.GetGameState(InActor)
        if GameState then                        
            G.log:info("[hycoldrain]", "BGMComponent:OnPlayerLeaveTrigger--- [%s], [%s]", G.GetDisplayName(self.BGM), G.GetDisplayName(GameState))         
            GameState:SendClientMessage("SetBGM", self.BGM, true)           
            GameState:SendClientMessage("SetAmbientSound", self.AmbientSound, true)            
        end        
    end
end


function BGMComponent:Stop()
    Super(BGMComponent).Stop(self)

    --G.log:debug("devin", "BGMComponent:Stop")
end

return BGMComponent
