require "UnLua"
require"os"

local Actor = require("common.actor")
local G = require("G")
local Loader = require("actors.client.AsyncLoaderManager")
local GameState = require("common.gameframework.game_state.default")
local WeatherManagerActor = Class(Actor)

local  WEATHER_MANAGER_KEY = 'WEATHER_MANAGER_GLOBAL'
local DAY_IN_SECONDES = 86400
local HOUR_IN_SECONDS = 3600
------------------------------------------------------------------------------------------------------------------------------------------------

SequenceHandle = 1

WeatherManagerActor.WeatherTypeAutoDay = 1;
WeatherManagerActor.WeatherTypeTrigger = 2;

WeatherManagerActor.AutoDayWeatherInterpolation = 0


-- 初始 Nowweather 赋值
--有新的weather加入，找出比nowweather还高的weather，设置为targetweather，过渡过去，这期间，如果有新weather加入，则targetweather不变。
--变换为targetweather后，nowweather改为targetweather值，然后再刷新去查找是否有新的targetweather
--删除weather，如果这个weather是targetweather，则延迟删除，将tagetweather上标记为删除状态，在过渡到targetweather时马上寻找下一个weather，再过渡过去，过渡结束时删除.


function WeatherManagerActor:Initialize(...)
    Super(WeatherManagerActor).Initialize(self, ...)
    self.NowWeather = nil
    self.TargetWeather = nil
    self.WeatherSequenceDict = {}
    self.InLerping = nil
end

function WeatherManagerActor:ReceiveBeginPlay()
    G.log:info("[lz]","-----WeatherManagerActor:ReceiveBeginPlay --------")

    local ObjectRegistryWorldSubsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(self, UE.UObjectRegistryWorldSubsystem)
    if ObjectRegistryWorldSubsystem ~= nil then
        ObjectRegistryWorldSubsystem:RegisterObject(WEATHER_MANAGER_KEY, self)
    end
end

function WeatherManagerActor:ReceiveEndPlay()
    G.log:info("[lz]","-----WeatherManagerActor:ReceiveEndPlay %s --------", self.TargetWeather)
    if self.TargetWeather ~= nil then
        self:StopLerpingToTarget()
    end

    self.NowWeather = nil

    for k, v in pairs(self.WeatherSequenceDict) do
        if  v.TargetActor ~= nil then
            v.TargetActor:K2_DestroyActor()
        end
    end
    self.WeatherSequenceDict = nil

    local ObjectRegistryWorldSubsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(self, UE.UObjectRegistryWorldSubsystem)
    if ObjectRegistryWorldSubsystem ~= nil then
        ObjectRegistryWorldSubsystem:UnregisterObject(WEATHER_MANAGER_KEY, self)
    end

end

function WeatherManagerActor:CreateSequenceActorFormLevelSequence(LevelSequence)
    local SpawnParameters = UE.FActorSpawnParameters()
    local SpawnTransform = UE.FTransform.Identity
    local ExtraData = {}
    local TemplateActor = GameAPI.SpawnActor(self:GetWorld(), UE.ALevelSequenceActor ,SpawnTransform, SpawnParameters, ExtraData)
    TemplateActor:SetSequence(LevelSequence)
    return TemplateActor
    
end

function WeatherManagerActor:RefreshTargetWeather()
    if self.TargetWeather~= nil then
        return
    end

    local NewWeatherTarget = nil
    for k, v in pairs(self.WeatherSequenceDict) do
        if v.Removed ==nil and v.TargetActor ~= nil and (NewWeatherTarget == nil or NewWeatherTarget.Priority < v.Priority) then
            NewWeatherTarget = v
        end
    end

    if NewWeatherTarget == nil then
        return
    end
    -- first time 
    if self.NowWeather == nil then
        self.NowWeather = NewWeatherTarget
        self.NowWeather.TargetActor.PlaybackSettings.LoopCount.Value = -1;
        self.NowWeather.TargetActor.SequencePlayer.PlaybackSettings.LoopCount.Value = -1;
        self.NowWeather.TargetActor.SequencePlayer:Play()

        G.log:info("[lz]","-----First weather comes %s--------", self.NowWeather.TargetActor:GetSequence():GetName())
        return
    end
    
    if G.FreezeTODTime ~=nil then
        return
    end
    if self.NowWeather.Removed ~= nil or (NewWeatherTarget ~= self.NowWeather and NewWeatherTarget.Priority > self.NowWeather.Priority) then
        self.TargetWeather = NewWeatherTarget

        self.NowWeather.StartLerpingTime = UE.UKismetMathLibrary.Now()
        G.log:info("[lz]","-----Start Lerp %s----->%s--------", self.NowWeather.TargetActor:GetSequence():GetName(), self.TargetWeather.TargetActor:GetSequence():GetName())
        self.InLerping = true
    end
end

