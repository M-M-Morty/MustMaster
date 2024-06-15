require "UnLua"

local G = require("G")

local LevelSequenceBase = require("actors.common.sequence.level_sequence_base")

local LSMessagePop = Class(LevelSequenceBase)


function LSMessagePop:PlayMessagePop()
	if not self:IsClient() then
		return
	end

    -- 处决弹幕
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    -- tmp args
    HudMessageCenterVM:ShowPreBarrage(5.3,4,7,7,9.3,9.3,14.10,0.7,0.3,0.3,0.1)
end

return LSMessagePop
