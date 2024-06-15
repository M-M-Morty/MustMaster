local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local check_table = require("common.data.state_conflict_data")
local G = require("G")
local t = require("t")
local SkillUtils = require("common.skill_utils")

local SwitchPlayerComponent = Component(ComponentBase)

local decorator = SwitchPlayerComponent.decorator

function SwitchPlayerComponent:Initialize(...)
    Super(SwitchPlayerComponent).Initialize(self, ...)
    self.SequenceSwitchInPlayer = nil
    self.SequenceSwitchOutPlayer = nil
    self.bPendingSwitchOut = false
    self.bPendingFadeOut = false    
end

function SwitchPlayerComponent:Start()
    Super(SwitchPlayerComponent).Start(self)
    self.bPendingSwitchOut = false
end

function SwitchPlayerComponent:ReceiveBeginPlay()
    Super(SwitchPlayerComponent).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("SwitchPlayerComponent(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
end

decorator.message_receiver()
function SwitchPlayerComponent:OnGameAbilitySystemReady()
    if self.GA_SwitchOutClass then
        self.actor.SkillComponent:GiveAbility(self.GA_SwitchOutClass, -1, utils.MakeUserData())
    end
end

function SwitchPlayerComponent:GetSwitchLevelSequence_Internal(InLevelSequence, PlayCallback, FinishCallback)
    G.log:debug("hycoldrain", "SwitchPlayerComponent:GetSwitchLevelSequence_Internal %s  %s  %s", G.GetDisplayName(InLevelSequence), self.actor:IsServer(), self.actor:GetDisplayName()) 
    if InLevelSequence and InLevelSequence:IsValid() then        
        local SequencePlayer, SequenceActor = UE.UHiLevelSequencePlayer.CreateHiLevelSequencePlayer(self.actor, InLevelSequence, UE.FMovieSceneSequencePlaybackSettings())            
        local BindingActors = UE.TArray(UE.AActor)
        BindingActors:Add(self.actor)
        SequenceActor:SetBindingByTag(self.BindPlayerTag, BindingActors)     
        -- bind weapon actor to sequnce
        for i = 1, self.actor.Weapons:Num() do
            local Weapon = self.actor.Weapons:GetRef(i)               
            if Weapon and Weapon:IsValid() and Weapon:K2_GetRootComponent().bVisible then
                BindingActors:Clear()
                BindingActors:Add(Weapon)
                SequenceActor:SetBindingByTag(Weapon.SequenceBindingTag, BindingActors)    
            end
        end        
        if PlayCallback then      
            SequencePlayer.OnPlay:Add(self, PlayCallback)        
        end
        if FinishCallback then
            SequencePlayer.OnFinished:Add(self, FinishCallback)
        end        
        return SequencePlayer
    else
        if PlayCallback then      
            PlayCallback()
        end
        if FinishCallback then
            FinishCallback()
        end
        return nil
    end
end


--------OLD PLAYER FUNTIONS --------

function SwitchPlayerComponent:OldPlayerFadingOut()
    if self.actor:IsServer() then
        self:Multicast_PlayerFadingOut()        
    end
end


function SwitchPlayerComponent:Multicast_PlayerFadingOut_RPC()
    local Success = self:PlayerFadingOut_Internal()
    G.log:debug("hycoldrain", "SwitchPlayerComponent:Multicast_PlayerFadingOut_RPC %s", Success) 
    if not Success then
        self:PlayerFadingOutFinishedCallback()
    end
end


--GameAbility Messages-------
decorator.message_receiver()
function SwitchPlayerComponent:OnComboTail(SkillID)
    -- G.log:error("hycoldrain", "SwitchPlayerComponent:OnRecieveComboTailEvent %s  %s  %s", self.bPendingSwitchOut, self.actor:IsServer(), self.actor:GetDisplayName())     
    if self.bPendingSwitchOut then
        self:OldPlayerFadingOut()
    end

    if SkillID == self.SwitchInSuperSkillID and self.actor:IsServer() then
        self.bStartQTETriggered = true
        local ControllerSPComp = self:GetControllerSwitchPlayerComponent()
        if ControllerSPComp.bInQTE then
            -- 超级登场技触发后摇事件，触发 QTE 显示.
            ControllerSPComp:StartQTE()
        end
    end
end

decorator.message_receiver()
function SwitchPlayerComponent:OnEndAbility(SkillID, SkillType)
    G.log:debug("hycoldrain", "SwitchPlayerComponent:OnEndAbility  %s  %s  %s", self.actor:GetDisplayName(), self.bPendingSwitchOut, self.actor:IsServer())
    if self.bPendingSwitchOut then
        self:ApplyMontageWhenSwitchOut()
        if not self.bPendingFadeOut then
            self:OldPlayerFadingOut()
        end
    end

    if SkillID == self.SwitchInSuperSkillID and self.actor:IsServer() then
        if not self.bStartQTETriggered then
            local ControllerSPComp = self:GetControllerSwitchPlayerComponent()
            if ControllerSPComp.bInQTE then
                -- 超级登场技被打断，没有触发后摇事件.
                ControllerSPComp:EndQTE()
            end
        end
    end
end

function SwitchPlayerComponent:GetControllerSwitchPlayerComponent()
    local PlayerController = self.actor.PlayerState:GetPlayerController()
    return PlayerController.ControllerSwitchPlayerComponent
end

decorator.message_receiver() -- OldPlayer
function SwitchPlayerComponent:OnRecieveMessageBeforeSwitchOut() 
    G.log:debug("hycoldrain", "SwitchPlayerComponent:OnRecieveMessageBeforeSwitchOut %s  %s  ", self.actor:GetDisplayName(),self.actor:IsServer())  
    self.bPendingSwitchOut = true
    if self.actor and self.actor:IsValid() then
        self.actor.CharacterMovement.UpdatedComponent:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Pawn, UE.ECollisionResponse.ECR_Ignore)
        self.actor:SetWeaponCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        self.actor:K2_GetRootComponent():SetGenerateOverlapEvents(false)    
    end
    self:SendClientMessage("SetEffectAllowed", false)

    -- if self.actor and self.actor:IsServer() then
    --     UE.UHiUtilsFunctionLibrary.AIUnregisterPerceptionSource(self.actor)
    -- end
    -- 释放技能中，等技能结束(或进入后摇状态)，再 fadeout 角色
    if not SkillUtils.HasActivateAbilities(self.actor) then                
        self:ApplyMontageWhenSwitchOut()
        self:OldPlayerFadingOut()   
    end