function WeatherManagerActor:ScriptTick(DeltaSeconds)
    
    if false and G.TimeCatchUp~= nil then
        local ObjectRegistryWorldSubsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(self, UE.UObjectRegistryWorldSubsystem)
        G.log:debug("Content", "TimeCatchUps。。。%s", ObjectRegistryWorldSubsystem)
        if ObjectRegistryWorldSubsystem ~= nil then
            local wma = ObjectRegistryWorldSubsystem:FindObject(WEATHER_MANAGER_KEY)
            if wma ~= nil then
                wma:SkipToNewTime(G.TimeCatchUp)
            end
        end
        G.TimeCatchUp = nil
    end
    if G.FreezeTODTime ~= nil then
        if self.NowWeather then
            self.NowWeather.TargetActor.SequencePlayer:JumpToProportion(G.FreezeTODTime / 12)
        end

        local TODControllerActor = self:GetTODControllerActor()
            if TODControllerActor then
                TODControllerActor:SetSolarTime(G.FreezeTODTime)
            end
        return
    end

    if self.InLerping then
        self:OnLerpingToTarget()
    end
    
    local GlobaltimeActor = self:GetGlobalTimeActor(true)
    if GlobaltimeActor then
 
        local NowTimeInSecond, NowPlayRate = GlobaltimeActor:GetNowTimeInGameWorld()
        if self.NowWeather then
            local Frames = self.NowWeather.TargetActor.SequencePlayer:GetFrameDuration()
            local OriFrameRate =  self.NowWeather.TargetActor.SequencePlayer:GetFrameRateInFPS()

            local PlayRateInRealDay = Frames / DAY_IN_SECONDES / OriFrameRate
            local PlayRateInGameWorld = PlayRateInRealDay * NowPlayRate
            self.NowWeather.TargetActor.SequencePlayer:SetPlayRate(PlayRateInGameWorld);
            self.NowWeather.TargetActor.SequencePlayer:JumpToProportion(NowTimeInSecond / DAY_IN_SECONDES)
            

            local TODControllerActor = self:GetTODControllerActor()
            if TODControllerActor then
                TODControllerActor:SetSolarTime(NowTimeInSecond / HOUR_IN_SECONDS)
            end
        end
    end
end

function WeatherManagerActor:DebugOutputWeathers(Info)
    G.log:info("[lz]","-------------------------%s-----------------------------", Info)
    for k, v in pairs(self.WeatherSequenceDict) do
        local TargetName = nil
        if v.TargetActor then
            TargetName = v.TargetActor:GetSequence():GetName()
        end
        G.log:info("[lz]","key = [%s], Actor = [%s], Handle = [%s], Priority = [%s], Remove = [%s], LoadingHandle = [%s]", k, 
    TargetName, v.Handle, v.Priority, v.Removed, v.LoadingHandle)
    end
    G.log:info("[lz]","-------------------------%s-----------------------------", Info)
    
end


function  WeatherManagerActor:Interpolate(FromWeather, ToWeather, Now)
   
    local Total = ToWeather.LastTime
    assert(Now <= Total)
    return Now / Total
end


function WeatherManagerActor:OnLerpingToTarget()
    assert(self.NowWeather)
    assert(self.TargetWeather)
    local ElapseTime =  utils.GetSecondsUntilNow(self.NowWeather.StartLerpingTime)
    if  self.WeatherSequenceDict[self.NowWeather.Handle].OnFinishing == 1 then
        self.WeatherSequenceDict[self.NowWeather.Handle].OnFinishing = nil
        self:StopLerpingToTarget()
        return
    end
    if  ElapseTime >= self.TargetWeather.LastTime then

        -- [[LerpTo 功能引擎中关闭了（为5.3合并准备）。先屏蔽过渡，等后续写好再打开。
        --self.NowWeather.TargetActor.SequencePlayer:LerpTo(self.TargetWeather.TargetActor.SequencePlayer, 1.0)
        --]]
        self.WeatherSequenceDict[self.NowWeather.Handle].OnFinishing = 1
        G.log:info("[lz]"," Weather change on finishing......%s--->%s", self.NowWeather.TargetActor:GetSequence():GetName(), self.TargetWeather.TargetActor:GetSequence():GetName())
    else
        local Weight = self:Interpolate(self.NowWeather, self.TargetWeather, ElapseTime)
        
        if (Weight > 1) then
           Weight = 1
        end

        --G.log:info("[lz]","-------------------------weather Lerp %s -----> %s weight %s----------------------------",  self.NowWeather.TargetActor:GetSequence():GetName(), self.TargetWeather.TargetActor:GetSequence():GetName(),  Weight)
        -- [[LerpTo 功能引擎中关闭了（为5.3合并准备）。先屏蔽过渡，等后续写好再打开。
        --self.NowWeather.TargetActor.SequencePlayer:LerpTo(self.TargetWeather.TargetActor.SequencePlayer, Weight)
        --]]
    end
