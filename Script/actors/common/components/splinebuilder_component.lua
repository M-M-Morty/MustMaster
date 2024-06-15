--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local BuildingUtils = require("common.building_system_utils")

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local InputModes = require("common.event_const").InputModes


local SplineBuilderComponent = Component(ComponentBase)

local decorator = SplineBuilderComponent.decorator

function SplineBuilderComponent:Start()
    Super(SplineBuilderComponent).Start(self)    
    --G.log:debug("hycoldrain", "SplineBuilderComponent:Start ......")    
    --self:EnableSplineBuilder(true)
end

function SplineBuilderComponent:Stop()
    Super(SplineBuilderComponent).Stop(self)            
    --G.log:debug("hycoldrain", "SplineBuilderComponent:Stop ......")    
    --self:SendMessage("UnRegisterInputHandler", InputModes.Build)    
    self:EnableSplineBuilder(false)
end

function SplineBuilderComponent:EnableSplineBuilder(bEnable)
    if self.actor:IsPlayer() then
        G.log:debug("hycoldrain", "SplineBuilderComponent:EnableSplineBuilder.....%s", tostring(bEnable))
        if bEnable then
            self:SendMessage("RegisterInputHandler", InputModes.SplineBuilder, self)
        else
            self:SendMessage("UnRegisterInputHandler", InputModes.SplineBuilder, self)
        end        
        local BuilderSubsystem = BuildingUtils.GetSubSystem()
        BuilderSubsystem:ShowSplineBuilderUI(bEnable, self.actor)        
    end
end

function SplineBuilderComponent:Attack(bPress)
    G.log:debug("hycoldrain", "SplineBuilderComponent:Attack %s", tostring(self.actor:GetName()))  
    -- If the edit mode is activated, the position of a spline point can be changed with the left mouse button.
    if bPress then
        if self.EditModeActive then
            self:StartEditing()
        else
            --Left and right mouse buttons are used here to add new spline points, delete old ones or delete the splineMeshes in Destroy Mode.
            if self.SpawnedSplineActor and self.SpawnedSplineActor:IsValid() then
                self:NewSplinePoint()
            else
                if SplineBuilderComponent.DestroyModeActive then
                    self:DestroySplineMesh()
                end
            end
        end        
    else
        if self.EditModeActive then
            self:StopEditing()
        end
    end
end


function SplineBuilderComponent:Aim(bPress)
    G.log:debug("hycoldrain", "SplineBuilderComponent:Block %s", tostring(self:GetName()))  
    -- If the edit mode is activated, the position of a spline point can be changed with the left mouse button.
    if bPress then
        if self.SpawnedSplineActor and self.SpawnedSplineActor:IsValid() then
            self:DeleteLastSplinePoint()
        end
    end
end







-- function M:Initialize(Initializer)
-- end

-- function M:ReceiveBeginPlay()
-- end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

return SplineBuilderComponent
