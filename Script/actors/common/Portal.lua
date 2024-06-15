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
local Loader = require("actors.client.AsyncLoaderManager")

---@type BP_Portal_C
local Portal = Class(Actor)


function Portal:ReceiveBeginPlay()
    self:SetTarget(self.PortalTarget)
    if self:IsClient() then
        function OnMaterialInstanceLoaded(MI_Object)
            self.MaterialInstance = UE.UKismetMaterialLibrary.CreateDynamicMaterialInstance(0, MI_Object)
            self.StaticMesh:SetMaterial(0, self.MaterialInstance)
            self.MaterialInstance:SetTextureParameterValue("txt_Portal", nil)
        end
        local MaterialInstancePath = "MaterialInstanceConstant'/HiPortal/MI_Portal.MI_Portal'"
        Loader:AsyncLoadAsset(MaterialInstancePath, OnMaterialInstanceLoaded) 
    end    

    self.PortalArea.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap)
    self.PortalArea.OnComponentEndOverlap:Add(self, self.OnEndOverlap)
end
 

function Portal:ReceiveTick(DeltaSeconds)        
    if self:IsActive() then
        self:ServerUpdate()
    end
end


function Portal:ReceiveEndPlay()
    self.PortalArea.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap)
    self.PortalArea.OnComponentEndOverlap:Remove(self, self.OnEndOverlap)
end


function Portal:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    --G.log:debug("hyportal", "Portal:OnBeginOverlap .%s  %s  %s", OtherActor:GetName(), OtherComp:GetName(), tostring(self:IsClient()))    
    if self:IsClient() then
        if GameAPI.IsPlayer(OtherActor) then
            self.MaterialInstance:SetScalarParameterValue("ScaleVertex", 1.0)
        end
    else
        local ActorClass = UE.UGameplayStatics.GetClass(OtherActor)       
        if UE.UKismetMathLibrary.ClassIsChildOf(ActorClass, UE.AHiCharacter) then
            self.CharactersInArea:Add(OtherActor)
        end        
        self:SetActive(true)
    end
end

function Portal:OnEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    --G.log:debug("hyportal", "Portal:OnEndOverlap %s  %s  %s", OtherActor:GetName(), OtherComp:GetName(), tostring(self:IsClient()))
    if self:IsClient() then
        if GameAPI.IsPlayer(OtherActor) then
            self.MaterialInstance:SetScalarParameterValue("ScaleVertex", 0.0)
        end
    else
        local ActorClass = UE.UGameplayStatics.GetClass(OtherActor)       
        if UE.UKismetMathLibrary.ClassIsChildOf(ActorClass, UE.AHiCharacter) then
            self.CharactersInArea:Remove(OtherActor)
            local CharactersArray = self.CharactersInArea:ToArray()
            if CharactersArray:Length() == 0 then
                self:SetActive(false)
            end    
        end
    end
end

--run on client
function Portal:SetRTT(RenderTexture)
    if RenderTexture and RenderTexture:IsValid() then
        if self.MaterialInstance and self.MaterialInstance:IsValid() then
            self.MaterialInstance:SetTextureParameterValue("txt_Portal", RenderTexture)
        end
    end
end


function Portal:ClearRTT()
    if self.MaterialInstance and self.MaterialInstance:IsValid() then
        self.MaterialInstance:SetTextureParameterValue("txt_Portal", nil)
    end
end


--run on server
function Portal:ServerUpdate()
    if self:IsServer() then
        --G.log:debug("hyportal", "Portal:ServerUpdate()")
        local CharactersArray = self.CharactersInArea:ToArray()
		for i = 1, CharactersArray:Length() do        
            local Character = CharactersArray:Get(i)
            if Character and Character:IsValid() then
                local Location = Character:K2_GetActorLocation()
                local bInsideBox = UE.UPortalBlueprintLibrary.IsPointInsideBox(Location, self.PortalArea)
                if bInsideBox then
                    local bPlayerCrossPortal = self:IsPointCrossingPortal(Location, self:K2_GetActorLocation(), self:K2_GetRootComponent():GetForwardVector() * -1)
                    if bPlayerCrossPortal then                         
                        self:TeleportActor(Character)                
                    end
                end
            end
        end        
    end  
end


function Portal:TeleportActor(ActorToTeleport)
    if ActorToTeleport and ActorToTeleport:IsValid() and self.PortalTarget and self.PortalTarget:IsValid() then
        self.NewLocation = self.PortalTarget:K2_GetActorLocation()
        self.NewRotation = self.PortalTarget:K2_GetActorRotation()        
        local TeleportComponent = ActorToTeleport:GetComponentByName("TeleportComponent")        
        if TeleportComponent and TeleportComponent:IsValid() then
            TeleportComponent:TeleportTo(self.NewLocation, self.NewRotation, true, true)
            self.LastPosition = self.NewLocation
        end       
    end
end



return RegisterActor(Portal)
