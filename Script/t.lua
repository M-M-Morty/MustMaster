local G = require("G")
local decorator = require("common.decorator").new()
local state_conflict_data = require("common.data.state_conflict_data")
local OfficeConst = require("common.const.office_const")
local BPConst = require("common.const.blueprint_const")
local GlobalActorConst = require ("common.const.global_actor_const")
local DialogueObjectModule = require("mission.dialogue_object")
local EdUtils = require("common.utils.ed_utils")
local SubsystemUtils = require("common.utils.subsystem_utils")


local ServerOnly = 1
local ClientOnly = 2
local ServerAndClient = 3

local t = setmetatable({}, 
{
	__index = _G,
	__newindex = function (t, k, v)
					v = decorator:Execute(t, k, v)
                    if rawget(_G, k) == nil or type(v) == "function" then
                        -- 设置到_G中，方便LuaConsoleCmd使用
    					rawset(_G, k, v)
                    end
				end
})

t.Avatars_Server = UE.TArray(UE.AActor)
t.Avatars_Client = UE.TArray(UE.AActor)
t.Monsters_Server = UE.TArray(UE.AActor)
t.Monsters_Client = UE.TArray(UE.AActor)
t.ServerOnly = ServerOnly
t.ClientOnly = ClientOnly
t.ServerAndClient = ServerAndClient

t.LuaCmds = {}

local function RegisterLuaConsoleCmd()
	local lua_console_cmds = decorator:GetDecorator(decorator.decorator_type_lua_console_cmd)
    local decorated_vars = lua_console_cmds:GetDecoratedVars()
    for cmd_name, cmd_info in pairs(decorated_vars) do
        t.LuaCmds[cmd_name] = cmd_info
    end

    local old_gmttable = getmetatable(_G)

    local function G_get(t, k)
        if k == "p" then
            if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
                return rawget(_G, "_ps")
            else
                return rawget(_G, "_p")
            end
        else
            local ret = rawget(_G, k)
            if ret == nil and old_gmttable ~= nil then
                ret = old_gmttable[k]
            end

            return ret
        end
    end

    setmetatable(_G, {__index = G_get})

	return t
end

function t.Setp(v)
    rawset(_G, "_p", v)
end

function t.Setps(v)
    rawset(_G, "_ps", v)
end

function t.OnServerAvararCreate(Avatar)
    t.Avatars_Server:Add(Avatar)
    if t.Avatars_Server:Length() == 1 then
        t.Setps(Avatar)
    end
end

function t.OnClientAvararCreate(Avatar)
    t.Avatars_Client:Add(Avatar)
    if t.Avatars_Client:Length() == 1 then
        t.Setp(Avatar)
    end
end

-------------------------- lua cmd definition ----------------------------

decorator.lua_console_cmd(ServerOnly)
function t.PS(index)
	return t.Avatars_Server:Get(index)
end

decorator.lua_console_cmd(ClientOnly)
function t.PC(index)
	return t.Avatars_Client:Get(index)
end

decorator.lua_console_cmd(ServerOnly)
function t.MS(index)
	return t.Monsters_Server:Get(index)
end

decorator.lua_console_cmd(ClientOnly)
function t.MC(index)
	return t.Monsters_Client:Get(index)
end

decorator.lua_console_cmd(ServerOnly)
function t.PrintActivateSkillID(Actor)
    local AbilitySystemComponent = G.GetHiAbilitySystemComponent(Actor)
    local ActivatableAbilities = AbilitySystemComponent.ActivatableAbilities.Items
    local Count = ActivatableAbilities:Length()
    for ind = 1, Count do
        local Spec = ActivatableAbilities:Get(ind)
        local UserData = Spec.UserData
        if UserData then
            G.log:debug("ConsoleCmd", "Activate Skill %s IsClient.%s", UserData.SkillID, Actor:IsClient())
        end
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.DumpAllState(Actor)
    local StateController = Actor:_GetComponent("StateController", false)
    G.log:debug("ConsoleCmd", utils.FormatTable(StateController.state_machine.states, 1))
end

decorator.lua_console_cmd(ClientOnly)
function t.DumpMoveState(Actor)
    G.log:debug("ConsoleCmd", Actor.CharacterMovement.MovementMode)
end

function t.GetActorByName(Name, bIsServer)
    local SearchActors = UE.TArray(UE.AActor)
    if bIsServer then
        SearchActors:Append(t.Avatars_Server)
        SearchActors:Append(t.Monsters_Server)
    else
        SearchActors:Append(t.Avatars_Client)
        SearchActors:Append(t.Monsters_Client)
    end

    for Ind = 1, SearchActors:Length() do
        local Actor = SearchActors:Get(Ind)
        local ActorName = G.GetDisplayName(Actor)
        if ActorName == Name then
            return Actor
        end
    end

    return nil
end

decorator.lua_console_cmd(ServerOnly)
function t.Knock(ActorName, KnockImpulse, KnockDir, bEnableZG, ZGTime)
    local Actor = t.GetActorByName(ActorName, true)
    if Actor then
        local KInfoClass = UE.UObject.Load("/Game/Blueprints/Common/UserData/UD_FKnockInfo.UD_FKnockInfo")
        local KInfo = KInfoClass()
        KInfo.KnockImpulse = KnockImpulse
        KInfo.KnockDir = KnockDir
        KInfo.EnableZeroGravity = bEnableZG
        KInfo.ZeroGravityTime = ZGTime

        Actor:SendMessage("HandleKnock", p, p, KInfo)
    end
end

decorator.lua_console_cmd(ServerOnly)
function t.kf(ActorName, DisScale)
    G = require("G")

    local Target = p
    if ActorName and ActorName ~= "" then
        Target = t.GetActorByName(ActorName, true)
    end

    if not Target then
        G.log:error("t", "No target found.")
        return
    end

    if not DisScale then
        DisScale = {1, 1, 1}
    end
    DisScale = UE.FVector(DisScale[1], DisScale[2], DisScale[3])

    local KnockInfo = SkillUtils.NewKnockInfoObject()
    KnockInfo.KnockDisScale = DisScale
    local KnockFlyTag = UE.UHiGASLibrary.RequestGameplayTag("Event.Hit.KnockBack.SuperHeavy")
    if not KnockFlyTag then
        G.log:error("t", "Knock fly tag not found")
        return
    end

    KnockInfo.HitTags.GameplayTags:Add(KnockFlyTag)

    local HitPayload = UE.FGameplayEventData()
    HitPayload.EventTag = KnockFlyTag
    HitPayload.Instigator = Target
    HitPayload.Target = Target
    HitPayload.OptionalObject = KnockInfo
    Target:SendMessage("HandleHitEvent", HitPayload)
end

