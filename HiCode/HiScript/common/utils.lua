local G = require("G")
local StateConflictData = require("common.data.state_conflict_data")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

utils = {}


function utils.get_dict_length(dictobj)
    local n = 0
    for k, v in pairs(dictobj) do
        n = n + 1
    end
    return n
end

function utils.get_dict_acc_value(dictobj)
    local n = 0
    for k, v in pairs(dictobj) do
        n = n + v
    end

    return n
end

function utils.is_dict_empty(dictobj)
    for k, v in pairs(dictobj) do
        return false
    end
    return true
end

function utils.merge_table(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = v
        elseif type(v) == "table" and type(dst[k]) == "table" then
            utils.merge_table(dst[k], v)
        end
    end
end

function utils.merge_array(dst, src)
    for idx, ele in pairs(src) do
        table.insert(dst, ele)
    end
end

-- two array
function utils.intersection(t_a, t_b)
    ret = {}
    for _, v_a in ipairs(t_a) do
        for _, v_b in ipairs(t_b) do
            if v_a == v_b then
                table.insert(ret, v_a)
                break
            end
        end
    end
    return ret
end

function utils.find(arrayobj, value)
    for k, v in ipairs(arrayobj) do
        if v == value then
            return k
        end 
    end
    return 0
end

function utils.dict_find(dictobj, key)
    for k, v in pairs(dictobj) do
        if k == key then
            return v
        end 
    end
    return nil
end

function utils.insert_priority_array(arrayobj, data, key, desc)

    local priority_v = data[key]

    for idx, ele in ipairs(arrayobj) do
        if true == desc and priority_v > ele[key] then
            table.insert(arrayobj, idx, data)
            return

        elseif false == desc and priority_v < ele[key] then
            table.insert(arrayobj, idx, data)
            return
        end
    end

    table.insert(arrayobj, data)
end

function utils.dict_len(dictobj)
    local len = 0
    for k, v in pairs(dictobj) do
        len = len + 1
    end
    return len
end

function utils.DoDelay(WorldContectObject, InDuration, InFunction, ...)     
    local arg = {...}
    local co = coroutine.create(
    function(WorldContectObject, InDuration)            
            UE.UKismetSystemLibrary.Delay(WorldContectObject, InDuration)             
            InFunction(table.unpack(arg))
        end
    )
    coroutine.resume(co, WorldContectObject, InDuration)    
end

function utils.ToString(Arr)
    local Ret = ""
    if not Arr then
        return Ret
    end

    if type(Arr) ~= "table" then
        return Arr
    end

    Ret = "["
    for _, Val in ipairs(Arr) do
        Ret = Ret .. Val .. ", "
    end
    Ret = Ret .. "]"

    return Ret
end

--- 打印表内容
---@overload fun(tbl: table):string
---@param TableToPrint table
---@param MaxIntent number
---@return string
function utils.TableToString(TableToPrint, MaxIntent)
    local HandlerdTable = {}
    local function ItretePrintTable(TP, Indent)
        if not Indent then Indent = 0 end
        if type(TP) ~= "table" then return tostring(TP) end

        if(Indent > MaxIntent) then return tostring(TP) end

        if HandlerdTable[TP] then
            return "";
        end
        HandlerdTable[TP] = true
        local StrToPrint = string.rep(" ", Indent) .. "{\r\n"
        Indent = Indent + 2
        for k, v in pairs(TP) do
            StrToPrint = StrToPrint .. string.rep(" ", Indent)
            if (type(k) == "number") then
                StrToPrint = StrToPrint .. "[" .. k .. "] = "
            elseif (type(k) == "string") then
                StrToPrint = StrToPrint  .. k ..  "= "
            else
                StrToPrint = StrToPrint  .. tostring(k) ..  " = "
            end
            if (type(v) == "number") then
                StrToPrint = StrToPrint .. v .. ",\r\n"
            elseif (type(v) == "string") then
                StrToPrint = StrToPrint .. "\"" .. v .. "\",\r\n"
            elseif (type(v) == "table") then
                StrToPrint = StrToPrint .. tostring(v) .. ItretePrintTable(v, Indent + 2) .. ",\r\n"
            else
                StrToPrint = StrToPrint .. "\"" .. tostring(v) .. "\",\r\n"
            end
        end
        StrToPrint = StrToPrint .. string.rep(" ", Indent-2) .. "}"
        return StrToPrint
    end

    if MaxIntent == nil then
        MaxIntent = 64
    end
    return ItretePrintTable(TableToPrint)
end

function utils.TArrayToString(TArr)
    local Ret = "["
    for Ind = 1, TArr:Length() do
        Ret = Ret .. TArr:Get(Ind) .. ", "
    end
    Ret = Ret .."]"

    return Ret
end

function utils.TSetToString(TSet)
    return utils.TArrayToString(TSet:ToArray())
end

function utils.DumpTArray(array)
    local ret = {}
    for i = 1, array:Length() do
        table.insert(ret, array:Get(i))
    end
    return "[" .. table.concat(ret, ",") .. "]"
end

function utils.PrintString(text, color, duration)
    color = color or UE.FLinearColor(1, 1, 1, 1)
    duration = duration or 100
    UE.UKismetSystemLibrary.PrintString(nil, text, true, false, color, duration)
end

function utils.GetDis(Pos1, Pos2)
    return math.sqrt((Pos1.X - Pos2.X)^2 + (Pos1.Y - Pos2.Y)^2 + (Pos1.Z - Pos2.Z)^2)
end

function utils.GetDisSquare(Pos1, Pos2)
    return (Pos1.X - Pos2.X)^2 + (Pos1.Y - Pos2.Y)^2 + (Pos1.Z - Pos2.Z)^2
end

---Get source point to target actor or component nearest distance.
---@param SourcePoint FVector source point
---@param TargetActor AActor target actor
---@param TargetComp UPrimitiveComponent target component (Priority use this if not nil)
---@return number target min distance
---@return FVector target location
---@return UPrimitiveComponent out component.
function utils.GetTargetNearestDistance(SourcePoint, TargetActor, TargetComp)
    local TargetDis, TargetLocation, OutComp
    if TargetComp then
        TargetDis, TargetLocation = UE.UHiUtilsFunctionLibrary.GetNearestDistanceToComponent(SourcePoint, TargetComp)
        OutComp = TargetComp
    elseif TargetActor then
        TargetDis, TargetLocation, OutComp = UE.UHiUtilsFunctionLibrary.GetNearestDistanceToActor(SourcePoint, TargetActor, UE.ECollisionChannel.ECC_Pawn)
    end

    if not TargetDis or TargetDis < 0 then
        TargetLocation = nil
        if TargetComp then
            TargetLocation = TargetComp:K2_GetComponentLocation()
            TargetDis = utils.GetDis(TargetLocation, SourcePoint)
        elseif TargetActor then
            TargetLocation = TargetActor:K2_GetActorLocation()
            TargetDis = utils.GetDis(TargetLocation, SourcePoint)
        end
    end

    return TargetDis, TargetLocation, OutComp
end

function utils.GetNearestComponent(SourceLocation, Comps)
    local MinDis
    local FoundComp, FoundLocation
    for Ind = 1, Comps:Length() do
        local CurComp = Comps:Get(Ind)
        local CurDis, CurLocation = utils.GetTargetNearestDistance(SourceLocation, nil, CurComp)
        if not MinDis or CurDis < MinDis then
            MinDis = CurDis
            FoundComp = CurComp
            FoundLocation = CurLocation
        end
    end

    return MinDis, FoundLocation, FoundComp
end

function utils.FormatValue(val)
    if type(val) == "string" then
        return string.format("%q", val)
    end
    return tostring(val)
end

function utils.FormatTable(t, tabcount)
    
    tabcount = tabcount or 0
    tabcount = math.min(tabcount, 5)

    local str = ""
    if type(t) == "table" then
        for k, v in pairs(t) do
            local tab = string.rep("\t", tabcount)
            if type(v) == "table" then
                str = str..tab..string.format("[%s] = {", utils.FormatValue(k))..'\n'
                str = str..utils.FormatTable(v, tabcount + 1)..tab..'}\n'
            else
                str = str..tab..string.format("[%s] = %s", utils.FormatValue(k), utils.FormatValue(v))..',\n'
            end
        end
    else
        str = str..tostring(t)..'\n'
    end

    return str
end

function utils.StrSplit(s, delimiter)
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result
end

function utils.GetMillisUntilNow(BeginDateTime)
    return utils.GetMillisElapsed(BeginDateTime, UE.UKismetMathLibrary.Now())
end

function utils.GetSecondsUntilNow(BeginDateTime)
    return utils.GetMillisUntilNow(BeginDateTime) / 1000.0
end

function utils.GetMillisElapsed(BeginDateTime, EndDateTime)
    local TimeSpan = UE.UKismetMathLibrary.Subtract_DateTimeDateTime(EndDateTime, BeginDateTime)
    return UE.UKismetMathLibrary.GetTotalMilliseconds(TimeSpan)
end

function utils.GetSecondsElapsed(BeginDateTime, EndDateTime)
    return utils.GetMillisElapsed(BeginDateTime, EndDateTime) / 1000.0
end

function utils.MakeUserData()
    local UserDataClass = UE.UClass.Load("Blueprint'/Game/Blueprints/Common/UserData/UD_Common.UD_Common_C'")
    return NewObject(UserDataClass)
end

function utils.GetFeetLocation(Actor)
    local Location = Actor:K2_GetActorLocation()
    if Actor.CapsuleComponent then
        Location.Z = Location.Z - Actor.CapsuleComponent:GetScaledCapsuleHalfHeight()
    end
    return Location
end

function utils.D_N2P(degree)
    -- negative degree to positive degree
    if degree < 0.0 then
        return degree + 360.0
    else
        return degree
    end
end

function utils.SmoothActorLocation(Actor, TargetLocation, InterpSpeed, DeltaTime)
    local SmoothLocation = UE.UKismetMathLibrary.VInterpTo_Constant(Actor:K2_GetActorLocation(), TargetLocation, DeltaTime, InterpSpeed)
    Actor:K2_SetActorLocation(SmoothLocation, false, nil, false)
end

function utils.SmoothActorRotation(Actor, TargetRotation, Target, TargetInterpSpeed, ActorInterpSpeed, DeltaTime)
    TargetRotation = UE.UMathHelper.RNearestInterpConstantTo(TargetRotation, Target, DeltaTime, TargetInterpSpeed)
    local ResultActorRotation = UE.UMathHelper.RNearestInterpTo(Actor:K2_GetActorRotation(), TargetRotation, DeltaTime, ActorInterpSpeed)
    Actor:K2_SetActorRotation(ResultActorRotation, true)
    return TargetRotation
end

function utils.LineTraceDebugByLL(StartLocation, EndLocation)
    -- for debug
    local Hits = UE.TArray(UE.FHitResult)
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.ObjectTypeQuery1)
    UE.UKismetSystemLibrary.LineTraceMultiForObjects(G.GameInstance:GetWorld(), StartLocation, EndLocation, ObjectTypes, true, UE.TArray(UE.AActor), 1, Hits, true)