end


function SwitchPlayerComponent:ApplyMontageWhenSwitchOut()
    G.log:debug("hycoldrain", "SwitchPlayerComponent:ApplyMontageWhenSwitchOut %s  %s  %s", self.actor:IsServer(), self.actor:GetDisplayName(), G.GetDisplayName(self.Montage_SwitchOut)) 
    if self.Montage_SwitchOut then       
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, self.Montage_SwitchOut, 1.0)
        --local callback = function(name)                            
        --                end
        --PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        --PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
        return true
    else
        return false
    end       
end

function SwitchPlayerComponent:AttachActorToPlayerController()
    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    if CameraManager then
        --self.actor:K2_AttachToActor(CameraManager, "None", UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative)
    end
end

function SwitchPlayerComponent:DetachActorFromPlayerController()
    --self.actor:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)    
end


function SwitchPlayerComponent:PlayerFadingOutFinishedCallback()
    if self.actor and self.actor:IsServer() then
        self:Multicast_PlayerFadingOutFinished()
    end
end

function SwitchPlayerComponent:Multicast_PlayerFadingOutFinished_RPC()
    G.log:debug("hycoldrain", "PlayerFadingOutFinishedCallback  %s %s", self.actor:IsClient(),  self.actor:GetDisplayName())    
    self.actor:SetCapsuleCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    self.actor.CharacterMovement:Deactivate()
    self:AttachActorToPlayerController()    
    self.actor:SetVisibility_RepNotify(false,true)
    
    -- 角色退场前清下状态机，以防下次出场时状态不对的问题
    self:SendMessage("ExecuteAction", check_table.Action_SwitchPlayerOut)
    self.bPendingSwitchOut = false
    self.bPendingFadeOut = false
end

