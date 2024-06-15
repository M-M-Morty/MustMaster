require "UnLua"

local G = require("G")

LoadingUtils = {}

LoadingUtils.StartLoadingTimeMs = 0

function LoadingUtils:GetLoadingPrgress()
    -- 目前提供的假loading效果，时长固定5S。
    -- 以后切换成正式流程，需要删除StartLoadingTimeMs变量
    local NowMs = G.GetNowTimestampMs()

    if self.StartLoadingTimeMs == 0 then
        self.StartLoadingTimeMs = NowMs
        return 0
    end

    if NowMs - self.StartLoadingTimeMs >= 5000 then
        self.StartLoadingTimeMs = 0
        return 1
    end

    return (NowMs - self.StartLoadingTimeMs) / 5000.0
end

return LoadingUtils