end

function utils.LineTraceDebugByLR(StartLocation, Rotation)
    -- for debug
    local EndLocation = StartLocation + UE.UKismetMathLibrary.Conv_RotatorToVector(Rotation) * 2000  -- 20m
    local Hits = UE.TArray(UE.FHitResult)
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.ObjectTypeQuery1)
    UE.UKismetSystemLibrary.LineTraceMultiForObjects(G.GameInstance:GetWorld(), StartLocation, EndLocation, ObjectTypes, true, UE.TArray(UE.AActor), 1, Hits, true)
end

function utils.GetFunctionNames(Obj)
    if type(Obj) ~= "table" then
        return {}
    end

    local FunctionNames = {}
    for k, v in pairs(getmetatable(Obj)) do
        if type(v) == "function" then
            table.insert(FunctionNames, k)
        end
    end

    return FunctionNames
end

---Convert one action or actions array to readable string
function utils.ActionToStr(Arr)
    local Ret = ""
    if not Arr then
        return Ret
    end

    if type(Arr) ~= "table" then
        return StateConflictData.extra_data.actions[Arr]
    end

    for _, Val in ipairs(Arr) do
        Ret = Ret .. StateConflictData.extra_data.actions[Val] .. ", "
    end

    return Ret
end

---Convert one state or states array to readable string
function utils.StateToStr(Arr)
    local Ret = ""
    if not Arr then
        return Ret
    end

    if type(Arr) ~= "table" then
        return StateConflictData.extra_data.states[Arr]
    end

    for _, Val in ipairs(Arr) do
        Ret = Ret .. StateConflictData.extra_data.states[Val] .. ", "
    end

    return Ret
