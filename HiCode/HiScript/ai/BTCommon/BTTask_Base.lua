require "UnLua"


local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = Class()


function BTTask_Base:ReceiveExecuteAI(Controller, Pawn)
    xpcall(
        -- try
        function(...)
            Pawn:SendMessage("RegisterBTSwitchCB", self, self.OnSwitch)
            local ret = self:Execute(Controller, Pawn)
            if ret == ai_utils.BTTask_Succeeded then
                self:TaskFinish(Controller, Pawn, true)
            elseif ret == ai_utils.BTTask_Failed then
                self:TaskFinish(Controller, Pawn, false)
            end
        end, 
        -- catch
        function(err)
            err = err .. "\n" .. G.GetDisplayName(Pawn)
            err = err .. "\n" .. debug.traceback()
            UnLua.LogError(err)
            self:TaskFinish(Controller, Pawn, false)
        end
    )
end

function BTTask_Base:Execute(Controller, Pawn)
    -- override by child node
end

function BTTask_Base:ReceiveTickAI(Controller, Pawn, DeltaSeconds)
    xpcall(
        -- try
        function(...)
            if self:CanBreak(Controller, Pawn) then
                self:OnBreak(Controller, Pawn)
                self:FinishExecute(true)
                Pawn:SendMessage("SetCurBTNodeBreak", false)
                return
            end

            local ret = self:Tick(Controller, Pawn, DeltaSeconds)
            if ret == ai_utils.BTTask_Succeeded then
                self:TaskFinish(Controller, Pawn, true)
            elseif ret == ai_utils.BTTask_Failed then
                self:TaskFinish(Controller, Pawn, false)
            end
        end,
        -- catch
        function(err)
            err = err .. "\n" .. G.GetDisplayName(Pawn)
            err = err .. "\n" .. debug.traceback()
            UnLua.LogError(err)
            self:TaskFinish(Controller, Pawn, false)
        end
    )
end

function BTTask_Base:Tick(Controller, Pawn, DeltaSeconds)
    -- override by child node
end

function BTTask_Base:TaskFinish(Controller, Pawn, Succeeded)
    xpcall(
        function(...)
            self:OnFinish(Controller, Pawn, Succeeded)
            self:FinishExecute(Succeeded)
        end,
        function(err)
            err = err .. "\n" .. G.GetDisplayName(Pawn)
            err = err .. "\n" .. debug.traceback()
            UnLua.LogError(err)
            self:FinishExecute(false)
        end
    )
end

function BTTask_Base:CanBreak(Controller, Pawn)
    -- can override by child node
    return Pawn.GetAIServerComponent and Pawn:GetAIServerComponent().bCanBreakCurBTNode
end

function BTTask_Base:OnFinish(Controller, Pawn, Succeeded)
    -- 正常结束
end

function BTTask_Base:OnSwitch(Controller, Pawn)
    -- BT切换
end

function BTTask_Base:OnBreak(Controller, Pawn)
    -- 自定义中止
end


return BTTask_Base