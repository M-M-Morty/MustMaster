require "UnLua"

local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local check_table = require("common.data.state_conflict_data")
local utils = require("common.utils")
local SubsystemUtils = require("common.utils.subsystem_utils")
local EdUtils = require("common.utils.ed_utils")
local ClusterStateMachine = require("common.utils.cluster_state_machine")

local ClusterMasterComponent = Component(ComponentBase)
local decorator = ClusterMasterComponent.decorator



-- function ClusterMasterComponent:ReceiveBeginPlay()
--     Super(ClusterMasterComponent).ReceiveBeginPlay(self)
--     if self.actor:IsClient() then
--         return
--     end

--     self:CreateCluster()
--     self.ActionRegions = nil
--     self.TeamForm = nil

--     self.State = ClusterStateMachine.InitState(self)
-- end

-- decorator.message_receiver()
-- function ClusterMasterComponent:OnReceiveTick(DeltaSeconds)
--     if self.actor:IsClient() then
--         return
--     end

--     self:StateTick()
--     self:DrawDebug()
-- end

-- function ClusterMasterComponent:CreateCluster()
--     local SlaveIds = self:GetActorIds("PresetSlaves")
--     for idx = 1, #SlaveIds do
--         local SlaveID = SlaveIds[idx]
--         local Slave = SubsystemUtils.GetMutableActorSubSystem(self.actor):GetActor(SlaveID)
--         if Slave and Slave:IsMonster() then
--             Slave:SendMessage("EnterCluster", self.actor)
--             self.Slaves:Add(Slave)
--             G.log:debug("yj", "CreateCluster 1 ActorId.%s, Actor.%s", SlaveID, G.GetDisplayName(Slave))

--         elseif not Slave then
--             SubsystemUtils.GetMutableActorSubSystem(self.actor):ListenActorSpawnOrDestroy(SlaveID, self, function( ... )
--                 if not self.actor then
--                     -- Destroy
--                     return
--                 end

--                 utils.DoDelay(self.actor, 0.1, function( ... )
--                     -- 延一帧，否则SendMessage发不到component上（因为此时的actor还没有初始化component）
--                     local Slave = SubsystemUtils.GetMutableActorSubSystem(self.actor):GetActor(SlaveID)
--                     Slave:SendMessage("EnterCluster", self.actor)
--                     self.Slaves:Add(Slave)
--                     G.log:debug("yj", "CreateCluster 2 ActorId.%s, Actor.%s", SlaveID, G.GetDisplayName(Slave))
--                 end)
--             end)
--         end
--     end

-- end

-- decorator.message_receiver()
-- function ClusterMasterComponent:OnSlaveDead(Slave)
--     for Idx = 1, self.Slaves:Length() do
--         if Slave == self.Slaves:Get(Idx) then
--             -- G.log:debug("yj", "[ClusterMasterComponent] %s leave cluster", Slave:GetDisplayName())
--             self.Slaves:Remove(Idx)
--             break
--         end
--     end

--     if self.Slaves:Length() == 0 then
--         self:SendMessage("StopBT")
--         return
--     end

--     -- 切阵型，切BT
--     self:GenTeamFormStr()
--     self:GenTeamFormLocation()
--     self:SendMessage("SwitchBT", self:GetClusterBT(self.ClusterBattleBTs))
-- end

-- decorator.message_receiver()
-- function ClusterMasterComponent:OnSlaveDamaged(Slave)
--     self.LastSlaveDamagedTime = G.GetNowTimestampMs()
-- end

-- function ClusterMasterComponent:StateTick()
--     local NewTarget, Dis = self:GetTargetActor_AOI(self.RelaxRadius)

--     local Controller = self.actor:GetController()
--     local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
--     local OldTarget = BB:GetValueAsObject("TargetActor")
--     if NewTarget ~= OldTarget then
--         self:ChangeTargetActor(OldTarget, NewTarget)
--     end

--     self.State:tick(Dis)

--     -- G.log:debug("yj", "ClusterMasterComponent Cluster_EnterState %s %s NewTarget.%s Dis.%s", self.ClusterState, self.RelaxRadius, NewTarget, Dis)
-- end

-- decorator.message_receiver()
-- function ClusterMasterComponent:Cluster_EnterState(State)
--     if self.ClusterState == State then
--         return
--     end

--     -- broadcast
--     for idx = 1, self.Slaves:Length() do
--         -- TODO rpc for dds
--         local Slave = self.Slaves:Get(idx)
--         Slave:SendMessage("OnClusterStateChange", State)
--     end

--     self.ClusterState = State
-- end

