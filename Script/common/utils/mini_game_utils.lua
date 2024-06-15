local G = require("G")

local MiniGameUtils = {
    Data = {}
}

function MiniGameUtils:SetMiniGameData(GameId, SaveData)
    self.Data[GameId] = SaveData
end

function MiniGameUtils:GetMiniGameData(GameId)
    return self.Data[GameId] 
end

function MiniGameUtils:GetRemainRewardCount()
    return 10
end

return MiniGameUtils
