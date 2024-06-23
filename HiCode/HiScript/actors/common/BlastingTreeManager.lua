require "UnLua"
require"os"

local G = require("G")
local GameState = require("common.gameframework.game_state.default")
local BlastingTreeManager = Class()


local BlastingTreeStage1Dict = {}
local BlastingTreeStage2Dict = {}
local BlastingTreeStage3Dict = {}
local TickHandle = nil

function BlastingTreeManager:TryStartTick()
    if TickHandle == nil then
        TickHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({UE.UGameplayStatics.GetGameState(G.GameInstance:GetWorld()), GameState.TickInTreeBlastingMananger}, 0.01, true)
    end
end

function BlastingTreeManager:TryStopTick()
    if TickHandle ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(UE.UGameplayStatics.GetGameState(G.GameInstance:GetWorld()), TickHandle)
        TickHandle = nil
    end
end

function BlastingTreeManager:Tick()
    local tempList = {}
    local HasValue = false
    for k, v in pairs(BlastingTreeStage1Dict) do
        local ElapseTime =  utils.GetSecondsUntilNow(v.StartTime)
        if ElapseTime >= 10.0 then
            table.insert(tempList, k)
        else
            HasValue = true
        end
    end

    for k, v in ipairs(tempList) do
        BlastingTreeStage1Dict[v] = nil
        v:SetMassOverrideInKg("", 10000)
        BlastingTreeStage2Dict[v] = {StartTime = UE.UKismetMathLibrary.Now()}
    end

    tempList = {}
    for k, v in pairs(BlastingTreeStage2Dict) do
        local ElapseTime =  utils.GetSecondsUntilNow(v.StartTime)
        if ElapseTime >= 5.0 then
            table.insert(tempList, k)
        else
            HasValue = true
        end
    end
    for k, v in ipairs(tempList) do
        BlastingTreeStage2Dict[v] = nil
        v:SetSimulatePhysics(false)
        BlastingTreeStage3Dict[v] = {StartTime = UE.UKismetMathLibrary.Now()}
    end

    tempList = {}
    for k, v in pairs(BlastingTreeStage3Dict) do
        local ElapseTime =  utils.GetSecondsUntilNow(v.StartTime)
        if ElapseTime >= 3.0 then
            table.insert(tempList, k)
        else
            HasValue = true
        end
    end
    for k, v in ipairs(tempList) do
        BlastingTreeStage3Dict[v] = nil
        v:SetVisibility(false)
        v:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    end


    if HasValue == false then
        self:TryStopTick()
    end


end


function BlastingTreeManager:AddBlastingTree(Mesh)
    assert(BlastingTreeStage1Dict[Mesh] == nil)
    local Materials = Mesh:GetMaterials()
    local MaterialParams = {}
    for i = 1, Materials:Length() do
        local ParamDict = {}
        local Material = Materials:Get(i)
        local MaterialInstance = UE.UKismetMaterialLibrary.CreateDynamicMaterialInstance(0, Material)

        --local Wind_Speed_Power = Material:GetScalarParameterValue("Wind_Speed_Power")
        --ParamDict['Wind_Speed_Power'] = Wind_Speed_Power
        MaterialInstance:SetScalarParameterValue("Wind_Speed_Power", 0)
        MaterialInstance:SetScalarParameterValue("SimpleGrassWindPower", 0)
        MaterialInstance:SetScalarParameterValue("Wind_Power", 0)
        Mesh:SetMaterial(i - 1, MaterialInstance)
        --MaterialParams[i] = ParamDict
    end
    Mesh:SetMassOverrideInKg("", 100)
    BlastingTreeStage1Dict[Mesh] = {StartTime = UE.UKismetMathLibrary.Now()}
    self:TryStartTick()
end

return BlastingTreeManager