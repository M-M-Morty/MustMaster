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
local ServerTable = require("common.data.server_data").data
local utils = require('common.utils')
local json = require("thirdparty.json")

---@class WBP_CustomLoginWidget : WBP_CustomLoginWidget_C

---@type WBP_CustomLoginWidget_C
local WBP_CustomLoginWidget = Class(UIWindowBase)


---@param self WBP_CustomLoginWidget
local function OnClickLogin(self)
    local GameServerSettings = UE.UHiUtilsFunctionLibrary.GetGameServerSettings()
    --local GateUrl = self.HostInput.Text .. ":" .. GameServerSettings.DefaultGatePort
    --local RealmUrl = self.HostInput.Text .. ":" .. GameServerSettings.DefaultRealmPort
    local GateUrl = self.ComboHostInput:GetSelectedOption() .. ":" .. GameServerSettings.DefaultGatePort
    local RealmUrl = self.ComboHostInput:GetSelectedOption() .. ":" .. GameServerSettings.DefaultRealmPort
    local OpenID = self.OpenIDInput.Text
    local ClientSubsystem = SubsystemUtils.GetTSF4GClientSubsystem(UIManager.GameWorld)
    ClientSubsystem:Login(GateUrl, RealmUrl, OpenID, "higame")
    self.LoginButton:SetIsEnabled(false)
    
    local UserInfo = {
        Username = OpenID,
        Host = self.ComboHostInput:GetSelectedOption()
    }
    
    pcall(function()
        local UserInfoPath = UE.UKismetSystemLibrary.GetProjectSavedDirectory() .. "userinfo.json"
        local JsonRecord = json.encode(UserInfo)
        --[[
        local File = io.open(UserInfoPath, "w")
        File:write(JsonRecord)
        io.close(File)
        --]]
        utils.SaveStringToFile(JsonRecord, UserInfoPath)
    end)
    
end

function WBP_CustomLoginWidget:Construct()
    local GameServerSettings = UE.UHiUtilsFunctionLibrary.GetGameServerSettings()
    --self.HostInput:SetText(UE.UHiUtilsFunctionLibrary.GetDefaultLoginHost())
    for ID,ServerData in pairs(ServerTable) do
        self.ComboHostInput:AddOption(tostring(ServerData.ip))
    end
    self.ComboHostInput:SetSelectedIndex(0)
    self.OpenIDInput:SetText(GameServerSettings.DefaultOpenID)
    self.LoginButton.OnClicked:Add(self, OnClickLogin)
    local ClientSubsystem = SubsystemUtils.GetTSF4GClientSubsystem(UE.UHiUtilsFunctionLibrary.GetGWorld())
    ClientSubsystem.ConnectFailDelegate:Add(self, self.OnConnectFail)
    ClientSubsystem.LoginSuccDelegate:Add(self, self.OnLoginSucc)
    ClientSubsystem.LoginFailDelegate:Add(self, self.OnLoginFail)
    ClientSubsystem.ChooseWorldDelegate:Add(self, self.OnChooseWorld)
    ClientSubsystem.DisconnectDelegate:Add(self, self.OnDisconnect)

    local Result = io.popen('git config user.name')
    local Username = Result:read("*all")
    Username = Username:gsub("%s+", "")
    if Username:match("^[a-zA-Z]+$") then
        self.OpenIDInput:SetText(Username)
    end

   
    local UserInfo = nil
    if pcall(function ()
        local UserInfoPath = UE.UKismetSystemLibrary.GetProjectSavedDirectory() .. "userinfo.json"
        --[[
        local File = io.open(UserInfoPath, "r")
        if File ~= nil then
            local JsonRecord = File:read("*all")
            UserInfo = json.decode(JsonRecord)
            io.close(File)
        end 
        --]]
        local JsonRecord = utils.LoadFileToString(UserInfoPath)  
        UserInfo = json.decode(JsonRecord)
    end) then
        if UserInfo ~= nil then
            if UserInfo.Username ~= nil then
                self.OpenIDInput:SetText(UserInfo.Username)
            end
            if UserInfo.Host ~= nil then
                --self.HostInput:SetText(UserInfo.Host)
                self.ComboHostInput:SetSelectedOption(UserInfo.Host)
            end
        end
    end
end

function WBP_CustomLoginWidget:Destruct()
    self.LoginButton.OnClicked:Remove(self, OnClickLogin)
    local ClientSubsystem = SubsystemUtils.GetTSF4GClientSubsystem(UE.UHiUtilsFunctionLibrary.GetGWorld())
    ClientSubsystem.ConnectFailDelegate:Remove(self, self.OnConnectFail)
    ClientSubsystem.LoginSuccDelegate:Remove(self, self.OnLoginSucc)
    ClientSubsystem.LoginFailDelegate:Remove(self, self.OnLoginFail)
    ClientSubsystem.ChooseWorldDelegate:Remove(self, self.OnChooseWorld)
    ClientSubsystem.DisconnectDelegate:Remove(self, self.OnDisconnect)
end

function WBP_CustomLoginWidget:OnConnectFail()
    self.LoginButton:SetIsEnabled(true)
end

function WBP_CustomLoginWidget:OnLoginSucc()
end

function WBP_CustomLoginWidget:OnLoginFail()
    self.LoginButton:SetIsEnabled(true)
end

function WBP_CustomLoginWidget:OnChooseWorld()
    self.ChooseWorldWidget = UE.UWidgetBlueprintLibrary.Create(UIManager.GameWorld, self.ChooseWorldWidgetClass)
    self.ChooseWorldWidget:AddToViewport()
end

function WBP_CustomLoginWidget:OnDisconnect()
    if self.ChooseWorldWidget ~= nil then
        self.ChooseWorldWidget:RemoveFromParent()
    end
    self.LoginButton:SetIsEnabled(true)
end
    
--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

-- function M:Construct()
-- end

--function M:Tick(MyGeometry, InDeltaTime)
--end

return WBP_CustomLoginWidget
