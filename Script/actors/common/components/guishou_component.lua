local G = require("G")
local check_table = require("common.data.state_conflict_data")

local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local GuiShouComponent = Component(ComponentBase)

local decorator = GuiShouComponent.decorator


function GuiShouComponent:Initialize(...)
    Super(GuiShouComponent).Initialize(self, ...)
    self.GuiShouTargetLocation = nil
    self.GuiShouActorOwner = nil
end

decorator.message_receiver()
function GuiShouComponent:PostBeginPlay()
    if self.GA_GuiShouClass then
        self.actor.SkillComponent:GiveAbility(self.GA_GuiShouClass, 0)
    end
end

decorator.message_receiver()
function GuiShouComponent:OnGuiShouCreate()
	if not self.actor:IsOnFloor() then
		self.ZGHandle = self.actor.ZeroGravityComponent:EnterZeroGravity(10, false)
	end

    self.actor:Client_SendMessage("Client_OnGuiShouCreate")

	self:CreateGuiShou()
end

decorator.message_receiver()
function GuiShouComponent:SetGuiShouLocation(Location, Length)
	self:OnSetGuiShouLocation(Location, Length)
end

decorator.message_receiver()
function GuiShouComponent:OnGuiShouDestroy()
    self.actor:Client_SendMessage("Client_OnGuiShouDestroy")

    self:DestroyGuiShou()
end

function GuiShouComponent:CreateGuiShou()
	if self.GuiShouClass ~= nil and self.GuiShou == nil then
        self.GuiShou = GameAPI.SpawnActor(self.actor:GetWorld(), self.GuiShouClass, self.actor:GetTransform(), UE.FActorSpawnParameters(), {})
    end
    assert(self.GuiShou)
end

function GuiShouComponent:DestroyGuiShou()
	if self.GuiShou then
	    self.GuiShou:K2_DestroyActor()
	    self.GuiShou = nil
	end
end

function GuiShouComponent:OnRep_GuiShou()
	if self.GuiShou then
		if self.RopeClass ~= nil and self.Rope == nil then
	        self.Rope = GameAPI.SpawnActor(self.actor:GetWorld(), self.RopeClass, self.actor:GetTransform(), UE.FActorSpawnParameters(), {})
	        self.Rope:K2_GetRootComponent():K2_AttachToComponent(self.actor:K2_GetRootComponent(), "", UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget)
		    self.Rope:K2_GetRootComponent():SetAttachEndTo(self.GuiShou, "")
	    end
	    assert(self.Rope)
	else
		if self.Rope ~= nil then
		    self.Rope:K2_DestroyActor()
		    self.Rope = nil
		end
	end
end

decorator.message_receiver()
function GuiShouComponent:Client_OnGuiShouCreate()
	if not self.actor:IsOnFloor() then
		-- TODO - 临时处理空中使用钩锁拉回怪物被撞飞的问题
		if self.actor.CapsuleComponent:GetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Pawn) ~= UE.ECollisionResponse.ECR_Ignore then
			self.actor.CapsuleComponent:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Pawn, UE.ECollisionResponse.ECR_Ignore)
		end
	end

	self:SendMessage("EnterState", check_table.State_Skill)
end

decorator.message_receiver()
function GuiShouComponent:Client_OnGuiShouDestroy()
	if not self.actor:IsOnFloor() then
	    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self.actor, self.actor.EndZeroGravity}, 0.3, false)
	end	

	if self.actor.CapsuleComponent:GetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Pawn) ~= UE.ECollisionResponse.ECR_Block then
		self.actor.CapsuleComponent:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Pawn, UE.ECollisionResponse.ECR_Block)
	end

	self:SendMessage("EndState", check_table.State_Skill)
end

decorator.message_receiver()
function GuiShouComponent:OnGuiShouHitWorldStatic(ImpactPoint, OtherActor)
	self:BeginFlyToWorldStaticImpactPoint(ImpactPoint)
end

decorator.message_receiver()
function GuiShouComponent:OnHitByGuiShou(GuiShouActor)
	self:BeginFlyToGuishouOwner(GuiShouActor)
end

decorator.message_receiver()
function GuiShouComponent:OnReceiveTick(DeltaSeconds)

	-- G.log:debug("yj", "GuiShouComponent:OnReceiveTick TickEnabled.%s IsClient.%s", self.Rope:K2_GetRootComponent():IsComponentTickEnabled(), self.actor:IsClient())

	if self.actor:IsClient() then
	    -- G.log:debug("yj", "GuiShouComponent:OnReceiveTick self.%s GuiShou.%s Rope.%s IsClient.%s", 
	    -- 	self.actor:GetDisplayName(), G.GetDisplayName(self.GuiShou), G.GetDisplayName(self.Rope), self.actor:IsClient())
		return
	end

	if self.actor.CharIdentity == Enum.Enum_CharIdentity.Player then
		self:OnReceiveTick_Player(DeltaSeconds)
	else
		self:OnReceiveTick_Monster(DeltaSeconds)
	end
