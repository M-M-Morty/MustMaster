local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local BurstPointComponent = Component(ComponentBase)
local decorator = BurstPointComponent.decorator

-- local MaxBurstPerActor = 20

-- decorator.message_receiver()
-- function BurstPointComponent:PostBeginPlay()
--     if not self.actor:IsClient() then
--     	if self.BurstGA then
-- 	    	self.actor.SkillComponent:GiveAbility(self.BurstGA, 0)
-- 	    end

--     	if self.BurstGA_Self then
-- 	    	self.actor.SkillComponent:GiveAbility(self.BurstGA_Self, 0)
-- 	    end
--     end
-- end

-- decorator.message_receiver()
-- function BurstPointComponent:OnFuYouPaoBegin(BurstPoint)

-- 	self:ClearBurstPoint()

--     self.BurstNumOnTarget = 0
--     self.BurstNumOnSelf = 0
-- end

-- function BurstPointComponent:AddBurstPoint(BurstPoint)

-- 	local Dis2Self = UE.UKismetMathLibrary.Vector_Distance2D(BurstPoint, self.actor:K2_GetActorLocation())
-- 	local Dis2Target = UE.UKismetMathLibrary.Vector_Distance2D(BurstPoint, self.actor.TargetActor:K2_GetActorLocation())

-- 	if Dis2Target < Dis2Self then
-- 		-- burst on target
-- 		if self.BurstNumOnTarget >= MaxBurstPerActor then
-- 			return
-- 		end
-- 		self.BurstNumOnTarget = self.BurstNumOnTarget + 1
-- 	else
-- 		-- burst on self
-- 		if self.BurstNumOnSelf >= MaxBurstPerActor then
-- 			return
-- 		end
-- 		self.BurstNumOnSelf = self.BurstNumOnSelf + 1
-- 	end

-- 	-- if Dis2Target < Dis2Self then
-- 	-- 	G.log:debug("yj", "BurstPointComponent:AddBurstPoint %s %s BurstNumOnTarget.%s", BurstPoint, self.actor:IsClient(), self.BurstNumOnTarget)
-- 	-- else
-- 	-- 	G.log:debug("yj", "BurstPointComponent:AddBurstPoint %s %s BurstNumOnSelf.%s", BurstPoint, self.actor:IsClient(), self.BurstNumOnSelf)
-- 	-- end

-- 	self.BurstPoints:Add(BurstPoint)
-- end

-- function BurstPointComponent:IsBurstOnTarget()
-- 	return self.BurstNumOnTarget > 0
-- end

-- decorator.message_receiver()
-- function BurstPointComponent:OnReceiveTick(DeltaSeconds)
-- 	if not self.actor:IsClient() and self:GetBurstPointsNum() > 0 then

--         local BurstPoint = self:GetBurstPoint()
-- 		local Dis2Self = UE.UKismetMathLibrary.Vector_Distance2D(BurstPoint, self.actor:K2_GetActorLocation())
-- 		local Dis2Target = UE.UKismetMathLibrary.Vector_Distance2D(BurstPoint, self.actor.TargetActor:K2_GetActorLocation())

-- 		-- if Dis2Target < Dis2Self then
-- 		-- 	G.log:debug("yj", "BurstPointComponent:OnReceiveTick Name.%s BurstNumOnTarget.%s", self.actor:GetDisplayName(), self.BurstNumOnTarget)
-- 		-- else
-- 		-- 	G.log:debug("yj", "BurstPointComponent:OnReceiveTick Name.%s BurstNumOnSelf.%s", self.actor:GetDisplayName(), self.BurstNumOnSelf)
-- 		-- end

-- 		local ASC = self.actor:GetASC()
-- 		if Dis2Target < Dis2Self then
-- 			ASC:TryActivateAbilityByClass(self.BurstGA)
-- 		else
-- 			ASC:TryActivateAbilityByClass(self.BurstGA_Self)
-- 		end

--         self:SubBurstPoint()
-- 	end
-- end


return BurstPointComponent
