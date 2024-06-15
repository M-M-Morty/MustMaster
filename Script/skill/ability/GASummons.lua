--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local GAPlayerBase = require("skill.ability.GAPlayerBase")

---@type GA_Summons_C
local GASummons = Class(GAPlayerBase)

local SpawnOffsetZ = 500
-- 第一版出生位置计算废弃
-- function GASummons:HandleActivateAbility()
--     G.log:info(self.__TAG__, "GASummons", "trigger")
--     Super(GASummons).HandleActivateAbility(self)
--     local Actor = self.OwnerActor
--     if Actor:IsServer() then
--         local ActorPosition = Actor:K2_GetActorLocation()
--         local ActorForward = Actor:GetActorForwardVector()
--         G.log:info(self.__TAG__, "GASummons Actor forward x:%s y:%s z:%s, dis: %s  %s", ActorForward.X, ActorForward.Y, ActorForward.Z, self.LocationOffset, Actor:GetName())
--         local Position = ActorPosition + ActorForward * self.LocationOffset

--         local CameraYaw = Actor:GetControlRotation().Yaw
--         local Rotator = UE.FRotator(0, CameraYaw, 0)
--         G.log:info(self.__TAG__, "GASummons Forward x:%s y:%s z:%s, dis: %s", Rotator:GetForwardVector().X, Rotator:GetForwardVector().Y, Rotator:GetForwardVector().Z, self.ForwardLength)
--         local SummonsPosition = Position  + Rotator:GetForwardVector() * self.ForwardLength
--         SummonsPosition = SummonsPosition + Rotator:GetForwardVector():RotateAngleAxis(90, UE.FVector(0, 0, 1)) * self.RightLength
--         local HitResult = UE.FHitResult()
--         local ActorsToIgnore = UE.TArray(UE.AActor)

--         local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
--         ObjectTypes:Add(UE.EObjectTypeQuery.WorldStatic)
--         ObjectTypes:Add(UE.EObjectTypeQuery.Destructible)

--         -- 在主角和期望点中间找一个不撞墙的点
--         local ReturnValue = UE.UKismetSystemLibrary.LineTraceSingleForObjects(self:GetWorld(), ActorPosition, SummonsPosition, ObjectTypes, false, ActorsToIgnore, UE.EDrawDebugTrace.None, HitResult, true)
--         if ReturnValue then
--             G.log:info(self.__TAG__, "actor has block by static mesh")
--             local HitPosition = UE.FVector(HitResult.Location.X, HitResult.Location.Y, 0)
--             ActorPosition.Z= 0
--             local Direction = UE.UKismetMathLibrary.GetDirectionUnitVector(HitPosition, ActorPosition) * self.CollisionRadius
--             SummonsPosition = UE.FVector(HitResult.Location.X, HitResult.Location.Y, HitResult.Location.Z) + Direction
--         end

--         --- 寻找召唤物落脚点
--         local OffsetVector = UE.FVector(0, 0, 1000)
--         G.log:info(self.__TAG__, "GASummons SummonsPosition x:%s y:%s z:%s", SummonsPosition.X, SummonsPosition.Y, SummonsPosition.Z)
--         ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
--         --ObjectTypes:Add(UE.EObjectTypeQuery.WorldDynamic)
--         ObjectTypes:Add(UE.EObjectTypeQuery.WorldStatic)
--         ObjectTypes:Add(UE.EObjectTypeQuery.Destructible)
--         ObjectTypes:Add(UE.EObjectTypeQuery.PhysicsBody)
--         ObjectTypes:Add(UE.EObjectTypeQuery.Destructible)
--         ObjectTypes:Add(UE.EObjectTypeQuery.WorldDynamic)
--         local ReturnValue = UE.UKismetSystemLibrary.LineTraceSingleForObjects(self:GetWorld(), SummonsPosition + OffsetVector, SummonsPosition - OffsetVector, ObjectTypes, true, ActorsToIgnore, UE.EDrawDebugTrace.None, HitResult, true)
--         if ReturnValue then
--             SummonsPosition.Z = HitResult.Location.Z + SpawnOffsetZ
--             local Transform = UE.UKismetMathLibrary.MakeTransform(SummonsPosition, UE.FRotator(0, 0, 0), UE.FVector(1, 1, 1))
--             local SummonsActor = GameAPI.SpawnActor(Actor:GetWorld(), self.ActorClass, Transform, UE.FActorSpawnParameters(), {})

--             G.log:info(self.__TAG__, "spawn entity: %s", G.GetObjectName(SummonsActor))
--         else
--             G.log:info(self.__TAG__, "spawn failed: not point")
--         end
--     end
--     self:K2_EndAbility()
-- end

