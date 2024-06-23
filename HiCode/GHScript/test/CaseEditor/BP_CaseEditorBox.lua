--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class BP_CaseEditorBox : BP_CaseEditorBox_C

---@type BP_CaseEditorBox
local BP_CaseEditorBox = UnLua.Class()

local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function BP_CaseEditorBox:ReceiveBeginPlay()
    if not self:HasAuthority() then
        self.TriggerBox.OnComponentBeginOverlap:Add(self, self.TriggerBox_OnComponentBeginOverlap)
        self.TriggerBox.OnComponentEndOverlap:Add(self, self.TriggerBox_OnComponentEndOverlap)
    end
end

function BP_CaseEditorBox:ReceiveEndPlay()
    if not self:HasAuthority() then
        self.TriggerBox.OnComponentBeginOverlap:Remove(self, self.TriggerBox_OnComponentBeginOverlap)
        self.TriggerBox.OnComponentEndOverlap:Remove(self, self.TriggerBox_OnComponentEndOverlap)
    end
end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param OtherBodyIndex integer
---@param bFromSweep boolean
---@param SweepResult FHitResult
function BP_CaseEditorBox:TriggerBox_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not self:HasAuthority() then
        print("BP_CaseEditorBox:TriggerBox_OnComponentBeginOverlap")
        local Path = PathUtil.getFullPathString(self.CaseEditorWbpClass)
        local WBPClass = LoadObject(Path)
        ---@type WBP_CaseEditor_C
        self.WBPCaseEditor = NewObject(WBPClass, self)
        --local controller = UE.UGameplayStatics.GetPlayerController(self, 0)
        self.WBPCaseEditor:AddToViewport(100)
        self.WBPCaseEditor:SetOwnerTrigger(self)
    end
end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param OtherBodyIndex integer
function BP_CaseEditorBox:TriggerBox_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if not self:HasAuthority() and self.WBPCaseEditor then
        self.WBPCaseEditor:RemoveFromParent()
    end
end
-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

return BP_CaseEditorBox
