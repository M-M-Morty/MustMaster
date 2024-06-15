--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local BPConst = require("common.const.blueprint_const")
local SubsystemUtils = require("common.utils.subsystem_utils")
local BaseItem = require("actors.common.interactable.base.base_item")


---@type BP_Spawner_C
local Spawner = Class(BaseItem)

function Spawner:Initialize(Initializer)
    Super(Spawner).Initialize(self, Initializer)
end

-- function M:UserConstructionScript()
-- end

-- function M:ReceiveBeginPlay()
-- end

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

function Spawner:Spawn(SpawnClass, Tag)
    G.log:debug("xaelpeng", "Spawner:Spawn Spawner:%s  Actor:%s", self:GetName(), SpawnClass:GetName())
    if self:HasAuthority() then
        SubsystemUtils.GetMutableActorSubSystem(self):SpawnNewRuntimeActor(SpawnClass, self:GetTransform(), self, Tag)
    end
end

return Spawner
