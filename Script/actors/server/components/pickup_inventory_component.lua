--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
-- local UIManager = require('ui.ui_manager')
local Component = require("common.component")
local ComponentBase = require("common.componentbase")

---@type BP_PickupInventoryComponent_C
local M = Component(ComponentBase)

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

function M:ReceiveBeginPlay()
    Super(M).ReceiveEndPlay(self)
    if not self:HasAuthority() then
        self.arrClientAttachedObjects = UE.TArray(UE.AActor)
    end
end

function M:HasAuthority()
    local owner = self:GetOwner()
    return owner and owner:HasAuthority() or false
end

function M:GetOwnerActorLabel()
    local owner = self:GetOwner()
    return owner and G.GetDisplayName(owner) or 'Unknow OwnerActor'
end

function M:hasPickedSceneObject()
    return self.arrPickedSceneObjects:Num() > 0
end

function M:GetPickedSceneObject(nIndex)
    if nIndex > 0 and nIndex <= self.arrPickedSceneObjects:Num() then
        return self.arrPickedSceneObjects:Get(nIndex)
    end
end

---@param sceneObject AActor
function M:ServerAddSceneObject(sceneObject)
    if self:HasAuthority() then
        self.arrPickedSceneObjects:AddUnique(sceneObject)

        local worldLocation = self:GetOwner():K2_GetActorLocation()
        sceneObject:K2_SetActorLocation(UE.FVector(worldLocation.X, worldLocation.Y, worldLocation.Z), false, UE.FHitResult(), true)
        sceneObject:K2_AttachToActor(self:GetOwner(), '', UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld)
    end
end

---@param sceneObject AActor
function M:ServerRemoveSceneObject(sceneObject)
    if self:HasAuthority() then
        self.arrPickedSceneObjects:RemoveItem(sceneObject)
        if sceneObject:GetAttachParentActor() == self:GetOwner() then
            sceneObject:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)
        end
    end
end

function M:ServerDropAllSceneObject()
    if self:HasAuthority() then
        for i = 1, self.arrPickedSceneObjects:Num() do
            local sceneObject = self.arrPickedSceneObjects:Get(i)
            if sceneObject then
                if sceneObject:GetAttachParentActor() == self:GetOwner() then
                    sceneObject:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)
                end

                local randRot = UE.FRotator(0, math.random(0, 360), 0)
                local randRange = UE.UKismetMathLibrary.RandomFloatInRange(200, 400)
                local worldLocation = sceneObject:K2_GetActorLocation()
                local targetLocation = worldLocation + randRot:RotateVector(UE.FVector(randRange, 0, 0))
                sceneObject:StartProjectileMove(targetLocation, UE.UKismetMathLibrary.RandomFloatInRange(0.5, 0.8))
            end
        end
        self.arrPickedSceneObjects:Clear()
    end
end

function M:OnRep_arrPickedSceneObjects()
    if not self:HasAuthority() then
        for i = 1, self.arrClientAttachedObjects:Num() do
            ---@type AActor
            local sceneObject = self.arrClientAttachedObjects:Get(i)
            if sceneObject then
                if not self.arrPickedSceneObjects:Contains(sceneObject) then
                    sceneObject:StopRotating()
                end
            end
        end
        self.arrClientAttachedObjects:Clear()

        for i = 1, self.arrPickedSceneObjects:Num() do
            ---@type AActor
            local sceneObject = self.arrPickedSceneObjects:Get(i)
            if sceneObject then
                self.arrClientAttachedObjects:Add(sceneObject)
                sceneObject:StartRotating(UE.UKismetMathLibrary.RandomFloatInRange(60, 80), UE.UKismetMathLibrary.RandomFloatInRange(60, 80))
            end
        end
        self:LogInfo('zsf', 'rep picked scene objects', self:GetOwnerActorLabel())
    end
end

function M:OnPickupAction(InputAction, PressedKeys)
    self:LogInfo('zsf', 'OnPickupAction %s %s %s', InputAction, G.GetObjectName(InputAction), PressedKeys:Length())
    -- UIManager:OnPickupAction(InputAction, PressedKeys, self)
end

return M
