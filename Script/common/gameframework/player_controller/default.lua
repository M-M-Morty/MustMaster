require "UnLua"

local Actor = require("common.actor")
local G = require("G")
local TipsUtil = require("CP0032305_GH.Script.common.utils.tips_util")
local MsgCode = require("common.consts").MsgCode
local SWITCH_PLAYER_CD = "SWITCH_PLAYER_CD"
local SWITCH_PLAYER_DEAD = "SWITCH_PLAYER_DEAD"

---@class PlayerController
local PlayerController = Class(Actor)

PlayerController.__all_client_components__ = {
    InputComponent = "common.gameframework.player_controller.components.controller_input_component",
}

function PlayerController:Initialize(...)
    Super(PlayerController).Initialize(self, ...)
end

function PlayerController:ReceiveBeginPlay()
    self:EnableCheats()

    -- G.log:debug("yj", "PlayerController:ReceiveBeginPlay IsClient.%s IsServer.%s IsStandalone.%s", self:IsClient(), self:IsServer(), UE.UKismetSystemLibrary.IsStandalone(self))

    if self:IsClient() or UE.UKismetSystemLibrary.IsStandalone(self) then
        self:_AddClientComponent()
        self.OnPossessEvent:Add(self, self.OnPlayerPossessEvent)
    end

    if self:IsServer() or UE.UKismetSystemLibrary.IsStandalone(self) then
        local TeamInfo = self.ControllerSwitchPlayerComponent.TeamInfo
        self.CurCharType = TeamInfo[1]        
    end

    if self:IsServer() then
        UE.UHiUtilsFunctionLibrary.CreateHiGameplayDebuggerCategoryReplicator(self)
    end

    UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.PostBeginPlay}, 0.01, false)
end

function PlayerController:OnPlayerPossessEvent(InPawn, bPossess)
    self:SendMessage("OnPlayerPossessEvent", InPawn, bPossess)
end

function PlayerController:PostBeginPlay()
    G.log:info("InputMgr", "PostBeginPlay %s", self:IsClient())
    self:SendMessage("PostBeginPlay")
end

function PlayerController:ReceivePossess(PossessedPawn)
    --G.log:info("hycoldrain", "PlayerController:ReceivePossess  %s %s", G.GetDisplayName(PossessedPawn), tostring(PossessedPawn:IsServer()))
    self:SendServerMessage("OnReceivePossess", PossessedPawn)
end

function PlayerController:ReceiveUnPossess(UnpossessedPawn)
    --G.log:info("hycoldrain", "PlayerController:ReceiveUnPossess  %s  %s", G.GetDisplayName(UnpossessedPawn), tostring(UnpossessedPawn:IsServer()))
    self:SendServerMessage("OnReceiveUnPossess", UnpossessedPawn)
end

function PlayerController:_AddClientComponent()
    self:AddScriptComponent("InputComponent", true)
end

function PlayerController:ReceiveTick(DeltaSeconds)
    self:SendMessage("OnReceiveTick", DeltaSeconds)

    -- FIXME(hangyuewang): ItemManager迁移到PlayerState临时处理，CP代码修改完后删除下面代码
    if not self.ItemManager and self.PlayerState then
        self.ItemManager = self.PlayerState.ItemManager
    end
end

function PlayerController:SwitchPlayer(CharType, bPlayerDeadReason)

    G.log:info("devin", "PlayerController:SwitchPlayer")

    local NowMs = G.GetNowTimestampMs()
    if self.NextSwitchPlayerTime ~= 0 and self.NextSwitchPlayerTime > NowMs then
        TipsUtil.ShowCommonTips(SWITCH_PLAYER_CD)
        return
    end

    local ExtraInfo = Struct.BPS_SwitchPlayerExtraInfo()
    ExtraInfo.bPlayerDeadReason = bPlayerDeadReason
    self.ExtraInfo = ExtraInfo
    self:ServerSwitchPlayer(CharType, ExtraInfo)
end