end

function WeatherManagerActor:StopLerpingToTarget()
  
    assert(self.NowWeather)
    assert(self.TargetWeather)

    local CurrentPlayTime = self.NowWeather.TargetActor.SequencePlayer:GetCurrentTime()

   self.TargetWeather.TargetActor.PlaybackSettings.LoopCount.Value = -1;
   self.TargetWeather.TargetActor.SequencePlayer.PlaybackSettings.LoopCount.Value = -1;

    self.TargetWeather.TargetActor.SequencePlayer:JumpToFrameTime(CurrentPlayTime)
    self.TargetWeather.TargetActor.SequencePlayer:Play()
    self.TargetWeather.TargetActor.SequencePlayer:SetPlayRate(self.NowWeather.TargetActor.SequencePlayer:GetPlayrate())

    self.NowWeather.TargetActor.SequencePlayer:Pause()
    self.NowWeather.TargetActor.SequencePlayer:Stop()
  
    --self.TargetWeather.TargetActor.SequencePlayer:Pause()
    --self.TargetWeather.TargetActor.SequencePlayer:Stop()
    if (self.NowWeather.Removed ~= nil) then
        G.log:info("[lz]","WeatherManagerActor destroy1 Sequence Actor: [%s][%s]-------", self.NowWeather.TargetActor:GetName(), self.NowWeather.TargetActor:GetSequence():GetName())
        self.NowWeather.TargetActor:K2_DestroyActor()
        self.WeatherSequenceDict[self.NowWeather.Handle] = nil
    end

    self. NowWeather = self.TargetWeather
    self.TargetWeather = nil

    self.InLerping = nil
    
    self:RefreshTargetWeather()
end

function WeatherManagerActor:AddWeather(WeatherSequence, Priority, LastTime, Type)
    local SeqHandle = SequenceHandle
    function __AddWeather(LevelSequenceActor)
        self.WeatherSequenceDict[SeqHandle].TargetActor = LevelSequenceActor
        self.WeatherSequenceDict[SeqHandle].LoadingHandle = nil
        self:RefreshTargetWeather()
    end

    self.WeatherSequenceDict[SeqHandle] = {TargetActor = nil, Handle = SeqHandle, Priority = Priority, LastTime = LastTime, Removed = nil, LoadingHandle = nil, WeatherType = Type, OnFinishing = nil}
    SequenceHandle = SequenceHandle + 1
    --G.log:info("[lz]","--------------WeatherManagerActor:AddWeather[%s][%s][%s][%s]-------", WeatherSequence, tostring(WeatherSequence), Priority, LastTime)
    --if (WeatherSequence:IsA(UE.ULevelSequence)) then
    if string.find(tostring(WeatherSequence), "LevelSequence") then
        local Actor = self:CreateSequenceActorFormLevelSequence(WeatherSequence)
        __AddWeather(Actor)
    elseif string.find(tostring(WeatherSequence), "FSoftObjectPath")or Type == WeatherManagerActor.WeatherTypeTrigger then
        local Path = nil
        Path = UE.UKismetSystemLibrary.BreakSoftObjectPath(WeatherSequence, Path)
        self.WeatherSequenceDict[SeqHandle].LoadingHandle = Loader:AsyncLoadActor(Path, __AddWeather, self)
        G.log:info("[lz]","--------------WeatherManagerActor:AddWeather FSoftObjectPath[%s]-------", Path)
    end
    --self:DebugOutputWeathers("InAddWeather")
    return SeqHandle
end

function WeatherManagerActor:RemoveWeather(SeqHandle)
    G.log:info("[lz]","--------------WeatherManagerActor:RemoveWeather[%s][%s][%s]-------", SeqHandle, self.WeatherSequenceDict[SeqHandle], type(SeqHandle))
    --self:DebugOutputWeathers("RemoveWeather")
    assert(self.WeatherSequenceDict[SeqHandle])
    if self.WeatherSequenceDict[SeqHandle] == self.TargetWeather or self.WeatherSequenceDict[SeqHandle] == self.NowWeather then
        self.WeatherSequenceDict[SeqHandle].Removed = 1
    else
        if self.WeatherSequenceDict[SeqHandle].TargetActor == nil then
            Loader:CancelAsyncLoadTask(self.WeatherSequenceDict[SeqHandle].LoadingHandle)
        else
            G.log:info("[lz]","WeatherManagerActor destroy2 Sequence Actor: [%s][%s]-------", self.WeatherSequenceDict[SeqHandle].TargetActor:GetName(), self.WeatherSequenceDict[SeqHandle].TargetActor:GetSequence():GetName())
            self.WeatherSequenceDict[SeqHandle].TargetActor:K2_DestroyActor()
        end
        self.WeatherSequenceDict[SeqHandle] = nil
    end
    self:RefreshTargetWeather()
end

return WeatherManagerActor