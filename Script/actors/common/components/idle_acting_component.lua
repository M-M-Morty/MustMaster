local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local G = require("G")

local IdleActingComponent = Component(ComponentBase)

local decorator = IdleActingComponent.decorator

local INTERRUPT_BLEND_DURATION = 0.1

function IdleActingComponent:ReceiveBeginPlay()
    Super(IdleActingComponent).ReceiveBeginPlay(self)
	self.IsBreakSkill = false
	self.ActingMontage = nil
	self.PlayingIdleActingEndMontageList = self.DefaultBattleEndMontageList
	self.RemoveTimer = nil
	self.IdleAnimInstance = nil
	if UE.UHiUtilsFunctionLibrary.IsClientWorld() then
		self.IdleAnimInstance = self.actor.Mesh:GetAnimInstance() -- self.actor.Mesh:GetLinkedAnimGraphInstanceByTag("Locomotion")
		-- 表现层的动画只在客户端触发
		self.actor.AppearanceComponent.MovementInputChangedDelegate:Add(self, self.OnMovementInputChanged)
	end
end

function IdleActingComponent:OnInitializedAnimInstance()
	if UE.UHiUtilsFunctionLibrary.IsClientWorld() then
		self.IdleAnimInstance = self.actor.Mesh:GetAnimInstance() -- self.actor.Mesh:GetLinkedAnimGraphInstanceByTag("Locomotion")
	end
end

decorator.message_receiver()
function IdleActingComponent:OnBreakSKill(reason)
	self.IsBreakSkill = true
end

function IdleActingComponent:OnSkillAnimStateChanged(IsInSkillAnim, IdleActingBehavior)
	if self.IsBreakSkill then
		self.IsBreakSkill = false
		return
	end
	self.IsBreakSkill = false
	if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
		return
	end
	-- G.log:error("zaleggzhao", "OnSkillAnimStateChanged: %s", IsInSkillAnim)
	-- Reset acting montage data
	if self.RemoveTimer ~= nil then
		UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.RemoveTimer)
		self.RemoveTimer = nil
	end
	self.ActingMontage = nil

	if IsInSkillAnim then
		return
	end

	-- Ignore trigger idle acting when not on ground or moving
	if self.actor.CharacterMovement.MovementMode ~= UE.EMovementMode.MOVE_Walking then
		self:InterruptActingMontage()
		return
	end
	if self.actor.AppearanceComponent.bHasMovementInput then
		self:InterruptActingMontage()
		return
	end

	-- Play animation
	if IdleActingBehavior.Behavior == Enum.BPE_IdleActingType.Default then
		self.PlayingIdleActingEndMontageList = self.DefaultBattleEndMontageList
		self:PlayActingMontage(self.DefaultBattleIdleMontage)
	elseif IdleActingBehavior.Behavior == Enum.BPE_IdleActingType.Custom then
		self.PlayingIdleActingEndMontageList = IdleActingBehavior.CustomEndMontageList
		self:PlayActingMontage(IdleActingBehavior.CustomIdleMontage)
	else	-- Enum.BPE_IdleActingType.None
		self:InterruptActingMontage(INTERRUPT_BLEND_DURATION)
	end
end

function IdleActingComponent:OnMovementInputChanged(bHasInputMovement)
	-- G.log:error("zaleggzhao", "OnMovementInputChanged: %s %s", bHasInputMovement, G.GetDisplayName(self.ActingMontage))
	if bHasInputMovement then
		self:InterruptActingMontage(INTERRUPT_BLEND_DURATION)
	end
end

decorator.message_receiver()
function IdleActingComponent:OnMovementModeChanged(PrevMovementMode, NewMovementMode, PreCustomMode, NewCustomMode)
	if NewMovementMode ~= UE.EMovementMode.MOVE_Walking then
		self:InterruptActingMontage(INTERRUPT_BLEND_DURATION)
	end
end

function IdleActingComponent:PlayActingMontage(AnimMontage)
	if not AnimMontage then
		return
	end

	-- G.log:error("zaleggzhao", "PlayActingMontage")
	self.ActingMontage = AnimMontage
	self.IdleAnimInstance:Montage_Play(AnimMontage)
	self.RemoveTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.DelayEndActingMontage }, self.DefaultActingDuration, false)
end

function IdleActingComponent:DelayEndActingMontage()
	if self.ActingMontage then
		if self.PlayingIdleActingEndMontageList:Num() == 0 then
			self.IdleAnimInstance:Montage_Stop(self.ActingMontage.BlendOut.BlendTime, self.ActingMontage)
			self.ActingMontage = nil
		else
			-- G.log:error("zaleggzhao", "DelayEndActingMontage")
			local MontageIndex = math.random(1, self.PlayingIdleActingEndMontageList:Num())
			self.ActingMontage = self.PlayingIdleActingEndMontageList[MontageIndex]
			self.IdleAnimInstance:Montage_Play(self.ActingMontage)
		end
	end
end

function IdleActingComponent:InterruptActingMontage(BlendDuration)
	if self.ActingMontage then
		if self.RemoveTimer ~= nil then
			UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.RemoveTimer)
		end
		self.IdleAnimInstance:Montage_Stop(BlendDuration, self.ActingMontage)
		self.ActingMontage = nil
	end
end

return IdleActingComponent
