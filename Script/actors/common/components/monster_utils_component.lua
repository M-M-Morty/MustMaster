require "UnLua"

local G = require("G")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local t = require("t")

local MonsterUtilsComponent = Component(ComponentBase)

local decorator = MonsterUtilsComponent.decorator

decorator.message_receiver()
function MonsterUtilsComponent:OnHeavyBeJudgeEnded()
    local Controller = self.actor:GetController()
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    if not BB then
        return
    end

    local Target = BB:GetValueAsObject("TargetActor")
    if Target then
	    Target:Client_SendMessage("PlayBossDeadLevelSequence")
	end
end


return MonsterUtilsComponent