function PlayerController:ServerSwitchPlayer_RPC(CharType, ExtraInfo)
    self.ExtraInfo = ExtraInfo
    local bPlayerDeadReason = ExtraInfo.bPlayerDeadReason
    if bPlayerDeadReason then
        self.NextSwitchPlayerTime = 0
    else
        local NowMs = G.GetNowTimestampMs()
        if self.NextSwitchPlayerTime ~= 0 and self.NextSwitchPlayerTime > NowMs then
            return
        end
    end

    local game_mode = UE.UGameplayStatics.GetGameMode(self)
    if not game_mode:PlayerCanRestart(self) then
        return false
    end

    if CharType == self.CurCharType then
        return false
    end

    local OldPlayer = self:K2_GetPawn()
    local TargetTransform
    if OldPlayer then
        TargetTransform = OldPlayer:GetTransform()
    end
    local NewPlayer, _ = self:GetOrCreateNewPlayer(CharType, TargetTransform)

    if bPlayerDeadReason then
        NewPlayer.SwitchPlayerComponent:ClearSwitchPlayerCD()
    else
        if not NewPlayer.SwitchPlayerComponent:IsSwitchPlayerCD_Ready() then
            self:Client_OnSwitchPlayerFail(CharType, SWITCH_PLAYER_CD)
            return false
        end
    end

    if NewPlayer:IsDead() then
        self:Client_OnSwitchPlayerFail(CharType, SWITCH_PLAYER_DEAD)
        return false
    end

    self.ActorToSwitchIn = NewPlayer
    if NewPlayer.bClientReady then
        -- 已经创建的Player直接切
        self:SendMessage("SwitchPlayer", OldPlayer, NewPlayer, "OnFinishSwitchPlayer")
    else
        -- 新创建的Player等到Server_OnPlayerClientCreate_RPC再切
    end

    return true
end

function PlayerController:Client_OnSwitchPlayerFail_RPC(CharType, MsgCode)
    TipsUtil.ShowCommonTips(MsgCode)
end

function PlayerController:Server_OnPlayerClientCreate_RPC(NewPlayer)
    if NewPlayer then
        NewPlayer.bClientReady = true
    end

    if self.ActorToSwitchIn == NewPlayer and NewPlayer then
        local OldPlayer = self:K2_GetPawn()
        self:SendMessage("SwitchPlayer", OldPlayer, NewPlayer, "OnFinishSwitchPlayer")
    end
end

function PlayerController:OnFinishSwitchPlayer(OldPlayer, NewPlayer)
    -- G.log:debug("yj", "PlayerController:StandaloneSwitchPlayer OldName.%s NewName.%s %s", OldPlayer:GetDisplayName(), NewPlayer:GetDisplayName(), self.UseSuperSkill)
    self:OnSwitchPlayerSuccess(OldPlayer.CharType, NewPlayer.CharType)
    self:OnSwitchPlayerSuccess_Client(OldPlayer.CharType, NewPlayer.CharType)
end


function PlayerController:OnSwitchPlayerSuccess(OldCharType, NewCharType)
    self.NextSwitchPlayerTime = G.GetNowTimestampMs() + self.SwitchPlayerCD * 1000    
    self.CurCharType = NewCharType    

    self:SendMessage("OnSwitchPlayerSuccess", OldCharType, NewCharType)
end


function PlayerController:OnSwitchPlayerSuccess_Client_RPC(OldCharType, NewCharType)
    self:OnSwitchPlayerSuccess(OldCharType, NewCharType)
end

function PlayerController:SendPlayerMessage(method_name, ...)
    local CurPlayer = self:K2_GetPawn()
    if CurPlayer.Vehicle then
        return
    end
    CurPlayer:SendMessage(method_name, ...)
end

function PlayerController:OnServerRoleDead(CharType)
    -- TODO
    self:StandaloneSwitchPlayer(4, false)
end

function PlayerController:OnClientRoleDead(CharType)
    self:SendMessage("OnRoleDead", CharType)
end

function PlayerController:GetOrCreateNewPlayer(CharType, Transform)
    local NewPlayer = self:GetCharacterByCharType(CharType)
    local IsNewCreate = false
    if not NewPlayer then
        local game_mode = UE.UGameplayStatics.GetGameMode(self)
        NewPlayer = game_mode:SpawnNewPlayerBySwitchPlayer(self, CharType, Transform)
        IsNewCreate = true
    end

    return NewPlayer, IsNewCreate
end

function PlayerController:F12_Pressed()
    self:SendMessage("F12_Pressed")
end

function PlayerController:GM_ClearAllActiveStates()
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        Player:GM_ClearAllActiveStates()
    end
end

function PlayerController:DoLuaString(LuaStr)
    G.log:warn("yj", "PlayerController:DoLuaString %s", LuaStr)
    if not self.LuaDebugWidget then
        self:SendMessage("CallLuaDebugWidget")
    end
    self.LuaDebugWidget:_DoCmd(LuaStr)
    self:SendMessage("CallLuaDebugWidget")
end

