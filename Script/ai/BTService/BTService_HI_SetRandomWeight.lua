--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR panzibin
-- @DATE ${date} ${time}
--

-- local G = require("G")
---@type BTService_SetRandomWeight_C
local BTService_SetRandomWeight = Class()

-- function BTService_SetRandomWeight:ReceiveActivationAI(Controller,Pawn)
-- end

function BTService_SetRandomWeight:ReceiveSearchStartAI(Controller,Pawn)
    -- print("打印测试   BTService_SetRandomWeight:ReceiveSearchStartAI",G.GetDisplayName(Controller),G.GetDisplayName(Pawn))
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Name = self.RandomWeightName
	local RandomWeight = BB and BB:GetValueAsInt(Name)
	if not RandomWeight then return false end   --上一个值
    math.randomseed(os.time())
    local Var = math.random(self.MinVar,self.MaxVar)
    BB:SetValueAsInt(Name,Var)
    return true
end


return BTService_SetRandomWeight