-- function ClusterMasterComponent:ChangeTargetActor(OldTarget, NewTarget)
--     -- broadcast
--     for idx = 1, self.Slaves:Length() do
--         local Slave = self.Slaves:Get(idx)
--         Slave:SendMessage("OnTargetActorChange", NewTarget)
--     end

--     local Controller = self.actor:GetController()
--     local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
--     BB:SetValueAsObject("TargetActor", NewTarget)
-- end

-- function ClusterMasterComponent:GetTargetActor_AOI(AOIRadius)
--     local MinDis, TargetActor = 99999, nil
--     for i = 0, 10 do
--         local Target = G.GetPlayerCharacter(self.actor:GetWorld(), i)
--         if Target and Target.CharIdentity == Enum.Enum_CharIdentity.Avatar then
--             local Dis = self.actor:GetDistanceTo(Target)
--             -- G.log:debug("yj", "BTDecorator_IsTargetNearby %s - Dis(%s) < ToleranceDis(%s) = %s %s", Target, Dis, AOIRadius, Dis < AOIRadius, Dis < MinDis)
--             if Dis < AOIRadius and Dis < MinDis then
--                 MinDis = Dis
--                 TargetActor = Target
--             end
--         end
--     end

--     return TargetActor, MinDis
-- end

-- function ClusterMasterComponent:NeedRegenActionRegions()
--     if self.ClusterState ~= Enum.Enum_MonsterClusterState.Battle then
--         return false
--     end

--     if self.ActionRegions == nil then
--         return true
--     end

--     local Controller = self.actor:GetController()
--     local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
--     local TargetActor = BB:GetValueAsObject("TargetActor")
--     if TargetActor == nil then
--         return false
--     end

--     local OldCenterLocation = self.ActionRegions.CenterLocation
--     local OldCenterRotation = self.ActionRegions.CenterRotation

--     local CurCenterLocation = TargetActor:K2_GetActorLocation()
--     local CurCenterRotation = UE.FRotator(0, TargetActor:GetCameraRotation().Yaw, 0)

--     if UE.UKismetMathLibrary.Vector_Distance(CurCenterLocation, OldCenterLocation) > self.RegenDis then
--         return true
--     end

--     if math.abs(CurCenterRotation.Yaw - OldCenterRotation.Yaw) > self.ReginYaw then
--         return true
--     end

--     -- G.log:debug("yj", "ClusterMasterComponent:NeedRegenActionRegions 3 %s %s %s", CurCenterRotation.Yaw, OldCenterRotation.Yaw, self.ReginYaw)
--     return false
-- end

-- decorator.message_receiver()
-- function ClusterMasterComponent:GenActionRegions()
--     if self.ClusterState ~= Enum.Enum_MonsterClusterState.Battle then
--         return
--     end

--     local Controller = self.actor:GetController()
--     local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
--     local TargetActor = BB:GetValueAsObject("TargetActor")
--     if TargetActor == nil then
--         return
--     end

--     self.ActionRegions = {}
--     self.ActionRegions.CenterLocation = TargetActor:K2_GetActorLocation()
--     self.ActionRegions.CenterRotation = UE.FRotator(0, TargetActor:GetCameraRotation().Yaw, 0)
--     self.ActionRegions.InnerRegion = {}
--     self.ActionRegions.MiddleRegion = {}
--     self.ActionRegions.OutRegion = {}

--     local DivideAngle = self.DivideAngle
--     local InnerRadius = self.InnerRadius
--     local MiddleRadius = self.MiddleRadius
--     local OutRadius = self.OutRadius

--     local DivideCnt = 360 // DivideAngle
--     local StartAngle = DivideAngle // 2

--     local Forward = UE.UKismetMathLibrary.Conv_RotatorToVector(self.ActionRegions.CenterRotation)
--     for i = 0, DivideCnt - 1 do
--         local RotAngle = -90 + StartAngle + i*DivideAngle -- 从左正方顺时针旋转
--         local TargetForward = UE.UKismetMathLibrary.RotateAngleAxis(Forward, RotAngle, UE.FVector(0, 0, 1))
--         local InnerPoint = UE.UKismetMathLibrary.Normal(TargetForward) * (InnerRadius / 2) + self.ActionRegions.CenterLocation
--         local MiddlePoint = UE.UKismetMathLibrary.Normal(TargetForward) * ((MiddleRadius - InnerRadius) / 2 + InnerRadius) + self.ActionRegions.CenterLocation
--         local OutPoint = UE.UKismetMathLibrary.Normal(TargetForward) * ((OutRadius - MiddleRadius) / 2 + MiddleRadius) + self.ActionRegions.CenterLocation
--         table.insert(self.ActionRegions.InnerRegion, InnerPoint)
--         table.insert(self.ActionRegions.MiddleRegion, MiddlePoint)
--         table.insert(self.ActionRegions.OutRegion, OutPoint)
--     end

