--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local playerCharacterBlueprintClass = UE.UClass.Load('/Game/Blueprints/Character/BPA_AvatarBase.BPA_AvatarBase_C')
local debrisBlueprintClass = UE.UClass.Load('/Game/Blueprints/Actor/lifecircle/bp_magic_debris.bp_magic_debris_C')
local circleBlueprintClass = UE.UClass.Load('/Game/Blueprints/Actor/lifecircle/bp_magic_circle.bp_magic_circle_C')

local tbRespCode =
{
    FAIL_PART = 0,
    SUCCESS_PART = 1,
    SUCCESS_ALL = 2,
}

---@type bp_magic_circle_C
local ActorBase = require("actors.common.interactable.base.interacted_item")
local M = Class(ActorBase)

function M:LogInfo(...)
    G.log:info_obj(self, ...)
end

function M:LogDebug(...)
    G.log:debug_obj(self, ...)
end

function M:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function M:LogError(...)
    G.log:error_obj(self, ...)
end

-- function M:Initialize(Initializer)
-- end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    self:LogInfo('zsf', '[lifecircle] ReceiveBeginPlay %s %s', self:HasAuthority(), self:IsServer())
    if self:HasAuthority() then
        self:LoadPlayStyleConfig()
        self:DestroyCreatedComponents()
        self:SetInteractable(true)
    else
        self:LoadPlayStyleConfig()
        self:CreatePlayStyleView()
        for i = 1, self.arrCreatedComponents:Num() do
            local comp = self.arrCreatedComponents:Get(i)
            if comp then
                ---@type USphereComponent
                local interactComp = comp:Cast(UE.USphereComponent)
                if interactComp then
                    interactComp.OnComponentBeginOverlap:Add(self, self.OnClientBeginOverlap)
                    interactComp.OnComponentEndOverlap:Add(self, self.OnClientEndOverlap)
                end
            end
        end
        -- 刷新已经交互成功的部分
        for i = 1, self.arrInteractedSlot:Num() do
            local slot = self.arrInteractedSlot:Get(i)
            self:ClientUpdateInteractedSlot(slot)
        end
    end
end

function M:ReceiveEndPlay()
    for i = 1, self.arrCreatedComponents:Num() do
        local comp = self.arrCreatedComponents:Get(i)
        if comp then
            comp:K2_DestroyComponent(comp)
        end
    end
    self.arrCreatedComponents:Clear()

    for i = 1, self.arrGuideComponents:Num() do
        local comp = self.arrGuideComponents:Get(i)
        if comp then
            comp:K2_DestroyComponent(comp)
        end
    end
    self.arrGuideComponents:Clear()
end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

function M:ClientUpdateInteractedSlot(slot)
    if self:HasAuthority() then
        return
    end

    if slot > 0 and slot <= self.arrGuideComponents:Num() then
        ---@type UNiagaraComponent
        local comp = self.arrGuideComponents:Get(slot)
        if comp then
            comp:K2_DestroyComponent(comp)

            local worldLocation = self:GetInteractLocation(slot)
            local newComp = UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(self, self.InteractNiagaraAsset, worldLocation)    ---@type UNiagaraComponent
            newComp:SetFloatParameter('LifeTime', 100000000.0)
            self.arrGuideComponents:Set(slot, newComp)
        end

        ---@type UActorComponent
        local comp = self.arrCreatedComponents:Get(slot)
        if comp then
            comp:K2_DestroyComponent(comp)
        end
    end
end

function M:SetInteractable(bCan)
    if not self:HasAuthority() then
        return
    end
    self.bInteractable = bCan
end

function M:GetInteractable()
    return self.bInteractable
end

function M:OnRep_bInteractable()
    if self:HasAuthority() then
        return
    end

    -- force update overlapping
    for i = 1, self.arrCreatedComponents:Num() do
        local comp = self.arrCreatedComponents:Get(i)
        if comp then
            local interactComp = comp:Cast(UE.USphereComponent) ---@type USphereComponent
            if interactComp then
                interactComp:SetGenerateOverlapEvents(self.bInteractable)
                interactComp:SetCollisionProfileName('NoCollision')
                interactComp:SetCollisionProfileName('LifeCircleOverlap', true)
            end
        end
    end
