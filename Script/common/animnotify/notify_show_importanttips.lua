--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR shiniingliu
-- @DATE 2024-1-18
--
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")

---@type AN_ShowImportantTips_C
local notify_show_importanttips = UnLua.Class()

function notify_show_importanttips:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsClient() then return false end
    TipsUtil.ShowImportantTips(self.TipsContentKey, self.Duration)
    return true
end

return notify_show_importanttips
