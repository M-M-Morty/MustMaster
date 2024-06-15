local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local check_table = require("common.data.state_conflict_data")
local G = require("G")

local GodViewComponent = Component(ComponentBase)

local decorator = GodViewComponent.decorator

function GodViewComponent:Initialize(...)
    Super(GodViewComponent).Initialize(self, ...)
    self.PlayerController = nil
    self.GodPlayer = nil
end

decorator.message_receiver()
function GodViewComponent:OnReceiveTick(DeltaSeconds)
	if not self.actor:IsClient() then
		return
	end

	if not self.PlayerController then
		return
	end

    self.PlayerController.PlayerCameraManager:PlayAnimation_WatchTarget(self.actor)
end

decorator.message_receiver()
function GodViewComponent:EnterGodView()
	if self.actor:IsClient() then
		return
	end

	-- only run on server

	self.actor:Client_SendMessage("Client_EnterGodView")

    local Path = "/Game/Blueprints/Character/BPA_AvatarBase.BPA_AvatarBase_C"
    local GodClass = UE.UClass.Load(Path)

    local SpawnParameters = UE.FActorSpawnParameters()
    SpawnParameters.Instigator = self.actor
    local SpawnLocation = self.actor:K2_GetActorLocation() + UE.FVector(0, 0, 1000)
    local SpawnRotation = self.actor:K2_GetActorRotation()
	local SpawnTransform = UE.UKismetMathLibrary.MakeTransform(SpawnLocation, SpawnRotation, UE.FVector(1, 1, 1))
    self.GodPlayer = GameAPI.SpawnActor(self.actor:GetWorld(), GodClass, SpawnTransform, SpawnParameters, {})
    self.GodPlayer.OriginPlayer = self.actor

	self.PlayerController = self.actor.PlayerState:GetPlayerController()
	self.PlayerController:Possess(self.GodPlayer)

	self.GodPlayer.ZeroGravityComponent:EnterZeroGravity(1000, false)
	self.GodPlayer.CapsuleComponent:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
	self.GodPlayer.Mesh:SetGenerateOverlapEvents(false)
	self.GodPlayer:SetActorHiddenInGame(true)
	self.GodPlayer:Client_SendMessage("GodPlayer_ClientModify")
end
	
decorator.message_receiver()
function GodViewComponent:Client_EnterGodView()
	self.PlayerController = self.actor.PlayerState:GetPlayerController()
    G.log:debug("yj", "EnterGodView IsClient.%s PlayerController.%s", self.actor:IsClient(), self.PlayerController)
end

decorator.message_receiver()
function GodViewComponent:GodPlayer_ClientModify()
	self:SendMessage("EnterState", check_table.State_ForbidMove)
	self:SendMessage("EnterState", check_table.State_HitZeroGravity)
end

decorator.message_receiver()
function GodViewComponent:LeaveGodView()
	-- run on server and client
	self.PlayerController:Possess(self.actor)
	self.GodPlayer:K2_DestroyActor()
end


return GodViewComponent
