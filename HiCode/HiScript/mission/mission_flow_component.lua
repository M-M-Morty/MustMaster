--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local SubsystemUtils = require("common.utils.subsystem_utils")

---@type BP_MissionFlowComponent_C
local MissionFlowComponent = Component(ComponentBase)
local decorator = MissionFlowComponent.decorator

function MissionFlowComponent:Initialize(Initializer)
end

function MissionFlowComponent:ReceiveBeginPlay()
end

function MissionFlowComponent:OnLoadFromDatabase(GameplayProperties)
    G.log:debug("xaelpeng", "MissionFlowComponent:OnLoadFromDatabase %s AssetLength:%d", self:GetName(), self.AssetSaveList:Length())
end

function MissionFlowComponent:OnSaveToDatabase(GameplayProperties)
    G.log:debug("xaelpeng", "MissionFlowComponent:OnSaveToDatabase %s AssetLength:%d", self:GetName(), self.AssetSaveList:Length())
    self:SaveMissionRootFlow()
end

return MissionFlowComponent
