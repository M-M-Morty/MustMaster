local G = require("G")

local GAKnockFlyBase = require("skill.knock.GAKnockFlyBase")
local InKnockTypes = require("common.event_const").InKnockTypes
local GAKnockFlyAvatar = Class(GAKnockFlyBase)

function GAKnockFlyAvatar:ActivateAbilityFromEvent()
    Super(GAKnockFlyAvatar).ActivateAbilityFromEvent(self)

    self:HandleComboTail()
end

return GAKnockFlyAvatar