-- 基于技能释放目标的位置来计算召唤物出生位置
function GASummons:HandleActivateAbility()
    Super(GASummons).HandleActivateAbility(self)
    
    --local Tag = UE.UHiGASLibrary.RequestGameplayTag("Ability.Buff.AssistSkill")
    -- 先召唤一个假怪谈怪来做纯客户端的表现
    -- local SkillTarget, _, _, SkillTargetComponent = self:GetSkillTarget()
    -- local Actor = self.OwnerActor
    -- local ASC = Actor.AbilitySystemComponent
    -- utils.RemoveGameplayTags(Actor, {"Ability.Buff.AssistSkill"})
    -- local SpawnTransform = UE.UKismetMathLibrary.MakeTransform(self.LocalTrans.Translation + Actor:GetCameraLocation(),
    --     UE.FRotator(self.LocalTrans.Rotation), self.LocalTrans.Scale3D)
    -- local FakeActor = GameAPI.SpawnActor(Actor:GetWorld(), self.FakeActorClass, SpawnTransform,
    --     UE.FActorSpawnParameters(), {
    --         BindTransform = self.LocalTrans
    --     })
    -- FakeActor.OwnerName = G.GetObjectName(Actor)
    -- local SkillTarget, _, _, SkillTargetComponent = self:GetSkillTarget()
    -- if SkillTarget then
    --     G.log:info(self.__TAG__, "[assist skill] get skill target success %s", G.GetObjectName(SkillTarget))
    -- else
    --     G.log:info(self.__TAG__, "[assist skill] get skill target failed")
    -- end
    -- -- local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(FakeActor.Mesh, self.SpawnAnim, 1.0)
    -- local AnimInstance = FakeActor.Mesh:GetAnimInstance()
    -- if AnimInstance then
    --     AnimInstance.OnMontageEnded:Add(self.OwnerActor, function(AnimMontage, bInterrupted)
    --         self.OnFakeAssistEnd(self, FakeActor, SkillTarget, SkillTargetComponent)
    --     end)
    --     AnimInstance:Montage_Play(self.SpawnAnim)
    -- end

    -- -- PlayMontageCallbackProxy.OnInterrupted:Add(self.OwnerActor, callback)   
    -- -- PlayMontageCallbackProxy.OnCompleted:Add(self.OwnerActor, callback)
    -- -- PlayMontageCallbackProxy.OnBlendOut:Add(self.OwnerActor,callback)
    -- self:K2_EndAbility()
end


function GASummons:ClearSpeed()

end

function GASummons:K2_OnEndAbility(bWasCancelled)
    Super(GASummons).K2_OnEndAbility(self, bWasCancelled)
end


function GASummons:GetMontageToPlay()
    --to do 改成根据主角类型读动作配置表
    if self.OwnerActor and self.OwnerActor.SkillComponent then
        return self.OwnerActor.SkillComponent:GetAssistAnim(self.AnimType)
    else
        return nil
    end
end


function GASummons:GetSpawnLocation()
    local ActorLocation = self.OwnerActor:K2_GetActorLocation()
    local CameraRotation = self.OwnerActor:GetCameraRotation()
    local LocalTransform = UE.UKismetMathLibrary.MakeTransform(ActorLocation, CameraRotation, UE.FVector(1, 1, 1))
    -- local Direction = {
    --     UE.FVector(0,1,0), -- 右边
    --     UE.FVector(-1,1,0), -- 右后
    --     UE.FVector(-1,0,0), -- 正后
    --     UE.FVector(-1,-1,0), -- 左后
    --     UE.FVector(0,-1,0), -- 正左
    --     UE.FVector(1,-1,0), -- 左前
    --     UE.FVector(1,0,0), -- 正前
    --     UE.FVector(1,1,0), -- 右前
    -- }
    local Direction = {
        UE.FVector(0,-1,0), -- 正左
        UE.FVector(1,-1,0), -- 左前
        UE.FVector(0,1,0), -- 正右
        UE.FVector(1,1,0), -- 右前
        UE.FVector(1,0,0), -- 正前
        UE.FVector(-1,-1,0), -- 左后
        UE.FVector(-1,1,0), -- 右后
    }
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.WorldStatic)
    ObjectTypes:Add(UE.EObjectTypeQuery.Destructible)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:AddUnique(self.OwnerActor)
    for _, Dir in pairs(Direction) do
        --找出合适的落脚点
        UE.UKismetMathLibrary.Vector_Normalize(Dir)
        local OffsetInWorld = UE.UKismetMathLibrary.TransformLocation(LocalTransform, Dir * self.SpawnOffsetRadius)
        local TempHits = UE.TArray(UE.FHitResult)        
        local CollisionRadius =  self.CollisionRadius
        local CollisionHalfHeight =  self.CollisionHalfHeight
        --UE.UKismetSystemLibrary.DrawDebugLine(self, OffsetInWorld, OffsetInWorld + UE.FVector(0, 0, 500), UE.FLinearColor(0, 1, 0), 300, 3) 
        local Flag = UE.UHiCollisionLibrary.CapsuleTraceMultiForObjects(self.OwnerActor, ActorLocation, OffsetInWorld, UE.FRotator(), 
            CollisionRadius, CollisionHalfHeight, ObjectTypes, true, ActorsToIgnore, 
            UE.EDrawDebugTrace.None, TempHits, true, UE.FLinearColor(1, 0, 0), UE.FLinearColor(0, 1, 0), 5.0) 
        G.log:info(self.__TAG__, "GASummons:GetSpawnLocation, hitnum: %s, hit flag %s", TempHits:Length(), Flag)
        if TempHits:Length() > 0 then
            local Distance = OffsetInWorld:Size()
            for Ind = 1, TempHits:Length() do
                local HitResult = TempHits:Get(Ind)
                if HitResult.bBlockingHit then            
                    Distance = HitResult.Distance
                    if HitResult.Distance < Distance then
                        Distance = HitResult.Distance
                    end            
                end
            end
            Distance = math.min(0.0, Distance - CollisionRadius)
            local TargetSpawnLocation = UE.UKismetMathLibrary.TransformLocation(LocalTransform, Dir * Distance)
            UE.UKismetSystemLibrary.DrawDebugLine(self, TargetSpawnLocation, TargetSpawnLocation + UE.FVector(0, 0, 500), UE.FLinearColor(1, 0, 0), 300, 3)        
            if Distance > self.SpawnMinDistance then
                return TargetSpawnLocation
            end
        else
            return OffsetInWorld
        end       
    end
