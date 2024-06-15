-- 预制技 - 鬼手

require "UnLua"

local G = require("G")

local Projectile = require("actors.common.Projectile")

local Projectile_GuiShou = Class(Projectile)

function Projectile_GuiShou:Initialize(...)
    Super(Projectile_GuiShou).Initialize(self, ...)
end

function Projectile_GuiShou:Init()
    Super(Projectile_GuiShou).Init(self)

    self.MaxLength = 5000  -- 鬼手最长50M
    self.IsMoveBack = false
    self.IsStopMove = false

    self.SourceActor:SendMessage("OnGuiShouCreate")
end

function Projectile_GuiShou:ReceiveTick(DeltaSeconds)
	if self:IsClient() then
		return
	end

	self:GuiShouMove(DeltaSeconds)

	local Dis = UE.UKismetMathLibrary.Vector_Distance(self:K2_GetActorLocation(), self.SourceActor:K2_GetActorLocation())
	if self.IsStopMove or self.IsMoveBack then
    	if Dis < 100 then
			self.SourceActor:Replicated_StopMontage()
 			-- self.SourceActor:SetGuiShouLocation(self:K2_GetActorLocation(), 0)
            self.SourceActor:SendMessage("SetGuiShouLocation", self:K2_GetActorLocation(), 0)
            self.SourceActor:SendMessage("OnGuiShouDestroy")
    		self:K2_DestroyActor()
    		return
    	end
	end

	-- 手臂
 	self.SourceActor:SendMessage("SetGuiShouLocation", self:K2_GetActorLocation(), Dis - 500)
end

function Projectile:GuiShouMove(DeltaSeconds)
	if self.IsStopMove then
		return
	end

    if not self.IsMoveBack then
    	self:MoveForward(DeltaSeconds)
    else
    	self:MoveBack(DeltaSeconds)
    end

	local Dis = UE.UKismetMathLibrary.Vector_Distance(self:K2_GetActorLocation(), self.SourceActor:K2_GetActorLocation())
    if Dis > self.MaxLength then
    	self.IsMoveBack = true
    end
end

function Projectile:MoveForward(DeltaSeconds)
    local HDelta = self:K2_GetRootComponent():GetForwardVector() * self.CurHSpeed * DeltaSeconds
    local VDelta = self:K2_GetRootComponent():GetUpVector() * self.CurVSpeed * DeltaSeconds

    local Forward = UE.UKismetMathLibrary.Conv_RotatorToVector(self:K2_GetActorRotation())
    self:K2_SetActorLocation(self:K2_GetActorLocation() + HDelta + VDelta, true, UE.FHitResult(), true)

    self:UpdateSpeed(DeltaSeconds)
end

function Projectile_GuiShou:MoveBack(DeltaSeconds)
	local Forward = UE.UKismetMathLibrary.Normal(self:K2_GetActorLocation() - self.SourceActor:K2_GetActorLocation())
    self:K2_SetActorRotation(UE.UKismetMathLibrary.Conv_VectorToRotator(Forward), true)
    local TargetLocation = self:K2_GetActorLocation() - Forward * 8000 * DeltaSeconds
	self:K2_SetActorLocation(TargetLocation, true, UE.FHitResult(), true)
end

function Projectile_GuiShou:BeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if OtherActor == self or OtherActor == self.SourceActor then
        return
    end

    if OtherActor.CharIdentity and OtherActor.CharIdentity == Enum.Enum_CharIdentity.Player then
    	return
    end

    if self.IsStopMove or self.IsMoveBack then
        return
    end

    if OtherActor.CharIdentity == nil then
	    -- self.SourceActor:SendMessage("OnGuiShouHitWorldStatic", self:K2_GetActorLocation(), OtherActor)
	    -- self.IsStopMove = true
	elseif OtherActor.CharIdentity == Enum.Enum_CharIdentity.Monster and OtherActor.MonsterType == Enum.Enum_MonsterType.Boss then
	    self.SourceActor:SendMessage("OnGuiShouHitWorldStatic", self:K2_GetActorLocation(), OtherActor)
	    self.IsStopMove = true
	else
	    -- self.SourceActor:SendMessage("OnGuiShouHitMonster", self, self:K2_GetActorLocation(), OtherActor)
	    OtherActor:SendMessage("OnHitByGuiShou", self)
	    self.IsMoveBack = true
    end

end

function Projectile_GuiShou:HitCallback(ChannelType, Hit)
	-- Hook
end

return RegisterActor(Projectile_GuiShou)