-- old player fade out
function SwitchPlayerComponent:PlayerFadingOut_Internal()   
    if not self.actor:IsDead() then
        if self.actor.InteractionComponent then            
            self.actor.InteractionComponent:SetInteractable(false)
        end
        return self:PlaySwitchOutLevelSequence(nil, function()
            --G.log:debug("hycoldrain", "OnPlayForwardSequence When Switchout %s   %s",  self.actor:GetDisplayName(), G.GetDisplayName(self.SwitchOutSequence))
            self:PlayerFadingOutFinishedCallback()
            end)
    else
        return false
    end
end


function SwitchPlayerComponent:PlaySwitchOutLevelSequence(PlayCallback, FinishCallback)
    self.bPendingFadeOut = true 
    if not self.SequenceSwitchOutPlayer then
        self.SequenceSwitchOutPlayer = self:GetSwitchLevelSequence_Internal(self.SwitchOutSequence, PlayCallback, FinishCallback)    
    end
    if self.SequenceSwitchOutPlayer and self.SequenceSwitchOutPlayer:IsValid() then
        if self.SequenceSwitchInPlayer and self.SequenceSwitchInPlayer:IsValid() and self.SequenceSwitchInPlayer:IsPlaying() then
            self.SequenceSwitchInPlayer:Stop()
        end
        self.SequenceSwitchOutPlayer:Play()
        return true
    else
        return false
    end
end



--------NEW PLAYER FUNCTIONS  ------------
-- new player do something before switch in
decorator.message_receiver()
function SwitchPlayerComponent:OnRecieveMessageBeforeSwitchIn(PlayerLocation, PlayerRotation, OldPlayer)
    local bInAir = OldPlayer:IsInAir()
    self.bPendingSwitchOut = false   
    if self.actor and self.actor:IsValid() then 
        self.actor:SetCapsuleCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)        
        self.actor.CharacterMovement:Activate()
        self.actor.CharacterMovement.UpdatedComponent:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Pawn, UE.ECollisionResponse.ECR_Block)    
        self.actor:SetWeaponCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
        self.actor:K2_GetRootComponent():SetGenerateOverlapEvents(true)        
        if self.actor.InteractionComponent then
            self.actor.InteractionComponent:SetInteractable(true)
        end
        G.log:debug("hycoldrain", "SwitchPlayerComponent:OnRecieveMessageBeforeSwitchIn %s  ",self.actor:GetDisplayName())
    end
    self:DetachActorFromPlayerController()

    if self.actor and self.actor:IsServer() then
        if self.SequenceSwitchOutPlayer and self.SequenceSwitchOutPlayer:IsValid() and self.SequenceSwitchOutPlayer:IsPlaying() then
            self.SequenceSwitchOutPlayer:Stop()
        end
        
        local ExtraInfo = OldPlayer.PlayerState:GetPlayerController().ExtraInfo
        local bInBattle = ExtraInfo.bInBattle
        --local bInExtreme = ExtraInfo.bInExtreme
        --local bInAir = ExtraInfo.bInAir
        --local bInQTE = ExtraInfo.bInQTE
        local NewLocation = PlayerLocation
        local NewRotation = PlayerRotation
        -- 战斗中切换角色的位移
        if bInBattle then
            local OffsetInWorldSpace = PlayerRotation:RotateVector(UE.FVector(self.SpwanLocationOffset.X, self.SpwanLocationOffset.Y, 0))
            NewLocation = PlayerLocation + OffsetInWorldSpace

            local TempHits = UE.TArray(UE.FHitResult)
            local ActorsToIgnore = UE.TArray(UE.AActor)
            ActorsToIgnore:AddUnique(OldPlayer)

            local CollisionRadius =  self.actor.CapsuleComponent.CapsuleRadius
            local CollisionHalfHeight =  self.actor.CapsuleComponent.CapsuleHalfHeight
            UE.UHiCollisionLibrary.CapsuleTraceMultiForObjects(self.actor, PlayerLocation, NewLocation, UE.FRotator(), CollisionRadius, CollisionHalfHeight, self.ObjectTypesQuery, true, ActorsToIgnore, UE.EDrawDebugTrace.ForDuration, TempHits, true, UE.FLinearColor(1, 0, 0), UE.FLinearColor(0, 1, 0), 5.0)

            if TempHits:Length() > 0 then
                local Distance = UE.UKismetMathLibrary.Vector_Distance(UE.FVector(0, 0, 0), OffsetInWorldSpace)
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
                UE.UKismetMathLibrary.Vector_Normalize(OffsetInWorldSpace)
                NewLocation = PlayerLocation + OffsetInWorldSpace * Distance
            end
        -- 休闲状态下切人    
        else
            NewLocation = PlayerLocation
            NewRotation = OldPlayer:K2_GetActorRotation()
            
            -- 移动状态下让角色向前位移一段距离
            local OldVelocity = OldPlayer.CharacterMovement.Velocity
            local OldRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(OldVelocity)
            if UE.UKismetMathLibrary.VSizeXY(OldVelocity) > 0 then
                NewLocation = NewLocation + OldPlayer:GetActorForwardVector() * 50.0
                NewRotation.Yaw = OldRotation.Yaw
            end
            
            local HeightOffset = self.actor.CapsuleComponent:GetScaledCapsuleHalfHeight() - OldPlayer.CapsuleComponent:GetScaledCapsuleHalfHeight()
            NewLocation.Z = NewLocation.Z + HeightOffset
        end
        self.actor:K2_TeleportTo(NewLocation, NewRotation)
        self:Multicast_SetPlayerTransform(NewLocation, NewRotation)
    end
    -- 清理角色身上残留的 buff, 放在 switch in 而不是 switch out 的原因是，switch out 时角色可能在继续播放技能通过蒙太奇添加 buff，时机不对.
    self.actor:SendMessage("ClearBuff")
