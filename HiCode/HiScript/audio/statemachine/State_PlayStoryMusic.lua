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
            local AmbientSound = Blackboard.AmbientSound
            if AmbientSound then
                G.log:info("hycoldrain", "State_PlayGBM:OnStateUpdate   play AmbientSound DataAsset  %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(AmbientSound))   
            end
        end

        if Blackboard.bBGMDirty then
            Blackboard.bBGMDirty = false
            local BGM = Blackboard.BGM
            if BGM then
                G.log:info("hycoldrain", "State_PlayGBM:OnStateUpdate  Play Background Music DataAsset   %s %s", self:GetNodeName(), UE.UKismetSystemLibrary.GetDisplayName(BGM))   
            end
        end
    end
end

return State_PlayGBM