function PlayerController:ForwardMovementAction(Value)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:ForwardMovementAction(UE.UEnhancedInputLibrary.Conv_InputActionValueToAxis1D(Value))
        end
    end
end

function PlayerController:RightMovementAction(Value)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:RightMovementAction(UE.UEnhancedInputLibrary.Conv_InputActionValueToAxis1D(Value))
        end
    end
end

function PlayerController:CameraUpAction(Value)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:CameraUpAction(UE.UEnhancedInputLibrary.Conv_InputActionValueToAxis1D(Value))
        end
    end
end

function PlayerController:CameraRightAction(Value)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:CameraRightAction(UE.UEnhancedInputLibrary.Conv_InputActionValueToAxis1D(Value))
        end
    end
end

function PlayerController:CameraScaleAction(Value)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:CameraScaleAction(UE.UEnhancedInputLibrary.Conv_InputActionValueToAxis1D(Value))
        end
    end
end

function PlayerController:GetInVehicleAction(Value)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then 
        Player:SendMessage('GetInVehicleAction', UE.UEnhancedInputLibrary.Conv_InputActionValueToBool(Value))
    end
end

function PlayerController:SprintAction(Value)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        -- 在唤出LuaConsoleCmd的情况下，Shift键的效果要屏蔽，改用SendMessage可以达到动态屏蔽的效果
        Player:SendMessage("SprintAction", UE.UEnhancedInputLibrary.Conv_InputActionValueToBool(Value))
    end
end

function PlayerController:AimAction(Value)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:AimAction(UE.UEnhancedInputLibrary.Conv_InputActionValueToBool(Value))
        end
    end
end

function PlayerController:AttackAction(Value)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:AttackAction(UE.UEnhancedInputLibrary.Conv_InputActionValueToBool(Value))
        end
    end
end

function PlayerController:StanceAction()
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:StanceAction()
        end
    end
end

function PlayerController:WalkAction()
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:WalkAction()
        end
    end
end

function PlayerController:RagdollAction()
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:RagdollAction()
        end
    end
end

function PlayerController:VelocityDirectionAction()
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:VelocityDirectionAction()
        end
    end
end

function PlayerController:LookingDirectionAction()
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:LookingDirectionAction()
        end
    end
end

--- 长按触发的 action
function PlayerController:ChargeAction(Value)
    local Player = G.GetPlayerCharacter(self, 0)
    if Player then
        local InputComponent = Player:_GetComponent("BP_InputComponent", false)
        if InputComponent then
            InputComponent:ChargeAction(Value)
        end
    end
end

function PlayerController:GetCharacterByCharType(CharType)
    for i = 1, self.SwitchPlayers:Length() do
        local Character = self.SwitchPlayers:Get(i)        
        if Character and Character.CharType == CharType then
            G.log:info("hycoldrain", "get switch cd  %s %s  %s  %s", Character:GetDisplayName(), Character.CharType, CharType, self.SwitchPlayers:Length())
            return Character       
        end
    end
    return nil
end

function PlayerController:GetAvatarByIndex(Index)
    local CharType = self.ControllerSwitchPlayerComponent.TeamInfo[Index]
    if CharType == nil then
        return nil
    end

    for i = 1, self.SwitchPlayers:Length() do
        local Character = self.SwitchPlayers:Get(i)
        if Character and Character.CharType == CharType then
            return Character
        end
    end
    return nil
end

function PlayerController:GetSwitchPlayerCD(CharType)
    local SingleRemainTime = 0

    local Character = self:GetCharacterByCharType(CharType)
    if Character then
        SingleRemainTime = Character.SwitchPlayerComponent:GetSingleRemainTime()
    end

    local PublicRemainTime = 0 
    if self.NextSwitchPlayerTime ~= 0 then
        PublicRemainTime = self.NextSwitchPlayerTime - G.GetNowTimestampMs()
    end

    G.log:info("hycoldraincd", "get switch cd  %s %s", PublicRemainTime, SingleRemainTime)

    return math.max(0, SingleRemainTime, PublicRemainTime) / 1000.0
end 

--后续ItemManager组件可能不会挂在PlayerController上，封装下，外部尽量不要直接访问ItemManager这个变量
---@return BP_ItemManager
function PlayerController:GetItemManager()
    return self.ItemManager
end

function PlayerController:GetRemoteMetaInvoker(MetaType, MetaUID)
    local RemoteMetaInvoker = require("micro_service.RemoteMetaInvoker")
    return RemoteMetaInvoker.CreatePlayerContextInvoker(MetaType, MetaUID, self)
end

return RegisterActor(PlayerController)
