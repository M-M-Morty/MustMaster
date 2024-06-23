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

---@type State_PlayBattleMusic
local State_PlayBattleMusic = Class(BaseNode)


function State_PlayBattleMusic:OnStateBegin()
    --G.log:info("hycoldrain", "State_PlayBattleMusic:EventOnStateBegin %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(self.AkEvent))
    local InActor = self:GetContext()
    if self.AkEvent and self.AkEvent:IsValid() then
        --G.log:info("hycoldrain", "State_PlayBattleMusic:EventOnStateBegin  play akevent %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(self.AkEvent))
        UE.UAkGameplayStatics.PostEvent(self.AkEvent, InActor, 0, nil)  
    end
    if self.AkSwitch and self.AkSwitch:IsValid() then     
        --G.log:info("hycoldrain", "State_PlayBattleMusic:EventOnStateBegin  set switch   %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(self.AkSwitch))   
        UE.UAkGameplayStatics.SetSwitch(self.AkSwitch, InActor, "None", "None")
    end
    if self.AkState and self.AkState:IsValid() then
        --G.log:info("hycoldrain", "State_PlayBattleMusic:EventOnStateBegin  set sate %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(self.AkState))
        UE.UAkGameplayStatics.SetState(self.AkState, "None", "None")
    end
end


function State_PlayBattleMusic:OnStateEnd()
    if self:IsEndState() then
        G.log:info("hycoldrain", " State_PlayBattleMusic:OnStateEnd()    %s", self:GetNodeName())   

        if self.StopAkEvent and self.StopAkEvent:IsValid() then
            --G.log:info("hycoldrain", "State_PlayBattleMusic:EventOnStateBegin  play akevent %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(self.AkEvent))
            UE.UAkGameplayStatics.PostEvent(self.StopAkEvent, self:GetContext(), 0, nil)  
        end

    end
end


return State_PlayBattleMusic