decorator.lua_console_cmd(ServerOnly)
---@param DisScale table
---@param InKnockDir string Middle/Left/Right
---@param Strength string Light/Heavy, default Light
function t.kb(ActorName, DisScale, InKnockDir, Strength)
    G = require("G")

    local Target = p
    if ActorName and ActorName ~= "" then
        Target = t.GetActorByName(ActorName, true)
    end

    if not Target then
        G.log:error("t", "No target found.")
        return
    end

    if not DisScale then
        DisScale = {1, 1, 1}
    end
    DisScale = UE.FVector(DisScale[1], DisScale[2], DisScale[3])

    local KnockInfo = SkillUtils.NewKnockInfoObject()
    KnockInfo.KnockDisScale = DisScale
    local TagStr = "Event.Hit.KnockBack.Light"
    if Strength == "Heavy" then
        TagStr = "Event.Hit.KnockBack.Heavy"
    end
    local KnockTag = UE.UHiGASLibrary.RequestGameplayTag(TagStr)
    if not KnockTag then
        G.log:error("t", "Knock tag not found")
        return
    end

    local KnockDir = Enum.Enum_KnockDir.Middle
    if InKnockDir == "Left" then
        KnockDir = Enum.Enum_KnockDir.Left
    elseif InKnockDir == "Right" then
        KnockDir = Enum.Enum_KnockDir.Right
    end
    KnockInfo.KnockDir = KnockDir

    KnockInfo.HitTags.GameplayTags:Add(KnockTag)

    local HitPayload = UE.FGameplayEventData()
    HitPayload.EventTag = KnockTag
    HitPayload.Instigator = Target
    HitPayload.Target = Target
    HitPayload.OptionalObject = KnockInfo
    Target:SendMessage("HandleHitEvent", HitPayload)
end

decorator.lua_console_cmd(ServerOnly)
function t.Damage(ActorName, Damage)
    local Target = p
    if ActorName and ActorName ~= "" then
        Target = t.GetActorByName(ActorName, true)
    end

    if not Target then
        G.log:error("t", "No target found.")
        return
    end

    local GEClass = UE.UClass.Load("/Game/Blueprints/Skill/GE/GE_Damage_GM.GE_Damage_GM_C")
    local ASC = Target.AbilitySystemComponent
    if not ASC then
        G.log:error("t", "Target no ASC")
        return
    end

    if not Damage then
        Damage = 100
    end

    local GESpecHandle = ASC:MakeOutgoingSpec(GEClass, 1, UE.FGameplayEffectContextHandle())
    UE.UAbilitySystemBlueprintLibrary.AssignTagSetByCallerMagnitude(GESpecHandle, UE.UHiGASLibrary.RequestGameplayTag("Data.Damage"), Damage)
    ASC:BP_ApplyGameplayEffectSpecToSelf(GESpecHandle)
end

decorator.lua_console_cmd(ClientOnly)
function t.PlayerExecAction(Action)
    p:SendMessage("ExecuteAction", Action)
end

decorator.lua_console_cmd(ClientOnly)
function t.PlayerExecState(State, bEnter)
    if bEnter == nil or bEnter then
        p:SendMessage("EnterState", State)
    else
        p:SendMessage("EndState", State)
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.PlayerShowStates()
    local StateController = p:_GetComponent("StateController", false)

    local States = {}
    for _, State in pairs(StateController.state_machine.active_states) do
        table.insert(States, state_conflict_data.extra_data.states[State])
    end
    G.log:debug("yj", "ConsoleCmd Name.%s States.%s StatesName.%s", p:GetDisplayName(), utils.ToString(StateController.state_machine.active_states), utils.ToString(States))
end

decorator.lua_console_cmd(ClientOnly)
function t.PlayerClearStates()
    local StateController = p:_GetComponent("StateController", false)
    StateController.state_machine.active_states = {}
    StateController.state_machine.states = {}
end


decorator.lua_console_cmd(ServerOnly)
function t.SetAttr(...)
    local ASC = G.GetHiAbilitySystemComponent(p)
    local args = {...}

    local Ind = 1
    while Ind < #args do
        if Ind + 1 > #args then
            break
        end

        local Key = args[Ind]
        local Val = args[Ind + 1]
        SkillUtils.SetAttributeBaseValue(ASC, Key, Val)
        Ind = Ind + 2
    end
end

decorator.lua_console_cmd(ServerOnly)
function t.KillPlayer()
    p:SendMessage("KillSelf")
end

decorator.lua_console_cmd(ClientOnly)
function t.Show()
    p:SetActorHiddenInGame(false)
end

decorator.lua_console_cmd(ClientOnly)
function t.Hide()
    p:SetActorHiddenInGame(true)
end


decorator.lua_console_cmd(ClientOnly)
function t.FreezeTODTime(freeze_time)
    local ObjectRegistryWorldSubsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(UE.UHiUtilsFunctionLibrary.GetGWorld(), UE.UObjectRegistryWorldSubsystem)
    if ObjectRegistryWorldSubsystem ~= nil then
        local wma = ObjectRegistryWorldSubsystem:FindObject("TODWeatherManager")
        if wma ~= nil then
            wma:TransitionHourTimeTo(freeze_time, 1.0)
            G.log:debug("TOD Time Transitioned")
        else
            G.log:debug("No Tod Manager")
        end
    else
        G.log:debug("No ORWS")
    end    
end

decorator.lua_console_cmd(ServerOnly)
function t.TeleportForward(Distance)
    local Location = p:K2_GetActorLocation()
    local Rotation = p:K2_GetActorRotation()
    local NormalForward = UE.UKismetMathLibrary.Normal(UE.UKismetMathLibrary.Conv_RotatorToVector(Rotation))
    local HitResult = UE.FHitResult()
    p:K2_SetActorLocation(Location + NormalForward * Distance, true, HitResult, false)
    if HitResult.Component and HitResult.Component:GetOwner() then
        local CurActor = HitResult.Component:GetOwner()
        G.log:debug("yj", "TeleportForward Component.%s Actor.%s", G.GetDisplayName(HitResult.Component), G.GetDisplayName(CurActor))
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.ProfileTest()
    local GameAPI = require("common.game_api")

    local TargetActors = UE.TArray(UE.AActor)
    local BeginMs = G.GetNowTimestampMs()
    for Ind = 1, 10000 do
        -- UE.UGameplayStatics.GetAllActorsWithTag(p:GetWorld(), "TrapActor", TargetActors)

        -- UE.UGameplayStatics.GetAllActorsOfClass(p:GetWorld(), UE.AHiCharacter, TargetActors)

        -- UE.UGameplayStatics.GetAllActorsWithInterface(p:GetWorld(), UE.UAbilitySystemInterface, TargetActors)

        -- TargetActors = GameAPI.GetActorsWithTag(p, "Player")
    end
    local EndMs = G.GetNowTimestampMs()

    G.log:debug("yj", "ProfileTest timecost.%sms", EndMs - BeginMs)
end

