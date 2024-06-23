require "UnLua"

local Notify_CallPartnerEnterBattle = Class()

-- AN_CallPartnerEnterBattle
function Notify_CallPartnerEnterBattle:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsClient() then
        return true
    end

    Owner:SendMessage("CallPartnerEnterBattle")
    return true
end

return Notify_CallPartnerEnterBattle
