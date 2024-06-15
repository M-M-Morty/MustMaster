--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BP_BaseNPC_C
require "UnLua"

local BPConst = require("common.const.blueprint_const")
local Actor = require("common.actor")

local BaseNPC = Class(Actor)


function BaseNPC:GetSaveDataClass()
    return BPConst.GetBaseNPCSaveDataClass()
end

function BaseNPC:LoadFromSaveData(SaveData)
    self:SetActorHiddenInGame(SaveData.bHiddenInGame)
end

function BaseNPC:SaveToSaveData(SaveData)
    SaveData.bHiddenInGame = self.bHidden
end


-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function BaseNPC:ReceiveBeginPlay()
    Super(BaseNPC).ReceiveBeginPlay(self)
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

return BaseNPC
