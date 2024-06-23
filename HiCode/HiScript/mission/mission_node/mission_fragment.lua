--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")

---@type BP_MissionFragment_C
local MissionFragment = UnLua.Class()

function MissionFragment:OnSubGraphStart()
    G.log:debug("xaelpeng", "MissionFragment:OnSubGraphStart MissionID:%d|%d|%d", self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID())
    self:GetDataComponent():OnMissionEventStart(self:GetMissionIdentifier(), self.MissionFragmentID)
end

function MissionFragment:OnSubGraphFinish()
    G.log:debug("xaelpeng", "MissionFragment:OnSubGraphFinish MissionID:%d|%d|%d", self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID())
    self:GetDataComponent():OnMissionEventFinish(self:GetMissionIdentifier(), self.MissionFragmentID)
end

function MissionFragment:OnFinishedInputNamesUpdate()
    G.log:debug("xaelpeng", "MissionFragment:OnFinishedInputNamesUpdate MissionID:%d|%d|%d", self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID())
    local Progress = self.FinishedInputNames:Length()
    self:GetDataComponent():OnMissionEventProgressUpdate(self:GetMissionIdentifier(), self.MissionFragmentID, Progress)

end

return MissionFragment
