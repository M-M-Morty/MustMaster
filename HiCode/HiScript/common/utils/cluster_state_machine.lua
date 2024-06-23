local G = require("G")

local StateToString = {}
StateToString[Enum.Enum_MonsterClusterState.Init]       = "Init"
StateToString[Enum.Enum_MonsterClusterState.Relax]      = "Relax"
StateToString[Enum.Enum_MonsterClusterState.Alert]      = "Alert"
StateToString[Enum.Enum_MonsterClusterState.Battle]     = "Battle"
StateToString[Enum.Enum_MonsterClusterState.OutBattle]  = "OutBattle"

local StateBase = Class()

function StateBase:ctor(owner)
    self.owner = owner
    self.state = nil
end

function StateBase:enter( ... )
    -- G.log:error("yj", "StateBase %s enter %s ", self.owner.actor:GetDisplayName(), StateToString[self.state])
    self.owner:SendMessage("Cluster_EnterState", self.state)
end

function StateBase:tick( ... )
    assert(false)
end

local StateInit = Class(StateBase)
local StateRelax = Class(StateBase)
local StateAlert = Class(StateBase)
local StateBattle = Class(StateBase)
local StateOutBattle = Class(StateBase)


-- StateInit
function StateInit:ctor(owner)
    Super(StateInit).ctor(self, owner)
    self.state = Enum.Enum_MonsterClusterState.Init
end

function StateInit:enter( ... )
    Super(StateInit).enter(self, ...)
    self.owner:SendMessage("StopBT")
    self.owner:NotifySlavePauseBT()
end

function StateInit:tick(DisToTarget)
    if DisToTarget < self.owner.RelaxRadius then
        self.owner:NotifySlaveResumeBT()
        self.owner.State = StateRelax.new(self.owner)
        self.owner.State:enter()
    end
end


-- StateRelax
function StateRelax:ctor(owner)
    Super(StateRelax).ctor(self, owner)
    self.state = Enum.Enum_MonsterClusterState.Relax
end

function StateRelax:enter( ... )
    Super(StateRelax).enter(self, ...)
    self.owner:SendMessage("SwitchBT", self.owner.ClusterRelaxBT)
end

function StateRelax:tick(DisToTarget)
    if DisToTarget > self.owner.RelaxRadius then
        self.owner.State = StateInit.new(self.owner)
        self.owner.State:enter()
    elseif DisToTarget < self.owner.AlertRadius then
        self.owner.State = StateAlert.new(self.owner)
        self.owner.State:enter()
    end
end


-- StateAlert
function StateAlert:ctor(owner)
    Super(StateAlert).ctor(self, owner)
    self.state = Enum.Enum_MonsterClusterState.Alert
end

function StateAlert:enter( ... )
    Super(StateAlert).enter(self, ...)
    self.owner:SendMessage("SwitchBT", self.owner.ClusterAlertBT)
end

function StateAlert:tick(DisToTarget)
    if DisToTarget > self.owner.AlertRadius then
        self.owner.State = StateRelax.new(self.owner)
        self.owner.State:enter()
    elseif DisToTarget < self.owner.BattleRadius then
        self.owner.State = StateBattle.new(self.owner)
        self.owner.State:enter()
    end
end


-- StateBattle
function StateBattle:ctor(owner)
    Super(StateBattle).ctor(self, owner)
    self.state = Enum.Enum_MonsterClusterState.Battle
end

function StateBattle:enter( ... )
    Super(StateBattle).enter(self, ...)
    self.owner:SendMessage("SwitchBT", self.owner:GetClusterBT(self.owner.ClusterBattleBTs))
end

function StateBattle:tick(DisToTarget)
    if DisToTarget > self.owner.OutBattleRadius then
        self.owner.State = StateOutBattle.new(self.owner)
        self.owner.State:enter()
    end
end


-- StateOutBattle
function StateOutBattle:ctor(owner)
    Super(StateOutBattle).ctor(self, owner)
    self.state = Enum.Enum_MonsterClusterState.OutBattle
end

function StateOutBattle:enter( ... )
    Super(StateOutBattle).enter(self, ...)
    self.owner:SendMessage("StopBT")
    self.owner:NotifySlaveReturnToBornLocation()
end

function StateOutBattle:tick(DisToTarget)
    if self.owner:IsAnySlaveArriveBornLocation() then
        self.owner.State = StateRelax.new(self.owner)
        self.owner.State:enter()
    end
end

local M = {}
function M.InitState(owner)
    return StateInit.new(owner)
end

return M
