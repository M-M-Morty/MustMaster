--建造系统的支持，但未实装 by shiniingliu
require "UnLua"
local G = require("G")
local utils = require("common.utils")

local UIBuildingSystem = Class()

function UIBuildingSystem:Construct()	
	--G.log:info("hycoldrain", "UIBuildingSystem:Construct()	%s", UE.UGameplayStatics.GetPlatformName())	
	self.Overridden.Construct(self)	
	self:BindDelegate()	
end


function UIBuildingSystem:BindDelegate()
	self.Btn_Esc.OnClicked:Add(self, UIBuildingSystem.OnClicked_Btn_Esc)
	self.Btn_Next.OnClicked:Add(self, UIBuildingSystem.OnClicked_Btn_Next)
    self.Btn_Placement.OnClicked:Add(self, UIBuildingSystem.OnClicked_Btn_Placement)
    self.Btn_Rotate.OnClicked:Add(self, UIBuildingSystem.OnClicked_Btn_Rotate)
	self.Btn_Normal.OnClicked:Add(self, UIBuildingSystem.OnClicked_Btn_Normal)
	self.Btn_Spline.OnClicked:Add(self, UIBuildingSystem.OnClicked_Btn_Spline)
end

function UIBuildingSystem:OnClicked_Btn_Esc() 
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
	Player:SendMessage("Event_ExitBuildingSystem")
end

function UIBuildingSystem:OnClicked_Btn_Next()
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
	Player:SendMessage("Event_TargetActorChangeMesh")
end

function UIBuildingSystem:OnClicked_Btn_Placement()
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
	Player:SendMessage("Event_LaunchBuildMode")
end

function UIBuildingSystem:OnClicked_Btn_Rotate()      
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    G.log:info("hycoldrain", "UIBuildingSystem:OnClicked_Btn_Rotate()  %s", G.GetDisplayName(Player))
	Player:SendMessage("Event_RotateTargetActor")
end

function UIBuildingSystem:OnClicked_Btn_Normal()      
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    G.log:info("hycoldrain", "UIBuildingSystem:OnClicked_Btn_Rotate()  %s", G.GetDisplayName(Player))
	Player:SwitchNormalBuilder()
end

function UIBuildingSystem:OnClicked_Btn_Spline()      
    local Player = G.GetPlayerCharacter(self:GetWorld(), 0)
    G.log:info("hycoldrain", "UIBuildingSystem:OnClicked_Btn_Rotate()  %s", G.GetDisplayName(Player))
	Player:SwitchSplineBuilder()
end


return UIBuildingSystem
