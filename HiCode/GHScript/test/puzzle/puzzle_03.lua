--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BP_Puzzle03_C
local M = Class()

local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

local DiaoxiangClass = UE.UClass.Load('/Game/Developers/CP0032305_GH/Test/Puzzle/BP_Diaoxiang.BP_Diaoxiang_C')
local JiguanClass = UE.UClass.Load('/Game/Developers/CP0032305_GH/Test/Puzzle/BP_Jiguan.BP_Jiguan_C')
local YaBoxClass = UE.UClass.Load('/Game/Developers/CP0032305_GH/Test/Puzzle/BP_YaBox.BP_YaBox_C')
local BaoxiangClass = UE.UClass.Load('/Game/Developers/CP0032305_GH/Test/Puzzle/BP_Baoxiang.BP_Baoxiang_C')
local AnniuClass = UE.UClass.Load('/Game/Developers/CP0032305_GH/Test/Puzzle/BP_Anniu.BP_Anniu_C')

---@type PuzzleMap_03_C
local M = Class()

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function M:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)

    if self:HasAuthority() then
        return
    end

    self.Diaoxiang = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(self, DiaoxiangClass, self.Diaoxiang)

    local OutJiguan = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(self, JiguanClass, OutJiguan)

    for i = 1, OutJiguan:Length() do
        local elm = OutJiguan:Get(i)
        elm.OnActorBeginOverlap:Add(self, self.Jiguan_OnActorBeginOverlap)
        elm.OnActorEndOverlap:Add(self, self.Jiguan_OnActorEndOverlap)
    end

    local OutYaBox = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(self, YaBoxClass, OutYaBox)
    
    ---@type AActor
    self.YaBox = OutYaBox:Get(1)
    if self.YaBox then
        self.YaBox.OnActorBeginOverlap:Add(self, self.YaBox_OnActorBeginOverlap)
        self.YaBox.OnActorEndOverlap:Add(self, self.YaBox_OnActorEndOverlap)
    end

    local OutBaoxiang = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(self, BaoxiangClass, OutBaoxiang)
    
    ---@type AActor
    self.Baoxiang = OutBaoxiang:Get(1)
    if self.Baoxiang then
        self.Baoxiang:SetActorHiddenInGame(true)
        self.Baoxiang:SetActorEnableCollision(false)
        self.Baoxiang.OnActorBeginOverlap:Add(self, self.Baoxiang_OnActorBeginOverlap)
        self.Baoxiang.OnActorEndOverlap:Add(self, self.Baoxiang_OnActorEndOverlap)
    end

    local OutAnniu = UE.TArray(UE.AActor)
    UE.UGameplayStatics.GetAllActorsOfClass(self, AnniuClass, OutAnniu)

    for i = 1, OutAnniu:Length() do
        local elm = OutAnniu:Get(i)
        elm.OnActorBeginOverlap:Add(self, self.Anniu_OnActorBeginOverlap)
        elm.OnActorEndOverlap:Add(self, self.Anniu_OnActorEndOverlap)
        elm:SetYa(false)
    end

    self.bCompleted = false
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

---@param OverlappedActor AActor
---@param OtherActor AActor
function M:YaBox_OnActorBeginOverlap(OverlappedActor, OtherActor)
end

---@param OverlappedActor AActor
---@param OtherActor AActor
function M:YaBox_OnActorEndOverlap(OverlappedActor, OtherActor)
end

---@param OverlappedActor AActor
---@param OtherActor AActor
function M:Jiguan_OnActorBeginOverlap(OverlappedActor, OtherActor)
    if not self:HasAuthority() then
        local InteractItems = {}
        InteractItems[1] =
        {
            GetSelectionTitle = function()
                return '顺时针旋转'
            end,
            SelectionAction = function()
                self:Client_RotateJiguan(90)
            end,
            GetDisplayIconPath = function()
            end,
            GetType = function()
                return 1            -- MISSION
            end,
        }
        InteractItems[2] =
        {
            GetSelectionTitle = function()
                return '逆时针旋转'
            end,
            SelectionAction = function()
                self:Client_RotateJiguan(-90)
            end,
            GetDisplayIconPath = function()
            end,
            GetType = function()
                return 1            -- MISSION
            end,
        }
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        InteractVM:OpenInteractSelection(InteractItems)
    end
end

---@param OverlappedActor AActor
---@param OtherActor AActor
function M:Jiguan_OnActorEndOverlap(OverlappedActor, OtherActor)
    if not self:HasAuthority() then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        InteractVM:CloseInteractSelection()
    end
end

