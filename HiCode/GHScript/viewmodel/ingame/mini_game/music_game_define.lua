---@class SongListData
---@field songName string
---@field songId number
---@field totalScore number
---@field musicFile string
---@field cameraData string
---@field time number
---@field level string
---@field performer string
---@field lowScore number
---@field lowScoreReward number[]
---@field midScore number
---@field midScoreReward number[]
---@field highScore number
---@field highScoreReward number[]
---@field maxScore number|nil
local SongListData = {}

---@class SongReward
---@field RewardId integer
---@field Num integer
local SongReward = {}

---@class SongData
---@field SongId number
---@field SongListId number
---@field Name string
---@field MaxScore number|nil
---@field Level string
---@field Performer string
---@field Time integer
---@field Keys MusicKey[]
local SongData = {}

---@class MusicKey
---@field minDuration number 最小单位时间
---@field perfectTime number 最佳按键时间
---@field keyPosition number 按键位置 range 1-4/1-6
---@field bComplete boolean 是否完成
---@field keyType number 按键类型(1:长按 2:短按)
---@field duration number 键程
local MusicKey = {}

---@class SongIndex
---@field songName string
---@field time number
---@field level string
---@field performer string
---@field description string
---@field addBy string
---@field lowScore number
---@field lowScoreReward number[]
---@field midScore number
---@field midScoreReward number[]
---@field highScore number
---@field highScoreReward number[]
local SongIndex = {}

---@class MusicEvaluate
---@field desc string
---@field value string
local MusicEvaluate = {}

---@class MusicDescription
---@field desc string
---@field value string
local MusicDescription = {}

---@class SaveSongData
---@field Id integer
---@field Name string
---@field MaxScore number|nil
---@field RewardLevel number
local SaveSongData = {}

---@class RewardLevel
local RewardLevel =
{
    None = 1,
    Low = 2,
    Middle = 3,
    High = 4,
}

---@class MusicDescriptionText
local MusicDescriptionText =
{
    "MusicGame_TEXT_1001",
    "MusicGame_TEXT_1002",
}

---@class MusicEvaluateText
local MusicEvaluateText =
{
    "MusicGame_TEXT_1003",
    "MusicGame_TEXT_1004",
}

---@class LastScoreText
local LastScoreText =
{
    "MusicGame_TEXT_1008",  --- Miss
    "MusicGame_TEXT_1007",  --- Bad
    "MusicGame_TEXT_1006",  --- Good
    "MusicGame_TEXT_1005",  --- perfect
}

---@class EvaluateType
local EvaluateType =
{
    Perfect = 3,
    Good = 2,
    Bad = 1,
    Miss = 0,
}

---@class GameMode
local GameMode =
{
    Score = 1,
    Enjoy = 2,
}

local MusicGameDefine = Class()

MusicGameDefine.EvaluateType = EvaluateType
MusicGameDefine.RewardLevel = RewardLevel
MusicGameDefine.LastScoreText = LastScoreText
MusicGameDefine.MusicEvaluateText = MusicEvaluateText
MusicGameDefine.MusicDescriptionText = MusicDescriptionText
MusicGameDefine.SaveSongData = SaveSongData
MusicGameDefine.MusicDescription = MusicDescription
MusicGameDefine.MusicEvaluate = MusicEvaluate
MusicGameDefine.SongIndex = SongIndex
MusicGameDefine.MusicKey = MusicKey
MusicGameDefine.SongData = SongData
MusicGameDefine.SongReward = SongReward
MusicGameDefine.SongListData = SongListData
MusicGameDefine.GameMode = GameMode

return MusicGameDefine