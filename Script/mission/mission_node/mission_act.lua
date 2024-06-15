--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")

---@type BP_MissionAct_C
local MissionAct = UnLua.Class()

function MissionAct:OnSubGraphStart()
    G.log:debug("xaelpeng", "MissionAct:OnSubGraphStart MissionActID:%d|%d", self:GetMissionGroupID(), self:GetMissionActID())
    self:GetDataComponent():OnMissionActStart(self:GetMissionIdentifier())
end

function MissionAct:OnSubGraphFinish()
    G.log:debug("xaelpeng", "MissionAct:OnSubGraphFinish MissionActID:%d|%d", self:GetMissionGroupID(), self:GetMissionActID())
    self:GetDataComponent():OnMissionActFinish(self:GetMissionIdentifier())
end


return MissionAct