require "UnLua"

local G = require("G")

local utils = require("common.utils")
local ai_utils = require("common.ai_utils")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")

local AiComponent = Component(ComponentBase)

local decorator = AiComponent.decorator


decorator.message_receiver()
function AiComponent:OnServerReady()
    G.log:debug("yj", "AiComponent:OnServerReady AISwitch.%s IsClient.%s", self.actor.AISwitch, self.actor:IsClient())

    if not self.actor.AISwitch then
        self.actor:RemoveBlueprintComponent(self)
        return
    end

    self.BornLocation = self.actor:K2_GetActorLocation()

    self.ConfrontDis = self.ConfrontDis + math.random(-100, 100)
    
    self.LastUseSkillTime = G.GetNowTimestampMs()

    self:StartBT()
end

decorator.message_receiver()
function AiComponent:OnClientReady()
    self.actor:RemoveBlueprintComponent(self)
end

decorator.message_receiver()
function AiComponent:PostReceivePossessed()
    G.log:debug("yj", "AiComponent:PostReceivePossessed AISwitch.%s IsClient.%s", self.actor.AISwitch, self.actor:IsClient())

    -- Run on Server
    -- Component ReceivePossessed的顺序是不固定的...所以用PostReceivePossessed

    self:ListenBTSwitch()
end

decorator.message_receiver()
function AiComponent:OnReceiveTick(DeltaSeconds)
    self:FocusToTarget(DeltaSeconds)
end

function AiComponent:ListenBTSwitch()
    for Tag, SwitchInfo in pairs(self.BTSwitch:ToTable()) do
        -- G.log:error("yj", "AiComponent:ListenBTSwitch %s %s", Tag.TagName, Tag.TagName ~= "None")
        if Tag and Tag.TagName ~= "None" then
            self:RegisterGameplayTagCB(Tag.TagName, UE.EGameplayTagEventType.NewOrRemoved, "OnBTGamePlayTagNewOrRemove")
        else
            assert(false, string.format("AiComponent:ListenBTSwitch error %s", self.actor:GetDisplayName()))
        end
    end

    self:JudgeSwitch()
end

function AiComponent:OnBTGamePlayTagNewOrRemove(Tag, NewCount)
    self:JudgeSwitch()
end

function AiComponent:StartBT()

    self.actor:GetController():StopBehaviorTree()

    self:InitBTRuningData()
end

decorator.message_receiver()
function AiComponent:StopBT()
    G.log:debug("yj", "AiComponent:StopBT %s", self.BTName)
    self.actor:GetController():StopBehaviorTree()
    self.BTName = nil
end

decorator.message_receiver()
function AiComponent:PauseBT()
    if self.BTPauseRefCount == 0 then
        self.actor:GetController():PauseBehaviorTree("PauseBT")
    end

    self.BTPauseRefCount = self.BTPauseRefCount + 1
    G.log:debug("yj", "AiComponent:PauseBehaviorTree %s actor: %s, BTPauseRefCount.%s, onFloor: %s", self.BTName, G.GetObjectName(self.actor), self.BTPauseRefCount, self.actor:IsOnFloor())
end

decorator.message_receiver()
function AiComponent:ResumeBT()
    if self.actor:IsDead() then
        return
    end

    self.BTPauseRefCount = self.BTPauseRefCount - 1
    G.log:debug("yj", "AiComponent:ResumeBehaviorTree %s actor: %s, BTPauseRefCount.%s, onFloor: %s", self.BTName, G.GetObjectName(self.actor), self.BTPauseRefCount, self.actor:IsOnFloor())

    if self.BTPauseRefCount == 0 then
        self.actor:GetController():ResumeBehaviorTree("ResumeBT")
    end
end

function AiComponent:HasBTSwitchTag(Tag)
    if type(Tag) == "string" then
        Tag = UE.UHiGASLibrary.RequestGameplayTag(Tag)
    end
    return self.BTSwitch:Find(Tag) ~= nil
end

