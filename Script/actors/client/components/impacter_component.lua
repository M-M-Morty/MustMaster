--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


require "UnLua"
local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

---@type ImpacterComponent_C
local ImpacterComponent = Component(ComponentBase)
local decorator = ImpacterComponent.decorator

-- function M:Initialize(Initializer)
-- end

--function ImpacterComponent:ReceiveBeginPlay()
--    Super(ImpacterComponent).ReceiveBeginPlay(self)
--    G.log:info("[hycoldrain]", "ImpacterComponent:ReceiveBeginPlay")
--end
--


return ImpacterComponent

