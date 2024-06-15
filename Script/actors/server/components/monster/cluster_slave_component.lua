require "UnLua"

local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local check_table = require("common.data.state_conflict_data")

local ClusterSlaveComponent = Component(ComponentBase)
local decorator = ClusterSlaveComponent.decorator



-- function ClusterSlaveComponent:ReceiveBeginPlay()
--     Super(ClusterSlaveComponent).ReceiveBeginPlay(self)

--     self.BornLocation = self.actor:K2_GetActorLocation()
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:OnReceiveTick(DeltaSeconds)
-- 	self:SequenceCmdTick()
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:EnterCluster(Master)
--     -- G.log:debug("yj", "[ClusterSlaveComponent] %s enter cluster", self.actor:GetDisplayName())
--     self:SendMessage("StopBT")
--     self:SendMessage("LeaveBattle")
--     self.ClusterMaster = Master

--     self:SendMessage("SwitchBT", self.ClusterBT)
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:OnClusterStateChange(State)
-- 	-- G.log:error("yj", "ClusterSlaveComponent:OnClusterStateChange %s cluster state change %s IsClient.%s", self.actor:GetDisplayName(), State, self.actor:IsClient())

--     if State == Enum.Enum_MonsterClusterState.Battle then
--         self:SendMessage("EnterBattle")
--     elseif State == Enum.Enum_MonsterClusterState.OutBattle then
--         self:SendMessage("LeaveBattle")
--     elseif State == Enum.Enum_MonsterClusterState.Alert then
--         self:SendMessage("EnterAlert")
--     else
--         self:SendMessage("LeaveAlert")
--     end

--     self.ClusterState = State
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:OnTargetActorChange(TargetActor)
-- 	G.log:debug("yj", "[ClusterSlaveComponent] %s target change %s", self.actor:GetDisplayName(), TargetActor and G.GetDisplayName(TargetActor))
--     local Controller = self.actor:GetController()
--     local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
--     BB:SetValueAsObject("TargetActor", TargetActor)
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:OnDead()
-- 	if self.actor:IsClient() then
-- 		return
-- 	end

-- 	if self.ClusterMaster then
-- 		-- TODO rpc for dds
-- 		self.ClusterMaster:SendMessage("OnSlaveDead", self.actor)
-- 	end
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:OnDamaged(Damage, HitInfo, InstigatorCharacter, DamageCauser, DamageAbility, DamageGESpec)
-- 	if self.actor:IsClient() then
-- 		return
-- 	end

-- 	if self.ClusterMaster then
-- 		-- TODO rpc for dds
-- 		self.ClusterMaster:SendMessage("OnSlaveDamaged", self.actor)
-- 	end
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:UpdateFormIdx(FormIdx)
-- 	self.FormIdx = FormIdx
-- end

-- function ClusterSlaveComponent:GetCurCmdState()
-- 	return ai_utils.GetCmdState(self.actor, self.ClusterCmd.CmdType)
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:ReceiveClusterSequenceCmd(SequenceCmd, LoopCnt)
-- 	self.SequenceCmd = SequenceCmd
-- 	self.SequenceCmdBak = SequenceCmd
-- 	self.SequenceLoopCnt = LoopCnt
-- 	-- G.log:error("yj", "ReceiveClusterSequenceCmd before.%s %s %s", SequenceCmd:Get(1).JumpLoopCnt, self.SequenceCmd:Get(1).JumpLoopCnt, self.SequenceCmdBak:Get(1).JumpLoopCnt)
-- 	-- self.SequenceCmd:GetRef(1).JumpLoopCnt = 3
-- 	-- G.log:error("yj", "ReceiveClusterSequenceCmd after.%s %s %s", SequenceCmd:Get(1).JumpLoopCnt, self.SequenceCmd:Get(1).JumpLoopCnt, self.SequenceCmdBak:Get(1).JumpLoopCnt)
-- 	self:BeginRunSequenceCmd()
-- end

-- function ClusterSlaveComponent:SequenceCmdTick()
-- 	if self.SequenceCmd:Length() == 0 or self.SequenceCmdIdx == 0 then
-- 		return
-- 	end

-- 	local CurCmdState = self:GetCurCmdState()
-- 	local NowMs = G.GetNowTimestampMs()