end

function GuiShouComponent:OnReceiveTick_Player(DeltaSeconds)
	if self.GuiShouTargetLocation == nil then
		return
	end

	self.TotalFlyTime = self.TotalFlyTime - DeltaSeconds
	local Dis = UE.UKismetMathLibrary.Vector_Distance(self.actor:K2_GetActorLocation(), self.GuiShouTargetLocation)
	if self.TotalFlyTime < 0 or Dis < 100 then
		self:EndFlyToWorldStaticImpactPoint(self.GuiShouTargetLocation)
		return
	end

    self.actor.AppearanceComponent:Multicast_SmoothActorLocation(self.GuiShouTargetLocation, 3000, DeltaSeconds)
end

function GuiShouComponent:OnReceiveTick_Monster(DeltaSeconds)
	if self.GuiShouActorOwner == nil then
		return
	end

	self.TotalFlyTime = self.TotalFlyTime - DeltaSeconds
	local Dis = UE.UKismetMathLibrary.Vector_Distance(self.actor:K2_GetActorLocation(), self.GuiShouActorOwner:K2_GetActorLocation())
	if self.TotalFlyTime < 0 or Dis < 300 then
		self:EndFlyToGuishouOwner()
		return
	end

    self.actor.AppearanceComponent:Multicast_SmoothActorLocation(self.GuiShouActorOwner:K2_GetActorLocation(), 8000, DeltaSeconds)
end

function GuiShouComponent:BeginFlyToWorldStaticImpactPoint(ImpactPoint)
	self.GuiShouTargetLocation = ImpactPoint

	local Dis = UE.UKismetMathLibrary.Vector_Distance(self.actor:K2_GetActorLocation(), self.GuiShouTargetLocation)
	self.TotalFlyTime = Dis / 3000 + 1.0

	self:ClientBeginFlyToWorldStaticImpactPoint()
end

function GuiShouComponent:EndFlyToWorldStaticImpactPoint(ImpactPoint)
	self.GuiShouTargetLocation = nil
	self:ClientEndFlyToWorldStaticImpactPoint()
end

function GuiShouComponent:ClientBeginFlyToWorldStaticImpactPoint_RPC()
	self:SendMessage("EnterState", check_table.State_ForbidMove)
end

function GuiShouComponent:ClientEndFlyToWorldStaticImpactPoint_RPC()
	self:SendMessage("EndState", check_table.State_ForbidMove)
end

function GuiShouComponent:BeginFlyToGuishouOwner(GuiShouActor)
	self.GuiShouActorOwner = GuiShouActor.SourceActor
	local Dis = UE.UKismetMathLibrary.Vector_Distance(GuiShouActor:K2_GetActorLocation(), self.GuiShouActorOwner:K2_GetActorLocation())
	self.TotalFlyTime = Dis / 8000 + 1.0
	self.actor.ZeroGravityComponent:EnterZeroGravity(10, false)
end

function GuiShouComponent:EndFlyToGuishouOwner()
	local OwnerLocation = self.GuiShouActorOwner:K2_GetActorLocation()
	local OwnerRotation = self.GuiShouActorOwner:K2_GetActorRotation()

	local Normal = UE.UKismetMathLibrary.Normal(UE.UKismetMathLibrary.Conv_RotatorToVector(OwnerRotation))
	self.actor:K2_SetActorLocation(OwnerLocation + Normal * 50, false, nil, true)

	local SelfLocation = self.actor:K2_GetActorLocation()
	local FowardWithoutZ = UE.FVector(OwnerLocation.X, OwnerLocation.Y, 0) - UE.FVector(SelfLocation.X, SelfLocation.Y, 0)
	self.actor:K2_SetActorRotation(UE.UKismetMathLibrary.Conv_VectorToRotator(FowardWithoutZ), true)

    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self.actor, self.actor.EndZeroGravity}, 0.3, false)
	self.GuiShouActorOwner = nil
end

-- decorator.message_receiver()
-- function GuiShouComponent:AfterSetVisibility(InVisible)
-- 	local Dis = UE.UKismetMathLibrary.Vector_Distance(self.actor:K2_GetActorLocation(), self.actor.GuiShou:K2_GetComponentLocation())
-- 	if Dis < 100 then
-- 		self.Rope:SetVisibility(false)
-- 		self.GuiShou:SetVisibility(false)
-- 	end
-- end

return GuiShouComponent