end

decorator.message_receiver()
function SwitchPlayerComponent:ReceiveBeforeSwitchIn()
    if self.actor and self.actor:IsValid() then
        self.actor:SetCapsuleCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
        self.actor.CharacterMovement:Activate()
        self.actor.CharacterMovement.UpdatedComponent:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Pawn, UE.ECollisionResponse.ECR_Block)
        self.actor:SetWeaponCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
        self.actor:K2_GetRootComponent():SetGenerateOverlapEvents(true)
        if self.actor.InteractionComponent then
            self.actor.InteractionComponent:SetInteractable(true)
        end
    end
end

function SwitchPlayerComponent:Multicast_SetPlayerTransform_RPC(Location, Rotation)
    G.log:debug("hycoldrain", "Multicast_SetPlayerTransform When SwitchIn %s  %s",  self.actor:GetDisplayName(), self.actor:IsClient())
    self.actor:K2_SetActorLocationAndRotation(Location,Rotation,false,UE.FHitResult(),true)
    
    -- skip update rotation this tick
    self.actor:GetLocomotionComponent():SetSkipUpdateRotation()
    --local CustomSmoothContext = UE.FCustomSmoothContext()
    --self.actor.AppearanceComponent:SetCharacterRotation(Rotation, false, CustomSmoothContext)
    
    --smoothly move camera
    if self.actor:IsPlayer() then
        local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self.actor:GetWorld(), 0)
        CameraManager:EnablePivotSmooth(true)
        self.actor.CharacterStateManager.SwitchPlayer = true
        UE.UKismetSystemLibrary.K2_SetTimerDelegate({self.actor, function ()
            self.actor.CharacterStateManager.SwitchPlayer = false  
            CameraManager:EnablePivotSmooth(false)
        end}, self.CameraBlendTime, false)
    end
    -- fade in 
    self.actor:SetVisibility_RepNotify(false,true)
    self:PlaySwitchInLevelSequence(function()        
        self.actor:SetVisibility_RepNotify(true,true)
        self.actor:SendMessage("InitWeaponVisibility")
        end, nil)
end


decorator.message_receiver()
function SwitchPlayerComponent:OnNewPlayerSwitchIn_RunOnServer(bInBattle, bInExtreme, bInAir)   
    if not (bInBattle or bInExtreme) then
        self:Multicast_PlaySwitchinMontage(bInAir)
    end
end

