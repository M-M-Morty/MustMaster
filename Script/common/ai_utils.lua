local utils = require("common.utils")
local TargetFilter = require("actors.common.TargetFilter")

local G = require("G")

ai_utils = {}


ai_utils.BTTask_Succeeded  = 0
ai_utils.BTTask_Failed     = 1
ai_utils.BTTask_InProgress = 2


function ai_utils.GetCmdState(Slave, CmdType)
	if not Slave.ClusterSlaveComponent then
		return
	end

    if CmdType == Enum.Enum_ClusterCmdType.UseSkill then
        return Slave.ClusterSlaveComponent.CmdState_UseSkill
    elseif CmdType == Enum.Enum_ClusterCmdType.Perform then
        return Slave.ClusterSlaveComponent.CmdState_Perform
    elseif CmdType == Enum.Enum_ClusterCmdType.ArcMove then
        return Slave.ClusterSlaveComponent.CmdState_ArcMove
    elseif CmdType == Enum.Enum_ClusterCmdType.Confront then
        return Slave.ClusterSlaveComponent.CmdState_Confront
    elseif CmdType == Enum.Enum_ClusterCmdType.Return then
        return Slave.ClusterSlaveComponent.CmdState_Return
    end
end

function ai_utils.IsSlaveCmdLongToStart(Slave, CmdType, Time)
	local CmdState = ai_utils.GetCmdState(Slave, CmdType)
	if not CmdState then
		return false
	end

	if CmdState.CmdResult == Enum.Enum_ClusterCmdResult.Init then
		return false
	end

	local NowMs = G.GetNowTimestampMs()
	return NowMs - CmdState.CmdStartTime > Time
end

function ai_utils.IsSlaveCmdLongToFinish(Slave, CmdType, Time)
	local CmdState = ai_utils.GetCmdState(Slave, CmdType)
	if not CmdState then
		return false
	end

	if CmdState.CmdResult ~= Enum.Enum_ClusterCmdResult.Succeeded and 
	   CmdState.CmdResult ~= Enum.Enum_ClusterCmdResult.Failed and 
	   CmdState.CmdResult ~= Enum.Enum_ClusterCmdResult.Ignore then
	   	return false
	end

	local NowMs = G.GetNowTimestampMs()
	-- G.log:error("yj", "ai_utils.IsSlaveCmdLongToFinish %s Cmd.%s %s - %s > %s ?", Slave.ClusterSlaveComponent.FormIdx, CmdType, NowMs, CmdState.CmdFinishTime, Time)
	return NowMs - CmdState.CmdFinishTime > Time
end

function ai_utils.IsSlaveLongToIdle(Slave, Time)
	if not Slave.ClusterSlaveComponent then
		return false
	end

	if not Slave.ClusterSlaveComponent.ClusterCmd then
		return false
	end

	local CmdState = ai_utils.GetCmdState(Slave, Slave.ClusterSlaveComponent.ClusterCmd.CmdType)
    if not CmdState then
        return false
    end

	if CmdState.CmdResult ~= Enum.Enum_ClusterCmdResult.Succeeded and 
	   CmdState.CmdResult ~= Enum.Enum_ClusterCmdResult.Failed then
	   	return false
	end

	local NowMs = G.GetNowTimestampMs()
	return NowMs - CmdState.CmdFinishTime > Time
end

function ai_utils.RandomClusterSkillClass(SkillClassMap)
    assert(SkillClassMap:Length() > 0, "SkillClassMap is empty")

    local TotalNum = 0
    for idx = 1, SkillClassMap:Length() do
        local Ele = SkillClassMap:Get(idx)
        TotalNum = TotalNum + Ele.Weight
    end

    local RandNum = math.random(0, TotalNum)
    for idx = 1, SkillClassMap:Length() do
        local Ele = SkillClassMap:Get(idx)
        RandNum = RandNum - Ele.Weight
        if RandNum <= 0 then
            return Ele.SkillClass
        end
    end
end

function ai_utils.RandomClusterPerformMontage(PerformMontageMap)
    assert(PerformMontageMap:Length() > 0, "PerformMontageMap is empty")

    local TotalNum = 0
    for idx = 1, PerformMontageMap:Length() do
        local Ele = PerformMontageMap:Get(idx)
        TotalNum = TotalNum + Ele.Weight
    end

    local RandNum = math.random(0, TotalNum)
    for idx = 1, PerformMontageMap:Length() do
        local Ele = PerformMontageMap:Get(idx)
        RandNum = RandNum - Ele.Weight
        if RandNum <= 0 then
            return Ele.PerformMontage
        end
    end
end

function ai_utils.IsLocationReachable(Controller, Location)
    local OutPath = UE.TArray(UE.FVector)
    UE.UHiUtilsFunctionLibrary.FindNavPath(Controller, Location, OutPath)
    return OutPath:Length() > 0
end

