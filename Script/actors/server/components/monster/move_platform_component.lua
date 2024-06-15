require "UnLua"

local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local check_table = require("common.data.state_conflict_data")
local utils = require("common.utils")
local Queue = require("common.utils.simple_queue")

local MovePlatformComponent = Component(ComponentBase)
local decorator = MovePlatformComponent.decorator


function MovePlatformComponent:Initialize(...)
    Super(MovePlatformComponent).Initialize(self, ...)

    self.TargetRotation = UE.FRotator.ZeroRotator
end

decorator.message_receiver()
function MovePlatformComponent:OnMovePlatformActorCreate(MovePlatformActor)
    if self.actor.MovePlatformActor ~= nil then
        self.actor.MovePlatformActor:K2_DestroyActor()
        self.actor.MovePlatformActor = nil
    end

    self.actor.MovePlatformActor = MovePlatformActor
end

decorator.message_receiver()
function MovePlatformComponent:OnReceiveTick(DeltaSeconds)
    if self.actor.MovePlatformActor ~= nil then
        -- self:UpdateMovePlatformLocation(DeltaSeconds)
        self:SmoothMovePlatformLocation(DeltaSeconds)
    end
end

function MovePlatformComponent:SmoothMovePlatformLocation(DeltaSeconds)
    -- 转向抖动的原因是:
    --    服务端Actor的朝向是每帧都变的，但是同步到客户端的朝向会有连续几帧一样的情况，可能是同步策略导致的
    --    而移动平台是服务器客户端各自根据Actor朝向计算位置的，所以客户端会走走停停，表现为抖动
    -- 移动抖动的原因应该是:
    --    移动时Actor的Rotation自身会有细微的左右抖动，放到大前方10m就会比较明显，当平滑速度太快，就会出现角色位置的明显的左右抖动
    -- 优化的核心是让角色平滑的速度慢一些，平滑速度慢了既可以避免走走停停，也可以避免位置突变
    local SelfRotation = self.actor:K2_GetActorRotation()
    local SelfForward = UE.UKismetMathLibrary.Conv_RotatorToVector(SelfRotation)

    local SelfLocation = self.actor:K2_GetActorLocation()
    local PlatformLocation = self.actor.MovePlatformActor:K2_GetActorLocation()
    PlatformLocation.Z = SelfLocation.Z
    local Forward = PlatformLocation - SelfLocation

    local CosDelta = UE.UKismetMathLibrary.Dot_VectorVector(UE.UKismetMathLibrary.Normal(Forward), UE.UKismetMathLibrary.Normal(SelfForward))
    local DegreesDelta = UE.UKismetMathLibrary.DegACos(CosDelta)

    -- 默认前方6米，后续等正式制作时提成配置项
    local TargetLocation = SelfLocation + SelfForward * 600

    local CurrentVel = self.actor:GetVelocity()
    local Speed = CurrentVel:Size2D()
    if Speed > 150 then
        -- 移动中往前10米
        TargetLocation = SelfLocation + SelfForward * 1000
    end

    -- 优化点1：Boss转身夹角大于60度时，将平台升空，使平台一直落后目标点，同时避免穿模
    if DegreesDelta > 60 then
        TargetLocation.Z = TargetLocation.Z + 500
    end

    -- 优化点2：平滑速度减慢，且随距离变化而变化
    local InterSpeed = (TargetLocation - self.actor.MovePlatformActor:K2_GetActorLocation()):Size()
    utils.SmoothActorLocation(self.actor.MovePlatformActor, TargetLocation, InterSpeed, DeltaSeconds)

    self.TargetRotation = utils.SmoothActorRotation(self.actor.MovePlatformActor, self.TargetRotation, SelfRotation, 30, 0, DeltaSeconds)
end

function MovePlatformComponent:UpdateMovePlatformLocation(DeltaSeconds)
    local SelfLocation = self.actor:K2_GetActorLocation()
    local SelfRotation = self.actor:K2_GetActorRotation()
    local ForwardNormal = UE.UKismetMathLibrary.Normal(UE.UKismetMathLibrary.Conv_RotatorToVector(SelfRotation))

    local TargetLocation = SelfLocation + ForwardNormal * 1000
    utils.SmoothActorLocation(self.actor.MovePlatformActor, TargetLocation, 800, DeltaSeconds)
    self.TargetRotation = utils.SmoothActorRotation(self.actor.MovePlatformActor, self.TargetRotation, SelfRotation, 50, 0, DeltaSeconds)
end


return MovePlatformComponent
