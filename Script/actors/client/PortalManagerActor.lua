--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"
local G = require("G")
local Actor = require("common.actor")

---@type BP_PortalManagerActor_C
local PortalManagerActor = Class(Actor)


function PortalManagerActor:GetSceneCaptureComponent()
    return self.SceneCaptureComponent2D
end


function PortalManagerActor:ReceiveBeginPlay()
    if self.PortalTexture and self.PortalTexture:IsValid() then
        self.PortalTexture.bNeedsTwoCopies = false;
    end

    --self:DebugRenderTarget()
end

function PortalManagerActor:DebugRenderTarget()
    self.RTView = UE.UWidgetBlueprintLibrary.Create(self, UE.UClass.Load("WidgetBlueprint'/MyFirstFeature/UI/WBP_HUD.WBP_HUD_C'"))
    self.RTView:AddToViewport()
end

function PortalManagerActor:FillRenderTargetParams(SizeX, SizeY)
    if self.PortalTexture and self.PortalTexture:IsValid() then
        self.PortalTexture.RenderTargetFormat = UE.ETextureRenderTargetFormat.RTF_RGBA16f		
		self.PortalTexture.SizeX = SizeX;
		self.PortalTexture.SizeY = SizeY;
		self.PortalTexture.ClearColor = UE.FLinearColor.White;
		self.PortalTexture.TargetGamma = 2.2
		self.PortalTexture.bNeedsTwoCopies = false;
		self.PortalTexture.bAutoGenerateMips = false;
    end
end


function PortalManagerActor:UpdateSceneCapture(Portal)
    if self.ControllerOwner and self.ControllerOwner:IsValid() then
        local SceneCapture = self.SceneCaptureComponent2D
        if SceneCapture and SceneCapture:IsValid() and self.PortalTexture and self.PortalTexture:IsValid() and Portal and Portal:IsValid() and self.Character and self.Character:IsValid() then
            local Target = Portal:GetTarget()
            if Target and Target:IsValid() then
                local CharacterPitch = self.Character:K2_GetActorRotation().CharacterPitch
                local CameraRotator = self.ControllerOwner.PlayerCameraManager:GetCameraRotation()
                local CameraYaw = CameraRotator.Yaw
                local CameraRoll = CameraRotator.CameraRoll

                local ViewerRotator = UE.UKismetMathLibrary.MakeRotator(CameraRoll, CharacterPitch, CameraYaw)
                local ReferenceLocation = self.Character:K2_GetActorLocation()
                local TargetLocation = Target:K2_GetActorLocation()
                ReferenceLocation.Z = TargetLocation.Z
                local ReferenceTransform = UE.UKismetMathLibrary.MakeTransform(ReferenceLocation, ViewerRotator)
                local CameraLocation = self.ControllerOwner.PlayerCameraManager:GetCameraLocation()
                local NewLocation = UE.UPortalBlueprintLibrary.ConvertLocationToActorSpace(CameraLocation, ReferenceTransform, Target)
                local HitResult = UE.FHitResult() 
                SceneCapture:K2_SetWorldLocation(NewLocation, false, HitResult, false)

                local NewWorldQuat = UE.UPortalBlueprintLibrary.ConvertRotationToActorSpace(ViewerRotator, Target:K2_GetActorRotation(), Target)
                SceneCapture:K2_SetWorldRotation(NewWorldQuat, false, HitResult, false)

                SceneCapture.ClipPlaneNormal = Target:GetActorForwardVector()
                SceneCapture.ClipPlaneBase = TargetLocation + (SceneCapture.ClipPlaneNormal * -1.5)
            end

            Portal:SetRTT(self.PortalTexture)
            SceneCapture.TextureTarget = self.PortalTexture;
            SceneCapture.CustomProjectionMatrix = UE.UPortalBlueprintLibrary.GetCameraProjectionMatrix(self.ControllerOwner)
            SceneCapture.bUseCustomProjectionMatrix = true
            SceneCapture:CaptureScene()	
        end
    end
end
-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

-- function M:ReceiveBeginPlay()
-- end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

return RegisterActor(PortalManagerActor)
