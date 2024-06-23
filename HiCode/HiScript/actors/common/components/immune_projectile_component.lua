--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--该组件不反弹子弹，只免疫子弹的碰撞检查，反弹子弹参考使用TargetActor_ReboundProjectileSeq
--
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local utils = require("common.utils")



---@type BP_ImmuneProjectileComponent_C
local ImmuneProjectileComponent = Component(ComponentBase)
local decorator = ImmuneProjectileComponent.decorator

function ImmuneProjectileComponent:Start()
    Super(ImmuneProjectileComponent).Start(self)
    -- Continue zero gravity count by hit.
    self.IDGenerator = utils.IDGenerator()
    self.ImmuneMap:Clear()
    self.ImmuneHandlers:Clear()
end

function ImmuneProjectileComponent:ReceiveBeginPlay()
    Super(ImmuneProjectileComponent).ReceiveBeginPlay(self)
    self.__TAG__ = string.format("ImmuneProjectileComponent(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
end

decorator.message_receiver()
function ImmuneProjectileComponent:AddImmuneProjectiles(ImmuneProjectileInfo)
    local HandlerID = self.IDGenerator()
    self.ImmuneHandlers:Add(HandlerID, ImmuneProjectileInfo)
    for _, ProjectileIdentity in pairs(ImmuneProjectileInfo.ImmuneProjectileIdentities:ToTable()) do
        local Cnt = self.ImmuneMap:Find(ProjectileIdentity)
        self.ImmuneMap:Add(ProjectileIdentity,(Cnt and Cnt or 0) + 1)
    end
    G.log:info(self.__TAG__, "ImmuneProjectileComponent:AddImmuneProjectiles %s", HandlerID)
    return HandlerID
end

decorator.message_receiver()
function ImmuneProjectileComponent:RemoveImmuneProjectiles(HandlerID)
    local ImmuneProjectileInfo = self.ImmuneHandlers:Find(HandlerID)
    G.log:info(self.__TAG__, "ImmuneProjectileComponent:RemoveImmuneProjectiles %s", HandlerID)
    if not ImmuneProjectileInfo then return end
    for _, ProjectileIdentity in pairs(ImmuneProjectileInfo.ImmuneProjectileIdentities:ToTable()) do
        --self.ImmuneMap[ProjectileIdentity] = math.max((self.ImmuneMap[ProjectileIdentity] and self.ImmuneMap[ProjectileIdentity] or 0) - 1, 0)
        local Cnt = self.ImmuneMap:Find(ProjectileIdentity)
        self.ImmuneMap:Add(ProjectileIdentity, math.max((Cnt and Cnt or 0) - 1, 0))
    end
    self.ImmuneHandlers:Remove(HandlerID)
    return HandlerID
end

function ImmuneProjectileComponent:CheckImmuneProjectile(ProjectileIdentity)
    local Cnt = self.ImmuneMap:Find(ProjectileIdentity)
    return Cnt ~= nil and Cnt > 0
end

-- function M:Initialize(Initializer)
-- end

-- function M:ReceiveBeginPlay()
-- end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

return ImmuneProjectileComponent