decorator.lua_console_cmd(ServerOnly)
function t.SetHp(Hp)
    local ASC = G.GetHiAbilitySystemComponent(p)
    -- local MaxHealthAttr = ASC:FindAttributeByName(SkillUtils.AttrNames.MaxHealth)
    -- local AttributeSet = ASC:GetAttributeSet(MaxHealthAttr.AttributeOwner)
    -- AttributeSet.MaxHealth.CurrentValue = Hp
    -- AttributeSet.MaxHealth.BaseValue = Hp

    local HealthAttr = ASC:FindAttributeByName(SkillUtils.AttrNames.Health)
    AttributeSet = ASC:GetAttributeSet(HealthAttr.AttributeOwner)
    AttributeSet.Health.CurrentValue = Hp
    AttributeSet.Health.BaseValue = Hp
end

decorator.lua_console_cmd(ServerOnly)
function t.SetStamina(Stamina)
    local ASC = G.GetHiAbilitySystemComponent(p)
    local MaxStaminaAttr = ASC:FindAttributeByName(SkillUtils.AttrNames.MaxStamina)
    local AttributeSet = ASC:GetAttributeSet(MaxStaminaAttr.AttributeOwner)
    AttributeSet.MaxStamina.CurrentValue = Stamina

    local StaminaAttr = ASC:FindAttributeByName(SkillUtils.AttrNames.Stamina)
    AttributeSet = ASC:GetAttributeSet(StaminaAttr.AttributeOwner)
    AttributeSet.Stamina.CurrentValue = Stamina
end

decorator.lua_console_cmd(ServerAndClient)
function t.ReserveErrorLog()
    local FORCE_SHOW_LEVEL = require("debug.logger_config").FORCE_SHOW_LEVEL
    FORCE_SHOW_LEVEL.INFO = nil
    FORCE_SHOW_LEVEL.DEBUG = nil
    FORCE_SHOW_LEVEL.WARN = nil
end

decorator.lua_console_cmd(ClientOnly)
function t.moveforward(value)
    local InputComponent = p:_GetComponent("BP_InputComponent", false)
    InputComponent:ForwardMovementAction(value)
end

decorator.lua_console_cmd(ClientOnly)
function t.moveright(value)
    local InputComponent = p:_GetComponent("BP_InputComponent", false)
    InputComponent:RightMovementAction(value)
end

decorator.lua_console_cmd(ServerAndClient)
function t.gmgo(x, y, z)
    local Location = UE.FVector(x, y, z)
    local CharacterMovement = p.CharacterMovement
    if CharacterMovement then
        Location = Location - p:K2_GetActorLocation()
        CharacterMovement:K2_MoveUpdatedComponent(Location, p.Rotation, nil, false, false)
    end
    --local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    --Player:K2_SetActorLocation(Location, false, nil, false)
end

decorator.lua_console_cmd(ClientOnly)
function t.TurnToServer(Cmd)
    p:Server_DoConsoleCmd(Cmd)
end

decorator.lua_console_cmd(ClientOnly)
function t.setfacepoint(x,y)
    local nowloc = p:K2_GetActorLocation()
    local newloc = UE.FVector(x, y, nowloc.Z)
    local dif = newloc - nowloc
    --UE.UKismetMathLibrary.Vector_Normalize(dif)
    --G.log:debug("icy", "now dif_final.%s", dif)
    local rotaion = UE.UKismetMathLibrary.Conv_VectorToRotator(dif)

    local InputComponent = p:_GetComponent("BP_InputComponent", false)
    local yaw = rotaion.Yaw
    local oldyaw = p:GetControlRotation().Yaw
    local difyaw =  (yaw - oldyaw)/3.125
    InputComponent:CameraRightAction(difyaw)
    p:K2_SetActorRotation(rotaion,true)
end

decorator.lua_console_cmd(ServerOnly)
function t.SetSpeedScale(Scale)
    p.AppearanceComponent:SetSpeedScale(Scale)
    p.AppearanceComponent:Multicast_SetSpeedScale(Scale, false)
end

decorator.lua_console_cmd(ServerOnly)
function t.PointCollect()

    -- local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    -- local Location = Player:K2_GetActorLocation()
    -- G.log:error("lq","[PointCollent]%s",Location)

    local Location = p:K2_GetActorLocation()
    G.log:error("lq","[PointCollent]%s",Location)
end

decorator.lua_console_cmd(ClientOnly)
function t.Add(A,B)
    return A+B
end

decorator.lua_console_cmd(ClientOnly)
function t.Traverse()
    for i = 1, 100 do
        print(i)
        print("\n")
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.TeleInOffice()
    p.TeleportComponent:Server_TeleportToOffice()
end

decorator.lua_console_cmd(ClientOnly)
function t.TeleOutOffice()
    p.TeleportComponent:Server_WalkOutOfOffice()
end

decorator.lua_console_cmd(ClientOnly)
function t.TeleToActor(ActorID)
    p.TeleportComponent:Server_TeleportToActor(Enum.Enum_AreaType.MainWorld, tostring(ActorID))
end

decorator.lua_console_cmd(ClientOnly)
function t.DrawTargetDebugLine()
    p.BattleStateComponent.DrawDebug = true
end

decorator.lua_console_cmd(ServerOnly)
function t.GetTargetBTDebugInfo()
    if p.BattleStateComponent.CurTarget then
        G.log:error("yj", "%s.GetTargetBTDebugInfo:", p.BattleStateComponent.CurTarget:GetDisplayName())
        G.log:error("yj", p.BattleStateComponent.CurTarget:GetController():GetAIDebugInfo())
        G.log:error("yj", p.BattleStateComponent.CurTarget:GetController():GetBTDebugInfo())
    else
        G.log:error("yj", "CurTarget nil")
    end
    -- print(p.AIClusterComponent.PlaceHolderScore)
end

decorator.lua_console_cmd(ClientOnly)
function t.EnableRoleSwitch()
    local switches = require("switches")
    switches.EnableRoleSwitch = not switches.EnableRoleSwitch
end

decorator.lua_console_cmd(ServerOnly)
function t.gmaddbaggrid(TabIndex, Count)
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        local Player = p
        local PS = Player.PlayerState
        local ItemManager  = PS.ItemManager
        local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
        ItemManager:AddBagCapacity(TabIndex, Count)
    end
end

decorator.lua_console_cmd(ServerOnly)
function t.gmadditem(ExcelID, Count)
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        print("gmadditem Test gm Success")
        local Player = p
        local PS = Player.PlayerState
        local ItemManager  = PS.ItemManager
        local ItemUtil = require("common.item.ItemUtil")
        ItemManager:AddItemByExcelID(ExcelID, Count)
    end
end

decorator.lua_console_cmd(ServerOnly)
function t.gmreduceitem(ExcelID, Count)
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        print("gmreduceitem Test gm Success")
        local Player = p
        local PlayerController = Player.PlayerState:GetPlayerController()
        local ItemManager  = PlayerController.ItemManager
        local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
        ItemManager:ReduceItemByExcelID(ExcelID, Count)
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.gmtestsmallconfirm()
    print("gmtestsmallconfirm Test gm Success")
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    ---@type WBP_Common_SecondTextConfirm
    local SecondConfirmWidget = UIManager:OpenUI(UIDef.UIInfo.UI_Common_SecondTextConfirm)
    SecondConfirmWidget:SetTitleAndContent("ITEM_USE_TITILE", "ITEM_USE_CONTENT_BLOOD_FULL")

    local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
    local ItemManager  = ItemUtil.GetItemManager(t.PC(1))
    SecondConfirmWidget.WBP_Common_Popup_Small:BindCommitCallBack(ItemManager, ItemManager.PrintItems)
    SecondConfirmWidget.WBP_Common_Popup_Small:BindCancelCallBack(ItemManager, ItemManager.PrintItems)