function SwitchPlayerComponent:Multicast_PlaySwitchinMontage_RPC(bInAir)    
    local Montage = self.Montage_SwitchIn
    if bInAir then
        Montage = self.Montage_SwitchIn_Air
    end
    G.log:debug("hycoldrain", "SwitchPlayerComponent:PlayMontageWhenSwitchIn   %s  %s  %s  %s", tostring(bInAir),  self.actor:GetDisplayName(), tostring(self.actor:IsServer()), G.GetDisplayName(Montage)) 
    local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, 1.0)
end

function SwitchPlayerComponent:ApplyGameplayAbilityWhenSwitchIn(ExtraInfo)
    local bInBattle = ExtraInfo.bInBattle
    local bInExtreme = ExtraInfo.bInExtreme
    local bInAir = ExtraInfo.bInAir
    local bInQTE = ExtraInfo.bInQTE
    local SkillID = nil
    G.log:debug(self.__TAG__, "ApplyGameplayAbilityWhenSwitchIn bInBattle: %s, bInExtreme: %s, bInAir: %s, bInQTE: %s",
            tostring(bInBattle), tostring(bInExtreme), tostring(bInAir), tostring(bInQTE))
    if bInBattle then
        local SetNormalSkill = function()
            -- 释放普通登场技
            if bInAir then
                SkillID = self.SwitchInAirSkillID
            else
                SkillID = self.SwitchInSkillID
            end
        end
        
        if self.SwitchInSuperSkillID ~= 0 then
            local bNoCost = bInQTE

            local GA, _ = SkillUtils.FindAbilityInstanceFromSkillID(self.actor.AbilitySystemComponent, self.SwitchInSuperSkillID)
            if GA then
                GA:EnableCost()
            end

            -- 释放超级登场技
            if bNoCost then
                G.log:debug(self.__TAG__, "Trigger SwitchIn super skill without cost.")
                -- 触发 QTE，超级登场技不消耗
                SkillID = self.SwitchInSuperSkillID
                self.actor.SkillComponent:EnableSkillCost(self.SwitchInSuperSkillID, false, true)
            else
                -- 默认情况下，都需要消耗
                self.actor.SkillComponent:EnableSkillCost(self.SwitchInSuperSkillID, true, true)

                if SkillUtils.CanActivateSkill(self.actor, self.SwitchInSuperSkillID) then
                    G.log:debug(self.__TAG__, "Trigger SwitchIn super skill.")
                    SkillID = self.SwitchInSuperSkillID
                else
                    G.log:debug(self.__TAG__, "Can not activate SwitchIn super skill,Choose Normal SwitchIn Skill")
                    SetNormalSkill()
                end
            end
        else
            SetNormalSkill()
        end
    else
        if bInExtreme then
            if bInAir then
                SkillID = self.SwitchInExtraAirSkillID
            else
                SkillID = self.SwitchInExtraSkillID
            end
        end
    end

    -- 如果超级登场技释放失败，结束 QTE (由于新的 QTE 显示是在超级登场技的后摇触发)
    if (SkillID == 0 or SkillID == nil or SkillID ~= self.SwitchInSuperSkillID) and bInQTE then
        local ControllerSPComp = self:GetControllerSwitchPlayerComponent()
        ControllerSPComp:Server_EndQTE()
    end

    if SkillID then
        self.actor:SendMessage("StartSkill", SkillID)
    end
end

decorator.message_receiver()
function SwitchPlayerComponent:TriggerQTE(SkillID)
    G.log:debug(self.__TAG__, "TriggerQTE SkillID: %d", SkillID)

    local bFromSwitchInSuper = SkillID == self.SwitchInSuperSkillID
    local ControllerSPComp = self:GetControllerSwitchPlayerComponent()
    ControllerSPComp:TriggerQTE(bFromSwitchInSuper)
end

function SwitchPlayerComponent:IsSwitchPlayerCD_Ready()
    G.log:info("hycoldrain", "SwitchPlayerComponent:IsSwitchPlayerCD_Ready %s %s %s   %s", self.SwitchTimeClock, G.GetNowTimestampMs(), self.SwitchTimeClock <= G.GetNowTimestampMs(), G.GetDisplayName(self.actor))
    if self.SwitchTimeClock ~= 0  and self.SwitchTimeClock > G.GetNowTimestampMs() then
        return false
    else
        return true
    end
