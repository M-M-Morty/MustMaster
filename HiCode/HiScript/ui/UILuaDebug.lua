require "UnLua"
local G = require("G")
local t = require("t")
local UILuaDebug = Class()

local UObjectStrMap = {
	["UE.UHiUtilsFunctionLibrary"] = UE.UHiUtilsFunctionLibrary,
	["UE.UUnLuaFunctionLibrary"] = UE.UUnLuaFunctionLibrary,
	["UE.UGameplayStatics"] = UE.UGameplayStatics,
	["UE.UKismetMathLibrary"] = UE.UKismetMathLibrary,
	["UE.UWidgetBlueprintLibrary"] = UE.UWidgetBlueprintLibrary,
	["UE.UKismetSystemLibrary"] = UE.UKismetSystemLibrary,
}


function UILuaDebug:Construct()
    self.Overridden.Construct(self)

    self.HistoryCmd = {}
    self.OutputCmd = {}
    self.CmdMatchs = {}

    self.UECmds = {}
    self.LuaCmds = t.LuaCmds

    self.CurSelectIndex = 1
    self.InputBySelect = false
    self.SelectHistoryCmd = true

    self:OnModeChange()
end

function UILuaDebug:OnModeChange()
    if self.bIsClient == true then
        self.bIsClient = false
		self.Cmd_Input:SetHintText("Input Cmd (Server)")
    else
        self.bIsClient = true
		self.Cmd_Input:SetHintText("Input Cmd (Client)")
    end
	self.Cmd_Input:SetText("")
end

function UILuaDebug:OnTextChanged(Text)
    if not self:IsVisible() then
        return
    end

	if string.sub(Text, 1, 1) == "`" then
		self:OnModeChange()
		return
	end

    if string.find(Text, "\r\n") ~= nil then
    	-- CRLF
    	self:_DoCmd(Text)
    else
    	self:_MatchCmd(Text)
	end
end

function UILuaDebug:_DoCmd(Text)
	if string.sub(Text, 1, 5) == "close" then
	    local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
	    -- close lua debug
		Player:SendControllerMessage("CallLuaDebugWidget")
		return
	end

	if string.len(Text) > 2 then
		local Cmd = Text
		local _start, _end = string.find(Text, "\r\n")
		if _start then
			local Cmd = string.sub(Text, 1, _start - 1)..string.sub(Text, _end + 1, -1)
		end
		table.insert(self.HistoryCmd, Cmd)
		--table.insert(self.OutputCmd, Cmd)

		local LuaCmdInfo = self:GetLuaCmdInfo(Cmd)
		if LuaCmdInfo then
			local Side = LuaCmdInfo[1]
			if Side == t.ClientOnly then
				self:DoClientCmd(Cmd)
			elseif Side == t.ServerOnly then
				self:DoServerCmd(Cmd)
			elseif Side == t.ServerAndClient then
				self:DoClientCmd(Cmd)
				self:DoServerCmd(Cmd)
			end
		else
			if self.bIsClient then
				self:DoClientCmd(Cmd)
			else
				self:DoServerCmd(Cmd)
			end
		end
	end
    
	--table.insert(self.OutputCmd, self.String)
	--self.Cmd_Output:SetText(self:GenCmdBGText())
	--self.Cmd_Output:SetText(self:GenCmdOPText())

	self.Cmd_Input:SetText("")
	self.Cmd_History:SetText(self:GenCmdBGText())

	self.CurSelectIndex = 1
	self.SelectHistoryCmd = true
end

function UILuaDebug:DoClientCmd(Cmd)
    local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    Player:DoConsoleCmd(Cmd)
end

function UILuaDebug:DoServerCmd(Cmd)
    local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    Player:Server_DoConsoleCmd(Cmd)
end

