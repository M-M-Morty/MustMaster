--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_CaseEditorCreateFile : WBP_CaseEditorCreateFile_C
---@field CaseEditorWidget WBP_CaseEditor

---@type WBP_CaseEditorCreateFile
local WBP_CaseEditorCreateFile = UnLua.Class()

local MissionActUtils = require("CP0032305_GH.Script.mission.mission_act_utils")
local Json = require("rapidjson")

local ERROR_MSG1 = "请输入文件名"

local function GetMissionRelateRootPath()
    return UE.UKismetSystemLibrary.GetProjectContentDirectory() .. MissionActUtils.MISSION_RELATE_PATH
end

---@param self WBP_CaseEditorCreateFile
local function OnClickClose(self)
    self:RemoveFromParent()
end

---@param self WBP_CaseEditorCreateFile
local function OnClickCreate(self)
    local FileName = self.EditableTextFileName:GetText()
    if string.len(FileName) > 0 then
        local Directory = GetMissionRelateRootPath()
        ---@type FFilePath
        local FilePath = UE.FFilePath()
        FilePath.FilePath = Directory..FileName..".json"
        local FileString = Json.encode({}, {pretty = true})
        local _, JsonObject = UE.UJsonBlueprintFunctionLibrary.FromString(self, FileString)
        UE.UJsonBlueprintFunctionLibrary.ToFile(JsonObject, FilePath)
        self.CaseEditorWidget:OnAddFile()
        self:RemoveFromParent()
    else
        self.TextErrorMsg:SetText(ERROR_MSG1)
        self.TextErrorMsg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

---@param CaseEditorWidget WBP_CaseEditor
function WBP_CaseEditorCreateFile:SetCaseEditorWidget(CaseEditorWidget)
    self.CaseEditorWidget = CaseEditorWidget
end

function WBP_CaseEditorCreateFile:Construct()
    self.ButtonClose.OnClicked:Add(self, OnClickClose)
    self.ButtonCreate.OnClicked:Add(self, OnClickCreate)
end

function WBP_CaseEditorCreateFile:Destruct()
    self.ButtonClose.OnClicked:Remove(self, OnClickClose)
    self.ButtonCreate.OnClicked:Remove(self, OnClickCreate)
end

return WBP_CaseEditorCreateFile
