--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")

---@type PlayerUIInputComponent_C
local PlayerUIInputComponent = Component(ComponentBase)
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')


-- function M:ReceiveTick(DeltaSeconds)
-- end

function PlayerUIInputComponent:OnInputBoolActionTriggered(ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    G.log:debug("xaelpeng", "PlayerUIInputComponent:OnInputBoolActionTriggered %s", G.GetObjectName(InputAction))
    UIManager:DispatchActionTriggered(G.GetObjectName(InputAction), ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
end

function PlayerUIInputComponent:OnInputBoolActionStarted(ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    G.log:debug("xaelpeng", "PlayerUIInputComponent:OnInputBoolActionStarted %s", G.GetObjectName(InputAction))
    UIManager:DispatchActionStarted(G.GetObjectName(InputAction), ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
end

function PlayerUIInputComponent:OnInputBoolActionCompleted_LoadMutableActorAction(ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    G.log:debug("xaelpeng", "OnInputBoolActionCompleted_LoadMutableActorAction")
    local playerActor = G.GetPlayerCharacter(UIManager.GameWorld, 0)
    if playerActor and playerActor.EdRuntimeComponent then
        local EditorIDs = UE.TArray(UE.FString)
        local tEditorIDs = {
            41013001,
            41005013,
            41005014,
            41005015,
            41006007
        }
        for _,ActorId in ipairs(tEditorIDs) do
            EditorIDs:Add(tostring(ActorId))
        end
        playerActor.EdRuntimeComponent:Server_LoadMutableActorAction(EditorIDs)
    end
end

function PlayerUIInputComponent:OnInputBoolActionCompleted(ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    local ActionName = G.GetObjectName(InputAction)
    local ActionCallbackName = "OnInputBoolActionCompleted_"..ActionName
    if self[ActionCallbackName] then
        self[ActionCallbackName](ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    end
    G.log:debug("xaelpeng", "PlayerUIInputComponent:OnInputBoolActionCompleted %s", ActionName)
    UIManager:DispatchActionCompleted(G.GetObjectName(InputAction), ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
end

function PlayerUIInputComponent:OnInputBoolActionCanceled(ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    G.log:debug("xaelpeng", "PlayerUIInputComponent:OnInputBoolActionCanceled %s", G.GetObjectName(InputAction))
    UIManager:DispatchActionCanceled(G.GetObjectName(InputAction), ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
end

function PlayerUIInputComponent:OnInputFloatActionTriggered(ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    G.log:debug("xaelpeng", "PlayerUIInputComponent:OnInputFloatActionTriggered %s", G.GetObjectName(InputAction))
    UIManager:DispatchActionTriggered(G.GetObjectName(InputAction), ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
end

function PlayerUIInputComponent:OnInputFloatActionStarted(ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    G.log:debug("xaelpeng", "PlayerUIInputComponent:OnInputFloatActionStarted %s", G.GetObjectName(InputAction))
    UIManager:DispatchActionStarted(G.GetObjectName(InputAction), ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
end

function PlayerUIInputComponent:OnInputFloatActionCompleted(ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    G.log:debug("xaelpeng", "PlayerUIInputComponent:OnInputFloatActionCompleted %s", G.GetObjectName(InputAction))
    UIManager:DispatchActionCompleted(G.GetObjectName(InputAction), ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
end

function PlayerUIInputComponent:OnInputFloatActionCanceled(ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
    G.log:debug("xaelpeng", "PlayerUIInputComponent:OnInputFloatActionCanceled %s", G.GetObjectName(InputAction))
    UIManager:DispatchActionCanceled(G.GetObjectName(InputAction), ActionValue, ElapsedSeconds, TriggeredSeconds, InputAction)
end


function PlayerUIInputComponent:OnSwitchPlayer(index)
    local PlayerController = self.actor.PlayerState:GetPlayerController()
    if PlayerController then
        PlayerController:SendMessage("Input_SwitchPlayer", index, false)
    end
end

function PlayerUIInputComponent:OnSwitchAllMonsterBT()
    self:SendMessage("SwitchAllMonsterBT")
end

return PlayerUIInputComponent
