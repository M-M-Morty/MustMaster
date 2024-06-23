local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local G = require("G")

local AIClusterComponent = Component(ComponentBase)

local decorator = AIClusterComponent.decorator

decorator.message_receiver()
function AIClusterComponent:OnServerReady()
    self.BattleSignal = {}
    self.BattleSignalCheckTimerHandler = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.BattleSignalCheckTimer}, 2, true)
end

function AIClusterComponent:ReceiveEndPlay()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.BattleSignalCheckTimerHandler)
end

decorator.message_receiver()
function AIClusterComponent:OnReceiveTick(DeltaSeconds)
    if not self.actor:IsServer() then
        return
    end

    self.SendSignalDeltaTime = self.SendSignalDeltaTime - DeltaSeconds

    if self.SendSignalDeltaTime < 0 then
        self:BattleSignalManager()
        if math.random(0, 1) == 1 then
            self.SendSignalDeltaTime = self.SendSignalCD + 0.5
        else
            self.SendSignalDeltaTime = self.SendSignalCD - 0.5
        end
    end
end

function AIClusterComponent:BattleSignalManager()
    local Targets = self.actor.BattleStateComponent:GetBattles()
    if Targets:Length() == 0 then
        return
    end

    local LuckyGuy, MaxScore = nil, -1
    local NowMS = G.GetNowTimestampMs()

    local Array = Targets:ToArray()
    for i = 1, Array:Length() do
        local Target = Array:Get(i)
        if not SkillUtils.IsBoss(Target) then
            -- boss不接受攻击信号
            if self:CanTargetReceiveBattleSignal(Target) then
                local Score = self:CalculateScore(Target, NowMS)
                if Score > MaxScore then
                    LuckyGuy, MaxScore = Target, Score
                end
            end
        end
    end

    if LuckyGuy ~= nil then
        self:SendBattleSignal(LuckyGuy, NowMS)
        -- UE.UKismetSystemLibrary.DrawDebugLine(self.actor, self.actor:K2_GetActorLocation(), LuckyGuy:K2_GetActorLocation(), UE.FLinearColor(0, 0, 1), 1.5)

        -- G.log:error("yj", "AIClusterComponent:OnGetAllBattleTarget %s", LuckyGuy:GetDisplayName())
        -- G.log:error("yj", "AIClusterComponent #############################################")
    end
end

function AIClusterComponent:CalculateScore(Target, NowMS)
    -- 距离得分
    local Score1 = math.min(1000, 200000/math.max(200, self.actor:GetDistanceTo(Target)))

    -- 威胁度得分
    local Score2 = 0
    if Target.MonsterType == Enum.Enum_MonsterType.Elite then
        Score2 = 1000
    end

    -- 玩家目标得分
    local Score3 = 0
    if self.LastDamageTarget == Target then
        Score3 = 200
    end

    -- 是否屏幕内得分
    local Score4 = 0
    local CameraForward = UE.UKismetMathLibrary.Normal(UE.UKismetMathLibrary.Conv_RotatorToVector(self.actor:GetCameraRotation()))
    local ToTargetForward = UE.UKismetMathLibrary.Normal(Target:K2_GetActorLocation() - self.actor:GetCameraLocation())
    local Dot = UE.UKismetMathLibrary.Dot_VectorVector(CameraForward, ToTargetForward)
    if Dot > 0 then
        Score4 = 1000
    end

    -- 距离上次攻击间隔得分
    local Score5 = 0
    local LastUseSkillTime = Target:GetAIServerComponent().LastUseSkillTime
    Score5 = (NowMS - LastUseSkillTime) / 1000 * 100


    -- 调整系数
    local Coefficient = 1.0
    if LastUseSkillTime + 5000 > NowMS then
        Coefficient = 0.1
    end

    -- G.log:debug("yj", "AIClusterComponent:CalculateScore.%s = %s %s * (%s + %s + %s + %s + %s)", 
    --     Coefficient * (Score1 + Score2 + Score3 + Score4 + Score5), Target:GetDisplayName(), Coefficient, Score1, Score2, Score3, Score4, Score5)
    return Coefficient * (Score1 + Score2 + Score3 + Score4 + Score5)
end

