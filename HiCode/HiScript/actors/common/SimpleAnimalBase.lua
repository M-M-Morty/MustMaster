--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BP_SimpleAnimal_Base_C
require "UnLua"
local G = require("G")


local BPConst = require("common.const.blueprint_const")
local ActorBase = require("actors.common.NPC")

local SimpleAnimalBase = Class(ActorBase)
local utils = require("common.utils")

function SimpleAnimalBase:ReceiveBeginPlay()
    Super(SimpleAnimalBase).ReceiveBeginPlay(self)
    local Controller0 = UE.UAIBlueprintHelperLibrary.GetAIController(self)
    local Controller = self:GetController()
    self:LogInfo("zsf", "SimpleAnimalBase %s %s %s", Controller0, Controller, self.BehaviorTree)
    if Controller then
        Controller:StopBehaviorTree()
        Controller:RunBehaviorTree(self.BehaviorTree)
    end
end


return SimpleAnimalBase

