require "UnLua"
local utils = require("common.utils")

local G = require("G")

local Notify_PlayMonologue = Class()

function Notify_PlayMonologue:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsClient() then
        return true
    end

    local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    Player:SendMessage("StartMonologue", self.MonologueID)

    return true
end


return Notify_PlayMonologue