end

---Check world space point whether in screen of player.
function utils.CheckPointInScreen(WorldContext, Location)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(WorldContext, 0)
    local ScreenPos = UE.FVector2D()
    if UE.UGameplayStatics.ProjectWorldToScreen(PlayerController, Location, ScreenPos) then
        local ScreenPosX = 0
        local ScreenPosY = 0
        ScreenPosX, ScreenPosY = PlayerController:GetViewportSize(ScreenPosX, ScreenPosY)
        if ScreenPos.X < 0 or ScreenPos.X > ScreenPosX or ScreenPos.Y < 0 or ScreenPos.Y > ScreenPosY then
            return false
        end

        return true
    end

    return false
end

function utils.GetCorrectTransform(Actor)
    local Transform = Actor:GetTransform()

    if Actor.CapsuleComponent then
        -- 取胶囊体底部
        local Location, Rotation, Scale = UE.UKismetMathLibrary.BreakTransform(Transform)
        Location.Z = Location.Z - Actor.CapsuleComponent.CapsuleHalfHeight * Scale.Z

        Transform = UE.UKismetMathLibrary.MakeTransform(Location, Rotation, Scale)
    end

    return Transform
end

function utils.GetActorLocation_Up(Actor)
    local Location = Actor:K2_GetActorLocation()

    if Actor.CapsuleComponent then
        -- 取胶囊体顶部
        local _, _, Scale = UE.UKismetMathLibrary.BreakTransform(Actor:GetTransform())
        Location.Z = Location.Z + Actor.CapsuleComponent.CapsuleHalfHeight * Scale.Z
    end

    return Location
