local AppearanceBase = require("actors.common.components.common_appearance")
local Component = require("common.component")
local G = require("G")

local check_table = require("common.data.state_conflict_data")
local HeroInitData = require("common.data.hero_initial_data").data

---@type BP_AvatarAppearance_C
local AvatarAppearence = Component(AppearanceBase)

local decorator = AvatarAppearence.decorator

function AvatarAppearence:CheckSprintCostAndCD(Action)
	return self.actor.PlayerState.AttributeComponent:TryBeginAction(check_table.Action_Sprint, Enum.Enum_ActionType.Sprint)
end

decorator.require_check_action(check_table.Action_Sprint, AvatarAppearence.CheckSprintCostAndCD)
function AvatarAppearence:StartSprintAction()
	-- G.log:error("devin", "AvatarAppearence:StartSprintAction 111 %s", tostring(value))
	self.Overridden.SprintAction(self, true)
end

function AvatarAppearence:StopSprintAction()
	-- G.log:error("devin", "AvatarAppearence:StopSprintAction")
	self.Overridden.SprintAction(self, false)
	if self.actor:IsPlayer() then
		self:SendMessage("EndState", check_table.State_Sprint)
	end
end

function AvatarAppearence:SprintAction(value)
	if value then
		if self.DesiredGait == UE.EHiGait.Sprinting then
			return
		end
		self:StartSprintAction()
		if self.DesiredGait == UE.EHiGait.Sprinting then
			if self.actor:IsPlayer() then
				self:Server_SprintAction(value)
			end
		end
	else
		if self.DesiredGait ~= UE.EHiGait.Sprinting then
			return
		end
		self:StopSprintAction()
		if self.actor:IsPlayer() then
			self:Server_SprintAction(value)
		end
	end
end

function AvatarAppearence:Server_SprintAction_RPC(Value)
	if Value then
		if not self.actor.PlayerState.AttributeComponent:TryBeginAction(check_table.Action_Sprint, Enum.Enum_ActionType.Sprint) then
			self:Client_RejectSprintAction()
			return
		end
	else
		self.actor.PlayerState.AttributeComponent:TryEndAction(Enum.Enum_ActionType.Sprint)
	end

	self.actor:GetLocomotionComponent():SprintAction(Value)
end

function AvatarAppearence:Client_RejectSprintAction_RPC()
	self:StopSprintAction()
end

decorator.message_receiver()
function AvatarAppearence:BreakSprint(reason)
	-- G.log:error("devin", "AvatarAppearence:BreakSprint")
	self:SprintAction(false)
end

function AvatarAppearence:OnActorRotateUpdateCamera(Rotation)
	local PlayerCameraManager = UE.UGameplayStatics.GetPlayerController(self.actor:GetWorld(), 0).PlayerCameraManager
	PlayerCameraManager:PlayAnimation_Rotate(Orientation, RotateHalfLife)
end

decorator.message_receiver()
function AvatarAppearence:CloneGait(FromAvatar)
	local lastGait = FromAvatar:GetLocomotionComponent().Gait
	self:SetDesiredGait(lastGait)
end

decorator.message_receiver()
function AvatarAppearence:OnDead(SourceActor, DeadReason)
	--G.log:debug("hycoldrain", "AvatarAppearence:OnDead.... %s  %s",self.actor:GetLocalRole(), self.actor:IsServer())
	if self.actor and self.actor:IsValid() then
		if self.actor:IsClient() then
			utils.ShowTemplateTips("PLAYER_DEAD", 2, HeroInitData[self.actor.CharType].name)
		end

		local FinishCallback = nil
		if self.actor:IsClient() then
			self:SendMessage("ExecuteAction", check_table.Action_Die)
			FinishCallback = function () 
				self.actor:K2_GetRootComponent():SetVisibility(false, true)
			end
		else
			if self.actor:HasAuthority() then			
				FinishCallback = function () 
					G.log:debug("hycoldrain", "AvatarAppearence:DeadLevelSequence OnFinish")
					local PlayerController = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)

					-- TODO 这里最好判断下是否为前台角色，可能会出现后台角色死亡.
					PlayerController:SendMessage("OnCurrentPlayerDead", DeadReason)
					-- self.actor:K2_GetRootComponent():SetVisibility(false, true)
					-- self.actor.bVisibleOnServer=false
					self.actor:SetVisibility_RepNotify(false,true)
				end
			end
		end

		if self.DeadMontage then
			local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, self.DeadMontage, 1.0)
        	PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, FinishCallback)
        	PlayMontageCallbackProxy.OnCompleted:Add(self.actor, FinishCallback)
		else
			FinishCallback()
		end
	end
end

function AvatarAppearence:EnterSkillAnimWithIdleActing(IdleActingBehavior)
	self:EnterSkillAnim(IdleActingBehavior)
	self.actor.IdleActingComponent:OnSkillAnimStateChanged(true, IdleActingBehavior)
end

function AvatarAppearence:LeaveSkillAnimWithIdleActing(IdleActingBehavior)
	self:LeaveSkillAnim(IdleActingBehavior)
	self.actor.IdleActingComponent:OnSkillAnimStateChanged(false, IdleActingBehavior)
end

return AvatarAppearence