--     if self.TeamFormStr == "" then
--         self:GenTeamFormStr()
--     end

--     self:GenTeamFormLocation()
-- end

-- function ClusterMasterComponent:GenTeamFormStr()
--     local IniStrs = self[string.format("TeamForms%s", self.Slaves:Length())]
--     assert(IniStrs ~= nil, string.format("Slaves num.%s error", self.Slaves:Length()))
--     self.TeamFormStr = IniStrs:Get(math.random(1, IniStrs:Length()))
-- end

-- decorator.message_receiver()
-- function ClusterMasterComponent:SwitchTeamFormStr(TeamFormStr)
--     self.TeamFormStr = TeamFormStr
--     self:GenTeamFormLocation()
-- end

-- decorator.message_receiver()
-- function ClusterMasterComponent:GenTeamFormLocation()
--     local RegionIdxs = utils.StrSplit(self.TeamFormStr, "-")
--     assert(self.Slaves:Length() == #RegionIdxs, string.format("self.TeamFormStr.%s Length ~= %s", self.TeamFormStr, self.Slaves:Length()))

--     if not self.ActionRegions then
--         self:GenActionRegions()
--     end

--     self.TeamForm = {}
--     self.TeamForm.TeamForm_Inner = {}
--     self.TeamForm.TeamForm_Middle = {}
--     self.TeamForm.TeamForm_Out = {}
--     for idx = 1, #RegionIdxs do
--         local I1, I2, Location = self:RegionIdx2Location(RegionIdxs[idx])
--         if I1 == "i" then
--             table.insert(self.TeamForm.TeamForm_Inner, {i = I1, idx = I2, location = Location})
--         elseif I1 == "m" then
--             table.insert(self.TeamForm.TeamForm_Middle, {i = I1, idx = I2, location = Location})
--         elseif I1 == "o" then
--             table.insert(self.TeamForm.TeamForm_Out, {i = I1, idx = I2, location = Location})
--         end
--     end

--     local Controller = self.actor:GetController()
--     local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
--     local TargetActor = BB:GetValueAsObject("TargetActor")
--     local TargetLocation = TargetActor:K2_GetActorLocation()

--     -- 随从排序（离目标由近至远）
--     local SortSlaves = {}
--     for idx = 1, self.Slaves:Length() do
--         table.insert(SortSlaves, self.Slaves:Get(idx))
--     end
--     table.sort(SortSlaves, function(a, b) 
--         local Disa = UE.UKismetMathLibrary.Vector_Distance(a:K2_GetActorLocation(), TargetLocation)
--         local Disb = UE.UKismetMathLibrary.Vector_Distance(b:K2_GetActorLocation(), TargetLocation)
--         return Disa < Disb
--     end)


--     local Forward = UE.UKismetMathLibrary.Conv_RotatorToVector(self.ActionRegions.CenterRotation)
--     local NormalForward = UE.UKismetMathLibrary.Normal(Forward)
--     local ZNormal = UE.FVector(0, 0, 1)
--     local LeftForwad = UE.UKismetMathLibrary.Cross_VectorVector(NormalForward, ZNormal)
--     local LeftForwadNormal = UE.UKismetMathLibrary.Normal(LeftForwad)
--     -- UE.UKismetSystemLibrary.DrawDebugLine(self.actor, TargetLocation, TargetLocation + LeftForwadNormal * 1000, UE.FLinearColor.White, 5)

--     -- 目标点分配
--     local function _AllocateLocation(_TeamForm, MoveDelay)
--         if #_TeamForm == 0 then
--             return
--         end

--         -- 匹配相同数量的随从
--         local _Slaves = {}
--         for idx = 1, #_TeamForm do
--             table.insert(_Slaves, table.remove(SortSlaves, 1))
--         end

--         -- 对目标点进行排序（按序号从小到大）
--         table.sort(_TeamForm, function(a, b) return a.idx < b.idx end)

--         -- 对随从进行排序
--         -- 先找到离_TeamForm[-1]最近的随从位置Ref
--         table.sort(_Slaves, function(a, b) 
--             local Disa = UE.UKismetMathLibrary.Vector_Distance(a:K2_GetActorLocation(), _TeamForm[#_TeamForm].location)
--             local Disb = UE.UKismetMathLibrary.Vector_Distance(b:K2_GetActorLocation(), _TeamForm[#_TeamForm].location)
--             return Disa < Disb
--         end)
--         local RefLocation = _Slaves[1]:K2_GetActorLocation()

--         -- 再根据离位置Ref的距离从远到近排序
--         table.sort(_Slaves, function(a, b) 
--             local Disa = UE.UKismetMathLibrary.Vector_Distance(a:K2_GetActorLocation(), RefLocation)
--             local Disb = UE.UKismetMathLibrary.Vector_Distance(b:K2_GetActorLocation(), RefLocation)
--             return Disa > Disb
--         end)

--         local DisToTeamStart = UE.UKismetMathLibrary.Vector_Distance(RefLocation, _TeamForm[1].location)
--         local DisToTeamEnd = UE.UKismetMathLibrary.Vector_Distance(RefLocation, _TeamForm[#_TeamForm].location)
--         if DisToTeamStart > DisToTeamEnd then
--             -- 走到这，说明是逆时针旋转了相机，找离_TeamForm[1]最近的随从位置
--             table.sort(_Slaves, function(a, b) 
--                 local Disa = UE.UKismetMathLibrary.Vector_Distance(a:K2_GetActorLocation(), _TeamForm[1].location)
--                 local Disb = UE.UKismetMathLibrary.Vector_Distance(b:K2_GetActorLocation(), _TeamForm[1].location)
--                 return Disa < Disb
--             end)
--             RefLocation = _Slaves[1]:K2_GetActorLocation()

--             -- 再根据离位置Ref的距离从近到远排序
--             table.sort(_Slaves, function(a, b) 
--                 local Disa = UE.UKismetMathLibrary.Vector_Distance(a:K2_GetActorLocation(), RefLocation)
--                 local Disb = UE.UKismetMathLibrary.Vector_Distance(b:K2_GetActorLocation(), RefLocation)
--                 return Disa < Disb
--             end)
--         end

--         -- UE.UKismetSystemLibrary.DrawDebugSphere(self.actor, RefLocation, 20, 10, UE.FLinearColor.Red, 5)

--         -- 给随从下达移动指令
--         utils.DoDelay(self.actor, MoveDelay, function()
--             for idx = 1, #_Slaves do
--                 local Slave = _Slaves[idx]
--                 local TargetForm = _TeamForm[idx]

--                 self.ClusterCmd.CmdType = Enum.Enum_ClusterCmdType.ArcMove
--                 self.ClusterCmd.TargetLocation = TargetForm.location

--                 -- TODO - rpc for DDS
--                 Slave:SendMessage("UpdateFormIdx", string.upper(string.format("%s%s", TargetForm.i, idx)))
--                 Slave:SendMessage("ReceiveClusterCmd", self.ClusterCmd)
--             end
--         end)
--     end

--     -- 内中外三圈独立分配目标点
--     _AllocateLocation(self.TeamForm.TeamForm_Inner, self.InnerMoveDelay)
--     _AllocateLocation(self.TeamForm.TeamForm_Middle, self.MiddleMoveDelay)
--     _AllocateLocation(self.TeamForm.TeamForm_Out, self.OutMoveDelay)
-- end

-- function ClusterMasterComponent:RegionIdx2Location(RegionIdx)
--     local I1 = string.sub(RegionIdx, 1, 1)
--     local I2 = tonumber(string.sub(RegionIdx, 2, -1))
--     if type(I2) ~= "number" then
--         G.log:error("yj", "GenTeamForm error ini str.%s", IniStr)
--         assert(false)
--     end

--     if I1 == "i" then
--         return I1, I2, self.ActionRegions.InnerRegion[I2]
--     elseif I1 == "m" then
--         return I1, I2, self.ActionRegions.MiddleRegion[I2]
--     elseif I1 == "o" then
--         return I1, I2, self.ActionRegions.OutRegion[I2]
--     else
--         G.log:error("yj", "GenTeamForm error ini str.%s", IniStr)
--         assert(false)
--     end
-- end

-- function ClusterMasterComponent:DrawDebug()
--     if not self.bDebug then
--         return
--     end

--     if self.ActionRegions ~= nil then
--         for idx = 1, #self.ActionRegions.InnerRegion do
--             if idx == 1 then
--                 UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, self.ActionRegions.InnerRegion[idx], self.DebugSize, UE.FLinearColor(1, 0, 0), 0.1)
--                 UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, self.ActionRegions.MiddleRegion[idx], self.DebugSize, UE.FLinearColor(1, 0, 0), 0.1)
--                 UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, self.ActionRegions.OutRegion[idx], self.DebugSize, UE.FLinearColor(1, 0, 0), 0.1)
--             elseif idx % 4 == 1 then
--                 UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, self.ActionRegions.InnerRegion[idx], self.DebugSize, UE.FLinearColor(1, 1, 1), 0.1)
--                 UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, self.ActionRegions.MiddleRegion[idx], self.DebugSize, UE.FLinearColor(1, 1, 1), 0.1)
--                 UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, self.ActionRegions.OutRegion[idx], self.DebugSize, UE.FLinearColor(1, 1, 1), 0.1)
--             else
--                 UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, self.ActionRegions.InnerRegion[idx], self.DebugSize, UE.FLinearColor(1, 1, 0), 0.1)
--                 UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, self.ActionRegions.MiddleRegion[idx], self.DebugSize, UE.FLinearColor(1, 0, 1), 0.1)
--                 UE.UKismetSystemLibrary.DrawDebugPoint(self.actor, self.ActionRegions.OutRegion[idx], self.DebugSize, UE.FLinearColor(0, 1, 1), 0.1)
--             end
--         end
--     end
-- end

