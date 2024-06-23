--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR PanZiBin
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local utils = require("common.utils")
local Projectile = require("actors.common.Projectile")
---@type Projectile_Likaduo_ThrowZL_C
local Projectile_ZL = Class(Projectile)

local Fre = 0.033
local HitRes = UE.FHitResult()
local DeltaZ = 400
local DeltaDisZ = 100
local DeltaDisXY = 200
local StopZ = 3900
local ParName = "Display Frame"

function Projectile_ZL:ReceiveBeginPlay()
    Super(Projectile_ZL).ReceiveBeginPlay(self)
    UE.UMeshComponent.SetCollisionEnabled(self.StaticMesh, UE.ECollisionEnabled.NoCollision)
    -- if not self:HasAuthority() then
    --     return
    -- end
    self.SetRotTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnRotUpdateFunc}, Fre, true)
    local StartRot = self.StaticMesh:K2_GetComponentRotation()
    self.StartRot = StartRot
    local Rot = UE.FRotator(StartRot.Pitch, StartRot.Yaw, self.ConstRoll) --固定效果
    self.TargetRot = Rot
    self.SetRotTimer = 0
end

function Projectile_ZL:ReceiveTick(DeltaSeconds)
    Super(Projectile_ZL).ReceiveTick(self, DeltaSeconds)

    if self:K2_GetActorLocation().Z < StopZ then
        self:OnStopMove()
    end
end

function Projectile_ZL:OnStopMove(Hit)
    if self.CanMove == false then return end
    self.CanMove = false    --停止轨迹移动
    local Comps = UE.TArray(UE.USceneComponent)
    UE.USceneComponent.GetChildrenComponents(self.RootComponent, true, Comps)

    for i = 1, Comps:Length() do   --所有组件关碰撞
        local Comp = Comps:Get(i)
        if Comp:Cast(UE.UPrimitiveComponent) then
            UE.UMeshComponent.SetCollisionEnabled(Comp, UE.ECollisionEnabled.NoCollision)
        end
    end

    self.ChangeMIDTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnMIDUpdateFunc}, Fre, true)
    self.ChangeMIDTimer = 0
    if self:HasAuthority() then
        self.SetLocTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnLocUpdateFunc}, Fre, true)
        self.StartPos = self:K2_GetActorLocation()
        self.TargetPosZ = self.ConstZ
        self.SetLocTimer = 0  
    else
        local AkEvent = self.OnLandAkAEvent
        utils.PlayAkEvent(AkEvent, false, self:K2_GetActorLocation(), self, nil)   --客户端播音效
        -- print("打印测试  Projectile_ZL:Multicast_OnCompleteLanding_RPC() 播音效", G.GetDisplayName(self),self:HasAuthority()) 

        -- Show hit effect
        if self.Spec.HitEffect and not self:HasAuthority() then
            UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(self, self.Spec.HitEffect, self:K2_GetActorLocation(), self:K2_GetActorRotation())
        end
    end
end

--修改Mesh的朝向 -> 双端
function Projectile_ZL:OnRotUpdateFunc()
    local Timer = self.SetRotTimer
    local TotalTime = self.UpdateRotTotalTime
    if Timer < TotalTime then
        Timer = math.min(Timer + Fre, TotalTime)
        local Value = Timer / TotalTime
        local Rot = UE.UKismetMathLibrary.RLerp(self.StartRot, self.TargetRot, Value, true)
        self.StaticMesh:K2_SetWorldRotation(Rot, true, HitRes, true)
        self.SetRotTimer = Timer
    elseif Timer >= TotalTime then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.SetRotTimerHandle)
    end
end

--修改着陆位置  -> 服务端
function Projectile_ZL:OnLocUpdateFunc()
    local Timer = self.SetLocTimer
    local TotalTime = self.UpdateLocTotalTime
    if Timer < TotalTime then
        Timer = math.min(Timer + Fre, TotalTime)
        local Value = Timer / TotalTime
        local Pos = self.StartPos
        Pos.Z = UE.UKismetMathLibrary.Lerp(Pos.Z,self.TargetPosZ,Value)
        self:K2_SetActorLocation(Pos, false, HitRes, false)
        self.SetLocTimer = Timer
    elseif Timer >= TotalTime then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.SetLocTimerHandle)
        self:SetUpCanTraceCollision(false)      --停止碰撞检测(碰撞检测也只在服务端跑)
    end
end

--更新材质破碎 -> 双端 双端分开处理
function Projectile_ZL:OnMIDUpdateFunc()
    local Timer = self.ChangeMIDTimer
    local TotalTime = self.UpdateChangeMIDTotalTime

    if Timer < TotalTime then
        Timer = math.min(Timer + Fre, TotalTime)
        if not self:HasAuthority() then --仅客户端表现破碎效果
            local Value = Timer / TotalTime
            Value = UE.UKismetMathLibrary.Lerp(0,300,Value)   --美术固定效果0到300
            local Mesh = self.StaticMesh
            local Materials = UE.UMeshComponent.GetMaterials(Mesh)
            for i = 0, Materials:Length() - 1 do
                local M = Materials:Get(i+1) --从1开始
                local MI = UE.UPrimitiveComponent.CreateDynamicMaterialInstance(Mesh, i, M, "None")    --从0开始
                UE.UMaterialInstanceDynamic.SetScalarParameterValue(MI,ParName,Value)
            end
        end
        self.ChangeMIDTimer = Timer
    elseif Timer >= TotalTime then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.ChangeMIDTimerHandle)
        self.DownZTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnDownZUpdateFunc}, Fre, true)
        self.DownZTimer = 0
        if self:HasAuthority() then --服务端
            UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.SetLocTimerHandle)  --这TimerHadnle只在服务端跑
            self:SetUpCanTraceCollision(false)      --再设一次,确保停止碰撞检测(先后顺序问题)
            self.StartPos = self:K2_GetActorLocation()
            self.TargetPosZ = self.StartPos.Z - self.DownZDistance            
        end
    end
end

--最后陷入地下 -> 双端分开处理
function Projectile_ZL:OnDownZUpdateFunc()
    local Timer = self.DownZTimer
    local TotalTime = self.UpdateDownZTotalTime

    if Timer < TotalTime then
        Timer = math.min(Timer + Fre, TotalTime)
        if self:HasAuthority() then --只在服务的改位置
            local Value = Timer / TotalTime
            local Pos = self.StartPos
            Pos.Z = UE.UKismetMathLibrary.Lerp(Pos.Z, self.TargetPosZ, Value)
            self:K2_SetActorLocation(Pos, false, HitRes, false)
        end
        self.DownZTimer = Timer
    elseif Timer >= TotalTime then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.DownZTimerHandle)
        self:DestroySelf()  --双端执行
    end
end

return RegisterActor(Projectile_ZL)