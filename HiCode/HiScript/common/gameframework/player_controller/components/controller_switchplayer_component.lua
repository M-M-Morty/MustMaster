local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local StateConflictData = require("common.data.state_conflict_data")
local switches = require("switches")
local G = require("G")
local t = require("t")
local SkillUtils = require("common.skill_utils")
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local Consts = require("common.consts")
local MsgCode = require("common.consts").MsgCode

local ControllerSwitchPlayerComponent = Component(ComponentBase)

local decorator = ControllerSwitchPlayerComponent.decorator

local SStage = {}
SStage.Begin = 0x00
SStage.OldFinish = 0x01
SStage.NewFinish = 0x10
SStage.NewSkillFinish = 0x100   -- 客户端技能是否初始化成功
SStage.AllFinish = 0x111

local SWITCH_PLAYER_TAG = "SWITCH_PLAYER_TAG"

function ControllerSwitchPlayerComponent:Initialize(...)
    Super(ControllerSwitchPlayerComponent).Initialize(self, ...)
end

function ControllerSwitchPlayerComponent:Start()
    Super(ControllerSwitchPlayerComponent).Start(self)

    self.bInQTE = false
    self.QTEAvailablePlayerList = {}    -- 等待触发 QTE 的角色 CharType 列表，触发完后会从列表中删除.
end

decorator.message_receiver()
function ControllerSwitchPlayerComponent:PostBeginPlay()
    self.actor.BP_InputManagerComponent:RegisterIMC(SWITCH_PLAYER_TAG, {"SwitchPlayer",}, {})
    --self.actor:SendMessage("RegisterIMC", SWITCH_PLAYER_TAG, {"SwitchPlayer",}, {})
end

function ControllerSwitchPlayerComponent:ReceiveEndPlay()
    self.actor:SendMessage("UnregisterIMC", SWITCH_PLAYER_TAG)
end

local function IsShowTeamUI(self)
    if self.actor.PlayerState.AreaType ~= Enum.Enum_AreaType.Office then
        return true
    end
    ---@type WBP_HUD_MainInterface
    local UIMainInterface = UIManager:GetUIInstance(UIDef.UIInfo.UI_MainInterfaceHUD.UIName)
    if not UIMainInterface then
        return false
    end
    return UIMainInterface:IsShowTeam()
end

decorator.message_receiver()
function ControllerSwitchPlayerComponent:Input_SwitchPlayer(Idx, UseSuperSkill)
    if not switches.EnableRoleSwitch then
        return
    end

    if not self.actor:IsClient() and not UE.UKismetSystemLibrary.IsStandalone(self.actor) then
        return
    end

    if not IsShowTeamUI(self) then
        return
    end

    if Idx > self.TeamInfo:Length() then
        return
    end

    local CurPlayer = self.actor:K2_GetPawn()
    local CharType = self.TeamInfo:Get(Idx)
    
    -- 同角色不能切换
    if CurPlayer then
        if CurPlayer.CharType == CharType then
            return
        end
    end

    -- 状态冲突检测
    if CurPlayer then
        local StateController = CurPlayer:_GetComponent("StateController", false)
        if StateController and not StateController:ExecuteAction(StateConflictData.Action_SwitchPlayer) then
            return
        end
    end
    
    self.actor:SwitchPlayer(CharType, false, self.bClientInQTE)
end

