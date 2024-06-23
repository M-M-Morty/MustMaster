local G = require("G")
local GAPlayerBase = require("skill.ability.GAPlayerBase")
local GASequence = Class(GAPlayerBase)

GASequence.__replicates = {
    SequencePlayer = 0,
    CameraSequenceHandler = 0,
}

function GASequence:K2_PostTransfer()
    Super(GASequence).K2_PostTransfer(self)

    self.CameraManager = UE.UGameplayStatics.GetPlayerController(self.OwnerActor:GetWorld(), 0).PlayerCameraManager
end

function GASequence:HandleActivateAbility()
    Super(GASequence).HandleActivateAbility(self)

    self:OnChangeActorLocAndRot()

    if self.SequenceToPlay then
        self.OwnerActor:Replicated_StopMontage(nil,0)
        local Settings = UE.FMovieSceneSequencePlaybackSettings()
        local Bindings = self:InitBindings()
        local PlayTask = UE.UHiAbilityTask_PlaySequence.CreatePlaySequenceAndWaitProxy(self, "", self.SequenceToPlay,
                Settings, Bindings, true, 1.0, self.SequenceToPlayOnSimulated)
        PlayTask.bStopWhenAbilityCanceled = self.bStopSequenceSync
        PlayTask.bStopWhenAbilityEnds = self.bStopSequenceSync
        PlayTask.OnStop:Add(self, self.OnStopSequence)

        if self.bDisableInput then
            if self.OwnerActor:IsPlayer() then
                self.OwnerActor:ClearVelocityAndAcceleration()                
            end
            if self:IsClient() then
                local HiddenLayerContext = nil
                PlayTask.OnPlay:Add(self, function()
                    HiddenLayerContext = utils.HideUI()
                    utils.SetPlayerInputEnabled(self.OwnerActor:GetWorld(), false)
                end)
                PlayTask.OnStop:Add(self, function()
                    utils.ShowUI(HiddenLayerContext)
                    utils.SetPlayerInputEnabled(self.OwnerActor:GetWorld(), true)
                end)                
            end
        end

        PlayTask:ReadyForActivation()
        self.SequencePlayer = PlayTask:GetLevelSequencePlayer()
    end

    self.CameraManager = UE.UGameplayStatics.GetPlayerController(self.OwnerActor:GetWorld(), 0).PlayerCameraManager
    if self.CameraSequenceToPlay and not self:IsServer() then
        local OwnerTransform = self.OwnerActor:GetTransform()
        local Params = UE.FCameraAnimationParams()
        Params.PlaySpace = UE.ECameraAnimationPlaySpace.UserDefined
        Params.UserPlaySpaceLocation = UE.UKismetMathLibrary.TransformLocation(OwnerTransform, self.CameraRelativeLocation)
        Params.UserPlaySpaceRotator = UE.UKismetMathLibrary.TransformRotation(OwnerTransform, self.CameraRelativeRotation)
        self.CameraSequenceHandler = self.CameraManager:PlaySequence(self.CameraSequenceToPlay, Params)
    end
end

function GASequence:OnComboTailEvent(Payload)
    -- 即使禁止输入的 sequence，后摇也要支持按键响应
    utils.SetPlayerInputEnabled(self.OwnerActor:GetWorld(), true)

    Super(GASequence).OnComboTailEvent(self, Payload)
end
UE.DistributedDSLua.RegisterFunction("OnComboTailEvent", GASequence.OnComboTailEvent)

function GASequence:OnStopSequence()
    self.CameraManager:StopSequence(self.CameraSequenceHandler)
    self:K2_EndAbility()
end
UE.DistributedDSLua.RegisterFunction("OnStopSequence", GASequence.OnStopSequence)

-- Subclass override this.
function GASequence:InitBindings()
    local Bindings = UE.TArray(UE.FAbilityTaskSequenceBindings)

    -- Player binding.
    if self.bBindingPlayer then
        local PlayerBinding = UE.FAbilityTaskSequenceBindings()
        PlayerBinding.BindingTag = self.PlayerBindingTag
        PlayerBinding.Actors = _MakeActorArray(self.OwnerActor)
        Bindings:Add(PlayerBinding)
    end

    -- Monster binding.
    if self.bBindingMonster then
        local TargetActor = self:GetSkillTarget()
        local MonsterBinding = UE.FAbilityTaskSequenceBindings()
        MonsterBinding.BindingTag = self.MonsterBindingTag
        MonsterBinding.Actors = _MakeActorArray(TargetActor)
        Bindings:Add(MonsterBinding)
    end

    return Bindings
end

function GASequence:HandleEndAbility(bWasCancelled)
    Super(GASequence).HandleEndAbility(self, bWasCancelled)

    if self.SequencePlayer:IsPlaying() then
        self.SequencePlayer:Stop()
    end

    if self.CameraSequenceHandler ~= nil then
        self.CameraManager:StopSequence(self.CameraSequenceHandler)
        self.SequenceHandler = nil
    end
end

--在Handle此GA时进行一次OwnerActor和TargetActor的Loc和Rot更新
function GASequence:OnChangeActorLocAndRot()
    local OwnerActor = self.OwnerActor
    local TargetActor = self:GetSkillTarget()
    if OwnerActor:IsMonster() then  
        local Controller = UE.UAIBlueprintHelperLibrary.GetAIController(OwnerActor)
        local BB = Controller and UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
        TargetActor = BB and BB:GetValueAsObject("TargetActor")
    end
    local function OnUpdate(Target, Info)
        local LocomotionComponent = Target and Target.LocomotionComponent
        if not LocomotionComponent then return end
        if not Info.bNeedToChange then return end
        local Loc, Rot
        if Info.bUseRouteActorLocAndRot then
            local Actors = GameAPI.GetActorsWithTag(Target, Info.RouteActorTagName)
            if Actors then
                for _, RouteActor in ipairs(Actors) do
                    if RouteActor then
                        Loc,Rot = RouteActor:K2_GetActorLocation(),RouteActor:K2_GetActorRotation()
                        LocomotionComponent:Multicast_SetActorLocationAndRotation(Loc, Rot, false, true)
                        break
                    end
                end
            end
        else
            Loc, Rot = Info.CustomLoc, Info.CustomRot
            LocomotionComponent:Multicast_SetActorLocationAndRotation(Loc, Rot, false, true)
        end
    end
    local OwnerInfo, TargetInfo = self.FChangeOwnerLocAndRot, self.FChangeTargetLocAndRot
    OnUpdate(OwnerActor, OwnerInfo)
    OnUpdate(TargetActor, TargetInfo)
end

UE.DistributedDSLua.RegisterCustomClass("GASequence", GASequence, GAPlayerBase)

return GASequence