end

decorator.lua_console_cmd(ClientOnly)
function t.gmtestuseitempopup()
    print("gmtestuseitempopup Test gm Success")
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    ---@type WBP_Knapsack_UsePopup
    local SecondConfirmWidget = UIManager:OpenUI(UIDef.UIInfo.UI_Knapsack_UsePopup_Main)

    local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
    local ItemManager  = ItemUtil.GetItemManager(t.PC(1))
    local Items = ItemManager:GetItemsByExcelID(100002)
    SecondConfirmWidget:UseItem(Items[1])
end

decorator.lua_console_cmd(ClientOnly)
function t.gmopenbag()
    print("gmtestuseitempopup Test gm Success")
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    ---@type WBP_Knapsack_UsePopup
    local SecondConfirmWidget = UIManager:OpenUI(UIDef.UIInfo.UI_Knapsack_Main)

    --local CallBack1 = function()
    --    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    --    local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
    --    local ItemManager  = ItemUtil.GetItemManager(t.PC(1))
    --    ItemManager:Server_GMAddItem(100001, 100)
    --end
    --
    --local CallBack2 = function()
    --    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    --    local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
    --    local ItemManager  = ItemUtil.GetItemManager(t.PC(1))
    --    ItemManager:Server_GMAddItem(100002, 1000000)
    --end
    --
    --UE.UKismetSystemLibrary.K2_SetTimerDelegate({SecondConfirmWidget, CallBack1}, 2, false)
    --
    --UE.UKismetSystemLibrary.K2_SetTimerDelegate({SecondConfirmWidget, CallBack2}, 4, false)
end

decorator.lua_console_cmd(ServerOnly)
function t.gmaddallitems()
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        local Player = p
        local PlayerController = Player.PlayerState:GetPlayerController()
        local ItemManager  = PlayerController.ItemManager
        local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
        local Configs = ItemUtil.GetAllItemConfig()
        for ExcelID, Config in pairs(Configs) do
            ItemManager:AddItemByExcelID(ExcelID, 1)
        end
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.gmsetspecialstate(bShow)
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    ---@type WBP_HUD_MainInterface
    local UIInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_SkillState.UIName)
end

decorator.lua_console_cmd(ClientOnly)
function t.gmsetmirrorstate(bShow)
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    ---@type WBP_HUD_MainInterface
    local UIInstance = UIManager:GetUIInstance(UIDef.UIInfo.UI_SkillState.UIName)
end

decorator.lua_console_cmd(ClientOnly)
function t.gmopentelephone()
    print("gmopentelephone Test gm Success")
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    ---@type WBP_Knapsack_UsePopup
    local SecondConfirmWidget = UIManager:OpenUI(UIDef.UIInfo.UI_InteractionTelephone)
end

decorator.lua_console_cmd(ClientOnly)
function t.gmopentombstone()
    print("gmopentombstone Test gm Success")
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    ---@type WBP_Interaction_Tombstone
    local TombstoneWidget = UIManager:OpenUI(UIDef.UIInfo.UI_Interaction_Tombstone)

    local OnMouseButtonDownCallback = function()
        print("gmopentombstone OnMouseButtonDownCallback")
    end

    local OnMouseButtonUpCallback = function()
        print("gmopentombstone OnMouseButtonUpCallback")
    end

    local OnCloseCallback = function()
        print("gmopentombstone OnCloseCallback")
    end

    TombstoneWidget:RegCloseCallBack(OnCloseCallback)
    TombstoneWidget:RegMouseButtonDownCallBack(OnMouseButtonDownCallback)
    TombstoneWidget:RegMouseButtonUpCallBack(OnMouseButtonUpCallback)

    local TombComplete = function()
        print("gmopentombstone TombComplete")
        TombstoneWidget:TombstoneCleanComplete()
    end

    UE.UKismetSystemLibrary.K2_SetTimerDelegate({TombstoneWidget, TombComplete}, 10, false)
end


decorator.lua_console_cmd(ServerOnly)
function t.gmfinishmission(MissionID)
    print("gmfinishmission MissionID")
    local SubsystemUtils = require("common.utils.subsystem_utils")
    if p ~= nil and UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        local MissionFlowSubsystem = SubsystemUtils.GetMissionFlowSubsystem(p)
        local MissionNode = MissionFlowSubsystem:FindMissionNode(MissionID)
        if MissionNode ~= nil then
            MissionNode:TriggerOutput("Finish", true, false)
        else
            print("gmfinishmission mission not found")
        end
    else
        print("gmfinishmission not in server")
    end
end

decorator.lua_console_cmd(ServerOnly)
function t.AddMissionAct(MissionActID)
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        local DataComponent = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MissionManager):GetDataBPComponent()
        local MissionActRecord = DataComponent:CreateMissionActRecord(MissionActID)
        MissionActRecord.InitTime = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
        DataComponent:BroadcastAddMissionAct(MissionActID)
        local MissionIdentifier = UE.FHiMissionIdentifier()
        MissionIdentifier.MissionActID = MissionActID
        DataComponent:BroadcastMissionActStateChange(MissionIdentifier, MissionActRecord.State)
    end
end

decorator.lua_console_cmd(ServerOnly)
function t.ChangeMissionActState(MissionActID, NewState)
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        local DataComponent = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MissionManager):GetDataBPComponent()
        local MissionIdentifier = UE.FHiMissionIdentifier()
        MissionIdentifier.MissionActID = MissionActID
        DataComponent:SetMissionActState(MissionIdentifier, NewState)
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.closegm()
    local controller = UE.UGameplayStatics.GetPlayerController(t.PC(1), 0)
    controller.ControllerUIComponent:CallLuaDebugWidget()
end

decorator.lua_console_cmd(ClientOnly)
function t.AccrptMissionAct(MissionActID)
    p.PlayerState.MissionAvatarComponent:Server_AcceptMissionAct(MissionActID)
end

decorator.lua_console_cmd(ServerAndClient)
function t.PrintMissionActInfo()
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        local MissionActDataList = p.PlayerState.MissionAvatarComponent:GetMissionActList()
        for i = 1, MissionActDataList:Num() do
            local MissionAct = MissionActDataList:GetRef(i)
            G.log:debug("[PrintMissionAct Server]", "MissionAct ActId=%s, State=%s", MissionAct.MissionActID, MissionAct.State)
        end
    else
        local MissionActDataList = p.PlayerState.MissionAvatarComponent:GetMissionActList()
        for i = 1, MissionActDataList:Num() do
            local MissionAct = MissionActDataList:GetRef(i)
            G.log:debug("[PrintMissionAct Client]", "MissionAct ActId=%s, State=%s", MissionAct.MissionActID, MissionAct.State)
        end
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.gmopentaskpreview(Index)
    local controller = UE.UGameplayStatics.GetPlayerController(t.PC(1), 0)
    controller.ControllerUIComponent:CallLuaDebugWidget()
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    local Uikey = UIDef.UIInfo.UI_Task_PlotReview
    local Widget = UIManager:OpenUI(Uikey)
    if Index == 1 then
        Widget:ShowReward(9001)
    end
    if Index == 2 then
        Widget:ShowSummary(9001)
    end
    print("gmopentaskpreview Test gm Success")
