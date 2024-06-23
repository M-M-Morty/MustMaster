local G = require("G")
local GASequence = require("skill.ability.GASequence")
local GASuperSkill = Class(GASequence)

function GASuperSkill:HandleActivateAbility()
    Super(GASuperSkill).HandleActivateAbility(self)

    if self:IsClient() then
        local switches = require("switches")
        self.bEnableRoleSwitch = switches.EnableRoleSwitch
        switches.EnableRoleSwitch = false
    end

    --local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    --CameraManager.bDebug = true
end

function GASuperSkill:HandleEndAbility(bWasCancelled)
    Super(GASuperSkill).HandleEndAbility(self, bWasCancelled)

    local PlayerController = UE.UGameplayStatics.GetPlayerController(self.OwnerActor:GetWorld(), 0)
    PlayerController:SetRenderShowOnlyPrimitiveComponents(false)
    PlayerController:SetShowOnlyActors(UE.TArray(UE.AActor))

    if self:IsClient() then
        local switches = require("switches")
        switches.EnableRoleSwitch = self.bEnableRoleSwitch
    end

    --local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    --CameraManager.bDebug = false
end

return GASuperSkill