end

function utils.GetCapsuleHalfHeight(Actor)
    if Actor.CapsuleComponent then
        local _, _, Scale = UE.UKismetMathLibrary.BreakTransform(Actor:GetTransform())
        return Actor.CapsuleComponent.CapsuleHalfHeight * Scale.Z
    end

    return 0.0
end

function utils.GetActorLocation_Down(Actor)
    local Location = Actor:K2_GetActorLocation()

    if Actor.CapsuleComponent then
        -- 取胶囊体底部
        local _, _, Scale = UE.UKismetMathLibrary.BreakTransform(Actor:GetTransform())
        Location.Z = Location.Z - Actor.CapsuleComponent.CapsuleHalfHeight * Scale.Z
    end

    return Location
end

---Check Actor any component in screen. Not accurate just use component location.
function utils.CheckActorInScreen(WorldContext, Actor, SourceLocation)
    local Comps = Actor:K2_GetComponentsByClass(UE.UPrimitiveComponent)
    for Ind = 1, Comps:Length() do
        local CurComp = Comps:Get(Ind)
        --TODO both WasRecentlyRendered and WasRecentlyRenderedWithoutShadow not work rightly.
        if utils.CheckPointInScreen(WorldContext, CurComp:K2_GetComponentLocation()) then
            return true
        end
    end

    if SourceLocation then
        -- TODO Not accurate, just check the nearest component whether visible. Maybe better than check component's 8 bounds point.
        local _, TargetLocation = utils.GetTargetNearestDistance(SourceLocation, Actor)
        if utils.CheckPointInScreen(WorldContext, TargetLocation) then
            return true
        end
    end

    return false
end

function utils.IsWithStandSuccess(CauserActor, SelfActor)
    if not CauserActor or not SelfActor then
        return false
    end

    local WithStandComp = SelfActor:GetSkillWithStandComponent(true)
    if WithStandComp and WithStandComp.WithStandAbility then
        return UE.UHiGASLibrary.IsWithStand(CauserActor, SelfActor, WithStandComp.WithStandAbility.WithStandAngleIn, WithStandComp.WithStandAbility.WithStandAngleOut)
    end

    return false
end

function utils.SetActorCollisionEnabled(Actor, NewType)
    local SkeletalMeshComponents = Actor:K2_GetComponentsByClass(UE.USkeletalMeshComponent)
    for i = 1, SkeletalMeshComponents:Length() do
        SkeletalMeshComponents:Get(i):SetCollisionEnabled(NewType)
    end

    local CapsuleComponents = Actor:K2_GetComponentsByClass(UE.UCapsuleComponent)
    for i = 1, CapsuleComponents:Length() do
        CapsuleComponents:Get(i):SetCollisionEnabled(NewType)
    end

    local StaticMeshComponents = Actor:K2_GetComponentsByClass(UE.UStaticMeshComponent)
    for i = 1, StaticMeshComponents:Length() do
        StaticMeshComponents:Get(i):SetCollisionEnabled(NewType)
    end
