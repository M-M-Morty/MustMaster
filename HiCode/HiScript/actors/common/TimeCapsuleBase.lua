--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

local InteractedItem = require("actors.common.interactable.base.interacted_item")

---@type BP_TimeCapsule_Base_C
local TimeCapsuleBase = Class(InteractedItem)


-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

-- function M:ReceiveBeginPlay()
-- end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

function TimeCapsuleBase:StartUICountdown(DurationTime)
    local Callback = function (Result)
        
    end
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        HudMessageCenterVM:ShowTimerDisplay(DurationTime, Callback)
    end

end

function TimeCapsuleBase:CancelUICountdown()
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        HudMessageCenterVM:CancelTimerDisplay()
    end
end


return TimeCapsuleBase