end

decorator.lua_console_cmd(ServerOnly)
function t.EnableExtremeDodge()
    p.BuffComponent:AddPreAttackBuff()
end

decorator.lua_console_cmd(ServerOnly)
function t.ClearExtremeDodge()
    p.BuffComponent:RemovePreAttackBuff()
end

decorator.lua_console_cmd(ClientOnly)
function t.HandleSmsChoice(NpcID, CurrentChoice)
    p.PlayerState.MissionAvatarComponent:HandleDialogueChoice(NpcID, CurrentChoice)
    local DialogStep = p.PlayerState.MissionAvatarComponent:GetCurrentSmsDialogueStep(NpcID)
    if DialogStep:GetType() == DialogueObjectModule.DialogueType.TALK then
        -- 普通对白
        G.log:debug("GM", "TALK Content=%s", DialogStep:GetContent())
    elseif DialogStep:GetType() == DialogueObjectModule.DialogueType.INTERACT then
        -- 交互对白
        G.log:debug("GM", "INTERACT Num=%s", #DialogStep:GetInteractItems())
    elseif DialogStep:GetType() == DialogueObjectModule.DialogueType.FINISHED then
        -- 结束对白
        G.log:debug("GM", "FINISH Dialogue")
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.FinishDialogue(NpcID)
    p.PlayerState.MissionAvatarComponent:FinishDialogue(NpcID)
end

local function CreateDialogueStep(DialogueID, StepType, Index)
    local DialogueStepRecordClass = EdUtils:GetUE5ObjectClass(BPConst.DialogueStepRecord, true)
    local DialogueStepRecord = DialogueStepRecordClass()
    DialogueStepRecord.DialogueID = DialogueID
    DialogueStepRecord.StepType = StepType
    DialogueStepRecord.Index = Index
    return DialogueStepRecord
end

decorator.lua_console_cmd(ServerOnly)
function t.AddHistoryDialogue()
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        local DialogueRecordClass = EdUtils:GetUE5ObjectClass(BPConst.DialogueRecord, true)
        local DialogueRecord = DialogueRecordClass()
        DialogueRecord.MissionActID = 9002
        DialogueRecord.NpcID = 90001

        local DialogueStepRecord1 = CreateDialogueStep(10001, 1, 1)
        DialogueRecord.StepRecords:Add(DialogueStepRecord1)
        local DialogueStepRecord2 = CreateDialogueStep(10001, 1, 2)
        DialogueRecord.StepRecords:Add(DialogueStepRecord2)
        local DialogueStepRecord3 = CreateDialogueStep(10001, 1, 3)
        DialogueRecord.StepRecords:Add(DialogueStepRecord3)
        local DialogueStepRecord4 = CreateDialogueStep(10001, 1, 4)
        DialogueRecord.StepRecords:Add(DialogueStepRecord4)
        local DialogueStepRecord5 = CreateDialogueStep(1001, 2, 2)
        DialogueRecord.StepRecords:Add(DialogueStepRecord5)
        local DialogueStepRecord6 = CreateDialogueStep(10004, 1, 1)
        DialogueRecord.StepRecords:Add(DialogueStepRecord6)

        p.PlayerState.MissionAvatarComponent.HistorySmsDialogues:Add(DialogueRecord)
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.AssistSkill()
    p.SkillComponent:AssistSkill()
end

decorator.lua_console_cmd(ServerOnly)
function t.GoldenBody(open)
    p:SendMessage("GoldenBody", open)
end

decorator.lua_console_cmd(ClientOnly)
function t.PlayAkayaPickupDogLS()
    p:SendMessage("PlayAkayaPickupDogLS")
end

decorator.lua_console_cmd(ClientOnly)
function t.MonologueTest(MonologueID)
    p:SendMessage("StartMonologue", MonologueID)
end

decorator.lua_console_cmd(ClientOnly)
function t.DrawDebugSphere(Radius)
    TargetLocation = p:K2_GetActorLocation()
    UE.UKismetSystemLibrary.DrawDebugSphere(p:GetWorld(), TargetLocation, Radius, 20, UE.FLinearColor.Red, 2, 5.0)
end

decorator.lua_console_cmd(ClientOnly)
function t.hideallui()
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    if UIManager.HiddenLayerContext then
        UIManager:ResetHiddenLayerContext(UIManager.HiddenLayerContext)
    end
    UIManager.HiddenLayerContext = UIManager:SetOtherLayerHiddenExcept({})
end

decorator.lua_console_cmd(ClientOnly)
function t.showallui()
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    if UIManager.HiddenLayerContext then
        UIManager:ResetHiddenLayerContext(UIManager.HiddenLayerContext)
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.ShowCharacterLocation(bOpen)
    if bOpen == 1 then

        local controller = UE.UGameplayStatics.GetPlayerController(t.PC(1), 0)
        controller.ControllerUIComponent:CallDebugInfoWidget(1)

    end

    if bOpen == 0 then
        local controller = UE.UGameplayStatics.GetPlayerController(t.PC(1), 0)
        controller.ControllerUIComponent:CallDebugInfoWidget(0)
    end
end


		
decorator.lua_console_cmd(ClientOnly)
function t.ShowSkillScale(bOpen)
    if bOpen == 1 then
        local controller = UE.UGameplayStatics.GetPlayerController(t.PC(1), 0)
        ControllerUIComponent = controller.ControllerUIComponent
        ControllerUIComponent.FirstStarthandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ControllerUIComponent,ControllerUIComponent.DrawDebugCircle},0.01,true)
    end

    if bOpen == 0 then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(ControllerUIComponent,ControllerUIComponent.FirstStarthandle)
    end
end

decorator.lua_console_cmd(ServerOnly)
function t.GetGameTime()
    local GameState = UE.UGameplayStatics.GetGameState(p)
    local Component = GameState.GameTimeComponent
    G.log:debug("GetGameTime", "DayNum=%s, MinuteOfDay=%s", Component.DayNum, Component.MinuteOfDay)
end

decorator.lua_console_cmd(ServerOnly)
function t.AddGameTime(Minutes)
    local GameState = UE.UGameplayStatics.GetGameState(p)
    local Component = GameState.GameTimeComponent
    Component:AddMinutes(Minutes)
    G.log:debug("AddGameTime", "AddMinutes=%s, DayNum=%s, MinuteOfDay=%s", Minutes, Component.DayNum, Component.MinuteOfDay)