end

function utils.SetCapsuleCollisionEnabled(Actor, NewType)
    local CapsuleComponents = Actor:K2_GetComponentsByClass(UE.UCapsuleComponent)
    for i = 1, CapsuleComponents:Length() do
        CapsuleComponents:Get(i):SetCollisionEnabled(NewType)
    end
end


--- closure id generator.
function utils.IDGenerator()
    local id = 0
    function next()
        id = id + 1
        return id
    end

    return next
end


function utils.AddGamePlayTags(Actor, TagNames)
    local TagContainer = UE.FGameplayTagContainer()
    local ASC = Actor.AbilitySystemComponent
    for _, TagName in ipairs(TagNames) do
        local Tag = UE.UHiGASLibrary.RequestGameplayTag(TagName)
        TagContainer.GameplayTags:Add(Tag)
    end
    UE.UAbilitySystemBlueprintLibrary.AddLooseGameplayTags(Actor, TagContainer, true)
end

function utils.RemoveGameplayTags(Actor, TagNames)
    local TagContainer = UE.FGameplayTagContainer()
    local ASC = Actor.AbilitySystemComponent
    for _, TagName in ipairs(TagNames) do
        local Tag = UE.UHiGASLibrary.RequestGameplayTag(TagName)
        if ASC:HasGameplayTag(Tag) then
            TagContainer.GameplayTags:Add(Tag)
        end
    end
    UE.UAbilitySystemBlueprintLibrary.RemoveLooseGameplayTags(Actor, TagContainer, true)
end

function utils.IsInQwl(WorldContext)
    local LevelObjects = GameAPI.GetActorsWithTag(WorldContext, "LevelObject_QWL")
    if LevelObjects == nil or #LevelObjects == 0 then
        return false
    end

    return true
end

function utils.GetBoss()
    local AllBoss = GameAPI.GetActorsWithTag(UE.UHiUtilsFunctionLibrary.GetGWorld(), "Boss")
    if AllBoss == nil or #AllBoss == 0 then
        return
    end

    return AllBoss[1]
end

function utils.HideUI()
    G.log:debug("yj", "utils.HideUI")
    UIManager:HideAll3DUIComponent()
    return UIManager:SetOtherLayerHiddenExcept({Enum.Enum_UILayer.SequnceLayer})
end

function utils.ShowUI(HiddenLayerContext)
    G.log:debug("yj", "utils.ShowUI")
    UIManager:ResetHiddenLayerContext(HiddenLayerContext)
    UIManager:RecoverShowAll3DUIComponent()
end

function utils.SetPlayerInputEnabled(WorldContextObject, bEnabled)
    local Player = G.GetPlayerCharacter(WorldContextObject, 0)
    local PC = UE.UGameplayStatics.GetPlayerController(WorldContextObject, 0)
    if bEnabled then
        Player:EnableInput(PC)
    else
        Player:DisableInput(PC)
    end
end

function utils.EvCreateLevelSequencePlayer(WorldContextObject, LevelSequence, Settings, IsHideUI, IsBanInput)
    local SequencePlayer, SequenceActor = UE.UHiLevelSequencePlayer.CreateHiLevelSequencePlayer(WorldContextObject, LevelSequence, Settings)
    local HiddenLayerContext = nil
    SequencePlayer.OnPlay:Add(WorldContextObject, function()
        if IsHideUI then
            HiddenLayerContext = utils.HideUI()
        end

        if IsBanInput then
            local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
            Player:SendMessage("BanInput")
        end
    end)

    SequencePlayer.OnFinished:Add(WorldContextObject, function()
        if IsHideUI then
            utils.ShowUI(HiddenLayerContext)
        end

        if IsBanInput then
            local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
            Player:SendMessage("UnbanInput")
        end
    end)

    SequencePlayer.OnStop:Add(WorldContextObject, function()
        if IsHideUI then
            utils.ShowUI(HiddenLayerContext)
        end

        if IsBanInput then
            local Player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
            Player:SendMessage("UnbanInput")
        end
    end)

    return SequencePlayer, SequenceActor
