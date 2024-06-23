--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"
local G = require("G")


---@type BP_BuilderSubSystem_C
local BuilderSubSystem = UnLua.Class()

function BuilderSubSystem:ConstructionScript()
    G.log:debug("hycoldrain", "BuilderSubSystem:ConstructionScript..... ")
    --if self.actor:GetLocalRole() == UE.ENetRole.ROLE_AutonomousProxy then
    --    --G.log:debug("hybuild", "BuildingSystemComponent:Start.....")        
    --    self.Widget = nil
    --end
    self.MainWidget = nil
    self.SplineBuilderWidget = nil
end


function BuilderSubSystem:PossesToCamera(Player)
    self.Player = Player
    local Controller = UE.UGameplayStatics.GetPlayerController(self.Player:GetWorld(), 0)--self.Player:GetController()
    Controller:UnPossess(self.Player)
    Controller:Possess(self.CameraCharactor)
end

function BuilderSubSystem:PossesBackPlayer()
    if self.CameraCharactor and self.CameraCharactor:IsValid() then
        local Controller = UE.UGameplayStatics.GetPlayerController(self.Player:GetWorld(), 0) --self.CameraCharactor:GetController()--
        Controller:UnPossess(self.CameraCharactor)
        G.log:info("hycoldrain", "BuilderSubSystem:PossesBackPlayer()  %s", G.GetDisplayName(Controller))
        Controller:Possess(self.Player)    
        self:DestoryCameraCharactor()   
    end    
end


function BuilderSubSystem:ShowBuildUI(bShow, actor)
    if bShow then
        if not self.MainWidget then
            self.MainWidget = UE.UWidgetBlueprintLibrary.Create(actor, self.BuilingSystemMainWidgetClass)
            self.MainWidget:AddToViewport()         
            --local Controller = self.actor:GetController()
            --UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(Controller)           
        end
    else
        if self.MainWidget then
            self.MainWidget:RemoveFromViewport()            
            self.MainWidget = nil            
        end
    end
end

function BuilderSubSystem:ShowSplineBuilderUI(bShow, actor)
    if bShow then
        if not self.SplineBuilderWidget then
            self.SplineBuilderWidget = UE.UWidgetBlueprintLibrary.Create(actor, self.SplineBuilderWidgetClass)
            self.SplineBuilderWidget.CameraCharacterReference = actor
            self.SplineBuilderWidget:AddToViewport()         
            --local Controller = self.actor:GetController()
            --UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(Controller)           
        end
    else
        if self.SplineBuilderWidget then
            self.SplineBuilderWidget:RemoveFromViewport()            
            self.SplineBuilderWidget = nil            
        end
    end
end

function BuilderSubSystem:DestoryCameraCharactor()
    if self.Player:GetLocalRole() == UE.ENetRole.ROLE_Authority then
        if self.CameraCharactor then
            self.CameraCharactor:K2_DestroyActor()
            self.CameraCharactor = nil
        end
    end
end


--rpc run on server
function BuilderSubSystem:SpawnCameraCharactor(World, Transform)    
    G.log:debug("hycoldrain", "BuilderSubSystem:SpawnCameraCharactor..... %s", tostring(debug.traceback()))    
    if not self.CameraCharactor then
        local SpawnParameters = UE.FActorSpawnParameters()              
        local ExtraData = {
            LastPossessed = self.actor,
        } 
        self.CameraCharactor = GameAPI.SpawnActor(World, self.BuildingCameraClass, Transform, SpawnParameters, ExtraData)    
    end
    return self.CameraCharactor    
end

return BuilderSubSystem