function UILuaDebug:GenCmdBGText()
	local MaxLoop = 20
	local CmdBG_Text = ""
	for i = #self.HistoryCmd, 1, -1 do
		CmdBG_Text = ">> "..self.HistoryCmd[i].."\r\n"..CmdBG_Text
		MaxLoop = MaxLoop - 1
		if MaxLoop == 0 then
			break
		end
	end

	return CmdBG_Text
end

function UILuaDebug:GenCmdOPText()
	local MaxLoop = 20
	local CmdOP_Text = ""
	for i = #self.OutputCmd, 1, -1 do
		CmdOP_Text = ">> "..self.OutputCmd[i].."\r\n"..CmdOP_Text
		MaxLoop = MaxLoop - 1
		if MaxLoop == 0 then
			break
		end
	end

	return CmdOP_Text
end

function UILuaDebug:_MatchCmd(Text)
	if self.InputBySelect then
		return
	end

	if string.len(Text) > 0 then

		self.SelectHistoryCmd = false

		if string.sub(Text, -1, -1) == "(" or string.sub(Text, -2, -2) == "(" then
			-- "(" is a magic character in lua
			self.Cmd_Match:SetVisibility(2)
			return
		end

		if string.sub(Text, -1, -1) == ":" then
			self:GenBlueprintCallableCmds(Text)
			self:GenLuaCallableCmds(Text)
		elseif string.sub(Text, -1, -1) == "." then
			self:GenComponents(Text)
		end

		if string.find(Text, "%:") ~= nil then
			self:BlueprintCallableCmdMatch(Text)
		elseif string.find(Text, "%.") ~= nil then
			self:ComponentMatch(Text)
		else
			self:LuaCmdMatch(Text)
		end

		self.CurSelectIndex = 1

		if #self.CmdMatchs > 0 then
			self.Cmd_Match:SetText(self:GenMatchCmdBGText())
			self.Cmd_Match:SetVisibility(0)
		else
			self.Cmd_Match:SetVisibility(2)
		end

	else
		self.SelectHistoryCmd = true
		self.Cmd_Match:SetText("")
		self.Cmd_Match:SetVisibility(2)
	end
end

function UILuaDebug:GenBlueprintCallableCmds(Pattern)
	self.UECmds = {}

	if Pattern == "UE." then
		for key, _ in pairs(UObjectStrMap) do
			table.insert(self.UECmds, key)
		end
	else
		local CallableFunctionNames = UE.TSet(UE.FString)

		local ObjectStr = self:GetObjectStr(Pattern)
		local Object = self:_GetUObjectByStr(ObjectStr)
		if Object == nil then
			local LoadStr = ""
			LoadStr = LoadStr.."if UE.UKismetSystemLibrary.IsValid("..ObjectStr..") then "
			LoadStr = LoadStr.."	return UE.UHiUtilsFunctionLibrary.ObjectGetAllCallableFunctionNames("..ObjectStr..") "
			-- LoadStr = LoadStr.."else"
			-- LoadStr = LoadStr.."	return UE.TSet(UE.FString) "
			LoadStr = LoadStr.."end"
			local hi = load(LoadStr)
			if hi ~= nil then
				CallableFunctionNames = hi()
			end
		else
			if UE.UKismetSystemLibrary.IsValid(Object) then
				CallableFunctionNames = UE.UHiUtilsFunctionLibrary.ObjectGetAllCallableFunctionNames(Object)
			end
		end

		local Array = CallableFunctionNames:ToArray()
		for i = 1, Array:Length() do
			table.insert(self.UECmds, Pattern..Array:Get(i))
    	end
	end
end

function UILuaDebug:GenLuaCallableCmds(Pattern)
	local ObjectStr = self:GetObjectStr(Pattern)
	local LoadStr = ""
	LoadStr = LoadStr.."	return utils.GetFunctionNames("..ObjectStr..")"

	FunctionsNames = {}
	local hi = load(LoadStr)
	if hi ~= nil then
		FunctionsNames = hi()
	end
	
	-- print("[" .. table.concat(FunctionsNames, ",") .. "]")

	for idx, name in pairs(FunctionsNames) do
		table.insert(self.UECmds, Pattern..name)
	end

	if #self.UECmds == 0 then
	    table.insert(self.UECmds, Pattern.." !!! prefix invalid, please check input")
	end