decorator.message_receiver()
function AIClusterComponent:OnDamageOther(Damage, BeDamageActor)
    self.LastDamageTarget = BeDamageActor
end

decorator.message_receiver()
function AIClusterComponent:AddPlaceHolderScore(Value)
    self.PlaceHolderScore = self.PlaceHolderScore + Value
end

decorator.message_receiver()
function AIClusterComponent:SubPlaceHolderScore(Value)
    self.PlaceHolderScore = self.PlaceHolderScore - Value
end

decorator.message_receiver()
function AIClusterComponent:OnEliteTargetDead(Target)
    local Targets = self.actor.BattleStateComponent.Targets
    local Array = Targets:ToArray()
    for i = 1, Array:Length() do
        local Target = Array:Get(i)
        Target:SendMessage("EnterStressState", Enum.Enum_ClusterStressSubState.EliteDead)
    end
end

function AIClusterComponent:GetTargetPlaceHolderScoreNeeded(Target)
    if Target.MonsterType == Enum.Enum_MonsterType.Elite then
        return 1.5
    else
        return 1
    end
end

function AIClusterComponent:CanTargetReceiveBattleSignal(Target)
    if Target.State.state == Enum.Enum_MonsterBattleState.BattleAttack then
        -- 战斗攻击状态下不接受攻击信号
        return false
    end

    if self.PlaceHolderScore < self:GetTargetPlaceHolderScoreNeeded(Target) then
        -- 占位不够，无法接受攻击信号
        return false
    end

    return self.BattleSignal:Find(Target) == nil
end

function AIClusterComponent:SendBattleSignal(Target, NowMS)
    local BSI = Struct.UD_BattleSignalInfo()
    BSI.TimeMs = NowMS
    BSI.Score = self:GetTargetPlaceHolderScoreNeeded(Target)
    self.BattleSignal:Add(Target, BSI)

    self:SubPlaceHolderScore(BSI.Score)
    Target:SendMessage("ReceiveBattleSignal", self.actor)

    G.log:debug("yj", "AIClusterComponent:SendBattleSignal %s cost place holder score.%s remain.%s", Target:GetDisplayName(), BSI.Score, self.PlaceHolderScore)
end

decorator.message_receiver()
function AIClusterComponent:RecycleBattleSignal(Target)
    -- 信号归还有两处：
    -- 1.超时归还 - 攻击时间超过MaxSignalHolderTime或SignalHolerTime
    -- 2.主动归还 - 怪物离开战斗攻击状态
    local BSI = self.BattleSignal:Find(Target)
    if BSI == nil then
        return
    end

    self:AddPlaceHolderScore(BSI.Score)
    self.BattleSignal:Remove(Target)

    G.log:debug("yj", "AIClusterComponent:RecycleBattleSignal %s recycle place holder score.%s remain.%s", Target:GetDisplayName(), BSI.Score, self.PlaceHolderScore)
end

function AIClusterComponent:BattleSignalCheckTimer()
    local NowMS = G.GetNowTimestampMs()
    local NeedReturnBattleSignal = {}
    local Targets = self.BattleSignal:Keys()
    for i = 1, Targets:Length() do
        local Target = Targets:Get(i)
        local v = self.BattleSignal:Find(Target)
        local DeltaTimeMs = NowMS - v.TimeMs
        if Target then
            if Target:GetAIServerComponent() == nil then
                table.insert(NeedReturnBattleSignal, Target)
            elseif DeltaTimeMs > math.min(Target:GetAIServerComponent().SignalHolderTime, self.MaxSignalHolderTime) * 1000 then
                if DeltaTimeMs > self.MaxSignalHolderTime * 1000 then
                    G.log:warn("yj", "AIClusterComponent:BattleSignalCheckTimer target(%s) signal holder time(%s) too long!!!", Target:GetDisplayName(), DeltaTimeMs)
                end
                table.insert(NeedReturnBattleSignal, Target)
            end 
        end
    end

    for idx, Target in pairs(NeedReturnBattleSignal) do
        self:RecycleBattleSignal(Target)
        if Target:IsValid() then
            Target:SendMessage("ReturnBattleSignal")
        end
    end
end

return AIClusterComponent
