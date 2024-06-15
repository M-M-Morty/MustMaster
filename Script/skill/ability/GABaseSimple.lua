-- Rush task
local G = require("G")

local GABaseSimple = Class()

function GABaseSimple:K2_ActivateAbility()

    G.log:debug("yj", "GABaseSimple:K2_ActivateAbility %s", G.GetDisplayName(self))
    
    local Tags = self.EffectContainerMap:Keys()
    for i = 1, Tags:Length() do
        self:HandleCalc(Tags:Get(i))
    end

    self:K2_EndAbility()
end

function GABaseSimple:HandleCalc(EventTag)

    local EffectContainer = UE.FHiGameplayEffectContainer()
    local Specs = UE.TArray(UE.FGameplayEffectSpecHandle)
    local bFounded = self:MakeEffectContainerSpecByTag(EventTag, self:GetAbilityLevel(), EffectContainer, Specs)
    if not bFounded then
        return
    end

    if not UE.UKismetSystemLibrary.IsValidClass(EffectContainer.TargetType) then
        G.log:error("yj", "GABaseSimple OnCalcEvent TargetActor type is invalid for tag: %s", UE.UBlueprintGameplayTagLibrary.GetTagName(EventTag))
        return
    end

    local KInfoClass = UE.UObject.Load("/Game/Blueprints/Common/UserData/UD_KnockInfo.UD_KnockInfo_C")
    local KInfo = NewObject(KInfoClass)
    local ExtraData = {
        GameplayEffectsHandle = Specs,
        ApplicationTag = EventTag,
        KnockInfo = KInfo,
    }
    local OwnerActor = self:GetAvatarActorFromActorInfo()
    local TargetActor = GameAPI.SpawnActor(OwnerActor:GetWorld(), EffectContainer.TargetType, OwnerActor:GetTransform(), UE.FActorSpawnParameters(), ExtraData)
    local WaitTargetDataTask = UE.UAbilityTask_WaitTargetData.WaitTargetDataUsingActor(self, "", EffectContainer.ConfirmationType, TargetActor)
    WaitTargetDataTask.ValidData:Add(self, self.OnValidDataCallback)
    WaitTargetDataTask:ReadyForActivation()
    self:AddTaskRefer(WaitTargetDataTask)
end

function GABaseSimple:OnValidDataCallback(Data, EventTag)

    G.log:debug("yj", "GABaseSimple OnValidDataCallback, tag: %s, IsServer: %s", UE.UBlueprintGameplayTagLibrary.GetTagName(EventTag), self:K2_HasAuthority())
    self:ApplyGEToTargetData(Data, EventTag)
end

function GABaseSimple:ApplyGEToTargetData(Data, EventTag)
    local EffectContainer = UE.FHiGameplayEffectContainer()
    local Specs = UE.TArray(UE.FGameplayEffectSpecHandle)
    local bFounded = self:MakeEffectContainerSpecByTag(EventTag, self:GetAbilityLevel(), EffectContainer, Specs)
    if not bFounded then
        G.log:error("yj", "GABaseSimple ApplyGEToTargetData not found EffectContainer for tag: %s", UE.UKismetSystemLibrary.GetTagName(EventTag))
        return
    end

    if Specs:Length() == 0 then
        return
    end

    -- Capsule calc event tag to GE spec for index skill base damage.
    -- TODO here just add to Asset tag.
    for Ind = 1, Specs:Length() do
        UE.UAbilitySystemBlueprintLibrary.AddAssetTag(Specs:Get(Ind), EventTag)
    end

    self:ApplyEffectContainerSpec(Specs, Data)
end

function GABaseSimple:K2_OnEndAbility(bWasCancelled)
    G.log:debug("yj", "GABaseSimple:K2_OnEndAbility %s", G.GetDisplayName(self))

    self:ClearTasks()
end

-- Add task reference to avoid gc by ue.
function GABaseSimple:AddTaskRefer(AbilityTask)
    self.Tasks:Add(AbilityTask)
end

function GABaseSimple:ClearTasks()
    self.Tasks:Clear()
end

return GABaseSimple
