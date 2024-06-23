--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local mission_widget_test = require('CP0032305_GH.Script.system_simulator.mission_system.mission_widget_test')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")

---@type BP_ThrowPointWidget_C
local M = Component(ComponentBase)
local decorator = M.decorator

-- function M:Initialize(Initializer)
-- end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    local mesh = self:GetOwner().Mesh or self:GetOwner().StaticMesh
    if not mesh then
        mesh = self.MeshComponent
    end
    local Origin, BoxExtent = UE.UKismetSystemLibrary.GetComponentBounds(mesh)
    local Z = BoxExtent.Z
    if BoxExtent.Z <= 10 and self:GetOwner().GeometryCollectionComponent then
        Origin, BoxExtent = UE.UKismetSystemLibrary.GetComponentBounds(self:GetOwner().GeometryCollectionComponent)
        Z = BoxExtent.Z
    end
    local Loc = self:GetOwner():K2_GetActorLocation()
    Loc.Z = Origin.Z + self.PosOffset * Z
    self:K2_SetWorldLocation(Loc, false, UE.FHitResult(), true)
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

decorator.message_receiver()
function M:ShowCapture(bShow)
    --G.log:debug("zys", table.concat({"M:ShowCapture() bShow", tostring(bShow)}))
    if not self:GetOwner():HasAuthority() then
        local widget = self:GetWidget()
        if widget and widget.SetPointVisible then
            widget:SetPointVisible(bShow)
        end
    end
end

return M