-- 	local SequenceEle = self.SequenceCmd:Get(self.SequenceCmdIdx)
-- 	if SequenceEle.TurnType == Enum.Enum_ClusterSequenceCmdTurnType.Start then
-- 		if NowMs - CurCmdState.CmdStartTime > SequenceEle.HowLongHasItBeen * 1000 then
-- 			-- G.log:error("yj", "Start next NowMs.%s CmdStartTime.%s HowLong.%s", NowMs, CurCmdState.CmdStartTime, SequenceEle.HowLongHasItBeen * 1000)
-- 			self:RunNextSequenceCmd()
-- 		end
-- 	elseif SequenceEle.TurnType == Enum.Enum_ClusterSequenceCmdTurnType.Finish then
-- 		if CurCmdState.CmdFinishTime > CurCmdState.CmdStartTime and NowMs - CurCmdState.CmdFinishTime > SequenceEle.HowLongHasItBeen * 1000 then
-- 			-- G.log:error("yj", "Finish next NowMs.%s CmdFinishTime.%s CmdStartTime.%s HowLong.%s", NowMs, CurCmdState.CmdFinishTime, CurCmdState.CmdStartTime, SequenceEle.HowLongHasItBeen * 1000)
-- 			self:RunNextSequenceCmd()
-- 		end
-- 	end
-- end

-- function ClusterSlaveComponent:BeginRunSequenceCmd()
-- 	if self.SequenceCmd:Length() == 0 then
-- 		return
-- 	end

-- 	self.SequenceCmdIdx = 1
-- 	local SequenceEle = self.SequenceCmd:Get(self.SequenceCmdIdx)
-- 	local ClusterCmd = self:GenClusterCmdBySequenceEle(SequenceEle)
-- 	self:_ReceiveClusterCmd(ClusterCmd)
-- end

-- function ClusterSlaveComponent:RunNextSequenceCmd()
-- 	local CurSequenceEle = self.SequenceCmd:GetRef(self.SequenceCmdIdx)
-- 	local CurSequenceEleBak = self.SequenceCmdBak:GetRef(self.SequenceCmdIdx)
-- 	if CurSequenceEle.JumpLoopCnt == 1 then
-- 		-- G.log:error("yj", "RunNextSequenceCmd CurFinish.%s CurLoopCnt.(%s-%s) NextIdx.%s BigLoop.%s", self.SequenceCmdIdx, CurSequenceEle.JumpLoopCnt, CurSequenceEleBak.JumpLoopCnt, self.SequenceCmdIdx + 1, self.SequenceLoopCnt)
-- 		self.SequenceCmdIdx = self.SequenceCmdIdx + 1
-- 	else
-- 		-- 小循环（小于1表示无限循环，大于1表示循环次数，每次递减，减到1就不会再减了）
-- 		-- G.log:error("yj", "RunNextSequenceCmd CurFinish.%s CurLoopCnt.(%s-%s) NextIdx.%s BigLoop.%s", self.SequenceCmdIdx, CurSequenceEle.JumpLoopCnt, CurSequenceEleBak.JumpLoopCnt, CurSequenceEle.JumpTo + 1, self.SequenceLoopCnt)
-- 		self.SequenceCmdIdx = CurSequenceEle.JumpTo + 1
-- 		if CurSequenceEle.JumpLoopCnt > 1 then
-- 			CurSequenceEle.JumpLoopCnt = CurSequenceEle.JumpLoopCnt - 1
-- 		end
-- 	end

-- 	if self.SequenceCmdIdx > self.SequenceCmd:Length() then
-- 		if self.SequenceLoopCnt == 1 then
-- 			self.SequenceCmd:Clear()
-- 			self.SequenceCmdIdx = 0
-- 		else
-- 			-- 大循环
-- 			self.SequenceCmd = self.SequenceCmdBak
-- 			self:BeginRunSequenceCmd()
-- 			if self.SequenceLoopCnt > 1 then
-- 				self.SequenceLoopCnt = self.SequenceLoopCnt - 1
-- 			end
-- 		end
-- 		return
-- 	end

-- 	local NextSequenceEle = self.SequenceCmd:Get(self.SequenceCmdIdx)
-- 	local ClusterCmd = self:GenClusterCmdBySequenceEle(NextSequenceEle)
-- 	self:_ReceiveClusterCmd(ClusterCmd)
-- end

-- function ClusterSlaveComponent:GenClusterCmdBySequenceEle(SequenceEle)
--     local ClusterCmd = Struct.UD_ClusterCmd()
--     ClusterCmd.CmdType = SequenceEle.CmdType

