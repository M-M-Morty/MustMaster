--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")

---@type BP_Mission_C
local Mission = UnLua.Class()

function Mission:OnSubGraphStart()
    G.log:debug("xaelpeng", "Mission:OnSubGraphStart MissionID:%d|%d|%d", self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID())
    self:GetDataComponent():OnMissionStart(self:GetMissionIdentifier())
end

function Mission:OnSubGraphFinish()
    G.log:debug("xaelpeng", "Mission:OnSubGraphFinish MissionID:%d|%d|%d", self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID())
    self:GetDataComponent():OnMissionFinish(self:GetMissionIdentifier())
end

return Mission