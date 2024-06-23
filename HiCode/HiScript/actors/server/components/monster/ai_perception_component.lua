local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local G = require("G")

local AIPerceptionComponent = Component(ComponentBase)

local decorator = AIPerceptionComponent.decorator

-- 放弃UE的视觉感知，原因如下:
-- 1.UE的视觉感知对切人不友好，切人时一定会先lose target然后再discover target
-- 2.UE的视觉感知对大世界不友好，在复杂场景中很容易被挡住出视野


function AIPerceptionComponent:PerceptionForAlert()
    -- 目前只有距离感知
    return self:ChoiceTarget(self:GetAlertDis())
end

function AIPerceptionComponent:PerceptionForPursue()
    -- 目前只有距离感知
    return self:ChoiceTarget(self:GetPursueDis())
end

function AIPerceptionComponent:ChoiceTarget(ToleranceDis)
    local SelfLocation = self.actor:K2_GetActorLocation()
    local MinDis, TargetActor = 99999, nil

    local function _ChoiceTarget(Targets)
        for idx, Target in pairs(Targets) do
            if Target and SkillUtils.IsEnemy(self.actor, Target) then
                local Dis = self.actor:GetDistanceTo(Target)
                local TargetLocation = Target:K2_GetActorLocation()
                local AllAvatarDead = false;
                if Target.PlayerState and Target.PlayerState:GetPlayerController() then
                    AllAvatarDead = Target.PlayerState:GetPlayerController().ControllerSwitchPlayerComponent:CheckAvatarAllDead();
                end

                -- G.log:error("yj", "MonsterBattleStateComponent %s - Dis(%s) < ToleranceDis(%s) = %s --- %s %s", Target, Dis, ToleranceDis, Dis < ToleranceDis, math.abs(SelfLocation.Z - TargetLocation.Z), self.MaxZDis)
                if Dis < ToleranceDis and Dis < MinDis and math.abs(SelfLocation.Z - TargetLocation.Z) < self.MaxZDis and not AllAvatarDead then
                    if not SkillUtils.IsBakAvatar(Target) then
                        MinDis = Dis
                        TargetActor = Target
                    end
                end
            end
        end
    end

    _ChoiceTarget(GameAPI.GetActorsWithTag(self.actor, "Player"))
    if TargetActor == nil then
        _ChoiceTarget(GameAPI.GetActorsWithTag(self.actor, "Monster"))
    end

    return TargetActor
end

function AIPerceptionComponent:GetAlertDis()
    return self.AlertDis
end

function AIPerceptionComponent:GetPursueDis()
    return self.PursueDis
end

function AIPerceptionComponent:GetInAttackDis()
    return self.InAttackDis
end

function AIPerceptionComponent:GetOutAttackDis()
    return self.OutAttackDis
end

-- TODO
decorator.message_receiver()
function AIPerceptionComponent:EnterBattleByFlowGraph()
    local Target = self:ChoiceTarget(self:GetPursueDis())
    if Target then
        self:SendMessage("TurnTo_StateBattlePursue", Target)
    end
end

return AIPerceptionComponent
