--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")

---@type BP_MissionGroup_C
local MissionGroup = UnLua.Class()

function MissionGroup:OnSubGraphStart()
    G.log:debug("xaelpeng", "MissionGroup:OnSubGraphStart MissionGroupID:%d", self:GetMissionGroupID())
    self:GetDataComponent():OnMissionGroupStart(self:GetMissionIdentifier())
end

function MissionGroup:OnSubGraphFinish()
    G.log:debug("xaelpeng", "MissionGroup:OnSubGraphFinish MissionGroupID:%d", self:GetMissionGroupID())
    self:GetDataComponent():OnMissionGroupFinish(self:GetMissionIdentifier())
end


return MissionGroup