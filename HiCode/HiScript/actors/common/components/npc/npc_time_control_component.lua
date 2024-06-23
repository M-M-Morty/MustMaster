--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local NpcBaseData = require("common.data.npc_base_data").data
local NpcTimeControlData = require("common.data.npc_time_control_data").data
local TimeUtil = require("common.utils.time_utils")

---@type NpcTimeControlComponent_C
local NpcTimeControlComponent = Component(ComponentBase)

function NpcTimeControlComponent:Initialize(Initializer)
    Super(NpcTimeControlComponent).Initialize(self, Initializer)
end

function NpcTimeControlComponent:ReceiveBeginPlay()
    Super(NpcTimeControlComponent).ReceiveBeginPlay(self)
    if self:GetOwner():IsServer() then
        local GameState = UE.UGameplayStatics.GetGameState(self)
        GameState.GameTimeComponent.OnGameHourChanged:Add(self, self.HandleHourChange)

        if NpcBaseData[self:GetOwner():GetNpcId()] == nil then
            G.log:error("NpcTimeControlComponent", "ReceiveBeginPlay, error Npc ID(%s)", self:GetOwner():GetNpcId())
            return
        end
        local TimeControlId = NpcBaseData[self:GetOwner():GetNpcId()].Time_Control
        if not TimeControlId then
            return
        end

        -- 触发初始行为
        local Hour = GameState.GameTimeComponent:GetHourOfDay()
        local ActionList = self:GetStartActionList(TimeControlId, Hour)
        if ActionList then
            local Actions = UE.TArray(UE.FInt)
            for _, ActionId in ipairs(ActionList) do
                Actions:Add(ActionId)
            end
            self.EventOnChangeActions:Broadcast(Actions)
        end
    end
end

function NpcTimeControlComponent:GetStartActionList(TimeControlId, Hour)
    local CurHour = Hour
    local TimeControlData = NpcTimeControlData[TimeControlId]
    while true do
        local Key = "time_" .. CurHour
        if TimeControlData[Key] then
            return TimeControlData[Key]
        end
        CurHour = (CurHour - 1 + TimeUtil.HOURS_PER_DAY ) % TimeUtil.HOURS_PER_DAY 
        if CurHour == Hour then
            -- 24小时都没有找到actions
            break
        end
    end

    return nil
end

function NpcTimeControlComponent:HandleHourChange(CurHour)
    local TimeControlId = NpcBaseData[self:GetOwner():GetNpcId()].Time_Control
    if not TimeControlId then
        return
    end
    local TimeControlData = NpcTimeControlData[TimeControlId]
    local Key = "time_" .. CurHour
    if not TimeControlData[Key] then
        -- 当前小时没有行为指令
        return
    end

    local Actions = UE.TArray(UE.FInt)
    for _, ActionId in ipairs(TimeControlData[Key]) do
        Actions:Add(ActionId)
    end
    self.EventOnChangeActions:Broadcast(Actions)
end

return NpcTimeControlComponent
