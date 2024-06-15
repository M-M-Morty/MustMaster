--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")

---@type ANS_MeshHide_C
local M = Class()

function M:Received_NotifyBegin(MeshComp, Animation, TotalDuration)
    -- local Owner = MeshComp:GetOwner()
    -- Owner:SetActorHiddenInGame(true)
    MeshComp:SetVisibility(false, false)
    return true
end

-- function M:Received_NotifyTick(MeshComp, Animation, FrameDeltaTime)
-- end

function M:Received_NotifyEnd(MeshComp, Animation)
    MeshComp:SetVisibility(true, false)
    -- local Owner = MeshComp:GetOwner()
    -- Owner:SetActorHiddenInGame(false)
    return true
end

return M