-- function ClusterMasterComponent:GetSlaveByFormIdx(FormIdx)
--     for idx = 1, self.Slaves:Length() do
--         local Slave = self.Slaves:Get(idx)
--         if Slave.ClusterSlaveComponent.FormIdx == FormIdx then
--             return Slave
--         end
--     end
-- end

-- function ClusterMasterComponent:GetActorContainerPropertyName(PropertyName)
--     return PropertyName.."@Container"
-- end

-- function ClusterMasterComponent:GetActorIdBase(ActorId)
--     if ActorId then
--         local Data = EdUtils:SplitPath(ActorId, "@")
--         if #Data > 1 then
--             ActorId = Data[2]
--         end
--     end
--     return ActorId
-- end

-- function ClusterMasterComponent:GetActorIds(PropertyName)
--     local Name = self:GetActorContainerPropertyName(PropertyName)
--     local IDs = {}
--     if self.actor[Name] then
--         for ind=1, #self.actor[Name] do
--             local ActorId = self.actor[Name][ind]
--             table.insert(IDs, self:GetActorIdBase(ActorId))
--         end
--     end
--     return IDs
-- end

-- function ClusterMasterComponent:GetClusterBT(BTMap)
--     local SlavesNum = self.Slaves:Length()
--     local BT = BTMap:Find(SlavesNum)
--     -- TODO BT ~= nill
--     -- assert(BT ~= nil, string.format("BTMap has no %s", SlavesNum))
--     if BT == nil then
--         BT = self.ClusterBattleBT
--     end
--     return BT
-- end