function M:Client_RotateJiguan(AngleInDeg)

    local RightYawCount = 0
    ---@param elm AActor
    for _, elm in pairs(self.Diaoxiang) do
        local ActorRotation = elm:K2_GetActorRotation()
        local NewYaw = ActorRotation.Yaw

        if not elm.AnniuRef.bShowYaBox then
            NewYaw = NewYaw + AngleInDeg
            if NewYaw < 0 then
                NewYaw = NewYaw + 360
            end
            if NewYaw > 360 then
                NewYaw = NewYaw - 360
            end
            local NewRot = UE.FRotator(ActorRotation.Pitch, NewYaw, ActorRotation.Roll)

            elm:K2_SetActorRotation(NewRot, true)
        end

        local DiffYaw = math.abs(NewYaw - elm.RightYaw)
        if DiffYaw < 10 then
            RightYawCount = RightYawCount + 1
        end
    end

    if RightYawCount == self.Diaoxiang:Length() then
        self.bCompleted = true
        self.Baoxiang:SetActorEnableCollision(true)
        self.Baoxiang:SetActorHiddenInGame(false)
    end
end


---@param OverlappedActor AActor
---@param OtherActor AActor
function M:YaBox_OnActorBeginOverlap(OverlappedActor, OtherActor)
    if not self:HasAuthority() then
        if OverlappedActor:GetAttachParentActor() then
            return
        end

        local InteractItems = {}
        InteractItems[1] =
        {
            GetSelectionTitle = function()
                return '拾取'
            end,
            SelectionAction = function()
                self:Client_LootYaBox()
            end,
            GetDisplayIconPath = function()
            end,
            GetType = function()
                return 1            -- MISSION
            end,
        }
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        InteractVM:OpenInteractSelection(InteractItems)
    end
end

---@param OverlappedActor AActor
---@param OtherActor AActor
function M:YaBox_OnActorEndOverlap(OverlappedActor, OtherActor)
    if not self:HasAuthority() then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        InteractVM:CloseInteractSelection()
    end
end

function M:Client_HideYaBox()
    if self.YaBox then
        self.YaBox:SetActorHiddenInGame(true)
        self.YaBox:K2_AttachToActor(self, '', UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, false)
        self.YaBox:K2_SetActorRelativeLocation(UE.FVector(0, 0, 0), false, nil, true)
    end
end

function M:Client_LootYaBox()
    if self.YaBox then
        self.YaBox:SetActorHiddenInGame(false)
        local PlayerActor = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
        self.YaBox:K2_AttachToActor(PlayerActor, '', UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, false)
        self.YaBox:K2_SetActorRelativeLocation(UE.FVector(70, 0, 70), false, nil, true)

        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        InteractVM:CloseInteractSelection()
    end
end


---@param OverlappedActor AActor
---@param OtherActor AActor
function M:Baoxiang_OnActorBeginOverlap(OverlappedActor, OtherActor)
    if not self:HasAuthority() then
        local InteractItems = {}
        InteractItems[1] =
        {
            GetSelectionTitle = function()
                return '开启宝箱'
            end,
            SelectionAction = function()
            end,
            GetDisplayIconPath = function()
            end,
            GetType = function()
                return 1            -- MISSION
            end,
        }
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        InteractVM:OpenInteractSelection(InteractItems)
    end
end

---@param OverlappedActor AActor
---@param OtherActor AActor
function M:Baoxiang_OnActorEndOverlap(OverlappedActor, OtherActor)
    if not self:HasAuthority() then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        InteractVM:CloseInteractSelection()
    end
end


---@param OverlappedActor AActor
---@param OtherActor AActor
function M:Anniu_OnActorBeginOverlap(OverlappedActor, OtherActor)
    if not self:HasAuthority() then
        local InteractItems = {}

        local PlayerActor = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
        if self.YaBox:GetAttachParentActor() == PlayerActor then
            InteractItems[1] =
            {
                GetSelectionTitle = function()
                    return '压住按钮'
                end,
                SelectionAction = function()
                    OverlappedActor:SetYa(true)
                    self:Client_HideYaBox()
                end,
                GetDisplayIconPath = function()
                end,
                GetType = function()
                    return 1            -- MISSION
                end,
            }
        elseif OverlappedActor.bShowYaBox then
            InteractItems[1] =
            {
                GetSelectionTitle = function()
                    return '拿起压压盒'
                end,
                SelectionAction = function()
                    OverlappedActor:SetYa(false)
                    self:Client_LootYaBox()
                end,
                GetDisplayIconPath = function()
                end,
                GetType = function()
                    return 1            -- MISSION
                end,
            }
        end

        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        InteractVM:OpenInteractSelection(InteractItems)
    end
end

---@param OverlappedActor AActor
---@param OtherActor AActor
function M:Anniu_OnActorEndOverlap(OverlappedActor, OtherActor)
    if not self:HasAuthority() then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        InteractVM:CloseInteractSelection()
    end
end


return M