function AiComponent:JudgeSwitch()
    local MinPriority, BehaviorTree = -1, nil
    for Tag, SwitchInfo in pairs(self.BTSwitch:ToTable()) do
        if self.actor:GetAbilitySystemComponent():HasGameplayTag(Tag) then
            if SwitchInfo.priority > MinPriority then
                MinPriority = SwitchInfo.priority
                BehaviorTree = SwitchInfo.BehaviorTree
            end
        end
    end

    if BehaviorTree ~= nil then
        self:SwitchBT(BehaviorTree)
    else
        self.actor:GetController():StopBehaviorTree()
    end
end

decorator.message_receiver()
function AiComponent:SwitchBT(BT)

    local BTName = G.GetDisplayName(BT)
    if self.BTName == BTName then
        return
    end

    if BT == nil then
        G.log:error("yj", "AiComponent:SwitchBT nil")
        return
    end

    G.log:debug("yj", "AiComponent:SwitchBT %s Name.%s", BTName, self.actor:GetDisplayName())

    self:BeforeBTSwitch()

    self.actor:GetController():StopBehaviorTree()

    self:ResetBTRuningData()

    self.actor:GetController():RunBehaviorTree(BT)
    self.BTName = BTName
end

function AiComponent:InitBTRuningData()
    self.ObservePath = {}
    self.RatioLimits = {}
    self.BTCounters = {}
    self.BTTimers = {}
end

function AiComponent:ResetBTRuningData()
    self.ObservePath = {}
    self.RatioLimits = {}

    -- reset
    for k, v in pairs(self.BTCounters) do
        if v[2] == true then
            self.BTCounters[k][1] = 0
        end
    end
end

decorator.message_receiver()
function AiComponent:RegisterBTSwitchCB(TaskNode, Callback)
    if self.BTSwitchCB == nil then
        self.BTSwitchCB = {}
    end

    self.BTSwitchCB.TaskNode = TaskNode
    self.BTSwitchCB.Callback = Callback
end

function AiComponent:BeforeBTSwitch()
    if self.BTSwitchCB ~= nil then
        self.BTSwitchCB.Callback(self.BTSwitchCB.TaskNode, self.actor:GetController(), self.actor)
    end
    
    self.BTSwitchCB = nil
end

function AiComponent:FocusToTarget(DeltaSeconds)
    local Pawn = self.actor:GetInstigator()
    local Controller = Pawn:GetController()

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    if not BB then
        return
    end

    local Target = BB:GetValueAsObject("TargetActor")

    if not Target then
        Controller:K2_ClearFocus()
    else
        if self.actor.FocusMode == Enum.Enum_FocusMode.Normal then
            Controller:K2_SetFocus(Target)
        elseif self.actor.FocusMode == Enum.Enum_FocusMode.HeadToHead then
            self:SetFocusToTargetHead2Head(DeltaSeconds, 50)
        else
            Controller:K2_ClearFocus()
        end
    end
end

function AiComponent:TickTurnToTarget(DeltaSeconds, InterSpeed)
    self:SetFocusToTargetHead2Head(DeltaSeconds, InterSpeed)
end

function AiComponent:TickTurnToLocation(DeltaSeconds, InterSpeed, Location)
    self:SetFocusToPoint(DeltaSeconds, InterSpeed, Location)
end

function AiComponent:SetFocusToTargetHead2Head(DeltaSeconds, InterSpeed)

    local Pawn = self.actor:GetInstigator()
    local Controller = Pawn:GetController()
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")

    if Target == nil then
        return
    end

    local TargetHeadLocation = utils.GetActorLocation_Up(Target)
    self:SetFocusToPoint(DeltaSeconds, InterSpeed, TargetHeadLocation)
end

function AiComponent:SetFocusToPoint(DeltaSeconds, InterSpeed, Point)
    if InterSpeed < 0.000001 then
        return
    end

    local SelfHeadLocation = utils.GetActorLocation_Up(self.actor)
    local Forward = Point - SelfHeadLocation
    local TargetRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(Forward)

    -- G.log:debug("yj", "SetFocusToTargetHead2Head %s TargetRotation.Yaw.%s - Aiming.Yaw.%s Hope.Yaw.%s - DeltaSeconds.%s InterSpeed.%s", 
    --     self.actor:GetDisplayName(), self.actor:K2_GetActorRotation().Yaw, self.actor.AppearanceComponent:GetAimingRotation().Yaw, TargetRotation.Yaw, DeltaSeconds, InterSpeed)

    self.actor.AppearanceComponent:Multicast_SmoothAimingRotation(TargetRotation, InterSpeed, DeltaSeconds)

    TargetRotation.Pitch = 0.0
    self.actor.AppearanceComponent:SmoothActorRotation(TargetRotation, InterSpeed, 0, DeltaSeconds)
