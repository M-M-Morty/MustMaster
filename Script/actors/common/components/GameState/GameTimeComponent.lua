local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local GameConstData = require("common.data.game_const_data").data
local TimeUtil = require("common.utils.time_utils")

local GameTimeComponent = Component(ComponentBase)

local GAME_TIME_SYNC_INTERVAL = 10  -- 游戏时间10分钟，服务端向客户端同步一次

function GameTimeComponent:Initialize(Initializer)
    self.LastUpdateTimeStamp = 0  -- 上一次更新MinuteOfDay的时间戳(现实时间)
    self.UpdateTimer = nil
end

function GameTimeComponent:ReceiveBeginPlay()
    self.LastUpdateTimeStamp = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    if self:GetOwner():IsServer() then
        self:RefreshUpdateTimer()
    end
end

function GameTimeComponent:ReceiveEndPlay()
    if self.UpdateTimer then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.UpdateTimer)
        self.UpdateTimer = nil
    end
end

function GameTimeComponent:GetDayNum()
    local TimeStamp = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    local GameTimeDurationMinute = math.floor((TimeStamp - self.LastUpdateTimeStamp) / TimeUtil.SECONDS_PER_MINUTE * GameConstData.GAME_TIME_RATE.IntValue)
    return self.DayNum + math.floor((self.MinuteOfDay + GameTimeDurationMinute) / TimeUtil.MINUTES_PER_DAY)
end

function GameTimeComponent:GetMinuteOfDay()
    local TimeStamp = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    local GameTimeDurationMinute = math.floor((TimeStamp - self.LastUpdateTimeStamp) / TimeUtil.SECONDS_PER_MINUTE * GameConstData.GAME_TIME_RATE.IntValue)
    return (self.MinuteOfDay + GameTimeDurationMinute) % TimeUtil.MINUTES_PER_DAY
end

function GameTimeComponent:GetHourOfDay()
    return math.floor(self:GetMinuteOfDay() / TimeUtil.MINUTES_PER_HOUR)
end

-- server
function GameTimeComponent:OnUpdateTime(GameTimeDurationMinute)
    -- 游戏时间每隔GAME_TIME_SYNC_INTERVAL分钟，通知下客户端
    self.LastUpdateTimeStamp = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    self.DayNum = self.DayNum + math.floor((self.MinuteOfDay + GameTimeDurationMinute) / TimeUtil.MINUTES_PER_DAY)
    self.MinuteOfDay = (self.MinuteOfDay + GameTimeDurationMinute) % TimeUtil.MINUTES_PER_DAY
    self:CheckHourTime()
end

-- server
function GameTimeComponent:AddMinutes(Minutes)
    if Minutes < GAME_TIME_SYNC_INTERVAL or Minutes > TimeUtil.MINUTES_PER_DAY then
        G.log:warn("GameTimeComponent:AddMinutes", "Minutes(%s) error", Minutes)
        return
    end
    Minutes = math.floor(Minutes / GAME_TIME_SYNC_INTERVAL) * GAME_TIME_SYNC_INTERVAL  -- 时间对齐
    self:OnUpdateTime(Minutes)
    -- 刷新计时器
    self:RefreshUpdateTimer()
end

function GameTimeComponent:RefreshUpdateTimer()
    if self.UpdateTimer then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.UpdateTimer)
    end
      -- 游戏时间每十分钟触发一次
    self.UpdateTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, function() self:OnUpdateTime(GAME_TIME_SYNC_INTERVAL) end}, 
        TimeUtil.SECONDS_PER_MINUTE / GameConstData.GAME_TIME_RATE.IntValue * GAME_TIME_SYNC_INTERVAL, true)
end

function GameTimeComponent:OnRep_MinuteOfDay()
    -- 游戏内分钟数变化
    self.LastUpdateTimeStamp = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    self:CheckHourTime()
    -- 客户端昼夜变化表现
    if self.MinuteOfDay % TimeUtil.MINUTES_PER_HOUR == 0 then
        self:TimeChangeAppearance()
    end
end

function GameTimeComponent:OnRep_DayNum()
    -- 游戏内天数变化
end

function GameTimeComponent:CheckHourTime()
    if self.MinuteOfDay % TimeUtil.MINUTES_PER_HOUR == 0 then
        -- 整点
        self.OnGameHourChanged:Broadcast(math.floor(self.MinuteOfDay / TimeUtil.MINUTES_PER_HOUR))
    end
end

function GameTimeComponent:TimeChangeAppearance()
    local CurHour = math.floor(self.MinuteOfDay / TimeUtil.MINUTES_PER_HOUR)
    local TargetActors = UE.TArray(UE.ATODWeatherManager)
    UE.UGameplayStatics.GetAllActorsOfClass(self, UE.ATODWeatherManager, TargetActors)

    for i = 1, TargetActors:Length() do
        -- 理论上应该只会有一个
        G.log:debug("GameTimeComponent", "TimeChangeAppearance Hour=%s, Transition=%s", CurHour, GameConstData.DAY_NIGHT_TRANSITION_DURATION.IntValue)
        local Target = TargetActors[i]
        Target:TransitionHourTimeTo(CurHour, GameConstData.DAY_NIGHT_TRANSITION_DURATION.IntValue)
    end
end

return GameTimeComponent
