
-- some.field come from c++

TestModule = UE.UTestModule()

AutoTest={}

AutoTest.gIsEnableAutoTest = true
AutoTest.gIsEnableAutoTest4XUP = true

function AutoTest.GetEnableAutoTestFlag()
	local t = {}
	t[1] = AutoTest.gIsEnableAutoTest
	t[2] = AutoTest.gIsEnableAutoTest4XUP
	return t
end

function AutoTest.MoveToPoint(x, y, z)
	if TestModule ~= nil then
    	TestModule:MoveToPoint(x, y, z)
	end
end

function AutoTest.ConsoleCommand(CmdStr)
	print(CmdStr)
    TestModule:ConsoleCommand(CmdStr)
end

function AutoTest.ScreenShot(CmdStr,width,typee)
	print(CmdStr)
    TestModule:ScreenShot(CmdStr,width,typee)
end

function AutoTest.GetLuaReturnVal(var)
	if TestModule ~= nil then
		print("call GetLuaReturnVal:" .. tostring(var))
		TestModule:GetLuaReturnVal(var)
	end
end

function AutoTest.AutoTestGetMemoryDetail()
	if TestModule ~= nil then
		print("call AutoTestGetMemoryDetail")
		TestModule:AutoTestGetMemoryDetail();
	end
end

function AutoTest.AutoTestGetDrawCallDetail()
	if TestModule ~= nil then
		print("call AutoTestGetDrawCallDetail")
		TestModule:AutoTestGetDrawCallDetail();
	end
end

function AutoTest.AutoTestGetPrimitivesDetail()
	if TestModule ~= nil then
		print("call AutoTestGetPrimitivesDetail")
		TestModule:AutoTestGetPrimitivesDetail();
	end
end

function AutoTest.AutoTestGetRenderTimeDetail()
	if TestModule ~= nil then
		print("call AutoTestGetRenderTimeDetail")
		TestModule:AutoTestGetRenderTimeDetail();
	end
end

function AutoTest.AutoTestGetRuntimeStats()
	if TestModule ~= nil then
		print("call AutoTestGetRuntimeStats")
		TestModule:AutoTestGetRuntimeStats();
	end
end

function AutoTest.AutoTestGetMiscStats()
	if TestModule ~= nil then
		print("call AutoTestGetMiscStats")
		TestModule:AutoTestGetMiscStats();
	end
end

function AutoTest.RotateToFacePoint( x, y, z )
	if TestModule ~= nil then
    	TestModule:RotateToFacePoint(x,y,z)
	end
end

function AutoTest.ClickButton(path ,  duringtime,  start_x,  start_y,  end_x,  end_y,  p_TouchIndex,  p_ControllerId, screensize_x, screensize_y, usepos)
	if TestModule ~= nil then
		print("call AutoTest:ClickButton")
		TestModule:ClickButton(path ,  duringtime,  start_x,  start_y,  end_x,  end_y,  p_TouchIndex,  p_ControllerId, screensize_x, screensize_y, usepos)
	end
end

function AutoTest.Swipe(path ,  duringtime,  start_x,  start_y,  end_x,  end_y,  p_TouchIndex,  p_ControllerId, screensize_x, screensize_y)
	if TestModule ~= nil then
		print("call AutoTest:Swipe")
		TestModule:Swipe(path ,  duringtime,  start_x,  start_y,  end_x,  end_y,  p_TouchIndex,  p_ControllerId, screensize_x, screensize_y)
	end
end

function AutoTest.RegisterInputProcessor()
	if TestModule ~= nil then
		print("call AutoTest:RegisterInputProcessor")
		TestModule:RegisterInputProcessor()
	end
end

function AutoTest.StartRecordInput(cmdstr)
	if TestModule ~= nil then
		print("call AutoTest:StartRecordInput")
		TestModule:StartRecordInput(cmdstr)
	end
end

function AutoTest.StopRecordInput()
	if TestModule ~= nil then
		print("call AutoTest:StopRecordInput")
		TestModule:StopRecordInput()
	end
end

function AutoTest.StartPlayInput(filename)
	if TestModule ~= nil then
		print("call AutoTest:StartPlayInput")
		TestModule:StartPlayInput(filename)
	end
end

function AutoTest.StopPlayInput()
	if TestModule ~= nil then
		print("call AutoTest:StopPlayInput")
		TestModule:StopPlayInput()
	end
end

function AutoTest.OpenDebugg()
	if TestModule ~= nil then
		print("call AutoTest:OpenDebugg")
		TestModule:OpenDebugg()
	end
end

function AutoTest.GetPlayerLocation()
	if TestModule ~= nil then
		print("call AutoTest:GetPlayerLocation")
		TestModule:GetPlayerLocation()
	end
end

function AutoTest.GetRotation()
	if TestModule ~= nil then
		print("call AutoTest:GetRotation")
		TestModule:GetRotation()
	end
end

function AutoTest.SetRotation(Pitch, Yaw, Roll)
	if TestModule ~= nil then
		print("call AutoTest:SetRotation")
		TestModule:SetRotation(Pitch, Yaw, Roll)
	end
end

function AutoTest.PointCollect()
    local G = require("G")
    local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    local Location = Player:K2_GetActorLocation()
    G.log:error("lq","[PointCollent]%s",Location)

    local Location = p:K2_GetActorLocation()
    G.log:error("lq","[PointCollent]%s",Location)
end

function AutoTest.MultiCheckStaticMesh(Radius, DeformationDistance, CheckComplexCollisionQuery)
	if TestModule ~= nil then
		print("call AutoTest:MultiCheckStaticMesh")
		TestModule:MultiCheckStaticMesh(Radius, DeformationDistance, CheckComplexCollisionQuery)
	end
end

function AutoTest.GetPlayerControllerFromLua()
	if TestModule ~= nil then
		print("call AutoTest:GetPlayerControllerFromLua")
		TestModule:GetPlayerControllerFromLua()
	end
end

function AutoTest.TestCallLua()
	if TestModule ~= nil then
		print("call AutoTest:TestCallLua")
		local G = require("G")
		local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
		return Player
	end
end

return AutoTest
