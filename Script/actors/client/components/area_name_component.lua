--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


require "UnLua"

local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

---@type AreaNameComponent_C
local AreaNameComponent = Component(ComponentBase)
local decorator = AreaNameComponent.decorator

-- function M:Initialize(Initializer)
-- end

--function AreaNameComponent:ReceiveBeginPlay()
--    Super(AreaNameComponent).ReceiveBeginPlay(self)
--    G.log:info("[hycoldrain]", "AreaNameComponent:ReceiveBeginPlay")
--end
--

decorator.message_receiver()
function AreaNameComponent:OnPlayerEnterTrigger(InActor)
    --G.log:info("[hycoldrain]", "AreaNameComponent:OnPlayerEnterTrigger--- [%s], [%s]", self, self.AreaName)    
    if not self.AreaName then
        return
    end
    
    local World = InActor:GetWorld()
    if not World then
        return
    end

    if UE.UKismetSystemLibrary.IsServer(World) then
        return
    end

    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        HudMessageCenterVM:ShowLocationTip(self.AreaName, "AoZiGu")
    end
end

decorator.message_receiver()
function AreaNameComponent:OnPlayerLeaveTrigger(InActor)
    --G.log:info("[hycoldrain]", "AreaNameComponent:OnPlayerLeaveTrigger--- [%s], [%s]", self, InActor)

end

return AreaNameComponent