end

---@param invoker AActor
function M:DoClientInteractAction(invoker)
    if not self:HasAuthority() and self:GetInteractable() and invoker then
        ---@type BP_ThirdPersonCharacter_C
        local playerActor = self:GetPlayerActor(invoker)
        if playerActor then
            playerActor.EdRuntimeComponent:Server_InteractEvent(self, 100.0, UE.FVector(0,0,0))
            self:LogInfo('zsf', '%s Interact with %s', G.GetDisplayName(playerActor), G.GetDisplayName(self))
        end
    end
end

-- called by ServerInteractEvent
---@param invoker AActor
---@param InteractLocation Vector
function M:DoServerInteractAction(invoker, Damage, InteractLocation)
    if not self.playStyleRow then
        return
    end

    if self:HasAuthority() and self:GetInteractable() then
        ---@type BP_ThirdPersonCharacter_C
        local playerActor = self:GetPlayerActor(invoker)
        if playerActor and playerActor.PickupInventoryComponent:hasPickedSceneObject() then
            -- check overlapping
            local tbObjectTypes = { UE.EObjectTypeQuery.Pawn }
            local interactSlot = 0
            for i = 1, 6 do
                local worldLocation = self:GetInteractLocation(i)
                local _, arrOverlapping = UE.UKismetSystemLibrary.SphereOverlapActors(self, worldLocation, self.fInteractRadius, tbObjectTypes, playerCharacterBlueprintClass, {})
                if arrOverlapping:Contains(playerActor) then
                    interactSlot = i
                    break
                end    
            end
            if interactSlot > 0 then
                self:LogInfo('zsf', '%s Interact with %s (slot:%d)', G.GetDisplayName(playerActor), G.GetDisplayName(self), interactSlot)
                self:OnServerInteractSlot(playerActor, interactSlot)
            end
        end
    end
end

function M:IsInteractAll()
    if self.playStyleRow.arrPlayerSlot:Num() ~= self.arrInteractedSlot:Num() then
        return false
    end
    for i = 1, self.arrInteractedSlot:Num() do
        local slot = self.arrInteractedSlot:Get(i)
        if not self.playStyleRow.arrPlayerSlot:Contains(slot) then
            return false
        end
    end
    return true
end

---@param playerActor BP_ThirdPersonCharacter_C
function M:OnServerInteractSlot(playerActor, interactSlot)
    ---@type AActor
    local pickedSceneObject = playerActor.PickupInventoryComponent:GetPickedSceneObject(1)
    if not pickedSceneObject then
        return
    end

    if self.playStyleRow.arrPlayerSlot:Contains(interactSlot) then
        self.arrInteractedSlot:AddUnique(interactSlot)
        
        playerActor.PickupInventoryComponent:ServerRemoveSceneObject(pickedSceneObject)
        pickedSceneObject:K2_DestroyActor()

        if self.playStyleRow.bSuccessFillAny or self:IsInteractAll() then
            self:OnServerInteractSuccessAll(playerActor)
        else
            self:OnServerInteractSuccessPart(playerActor, interactSlot)
        end
    else
        self:OnServerInteractFailPart(playerActor, pickedSceneObject, interactSlot)
    end
end

function M:IsMagicCircle()
    return true
end

function M:OnServerInteractSuccessAll(playerActor)
    self:ClientInteractResponseEvent(tbRespCode.SUCCESS_ALL, 0)
    self:SetInteractable(false)
    self:LogInfo('zsf', '%s interact success all', G.GetDisplayName(playerActor))

    -- TODO(dougzhang): 完成当前挑战
    local localPlayerActor = G.GetPlayerCharacter(self, 0)
    if localPlayerActor then -- 扔掉玩家身上的碎片
        localPlayerActor.PickupInventoryComponent:ServerDropAllSceneObject()
    end
    --local gameMode = UE.UGameplayStatics.GetGameMode(self)
    --if gameMode then
    --    gameMode:CheckLifeCircleFinish()
    --end
    self:LogicComplete()
