local G = require("G")
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local MusicGameDefine = require('CP0032305_GH.Script.viewmodel.ingame.mini_game.music_game_define')
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
local MiniGameUtils = require('Script.common.utils.mini_game_utils')
local PicText = require("CP0032305_GH.Script.common.pic_const")
local ConstTextTable = require("common.data.const_text_data").data
local SongIndexData = require("common.data.SongIndex").data

local HeadPath = "common.data."

---@class MusicGameVM : ViewModelBase
local MusicGameVM = Class(ViewModelBaseClass)
MusicGameVM.DEFAULT_SONG_ID = 1
MusicGameVM.DEFAULT_ITEM_ID = 1
MusicGameVM.INVALID_TIME = -1
MusicGameVM.INVALID_SCORE = 0

function MusicGameVM:ctor()
    Super(MusicGameVM).ctor(self)

    ---@type SongListData[]
    self.CurSongIndexData = {}
    self.CurSongIndexSortList = {}
    self.LastSelectedSong = self.DEFAULT_SONG_ID
    self.LastSelectedItem = self.DEFAULT_ITEM_ID
    self.CurrentSelectSongField = self:CreateVMField(self.DEFAULT_SONG_ID)
    self.CurrentSelectedItemField = self:CreateVMField(self.DEFAULT_ITEM_ID)
    self:InitMusicGameVM()

    self.bFirstOpen = 1
    self.SongItemPress = -1
end

function MusicGameVM:InitMusicGameVM()
    self:ResetData()
end

function MusicGameVM:split(str, sep)
    local result = {}
    local pattern = string.format("([^%s]+)", sep)
    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end
    return result
end

function MusicGameVM:InitSongListByIndexList(idxList)
    local tmpList = self:split(idxList,";")
    self.CurSongIndexData = {}
    self.CurSongIndexSortList = {}
    for i, v in ipairs(tmpList) do
        table.insert(self.CurSongIndexSortList, tonumber(v))
        self.CurSongIndexData[tonumber(v)] = {}
        self.CurSongIndexData[tonumber(v)].songId = tonumber(v)
        self.CurSongIndexData[tonumber(v)].songName = SongIndexData[tonumber(v)].songName
    end
end

function MusicGameVM:GetCurSongIndexList()
    local indexList = {}
    for i, v in pairs(self.CurSongIndexData) do
        table.insert(indexList, v.songId)
    end
    return indexList
end

function MusicGameVM:GetMaxSongNum()
    if self.CurSongIndexSortList == nil then
        return 0
    end
    return #self.CurSongIndexSortList
end

function MusicGameVM:InitSongIndexData()
    ---@type SongListData[]
    local AllSongData = SongIndexData
    self.CurSongIndexData = {}
    self.CurSongIndexSortList = {}
    for i, v in pairs(AllSongData) do
        table.insert(self.CurSongIndexSortList, i)
        self.CurSongIndexData[i] = {}
        self.CurSongIndexData[i].songId = i
        self.CurSongIndexData[i].songName = v.songName
    end
end

function MusicGameVM:ResetData()
    self:ResetSongData()
    self:ResetNumData()

    self.LastSelectedSong = self.DEFAULT_SONG_ID
    self.LastSelectedItem = self.DEFAULT_ITEM_ID
    self.CurrentSelectSongField:SetFieldValue(self.DEFAULT_SONG_ID)
    self.CurrentSelectSongField:BroadcastValueChanged()
    self.CurrentSelectedItemField:SetFieldValue(self.DEFAULT_ITEM_ID)
    self.CurrentSelectedItemField:BroadcastValueChanged()
end

function MusicGameVM:ResetSongData()
    ---@type SongData
    self.curSongData = {}
    ---@type MusicKey
    self.tbCurSongKeyList = {}
    ---@type SongListData
    self.tbSongIndex = {}
    ---@type MusicEvaluate[]
    self.curEvaluteList = {}

    self:InitRewardData()
end

