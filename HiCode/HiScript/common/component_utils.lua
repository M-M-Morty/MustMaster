require "UnLua"

ComponentUtils = {}

-- Component tags of actor.
local Tags = {}
Tags.Lockable = "Lockable"
Tags.InAirLockable = "InAirLockable"
Tags.Body = "Body"
Tags.Head = "Head"
Tags.HandleLeft = "Hand_L"
Tags.HandleRight = "Hand_R"
Tags.ArmLeft = "Arm_L"
Tags.ArmRight = "Arm_R"
Tags.UnHitable = "UnHitable"

ComponentUtils.Tags = Tags

function ComponentUtils.ComponentLockable(Comp)
    return Comp:ComponentHasTag(Tags.Lockable)
end

function ComponentUtils.ComponentUnHitable(Comp)
    return Comp:ComponentHasTag(Tags.UnHitable)
end

return ComponentUtils