--     if ClusterCmd.CmdType == Enum.Enum_ClusterCmdType.UseSkill then
--         ClusterCmd.SkillClass = ai_utils.RandomClusterSkillClass(SequenceEle.SkillClassMap)

--     elseif ClusterCmd.CmdType == Enum.Enum_ClusterCmdType.Perform then
--         ClusterCmd.PerformMontage = ai_utils.RandomClusterPerformMontage(SequenceEle.PerformMontageMap)

--     elseif ClusterCmd.CmdType == Enum.Enum_ClusterCmdType.ArcMove then
--     	local _, _, Location = self.ClusterMaster.ClusterMasterComponent:RegionIdx2Location(SequenceEle.RegionIdx)
--         ClusterCmd.TargetLocation = Location
--     end

--     return ClusterCmd
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:ReceiveClusterCmd(Cmd)
-- 	self.SequenceCmd:Clear()
-- 	self.SequenceCmdIdx = 0
-- 	self:_ReceiveClusterCmd(Cmd)
-- end

-- function ClusterSlaveComponent:_ReceiveClusterCmd(Cmd)
-- 	local CurCmdState = self:GetCurCmdState()
-- 	if CurCmdState and CurCmdState.CmdResult == Enum.Enum_ClusterCmdResult.Runing then
-- 		-- if Cmd.CmdType <= self.ClusterCmd.CmdType then
-- 		-- 	-- 打断
-- 		-- 	self.InterruptCurCmd = true
-- 		-- else
-- 		-- 	-- 忽略
-- 		-- 	self.ClusterCmd = Cmd
-- 		-- 	local CurCmdState = self:GetCurCmdState()
-- 		-- 	CurCmdState.CmdStartTime = G.GetNowTimestampMs()
-- 		-- 	CurCmdState.CmdResult = Enum.Enum_ClusterCmdResult.Ignore
-- 		-- 	CurCmdState.CmdFinishTime = CurCmdState.CmdStartTime
-- 		-- 	G.log:warn("yj", "ClusterSlaveComponent:ReceiveClusterCmd ignore cmd.%s", Cmd.CmdType)
-- 		-- 	return
-- 		-- end

-- 		-- 移动指令可以互相打断
-- 		if Cmd.CmdType == self.ClusterCmd.CmdType and Cmd.CmdType == Enum.Enum_ClusterCmdType.ArcMove then
-- 			self.InterruptCurCmd = true
-- 		end

-- 		-- 不同的指令之间可以互相打断（但Return指令不能被打断）
-- 		if Cmd.CmdType ~= self.ClusterCmd.CmdType and self.ClusterCmd.CmdType ~= Enum.Enum_ClusterCmdType.Return then
-- 			self.InterruptCurCmd = true
-- 		end
-- 	end

-- 	-- TODO - 改成触发式
-- 	self.ClusterCmd = Cmd
-- 	local CurCmdState = self:GetCurCmdState()
-- 	CurCmdState.CmdStartTime = G.GetNowTimestampMs()
-- 	CurCmdState.CmdResult = Enum.Enum_ClusterCmdResult.Init
-- 	-- G.log:error("yj", "ClusterSlaveComponent:ReceiveClusterCmd %s Cmd.%s %s", self.FormIdx, self.ClusterCmd.CmdType, CurCmdState.CmdStartTime)
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:StartExecClusterCmd()
-- 	local CurCmdState = self:GetCurCmdState()
-- 	CurCmdState.CmdResult = Enum.Enum_ClusterCmdResult.Runing
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:InterruptExecClusterCmd()
--     self.InterruptCurCmd = false
-- end

-- decorator.message_receiver()
-- function ClusterSlaveComponent:FinishExecClusterCmd(IsSuccess)
-- 	local CurCmdState = self:GetCurCmdState()
-- 	if IsSuccess then
-- 		CurCmdState.CmdResult = Enum.Enum_ClusterCmdResult.Succeeded
-- 	else
-- 		CurCmdState.CmdResult = Enum.Enum_ClusterCmdResult.Failed
-- 	end

-- 	CurCmdState.CmdFinishTime = G.GetNowTimestampMs()

-- 	-- G.log:info("yj", "ClusterSlaveComponent:FinishExecClusterCmd %s", self.ClusterCmd)
-- end


return ClusterSlaveComponent
