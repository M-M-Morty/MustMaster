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

---@type TeleportComponent_C
local NiagaraSlotComponent = Component(ComponentBase)

local decorator = NiagaraSlotComponent.decorator


function NiagaraSlotComponent:ReceiveBeginPlay()
    Super(NiagaraSlotComponent).ReceiveBeginPlay(self)

    for idx = 1, self.NiagaraComponentNum do
    	local NiagaraComponent = NewObject(UE.UNiagaraComponent, self)
    	UE.UHiUtilsFunctionLibrary.RegisterComponent(NiagaraComponent)
    	NiagaraComponent.bAutoManageAttachment = true

    	self.NiagaraComponentArray:Add(NiagaraComponent)
    end

    self.CurrentArrayIdx = 0
end

function NiagaraSlotComponent:GetNextValidNiagaraComponent()
	self.CurrentArrayIdx = self.CurrentArrayIdx + 1
	if self.CurrentArrayIdx > self.NiagaraComponentArray:Length() then
		self.CurrentArrayIdx = 1
	end

	-- G.log:debug("yj", "NiagaraSlotComponent:GetNextValidNiagaraComponent %s NiagaraComponentNum.%s %s", self.CurrentArrayIdx, self.NiagaraComponentNum, self.NiagaraComponentArray:Length())
	return self.NiagaraComponentArray:Get(self.CurrentArrayIdx)
end

return NiagaraSlotComponent

