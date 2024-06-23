--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local WeatherManager = require("actors.client.WeatherManager")
---@class WeatherChangeTrigger
local WeatherChangeVolume = Class()

--function WeatherChangeVolume:Initialize(Initializer)
--end

--function WeatherChangeVolume:UserConstructionScript()
--end

--function WeatherChangeVolume:ReceiveBeginPlay()
--end

--function WeatherChangeVolume:ReceiveEndPlay()
--end

-- function WeatherChangeVolume:ReceiveTick(DeltaSeconds)
-- end

--function WeatherChangeVolume:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function WeatherChangeVolume:ReceiveActorBeginOverlap(OtherActor)
--end

--function WeatherChangeVolume:ReceiveActorEndOverlap(OtherActor)
--end


function WeatherChangeVolume:OnEnter()
    G.log:info("[lz]", "WeatherChangeVolume:OnEnter--- [name: %s], [last time : %s] [priority: %s][ handle:%s]", self:GetName(), self.LastTime, self.Priority, WeatherManager, self.WeatherHandle)
    self.WeatherHandle = WeatherManager:AddWeather(self.WeatherParams, self.Priority, self.LastTime, WeatherManager.WeatherTypeTrigger)
end

function WeatherChangeVolume:OnLeave()
    G.log:info("[lz]", "WeatherChangeVolume:OnLeave--- [name: %s], [lasttime : %s], [priority: %s][handle:%s]", self:GetName(), self.LastTime, self.Priority, self.WeatherHandle)
    WeatherManager:RemoveWeather(self.WeatherHandle)
end

function WeatherChangeVolume:OnLerpingToTarget()
    WeatherManager:OnLerpingToTarget()
end
return WeatherChangeVolume
