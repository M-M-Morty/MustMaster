--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

---@type BP_NpcIntentionComponent_C
local NpcIntentionComponent = Component(ComponentBase)

function NpcIntentionComponent:Initialize(Initializer)
    Super(NpcIntentionComponent).Initialize(self, Initializer)
end

function NpcIntentionComponent:ReceiveBeginPlay()
    Super(NpcIntentionComponent).ReceiveBeginPlay(self)
end

function NpcIntentionComponent:InNormal()
    return self.Intention == Enum.BPE_NpcIntentionType.Normal
end

function NpcIntentionComponent:InMission()
    return self.Intention == Enum.BPE_NpcIntentionType.Mission
end

function NpcIntentionComponent:InBattle()
    return self.Intention == Enum.BPE_NpcIntentionType.Battle
end

-- server
function NpcIntentionComponent:ChangeIntention(NewIntension)
    self.Intention = NewIntension
    self.EventOnIntentionChange:Broadcast(self.Intention)
end

function NpcIntentionComponent:OnRep_Intention()
    self.EventOnIntentionChange:Broadcast(self.Intention)
end

return NpcIntentionComponent
