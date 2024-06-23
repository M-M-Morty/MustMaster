require "UnLua"
require"os"

local G = require("G")
local Loader = require("actors.client.AsyncLoaderManager")
local GameState = require("common.gameframework.game_state.default")
local WeatherManager = Class()

------------------------------------------------------------------------------------------------------------------------------------------------
local DefaultWeatherTemplateActor = nil
local NowWeather = nil
local TargetWeather = nil
local SequenceHandle = 1
local WeatherSequenceDict = {}
local LerpingTickHandle = nil


WeatherManager.WeatherTypeAutoDay = 1;
WeatherManager.WeatherTypeTrigger = 2;

WeatherManager.AutoDayWeatherInterpolation = 0


-- 初始 Nowweather 赋值
--有新的weather加入，找出比nowweather还高的weather，设置为targetweather，过渡过去，这期间，如果有新weather加入，则targetweather不变。
--变换为targetweather后，nowweather改为targetweather值，然后再刷新去查找是否有新的targetweather
--删除weather，如果这个weather是targetweather，则延迟删除，将tagetweather上标记为删除状态，在过渡到targetweather时马上寻找下一个weather，再过渡过去，过渡结束时删除.


function WeatherManager:CreateSequenceActorFormLevelSequence(LevelSequence)
    local SpawnParameters = UE.FActorSpawnParameters()
    local SpawnTransform = UE.FTransform.Identity
    local ExtraData = {}
    local TemplateActor = GameAPI.SpawnActor(G.GameInstance:GetWorld(), UE.ALevelSequenceActor ,SpawnTransform, SpawnParameters, ExtraData)
    TemplateActor:SetSequence(LevelSequence)
    return TemplateActor
    
end

function WeatherManager:RefreshTargetWeather()
    if TargetWeather~= nil then
        return
    end

    local NewWeatherTarget = nil
    for k, v in pairs(WeatherSequenceDict) do
        if v.Removed ==nil and v.TargetActor ~= nil and (NewWeatherTarget == nil or NewWeatherTarget.Priority < v.Priority) then
            NewWeatherTarget = v
        end
    end

    if NewWeatherTarget == nil then
        return
    end
    -- first time 
    if NowWeather == nil then
        NowWeather = NewWeatherTarget
        NowWeather.TargetActor.SequencePlayer:Play()
        G.log:info("[lz]","-----frist weather come %s--------", NowWeather.TargetActor:GetSequence():GetName())
        return
    end
    
    if NowWeather.Removed ~= nil or (NewWeatherTarget ~= NowWeather and NewWeatherTarget.Priority > NowWeather.Priority) then
        TargetWeather = NewWeatherTarget

        TargetWeather.TargetActor.PlaybackSettings.bPauseAtEnd = true
        --TargetWeather.TargetActor.SequencePlayer:JumpToSeconds(0.1)
        --TargetWeather.TargetActor.SequencePlayer:Play()

        NowWeather.TargetActor.PlaybackSettings.bPauseAtEnd = true
        --NowWeather.TargetActor.SequencePlayer:JumpToSeconds(0.1)
        --NowWeather.TargetActor.SequencePlayer:Play()

        NowWeather.StartLerpingTime = UE.UKismetMathLibrary.Now()
        G.log:info("[lz]","-----start Lerp %s----->%s--------", NowWeather.TargetActor:GetSequence():GetName(), TargetWeather.TargetActor:GetSequence():GetName())
        if (LerpingTickHandle == nil) then
            LerpingTickHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({UE.UGameplayStatics.GetGameState(G.GameInstance:GetWorld()), GameState.LerpingInWeatherMananger}, 0.01, true)
        end
    end
end

function WeatherManager:DebugOutputWeathers(Info)
    G.log:info("[lz]","-------------------------%s-----------------------------", Info)
    for k, v in pairs(WeatherSequenceDict) do
        local TargetName = nil
        if v.TargetActor then
            TargetName = v.TargetActor:GetSequence():GetName()
        end
        G.log:info("[lz]","key = [%s], Actor = [%s], Handle = [%s], Priority = [%s], Remove = [%s], LoadingHandle = [%s]", k, 
    TargetName, v.Handle, v.Priority, v.Removed, v.LoadingHandle)
    end
    G.log:info("[lz]","-------------------------%s-----------------------------", Info)
    
end


function  WeatherManager:Interpolate(FromWeather, ToWeather, Now)
    --if (FromWeather.WeatherType == WeatherManager.WeatherTypeAutoDay and ToWeather.WeatherType == WeatherManager.WeatherTypeAutoDay) then
    --    return WeatherManager.AutoDayWeatherInterpolation
    --end

    local Total = ToWeather.LastTime
    assert(Now <= Total)
    return Now / Total
end