end

decorator.message_receiver()
function AiComponent:OnEndAbility(SkillID, SkillType)
    if self.actor.SkillInUse == SkillID then
        self.actor.SkillInUse = nil
    end
end

decorator.message_receiver()
function AiComponent:OnBeginInKnock()
    local TenacityTag = UE.UHiGASLibrary.RequestGameplayTag("Ability.AI.Defend.Tenacity")
    if self.actor:GetAbilitySystemComponent():HasGameplayTag(TenacityTag) then
        return
    end

    self:StopSkillAndBT()
end

decorator.message_receiver()
function AiComponent:OnEndInKnock()
    G.log:debug("santi", "Monster: %s OnEndInKnock", self.actor:GetDisplayName())
    self:ResumeBT()
end

decorator.message_receiver()
function AiComponent:OnBeginningOutBalance()
    G.log:debug("santi", "Monster: %s OnBeginningOutBalance", self.actor:GetDisplayName())
    self:StopSkillAndBT()
end

decorator.message_receiver()
function AiComponent:OnEndOutBalance()
    G.log:debug("santi", "Monster: %s OnEndOutBalance", self.actor:GetDisplayName())
    self:ResumeBT()
end

decorator.message_receiver()
function AiComponent:OnBeginBeJudge()
    G.log:debug("santi", "Monster: %s OnBeginBeJudge", self.actor:GetDisplayName())
    self:StopSkillAndBT()
end

decorator.message_receiver()
function AiComponent:OnEndBeJudge()
    G.log:debug("santi", "Monster: %s OnEndBeJudge", self.actor:GetDisplayName())
    self:ResumeBT()
end

decorator.message_receiver()
function AiComponent:OnBeginRide(vehicle)
    if not self.actor:IsClient() then
        local ASC = self.actor:GetAbilitySystemComponent()
        local OnRideGEClass = UE.UClass.Load("/Game/Blueprints/Skill/GE/GE_OnRide.GE_OnRide_C")
        local OnRideGEGESpecHandle = ASC:MakeOutgoingSpec(OnRideGEClass, 1, UE.FGameplayEffectContextHandle())
        ASC:BP_ApplyGameplayEffectSpecToSelf(OnRideGEGESpecHandle)
    end
end

decorator.message_receiver()
function AiComponent:OnEndRide(vehicle)
    if not self.actor:IsClient() then
        local ASC = self.actor:GetAbilitySystemComponent()
        local OutRideGEClass = UE.UClass.Load("/Game/Blueprints/Skill/GE/GE_OutRide.GE_OutRide_C")
        local OutRideGEGESpecHandle = ASC:MakeOutgoingSpec(OutRideGEClass, 1, UE.FGameplayEffectContextHandle())
        ASC:BP_ApplyGameplayEffectSpecToSelf(OutRideGEGESpecHandle)
    end
end

decorator.message_receiver()
function AiComponent:StopSkillAndBT()
    self:StopSkill()
    self:PauseBT()
    self.actor:GetController():StopMovement()
end

decorator.message_receiver()
function AiComponent:StopSkill()
    if self.actor.SkillInUse ~= nil then
        local AbilitySystemComponent = self.actor:GetAbilitySystemComponent()
        local AbilityHandle = self.actor:FindAbilitySpecHandleFromSkillID(self.actor.SkillInUse)
        AbilitySystemComponent:BP_CancelAbilityHandle(AbilityHandle)
    end
end

decorator.message_receiver()
function AiComponent:OnHitFalling(bInHitFalling)
    G.log:debug("santi", "AI InHitFalling: %s", tostring(bInHitFalling))

    if bInHitFalling then
        self:StopSkillAndBT()
    else
        self:ResumeBT()
    end
end

