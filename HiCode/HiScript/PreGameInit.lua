local BPConst = require("common.const.blueprint_const")

local G = require("G")

function LoadBPSubsystems()
    G.log:info("xaelpeng", "PreGameInit LoadBPSubsystems")
    BPConst.GetClientConnectorSubsystemClass()
end

LoadBPSubsystems()

return {}
