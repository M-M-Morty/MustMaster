local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local G = require("G")

local AvatarTrapComponent = Component(ComponentBase)

local decorator = AvatarTrapComponent.decorator


function AvatarTrapComponent:ReceiveBeginPlay()
    Super(AvatarTrapComponent).ReceiveBeginPlay(self)
	-- G.log:debug("yj", "AvatarTrapComponent:OnBecomePlayer %s", self.actor:GetDisplayName())
    self.actor:K2_GetRootComponent().OnComponentBeginOverlap:Add(self, self.BeginOverlapTrap)
    self.actor:K2_GetRootComponent().OnComponentEndOverlap:Add(self, self.EndOverlapTrap)
end

function AvatarTrapComponent:BeginOverlapTrap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)

    --[[
    -- G.log:error("yj", "AvatarTrapComponent BeginOverlapTrap Self.%s OtherActor.%s, OtherComp.%s", G.GetDisplayName(self.actor), G.GetDisplayName(OtherActor), G.GetDisplayName(OtherComp))
    if OtherActor and OtherActor.IsTrapActor then
        self:Server_BeginOverlapTrap(OtherActor)
    end
    ]]--

    -- 暂时不需要客户端RPC，直接转由双端同步执行
    if OtherActor and OtherActor.IsTrapActor then
        OtherActor:OnActorBeginOverlap(self.actor);
    end
end

function AvatarTrapComponent:EndOverlapTrap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    --[[
    -- G.log:error("yj", "AvatarTrapComponent EndOverlapTrap Self.%s OtherActor.%s, OtherComp.%s", G.GetDisplayName(self.actor), G.GetDisplayName(OtherActor), G.GetDisplayName(OtherComp))
    if OtherActor and OtherActor.IsTrapActor then
        self:Server_EndOverlapTrap(OtherActor)
    end
    ]]--

    if OtherActor and OtherActor.IsTrapActor then
        OtherActor:OnActorEndOverlap(self.actor);
    end
end

function AvatarTrapComponent:Server_BeginOverlapTrap_RPC(OtherActor)
    -- G.log:debug("yj", "AvatarTrapComponent Server_BeginOverlapTrap_RPC OtherActor.%s.%s", OtherActor, G.GetDisplayName(OtherActor))
    if OtherActor and OtherActor.IsTrapActor then
    	-- 延时一帧通知，因为此时位移变化可能还没有同步到服务器
        UE.UKismetSystemLibrary.K2_SetTimerDelegate({self.actor, function() OtherActor:OnActorBeginOverlap(self.actor) end}, 0.01, false)
	end
end

function AvatarTrapComponent:Server_EndOverlapTrap_RPC(OtherActor)
    -- G.log:debug("yj", "AvatarTrapComponent Server_EndOverlapTrap_RPC OtherActor.%s.%s", OtherActor, G.GetDisplayName(OtherActor))
    if OtherActor and OtherActor.IsTrapActor then
        UE.UKismetSystemLibrary.K2_SetTimerDelegate({self.actor, function() OtherActor:OnActorEndOverlap(self.actor) end}, 0.01, false)
	end
end

decorator.message_receiver()
function AvatarTrapComponent:OnEnterTrap(TrapActor)
	-- Run On Server
	G.log:debug("yj", "%s OnEnterTrap %s IsClient.%s", self.actor:GetDisplayName(), TrapActor:GetDisplayName(), self.actor:IsClient())
    self:Client_OnEnterTrap(TrapActor)
end

decorator.message_receiver()
function AvatarTrapComponent:OnLeaveTrap(TrapActor)
	-- Run On Server
    G.log:debug("yj", "%s OnLeaveTrap %s IsClient.%s", self.actor:GetDisplayName(), TrapActor:GetDisplayName(), self.actor:IsClient())
    self:Client_OnLeaveTrap(TrapActor)
end

function AvatarTrapComponent:Client_OnEnterTrap_RPC(TrapActor)
    -- Run On Client
    G.log:debug("yj", "%s Client_OnEnterTrap %s IsClient.%s", self.actor:GetDisplayName(), TrapActor:GetDisplayName(), self.actor:IsClient())
    self:SendMessage("Client_OnEnterTrap", TrapActor)
end

function AvatarTrapComponent:Client_OnLeaveTrap_RPC(TrapActor)
    -- Run On Client
    G.log:debug("yj", "%s Client_OnLeaveTrap %s IsClient.%s", self.actor:GetDisplayName(), TrapActor:GetDisplayName(), self.actor:IsClient())
    self:SendMessage("Client_OnLeaveTrap", TrapActor)
end


return AvatarTrapComponent
