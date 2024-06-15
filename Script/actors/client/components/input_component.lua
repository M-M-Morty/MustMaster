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

function InputComponent:ReceiveBeginPlay()
    Super(InputComponent).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("InputComponent(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
end

function InputComponent:Start()
    Super(InputComponent).Start(self)

    self.TargetWalkMode = UE.EMovementMode.MOVE_Walking

    self.InputLayer_Move = {InputModes.Dodge, InputModes.Climb, InputModes.Normal, InputModes.Skill}
    self.InputLayer_Attack = {InputModes.AreaAbilityUse, InputModes.AreaAbility, InputModes.Maduke, InputModes.SplineBuilder, InputModes.NormalBuilder, InputModes.Skill}
    self.InputLayer_Aim = {InputModes.AreaAbilityUse, InputModes.AreaAbility, InputModes.SplineBuilder, InputModes.NormalBuilder, InputModes.Skill}
    self.InputLayer_Sprint = {InputModes.AreaAbilityUse, InputModes.AreaAbility, InputModes.Climb, InputModes.Dodge, InputModes.Ride}
    self.InputModes = {}
end

function InputComponent:ForwardMovementAction(value)
    -- G.log:debug("lizhao", "InputComponent:ForwardMovementAction %s", tostring(value))
    if math.abs(value) > G.EPS then
        self:SendMessage("MoveForward", value)
    else
        self:SendMessage("MoveForward_Released", value)
    end

    for k, MovementType in pairs(self.InputLayer_Move) do
        local InputHandler = self.InputModes[MovementType]
        if InputHandler then
            InputHandler["MoveForward"](InputHandler, value)
        end
    end
end

function InputComponent:RightMovementAction(value)
    if math.abs(value) > G.EPS then
        self:SendMessage("MoveRight", value)
    else
        self:SendMessage("MoveRight_Released", value)
    end

    for k, MovementType in pairs(self.InputLayer_Move) do
        local InputHandler = self.InputModes[MovementType]
        if InputHandler then
            InputHandler["MoveRight"](InputHandler, value)
        end
    end
end

decorator.message_receiver()
function InputComponent:RegisterInputHandler(MovementType, handler)
    G.log:debug(self.__TAG__, "RegisterInputHandler MovementType: %s", MovementType)
    self.InputModes[MovementType] = handler
end

decorator.message_receiver()
function InputComponent:UnRegisterInputHandler(MovementType)
    G.log:debug(self.__TAG__, "UnRegisterInputHandler MovementType: %s", MovementType)
    self.InputModes[MovementType] = nil
end

function InputComponent:AttackAction(value)
    self:SendMessage("Attack", value)
    for k, AttackType in pairs(self.InputLayer_Attack) do
        if not (self.actor.Vehicle and AttackType ~= InputModes.Ride) then
            local InputHandler = self.InputModes[AttackType]
            if InputHandler then
                local AttackAction = InputHandler["Attack"]
                --G.log:debug("hycoldrain", "InputComponent:AttackAction....%s. %s", tostring(AttackAction), AttackType)
                if AttackAction then 
                    AttackAction(InputHandler, value)                        
                end
                break -- todo priority & block
            end
        end
    end 
end

decorator.message_receiver()
function InputComponent:Kick_Pressed()
    self:SendMessage("Kick")
end

decorator.message_receiver()
function InputComponent:Rush_Pressed()
    self:SendMessage("Rush")
end

decorator.message_receiver()
function InputComponent:Dodge_Pressed()
    self:SendMessage("Dodge")
end

-- Move To Controller Input Component
-- decorator.engine_callback()
-- function InputComponent:LockAttack_Pressed()
--     self:SendMessage("LockAttack", true)
--     self.actor:SendControllerMessage("LockAttack", true)
-- end

-- decorator.engine_callback()
-- function InputComponent:LockAttack_Released()
--     self:SendMessage("LockAttack", false)
-- end

-- decorator.engine_callback()
-- function InputComponent:CycleOverlayUp_Pressed()
--     G.log:debug("yj", "CycleOverlayUp_Pressed")
--     self:SendMessage("MouseWheelUp")
--     self.actor:SendControllerMessage("MouseWheelUp")
-- end

-- decorator.engine_callback()
-- function InputComponent:CycleOverlayDown_Pressed()
--     G.log:debug("yj", "CycleOverlayDown_Pressed")
--     self:SendMessage("MouseWheelDown")
--     self.actor:SendControllerMessage("MouseWheelDown")
-- end

decorator.message_receiver()
function InputComponent:SwitchFight_Pressed()
    self:SendMessage("SwitchFightStance")
end

function InputComponent:GetInVehicleAction(InJump)
    self:SendMessage("GetInVehicleAction", InJump)
end

function InputComponent:AimAction(value)
    if self.actor.Vehicle == nil then
        self:SendMessage("Block", value)
    end
    
    for _, AimType in pairs(self.InputLayer_Aim) do
        if not (self.actor.Vehicle and AimType ~= InputModes.Ride) then
            local InputHandler = self.InputModes[AimType]
            if InputHandler then
                local AimAction = InputHandler["Aim"]
                --G.log:debug("hycoldrain", "InputComponent:AimAction....%s.", tostring(AimAction))
                if AimAction then
                    AimAction(InputHandler, value)
                end
                break -- todo priority & block
            end
        end
    end 
end

function InputComponent:CameraUpAction(value)
    self.actor.Overridden.CameraUpAction(self.actor, value)
    self:SendMessage("OnCameraUpAction", value)
end

function InputComponent:CameraRightAction(value)
    self.actor.Overridden.CameraRightAction(self.actor, value)
    self:SendMessage("OnCameraRightAction", value)
end

function InputComponent:CameraScaleAction(value)
    self.actor.Overridden.CameraScaleAction(self.actor, value)
    self:SendMessage("OnCameraScaleAction", value)
end

decorator.message_receiver()
function InputComponent:SprintAction(value)
    for k, SprintType in pairs(self.InputLayer_Sprint) do
        if not (self.actor.Vehicle and SprintType ~= InputModes.Ride) then
            local InputHandler = self.InputModes[SprintType]
            if InputHandler then
                local SprintAction = InputHandler["SprintAction"]
                if SprintAction and SprintAction(InputHandler, value)  then
                    return
                end
            end
        end
    end 
end

-- 角色成为前台 Player 之后，启用 input
decorator.message_receiver()
function InputComponent:OnClientPlayerReady()
    utils.SetPlayerInputEnabled(self.actor:GetWorld(), true)
end

function InputComponent:WalkAction()
    self.actor.Overridden.WalkAction(self.actor)
end

function InputComponent:ChargeAction(Value)
    self:SendMessage("ChargeAction")
end

return InputComponent
