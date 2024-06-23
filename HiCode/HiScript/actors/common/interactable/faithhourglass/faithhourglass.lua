--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/04/19
--

---@type BP_FaithHourGlass_C
local G = require("G")
local EdUtils = require("common.utils.ed_utils")
local os = require("os")
local math = require("math")
local table = require("table")

require "UnLua"
local ActorBase = require("actors.common.interactable.base.base_item")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
    self.faithclockcount = nil
    self.faithclocksActors = nil
    self.is_finished = false
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
end

function M:InitFaithClockActors()
    if not self:IsClient() and not UE.UKismetSystemLibrary.IsStandalone(self) then
        return
    end
    if self.faithclockcount == nil then
        if self.JsonObject then
            local MutableActorSubSystem = self:GetMutableActorSubSystem()
            local sourcepath = UE.UHiEdRuntime.GetStringField(self.JsonObject, "sourcepath")
            local JsonArray = UE.UHiEdRuntime.FindFilesRecursive(MutableActorSubSystem.data_root .. sourcepath , "*.json", true, false)
            self.faithclockcount = 0
            for Ind = 1, JsonArray:Length() do
                local JsonFile = JsonArray:Get(Ind)
                local editor_id = EdUtils:GetEditorID(JsonFile)
                if not MutableActorSubSystem:ContainsInJsonObjectWrapperDatas(editor_id) then
                    MutableActorSubSystem:LoadFileToJsonWrapper(editor_id, JsonFile)
                end
                local JsonWrapper = MutableActorSubSystem:GetJsonObjectWrapper(editor_id)
                local Source = UE.UHiEdRuntime.GetStringField(JsonWrapper, "source")
                if EdUtils:IsFaithClock(Source) then
                    self.faithclockcount = self.faithclockcount + 1
                end
            end
        end
    end

    if self.faithclocksActors == nil then
        local overlapActors = UE.TArray(UE.AActor)
        self.Box:GetOverlappingActors(overlapActors)
        --G.log:debug("zsf", "InitFaithClockActors %s %s %s %s %s", overlapActors:Length(), self.faithclockcount, self:IsServer(), self.faithclockcount == overlapActors:Length(), self.Box)
        self.faithclocksActors = {}
        local cnt = 0
        for ind = 1, overlapActors:Length() do
            local actor = overlapActors[ind]
            if actor.IsFaithClock and actor:IsFaithClock() then
                --G.log:debug("zsf", "OnBeginOverlap_Sphere %s %s", actor:GetDisplayName(), ind)
                local JsonData = EdUtils:GetJsonData(self, actor)
                local index = UE.UHiEdRuntime.GetNumberField(JsonData, "id")
                table.insert(self.faithclocksActors, {index, actor:GetEditorID()})
                cnt = cnt + 1
            end
        end
        if cnt ~= self.faithclockcount then
            self.faithclocksActors = nil
        end

        if self.faithclocksActors ~= nil then
            local function cmp(elm1, elm2)
                return elm1[1] < elm2[1]
            end
            table.sort(self.faithclocksActors, cmp)
        end
    end
end

function M:CheckOK(TextMy, TextClock, ClockActor, index)
    local location_my = self:K2_GetActorLocation()
    local location_clock = ClockActor:K2_GetActorLocation()
    local clock_v = location_clock - location_my
    clock_v = UE.UKismetMathLibrary.Normal(clock_v)
    local clock_forward = self:GetActorForwardVector()
    clock_forward = UE.UKismetMathLibrary.Normal(clock_forward)
    local CosDeltaF = UE.UKismetMathLibrary.Dot_VectorVector(clock_v, clock_forward)
    local DegreesDeltaF = UE.UKismetMathLibrary.DegACos(CosDeltaF)
    local clock_right = self:GetActorRightVector()
    local CosDeltaR = UE.UKismetMathLibrary.Dot_VectorVector(clock_v, clock_right)
    local DegreesDeltaR = UE.UKismetMathLibrary.DegACos(CosDeltaR)
    clock_right = UE.UKismetMathLibrary.Normal(clock_right)
    local location_text_my = TextMy:K2_GetComponentLocation()
    local location_text_clock = TextClock:K2_GetComponentLocation()
    local Rotator = ClockActor:K2_GetActorRotation()
    local ClockYaw = Rotator.Yaw
    local dir = "up"
    local ret = true
    if DegreesDeltaF < 50 and DegreesDeltaF >= 0 then -- 前
        dir = "up"
        ret = math.abs(ClockYaw - 90) < 1.0
    elseif DegreesDeltaF < 180 and DegreesDeltaF >= 150 then -- 后
        dir = "down"
        ret = math.abs(ClockYaw - 90) < 1.0
    elseif DegreesDeltaR < 50 and DegreesDeltaR >= 0 then -- 左
        dir = "left"
        ret = math.abs(ClockYaw - 90) < 1.0
    else -- 右
        dir = "right"
        ret = math.abs(ClockYaw - 90) < 1.0
    end
    --G.log:debug("zsf", "CheckOk %s %s %s %s %s %s %s %s %s", G.GetDisplayName(ClockActor), TextMy, TextClock, DegreesDeltaF, DegreesDeltaR, index, clock_v, dir, ClockYaw)
    return ret
end

function M:SetFinish()
    G.log:debug("zsf", "[faithhourglass] SetFinish")
    self:LogicComplete()
end

function M:MissionComplete(sData)
   self:CallEvent_MissionComplete(sData)
end

function M:ReceiveTick(DeltaSeconds)
    if self.is_finished then
        if not self:IsServer() and not UE.UKismetSystemLibrary.IsStandalone(self) then
            return
        end
        if self.OldLocation == nil then
            return
        end
        return
    end
    self:InitFaithClockActors()
    if self.faithclocksActors == nil then
        return
    end
    local isOk = true
    for i=1,4 do
       local name= "Text"..tostring(i)
        for k=1,#self.faithclocksActors do
            local clockActor = self:GetEditorActor(self.faithclocksActors[k][2])
            if clockActor then
                local ret = self:CheckOK(self[name], clockActor[name], clockActor, i)
                if not ret then
                    isOk = false
                    break
                end
            end
        end
        if not isOk then
            break
        end
    end
    if isOk then
        self.is_finished = true
        self:SetFinish()
    end
end

return M
