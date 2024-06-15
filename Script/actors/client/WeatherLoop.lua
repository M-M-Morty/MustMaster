--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type WeatherBase_C


require "UnLua"
local G = require("G")
local WeatherManager = require("actors.client.WeatherManager")
local WeatherLoop = Class()

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

-- function M:ReceiveBeginPlay()
-- end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end
--[[
function WeatherLoop:SetDefaultWeatherTemplate(WeatherTemplate, Prority)
   
    --G.log:info("[lz]","---------SetDefaultWeatherTemplate, AddWeather [%s][%d]-------", WeatherTemplate:GetName(), Prority)

    WeatherManager:SetWeatherActor(self)

    WeatherManager:SetDefaultWeather(WeatherTemplate, Prority)
end
]]


function WeatherLoop:AddWeather(WeatherTemplate, Prority, LastTime)
    G.log:info("[lz]","---------AddTargetWeather [%s][%d]-------", WeatherTemplate:GetName(), Prority)
    return WeatherManager:AddWeather(WeatherTemplate, Prority, LastTime, WeatherManager.WeatherTypeAutoDay)
end

function  WeatherLoop:RemoveWeather(Handle)
    WeatherManager:RemoveWeather(Handle)
end


function WeatherLoop:ReceiveTick(DeltaSeconds)
    if UE.UKismetSystemLibrary.IsDedicatedServer(self) then
        return
    end
    if self.WeatherTable == nil then
        return;
    end
    if self.bInit ~= true then
        return 
    end
    local TimePassed = self:GetWorld():GetTimeSeconds() - self.StartTimeInSeconds
    local StartMoment = nil;
    local EndMoment = nil;
    local Interpolation = 0;
    StartMoment, EndMoment, Interpolation = self.WeatherTable:GetMomentsAccordingGameTime(TimePassed);
   
    --WeatherManager.AutoDayWeatherInterpolation = Interpolation
    if StartMoment.MomentName == self.NowWeatherMoment.MomentName and EndMoment.MomentName == self.ToWeatherMoment.MomentName then
        --
    else
        if (self.NowWeatherMoment.MomentTime == UE.EWeatherMomentTime.UnknowMoment) then
            G.log:info("[lz]","---------ReceiveTick [%s][%s]-------", StartMoment.MomentTime, self.WeatherType)

            local LevelSequenceStart = self.WeatherTable:GetWeatherTypeSequence(StartMoment, self.WeatherType)
            self.NowWeatherHandle = self:AddWeather(LevelSequenceStart, 0, 3)
            self.ToWeatherHandle = -1
        
        else
            assert(StartMoment.MomentName  == self.ToWeatherMoment.MomentName)
            self.NowWeatherHandle = self.ToWeatherHandle
            self.ToWeatherHandle = -1
            
        end

        self.ToWeatherMoment = EndMoment
        self.NowWeatherMoment = StartMoment

    end
    --G.log:info("[lzlz]","GetMomentsAccordingGameTime %s -->%s, %s, %s", StartMoment.MomentName, EndMoment.MomentName, Interpolation, self.ToWeatherHandle)
    if Interpolation > 0.8  and self.ToWeatherHandle < 0 then -- change
        G.log:info("[lz]","---------will change [%s]-->[%s]-------", StartMoment.MomentName,EndMoment.MomentName)
        local LevelSequence = self.WeatherTable:GetWeatherTypeSequence(EndMoment, self.WeatherType)
        self.ToWeatherHandle = self:AddWeather(LevelSequence, 0, 3)
        self:RemoveWeather(self.NowWeatherHandle)
        self.NowWeatherHandle = nil
    end

end



return WeatherLoop
