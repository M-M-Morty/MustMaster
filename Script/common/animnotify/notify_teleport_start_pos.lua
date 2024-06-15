require "UnLua"
local G = require("G")
local M = Class()

-- function M:Received_NotifyBegin(MeshComp, Animation, TotalDuration)
-- end

function M:Received_Notify(MeshComp, Animation, EventReference)
    local actor = MeshComp:GetOwner()
    if actor:IsServer() then
        return
    end
    -- G.log:debug("hycoldrain", "MaterialMgrComponent Notify_TeleportStartPos Received_Notify+++++++++++++ %s %s %s %s", tostring(actor:IsServer()), tostring(self), tostring(Animation), tostring(self.DynamicMaterial))

    if self.MaterialParameterName and self.MaterialParameterName ~= "None" then
        local Location = (MeshComp:GetSocketLocation(self.HeadSocketName) + MeshComp:GetSocketLocation(self.FootSocketName)) * 0.5
        actor:SendMessage("CacheParameterValues", Animation, self.DynamicMaterial, self.MaterialParameterName, Location)
    end

    -- G.log:debug("hycoldrain", "MaterialMgrComponent Notify_TeleportStartPos Received_Notify+++++++++++++ 111 %s %s %s %s", tostring(actor:IsServer()), tostring(self), tostring(Animation), tostring(self.DynamicMaterial))
end

return M