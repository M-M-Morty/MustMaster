require "UnLua"

local G = require("G")

local LevelSequenceBase = require("actors.common.sequence.level_sequence_base")

local LSBossLikaduoDie = Class(LevelSequenceBase)


function LSBossLikaduoDie:ReplaceBigBalloonEmoji()
	if not self:IsClient() then
		return
	end

    -- 替换气球emoji
    local BigBalloons = GameAPI.GetActorsWithTag(self, "TrapBalloon_Big")
    for i = 1, #BigBalloons do
        BigBalloons[i]:ReplaceEmoji()
    end
end

function LSBossLikaduoDie:PlayScreenCreditList(Delay)
	utils.DoDelay(self, Delay, function()
		local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
		local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
		local mission_system_sample = require('CP0032305_GH.Script.system_simulator.mission_system.mission_system_sample')
	    local BrgVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.BarrageVM.UniqueName)
	    BrgVM:OpenScreenCreditList(mission_system_sample:Test_ScreenCreditList())
	end)
end

return LSBossLikaduoDie
