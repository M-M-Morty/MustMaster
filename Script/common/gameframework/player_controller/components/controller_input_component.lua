require "UnLua"

local G = require("G")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")

local check_table = require("common.data.state_conflict_data")

local InputModes = require("common.event_const").InputModes

local InputComponent = Component(ComponentBase)

local decorator = InputComponent.decorator


function InputComponent:Initialize(...)
    Super(InputComponent).Initialize(self, ...)
end

function InputComponent:Start()
    Super(InputComponent).Start(self)
end

-- decorator.engine_callback()
-- function InputComponent:Attack_Pressed()
--     self.actor:SendPlayerMessage("Attack", true)
-- end

-- decorator.engine_callback()
-- function InputComponent:Attack_Released()
--     self.actor:SendPlayerMessage("Attack", false)
-- end

-- decorator.engine_callback()
-- function InputComponent:Kick_Pressed()
--     self.actor:SendPlayerMessage("Kick")
-- end

-- decorator.engine_callback()
-- function InputComponent:Rush_Pressed()
--     self.actor:SendPlayerMessage("Rush")
-- end

-- decorator.engine_callback()
-- function InputComponent:Dodge_Pressed()
--     self.actor:SendPlayerMessage("Dodge")
-- end

decorator.engine_callback()
function InputComponent:LockAttack_Pressed()
    -- self:SendMessage("LockAttack", true)
    -- self.actor:SendPlayerMessage("LockAttack", true)
    self:SendMessage("Tab_Pressed", true)
end

decorator.engine_callback()
function InputComponent:LockAttack_Released()
    -- self:SendMessage("LockAttack", false)
    -- self.actor:SendPlayerMessage("LockAttack", false)
end

decorator.engine_callback()
function InputComponent:CycleOverlayUp_Pressed()
    self:SendMessage("MouseWheelUp")
end

decorator.engine_callback()
function InputComponent:CycleOverlayDown_Pressed()
    self:SendMessage("MouseWheelDown")
end

decorator.engine_callback()
function InputComponent:SecondarySkillAction(Value)
    local Flag = UE.UEnhancedInputLibrary.Conv_InputActionValueToBool(Value)
    if Flag then
        self.actor:SendPlayerMessage("SecondarySkill", Value)
    end
end

decorator.engine_callback()
function InputComponent:SuperSkillAction(Value)
    local Flag = UE.UEnhancedInputLibrary.Conv_InputActionValueToBool(Value)
    if Flag then
        self.actor:SendPlayerMessage("SuperSkill")
    end
end

decorator.engine_callback()
function InputComponent:AssistSkillAction(Value)
    local Flag = UE.UEnhancedInputLibrary.Conv_InputActionValueToBool(Value)
    if Flag then
        --self.actor:SendPlayerMessage("AssistSkill")
        --走使用道具流程
        self.actor:K2_GetPawn().PlayerState:SendClientMessage("UseAssistItem")
    end
end

-- decorator.engine_callback()
-- function InputComponent:Jump_Pressed()
--     self.actor:SendPlayerMessage("Jump", true)
-- end

-- decorator.engine_callback()
-- function InputComponent:Jump_Released()
--     self.actor:SendPlayerMessage("Jump", false)
-- end

-- decorator.engine_callback()
-- function InputComponent:SwitchFight_Pressed()
--     self.actor:SendPlayerMessage("SwitchFightStance")
-- end

return InputComponent
