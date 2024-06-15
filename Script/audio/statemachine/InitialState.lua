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

---@type S_Initial_C
local S_Initial = Class(BaseNode)


function S_Initial:OnStateBegin()
    --G.log:info("hycoldrain", "S_Initial:EventOnStateBegin %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(self.AkEvent))
    local InActor = self:GetContext()
    if self.AkEvent and self.AkEvent:IsValid() then
        G.log:info("hycoldrain", "S_Initial:EventOnStateBegin  play akevent %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(self.AkEvent))
        --UE.UAkGameplayStatics.PostEvent(self.AkEvent, InActor, 0, nil)  
    end
    if self.AkSwitch and self.AkSwitch:IsValid() then     
        G.log:info("hycoldrain", "S_Initial:EventOnStateBegin  set switch   %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(self.AkSwitch))   
        --UE.UAkGameplayStatics.SetSwitch(self.AkSwitch, InActor, "None", "None")
    end
    if self.AkState and self.AkState:IsValid() then
        G.log:info("hycoldrain", "S_Initial:EventOnStateBegin  set sate %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(self.AkState))
        --UE.UAkGameplayStatics.SetState(self.AkState, "None", "None")
    end
end

return S_Initial