decorator.message_receiver()
function ControllerSwitchPlayerComponent:SwitchPlayer(OldPlayer, NewPlayer, CallbackName)
    -- QTE 中的换人处理
    if self.QTETimer and UE.UKismetSystemLibrary.K2_IsValidTimerHandle(self.QTETimer) then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.QTETimer)
        self.QTETimer = nil
        
        --QTE 换人判断
        if self.bInQTE and NewPlayer.CharType ~= self.NextQTECharType then
            self:EndQTE()
        end
    end

    local ActorLocation = OldPlayer:K2_GetActorLocation()
    local CameraRotation = OldPlayer:GetCameraRotation()
    CameraRotation.Pitch = 0.0

    local bInExtreme = OldPlayer.BuffComponent:HasPreAttackBuff()
    local bInBattle = OldPlayer.BattleStateComponent:IsInBattle()
    local bInAir = not OldPlayer:IsOnFloor()
    local bInQTE = self.bInQTE

    local ExtraInfo = self.actor.ExtraInfo
    ExtraInfo.bInExtreme = bInExtreme
    ExtraInfo.bInBattle = bInBattle
    ExtraInfo.bInAir = bInAir
    ExtraInfo.bInQTE = bInQTE

    --G.log:debug("hycoldrain", "SwitchPlayer......CamraRotation    %s  %s", CameraRotation, OldPlayer:K2_GetActorRotation(), OldPlayer:IsServer())

    -- TODO. 施工中
    self:Multicast_RecordSwitchState(OldPlayer, NewPlayer)
    self:BeforeSwitch(OldPlayer, NewPlayer, ActorLocation, CameraRotation)
    self:BeforeSwitch_Client(OldPlayer, NewPlayer, ActorLocation, CameraRotation)

    self.actor:UnPossess()
    self.actor:Possess(NewPlayer)

    NewPlayer.BattleStateComponent.InBattle = bInBattle

    NewPlayer:SendMessage("OnNewPlayerSwitchIn_RunOnServer",bInBattle, bInExtreme, bInAir)
    if bInExtreme then
        OldPlayer.BuffComponent:RemovePreAttackBuff()
    end

    -- 角色刚切入时，QTE 一定未显示.
    self.bQTEStarted = false
    
    -- TODO. 施工中
    self:Multicast_InheritSwitchState(OldPlayer, NewPlayer)
    self:AfterSwitch(OldPlayer, NewPlayer, ExtraInfo)
    self:AfterSwitch_Client(OldPlayer, NewPlayer, ExtraInfo)
    self.actor[CallbackName](self.actor, OldPlayer, NewPlayer)
end

function ControllerSwitchPlayerComponent:BeforeSwitch(OldPlayer, NewPlayer, OrgLocation, OrgRotation)
    OldPlayer:SendMessage("OnReceiveMessageBeforeSwitchOut")    
    NewPlayer:SendMessage("OnRecieveMessageBeforeSwitchIn", OrgLocation, OrgRotation, OldPlayer)
end

function ControllerSwitchPlayerComponent:BeforeSwitch_Client_RPC(OldPlayer, NewPlayer, OrgLocation, OrgRotation)    
    OldPlayer:SendMessage("EndCurrentZeroGravity")    
    self:BeforeSwitch(OldPlayer, NewPlayer, OrgLocation, OrgRotation)   
    self.SwitchStage = SStage.Begin

    if NewPlayer.SkillComponent.bSkillInited then
        -- 技能初始化只在第一次切人才会回调，这里读取之前保存的技能初始化状态
        self.SwitchStage = bit.bor(self.SwitchStage, SStage.NewSkillFinish)
    end
end

function ControllerSwitchPlayerComponent:AfterSwitch(OldPlayer, NewPlayer, ExtraInfo)
    OldPlayer:SendMessage("OnReceiveMessageAfterSwitchOut")
    NewPlayer:SendMessage("AfterSwitchIn", OldPlayer, NewPlayer, ExtraInfo)
end

function ControllerSwitchPlayerComponent:AfterSwitch_Client_RPC(OldPlayer, NewPlayer, ExtraInfo)
    NewPlayer:SendClientMessage("CloneGait", OldPlayer)
    if self.SwitchStage == SStage.AllFinish then
        -- 确保NewPlayer的LocalRole是AutonomousProxy，OldPlayer的LocalRole不确定
        --NewPlayer.CharacterStateManager.SwitchPlayer = true    
        OldPlayer:SendClientMessage("OnPlayerSwitchOut")
        self:AfterSwitch(OldPlayer, NewPlayer, ExtraInfo)
    else
        -- 要通过蓝图引用保存下 ExtraInfo 结构体，否则会被 GC.
        self.CallbackExtraInfo = ExtraInfo
        self.SwitchFinishCallbackFunc = function(ExtraInfo)
            self:AfterSwitch_Client(OldPlayer, NewPlayer, ExtraInfo)
        end
    end
