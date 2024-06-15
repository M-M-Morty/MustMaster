--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR PanZiBin
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")

local TrapActorBalloonSmall = require("actors.common.trap.TrapActorBalloonSmall")

---@type TrapBalloon_Small_SpawnShowActor_C
local TrapBalloon_Small_SpawnShowActor = Class(TrapActorBalloonSmall)

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function TrapBalloon_Small_SpawnShowActor:ReceiveBeginPlay()
    Super(TrapBalloon_Small_SpawnShowActor).ReceiveBeginPlay(self)

    self.ShowActorSpawnPoint:SetHiddenInGame(true, false)
    self.ShowActorSpawnPoint:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    self:SetterbActive(self.bActive)
end

--重写,需要外部事件激活后碰撞触发
function TrapBalloon_Small_SpawnShowActor:OverlapByOtherActor(OtherActor)
--[[
    if not self:CanActive() then
        return false
    end
    self:RealActive(OtherActor)
    return true
]]--
end

function TrapBalloon_Small_SpawnShowActor:OnRep_bActive()
    self:SetterbActive(self.bActive)
end

function TrapBalloon_Small_SpawnShowActor:ActiveByFlowGraph(OtherActor)
    if not self:CanActive() then
        return false
    end
    self:RealActive(OtherActor)
    return true
end

function TrapBalloon_Small_SpawnShowActor:RealActive(OtherActor)
    Super(TrapBalloon_Small_SpawnShowActor).RealActive(self)
    self:TrySpawnShowActor()
    self:TryStiffnessBoss()
    self.AkSwitch = false
end

function TrapBalloon_Small_SpawnShowActor:CanActive()
    if not self.AkSwitch then
        return false
    end

    if not self:GetterbActive() then 
        return false
    end

    return true
end

--激活  外部调用
function TrapBalloon_Small_SpawnShowActor:Active(bActive, bActiveStiffness)
    self:SetterbActive(bActive, bActiveStiffness)
end

--返回是否已经激活
function TrapBalloon_Small_SpawnShowActor:GetterbActive()
    return self.bActive
end

--设置是否已经激活
function TrapBalloon_Small_SpawnShowActor:SetterbActive(bActive, bActiveStiffness)
    self:SetActorHiddenInGame(not bActive)
    self.HiddenInGame = not bActive;
    self.bActive = bActive
    self.bStiffnessStaticSwitch = bActiveStiffness
end

--尝试生成ShowActor
function TrapBalloon_Small_SpawnShowActor:TrySpawnShowActor()
    if not self.ShowActorClass then return end
    local Transform = UE.UStaticMeshComponent.K2_GetComponentToWorld(self.ShowActorSpawnPoint)
    Transform.Scale3D = UE.FVector(1,1,1)
    self.ShowActor = GameAPI.SpawnActor(self:GetWorld(), self.ShowActorClass, Transform, UE.FActorSpawnParameters(), {})
    if self.ShowActor and self.ShowActor.EventAfterSpawn then
        self.ShowActor:EventAfterSpawn(self.PlayAnimSeqInfo)
    end
end

function TrapBalloon_Small_SpawnShowActor:TryStiffnessBoss()
    -- 动态开关，由策划配置
    if not self.bStiffnessDynamicSwitch then
        return
    end

    -- 静态开关，到指定阶段之后打开
    if not self.bStiffnessStaticSwitch then
        return
    end

    local Boss = utils.GetBoss()
    Boss:SendMessage("BSM_EnterStiffness")
end


function TrapBalloon_Small_SpawnShowActor:FlyAnimationOver()
    self:SetActorHiddenInGame(true)
    self.HiddenInGame = true;
    self.AkSwitch = true;
end

function TrapBalloon_Small_SpawnShowActor:ReceiveEndPlay()
    Super(TrapBalloon_Small_SpawnShowActor).ReceiveEndPlay(self)
    if self.ShowActor then
        self.ShowActor:K2_DestroyActor()
    end
end

return TrapBalloon_Small_SpawnShowActor
