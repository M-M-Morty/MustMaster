--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BP_MonsterBar_Test_C
local NormalMonster = Class()

function NormalMonster:Initialize(Initializer)
    -- self.Level = 20
    -- self.LevelShow = 40
    -- self.LevelAndBar = 30
    -- self.MonsterAlert = 20
    -- self.DiscoverPlayer = 15

    -- self.HealthLimit = 250
    -- self.CurHealth = 150
    -- self.TenacityLimit = 100
    -- self.CurTenacity = 90
end

function NormalMonster:GetMonsterType()
    return self.MonsterType
end

function NormalMonster:GetLevelShowDistance()
    return self.LevelShowDis
end

function NormalMonster:GetLevelAndBarDistance()
    return self.LevelAndBarDis
end

function NormalMonster:GetMonsterAlertDistance()
    return self.MonsterAlertDis
end

function NormalMonster:GetDiscoverPlayerDistance()
    return self.DiscoverPlayerDis
end

function NormalMonster:GetLevelName()
    return "Lv." .. self.Level
end

function NormalMonster:GetHealthLimit()
    return self.HealthLimit
end

function NormalMonster:GetCurHealth()
    return self.CurHealth
end

function NormalMonster:GetTenacityLimit()
    return self.TenacityLimit
end

function NormalMonster:GetCurTenacity()
    return self.CurTenacity
end

-- function NormalMonster:UserConstructionScript()
-- end

-- function NormalMonster:ReceiveBeginPlay()
-- end

-- function NormalMonster:ReceiveEndPlay()
-- end

-- function NormalMonster:ReceiveTick(DeltaSeconds)
-- end

-- function NormalMonster:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function NormalMonster:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function NormalMonster:ReceiveActorEndOverlap(OtherActor)
-- end

return NormalMonster
