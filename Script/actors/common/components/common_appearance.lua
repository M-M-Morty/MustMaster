local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local G = require("G")

local CommonAppearence = Component(ComponentBase)

local decorator = CommonAppearence.decorator

function CommonAppearence:EnterSkillAnimWithIdleActing(IdleActingBehavior)
    self:EnterSkillAnim()
end

function CommonAppearence:LeaveSkillAnimWithIdleActing(IdleActingBehavior)
    self:LeaveSkillAnim()
end


return CommonAppearence