end

function UILuaDebug:GenComponents(Pattern)
	self.UECmds = {}

	local ObjectStr = self:GetObjectStr(Pattern)
	local LoadStr = ""
	LoadStr = LoadStr.."if UE.UKismetSystemLibrary.IsValid("..ObjectStr..") and "..ObjectStr..".GetBlueprintComponents then "
	LoadStr = LoadStr.."	return "..ObjectStr..":GetBlueprintComponents()"
	LoadStr = LoadStr.."else"
	LoadStr = LoadStr.."	return {}"
	LoadStr = LoadStr.."end"

	Components = {}
	local hi = load(LoadStr)
	if hi ~= nil then
		Components = hi()
	end

	for name, _ in pairs(Components) do
		table.insert(self.UECmds, Pattern..name)
	end

	if #self.UECmds == 0 then
	    table.insert(self.UECmds, Pattern.." !!! prefix invalid, please check input")
	end

	-- print("[" .. table.concat(self.UECmds, ",") .. "]")
end

function UILuaDebug:GetObjectStr(Pattern)
	local StartIdx = string.find(Pattern, "=") or string.find(Pattern, "%(")
	if StartIdx == nil then
		StartIdx = 1
	else
		StartIdx = StartIdx + 1
		while string.sub(Pattern, StartIdx, StartIdx) == " " do
			StartIdx = StartIdx + 1
		end
	end

	local ObjectStr = string.sub(Pattern, StartIdx, -2)	

	return ObjectStr
end

function UILuaDebug:_GetUObjectByStr(ObjectStr)
	if UObjectStrMap[ObjectStr] ~= nil then
		return UObjectStrMap[ObjectStr]
	else
		return rawget(_G, ObjectStr)
	end
end

function UILuaDebug:LuaCmdMatch(Pattern)
	self.CmdMatchs = {}
	for Cmd, _ in pairs(self.LuaCmds) do
		local s, _ = string.find(Cmd, Pattern)
		if s == 1 then
			table.insert(self.CmdMatchs, Cmd)
		end
	end
end

function UILuaDebug:GetLuaCmdInfo(Cmd)
	local s, _ = string.find(Cmd, "%(", 1)
	if s ~= nil then
		return self.LuaCmds[string.sub(Cmd, 1, s - 1)]
	else
		return self.LuaCmds[Cmd]
	end
end

function UILuaDebug:BlueprintCallableCmdMatch(Pattern)
	-- PC(1) -> PC%(1)
	local StartIdx, MaxLoop = 1, 100
	while MaxLoop > 0 do
		local s, e = string.find(Pattern, "%(", StartIdx)
		if s ~= nil then
			Pattern = string.sub(Pattern, 1, s - 1).."%"..string.sub(Pattern, s, -1)
			StartIdx = e + 2
			MaxLoop = MaxLoop - 1
		else
			break
		end
	end

	-- PC%(1) -> PC%(1%)
	StartIdx, MaxLoop = 1, 100
	while MaxLoop > 0 do
		local s, e = string.find(Pattern, "%)", StartIdx)
		if s ~= nil then
			Pattern = string.sub(Pattern, 1, s - 1).."%"..string.sub(Pattern, s, -1)
			StartIdx = e + 2
			MaxLoop = MaxLoop - 1
		else
			break
		end
	end

	self.CmdMatchs = {}
	for i = 1, #self.UECmds, 1 do
		local Cmd = self.UECmds[i]
		local s, _ = string.find(Cmd, Pattern)
		if s == 1 then
			table.insert(self.CmdMatchs, Cmd)
		end
	end
end