end

function ControllerSwitchPlayerComponent:CheckSwitchStageFinish()
    if self.SwitchStage == SStage.AllFinish then
        if self.SwitchFinishCallbackFunc then
            self.SwitchFinishCallbackFunc(self.CallbackExtraInfo)
            self.SwitchFinishCallbackFunc = nil
        end
    end
end

decorator.message_receiver()
function ControllerSwitchPlayerComponent:OnPlayerPossessEvent(InPawn, bPossess)
    if bPossess then
        self.SwitchStage = bit.bor(self.SwitchStage, SStage.NewFinish)
    else
        self.SwitchStage = bit.bor(self.SwitchStage, SStage.OldFinish)
    end

    self:CheckSwitchStageFinish()
end

decorator.message_receiver()
function ControllerSwitchPlayerComponent:OnClientPlayerSkillInited()
    self.SwitchStage = bit.bor(self.SwitchStage, SStage.NewSkillFinish)
    self:CheckSwitchStageFinish()
end

---客户端 SwitchIn 完成后通知服务器
function ControllerSwitchPlayerComponent:Server_AfterClientSwitchIn_RPC()
    G.log:debug(self.__TAG__, "Server_AfterClientSwitchIn")
end

function ControllerSwitchPlayerComponent:Server_StartQTE_RPC()
    G.log:debug(self.__TAG__, "Server_StartQTE")
    self:StartQTE()
end

function ControllerSwitchPlayerComponent:Server_EndQTE_RPC()
    G.log:debug(self.__TAG__, "Server_EndQTE")
    self:EndQTE()
end

-- decorator.message_receiver()
-- function ControllerSwitchPlayerComponent:OnReceivePossess(PossessedPawn)
--     if PossessedPawn.MutableActorComponent then
--         PossessedPawn.MutableActorComponent.DeadDelegate:Add(self, self.OnCurrentPlayerDead)
--     end
-- end

-- decorator.message_receiver()
-- function ControllerSwitchPlayerComponent:OnReceiveUnPossess(UnpossessedPawn)
--     if PossessedPawn.MutableActorComponent then
--         UnpossessedPawn.MutableActorComponent.DeadDelegate:Remove(self, self.OnCurrentPlayerDead)
--     end
-- end