function MusicGameVM:ResetNumData()
    self.CurScore = 0
    self.Accuracy = 0
    self.Combo = 0

    self.LowScore = 0
    self.MidScore = 0
    self.HighScore = 0

    self.PlayTime = self.INVALID_TIME

    self.MusicGameMode = true
end

function MusicGameVM:SetMusicGameMode(bShow)
    if bShow == nil then
        return
    end
    if bShow == "true" then
        self.MusicGameMode = true
    else
        self.MusicGameMode = false
    end
end

function MusicGameVM:SetCurRawData(tb)
    self.curRawData = tb
    self:InitSongListByIndexList(tb[1])
    self:SetMusicGameMode(tb[2])
end

function MusicGameVM:GetCurRawData()
    return self.curRawData
end

---@param SongKey number
function MusicGameVM:SetCurSongData(SongKey)
    local GetSuccess = self:SetSongRequireFilePath(SongKey)
    if not GetSuccess then
        return
    end
    local MaxScore = self:GetMaxScore(SongKey)
    self.curSongData.SongId = SongKey
    self.curSongData.Name = self.tbSongIndex.songName
    self.curSongData.Level = self.tbSongIndex.level
    self.curSongData.Performer = self.tbSongIndex.performer
    self.curSongData.Time = self.tbSongIndex.time
    self.curSongData.MaxScore = MaxScore
    self.curSongData.Keys = self.tbCurSongKeyList
end

---@param SongKey number
function MusicGameVM:SetSongRequireFilePath(SongKey)
    self.tbSongIndex = SongIndexData[SongKey]
    if not self.tbSongIndex then
        return
    end
    local musicFile = tostring(self.tbSongIndex.musicFile)
    local musicName = musicFile:gsub("%.mid$", "")
    local SongDataPath = HeadPath .. musicName
    local success, myModule = pcall(require, SongDataPath)
    if not success then
        G.log:error("wyx", "Music Game error loading module: %s", tostring(SongDataPath))
        return
    end
    self.tbCurSongKeyList = myModule.data
    return true
end

function MusicGameVM:UpdateSelectSong(SongId)
    self.LastSelectedSong = self.CurrentSelectSongField:GetFieldValue()
    self.CurrentSelectSongField:SetFieldValue(SongId)
end

function MusicGameVM:UpdateSelectedItem(Index)
    self.LastSelectedItem = self.CurrentSelectedItemField:GetFieldValue()
    self.CurrentSelectedItemField:SetFieldValue(Index)
end

---------------------------------------------------Reward(start)--------------------------------------------------------
function MusicGameVM:InitRewardData()
    ---@type SongReward
    self.LowRewardList = {}
    ---@type SongReward
    self.MidRewardList = {}
    ---@type SongReward
    self.HighRewardList = {}
end

function MusicGameVM:GetRewardsData()
    self.LowScore = self.tbSongIndex.lowScore
    self.MidScore = self.tbSongIndex.midScore
    self.HighScore = self.tbSongIndex.highScore

    self:SetRewardsData()
end

function MusicGameVM:SetRewardsData()
    local LowRewardList = self:ArrayToTable(self.tbSongIndex.lowScoreReward)
    self.LowRewardList = self:GetPropItemData(LowRewardList)

    local MidRewardList = self:ArrayToTable(self.tbSongIndex.midScoreReward)
    self.MidRewardList = self:GetPropItemData(MidRewardList)

    local HighRewardList = self:ArrayToTable(self.tbSongIndex.highScoreReward)
    self.HighRewardList = self:GetPropItemData(HighRewardList)
end

---@param RewardList SongReward[]
function MusicGameVM:ArrayToTable(RewardList)
    local result = {}
    for i = 1, #RewardList, 2 do
        local key = RewardList[i]
        local value = RewardList[i + 1]
        result[key] = value
    end
    return result
end

function MusicGameVM:GetPropItemData(RewardList)
    if not RewardList then
        return 0
    end
    local tbRewardList = ItemUtil.ItemSortFunctionByList(RewardList)
    for _, v in pairs(tbRewardList) do
        local rewardItem = ItemUtil.GetItemConfigByExcelID(v.ID)
        v.IconResourceObject = PicText.GetPicResource(rewardItem.icon_reference)
    end
    return tbRewardList