end

decorator.lua_console_cmd(ServerOnly)
function t.ChangeWeather(Weather)
    local GameState = UE.UGameplayStatics.GetGameState(p)
    local Component = GameState.GameWeatherComponent
    Component:ChangeGlobalWeather(Weather)
    G.log:debug("ChangeWeather", "GlobalWeather=%s", Component.GlobalWeather)
end

decorator.lua_console_cmd(ServerOnly)
function t.ChangeNpcActions(NpcId, Actions)
    local NpcId = tostring(NpcId)
    local NpcActor = SubsystemUtils.GetMutableActorSubSystem(p):GetActor(NpcId)
    if not NpcActor then
        G.log:error("ChangeNpcActions", "Can't find Npc, id=%s", NpcId)
        return
    end
    local ActionList = UE.TArray(UE.FInt)
    for _, ActionId in ipairs(Actions) do
        ActionList:Add(ActionId)
    end
    NpcActor.NpcTimeControlComponent.EventOnChangeActions:Broadcast(ActionList)
end

function t.FindAbilitySpecHandleFromSkillID(self, SkillID)
    local ASC = G.GetHiAbilitySystemComponent(self)
    local Spec = SkillUtils.FindAbilitySpecFromSkillID(ASC, SkillID)
    -- UnLua.SetLuaDebugWatch(true)
    if Spec then return Spec.Handle end
end

decorator.lua_console_cmd(ClientOnly)
function t.god_test1()
    p.AbilityHandle = t.FindAbilitySpecHandleFromSkillID(p, 6001)
    -- UnLua.SetLuaDebugWatch(false)
    G.log:error("yj", "t.test1 OldHandle1(%s %s)", p.AbilityHandle, p.AbilityHandle.Handle)
end

decorator.lua_console_cmd(ClientOnly)
function t.god_test2()
    -- UnLua.SetLuaDebugWatch(true)
    G.log:error("yj", "t.test2 OldHandle1(%s %s)", p.AbilityHandle, p.AbilityHandle.Handle)
    -- UnLua.SetLuaDebugWatch(false)
end

decorator.lua_console_cmd(ClientOnly)
function t.Judge()
    local Boss = utils.GetBoss()
    p.SkillComponent:TryJudge(Boss)
end

decorator.lua_console_cmd(ServerOnly)
function t.AddSubmitTestItems()
    if UE.UHiUtilsFunctionLibrary.IsServerWorld() then
        print("AddSubmitTestItems Test gm Success")
        local Player = p
        local PlayerController = Player.PlayerState:GetPlayerController()
        local ItemManager  = PlayerController.ItemManager
        local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")
        ItemManager:AddItemByExcelID(110001,2)
        ItemManager:AddItemByExcelID(110002,2)
        ItemManager:AddItemByExcelID(110003,1)
        ItemManager:AddItemByExcelID(110004,3)
        ItemManager:AddItemByExcelID(110005,3)
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.SubmitTest(type)
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')

    local submitPanel = UIManager:OpenUI(UIDef.UIInfo.UI_NpcDeliver)
    submitPanel:Test(type)
    closegm()
end

decorator.lua_console_cmd(ClientOnly)
function t.Setting(bOpen)
    local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    if bOpen then
        local SecondConfirmWidget = UIManager:OpenUI(UIDef.UIInfo.UI_GameSetting)
    else
        UIManager:CloseUIByName(UIDef.UIInfo.UI_GameSetting.UIName)
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.TestStructOnLua()
    local DecorationInfo = Struct.BPS_OfficeDecorationInfo()
    DecorationInfo.ActorID = "1111"
    DecorationInfo.BasicModelKey = "Key 111"
    local DecorationInfo2 = DecorationInfo:Copy()
    G.log:info("yongzyzhang", "TestStructOnLua before change DecorationInfo2, ActorID:%s, Key:%s", 
            DecorationInfo2.ActorID, DecorationInfo2.BasicModelKey)

    DecorationInfo2.BasicModelKey = "key 222"
    G.log:info("yongzyzhang", "TestStructOnLua after change DecorationInfo2, ActorID:%s, Key:%s DecorationInfo1.key:%s",
            DecorationInfo2.ActorID, DecorationInfo2.BasicModelKey, DecorationInfo.BasicModelKey)

    local LeaveParam = Struct.BPS_OfficeLeaveDecorationModeParam()
    LeaveParam.ActorDecorationInfos:AddDefault()
    local CopyedArray = LeaveParam.ActorDecorationInfos:Copy()
    G.log:info("yongzyzhang", "TestStructOnLua test copy CopyedArray:Length",
            CopyedArray:Length())
end


decorator.lua_console_cmd(ClientOnly)
function t.TestRPCStub()
    local RPCStubFactory = require("micro_service.rpc_stub_factory")
    RPCStubFactory:TestAsyncRPC()
end

decorator.lua_console_cmd(ServerOnly)
function t.DSTestRPCStub()
    local RPCStubFactory = require("micro_service.rpc_stub_factory")
    RPCStubFactory:TestAsyncRPC()
end

decorator.lua_console_cmd(ClientOnly)
function t.TestIRPCParseProto()
    local IRPC = require("micro_service.irpc.irpc")
    local PROTOC = require("micro_service.irpc.protoc").new()
    local IRPCLog = require("micro_service.irpc.irpc_log")
    local IRPCCore = require("irpc_core")

    local PB = require "pb"

    IRPC:Open()
    PROTOC:addpath(UE.UKismetSystemLibrary.GetProjectContentDirectory() .. "Protos/")
    PROTOC:addpath(UE.UKismetSystemLibrary.GetProjectContentDirectory() .. "Protos/Thirdparty/")

    -- 自动处理import依赖 @see https://github.com/starwing/lua-protobuf/blob/master/README.zh.md
    PROTOC.include_imports = true

    local ProtoFile = "Services/OfficeService/office_ms.proto"
    --加载Proto文件
    PROTOC:loadfile(ProtoFile)
    G.log:info("load proto file:%s done", ProtoFile)
end

decorator.lua_console_cmd(ClientOnly)
function t.OfficeBuyTrialItems()
    ---@type OfficeManager
    local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
    local DecorateHandlerComp = OfficeManager:GetDecorationHandlerComp()
    if not DecorateHandlerComp.bInDecorationMode then
        DecorateHandlerComp:Server_EnterDecorationMode()
    end
    utils.DoDelay(DecorateHandlerComp, 0.5,function()
        ---@type FOfficeClientDecorationShopCar
        local ShopCar = {SkinItems = {}, ColorItems = {}}
        local SkinKey = "Table_01_Skin_02"
        --ShopCar.SkinItems[SkinKey] = {
        --    SkinKey = SkinKey,
        --    Num = 1,
        --}
        ---@type FOfficeModelColorPayItem
        local ColorItem = {
            ModelKey = "Table_01_Skin_02",
            Color = {R = 150, G = 80},
            Index = 1
        }
        table.insert(ShopCar.ColorItems, ColorItem)
        ColorItem = {
            ModelKey = "Table_01_Basic",
            Color = {R = 160, B = 100},
            Index = 2
        }
        table.insert(ShopCar.ColorItems, ColorItem)
        DecorateHandlerComp:ClientPurchaseTrialItems(ShopCar)
    end)
