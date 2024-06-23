
local M = {}

-- lua gc间歇率（默认200，值越低，gc频率越高）
M.LuaGCPauseInPIE = 100

-- Tag
M.MonsterTag = "Monster"

-- 蔷薇领SequenceBind相关
M.BossBindTag = "Boss"
M.DogBindTag = "Dog"
M.AkayaBindTag = "Akaya"

M.BossActorTag = M.BossBindTag
M.DogActorTag = M.DogBindTag
M.AkayaActorTag = M.AkayaBindTag
M.ChuJueActorTag = "ChuJueLocation"

return M
