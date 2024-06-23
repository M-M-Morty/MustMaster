require "UnLua"
local G = require("G")

local GameAPI = require("common.game_api")
local TargetFilter = require("actors.common.TargetFilter")

local Component = require("common.component")
local ComponentBase = require("actors.common.components.time_dilation_component")
local TimeDilationComponent = Component(ComponentBase)
local decorator = TimeDilationComponent.decorator

function TimeDilationComponent:Start()
    
    self.CustomTimeDilationObjects = {}
    self.IgnoreTimeDilationObjects = {}
    self.ExcludeClass = nil

    self.TimeDilationClass = nil

    self.bWitchTime = false

    Super(TimeDilationComponent).Start(self)

    -- G.log:error("devin", "GlobalTimeDilationComponent:Start")

end

function TimeDilationComponent:SetActorTimeDilation(value)

    if self.bWitchTime then
        local world = self.actor:GetWorld()
        if world.SetPhysCustomTimeDilation then
            world:SetPhysCustomTimeDilation(value)
        end

        local TargetActors = GameAPI.GetActors(self)
        
        for index, Actor in ipairs(TargetActors) do
            local ActorClass = UE.UGameplayStatics.GetClass(Actor)
            if UE.UKismetMathLibrary.ClassIsChildOf(ActorClass, UE.AHiCharacter) and self.CampFilter:FilterActor(Actor) then
                if Actor:IsValid() then
                    Actor:SendMessage("RefreshWitchTime", value)
                    
                    local Objects = self.CustomTimeDilationObjects[Actor]

                    if Objects then
                        for index, Object in ipairs(Objects) do
                            if not Object:IsValid() then
                                table.remove(Objects, index)
                            else
                                self:RefreshTimeDilationForObject(Object, value)
                            end
                        end
                    end
                end
            end
        end
    else
        UE.UGameplayStatics.SetGlobalTimeDilation(self.actor:GetWorld(), value)
    end
end

function TimeDilationComponent:ClearTimeDilationInfo()
    Super(TimeDilationComponent).ClearTimeDilationInfo(self)

    self.ExcludeClass = nil
    self.CampFilter = nil
end

decorator.message_receiver()
function TimeDilationComponent:SetExcludeClass(ExcludeClass)
    self.ExcludeClass = ExcludeClass
end

function TimeDilationComponent:RefreshTimeDilationForObject(Object, TargetValue)
    if not self.IgnoreTimeDilationObjects[Object] then
        if Object:GetOwner() ~= Actor then
            -- if Object.GetAsset then
            --     G.log:error("lizhao", "TimeDilationComponent:RefreshTimeDilationForObject 222 %s %f %s %s", tostring(Actor), TargetValue, tostring(Object), tostring(Object:GetAsset():GetName()))
            -- end
            if Object.SetCustomTimeDilation then
                Object:SetCustomTimeDilation(TargetValue)
            elseif Object.CustomTimeDilation ~= nil then
                Object.CustomTimeDilation = TargetValue
            end
        else
            -- if Object.GetAsset then
            --     G.log:error("lizhao", "TimeDilationComponent:RefreshTimeDilationForObject 333 %s %f %s %s", tostring(Actor), TargetValue, tostring(Object), tostring(Object:GetAsset():GetName()))
            -- end
            if Object.SetForceSolo then
                Object:SetForceSolo(true)
            end
        end
    end
end

function TimeDilationComponent:RefreshTimeDilation(Actor, Object)

    local ActorClass = UE.UGameplayStatics.GetClass(Actor)
    if not UE.UKismetMathLibrary.ClassIsChildOf(ActorClass, UE.AHiCharacter) or not self.CampFilter:FilterActor(Actor) then
        return
    end

    -- if Object.GetAsset then
    --     G.log:error("lizhao", "TimeDilationComponent:RefreshTimeDilation 111 %s %s %s", tostring(Actor), tostring(Object), tostring(Object:GetAsset():GetName()))
    -- end

    local TargetValue = self.time_dilation

    Actor:SendMessage("RefreshWitchTime", TargetValue)

    self:RefreshTimeDilationForObject(Object, TargetValue)
end

decorator.message_receiver()
function TimeDilationComponent:StartWitchTime(TimeDilation, SourceActor)
    if self.bWitchTime then
        self:StopWitchTime()
    end

    self.bWitchTime = true

    self.CampFilter = TargetFilter.new(SourceActor, Enum.Enum_CalcFilterType.AllEnemy)

    if TimeDilation.TimeDilationCurve then
        self:SendMessage("SetTimeDilationByCurve", TimeDilation.TimeDilationDuration, TimeDilation.TimeDilationCurve, TimeDilation.TimeDilationDelay, TimeDilation.TimeDilationPriority)
    else
        self:SendMessage("SetTimeDilation", TimeDilation.TimeDilationDuration, TimeDilation.TimeDilationValue, TimeDilation.TimeDilationDelay, TimeDilation.TimeDilationPriority)
    end
