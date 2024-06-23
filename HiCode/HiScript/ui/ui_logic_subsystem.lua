--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local UIManagerLauncher = require('CP0032305_GH.Script.Blueprints.Components.ui_manager_launcher')
---@type BP_UILogicSubsystem_C
local UILogicSubsystem = UnLua.Class()

function UILogicSubsystem:InitializeScript()

end

function UILogicSubsystem:PostInitializeScript()
    
end

function UILogicSubsystem:OnWorldBeginPlayScript()
    G.log:info("UILogicSubsystem", "OnWorldBeginPlayScript begin")
    if UE.UHiUtilsFunctionLibrary.IsSSInstanceClient() then
        if UIManagerLauncher.IsInitialized() then
            UIManagerLauncher.ResetUIManager(self)
        else
            UIManagerLauncher.DoInitUI(self)
        end
        G.log:info("UILogicSubsystem", "UIManagerLauncher init finish")
    end
end

function UILogicSubsystem:DeinitializeScript()
end



return UILogicSubsystem
 