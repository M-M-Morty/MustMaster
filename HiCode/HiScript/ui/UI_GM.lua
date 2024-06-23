require "UnLua"
local G = require("G")
local t = require("t")
local UI_GM = Class()
local UIDebugInfo = require("ui.UIDebugInfo")

function UI_GM:Construct()
	self.Overridden.Construct(self)

end

-- function UI_GM:BindDelegate()
-- 	self.StaminaButton.OnPressed:Add(self,UI_GM.StaminaButton_Pressed)
-- end

-- function UI_GM:StaminaButton_Pressed()
-- 	self:SetStamina()
-- end

function UI_GM:Accelerate(Scale)
	Scale = 2
	local Cmd = string.format("SetSpeedScale(%s)",Scale)

	local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
	Player:Server_DoConsoleCmd(Cmd)
end

function UI_GM:Idioctonia(Hp)
	Hp = 0

	local Cmd = string.format("SetHp(%s)",Hp)

	local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
	Player:Server_DoConsoleCmd(Cmd)
end

function UI_GM:Invincible(Hp)
	Hp = 999999

	local Cmd = string.format("SetHp(%s)",Hp)

	local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
	Player:Server_DoConsoleCmd(Cmd)
end

function UI_GM:SetHp()
	Hp = self.Hp

	local Cmd = string.format("SetHp(%s)",Hp)

	local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
	Player:Server_DoConsoleCmd(Cmd)	
end

function UI_GM:SetMaxHp()
	MaxHp = self.MaxHp

	local Cmd = string.format("SetMaxHp(%s)",MaxHp)

	local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
	Player:Server_DoConsoleCmd(Cmd)	
end


function UI_GM:UnlimitedPhysicalStrength(Stamina)
	Stamina = 999999

	local Cmd = string.format("SetStamina(%s)",Stamina)

	local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
	Player:Server_DoConsoleCmd(Cmd)
end

function UI_GM:SetStamina()
	Stamina = self.Stamina

	local Cmd = string.format("SetStamina(%s)",Stamina)
	
	local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
	Player:Server_DoConsoleCmd(Cmd)
end

function UI_GM:SetMaxStamina()
	MaxStamina = self.MaxStamina

	local Cmd = string.format("SetMaxStamina(%s)",MaxStamina)
	
	local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
	Player:Server_DoConsoleCmd(Cmd)
end


function UI_GM:GoTo()
	Position = self.Position

	local Cmd = string.format("gmgo(%s,%s,%s)",Position.X,Position.Y,Position.Z)
	-- local Cmd = string.format("gmgo(%d,%d,%d)",0,0,0)
	
	local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
	Player:Server_DoConsoleCmd(Cmd)
end

function UI_GM:PointCollect()
	local Cmd = string.format("PointCollect()")
	local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
	Player:Server_DoConsoleCmd(Cmd)
end

function UI_GM:ShowCharacterLocation()

	local controller = UE.UGameplayStatics.GetPlayerController(t.PC(1), 0)
	ControllerUIComponent = controller.ControllerUIComponent

	if not ControllerUIComponent.actor.DebugInfoWidget then

		ControllerUIComponent:CallDebugInfoWidget(1)
    else
		ControllerUIComponent:CallDebugInfoWidget(0)
	end

end


return UI_GM