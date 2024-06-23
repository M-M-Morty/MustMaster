﻿---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by yongzyzhang.
--- DateTime: 2024/6/13 下午3:34
---

local G = require("G")
local Actor = require("common.actor")

local SubsystemUtils = require("common.utils.subsystem_utils")
local utils = require("common.utils")
local EdUtils = require("common.utils.ed_utils")
local BPConst = require("common.const.blueprint_const")
local GlobalActorConst = require("common.const.global_actor_const")
local MSConfig = require("micro_service.ms_config")
local OfficeEnums = require("office.OfficeEnums")

---@class OfficeDecorationGroupActor : Actor
local OfficeDecorationGroupActor = Class(Actor)

function OfficeDecorationGroupActor:K2_PreInitializeComponents()
    if self:IsClient() then
        local ActorName = UE.UKismetSystemLibrary.GetObjectName(self)
        local StarIndex,_, _ = string.find(ActorName, "_SpawnIndex_")
        if StarIndex then
            self.ActorID = string.sub(ActorName, 1, StarIndex - 1)
        else
            self.ActorID = ActorName
        end
        local DecorationComponentClass = UE.UClass.Load(BPConst.OfficeDecorationComponent)
        
        --- 此组家具子Actor和其对应的DecorationComponent
        ---@type table<Actor, OfficeDecorationComponent>
        self.FurnitureActorDecorationComponentTable = {}
        self.ChildActorPrepareDecorationCount = 0
        
        local ChildActorComponents = self:K2_GetComponentsByClass(UE.UChildActorComponent)
        self.FurnitureGroupActorNum = ChildActorComponents:Num()
        
        for Index, ChildActorComponent in ipairs(ChildActorComponents:ToTable()) do
            assert(ChildActorComponent.ChildActor ~= nil, "child actor is nil")
            local DecorationComponent = ChildActorComponent.ChildActor:GetComponentByClass(DecorationComponentClass)
            if not DecorationComponent then
                DecorationComponent = ChildActorComponent.ChildActor:AddComponentByClass(DecorationComponentClass, false, UE.FTransform.Identity, true)
                DecorationComponent:SetFurnitureGroup(self)
                DecorationComponent:SetActorID(self.ActorID)
                ChildActorComponent.ChildActor:FinishAddComponent(DecorationComponent, false, UE.FTransform.Identity)
            else
                DecorationComponent:SetFurnitureGroup(self)
                DecorationComponent:SetActorID(self.ActorID)
            end

            --local ActorName = UE.UKismetSystemLibrary.GetObjectName(ChildActorComponent.ChildActor)
            self.FurnitureActorDecorationComponentTable[ChildActorComponent.ChildActor] = DecorationComponent
        end
    end
end

function OfficeDecorationGroupActor:ReceiveBeginPlay()
    Super(OfficeDecorationGroupActor).ReceiveBeginPlay(self)
    
    if self:IsClient() then
        --self:InitializeChildActor()
        local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(self)
        if OfficeSubsystem then
            self.DefaultDecorationInfo = OfficeSubsystem:GetFurnitureDefaultDecorationInfo(self)
            self.CurrentModelID = self.DefaultDecorationInfo.BasicModelKey

            OfficeSubsystem:OnOfficeDecorationActorBeginPlay(self.ActorID, self.DefaultDecorationInfo)
            OfficeSubsystem:RegisterClientActorDecoratedEvent(self.ActorID, self, self.OnGroupDecorated)
        end
        local ObjectRegistryWorldSubsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(self, UE.UObjectRegistryWorldSubsystem)
        if ObjectRegistryWorldSubsystem ~= nil then
            ObjectRegistryWorldSubsystem:RegisterObject(self.ActorID, self)
        end
    end
end

function OfficeDecorationGroupActor:ReceiveEndPlay()
    Super(OfficeDecorationGroupActor).ReceiveEndPlay(self)

    ---@type OfficeSubsystem
    local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(self)
    if OfficeSubsystem and self:IsClient() then
        OfficeSubsystem:OnOfficeDecorationActorEndPlay(self.ActorID)
        OfficeSubsystem:UnRegisterClientActorDecoratedEvent(self.ActorID, self, self.OnGroupDecorated)
    end
    local ObjectRegistryWorldSubsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(self, UE.UObjectRegistryWorldSubsystem)
    if ObjectRegistryWorldSubsystem ~= nil then
        ObjectRegistryWorldSubsystem:UnregisterObject(self.ActorID)
    end
end

function OfficeDecorationGroupActor:OnChildActorPrepared()
    self.ChildActorPrepareDecorationCount = self.ChildActorPrepareDecorationCount + 1
    if self:IsAllChildActorPrepared() and self.CachedGroupDecoratedEvent then
        self:OnGroupDecorated(table.unpack(self.CachedGroupDecoratedEvent))
    end