function ControllerSwitchPlayerComponent:ReceiveBeginPlay()
    Super(ControllerSwitchPlayerComponent).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("ControllerSwitchPlayerComponent(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
end

decorator.message_receiver()
function ControllerSwitchPlayerComponent:OnCurrentPlayerDead(DeadReason)
    local CurPawn = self.actor:K2_GetPawn()
    local CurCharType = CurPawn.CharType
    self.DeadCharTypes:Add(CurCharType)
    G.log:debug(self.__TAG__, "OnCurrentPlayerDead, CharType: %s, TeamInfo: %s, DeadInfo: %s", CurCharType, utils.TArrayToString(self.TeamInfo), utils.TSetToString(self.DeadCharTypes))

    if self.bInQTE then
        self:EndQTE()
    end

    local CurTeamInfoKey = 0
    for Ind = 1, self.TeamInfo:Length() do
        local CharType = self.TeamInfo:Get(Ind)
        if CharType == CurCharType then
            CurTeamInfoKey = Ind
        end
    end

    if CurTeamInfoKey == 0 then
        G.log:error(self.__TAG__, "OnCurrentPlayerDead, Cur team info key is 0")
        return
    end

    for _ = 1, self.TeamInfo:Length() do
        local NextKey = CurTeamInfoKey % self.TeamInfo:Length() + 1
        local NewCharType = self.TeamInfo:Get(NextKey)
        if NewCharType and not self.DeadCharTypes:Contains(NewCharType) then
            G.log:debug(self.__TAG__, "OnCurrentPlayerDead, ServerSwitchPlayer")

            local ExtraInfo = Struct.BPS_SwitchPlayerExtraInfo()
            ExtraInfo.bPlayerDeadReason = true
            self.actor:ServerSwitchPlayer(NewCharType, ExtraInfo)
            return
        end

        CurTeamInfoKey = NextKey
    end

    -- All player dead.
    G.log:debug(self.__TAG__, "OnCurrentPlayerDead, All player dead.")

    -- 

    local DeadPoint = CurPawn:K2_GetActorLocation()
    self:Client_OnAllPlayerDead(DeadPoint, DeadReason)
end

function ControllerSwitchPlayerComponent:Client_OnAllPlayerDead_RPC(DeadPoint, DeadReason)
    G.log:debug(self.__TAG__, "Client OnAllPlayerDead reason: %s", tostring(DeadReason))
    -- 获取死亡原因对应的提示信息
    local DeadReasonInfo = self.DeadReasonMap:Find(DeadReason)
    if not DeadReasonInfo then
        G.log:warn(self.__TAG__, "Dead reason map not config key: %s", tostring(DeadReason))
    end

    self.actor:SendMessage(MsgCode.AllPlayerDead, DeadPoint, DeadReasonInfo)
end

function ControllerSwitchPlayerComponent:CheckAvatarAllDead()
    for Index = 1, self.TeamInfo:Length() do
        local NewCharType = self.TeamInfo:Get(Index)
        if NewCharType and not self.DeadCharTypes:Contains(NewCharType) then
            return false;
        end
    end

    return true;
end

decorator.message_receiver()
function ControllerSwitchPlayerComponent:ReliveInRelivePoint(DeadPoint)
    G.log:debug(self.__TAG__, "ReliveInRelivePoint, send to server")
    self:Server_ReliveInRelivePoint(DeadPoint)
end

function ControllerSwitchPlayerComponent:Server_ReliveInRelivePoint_RPC(DeadPoint)
    -- 找最近的复活点
    local RelivePoints = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsWithTag(self.actor:GetWorld(), Consts.RelivePointTag, RelivePoints)

    if RelivePoints:Length() == 0 then
        G.log:error(self.__TAG__, "ReliveInRelivePoint fail, no relive points found!")
        return
    end

    local MinDis = -1
    local RPInd = -1
    for Ind = 1, RelivePoints:Length() do
        local CurRP = RelivePoints:Get(Ind)
        local CurDis = UE.UKismetMathLibrary.Vector_DistanceSquared(CurRP:K2_GetActorLocation(), DeadPoint)
        if RPInd == -1 or CurDis < MinDis then
            MinDis = CurDis
            RPInd = Ind
        end
    end

    local TargetRP = RelivePoints:Get(RPInd)
    G.log:debug(self.__TAG__, "ReliveInRelivePoint found relive point: %s", G.GetObjectName(TargetRP))

    -- TODO loading 界面

    self:ReliveAllPlayers(TargetRP, true)
end

--- 复活所有的角色
---@param RelivePointActor AActor 复活点对应的 Actor
---@param bOnlyBackRoles boolean 是否只复活后台角色（用于前台角色未死亡情况）
decorator.message_receiver()
function ControllerSwitchPlayerComponent:ReliveAllPlayers(RelivePointActor, bAllRoles)
    -- 获取复活点位置
    local RPLocation = RelivePointActor:K2_GetActorLocation()
    local CurWorld = self.actor:GetWorld()
    local TargetReliveLocation = UE.FVector()
    UE.UNavigationSystemV1.GetNavigationSystem(CurWorld).K2_GetRandomReachablePointInRadius(CurWorld, RPLocation, TargetReliveLocation, RelivePointActor.Radius)

    local TeamInfo = self.TeamInfo
    for Ind = 1, TeamInfo:Length() do
        local ReliveChar = function(CharType)
            local NewPlayer, IsNewCreate = self.actor:GetOrCreateNewPlayer(CharType)
            NewPlayer.SwitchPlayerComponent:ClearSwitchPlayerCD()

            -- 复活后属性初始化
            local GEList = RelivePointActor.GEList
            for Ind = 1, GEList:Length() do
                local GEClass = GEList:Get(Ind)
                NewPlayer.AbilitySystemComponent:BP_ApplyGameplayEffectToSelf(GEClass, 0, nil)
            end

            local bFront = false
            if bAllRoles then
                -- 所有角色都死亡时，选取队伍中第一个角色作为前台角色
                bFront = Ind == 1
            end

            local CapsuleHeight = NewPlayer.CapsuleComponent.CapsuleHalfHeight
            local ReliveTransform = UE.UKismetMathLibrary.MakeTransform(TargetReliveLocation + UE.FVector(0, 0, CapsuleHeight), UE.FRotator(0, 0, 0), UE.FVector(1, 1, 1))
            self:OnFinishRelivePlayer(NewPlayer, ReliveTransform, bFront)
        end

        local CharType = TeamInfo:Get(Ind)
        if self.DeadCharTypes:Contains(CharType) then
            ReliveChar(CharType)
        end
    end

    self.DeadCharTypes:Clear()
end

decorator.message_receiver()
function ControllerSwitchPlayerComponent:OnFinishRelivePlayer(NewPlayer, NewTransform, bFront)
    G.log:debug(self.__TAG__, "OnFinishRelivePlayer %s", G.GetObjectName(NewPlayer))

    if bFront then
        self.actor.CurCharType = NewPlayer.CharType
        NewPlayer:SendMessage("ReceiveBeforeSwitchIn")
        NewPlayer:K2_SetActorTransform(NewTransform, false, nil, true)

        self.actor:UnPossess()
        self.actor:Possess(NewPlayer)
    end

    self:Client_AfterRelive(NewPlayer, NewTransform, bFront)
end

function ControllerSwitchPlayerComponent:Client_AfterRelive_RPC(NewPlayer, NewTransform, bFront)
    G.log:debug(self.__TAG__, "Client_AfterRelive player: %s, bFront: %s", G.GetObjectName(NewPlayer), bFront)
    if bFront then
        self.actor.CurCharType = NewPlayer.CharType
        NewPlayer:SendMessage("ReceiveBeforeSwitchIn")
        NewPlayer:K2_SetActorTransform(NewTransform, false, nil, true)
    end
    
    --NewPlayer:K2_GetRootComponent():SetVisibility(bFront, true)
    NewPlayer:SetVisibility_RepNotify(bFront,true)
    NewPlayer:SendMessage(MsgCode.ClearAllStates)
end

-- 切换到主角
ControllerSwitchPlayerComponent.MainCharType = 1
decorator.message_receiver()
function ControllerSwitchPlayerComponent:SwitchToMainPlayer()
    if self.actor:IsClient() then
        self:Server_SwitchToMainPlayer()
        return
    end
    self.SwitchBackCharType = self.actor:K2_GetPawn().CharType
    self.actor:SwitchPlayer(ControllerSwitchPlayerComponent.MainCharType, false)
end

-- 从主角切回
decorator.message_receiver()
function ControllerSwitchPlayerComponent:SwitchBackFromMainPlayer()
    if self.actor:IsClient() then
        self:Server_SwitchBackFromMainPlayer()
        return
    end

    if self.actor:K2_GetPawn().CharType ~= ControllerSwitchPlayerComponent.MainCharType then
        return
    end

    self.actor:SwitchPlayer(self.SwitchBackCharType, false)
end

-- 切换到主角RPC
decorator.message_receiver()
function ControllerSwitchPlayerComponent:Server_SwitchToMainPlayer_RPC()
    self:SwitchToMainPlayer()
end

-- 从主角切回RPC
decorator.message_receiver()
function ControllerSwitchPlayerComponent:Server_SwitchBackFromMainPlayer_RPC()
    self:SwitchBackFromMainPlayer()
end

---触发 QTE 流程，连续超级登场技（释放超级登场技不消耗）
---@param bFromSwitchInSuper boolean 是否来自超级登场技
function ControllerSwitchPlayerComponent:TriggerQTE(bFromSwitchInSuper)
    if self.bInQTE then
        G.log:debug(self.__TAG__, "Already in QTE, not duplicate trigger.")
        return
    end

    local CurPlayer = self.actor:K2_GetPawn()

    if not self.bInQTE then
        -- 初始化 QTE 切人列表
        self.QTEAvailablePlayerList = {}

        for Ind = 1, self.TeamInfo:Length() do
            local CharType = self.TeamInfo:Get(Ind)
            if not self.DeadCharTypes:Contains(CharType) then
                local bCanTrigger = true
                -- 如果 QTE 的触发来源为当前角色的超级登场技，需要通过开关判断是否当前角色后续继续在可触发 QTE 的列表中.
                if CharType == CurPlayer.CharType and bFromSwitchInSuper and not self.bCanSelfTriggerQTEWhenSuper then
                    bCanTrigger = false
                end

                if bCanTrigger then
                    table.insert(self.QTEAvailablePlayerList, CharType)
                end
            end
        end

        if #self.QTEAvailablePlayerList == 0 then
            G.log:warn(self.__TAG__, "QTE no available players.")
            return
        end
    end

    self.bInQTE = true

    self:StartQTE(true)
end

function ControllerSwitchPlayerComponent:StartQTE(bFirstTrigger)
    if not self.bInQTE or self.bQTEStarted then
        return
    end

    -- QTE 是否已经处理过
    self.bQTEStarted = true

    -- 随机一个在 available 列表中的非当前玩家.
    local CurPlayer = self.actor:K2_GetPawn()
    -- 将已触发的角色从待触发列表中移除(当前角色）
    if not bFirstTrigger then
        for Ind, CharType in ipairs(self.QTEAvailablePlayerList) do
            if CharType == CurPlayer.CharType then
                table.remove(self.QTEAvailablePlayerList, Ind)
                break
            end
        end
    end

    if #self.QTEAvailablePlayerList == 0 then
        G.log:debug(self.__TAG__, "StartQTE not left available players")
        self:EndQTE()
        return
    end

    -- QTE 触发次数统计
    if not self.CurQTEInd then
        self.CurQTEInd = 1
    end

    G.log:debug(self.__TAG__, "StartQTE index: %d", self.CurQTEInd)

    local QTETime = 2.0 -- 给个默认时间，防止蓝图中没配置报错.
    if self.QTETimeList:Length() > 0 then
        if self.CurQTEInd > self.QTETimeList:Length() then
            self.CurQTEInd = self.QTETimeList:Length()
        end

        QTETime = self.QTETimeList:Get(self.CurQTEInd)
    end

    self.CurQTEInd = self.CurQTEInd + 1

    -- 随机一个在 available 列表中的非当前玩家.
    self.NextQTECharType  = self.QTEAvailablePlayerList[math.random(#self.QTEAvailablePlayerList)]
    while self.NextQTECharType == CurPlayer.CharType do
        self.NextQTECharType  = self.QTEAvailablePlayerList[math.random(#self.QTEAvailablePlayerList)]
    end
    local CharInd = self.TeamInfo:Find(self.NextQTECharType )
    self:Client_OnStartQTE( CharInd, QTETime)

    -- 添加 QTE 触发倒计时
    self.QTETimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.EndQTE}, QTETime, false)
end

function ControllerSwitchPlayerComponent:EndQTE()
    if not self.bInQTE then
        return
    end

    G.log:debug(self.__TAG__, "EndQTE")
    self.bInQTE = false
    self.CurQTEInd = 1
    self.NextQTECharType = 0
    self:Client_OnEndQTE()
end

function ControllerSwitchPlayerComponent:Client_OnStartQTE_RPC(CharInd, QTETime)
    G.log:debug(self.__TAG__, "OnStartQTE CharInd: %d, QTETime: %s", CharInd, tostring(QTETime))
    self.bClientInQTE = true
    
    -- 通知 UI 显示 QTE 的按钮（换人按钮)
    self.actor:SendMessage(MsgCode.ShowQTE, CharInd, QTETime)
end

function ControllerSwitchPlayerComponent:Client_OnEndQTE_RPC()
    G.log:debug(self.__TAG__, "OnEndQTE.")
    self.bClientInQTE = false
    
    self.actor:SendMessage(MsgCode.EndQTE)
end

decorator.message_receiver()
function ControllerSwitchPlayerComponent:AfterFirstPlayerLogin()
    G.log:debug(self.__TAG__, "AfterFirstPlayerLogin init all other players in team.")

    -- 第一个角色初始化后，初始化队伍中其他的后台角色.
    local TeamInfo = self.TeamInfo
    for Ind = 2, TeamInfo:Length() do
        local InitChar = function(CharType)
            local NewPlayer, _ = self.actor:GetOrCreateNewPlayer(CharType)
            --NewPlayer:K2_GetRootComponent():SetVisibility(false, true)
            NewPlayer:SetVisibility_RepNotify(false,true)
            NewPlayer.SwitchPlayerComponent:ClearSwitchPlayerCD()
        end

        InitChar(TeamInfo:Get(Ind))
    end
end

-- 管理切换角色的状态继承
function ControllerSwitchPlayerComponent:Multicast_RecordSwitchState_RPC(OldPlayer, NewPlayer)
    self.OldVelocity = OldPlayer.CharacterMovement.Velocity
    self.OldAcceleration = OldPlayer.CharacterMovement:GetCurrentAcceleration()
    self.OldMoveMode = OldPlayer.CharacterMovement.MovementMode
end

function ControllerSwitchPlayerComponent:Multicast_InheritSwitchState_RPC(OldPlayer, NewPlayer)
    G.log:debug(self.__TAG__, "[dsh] Inherit switch character state start.")
    local ExtraInfo = self.actor.ExtraInfo
    -- 战斗切人
    if ExtraInfo.bInBattle then
        -- do nothing
    else
        local Velocity = self.OldVelocity
        if UE.UKismetMathLibrary.VSizeXY(Velocity) > 0 then
            self:InheritSwitchState(OldPlayer, NewPlayer)
            UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({self, function() self:InheritSwitchState(OldPlayer, NewPlayer)  end})
            --UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, function() self:InheritSwitchState(OldPlayer, NewPlayer)  end}, 0.01, false)
        end
    end
end

function ControllerSwitchPlayerComponent:InheritSwitchState(OldPlayer, NewPlayer)
    -- 继承角色的移动状态
    -- 如果OldPlayer处于Flying状态，新角色进入falling，否则会悬浮
    if self.OldMoveMode == UE.EMovementMode.MOVE_Flying or self.OldMoveMode == UE.EMovementMode.MOVE_Custom then
        NewPlayer.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
    else
        NewPlayer.CharacterMovement:SetMovementMode(self.OldMoveMode)
    end
    NewPlayer.CharacterMovement.LastUpdateVelocity = self.OldVelocity
    NewPlayer.CharacterMovement.Velocity = self.OldVelocity
    NewPlayer.CharacterMovement:SetCurrentAcceleration(self.OldAcceleration)
    -- 继承角色的输入
    NewPlayer:AddMovementInput(self.OldVelocity, 1.0)
    -- 跳过角色旋转更新
    NewPlayer:GetLocomotionComponent():SetSkipUpdateRotation()
    NewPlayer.Mesh:GetLinkedAnimGraphInstanceByTag("Locomotion"):SetSkipUpdateAnimatedYawOffset()
end

return ControllerSwitchPlayerComponent