function ai_utils.FindReachableLocationInZ(Controller, Location)
	if ai_utils.IsLocationReachable(Controller, Location) then
		return true, Location
	end

	local Pawn = Controller:K2_GetPawn()

    local ZAdd = UE.FVector(0, 0, 1000)
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.WorldStatic)
    local ActorsToIgnore = UE.TArray(UE.AActor)

    local bSuccess, ReachableLocation = false, nil
    local Hits = UE.TArray(UE.FHitResult)
    local IsHit = UE.UKismetSystemLibrary.LineTraceMultiForObjects(Pawn, Location, Location - ZAdd, ObjectTypes, true, ActorsToIgnore, UE.EDrawDebugTrace.None, Hits, true)
    for idx = 1, Hits:Length() do
    	local HitResult = Hits:Get(idx)
    	local Owner = HitResult.Component:GetOwner()
        local HitPoint = UE.FVector(HitResult.ImpactPoint.X, HitResult.ImpactPoint.Y, HitResult.ImpactPoint.Z + utils.GetCapsuleHalfHeight(Pawn))
        if ai_utils.IsLocationReachable(Controller, HitPoint) then
            bSuccess, ReachableLocation = true, HitPoint
        	-- UE.UKismetSystemLibrary.DrawDebugSphere(Pawn, HitResult.ImpactPoint, 20, 10, UE.FLinearColor.Red, 5)
        	-- G.log:debug("yj", "FindReachableLocationInZ Location.%s ReachableLocation.%s Name.%s", Location, ReachableLocation, G.GetDisplayName(Owner))
        	break
        end
    end

    return bSuccess, ReachableLocation
end

-- 生成战斗对（幂等）
function ai_utils.MakeBattleTargetPair(Monster, Target)
    -- 怪物设置目标
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Monster:GetController())
    if BB == nil then
        return
    end

    BB:SetValueAsObject("TargetActor", Target)
    Monster.AIPerceptionComponent.AITargetActor = Target

    -- 玩家添加目标
    Target:SendMessage("AddBattleTarget", Monster)
end

-- 解除战斗对（幂等）
function ai_utils.BreakBattleTargetPair(Monster, Target)
    -- 怪物清空目标
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Monster:GetController())
    if BB == nil then
        return
    end
    local Target = BB:GetValueAsObject("TargetActor") or Target
    BB:SetValueAsObject("TargetActor", nil)
    Monster.AIPerceptionComponent.AITargetActor = nil

    -- 玩家删除目标
    if Target then
        Target:SendMessage("SubBattleTarget", Monster)
    end
end

function ai_utils.GetBattleTarget(Monster)
    if Monster.AIPerceptionComponent.AITargetActor then
        return Monster.AIPerceptionComponent.AITargetActor
    end

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Monster:GetController())
    return BB and BB:GetValueAsObject("TargetActor")
end

function ai_utils.GetBornLocation(Monster)
    return Monster:GetAIServerComponent().BornLocation
end

function ai_utils.EvMoveToLocation(Controller, Pawn, TargetLocation)
    local SelfLocation = Pawn:K2_GetActorLocation()
    if not UE.UNavigationSystemV1.K2_ProjectPointToNavigation(Pawn, TargetLocation, nil, nil, nil, nil) then
        -- 目标不在寻路范围内，向目标靠近
        ai_utils.MoveToTarget(Pawn, TargetLocation)
    elseif not UE.UNavigationSystemV1.K2_ProjectPointToNavigation(Pawn, SelfLocation, nil, nil, nil, nil) then
        -- 自己不在寻路范围内，向导航网格靠近
        ai_utils.MoveToNavMesh(Pawn)
    else
        -- 寻路
        Controller:MoveToLocation(TargetLocation, 0, false)
    end
end

function ai_utils.MoveToNavMesh(Pawn)
    local SelfLocation = Pawn:K2_GetActorLocation()
    local OutLocation = UE.FVector(0, 0, 0)
    local bSuccess = UE.UNavigationSystemV1.K2_ProjectPointToNavigation(Pawn, SelfLocation, OutLocation, nil, nil, UE.FVector(500, 500, 500))
    if not bSuccess then
        return
    end
    -- UE.UKismetSystemLibrary.DrawDebugPoint(Pawn:GetWorld(), OutLocation, 20, UE.FLinearColor(1, 0, 0), 0.1)

    local Direction = UE.UKismetMathLibrary.Normal(OutLocation - SelfLocation)
    local MovementComponent = Pawn.AppearanceComponent:GetMyMovementComponent()
    MovementComponent:RequestDirectMove(Direction * 1000, false)
end

function ai_utils.MoveToTarget(Pawn, TargetLocation)
    local SelfLocation = Pawn:K2_GetActorLocation()
    local Direction = UE.UKismetMathLibrary.Normal(TargetLocation - SelfLocation)
    local MovementComponent = Pawn.AppearanceComponent:GetMyMovementComponent()
    MovementComponent:RequestDirectMove(Direction * 1000, false)
end

-- TargetActor: GAS中的TargetActor
-- Attacker: 技能施法者
-- Target: 目标
-- 返回值: true - 有效目标  false - 无效目标
function ai_utils.TargetActorFilter(TargetActor, Attacker, Target)
    if TargetActor.TargetFilter == nil then
        TargetActor.TargetFilter = TargetFilter.new(Attacker, TargetActor.CalcFilterType, TargetActor.CalcFilterIdentity)
    end

    return TargetActor.TargetFilter:FilterActor(Target)
end

return ai_utils