end

decorator.lua_console_cmd(ServerOnly)
function t.GMResetOffice()
    ---@type OfficeManager
    local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
    local DecorateHandlerComp = OfficeManager:GetDecorationHandlerComp()
    DecorateHandlerComp.SavedActorDecorationInfos:Clear()
    DecorateHandlerComp.TrialDecorationItems = Struct.BPS_OfficeDecorationTrialItems()
    local OwnerPlayerController = DecorateHandlerComp:GetOfficeOwnerPlayer()

    local MsConfig = require("micro_service.ms_config")
    local Invoker = OwnerPlayerController:GetRemoteMetaInvoker(MsConfig.MSOfficeEntityMetaName, OfficeManager.OfficeGid)
    Invoker:GMResetAsset({}, function() 
        
    end)
end

decorator.lua_console_cmd(ServerOnly)
function t.EnterOffice()
    ---@type OfficeManager
    local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
    local PlayerState = UE.UGameplayStatics.GetPlayerState(p:GetWorld(), 0)
    OfficeManager:EnterOffice(PlayerState)
end

decorator.lua_console_cmd(ServerOnly)
function t.LeaveOffice()
    ---@type OfficeManager
    local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
    local PlayerState = UE.UGameplayStatics.GetPlayerState(p:GetWorld(), 0)
    OfficeManager:LeaveOffice(PlayerState:GetPlayerController():GetPlayerRoleId())
end

decorator.lua_console_cmd(ClientOnly)
function t.SwitchOfficeMode(payAllWhenLeave)
    ---@type OfficeManager
    local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
    local DecorateHandlerComp = OfficeManager:GetDecorationHandlerComp()
    if not DecorateHandlerComp.bInDecorationMode then
        DecorateHandlerComp:Server_EnterDecorationMode()
    else
        DecorateHandlerComp:ClientRequestLevelDecorationMode(payAllWhenLeave)
    end
end

decorator.lua_console_cmd(ClientOnly)
function t.ChangeSkin(Index)
    ---@type OfficeManager
    local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
    local DecorateHandlerComp = OfficeManager:GetDecorationHandlerComp()
    local NewSkinKey = "Table_01_Basic"
    if Index == 2 then
        NewSkinKey = "Table_01_Skin_01"
    elseif Index == 3 then
        NewSkinKey = "Table_01_Skin_02"
    end
    DecorateHandlerComp:ClientChangeSkinForActor("HomeDecor_Furnitures_Stool_02_Exprmtl_C_1", NewSkinKey)
end

decorator.lua_console_cmd(ClientOnly)
function t.TrialSkin(Index)
    ---@type OfficeManager
    local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
    local DecorateHandlerComp = OfficeManager:GetDecorationHandlerComp()
    local NewSkinKey = "Table_01_Basic"
    if Index == 2 then
        NewSkinKey = "Table_01_Skin_01"
    elseif Index == 3 then
        NewSkinKey = "Table_01_Skin_02"
    end
    DecorateHandlerComp:ClientTrialSkinForActor("HomeDecor_Furnitures_Stool_02_Exprmtl_C_1", NewSkinKey)
end

decorator.lua_console_cmd(ClientOnly)
function t.ChangeColor(PartIndex, ColorIndex)
    ---@type OfficeManager
    local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
    local DecorateHandlerComp = OfficeManager:GetDecorationHandlerComp()
    local Color = UE.FColor(255, 0, 0, 255)
    if ColorIndex == 2 then
        Color = UE.FColor(0, 255, 0, 255)
    elseif ColorIndex == 3 then
        Color = UE.FColor(0, 0, 255, 255)
    end
    DecorateHandlerComp:ClientChangeColorForActor("HomeDecor_Furnitures_Stool_02_Exprmtl_C_1", PartIndex, Color)
    --DecorateHandlerComp:GetOfficeSubsystem().ClientActorDecoratedEventDispatcher:Broadcast("HomeDecor_Furnitures_Stool_02_Exprmtl_C_1", {ActorID = "HomeDecor_Furnitures_Stool_02_Exprmtl_C_1"},
    --        {bFirstSync = false})
end

decorator.lua_console_cmd(ClientOnly)
function t.TrialColor(PartIndex, ColorIndex)
    ---@type OfficeManager
    local OfficeManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.OfficeManager)
    local DecorateHandlerComp = OfficeManager:GetDecorationHandlerComp()
    local Color = UE.FColor(255, 0, 0, 255)
    if ColorIndex == 2 then
        Color = UE.FColor(0, 255, 0, 255)
    elseif ColorIndex == 3 then
        Color = UE.FColor(0, 0, 255, 255)
    end
    DecorateHandlerComp:ClientTrialColorForActor("HomeDecor_Furnitures_Stool_02_Exprmtl_C_1", PartIndex, Color)
end


decorator.lua_console_cmd(ClientOnly)
function t.TestApprouter(MetaUID)
    local MsConfig = require("micro_service.ms_config")
    local RemoteMetaInvoker = require("micro_service.RemoteMetaInvoker")
    local AvatarInvoker = RemoteMetaInvoker.CreateGenericInvoker(MsConfig.AvatarEntityMetaName, 1)
    AvatarInvoker:Hello(
        {
            Msg = "Test Approuter"
        },
        function(ClientContext, Response)
            local Status = ClientContext:GetStatus()
            if Status:OK() then
                G.log:info("yongzyzhang", "TestApprouter receive response:%s ", utils.TableToString(Response))
            else
                G.log:error("yongzyzhang", "TestApprouter failed, frame code:%s return code:%s error msg", Status:GetFrameworkRetCode(), Status:GetFuncRetCode(), Status:ErrorMessage())
            end
        end
    )
end

decorator.lua_console_cmd(ServerOnly)
function t.DSTestAgent(MetaUID)
    local MsConfig = require("micro_service.ms_config")
    local RemoteMetaInvoker = require("micro_service.RemoteMetaInvoker")
    local AvatarInvoker = RemoteMetaInvoker.CreateGenericInvoker(MsConfig.AvatarEntityMetaName, 1)
    AvatarInvoker:Hello(
            {
                Msg = "DSTestAgent"
            },
            function(ClientContext, Response)
                local Status = ClientContext:GetStatus()
                if Status:OK() then
                    G.log:info("yongzyzhang", "DSTestAgent receive response:%s ", utils.TableToString(Response))
                else
                    G.log:error("yongzyzhang", "DSTestAgent failed, frame code:%s return code:%s error msg", Status:GetFrameworkRetCode(), Status:GetFuncRetCode(), Status:ErrorMessage())
                end
            end
    )
end