end

function SwitchPlayerComponent:ClearSwitchPlayerCD()
    self.SwitchTimeClock = G.GetNowTimestampMs()
end

function SwitchPlayerComponent:GetSingleRemainTime()
    local SingleRemainTime = 0
    if self.SwitchTimeClock ~= 0 then
        SingleRemainTime = self.SwitchTimeClock - G.GetNowTimestampMs()
    end
    return SingleRemainTime
end

-- OldPlayer After Switch out
--decorator.message_receiver()
--function SwitchPlayerComponent:OnRecieveMessageAfterSwitchOut()
--    self.actor.CharacterMovement:Deactivate()
--end


-- NewPlayer After SwitchIn
decorator.message_receiver()
function SwitchPlayerComponent:AfterSwitchIn(OldPlayer, NewPlayer, ExtraInfo)
    --G.log:debug("hycoldrain", "SwitchPlayerComponent:AfterSwitchIn %s IsClient.%s", self.actor:GetLocalRole(), self.actor:IsClient())
    -- BP_OnRep_PlayerState 刷新 cache 多次切角色只会刷新一次，这里调用下刷新.
    if self.actor.InteractionComponent then            
        self.actor.InteractionComponent:SetInteractable(true)
    end
    self.actor:RefreshDataCache()
    self:SendClientMessage("SetEffectAllowed", true)

    --if self.actor and self.actor.SkillComponent and self.actor.SkillComponent.SkillDriver then
    --    self.actor.SkillComponent.SkillDriver:Reset()
    --end

    if self.actor:IsPlayer() and not ExtraInfo.bPlayerDeadReason then
        self:ApplyGameplayAbilityWhenSwitchIn(ExtraInfo)
    end

    self.SwitchTimeClock = G.GetNowTimestampMs() + self.SwitchPlayerCD * 1000

    if self.actor:IsClient() then
        local ControllerSPComp = self:GetControllerSwitchPlayerComponent()
        ControllerSPComp:Server_AfterClientSwitchIn()

        t.Setp(self.actor)
    else
        t.Setps(self.actor)        
        -- UE.UHiUtilsFunctionLibrary.AIRegisterPerceptionSource(self.actor)
    end
end

function SwitchPlayerComponent:PlaySwitchInLevelSequence(PlayCallback, FinishCallback)
    if not self.SequenceSwitchInPlayer then
        self.SequenceSwitchInPlayer = self:GetSwitchLevelSequence_Internal(self.SwitchInSequence, PlayCallback, FinishCallback)    
    end
    if self.SequenceSwitchInPlayer and self.SequenceSwitchInPlayer:IsValid() then       
        if self.SequenceSwitchOutPlayer and self.SequenceSwitchOutPlayer:IsValid() and self.SequenceSwitchOutPlayer:IsPlaying() then
            self.SequenceSwitchOutPlayer:Stop()
        end 
        self.SequenceSwitchInPlayer:Play()     
    end
end



------DEBUG-------
--decorator.message_receiver()
--function SwitchPlayerComponent:Test()
--    --if self.GA_SwitchInClass then        
--    --    self.actor.SkillComponent:GiveAbility(self.GA_SwitchInClass, -1, utils.MakeUserData())        
--    --end
----
--    --if self.GA_SwitchInClass_Air then
--    --    self.actor.SkillComponent:GiveAbility(self.GA_SwitchInClass_Air, -1, utils.MakeUserData())
--    --end
----
--    --if self.GA_SwitchInClass_Extra then
--    --    self.actor.SkillComponent:GiveAbility(self.GA_SwitchInClass_Extra, -1, utils.MakeUserData())
--    --end
----
--    --if self.GA_SwitchInClass_Extra_Air then
--    --    self.actor.SkillComponent:GiveAbility(self.GA_SwitchInClass_Extra_Air, -1, utils.MakeUserData())
--    --end
--
--    local ASC = UE.UAbilitySystemBlueprintLibrary.GetAbilitySystemComponent(self.actor)
--    ASC:TryActivateAbilityByClass(self.GA_SwitchInClass_Air, true)   
--
--end

return SwitchPlayerComponent