end

return GASummons



--废弃
--因怪谈召唤整体牵到技能流程，召唤通过TA来召唤，GA只负责播放召唤的动作

-- function GASummons:OnFakeAssistEnd(FakeActor, SkillTarget, SkillTargetComponent)
--     local Actor = self.OwnerActor
--     if not Actor:IsServer() then
--         G.log:info(self.__TAG__, "[assist skill] begin spawn real entity %s %s", G.GetObjectName(Actor),
--             G.GetObjectName(FakeActor))
--     end
--     if FakeActor then
--         -- FakeActor:K2_DestroyActor() --先隐藏，销毁交给actor自己的timer
--         FakeActor:SetActorHiddenInGame(true)
--         FakeActor = nil;
--     end
--     if not Actor:IsServer() then
--         -- self:K2_EndAbility()
--         return
--     end

--     if not SkillTarget then
--         -- self:K2_EndAbility()
--         return
--     end
--     local SpawnDirection = UE.FVector()
--     local TargetSpawnLocation = UE.FVector()
--     local TargetLocation = UE.FVector()
--     if Actor ~= SkillTarget then
--         local OwnerLocation = Actor:K2_GetActorLocation()
--         local TargetDis
--         TargetDis, TargetLocation = utils.GetTargetNearestDistance(OwnerLocation, SkillTarget, SkillTargetComponent)
--         G.log:info(self.__TAG__, "GASummons get target Location x:%s y:%s z:%s", TargetLocation.X, TargetLocation.Y,
--             TargetLocation.Z)
--         local OwnerLocationWithoutZ = UE.FVector(OwnerLocation.X, OwnerLocation.Y, 0)
--         local TargetLocationWithoutZ = UE.FVector(TargetLocation.X, TargetLocation.Y, 0)
--         local Direction = UE.UKismetMathLibrary.GetDirectionUnitVector(TargetLocationWithoutZ, OwnerLocationWithoutZ)
--         SpawnDirection = UE.UKismetMathLibrary.RotateAngleAxis(Direction, self.SpawnOffsetAngle, UE.FVector(0, 0, 1))
--         TargetSpawnLocation = TargetLocation + SpawnDirection * self.SpawnOffsetRadius

--         -- draw debug line
--         if self.bShowDebugInfo then
--             UE.UKismetSystemLibrary.DrawDebugLine(self, OwnerLocation, TargetLocation, UE.FLinearColor(0, 0, 1), 300, 3)
--             UE.UKismetSystemLibrary.DrawDebugLine(self, TargetLocation, TargetSpawnLocation, UE.FLinearColor(0, 1, 0),
--                 300, 3)
--         end
--         G.log:info(self.__TAG__, "GASummons expect SummonsPosition x:%s y:%s z:%s", TargetSpawnLocation.X,
--             TargetSpawnLocation.Y, TargetSpawnLocation.Z)
--     else
--         TargetLocation = Actor:K2_GetActorLocation()
--         local Rotation = Actor:GetControlRotation()
--         local Rotator = UE.FRotator(0, Rotation.Yaw, 0)
--         local Direction = Rotator:GetForwardVector()
--         SpawnDirection = UE.UKismetMathLibrary.RotateAngleAxis(Direction, self.SpawnOffsetAngle, UE.FVector(0, 0, 1))
--         TargetSpawnLocation = TargetLocation + SpawnDirection * self.SpawnOffsetRadius
--     end

