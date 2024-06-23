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


---@type BP_SoundBlackboardComponent_C
local SoundBlackboardComponent = Component(ComponentBase)
local decorator = SoundBlackboardComponent.decorator


function SoundBlackboardComponent:Initialize(Initializer)
    Super(SoundBlackboardComponent).Initialize(self, Initializer)
    -- play poi music
    self.bAmbientSoundDirty = false
    self.bStopAmbientSound = false
    self.AmbientSound = nil

    self.bBGMDirty = false
    self.bStopBGM = false
    self.BGM = nil

    self.bDayTime = true

    --battle music
    self.bInBattle = false
    self.EnemyActor = nil

    -- play story music
    self.bInStory = false
    self.Story = nil
end

decorator.message_receiver()
function SoundBlackboardComponent:SetBattleInfo(InEnemyActor)
    --G.log:info("hycoldrain", "SoundBlackboardComponent:SetBattleInfo  %s", G.GetDisplayName(InEnemyActor))
    self.bInBattle = InEnemyActor ~= nil
    self.EnemyActor = InEnemyActor
end

decorator.message_receiver()
function SoundBlackboardComponent:SetAmbientSound(InAmbientSound, bStop)
    --G.log:info("hycoldrain", "SoundBlackboardComponent:SetAmbientSound  %s", G.GetDisplayName(InAmbientSound))
    self.bAmbientSoundDirty = true
    self.AmbientSound = InAmbientSound
    self.bStopAmbientSound = bStop
end

decorator.message_receiver()
function SoundBlackboardComponent:SetBGM(InBGM, bStop)
    G.log:info("hycoldrain", "SoundBlackboardComponent:SetBGM  %s", G.GetDisplayName(InBGM))
    self.bBGMDirty = true
    self.BGM = InBGM
    self.bStopBGM = bStop
end


decorator.message_receiver()
function SoundBlackboardComponent:SetStoryInfo(InStory)
    self.bInStory = true
    self.Story = InStory
end


return SoundBlackboardComponent
