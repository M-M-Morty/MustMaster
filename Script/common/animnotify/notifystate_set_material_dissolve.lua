require "UnLua"
local utils = require("common.utils")

local G = require("G")

local check_table = require("common.data.state_conflict_data")


local NotifyState_SetMaterialDissolve = Class()


function NotifyState_SetMaterialDissolve:BP_ReceivedNotifyBegin(MeshComp, TotalDuration)
    self.TotalDuration = TotalDuration
    self.Value = self.StartValue

    return true
end

function NotifyState_SetMaterialDissolve:CalcDissolveValue(DeltaTime)
    local DeltaValue = (self.EndValue - self.StartValue) * DeltaTime / self.TotalDuration
    self.Value = self.Value + DeltaValue

    -- G.log:debug("yj", "NotifyState_SetMaterialDissolve:CalcDissolveValue StartValue.%s EndValue.%s DeltaTime.%s TotalDuration.%s DeltaValue.%s Value.%s", self.StartValue, self.EndValue, DeltaTime, self.TotalDuration, DeltaValue, self.Value)
    return self.Value
end


return NotifyState_SetMaterialDissolve
