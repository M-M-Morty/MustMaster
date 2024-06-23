--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BP_Elite_Monster_Test_C
local EliteMonster = Class()

function EliteMonster:Initialize(Initializer)
    -- self.Level = 50
    -- self.LevelShow = 40
    -- self.LevelAndBar = 30
    -- self.MonsterAlert = 20
    -- self.DiscoverPlayer = 15

    -- self.HealthLimit = 500
    -- self.CurHealth = 300
    -- self.TenacityLimit = 200
    -- self.CurTenacity = 180
end

function EliteMonster:GetMonsterType()
    return self.MonsterType
end

function EliteMonster:GetLevelShowDistance()
    return self.LevelShowDis
end

function EliteMonster:GetLevelAndBarDistance()
    return self.LevelAndBarDis
end

function EliteMonster:GetMonsterAlertDistance()
    return self.MonsterAlertDis
end

function EliteMonster:GetDiscoverPlayerDistance()
    return self.DiscoverPlayerDis
end

function EliteMonster:GetLevelName()
    return "Lv." .. self.Level
end

function EliteMonster:GetHealthLimit()
    return self.HealthLimit
end

function EliteMonster:GetCurHealth()
    return self.CurHealth
end

function EliteMonster:GetTenacityLimit()
    return self.TenacityLimit
end

function EliteMonster:GetCurTenacity()
    return self.CurTenacity
end

-- function EliteMonster:UserConstructionScript()
-- end

-- function EliteMonster:ReceiveBeginPlay()
-- end

-- function EliteMonster:ReceiveEndPlay()
-- end

-- function EliteMonster:ReceiveTick(DeltaSeconds)
-- end

-- function EliteMonster:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function EliteMonster:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function EliteMonster:ReceiveActorEndOverlap(OtherActor)
-- end

return EliteMonster
