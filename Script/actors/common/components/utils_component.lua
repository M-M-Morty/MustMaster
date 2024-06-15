require "UnLua"

local G = require("G")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local t = require("t")
local configs = require("configs")
local check_table = require("common.data.state_conflict_data")

local UtilsComponent = Component(ComponentBase)

local decorator = UtilsComponent.decorator

local Switch = false

decorator.message_receiver()
function UtilsComponent:SwitchAllMonsterBT()
    self:Server_SwitchAllMonsterBT()
end

function UtilsComponent:Server_SwitchAllMonsterBT_RPC()
    local Monsters = GameAPI.GetActorsWithTag(self.actor, configs.MonsterTag)
    for idx, Monster in pairs(Monsters) do
        if not Switch then
            Monster:SendMessage("PauseBT")
            Switch = true
        else
            Monster:SendMessage("ResumeBT")
            Switch = false
        end
    end
end

decorator.message_receiver()
function UtilsComponent:PlayLevelSequence(Sequence)
    self:Client_PlayLevelSequence(Sequence)
end

function UtilsComponent:Client_PlayLevelSequence_RPC(Sequence)
    local Settings = UE.FMovieSceneSequencePlaybackSettings()
    self.SequencePlayer, self.SequenceActor = utils.EvCreateLevelSequencePlayer(self.actor, Sequence, Settings, true, true)
    self.SequencePlayer:Play()
end

decorator.message_receiver()
function UtilsComponent:JudgeSuccess(BeJudgeActor)
    self.JudgeCnt = self.JudgeCnt + 1
end

decorator.message_receiver()
function UtilsComponent:TryPlayMessagePopSequence()
    if self.JudgeCnt ~= self.JudgeCntForMessagePop then
        return
    end

    self.actor:Client_SendMessage("PlayMessagePopSequence")
end

decorator.message_receiver()
function UtilsComponent:BanInput()
    self:SendMessage("EnterState", check_table.State_ForbidMove)
    self:SendMessage("EnterState", check_table.State_ForbidSkill)  
end

decorator.message_receiver()
function UtilsComponent:UnbanInput()
    self:SendMessage("EndState", check_table.State_ForbidMove)
    self:SendMessage("EndState", check_table.State_ForbidSkill)  
end

decorator.message_receiver()
function UtilsComponent:StartMonologue(MonologueID)
    self.actor.PlayerState:SendMessage("StartMonologue", MonologueID)
end

-- --------------------------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------------------------------------
-- -------------------------- 下面这几个Sequence是动画帧事件触发的，且没有通用性，不适合挪到FlowGraph中 --------------------------
-- --------------------------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------------------------------------
decorator.message_receiver()
function UtilsComponent:PlayMessagePopSequence()
    self:PlayBossLevelSequence(self.MessagePopLevelSequence)
end

decorator.message_receiver()
function UtilsComponent:PlayBossDeadLevelSequence()
    self:PlayBossLevelSequence(self.BossDeadLevelSequence, nil, self.PlayAkayaPickupDogLS)
end

function UtilsComponent:PlayBossLevelSequence(Sequence, PlayCallback, FinishCallback)
    local function _MakeActorArray(Actor)
        local Arr = UE.TArray(UE.AActor)
        Arr:Add(Actor)
        return Arr
    end

    local Boss = utils.GetBoss()
    local Settings = UE.FMovieSceneSequencePlaybackSettings()
    self.SequencePlayer, self.SequenceActor = utils.EvCreateLevelSequencePlayer(self.actor, Sequence, Settings, true, true)
    local MonsterBinding = UE.FAbilityTaskSequenceBindings()
    MonsterBinding.BindingTag = configs.BossBindTag
    MonsterBinding.Actors = _MakeActorArray(Boss)
    MonsterBinding.BindingClasses:Add(UE.UGameplayStatics.GetClass(Boss))

    local Location = Boss.Mesh:K2_GetComponentLocation()
    local Rotation = Boss.Mesh:K2_GetComponentRotation()
    local Transform = UE.UKismetMathLibrary.MakeTransform(Location, Rotation, UE.FVector(1, 1, 1))
    MonsterBinding.BindingTransforms:Add(Transform)

    self.SequenceActor:SetBindingByTag(MonsterBinding.BindingTag, MonsterBinding.Actors)

    if PlayCallback then
        self.SequencePlayer.OnPlay:Add(self, PlayCallback)
    end

    if FinishCallback then
        self.SequencePlayer.OnFinished:Add(self, FinishCallback)
    end

    self.SequencePlayer:Play()
end

decorator.message_receiver()
function UtilsComponent:PlayAkayaPickupDogLS()
    local AllDog = GameAPI.GetActorsWithTag(self.actor, configs.DogActorTag)
    if AllDog == nil or #AllDog == 0 then
        return
    end

    local AllAkaya = GameAPI.GetActorsWithTag(self.actor, configs.AkayaActorTag)
    if AllAkaya == nil or #AllAkaya == 0 then
        return
    end

    local Locations = GameAPI.GetActorsWithTag(self.actor, configs.ChuJueActorTag)
    if Locations == nil or #Locations == 0 then
        return
    end

    local Dog = AllDog[1]
    local Akaya = AllAkaya[1]

    Dog:SetActorHiddenInGame(false)
    Akaya:SetActorHiddenInGame(false)

    Dog:K2_SetActorLocation(Locations[1]:K2_GetActorLocation(), false, nil, false)
    Akaya:K2_SetActorLocation(Locations[1]:K2_GetActorLocation(), false, nil, false)

    local function _MakeActorArray(Actor)
        local Arr = UE.TArray(UE.AActor)
        Arr:Add(Actor)
        return Arr
    end

    local Settings = UE.FMovieSceneSequencePlaybackSettings()
    self.SequencePlayer, self.SequenceActor = utils.EvCreateLevelSequencePlayer(self.actor, self.AkayaPickupDogLevelSequence, Settings, true, true)

    local DogBinding = UE.FAbilityTaskSequenceBindings()
    DogBinding.BindingTag = configs.DogBindTag
    DogBinding.Actors = _MakeActorArray(Dog)
    DogBinding.BindingClasses:Add(UE.UGameplayStatics.GetClass(Dog))
    DogBinding.BindingTransforms:Add(Dog:GetTransform())
    self.SequenceActor:SetBindingByTag(DogBinding.BindingTag, DogBinding.Actors)

    local AkayaBinding = UE.FAbilityTaskSequenceBindings()
    AkayaBinding.BindingTag = configs.AkayaBindTag
    AkayaBinding.Actors = _MakeActorArray(Akaya)
    AkayaBinding.BindingClasses:Add(UE.UGameplayStatics.GetClass(Akaya))
    AkayaBinding.BindingTransforms:Add(Akaya:GetTransform())
    self.SequenceActor:SetBindingByTag(AkayaBinding.BindingTag, AkayaBinding.Actors)

    self.SequencePlayer.OnFinished:Add(self, self.OnAkayaPickupDogLSFinished)
    self.SequencePlayer:Play()
end

function UtilsComponent:OnAkayaPickupDogLSFinished()
    local AllDog = GameAPI.GetActorsWithTag(self.actor, configs.DogActorTag)
    local AllAkaya = GameAPI.GetActorsWithTag(self.actor, configs.AkayaActorTag)
    local Dog = AllDog[1]
    local Akaya = AllAkaya[1]

    Dog:SetActorHiddenInGame(true)
    Akaya:SetActorHiddenInGame(true)
end

return UtilsComponent
