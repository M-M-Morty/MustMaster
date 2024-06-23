require "UnLua"
local G = require("G")
local t = require("t")
local UIDebugInfo = Class()
local FirstStarthandle

function UIDebugInfo:Construct()
    self.Overridden.Construct(self)

    FirstStarthandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.UpdateText},0.1,true)
end

function UIDebugInfo:UpdateText()
    local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    local Location = Player:K2_GetActorLocation()

    Info = string.format("My Location:%.2f,%.2f,%.2f",Location.x,Location.y,Location.z)
	self.InfoTextBlock:SetText(Info)
end

function UIDebugInfo:Deconstruct()
    self.Overridden.Deconstruct()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self,self.FirstStarthandle)
end

return UIDebugInfo