end

function OfficeDecorationGroupActor:IsAllChildActorPrepared()
    return self.ChildActorPrepareDecorationCount == self.FurnitureGroupActorNum
end

function OfficeDecorationGroupActor:OnGroupDecorated(DecorationInfo, EventParam)
    if self:IsServer() then
        return
    end
    
    if DecorationInfo.ActorID ~= self.ActorID then
        return
    end

    --拆除了
    if DecorationInfo.bRemoved then
        G.log:info("yongzyzhang", "OfficeDecorationComponent destroy ActorID:%s", self.ActorID)
        self:K2_DestroyActor()
        return
    end

    -- 部分Actor未准备好
    if not self:IsAllChildActorPrepared() then
        self.CachedGroupDecoratedEvent = {DecorationInfo, EventParam}
        return
    end

    ---@type OfficeSubsystem
    local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(self)

    if DecorationInfo.SkinKey and DecorationInfo.SkinKey ~= "" then
        self.CurrentModelID = DecorationInfo.SkinKey
    else
        self.CurrentModelID = self.DefaultDecorationInfo.BasicModelKey
    end
    local SkinDTConfig = OfficeSubsystem:GetOfficeDataTableRow(self.CurrentModelID)
    assert(SkinDTConfig ~= nil, "SkinDTConfig is nil, CurrentModelID:" .. tostring(self.CurrentModelID))
    
    ---@type OfficeManager
    local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager, self)
    --local OfficeManager = SubsystemUtils.GetGlobalActorSubsystem(self):GetGlobalActorByName(GlobalActorConst.OfficeManager)

    -- 更换了蓝图
    if SkinDTConfig and self:IsModelBPChanged(SkinDTConfig) then
        OfficeManager:DestroyAndRespawnNewModelActor(self, DecorationInfo, EventParam)
        return
    end
    for ChildActor, ChildActorDecorationComp in pairs(self.FurnitureActorDecorationComponentTable) do
        ChildActorDecorationComp:OnFurnitureGroupDecorated(DecorationInfo, SkinDTConfig, EventParam)
    end
end

function OfficeDecorationGroupActor:IsModelBPChanged(SkinDTConfig)
    local PathName = tostring(UE.UKismetSystemLibrary.GetPathName(self:GetClass()))
    -- 去掉_C
    PathName = PathName:sub(1,-3)

    --更换了蓝图，需要销毁重新创建
    if SkinDTConfig and SkinDTConfig.BP and tostring(SkinDTConfig.BP) ~= PathName then
        return true
    end
    return false
end

function OfficeDecorationGroupActor:GetFurnitureGroupDefaultColors()
    if self.FurnitureGroupDefaultColors then
        return self.FurnitureGroupDefaultColors
    end
    ---@type OfficeSubsystem
    local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(self)
    local FurnitureGroupDTConfig = OfficeSubsystem:GetOfficeDataTableRow(self.CurrentModelID)
    assert(FurnitureGroupDTConfig ~= nil, "FurnitureGroupDTConfig is nil, CurrentModelID:" .. tostring(self.CurrentModelID))
    
    local ConfigComponentCount = 0
    local FurnitureGroupDefaultColors = {}
    for SubBP, SubConfig in pairs(FurnitureGroupDTConfig.ChildModelBPMap:ToTable()) do
        local SubBPClassName = tostring(SubBP) .. "_C"
        local SubModelBPClass = UE.UClass.Load(SubBPClassName)

        local SubMaterialCompColors
        if SubConfig.Material then
            SubMaterialCompColors = OfficeSubsystem:GetMaterialDefaultColors(tostring(SubConfig.Material))
        else
            for ChildActor, ChildActorDecorationComp in pairs(self.FurnitureActorDecorationComponentTable) do
                if ChildActor:IsA(SubModelBPClass) then
                    SubMaterialCompColors = ChildActorDecorationComp:GetOriginDefaultColors()
                    break
                end
            end
        end
        local SubModelCompIndex = 1
        for _, ComponentIndex in pairs(SubConfig.ComponentMasks:ToTable()) do
            FurnitureGroupDefaultColors[ComponentIndex] = SubMaterialCompColors[SubModelCompIndex]
            SubModelCompIndex = SubModelCompIndex + 1
            ConfigComponentCount = ConfigComponentCount + 1
        end
    end
    assert(ConfigComponentCount == #FurnitureGroupDefaultColors, "component config is not continue")
    self.FurnitureGroupDefaultColors = FurnitureGroupDefaultColors
    return self.FurnitureGroupDefaultColors
end

return OfficeDecorationGroupActor