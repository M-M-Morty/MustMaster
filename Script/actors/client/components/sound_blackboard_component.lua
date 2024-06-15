--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local utils = require("common.utils")


---@type BP_SoundBackboardComponent_C
local SoundBackboardComponent = Component(ComponentBase)
local decorator = SoundBackboardComponent.decorator


function SoundBackboardComponent:Initialize(Initializer)
    Super(SoundBackboardComponent).Initialize(self, Initializer)
    self.bInBattle = false
    self.EnemyActor = nil
end

decorator.message_receiver()
function SoundBackboardComponent:SetBattleInfo(InEnemyActor)
    --G.log:info("hycoldrain", "SoundBackboardComponent:SetBattleInfo  %s", G.GetDisplayName(InEnemyActor))
    self.bInBattle = InEnemyActor ~= nil
    self.EnemyActor = InEnemyActor
end


return SoundBackboardComponent