end

function utils.PlayAkEvent(AkEvent, bFollow, Location, Actor, Callback)
    if bFollow then
        local CallbackMask = bit.lshift(1, UE.EAkCallbackType.EndOfEvent)
        local PostEventAsyncNode = UE.UPostEventAsync.PostEventAsync(Actor, AkEvent, Actor, CallbackMask, {Actor, function() end}, false)
        PostEventAsyncNode:Activate()
    else
        local PostEventAtLocationAsyncNode = UE.UPostEventAtLocationAsync.PostEventAtLocationAsync(G.GameInstance:GetWorld(), AkEvent, Location, UE.FRotator(0, 0, 0))
        PostEventAtLocationAsyncNode:Activate()
    end
    
    if Callback then
        UE.UKismetSystemLibrary.K2_SetTimerDelegate(Callback, AkEvent.MaximumDuration, false)
    end
end

function utils.FloatEqual(fSrcVal, fTarVal, fTolerance)
    fTolerance = fTolerance or 0.001
    return UE.UKismetMathLibrary.NearlyEqual_FloatFloat(fSrcVal, fTarVal, fTolerance)
end

function utils.FloatZero(fSrcVal, fTolerance)
    return utils.FloatEqual(fSrcVal, 0, fTolerance)
end

function utils.FloatLittle(fSrcVal, fTarVal, fTolerance)
    fTolerance = fTolerance or 0.001
    return (fTarVal - fSrcVal) > fTolerance
end

function utils.FloatGreat(fSrcVal, fTarVal, fTolerance)
    fTolerance = fTolerance or 0.001
    return (fSrcVal - fTarVal) > fTolerance
end

function utils.ShowTips(Tips, Duration)
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    local RealDuration = Duration or 2
    HudMessageCenterVM:AddImportantTips(Tips, RealDuration)
end

function utils.ShowTemplateTips(TemplateKey, Duration, ...)
    local ConstTextTable = require("common.data.const_text_data").data
    if not ConstTextTable[TemplateKey] then
        G.log:error("utils", "TemplateKey: %s not found in const_text_data", TemplateKey)
        return
    end

    utils.ShowTips(string.format(ConstTextTable[TemplateKey].Content, ...), Duration)
end

---@param FileName string
---@return string
function utils.LoadFileToString(FileName)
    local File = UE.File()
    if not File:Open(FileName, "r") then
       return ""
    end
    local Content = File:Read("a")
    File:Close()
    return Content
end

---@param Content string
---@param FileName string
---@return boolean
function utils.SaveStringToFile(Content, FileName)
    local File = UE.File()
    if not File:Open(FileName, "w+") then
       return false
    end
    local ret = File:Write(Content)
    File:Close()
    return ret
end


---@param Fun function  协程中运行的function
function utils.Resume(Fun, ...)
    local args = {...}
    local InnerFun = function()
        Fun(table.unpack(args))
    end

    local NewCoro = coroutine.create(InnerFun)
    local result, value = coroutine.resume(NewCoro)
    if (result == false) then
        G.log:error("yongzyzhang", "Resume Coro Error:\n".. debug.traceback(NewCoro, value))
    end
    return result, NewCoro
end


function utils.IRPCStatusString(Status)
    return string.format("FrameworkRetCode:%s FuncRetCode:%s Msg:%s", Status:GetFrameworkRetCode(), Status:GetFuncRetCode(), Status:ErrorMessage())
end

---获取 PlayerController，服务器调用时返回 CacheController，客户端直接返回 world 中的 controller
function utils.GetPlayerController(Actor)
    if Actor:IsServer() then
        return Actor.CacheController
    end

    return UE.UGameplayStatics.GetPlayerController(Actor:GetWorld(), 0)
end

function utils.FColorToTable(Color)
    local ColorTable = {
        R = Color.R,
        G = Color.G,
        B = Color.B,
        A = Color.A
    }
    return ColorTable
end

function utils.ToFColor(ColorTable)
    local Color = UE.FColor()
    Color.R = ColorTable.R or 0
    Color.G = ColorTable.G or 0
    Color.B = ColorTable.B or 0
    Color.A = ColorTable.A or 0
    return Color
end

return utils
