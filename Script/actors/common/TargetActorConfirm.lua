require "UnLua"

-- TargetActorConfirm implement in lua.
local G = require("G")
local TargetActor = require("actors.common.TargetActor")

local TargetActorConfirm = Class(TargetActor)


function TargetActorConfirm:Initialize(...)
    Super(TargetActorConfirm).Initialize(self, ...)
end

function TargetActorConfirm:OnStartTargeting(Ability)
	Super(TargetActorConfirm).OnStartTargeting(self, Ability)
	if self.SourceActor:IsClient() and self.ReticleClass then
		self.SourceActor:SendMessage("CreateReticleActor", self.ReticleClass)
	end
end

function TargetActorConfirm:OnConfirmTargetingAndContinue()
	-- G.log:debug("yj", "TargetActorConfirm:OnConfirmTargetingAndContinue %s", G.GetDisplayName(self.SourceActor))
	if self.SourceActor:IsClient() then
    	self.SourceActor:SendMessage("SyncCameraLocationAndRotationToServer")
		if self.ReticleClass then
			self.SourceActor:SendMessage("DestroyReticleActor")
	    end

        -- if ConfirmationType == UserConfirmed then Broadcast will send GenericConfim event to Server else do nothing
        self:BroadcastTargetDataHandleWithHitResults(UE.TArray(UE.FHitResult))
	else

	    self.SkillTarget = self.SourceActor:GetLockTarget()
    	self:_InitStartLocation()
		Super(TargetActorConfirm).OnConfirmTargetingAndContinue(self)
	end
end

function TargetActorConfirm:ReceiveDestroyed()
	-- G.log:debug("yj", "TargetActorConfirm:ReceiveDestroyed")
	if self.ReticleClass then
		self.SourceActor:SendMessage("DestroyReticleActor")
    end
end

return RegisterActor(TargetActorConfirm)
