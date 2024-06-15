--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local json = require("thirdparty.json")
local MissionActionOnActorBase = require("mission.mission_action.mission_action_onactor_base")
local SubsystemUtils = require("common.utils.subsystem_utils")

---@type BP_MissionAction_SpawnMonster_C
local MissionActionSpawnMonster = Class(MissionActionOnActorBase)

function MissionActionSpawnMonster:GenerateActionParam()
    local DestroyTime = 0
    if self.Lifetime > 0 then
        DestroyTime = self.Lifetime + os.time()
    end
    local Param = {
        Tag = self.Tag,
        SpawnClassType = UE.UHiBlueprintFunctionLibrary.GetClassPath(self.spawnClass),
        DestroyTime = DestroyTime,
        bLimited = self.bLimited,
    }
    return json.encode(Param)
end

function MissionActionSpawnMonster:Run(Actor, ActionParamStr)
    Super(MissionActionSpawnMonster).Run(self, Actor, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    local SpawnClass = UE.UObject.Load(Param.SpawnClassType)
    if Actor:HasAuthority() then
        local Lifetime = nil
        if Param.DestroyTime > 0 then
            Lifetime = Param.DestroyTime - os.time()
            if Lifetime <= 0 then
                Lifetime = 0.001
            end
        end
        SubsystemUtils.GetMutableActorSubSystem(self):SpawnNewRuntimeActor(SpawnClass, Actor:GetTransform(), Actor, Param.Tag, Lifetime)
    end

end

function MissionActionSpawnMonster:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

return MissionActionSpawnMonster