end

function MusicGameVM:MergeRewardList(table1, table2)
    local result = {}
    for k, v in pairs(table1) do
        result[k] = v
    end
    for k, v in pairs(table2) do
        result[k] = v
    end
    return result
end

function MusicGameVM:GetSongRewards()
    if self.CurScore < self.LowScore then
        self:SetSongRewardLevel(MusicGameDefine.RewardLevel.None)
        return 0
    elseif self.CurScore >= self.LowScore and self.CurScore < self.MidScore then
        self:SetSongRewardLevel(MusicGameDefine.RewardLevel.Low)
        return self.LowRewardList
    elseif self.CurScore >= self.MidScore and self.CurScore < self.HighScore then
        self:SetSongRewardLevel(MusicGameDefine.RewardLevel.Middle)
        return self:MergeRewardList(self.LowRewardList, self.MidRewardList)
    else
        self:SetSongRewardLevel(MusicGameDefine.RewardLevel.High)
        local tempList = self:MergeRewardList(self.LowRewardList, self.MidRewardList)
        return self:MergeRewardList(tempList, self.HighRewardList)
    end
end

function MusicGameVM:SetSongRewardLevel(RewardLevel)
    ---@type SaveSongData
    local thisData = MiniGameUtils:GetMiniGameData(self.curSongData.SongId)
    if not thisData then
        local tbSaveList = {}
        tbSaveList.Id = self.curSongData.SongId
        tbSaveList.Name = self.curSongData.Name
        tbSaveList.RewardLevel = RewardLevel
        MiniGameUtils:SetMiniGameData(tbSaveList.Id, tbSaveList)
    else
        if thisData.RewardLevel and RewardLevel > thisData.RewardLevel then
            thisData.RewardLevel = RewardLevel
        end
    end
end

---------------------------------------------------Reward(end)----------------------------------------------------------

--------------------------------------------------Settlement(start)-----------------------------------------------------

---@param num number
---@param type number
function MusicGameVM:SetSongEvaluateData(num, type)
    local typeText = ConstTextTable[MusicGameDefine.LastScoreText[type + 1]].Content
    for i, v in pairs(self.curEvaluteList) do
        if v.desc == typeText then
            self.curEvaluteList[i].value = tostring(num)
            return
        end
    end
    ---@type MusicEvaluate
    local tempEvaluate = {}
    tempEvaluate.desc = typeText
    tempEvaluate.value = tostring(num)
    self.curEvaluteList[type+3] = tempEvaluate
end

function MusicGameVM:SetAccuracy(accuracy)
    self.Accuracy = accuracy
    ---@type MusicEvaluate
    local tempData = {}
    tempData.desc = ConstTextTable[MusicGameDefine.MusicEvaluateText[1]].Content
    tempData.value = tostring(self.Accuracy) .. "%"
    self.curEvaluteList[1] = tempData
end

function MusicGameVM:SetCombo(combo)
    self.Combo = combo
    ---@type MusicEvaluate
    local tempData = {}
    tempData.desc = ConstTextTable[MusicGameDefine.MusicEvaluateText[2]].Content
    tempData.value = tostring(self.Combo)
    self.curEvaluteList[2] = tempData
end

function MusicGameVM:GetShowTime(milliseconds)
    if milliseconds == nil then
        return ""
    end
    local ShowTime
    local seconds = milliseconds / 1000
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    local MinText = ConstTextTable["MusicGame_TEXT_1009"].Content
    local SecText = ConstTextTable["MusicGame_TEXT_1010"].Content
    if minutes > 0 and remainingSeconds > 0 then
        ShowTime = minutes .. MinText .. math.floor(remainingSeconds) .. SecText
    elseif remainingSeconds == 0 then
        ShowTime = minutes .. MinText
    elseif minutes == 0 then
        ShowTime = math.floor(remainingSeconds) .. SecText
    end
    return ShowTime