function WeatherManager:OnLerpingToTarget()
    assert(NowWeather)
    assert(TargetWeather)
    local ElapseTime =  utils.GetSecondsUntilNow(NowWeather.StartLerpingTime)
    if  WeatherSequenceDict[NowWeather.Handle].OnFinishing == 1 then
        WeatherSequenceDict[NowWeather.Handle].OnFinishing = nil
        self:StopLerpingToTarget()
        return
    end
    if  ElapseTime >= TargetWeather.LastTime then
        NowWeather.TargetActor.SequencePlayer:LerpTo(TargetWeather.TargetActor.SequencePlayer, 1.0)
        WeatherSequenceDict[NowWeather.Handle].OnFinishing = 1
        G.log:info("[lz]"," weather change on finishing......%s--->%s", NowWeather.TargetActor:GetSequence():GetName(), TargetWeather.TargetActor:GetSequence():GetName())
    else
        local Weight = self:Interpolate(NowWeather, TargetWeather, ElapseTime)
        --G.log:info("[lz]","Weight: %s", Weight)
        
        if (Weight > 1) then
           Weight = 1
        end
        --G.log:info("[lz]","-------OnLerpingToTarget [%s] [%s][%s]--------", ElapseTime, TargetWeather.LastTime, Weight)
        --TargetWeather.TargetActor.SequencePlayer:Play()
        --NowWeather.TargetActor.SequencePlayer:JumpToSeconds(0.1)
        --TargetWeather.TargetActor.SequencePlayer:JumpToSeconds(0.1)

        --G.log:info("[lz]","-------------------------Lerp %s -----> %s weight %s----------------------------",  NowWeather.TargetActor:GetSequence():GetName(), TargetWeather.TargetActor:GetSequence():GetName(),  Weight)
        NowWeather.TargetActor.SequencePlayer:LerpTo(TargetWeather.TargetActor.SequencePlayer, Weight)
      
       
    end
end

function WeatherManager:StopLerpingToTarget()
    assert(NowWeather)
    assert(TargetWeather)
    --TargetWeather.TargetActor.SequencePlayer:JumpToSeconds(0.1)
    --TargetWeather.TargetActor.SequencePlayer:Play()

    NowWeather.TargetActor.SequencePlayer:Pause()
    NowWeather.TargetActor.SequencePlayer:Stop()


    
    TargetWeather.TargetActor.SequencePlayer:Play()
    
    --TargetWeather.TargetActor.SequencePlayer:Pause()
    --TargetWeather.TargetActor.SequencePlayer:Stop()
    if (NowWeather.Removed ~= nil) then
        G.log:info("[lz]","WeatherManager destroy1 Sequence Actor: [%s][%s]-------", NowWeather.TargetActor:GetName(), NowWeather.TargetActor:GetSequence():GetName())
        NowWeather.TargetActor:K2_DestroyActor()
        WeatherSequenceDict[NowWeather.Handle] = nil
    end

    NowWeather = TargetWeather
    TargetWeather = nil

    if LerpingTickHandle ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(UE.UGameplayStatics.GetGameState(G.GameInstance:GetWorld()), LerpingTickHandle)
        LerpingTickHandle = nil
    end
    self:RefreshTargetWeather()
end

function WeatherManager:AddWeather(WeatherSequence, Priority, LastTime, Type)
    local SeqHandle = SequenceHandle
    function __AddWeather(LevelSequenceActor)
        WeatherSequenceDict[SeqHandle].TargetActor = LevelSequenceActor
        WeatherSequenceDict[SeqHandle].LoadingHandle = nil
        self:RefreshTargetWeather()
    end

    WeatherSequenceDict[SeqHandle] = {TargetActor = nil, Handle = SeqHandle, Priority = Priority, LastTime = LastTime, Removed = nil, LoadingHandle = nil, WeatherType = Type, OnFinishing = nil}
    SequenceHandle = SequenceHandle + 1
    --G.log:info("[lz]","--------------WeatherManager:AddWeather[%s][%s]-------", WeatherSequence, tostring(WeatherSequence))
    --if (WeatherSequence:IsA(UE.ULevelSequence)) then
    if string.find(tostring(WeatherSequence), "LevelSequence") then
        local Actor = self:CreateSequenceActorFormLevelSequence(WeatherSequence)
        __AddWeather(Actor)
    elseif string.find(tostring(WeatherSequence), "FSoftObjectPath") then
        local Path = nil
        Path = UE.UKismetSystemLibrary.BreakSoftObjectPath(WeatherSequence, Path)
        WeatherSequenceDict[SeqHandle].LoadingHandle = Loader:AsyncLoadActor(Path, __AddWeather, self:GetWorld())
        G.log:info("[lz]","--------------WeatherManager:AddWeather FSoftObjectPath[%s]-------", Path)
    end
    --self:DebugOutputWeathers("InAddWeather")
    return SeqHandle
end

function WeatherManager:RemoveWeather(SeqHandle)
    G.log:info("[lz]","--------------WeatherManager:RemoveWeather[%s][%s][%s]-------", SeqHandle, WeatherSequenceDict[SeqHandle], type(SeqHandle))
    --self:DebugOutputWeathers("RemoveWeather")
    assert(WeatherSequenceDict[SeqHandle])
    if WeatherSequenceDict[SeqHandle] == TargetWeather or WeatherSequenceDict[SeqHandle] == NowWeather then
        WeatherSequenceDict[SeqHandle].Removed = 1
    else
        if WeatherSequenceDict[SeqHandle].TargetActor == nil then
            Loader:CancelAsyncLoadTask(WeatherSequenceDict[SeqHandle].LoadingHandle)
        else
            G.log:info("[lz]","WeatherManager destroy2 Sequence Actor: [%s][%s]-------", WeatherSequenceDict[SeqHandle].TargetActor:GetName(), WeatherSequenceDict[SeqHandle].TargetActor:GetSequence():GetName())
            WeatherSequenceDict[SeqHandle].TargetActor:K2_DestroyActor()
        end
        WeatherSequenceDict[SeqHandle] = nil
    end
    self:RefreshTargetWeather()
end

return WeatherManager