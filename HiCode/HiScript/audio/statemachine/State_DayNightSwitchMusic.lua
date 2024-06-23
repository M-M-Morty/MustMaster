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

---@type S_State_DayNightSwitchMusic_C
local State_DayNightSwitchMusic = Class(BaseNode)


function State_DayNightSwitchMusic:OnStateBegin()
    --G.log:info("hycoldrain", "State_DayNightSwitchMusic:EventOnStateBegin %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(self.AkSwitchValue))

    local Blackboard = self:GetBlackBoard()    
    if Blackboard.AmbientSound or Blackboard.BGM then
        local InActor = self:GetContext()
        if InActor and InActor:IsValid() then
            if self.AkSwitchValue and self.AkSwitchValue:IsValid() then
                UE.UAkGameplayStatics.SetSwitch(self.AkSwitchValue, InActor, "None", "None")
            end
        end 
    end
           
end

return State_DayNightSwitchMusic