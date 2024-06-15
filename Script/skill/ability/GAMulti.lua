-- Multi segment GA, params with MaxCount and RecoverTime for one count.

local G = require("G")
local GASkillBase = require("skill.ability.GASkillBase")

local GAMulti = Class(GASkillBase)

function GAMulti:OnGive()
    --有错误先屏蔽了
    --G.log:debug("GAMulti", "OnGive, IsServer: %s", self:IsServer())

    self.LeftCount = self.MaxCount
    G.log:debug(G.GetObjectName(self), "OnGive, IsServer: %s %s %s", self.LeftCount, self.MaxCount, self.RecoverTime)
end

function GAMulti:OnRemove()
    G.log:debug("GAMulti", "OnRemove, IsServer: %s", self:IsServer())
    self:StopRecoverTimer()
end

function GAMulti:HandleActivateAbility()
    -- Left count扣除逻辑由服务端控制，客户端只同步属性，防止出现客户端和服务端恢复时间不同步的情况
    if self.OwnerActor:IsServer() then 
        self.LeftCount = self.LeftCount - 1
        self:InitRecoverTimer()
        G.log:debug(G.GetObjectName(self), "Left count: %d(%d), IsServer: %s", self.LeftCount, self.MaxCount, self:IsServer())
    end

    Super(GAMulti).HandleActivateAbility(self)
end

function GAMulti:K2_CanActivateAbility(ActorInfo, GASpecHandle, OutTags)
    if not Super(GAMulti).K2_CanActivateAbility(self, ActorInfo, GASpecHandle, OutTags) then
        return false
    end

    if self.LeftCount <= 0 then
        --G.log:debug("GAMulti", "K2_CanActivateAbility fail left count not enough, (%s)", self.LeftCount)
        return false
    end

    return true
end

function GAMulti:InitRecoverTimer()
    G.log:debug(self.__TAG__, "OnStart Timer, now left count: %d, IsServer: %s", self.LeftCount, self:IsServer())
    if self.RecoverTimerHandle and UE.UKismetSystemLibrary.K2_IsTimerActiveHandle(self, self.RecoverTimerHandle) then
        return
    end

    self.RecoverTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnRecover}, self.RecoverTime,true)
end

function GAMulti:StopRecoverTimer()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.RecoverTimerHandle)
end

function GAMulti:OnRecover()
    self.LeftCount = self.LeftCount + 1
    G.log:debug(self.__TAG__, "OnRecover Timer, now left count: %d, IsServer: %s", self.LeftCount, self:IsServer())

    if self.LeftCount >= self.MaxCount then
        self:StopRecoverTimer()
        return
    end

    -- self.LeftCount = self.LeftCount + 1
    -- G.log:debug(self.__TAG__, "OnRecover Timer, now left count: %d, IsServer: %s", self.LeftCount, self:IsServer())
end

return GAMulti