function UILuaDebug:ComponentMatch(Pattern)
	self:BlueprintCallableCmdMatch(Pattern)
end

function UILuaDebug:SelectPreCmd()
	self.InputBySelect = true

	if self.SelectHistoryCmd then
		self:SelectPreHistoryCmd()
	else
		self:SelectPreMatchCmd()
	end

	self.InputBySelect = false
end

function UILuaDebug:SelectNextCmd()
	self.InputBySelect = true

	if self.SelectHistoryCmd then
		self:SelectNextHistoryCmd()
	else
		self:SelectNextMatchCmd()
	end

	self.InputBySelect = false
end

function UILuaDebug:SelectPreHistoryCmd()
	if #self.HistoryCmd == 0 then
		return
	end

	self.CurSelectIndex = self.CurSelectIndex - 1

	if self.CurSelectIndex == 0 then
		self.CurSelectIndex = #self.HistoryCmd
	end

	-- G.log:debug("yj", "UILuaDebug:SelectPreCmd %s", table.concat(self.HistoryCmd, ","))
	self.Cmd_Input:SetText(self.HistoryCmd[self.CurSelectIndex])
end

function UILuaDebug:SelectNextHistoryCmd()
	if #self.HistoryCmd == 0 then
		return
	end

	self.CurSelectIndex = self.CurSelectIndex + 1

	if self.CurSelectIndex == #self.HistoryCmd + 1 then
		self.CurSelectIndex = 1
	end

	-- G.log:debug("yj", "UILuaDebug:SelectNextCmd %s", table.concat(self.HistoryCmd, ","))
	self.Cmd_Input:SetText(self.HistoryCmd[self.CurSelectIndex])
end

function UILuaDebug:SelectPreMatchCmd()
	if #self.CmdMatchs == 0 then
		return
	end

	self.CurSelectIndex = self.CurSelectIndex - 1

	if self.CurSelectIndex == 0 then
		self.CurSelectIndex = #self.CmdMatchs
	end

	-- G.log:debug("yj", "UILuaDebug:SelectPreCmd %s", self.CmdMatchs[self.CurSelectIndex])
	self.Cmd_Input:SetText(self.CmdMatchs[self.CurSelectIndex])
	self.Cmd_Match:SetText(self:GenMatchCmdBGText())
end

function UILuaDebug:SelectNextMatchCmd()
	if #self.CmdMatchs == 0 then
		return
	end

	self.CurSelectIndex = self.CurSelectIndex + 1

	if self.CurSelectIndex == #self.CmdMatchs + 1 then
		self.CurSelectIndex = 1
	end

	-- G.log:debug("yj", "UILuaDebug:SelectNextCmd %s", self.CmdMatchs[self.CurSelectIndex])
	self.Cmd_Input:SetText(self.CmdMatchs[self.CurSelectIndex])
	self.Cmd_Match:SetText(self:GenMatchCmdBGText())
end

function UILuaDebug:GenMatchCmdBGText()
	local MaxNum = 35
	local MatchCmdBG_Text = ""

	if self.CurSelectIndex <= MaxNum then
		for i = math.min(#self.CmdMatchs, MaxNum), 1, -1 do
			if self.CurSelectIndex == i then
				MatchCmdBG_Text = "->  "..self.CmdMatchs[i].."\r\n"..MatchCmdBG_Text
			else
				MatchCmdBG_Text = "    "..self.CmdMatchs[i].."\r\n"..MatchCmdBG_Text
			end
		end
	else
		for i = self.CurSelectIndex, self.CurSelectIndex - MaxNum + 1, -1 do
			if self.CurSelectIndex == i then
				MatchCmdBG_Text = "->  "..self.CmdMatchs[i].."\r\n"..MatchCmdBG_Text
			else
				MatchCmdBG_Text = "    "..self.CmdMatchs[i].."\r\n"..MatchCmdBG_Text
			end
		end
	end

	return MatchCmdBG_Text
end


return UILuaDebug
