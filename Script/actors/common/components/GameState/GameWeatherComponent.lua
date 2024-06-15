local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local GameWeatherComponent = Component(ComponentBase)

function GameWeatherComponent:GetWeather(RegionId)
    return self.GlobalWeather
end

-- server
function GameWeatherComponent:ChangeGlobalWeather(NewWeather)
    if NewWeather == self.GlobalWeather then
        G.log:warn("GameWeatherComponent:ChangeGlobalWeather", "New weather(%s) is same", NewWeather)
        return
    end
    self.GlobalWeather = NewWeather
    self.OnWeatherChanged:Broadcast(self.GlobalWeather, 0)
end

function GameWeatherComponent:OnRep_GlobalWeather()
    self.OnWeatherChanged:Broadcast(self.GlobalWeather, 0)
end

return GameWeatherComponent