--     local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
--     ObjectTypes:Add(UE.EObjectTypeQuery.WorldStatic)
--     ObjectTypes:Add(UE.EObjectTypeQuery.Destructible)
--     local HitResult = UE.FHitResult()
--     local ActorsToIgnore = UE.TArray(UE.AActor)
--     -- 在目标和期望点中间找一个不撞墙的点
--     G.log:info(self.__TAG__, "GASummons trace start Location x:%s y:%s z:%s", TargetLocation.X, TargetLocation.Y,
--         TargetLocation.Z)
--     local ReturnValue = UE.UKismetSystemLibrary.LineTraceSingleForObjects(self:GetWorld(), TargetLocation,
--         TargetSpawnLocation, ObjectTypes, false, ActorsToIgnore, UE.EDrawDebugTrace.None, HitResult, true)
--     -- if self.bShowDebugInfo then
--     --     UE.UKismetSystemLibrary.DrawDebugLine(self, TargetLocation, TargetSpawnLocation, UE.FLinearColor(1, 1, 0), 300, 5)
--     -- end
--     if ReturnValue then
--         G.log:info(self.__TAG__, "actor has block by static mesh: （%s, %s, %s)", HitResult.Location.X,
--             HitResult.Location.Y, HitResult.Location.Z)
--         local Direction = SpawnDirection * self.CollisionRadius
--         TargetSpawnLocation = UE.FVector(HitResult.Location.X, HitResult.Location.Y, HitResult.Location.Z) - Direction
--     end
--     -- 先不做落地检查了
--     -- local OffsetVector = UE.FVector(0, 0, 800) --落地碰撞检查
--     -- G.log:info(self.__TAG__, "GASummons real SummonsPosition x:%s y:%s z:%s", TargetSpawnLocation.X, TargetSpawnLocation.Y, TargetSpawnLocation.Z)
--     -- ObjectTypes:Add(UE.EObjectTypeQuery.WorldDynamic)
--     -- ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
--     -- ObjectTypes:Add(UE.EObjectTypeQuery.PhysicsBody)
--     -- ReturnValue = UE.UKismetSystemLibrary.LineTraceSingleForObjects(self:GetWorld(), TargetSpawnLocation + OffsetVector, TargetSpawnLocation, ObjectTypes, true, ActorsToIgnore, UE.EDrawDebugTrace.None, HitResult, true)
--     -- if ReturnValue then
--     --     TargetSpawnLocation.Z = HitResult.Location.Z + self.SpawnOffsetZ
--     -- else
--     --     TargetSpawnLocation.Z = TargetSpawnLocation.Z + self.SpawnOffsetZ
--     -- end
--     TargetSpawnLocation.Z = TargetSpawnLocation.Z + self.SpawnOffsetZ
--     local FaceDirection = TargetLocation - TargetSpawnLocation
--     local Rotator = UE.UKismetMathLibrary.MakeRotationFromAxes(FaceDirection, UE.FVector(0.0, 0.0, 0.0),
--         UE.FVector(0.0, 0.0, 0.0))
--     local RealRotator = UE.UKismetMathLibrary.MakeRotator(0, 0, Rotator.Yaw)
--     local TransportTransform = UE.UKismetMathLibrary
--                                    .MakeTransform(TargetSpawnLocation, RealRotator, UE.FVector(1, 1, 1))
--     -- G.log:info("yb", "[assist skill]assist target pos(%s %s %s)", TargetSpawnLocation.X, TargetSpawnLocation.Y, TargetSpawnLocation.Z)
--     -- local BindCameraTrans = UE.UKismetMathLibrary.MakeTransform(self.LocalTrans.Translation, UE.FRotator(self.LocalTrans.Rotation), self.LocalTrans.Scale3D)
--     local SummonsActor = GameAPI.SpawnActor(Actor:GetWorld(), self.ActorClass, TransportTransform,
--         UE.FActorSpawnParameters(), {})
--     if self.bShowDebugInfo then
--         UE.UKismetSystemLibrary.DrawDebugLine(self, TargetSpawnLocation, TargetSpawnLocation + UE.FVector(0, 0, 500),
--             UE.FLinearColor(1, 0, 0), 300, 3)
--     end
--     G.log:info(self.__TAG__, "[assist skill] spawn entity: %s", G.GetObjectName(SummonsActor))
--     -- self:K2_EndAbility()
-- end