end

function M:MissionComplete(sData)
   self:CallEvent_MissionComplete(sData)
end

function M:OnServerInteractSuccessPart(playerActor, interactSlot)
    self:ClientInteractResponseEvent(tbRespCode.SUCCESS_PART, interactSlot)
    self:LogInfo('zsf', '%s interact success part (slot %d)', G.GetDisplayName(playerActor), interactSlot)
end

function M:OnServerInteractFailPart(playerActor, pickedSceneObject, interactSlot)
    playerActor.PickupInventoryComponent:ServerRemoveSceneObject(pickedSceneObject)
    local debrisActor = pickedSceneObject:Cast(debrisBlueprintClass)    ---@type bp_magic_debris_C
    self:LogInfo('zsf', '[debris] OnServerInteractFailPart %s', G.GetDisplayName(debrisActor))
    if debrisActor then
        local randRot = UE.FRotator(0, math.random(0, 360), 0)
        local randRange = math.random(1.5 * self.fObjectRadius, 2 * self.fObjectRadius)
        local worldLocation = self:K2_GetActorLocation()
        local targetLocation = worldLocation + randRot:RotateVector(UE.FVector(randRange, 0, 0))

        debrisActor:SetInteractable(true)
        debrisActor:StartProjectileMove(targetLocation, UE.UKismetMathLibrary.RandomFloatInRange(0.5, 0.8))
        self:ClientInteractResponseEvent(tbRespCode.FAIL_PART, interactSlot)
        self:LogInfo('zsf', '%s interact success part (slot %d)', G.GetDisplayName(playerActor), interactSlot)
    end
end

-- call by ClientInteractResponseEvent
function M:ClientInteractResponse(resCode, interactSlot)
    if self:HasAuthority() then
        return
    end
    if tbRespCode.SUCCESS_ALL == resCode then
        -- 交互成功
        for i = 1, self.arrGuideComponents:Num() do
            ---@type UNiagaraComponent
            local guideComp = self.arrGuideComponents:Get(i)
            if guideComp then
                guideComp:K2_DestroyComponent(guideComp)
            end
        end

        for i = 1, self.arrCreatedComponents:Num() do
            local comp = self.arrCreatedComponents:Get(i)
            if comp then
                comp:K2_DestroyComponent(comp)
            end
        end

        if self.playStyleRow then
            for i = 1, 6 do
                local worldLocation = self:GetInteractLocation(i)
                UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(self, self.CompleteNiagaraAsset, worldLocation, UE.FRotator(), UE.FVector(1,1,1), true, true, UE.ENCPoolMethod.AutoRelease, true)
            end
        end
        self:LogInfo('zsf', 'interact success all')
    elseif tbRespCode.SUCCESS_PART == resCode then
        self:ClientUpdateInteractedSlot(interactSlot)
        self:LogInfo('zsf', 'interact success part (slot %d)', interactSlot)
    else
        -- 交互失败
        self:LogInfo('zsf', 'interact fail (slot %d)', interactSlot)
    end
end


function M:GetPlayerActor(OtherActor)
    if OtherActor.EdRuntimeComponent then
        return OtherActor
    end
end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param SweepResult FHitResult
function M:OnClientBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if self:HasAuthority() then
        return
    end

    if self:GetInteractable() then
        ---@type BP_ThirdPersonCharacter_C
        local playerActor = self:GetPlayerActor(OtherActor)
        if playerActor then
            playerActor.EdRuntimeComponent:AddNearbyActor(self)
        end
    end
end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
function M:OnClientEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if self:HasAuthority() then
        return
    end

    ---@type BP_ThirdPersonCharacter_C
    local playerActor = self:GetPlayerActor(OtherActor)
    if playerActor then
        playerActor.EdRuntimeComponent:RemoveNearbyActor(self)
    end
end

return M
