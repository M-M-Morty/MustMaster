--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require('G')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local SubsystemUtils = require('common.utils.subsystem_utils')
local LevelTable = require("common.data.level_data").data

---@class WBP_SelectWorldWidget : WBP_SelectWorldWidget_C

---@type WBP_SelectWorldWidget_C
local WBP_SelectWorldWidget = Class(UIWindowBase)

---@param self WBP_SelectWorldWidget
local function OnClickSameWorld(self)
    self:TryEnterWorld(1)
end

---@param self WBP_SelectWorldWidget
local function OnClickOwnWorld(self)
    self:TryEnterWorld(0)
end

function WBP_SelectWorldWidget:Construct()
    local GameServerSettings = UE.UHiUtilsFunctionLibrary.GetGameServerSettings()
    local GameplayEntitySubsystem = SubsystemUtils.GetGameplayEntitySubsystem(UIManager.GameWorld)
    local CurrentDungeonID = GameplayEntitySubsystem:K2_GetDungeonID()
    self.DungeonIDList = {}
    for DungeonID, LevelData in pairs(LevelTable) do
        if UE.UHiUtilsFunctionLibrary.IsWithEditor() or LevelData.release then
            table.insert(self.DungeonIDList, DungeonID)
        end
    end

    table.sort(self.DungeonIDList)
    local SelectedIndex = 1
    for Index, DungeonID in ipairs(self.DungeonIDList) do
        local LevelData = LevelTable[DungeonID]
        self.MapSelectComboBox:AddOption(tostring(DungeonID) .. ":" .. LevelData.name)
        if CurrentDungeonID == DungeonID then
            SelectedIndex = Index
        end
    end

    G.log:debug("xaelpeng", "WBP_SelectWorldWidget:Construct CurrentDungeonID:%s", CurrentDungeonID)
    self.MapSelectComboBox:SetSelectedIndex(SelectedIndex - 1)
    
    self.SameWorldButton.OnClicked:Add(self, OnClickSameWorld)
    self.OwnWorldButton.OnClicked:Add(self, OnClickOwnWorld)
    
end

function WBP_SelectWorldWidget:TryEnterWorld(bEnterShared)
    local ClientSubsystem = SubsystemUtils.GetTSF4GClientSubsystem(UIManager.GameWorld)
    local FirstSpaceID = UE.UHiUtilsFunctionLibrary.GetClientEnterSpaceID()
    local PlayMode = UE.UHiUtilsFunctionLibrary.GetClientPlayMode()
    local Index = self.MapSelectComboBox:GetSelectedIndex()
    local DungeonID = self.DungeonIDList[Index + 1]
    G.log:debug("xaelpeng", "WBP_SelectWorldWidge:TryEnterWorld DungeonID:%s", DungeonID)
    ClientSubsystem:ServiceTryEnterWorld(bEnterShared, DungeonID, PlayMode, FirstSpaceID)
    self.SameWorldButton:SetIsEnabled(false)
    self.OwnWorldButton:SetIsEnabled(false)
end
--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

-- function M:Construct()
-- end

--function M:Tick(MyGeometry, InDeltaTime)
--end

return WBP_SelectWorldWidget
