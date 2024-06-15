--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type MissionManager_C
local MissionManager = UnLua.Class()
local G = require("G")
local BPConst = require("common.const.blueprint_const")
local GlobalActorConst = require("common.const.global_actor_const")
local SubsystemUtils = require("common.utils.subsystem_utils")

-- function M:Initialize(Initializer)
-- end
MissionManager.EntityServiceName = ""
MissionManager.EntityPropertyMessageName = "MissionManager"

function MissionManager:GetGlobalName()
    return GlobalActorConst.MissionManager
end

function MissionManager:GetActorSaveComponents(Components)
    Components:Add(self:GetFlowBPComponent())
    Components:Add(self:GetDataBPComponent())
end

function MissionManager:OnPreInitializeComponents()
    if self:HasAuthority() then
        local World = UE.UHiUtilsFunctionLibrary.GetGWorld()
        local WorldSettings = World:K2_GetWorldSettings()
        G.log:debug("xaelpeng", "MissionManager:OnPreInitializeComponents %s %s", self:GetName(), WorldSettings.MissionRootFlow)
        if WorldSettings.MissionRootFlow ~= nil then
            self.BP_MissionFlowComponent.RootFlow = WorldSettings.MissionRootFlow
            WorldSettings.MissionRootFlow:RegisterMissionIdentifiers(self)
        end
    end
end

function MissionManager:OnLoadFromDatabase(GameplayProperties)
    local FlowComponent = self:GetFlowBPComponent()
    G.log:debug("xaelpeng", "MissionManager:OnLoadFromDatabase %s", self:GetName())
end

function MissionManager:OnSaveToDatabase(GameplayProperties)
    G.log:debug("xaelpeng", "MissionManager:OnSaveToDatabase %s", self:GetName())
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

return MissionManager
