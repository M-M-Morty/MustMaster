local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local AttributeComponentBase = Component(ComponentBase)

function AttributeComponentBase:Initialize(...)
    Super(AttributeComponentBase).Initialize(self, ...)
end

function AttributeComponentBase:Start()
    Super(AttributeComponentBase).Start(self)
end

return AttributeComponentBase
