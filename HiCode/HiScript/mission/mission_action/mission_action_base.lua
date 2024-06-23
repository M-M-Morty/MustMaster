--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local GlobalActorConst = require("common.const.global_actor_const")
local BPConst = require("common.const.blueprint_const")
local EdUtils = require("common.utils.ed_utils")

---@type BP_MissionAction_Base_C
local MissionActionBase = UnLua.Class()

function MissionActionBase:OnInitialize(OwnerNode)
    G.log:debug("xaelpeng", "MissionActionBase:OnInitialize %s", self:GetName())
end


function MissionActionBase:OnActive()
    G.log:debug("xaelpeng", "MissionActionBase:OnActive %s", self:GetName())
    self.Overridden.OnActive(self)
end

function MissionActionBase:RunActionOnActorByID(ActorID, ActionParamStr)
    G.log:debug("xaelpeng", "MissionActionBase:RunActionOnActorByID %s ActorID:%s Param:%s", self:GetName(), ActorID,
        ActionParamStr)
    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:RunActionOnMutableActorByID(ActorID, self:GenerateActionInfo(ActionParamStr))
end

function MissionActionBase:RunActionOnActorByTag(Tag, ActionParamStr)
    G.log:debug("xaelpeng", "MissionActionBase:RunActionOnActorByTag %s Tag:%s Param:%s", self:GetName(), Tag,
        ActionParamStr)
    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:RunActionOnMutableActorByTag(Tag, self:GenerateActionInfo(ActionParamStr))
end

function MissionActionBase:GenerateActionInfo(ActionParamStr)
    local ActionInfoClass = EdUtils:GetUE5ObjectClass(BPConst.MissionActionInfo, true)
    local ActionInfo = ActionInfoClass()
    ActionInfo.ActionID = 0
    ActionInfo.Timestamp = os.time()
    ActionInfo.ActionType = UE.UHiBlueprintFunctionLibrary.GetObjectClassPath(self)
    ActionInfo.Param = ActionParamStr
    return ActionInfo
end


function MissionActionBase:Run(Actor, ActionParamStr)
    G.log:debug("xaelpeng", "MissionActionBase:Run %s Actor:%s Param:%s", self:GetName(), Actor:GetName(), ActionParamStr)
    self.Overridden.Run(self, Actor, ActionParamStr)
end


return MissionActionBase