end

---@return MusicDescription[]
function MusicGameVM:GetMusicDescriptionData()
    ---@type MusicDescription
    local tempList = {}
    local tempData = {}
    local getTime

    tempData.desc = ConstTextTable[MusicGameDefine.MusicDescriptionText[1]].Content
    tempData.value = self.curSongData.Level
    table.insert(tempList, tempData)

    tempData = {}
    tempData.desc = ConstTextTable[MusicGameDefine.MusicDescriptionText[2]].Content
    if self.PlayTime ~= self.INVALID_TIME then
        getTime = self.PlayTime
    else
        getTime = self.curSongData.Time
    end
    tempData.value = self:GetShowTime(getTime)
    table.insert(tempList, tempData)

    return tempList
end

function MusicGameVM:SetPlayTime(Time)
    self.PlayTime = Time
end

function MusicGameVM:SetCurScore(score)
    local maxScore = self:GetMaxScore(self.curSongData.SongId) or self.INVALID_SCORE
    self.CurScore = score
    if maxScore < self.CurScore then
        self:SetMaxScore(self.CurScore)
    end
end

function MusicGameVM:SetMaxScore(maxScore)
    ---@type SaveSongData
    local thisData = MiniGameUtils:GetMiniGameData(self.curSongData.SongId)
    if not thisData then
        local tbSaveList = {}
        tbSaveList.Id = self.curSongData.SongId
        tbSaveList.Name = self.curSongData.Name
        tbSaveList.MaxScore = maxScore
        MiniGameUtils:SetMiniGameData(tbSaveList.Id, tbSaveList)
    else
        thisData.MaxScore = maxScore
    end
end

function MusicGameVM:GetMusicGameMode()
    return self.MusicGameMode
end

--------------------------------------------------Settlement(end)-------------------------------------------------------

---@return number
function MusicGameVM:GetCurrentSelectSong()
    return self.CurrentSelectSongField:GetFieldValue()
end

---@return number
function MusicGameVM:GetCurrentSelectItem()
    return self.CurrentSelectedItemField:GetFieldValue()
end

---@return number
function MusicGameVM:GetLastSelectedItem()
    return self.LastSelectedItem
end

---@return number
function MusicGameVM:GetLastSelectedSong()
    return self.LastSelectedSong
end

---@return SongData
function MusicGameVM:GetCurSongData()
    return self.curSongData
end

---@return SongListData[]
function MusicGameVM:GetCurSongIndexListData()
    if not self.CurSongIndexData or #self.CurSongIndexData < 1 then
        self:InitSongIndexData()
        G.log:warn("musicSong", "MusicSongList not exist, loading all song now....")
    end
    return self.CurSongIndexData
end

function MusicGameVM:GetCurSongIndexSortList()
    if not self.CurSongIndexSortList or #self.CurSongIndexSortList < 1 then
        self:InitSongIndexData()
        G.log:warn("musicSong", "MusicSortSongList not exist, loading all song now....")
    end
    return self.CurSongIndexSortList
end

function MusicGameVM:GetMusicEvaluate()
    return self.curEvaluteList
end

---@param key number
function MusicGameVM:GetMaxScore(key)
    if not key then
        return
    end
    local ThisData = MiniGameUtils:GetMiniGameData(key)
    if not ThisData then
        return
    end
    return ThisData.MaxScore
end

function MusicGameVM:GetSequenceBySong(id)
    return SongIndexData[id].cameraData
end

---@return number
function MusicGameVM:GetCurSocre()
    return self.CurScore
end

function MusicGameVM:GetTextByIndex(IndexText)
    return ConstTextTable[IndexText].Content
end

function MusicGameVM:SetFirstOpen(isFirst)
    self.bFirstOpen = isFirst
end

function MusicGameVM:GetFirstOpen()
    return self.bFirstOpen
end

function MusicGameVM:SetSongItemPressed(isPressed)
    self.SongItemPress = isPressed
end

function MusicGameVM:GetSongItemPressed()
    return self.SongItemPress
end

return MusicGameVM