decorator.message_receiver()
function AiComponent:OnDefendFrontDamage(SourceActor)

    local Forward = self.actor:K2_GetActorLocation() - SourceActor:K2_GetActorLocation()

    Forward = UE.UKismetMathLibrary.Vector_Normal2D(Forward)
    Forward = UE.UKismetMathLibrary.Multiply_VectorFloat(Forward, 50)

    local MoveLocation = UE.UKismetMathLibrary.Add_VectorVector(self.actor:K2_GetActorLocation(), Forward)

    self.actor:K2_SetActorLocation(MoveLocation, false, nil, true)
end

decorator.message_receiver()
function AiComponent:BeforeTryActiveAbility()
    self.bHitTheTarget = false
    self.bDamageTheTarget = false

    self.bBeWithStand = false
    self.bBeExtremeWithStand = false

    self.bBeDodge = false

    self.LastUseSkillTime = G.GetNowTimestampMs()
end

decorator.message_receiver()
function AiComponent:OnDamageOther(Damage, BeDamageActor)
    if self.actor:IsClient() then
        return
    end

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(self.actor:GetController())
    local Target = BB:GetValueAsObject("TargetActor")
    if Target == BeDamageActor then
        self.bHitTheTarget = true
        if Damage > 0.000001 then
            self.bDamageTheTarget = true
        end
    end
end

decorator.message_receiver()
function AiComponent:HandleBeWithStand(TargetActor)
    self.bBeWithStand = true
end

decorator.message_receiver()
function AiComponent:HandleBeExtremeWithStand(TargetActor)
    self.bBeExtremeWithStand = true
end

decorator.message_receiver()
function AiComponent:HandleBeImmunityBlockGameplayEffect(TargetActor, ImmunityGE)
    G.log:debug("yj", "AiComponent:HandleBeImmunityBlockGameplayEffect %s ImmunityGE.%s", self.actor:GetDisplayName(), UE.UHiGASLibrary.GetActiveGameplayEffectDebugString(ImmunityGE))
    self.bBeDodge = true
end

decorator.message_receiver()
function AiComponent:OnDead()
    -- self:DestroyAllMountActor()

    -- local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(self.actor:GetController())
    -- local OldTarget = BB:GetValueAsObject("TargetActor")
    -- if OldTarget then
    --     OldTarget:SendMessage("OnBattleTargetDead", self.actor)
    -- end

    ai_utils.BreakBattleTargetPair(self.actor)

    G.log:error("lizhao", "AiComponent:OnDead %s", tostring(self.actor:IsClient()))

    -- 死之前触发一次SwitchBT，确保TaskNode可以处理OnSwitch事件来进行收尾
    -- self:SwitchBT(self.InitBT)
    self:BeforeBTSwitch()

    self:StopSkillAndBT()
end

decorator.message_receiver()
function AiComponent:ReceiveBattleSignal(Source)
    -- 收到攻击信号，开始追击
    if self.BattleSignalSource ~= nil then
        self:ReturnBattleSignal()
    end
    self.BattleSignalSource = Source
end

decorator.message_receiver()
function AiComponent:ReturnBattleSignal()
    if self.BattleSignalSource == nil then
        return
    end

    G.log:debug("yj", "AiComponent:ReturnBattleSignal %s", self.actor:GetDisplayName())
    -- 归还攻击信号
    self.BattleSignalSource:SendMessage("RecycleBattleSignal", self.actor)
    self.BattleSignalSource = nil
end

decorator.message_receiver()
function AiComponent:SetCurBTNodeBreak(bCanBreak)
    -- 给BOSS技能连招用的
    self.bCanBreakCurBTNode = bCanBreak
end

decorator.message_receiver()
function AiComponent:TeleportToBornLocation()
    self.actor:K2_SetActorLocation(self.BornLocation, false, nil, false)
end

---------------------------------------------- CP商接口 ----------------------------------------------
-- 有了AI框架之后，这两个事件就不要了，框架负责管理战斗对
-- decorator.message_receiver()
-- function AiComponent:EnterBattle(Target)
--     -- 进战
--     ai_utils.MakeBattleTargetPair(self.actor, Target)
-- end

-- decorator.message_receiver()
-- function AiComponent:LeaveBattle(Target)
--     -- 出战
--     ai_utils.BreakBattleTargetPair(self.actor, Target)
-- end

return AiComponent
