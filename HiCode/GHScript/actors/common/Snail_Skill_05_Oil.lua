
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

---@type Snail_Skill_05_Oil_C
local Snail_Skill_05_Oil_C = Class()


function Snail_Skill_05_Oil_C:ReceiveBeginPlay()
    if self:HasAuthority() then
        self.start_time = UE.UGameplayStatics.GetTimeSeconds(self)
    end

    self.Collision.OnComponentBeginOverlap:Add(self, self.OnComponentBeginOverlap)
end

function Snail_Skill_05_Oil_C:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)

    if self:HasAuthority() then
        local current = UE.UGameplayStatics.GetTimeSeconds(self)
        if current - self.start_time > self.TOTAL_LIFE_SECOND then
            self:K2_DestroyActor()
            --self:InstantBomb()
        end

        --FunctionUtil:DrawShapeComponent(self.Collision)
    end
end

function Snail_Skill_05_Oil_C:ReceiveEndPlay(EndPlayReason)
    self.Collision.OnComponentBeginOverlap:Remove(self, self.OnComponentBeginOverlap)
end

function Snail_Skill_05_Oil_C:OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if self:HasAuthority() then
        if FunctionUtil:IsPlayer(OtherActor) then
            local ASC = OtherActor:GetAbilitySystemComponent()
            if ASC then
                local tag = UE.UHiGASLibrary.RequestGameplayTag('StateGH.AbilityState.HasOil')
                if ASC:HasGameplayTag(tag) then
                    ASC:RemoveActiveGameplayEffect(OtherActor.oil_spec_handle, -1)
                end
                OtherActor.oil_spec_handle = ASC:BP_ApplyGameplayEffectToSelf(self.GE_PLAYER_OIL, 1, nil)
            end
        end
    end
end

function Snail_Skill_05_Oil_C:InstantBomb()
    if self.bombing then
        return
    end

    local bomb_inst = self:GetWorld():SpawnActor(self.NA_BOMB_CLASS, self:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self:GetWorld())
    bomb_inst:SetLifeSpan(5)

    self.bombing = true
    local owner = self:GetOwner()
    if owner then
        local Caster = owner
        local tag = UE.UHiGASLibrary.RequestGameplayTag("StateGH.AbilityIdentify.Snail.OilBomb")
        local bombPayload = UE.FGameplayEventData()
        bombPayload.EventTag = tag
        bombPayload.Instigator = Caster
        bombPayload.Target = self
        bombPayload.OptionalObject = FunctionUtil:MakeUDKnockInfo(Caster, self.UD_FKNOCK_INFO)
        UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(Caster, tag, bombPayload)
    end

    self:K2_DestroyActor()
end


return Snail_Skill_05_Oil_C