decorator.lua_console_cmd(ClientOnly)
function t.TestDecoratorRespawn()
    ---@type OfficeSubsystem
    local OfficeSubsystem = SubsystemUtils.GetOfficeSubsystem(p)
    local SkinDTConfig = OfficeSubsystem:GetOfficeDataTableRow("Table_01_Basic")
    if SkinDTConfig == nil then
        G.log:error("yongzyzhang", "Office Model is nil modelID: Table_01_Basic")
        return
    end
    local ActorBPClassName = tostring(SkinDTConfig.BP) .. "_C"
    G.log:error("yongzyzhang", "TestBPClassName name:%s", ActorBPClassName)
    local ActorBPClass = UE.UClass.Load(ActorBPClassName)
    G.log:error("yongzyzhang", "TestBPClassName class name:%s", tostring(ActorBPClass))

end

decorator.lua_console_cmd(ClientOnly)
function t.UseItem(ItemID, ItemNum, AvatarIndex)
    p.PlayerState.ItemManager:Server_UseItemForAvatarByExcelID(ItemID, ItemNum, AvatarIndex)
end

-- 攻击NPC
decorator.lua_console_cmd(ServerOnly)
function t.AttackNPC(NpcIds)
    for _, Value in pairs(NpcIds) do
        local NpcId = tostring(Value)
        local NpcActor = SubsystemUtils.GetMutableActorSubSystem(p):GetActor(NpcId)
        if NpcActor and NpcActor.NPCReactionComponent and NpcActor.NPCReactionComponent.OnPlayerAttacked then
            NpcActor.NPCReactionComponent:OnPlayerAttacked()
        end
    end
end

-- 治疗NPC
decorator.lua_console_cmd(ServerOnly)
function t.HealNPC(NpcIds)
    for _, Value in pairs(NpcIds) do
        local NpcId = tostring(Value)
        local NpcActor = SubsystemUtils.GetMutableActorSubSystem(p):GetActor(NpcId)
        if NpcActor and NpcActor.NPCReactionComponent and NpcActor.NPCReactionComponent.OnPlayerHealed then
            NpcActor.NPCReactionComponent:OnPlayerHealed()
        end
    end
end


-- 测试改变 NPC状态
decorator.lua_console_cmd(ServerOnly)
function t.ChangeNpcState(NpcIds, State)
    for _, Value in pairs(NpcIds) do
        local NpcId = tostring(Value)
        local NpcActor = SubsystemUtils.GetMutableActorSubSystem(p):GetActor(NpcId)
        if NpcActor and NpcActor.NpcStateMachineComponent then
            NpcActor.NpcStateMachineComponent:ChangeState(State)
        end
    end
end

-- 测试改变 NPC意图
decorator.lua_console_cmd(ServerOnly)
function t.ChangeNpcIntention(NpcIds, Intention)
    for _, Value in pairs(NpcIds) do
        local NpcId = tostring(Value)
        local NpcActor = SubsystemUtils.GetMutableActorSubSystem(p):GetActor(NpcId)
        if NpcActor and NpcActor.NpcIntentionComponent then
            NpcActor.NpcIntentionComponent:ChangeIntention(Intention)
        end
    end
end

decorator.lua_console_cmd(ClientOnly) 
function t.EquipAssistItem(AssistItemID)
    local PS = p.PlayerState
    PS.BP_AssistTeamComponent:Server_EquipAssistItem(AssistItemID)
end

decorator.lua_console_cmd(ClientOnly) 
function t.NpcChatTest()
    local lguiManager = "/Game/Developers/shiniingliu/Collections/LGUI/Frame/LGUIManager.LGUIManager_C"
    local EventSystemActor = "/Game/Developers/shiniingliu/Collections/LGUI/Frame/PresetEventSystemActor.PresetEventSystemActor_C"
    local UIDef = require('CP0032305_GH.Script.ui.ui_define')
    local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    local lguiManagerClass = UE.UClass.Load(lguiManager)
    local EventSystemActorClass = UE.UClass.Load(EventSystemActor)

    Player:GetWorld():SpawnActor(lguiManagerClass, Player:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, Player)
    Player:GetWorld():SpawnActor(EventSystemActorClass, Player:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, Player)

    closegm()
end

decorator.lua_console_cmd(ServerOnly) 
function t.StartLogicTrigger(GroupActorID, TriggerID)
    local GroupActorIdStr = tostring(GroupActorID)
    local TriggerIdStr = tostring(TriggerID)
    local GroupActor = SubsystemUtils.GetMutableActorSubSystem(p):GetActor(GroupActorIdStr)
    GroupActor.LogicTriggerComponent.OnTriggerStart:Broadcast(TriggerIdStr)
end

decorator.lua_console_cmd(ServerOnly) 
function t.StopLogicTrigger(GroupActorID, TriggerID)
    local GroupActorIdStr = tostring(GroupActorID)
    local TriggerIdStr = tostring(TriggerID)
    local GroupActor = SubsystemUtils.GetMutableActorSubSystem(p):GetActor(GroupActorIdStr)
    GroupActor.LogicTriggerComponent.OnTriggerEnd:Broadcast(TriggerIdStr)
end

decorator.lua_console_cmd(ClientOnly)
function t.TestPBEncodeAndDecode()
    local ModelAsset = {
        BasicModelKey = "Test Key",
        SkinAsset = {
            ["Test SKinID"] = {
                SkinID = "Test SKinID",
                State = 2,
                ComponentAsset = {
                }
            },
        }
    }
    local PB = require "pb"
    
    local ModelType = PB.type("HiGame.Office.OfficeBasicModel")
    if ModelType == nil then
        local PROTOC = require("micro_service.ProtocInstance")
        PROTOC:loadfile("Entities/OfficeService/Office.proto")
        G.log:info("yongzyzhang", "TestPBEncodeAndDecode Load ProtoFile")
    end
    ModelType = PB.type("HiGame.Office.OfficeBasicModel")
    G.log:info("yongzyzhang", "TestPBEncodeAndDecode ModelTypeInfo:%s", ModelType)

    local EncodeData = PB.encode("HiGame.Office.OfficeBasicModel", ModelAsset)
    local ResultTable = {}
    PB.decode("HiGame.Office.OfficeBasicModel", EncodeData, ResultTable)
    G.log:info("yongzyzhang", "TestPBEncodeAndDecode:%s", utils.TableToString(ResultTable))
end

decorator.lua_console_cmd(ClientOnly)
function t.TestPBOption()
    local PB = require "pb"
    local PROTOC = require("micro_service.ProtocInstance")
    PROTOC:loadfile("Services/OfficeService/office_ms_entity.proto")
    --local Option = PB.option("HiGame.Office.MSOfficeEntity.HiGame.AutoLoadOnServer")
    --G.log:info("yongzyzhang", "TestPBOption Option:%s", Option)
    local Service = PB.service("HiGame.Office.MSOfficeEntity")
    G.log:info("yongzyzhang", "TestPBOption Service:%s", utils.TableToString(Service))

    Option = Service.options["HiGame.AutoLoadOnServer"]
    G.log:info("yongzyzhang", "TestPBOption Option:%s", Option)

end



return RegisterLuaConsoleCmd()
