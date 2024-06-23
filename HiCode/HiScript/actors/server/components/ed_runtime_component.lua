local string = require("string")
local EdUtils = require("common.utils.ed_utils")
local OutlinerUtils = require("common.utils.Outliner_utils")
local table = require("table")
local G = require("G")
local GameAPI = require("common.game_api")
-- local UIManager = require('ui.ui_manager')
local utils = require("common.utils")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local NpcInteractItemModule = require("mission.npc_interact_item")
local ConstTextTable = require("common.data.const_text_data").data
local GameConstData = require("common.data.game_const_data").data

local M = Component(ComponentBase)

local decorator = M.decorator

function M:LogInfo(...)
    G.log:info_obj(self, ...)
end

function M:LogDebug(...)
    G.log:debug_obj(self, ...)
end

function M:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function M:LogError(...)
    G.log:error_obj(self, ...)
end

 function M:Initialize(Initializer)
    Super(M).Initialize(self, Initializer)
 end

 function M:ReceiveBeginPlay()
     Super(M).ReceiveBeginPlay(self)
 end

function M:ReceiveEndPlay()
    Super(M).ReceiveEndPlay(self)
end

-- function M:ReceiveTick(DeltaSeconds)
-- end

function M:HasAuthority()
    local owner = self:GetOwner()
    return owner and owner:HasAuthority() or false
end

function M:GetOwnerActorLabel()
    local owner = self:GetOwner()
    return owner and G.GetDisplayName(owner) or 'Unknow OwnerActor'
end

function M:GetOwnerController()
    local owner = self:GetOwner()   ---@type APawn
    if owner and owner.GetController then
        return owner:GetController()
    end
end

function M:IsOwnerControllerLocalPlayer()
    local controller = self:GetOwnerController()
    return controller and controller:IsLocalPlayerController() or false
end

function M:AddEditorActor(EditorActor)
    if self:IsOwnerControllerLocalPlayer() then
        local Owner = self:GetOwner()   ---@type APawn
        if Owner and Owner:IsClient() then
            local EditorID = EditorActor:GetEditorID()
            if EditorID then
                EdUtils.mapEdActors[EditorID] = EditorActor
                for EdID,Actor in pairs(EdUtils.mapEdActors) do
                    if Actor and UE.UKismetSystemLibrary.IsValid(Actor) then
                        if Actor.CheckChildReady then
                            Actor:CheckChildReady()
                        end
                    else -- released object
                        EdUtils.mapEdActors[EdID] = nil
                    end
                end
            end
        end
    end
end

function M:RemoveEditorActor(EditorActor)
    if self:IsOwnerControllerLocalPlayer() then
        local EditorID = EditorActor:GetEditorID()
        if EditorID then
            EdUtils.mapEdActors[EditorID] = nil
        end
    end
end

function M:GetEditorActor(EditorID)
    if self:IsOwnerControllerLocalPlayer() then
        if EditorID then
            local EdActor = EdUtils.mapEdActors[EditorID]
            if EdActor and not UE.UKismetSystemLibrary.IsValid(EdActor) then -- released object
                EdUtils.mapEdActors[EditorID] = nil
                EdActor = nil
            end
            return EdActor
        end
    end
end

function M:RemoveAllInteractedUI()
    self.arrClientNearbyActors:Clear()
    self:UpdateInteractItems(self.arrClientNearbyActors)
end

---@param nearbyActor AActor
function M:AddNearbyActor(nearbyActor)
    if self:IsOwnerControllerLocalPlayer() then
        self.arrClientNearbyActors:AddUnique(nearbyActor)
        self:UpdateInteractItems(self.arrClientNearbyActors)
        -- UIManager:UpdateInteractiveUI(self.arrClientNearbyActors, self)
    end
    self:LogInfo('zsf', 'player %s enter %s pick radius (%s)', self:GetOwnerActorLabel(), G.GetDisplayName(nearbyActor), self.arrClientNearbyActors:Length())
end

---@param nearbyActor AActor
function M:RemoveNearbyActor(nearbyActor)
    if not self.arrClientNearbyActors:Contains(nearbyActor) then
        -- 不在arrClientNearbyActors里的直接返回，避免触发后续UpdateInteractItems
        return
    end
    if self:IsOwnerControllerLocalPlayer() then
        self.arrClientNearbyActors:RemoveItem(nearbyActor)
        self:UpdateInteractItems(self.arrClientNearbyActors)
        -- UIManager:UpdateInteractiveUI(self.arrClientNearbyActors, self)
    end
    self:LogInfo('zsf', 'player %s leave %s pick radius (%s)', self:GetOwnerActorLabel(), G.GetDisplayName(nearbyActor), self.arrClientNearbyActors:Length())
end

function M:UpdateInteractItems(nearbyActors)
    local tbItem = {}
    local cnt = 1
    local bNotSort
    local ForceIndex
    for i = 1, nearbyActors:Num() do
        ---@type AActor
        local actorInstance = nearbyActors:Get(i)
        if actorInstance and actorInstance.GetUIShowActors then
            local Actors = actorInstance:GetUIShowActors()
            for _,Actor in ipairs(Actors) do
                if ForceIndex == nil then
                    ForceIndex = Actor.ForceIndex
                end
                if bNotSort == nil then
                    bNotSort = Actor.bNotSort
                end
                local splite_str, sUI = ". ", tostring(Actor.sUIPick)
                local index = sUI:find(splite_str)
                if index and index > 0 then
                    sUI = sUI:sub(index+2)
                end
                --Actor.sUIPick = tostring(cnt)..splite_str..sUI
                cnt = cnt + 1
                local function ItemSelectecCallback()
                    local localPlayerActor = self.actor
                    if localPlayerActor then
                        Actor:DoClientInteractAction(localPlayerActor)
                    end
                end
                local ShowUIPick = Actor.sUIPick
                if ConstTextTable[ShowUIPick] ~= nil then
                    ShowUIPick = ConstTextTable[ShowUIPick].Content
                end
                local Item = NpcInteractItemModule.DefaultInteractEntranceItem.new(Actor, ShowUIPick, ItemSelectecCallback, self:GetActorInteractType(Actor))
                if Actor.sUIIcon then
                    local Path = UE.UKismetSystemLibrary.GetPathName(Actor.sUIIcon)
                    Item:SetDisplayIconPath(Path)
                end
                if Actor.bUseable ~= nil then
                    Item:SetUsable(Actor.bUseable)
                end
                table.insert(tbItem, Item)
            end
        end
    end
    if self.actor.PlayerUIInteractComponent ~= nil then
        self.actor.PlayerUIInteractComponent:UpdateInteractItems(tbItem, bNotSort, ForceIndex)
    end
end

function M:hasClientNearbyActor()
    return self.arrClientNearbyActors:Num() > 0
end

function M:GetActorInteractType(actor)
    if actor.eInteractType == nil then
        return Enum.Enum_InteractType.Normal
    end
    return actor.eInteractType
end

---@param InvokerActor AActor
---@param InteractLocation Vector
function M:ProcessServerInteract(InvokerActor, Damage, InteractLocation)
    if self:HasAuthority() then
        if InvokerActor and InvokerActor.DoServerInteractAction then
            InvokerActor:DoServerInteractAction(self:GetOwner(), Damage, InteractLocation)
        end
    end
end

function M:MissionComplete(eMiniGame, sData)
    local json = require("thirdparty.json")
    local Param = {
        eMiniGame=eMiniGame,
        sData=sData
    }
    local Data=json.encode(Param)
    self.Event_MissionComplete:Broadcast(Data)
end

return M