end

decorator.message_receiver()
function TimeDilationComponent:StopWitchTime()
    if not self.bWitchTime then
        return
    end

    local world = self.actor:GetWorld()
    if world.SetPhysCustomTimeDilation then
        world:SetPhysCustomTimeDilation(1.0)
    end

    local TargetActors = GameAPI.GetActors(self)

    -- G.log:error("lizhao", "GlobalTimeDilationComponent:StopWitchTime 111 %s %s", tostring(self), tostring(self.actor:IsClient()))
        
    for index, Actor in ipairs(TargetActors) do
        local ActorClass = UE.UGameplayStatics.GetClass(Actor)
        if UE.UKismetMathLibrary.ClassIsChildOf(ActorClass, UE.AHiCharacter) and self.CampFilter:FilterActor(Actor) then
            if Actor:IsValid() then
                -- G.log:error("lizhao", "GlobalTimeDilationComponent:StopWitchTime 222 %s %s", tostring(self), tostring(self.actor:IsClient()))

                Actor:SendMessage("StopWitchTime")
                
                local Objects = self.CustomTimeDilationObjects[Actor]

                if Objects then
                    for index, Object in ipairs(Objects) do
                        if Object:IsValid() then
                            self:RefreshTimeDilationForObject(Object, 1.0)
                        end
                    end
                end
            end
        end
        self.CustomTimeDilationObjects[Actor] = nil
    end

    self.bWitchTime = false
end

function TimeDilationComponent:OnSetTimeDilationEnd()

    if self.bWitchTime then
        self:StopWitchTime()
    end

    Super(TimeDilationComponent).OnSetTimeDilationEnd(self)
end

decorator.message_receiver()
function TimeDilationComponent:AddCustomTimeDilationObject(Owner, Object)

    if Object.CustomTimeDilation == nil and not Object.SetCustomTimeDilation then
        return
    end

    -- if Object.GetAsset then
    --     G.log:error("lizhao", "TimeDilationComponent:AddCustomTimeDilationObject 111 %s %s %s", tostring(Owner), tostring(Object), tostring(Object:GetAsset():GetName()))
    -- end

    local Objects = self.CustomTimeDilationObjects[Owner]
    
    if not Objects then
        Objects = {}
        self.CustomTimeDilationObjects[Owner] = Objects
    end

    for k, v in ipairs(Objects) do
        if v == Object then
            -- if Object.GetAsset then
            --     G.log:error("lizhao", "TimeDilationComponent:AddCustomTimeDilationObject 222 %s %s %s", tostring(Owner), tostring(Object), tostring(Object:GetAsset():GetName()))
            -- end
            return false
        end
    end

    -- if Object.GetAsset then
    --     G.log:error("lizhao", "TimeDilationComponent:AddCustomTimeDilationObject 333 %s %s %s", tostring(Owner), tostring(Object), tostring(Object:GetAsset():GetName()))
    -- end

    table.insert(Objects, Object)

    if self.bWitchTime then
        self:RefreshTimeDilation(Owner, Object)
    end

    return true
end

decorator.message_receiver()
function TimeDilationComponent:RemoveCustomTimeDilationObject(Owner, Object)

    local Objects = self.CustomTimeDilationObjects[Owner]
    
    if not Objects then
        return
    end
    for index, v in ipairs(Objects) do
        if v == Object then
            table.remove(Objects, index)
            if #Objects == 0 then
                self.CustomTimeDilationObjects[Owner] = nil
            end
            return
        end
    end
end

decorator.message_receiver()
function TimeDilationComponent:IgnoreTimeDilation(Object, Ignore)
    if Ignore then
        self.IgnoreTimeDilationObjects[Object] = true
    else
        self.IgnoreTimeDilationObjects[Object] = nil
    end

    if not self.bWitchTime then
        return
    end

    if Object:GetOwner() == Actor then
        if Object.SetCustomTimeDilation then
            Object:SetCustomTimeDilation(1.0 / self.time_dilation)
        elseif Object.CustomTimeDilation ~= nil then
            Object.CustomTimeDilation = 1.0 / self.time_dilation
        end
    end
end


return TimeDilationComponent

