require "UnLua"

-- local utils = require("common.utils")
-- local G = require("G")

---@type notify_begin_deathdissolve
local notify_begin_deathdissolve = Class()

function notify_begin_deathdissolve:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsClient() then return false end
    local AppearanceComponent = Owner.AppearanceComponent
    if not AppearanceComponent or not AppearanceComponent:IsValid() then return false end
    if AppearanceComponent and AppearanceComponent.OnDeathDissolveBegin then
        AppearanceComponent:OnDeathDissolveBegin()  --死亡消散效果Begin
    end
    return true
end

return notify_begin_deathdissolve