-- function ClusterMasterComponent:NotifySlavePauseBT()
--     for idx = 1, self.Slaves:Length() do
--         local Slave = self.Slaves:Get(idx)
--         -- TODO - rpc for DDS
--         Slave:SendMessage("PauseBT")
--     end
-- end

-- function ClusterMasterComponent:NotifySlaveResumeBT()
--     for idx = 1, self.Slaves:Length() do
--         local Slave = self.Slaves:Get(idx)
--         -- TODO - rpc for DDS
--         Slave:SendMessage("ResumeBT")
--     end
-- end

-- function ClusterMasterComponent:NotifySlaveReturnToBornLocation()
--     for idx = 1, self.Slaves:Length() do
--         local Slave = self.Slaves:Get(idx)

--         self.ClusterCmd.CmdType = Enum.Enum_ClusterCmdType.Return
--         -- TODO - rpc for DDS
--         Slave:SendMessage("ReceiveClusterCmd", self.ClusterCmd)
--     end
-- end

-- function ClusterMasterComponent:IsAllSlaveArriveBornLocation()
--     for idx = 1, self.Slaves:Length() do
--         local Slave = self.Slaves:Get(idx)
--         local SlaveLocation = Slave:K2_GetActorLocation()
--         local SlaveBornLocation = Slave.ClusterSlaveComponent.BornLocation
--         if UE.UKismetMathLibrary.Vector_Distance2D(SlaveLocation, SlaveBornLocation) > 50 then
--             return false
--         end
--     end

--     return true
-- end

-- function ClusterMasterComponent:IsAnySlaveArriveBornLocation()
--     for idx = 1, self.Slaves:Length() do
--         local Slave = self.Slaves:Get(idx)
--         local SlaveLocation = Slave:K2_GetActorLocation()
--         local SlaveBornLocation = Slave.ClusterSlaveComponent.BornLocation
--         if UE.UKismetMathLibrary.Vector_Distance2D(SlaveLocation, SlaveBornLocation) < 50 then
--             return true
--         end
--     end

--     return false
-- end


return ClusterMasterComponent
