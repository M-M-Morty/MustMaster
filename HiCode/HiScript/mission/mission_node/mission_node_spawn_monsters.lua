--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local EdUtils = require("common.utils.ed_utils")
local BPConst = require("common.const.blueprint_const")

local MissionNodeBase = require("mission.mission_node.mission_node_base")

---@type BP_MissionNode_SpawnMonsters_C
local MissionNodeSpawnMonsters = Class(MissionNodeBase)

function MissionNodeSpawnMonsters:K2_InitializeInstance()
    Super(MissionNodeSpawnMonsters).K2_InitializeInstance(self)
    self.SpawnActionName = "Spawn"
    local ActionClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionSpawnMonster)
    if ActionClass then
        local Action = NewObject(ActionClass)
        Action.Name = self.SpawnActionName
        Action.SpawnClass = self.spawnClass
        Action.Tag = self.Tag
        Action.Lifetime = self.Lifetime
        Action.bLimited = self.bLimited
        for i = 1, self.SpawnerList:Length() do
            local Spawner = self.SpawnerList:GetRef(i)
            Action.TargetActorIDList:Add(Spawner.ID)
        end
        self:RegisterAction(Action)
    end
end

function MissionNodeSpawnMonsters:K2_ExecuteInput(PinName)
    Super(MissionNodeSpawnMonsters).K2_ExecuteInput(self, PinName)
    self:TriggerOutput(self.SuccessPin, false, false)
    UE.UHiMissionAction_Base.RunMissionActionByName(self, self.SpawnActionName)
    self:TriggerOutput(self.SpawnedPin, true, false)
end

return MissionNodeSpawnMonsters