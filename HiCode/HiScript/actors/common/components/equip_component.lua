require "UnLua"


local G = require("G")
local SnapToTarget = UE.EAttachmentRule.SnapToTarget
local equip_const = require("common.const.equip_const")

local equip_data = require("common.data.hero_install_data").data

local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local EquipComponent = Component(ComponentBase)
local decorator = EquipComponent.decorator

local InvalidStance = -1


function EquipComponent:Start()
    Super(EquipComponent).Start(self)

    self.equipments = {}
    self.SwitchInSignalCounts = {}      -- Map to equipments
    self.CurrentStance = {}             -- Map to equipments
    
    self.OnBreakSkill = false
end


function EquipComponent:Stop()
    Super(EquipComponent).Stop(self)
end


function EquipComponent:GetEquipData(equip_id)
    return equip_data[equip_id]
end


decorator.message_receiver()
function EquipComponent:AddEquip(equip_type, equip_id)

    local equip_info = self.equipments[equip_id]
    assert(equip_info == nil)

    local equip_data = self:GetEquipData(equip_id)

    local equip_actor = self:SpawnEquip(equip_data.item_path)

    equip_info = {}
    equip_info.type = equip_type
    equip_info.actor = equip_actor
    equip_info.socket = ""
    
    local init2socket = equip_data.socket or equip_data.action_socket
    self.equipments[equip_id] = equip_info
    self.SwitchInSignalCounts[equip_id] = 0
    self.CurrentStance[equip_id] = InvalidStance
    
    if init2socket and equip_actor then
       self:AttachEquip(equip_info, init2socket)
    end
end


decorator.message_receiver()
function EquipComponent:ChangeEquipMaterial(MaterialInst)
    for equip_id, equip_info in pairs(self.equipments) do
        local equip_actor = equip_info.actor
        equip_actor.SkeletalMesh:SetMaterial(0, MaterialInst)
    end
end


decorator.message_receiver()
function EquipComponent:ResetEquipMaterial()
    for equip_id, equip_info in pairs(self.equipments) do
        local equip_actor = equip_info.actor
        equip_actor.SkeletalMesh:SetMaterial(0, nil)
    end
end


decorator.message_receiver()
function EquipComponent:SetEquipVisibility(InVisible)
    for equip_id, equip_info in pairs(self.equipments) do
        local equip_actor = equip_info.actor
        equip_actor.SkeletalMesh:SetVisibility(InVisible)
    end
end


decorator.message_receiver()
function EquipComponent:RemoveEquip(EquipType, EquipId)
    self:DestroyEquip(EquipType, EquipId)
end


function EquipComponent:SpawnEquip(path)
    local World = self.actor:GetWorld()
    if not World then
        return
    end
    local AlwaysSpawn = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
    local EquipClass = UE.UClass.Load(path)

    local SpawnParameters = UE.FActorSpawnParameters()

    local ExtraData = { CharIdentity = self.actor.CharIdentity, SourceActor = self.actor}
    local EquipActor = GameAPI.SpawnActor(self.actor:GetWorld(), EquipClass, self.actor:GetTransform(), SpawnParameters, ExtraData)

    if EquipActor.SetVisibility then
        EquipActor:SetVisibility(false)
    end
    -- G.log:debug("yj", "SpawnEquip @@@@@@@@@@@ %s %s %s", path, EquipActor, EquipActor.CharIdentity)

    -- local AIComponent = UE.UHiAIComponent.FindAIComponent(self.actor)
    -- if AIComponent then
    --     AIComponent:AddMountActor(EquipActor) 
    -- end

    local TimeDilationActor = HiBlueprintFunctionLibrary.GetTimeDilationActor(self.actor)

    if TimeDilationActor then

        local LevelSequenceActors = EquipActor:GetLevelSequenceActors()
        
        for i = 1, LevelSequenceActors:Length() do
            local LevelSequenceActor = LevelSequenceActors:Get(i)
            TimeDilationActor:AddCustomTimeDilationObject(self.actor, LevelSequenceActor)
        end
    end

    return EquipActor
end


function EquipComponent:DestroyEquip(EquipType, EquipId)
    local equip_info = self.equipments[EquipId]
    assert(equip_info ~= nil)
    assert(equip_info.type == EquipType)

    local equip_actor = equip_info.actor
    assert(equip_actor ~= nil)

    self.equipments[EquipId] = nil
    self.CurrentStance[EquipId] = InvalidStance
    self.SwitchInSignalCounts[EquipId] = 0

    equip_actor:K2_DestroyActor()
end


function EquipComponent:SwitchStance(EquipId, NewStance, ForceSwitch)
    G.log:debug("devin", "EquipComponent:SwitchStance %s", NewStance)
    if self.CurrentStance[EquipId] == NewStance and not ForceSwitch then
        return
    end
    self.CurrentStance[EquipId] = NewStance
    local socket_key = nil
    if NewStance == equip_const.StanceType_Normal then
        socket_key = "socket"
    elseif NewStance == equip_const.StanceType_Fight then
        socket_key = "action_socket"
    else
        assert(false, "invalid stance type")
    end

    local equip_data = self:GetEquipData(EquipId)
    local socket = equip_data.socket
    local action_socket = equip_data.action_socket
    if equip_data[socket_key] and equip_data[socket_key] ~= "" then
        self:AttachEquip(self.equipments[EquipId], equip_data[socket_key])
    else
        self:DetachEquip(self.equipments[EquipId], ForceSwitch)
    end
end


function EquipComponent:SwitchSocket(PrevSocket, NewSocket)
    G.log:debug("devin", "EquipComponent:SwitchSocket %s %s", PrevSocket, NewSocket)

    assert(PrevSocket ~= NewSocket)
    
    for equip_id, equip_info in pairs(self.equipments) do
        if equip_info.socket == PrevSocket then
            if NewSocket ~= "" then
                self:AttachEquip(equip_info, NewSocket)
            else
                self:DetachEquip(equip_info)
            end
        end
    end
end


function EquipComponent:SetCustomSocket(EquipId, NewSocket)
    -- G.log:debug("devin", "EquipComponent:SetCustomSocket %s %s %d %s %s", tostring(self), self.actor:IsServer(), EquipId, NewSocket, tostring(self.equipments[EquipId]))

    if NewSocket == "None" then
        NewSocket = ""
    end

    local equip_info = self.equipments[EquipId]
    if not equip_info or equip_info.socket == NewSocket then
        return
    end

    if NewSocket ~= "" then
        -- G.log:debug("devin", "EquipComponent:SetCustomSocket 111 %s %d %s", self.actor:IsServer(), EquipId, NewSocket)
        self:AttachEquip(equip_info, NewSocket)
    else
        -- G.log:debug("devin", "EquipComponent:SetCustomSocket 222 %s %d %s", self.actor:IsServer(), EquipId, NewSocket)
        self:DetachEquip(equip_info, true)
    end
end


function EquipComponent:ClearCustomSocket(EquipId)
    -- G.log:debug("devin", "EquipComponent:ClearCustomSocket %s %s %d %s", tostring(self), self.actor:IsServer(), EquipId, NewSocket)

    local equip_info = self.equipments[EquipId]
    if not equip_info then
        return
    end

    local equip_data = self:GetEquipData(EquipId)

    local socket_key = "socket"

    if self.CurrentStance == equip_const.StanceType_Fight then
        socket_key = "action_socket"
    end

    if equip_data[socket_key] and equip_data[socket_key] ~= "" then
        self:AttachEquip(equip_info, equip_data[socket_key])
    else
        self:DetachEquip(equip_info)
    end
end

decorator.message_receiver()
function EquipComponent:OnBreakSKill(reason)
    G.log:info_obj(self, "cp", "EquipComponent:BreakSkillTail %s", reason)
    self:DetachEquipFromAvatar()
end


decorator.message_receiver()
function EquipComponent:OnEndSKill(SkillID)
    G.log:info_obj(self, "cp", "EquipComponent:OnEndSKill %d", SkillID)
    self:DetachEquipFromAvatar()
end

function EquipComponent:DetachEquipFromAvatar()
    for _, equip_info in pairs(self.equipments) do
        if equip_info.actor then
            equip_info.actor:DetachFromAvatar()
        end
    end
end

decorator.message_receiver()
function EquipComponent:RestoreAttachEquip()
    
    G.log:info_obj(self,"cp", "EquipComponent:RestoreAttachEquip")
    for _, equip_info in pairs(self.equipments) do
        if equip_info.actor then
            equip_info.actor:AttachToAvatar()
        end
    end
end


function EquipComponent:AttachEquipToActor(equip_info, socket_name)
    local equip_actor = equip_info.actor
    local NewAttach = true
    if equip_actor then
        if equip_info.socket == socket_name then
            return
        else
            if equip_info.socket ~= "" then
                NewAttach = false
                equip_actor:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)
            end
            equip_actor:SetAttachToAvatar(self.actor, socket_name)--, SnapToTarget, SnapToTarget, SnapToTarget)
    end
        equip_info.socket = socket_name
       
    end
    if NewAttach and equip_info.type == equip_const.EquipType_Weapon then
        self:SendMessage("AddWeapon", equip_actor)
    end
end


function EquipComponent:DetachEquipFromParent(equip_info)
    local equip_actor = equip_info.actor
    if equip_actor then
        equip_actor:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)
    end
    if equip_info.type == equip_const.EquipType_Weapon then
        self:SendMessage("RemoveWeapon", equip_actor)
    end
end


function EquipComponent:AttachEquip(equip_info, socket_name)
    -- just change visible 
    local equip_actor = equip_info.actor
    --check attached
    self.OnBreakSkill = false
    self:AttachEquipToActor(equip_info, socket_name)
    G.log:info_obj(self, "AttachEquip", "[%s], socket_name:[%s]", G.GetObjectName(equip_actor), socket_name)
    if equip_actor then
        if equip_actor.IsPlayingDeath then
            equip_actor:StopDeath()
        end
        local WeaponMeshComponent = equip_info.actor:GetComponentByClass(UE.USkeletalMeshComponent)
        if WeaponMeshComponent then
            WeaponMeshComponent:AddTickPrerequisiteComponent(self.actor.Mesh)
        end
        if equip_actor.SetVisibility then
            G.log:info_obj(self, "AttachEquip", "SetVisibility True")
            equip_actor:SetVisibility(true)
        end
        if equip_actor.SupportPlayBirth and equip_actor:SupportPlayBirth() then
            equip_actor:Birth()
        end
    end
    return equip_actor
end


function EquipComponent:DetachEquip(equip_info, immediately)
    -- just change visible 
    local equip_actor = equip_info.actor
    G.log:info_obj(self, "DetachEquip", "[%s], immediately:[%s]", G.GetObjectName(equip_actor), immediately)
    if equip_actor then
        local WeaponMeshComponent = equip_info.actor:GetComponentByClass(UE.USkeletalMeshComponent)
        if WeaponMeshComponent then
            WeaponMeshComponent:RemoveTickPrerequisiteComponent(self.actor.Mesh)
        end
        equip_actor:Death(immediately)
        --equip_actor:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)
       --[[ if not immediately and equip_actor:SupportPlayDeath() then
            equip_actor:Death()
        else
            equip_actor:SetVisibility(false)
            G.log:info_obj(self, "AttachEquip", "SetVisibility False")
        end]]
    end

end


function EquipComponent:Destroy()
    for _, equip_info in pairs(self.equipments) do
        if equip_info.actor then
            self:DetachEquipFromParent(equip_info)
            equip_info.actor:K2_DestroyActor()
        end
    end

    self.equipments = {}
    
    Super(EquipComponent).Destroy(self)
end


decorator.message_receiver()
function EquipComponent:AttachWeapon(InSignal, Anim)
    G.log:info_obj(self, "[I]EquipComponent:0 AttachWeapon", " InSignal %s. %s", InSignal, Anim)
    if Anim == nil then
        return
    end

    for equip_id, equip_info in pairs(self.equipments) do
        self:DoAttachWeapon(equip_id, InSignal, Anim)
    end
end


function EquipComponent:AttachSingleWeapon(Hand, InSignal, Anim)
    G.log:info_obj(self, "[I]EquipComponent:1 AttachSingleWeapon", " Hand %s InSignal %s. %s", Hand, InSignal, Anim)
    for equip_id, equip_info in pairs(self.equipments) do
        local equip_actor =  equip_info.actor
        if equip_actor.Hand == Hand then
            self:DoAttachWeapon(equip_id, InSignal, Anim)
            return
        end
    end
end


function EquipComponent:DoAttachWeapon(EquipId, InSignal, Anim)
    if InSignal == 1 then
        self.SwitchInSignalCounts[EquipId] = self.SwitchInSignalCounts[EquipId] + 1
    else
        self.SwitchInSignalCounts[EquipId] = self.SwitchInSignalCounts[EquipId] - 1
    end
    G.log:info_obj(self, "[I]EquipComponent:AttachWeapon", "%s, %s, %s, %s", InSignal, EquipId, self.SwitchInSignalCounts[EquipId], G.GetObjectName(Anim))
    if self.SwitchInSignalCounts[EquipId] < 0 then
        G.log:info_obj(self, "[W]EquipComponent:AttachWeapon", "%s, %s, %s, %s", InSignal, EquipId, self.SwitchInSignalCounts[EquipId], G.GetObjectName(Anim))
        self.SwitchInSignalCounts[EquipId] = 0
    end
    if self.SwitchInSignalCounts[EquipId] > 1 then
        return
    end
    if self.SwitchInSignalCounts[EquipId] == 1 and InSignal == 0 then
        return
    end

    self:SwitchStance(EquipId, InSignal)
end


function EquipComponent:SwitchWeaponSocket(PrevSocket, NewSocket)
    self:SwitchSocket(PrevSocket, NewSocket)
end


function EquipComponent:PlayWeaponMontage(Hand, AnimMontage, LeaderAnimInstance, LeaderMontage)
    for equip_id, equip_info in pairs(self.equipments) do
        local equip_actor =  equip_info.actor
        while true do
            if not equip_actor then
                break
            end
            local MeshComponent = equip_actor:GetComponentByClass(UE.USkeletalMeshComponent)
            if not MeshComponent then
                break
            end
            if not UE.UHiUtilsFunctionLibrary.IsAssetSkeletonCompatible(MeshComponent:GetSkeletalMeshAsset().Skeleton, AnimMontage) then
                break
            end
            if equip_actor.Hand ~= 0 and equip_actor.Hand ~= nil and equip_actor.Hand ~= Hand then
                G.log:info_obj(self, "EquipComponent", "PlayWeaponMontage not fix hand continue,%d, %d, %s",
                        Hand, equip_actor.Hand, G.GetObjectName(AnimMontage))
                break
            end
            local AnimInstance = MeshComponent:GetAnimInstance()
            if AnimInstance ~= nil then
                if AnimInstance:Montage_IsPlaying(AnimMontage) then
                    G.log:info_obj(self, "EquipComponent", "%s Montage %s is Played By Other",
                            G.GetObjectName(equip_actor),
                            G.GetObjectName(AnimMontage))
                else
                    G.log:info_obj(self, "EquipComponent", "Montage_Play %s , %s",
                            G.GetObjectName(AnimMontage),
                            G.GetObjectName(equip_actor))
                    AnimInstance:Montage_Play(AnimMontage)
                    
                    if LeaderMontage:IsA(UE.UAnimMontage) and LeaderAnimInstance:Montage_IsPlaying(LeaderMontage) then
                        G.log:info_obj(self, "EquipComponent", "MontageSync_Follow %s, LeaderMontage %s, %s",
                                G.GetObjectName(AnimMontage),
                                G.GetObjectName(LeaderAnimInstance),
                                G.GetObjectName(LeaderMontage))
                        MeshComponent:GetAnimInstance():MontageSync_Follow(AnimMontage, LeaderAnimInstance, LeaderMontage)
                    end
                end
            end

            break
        end
    end
end


function EquipComponent:StopSyncWeaponMontage(AnimMontage)
    for equip_id, equip_info in pairs(self.equipments) do
        if equip_info.actor then
            local MeshComponent = equip_info.actor:GetComponentByClass(UE.USkeletalMeshComponent)
            if MeshComponent then
                MeshComponent:GetAnimInstance():MontageSync_StopFollowing(AnimMontage)
            end
        end
    end
end


decorator.message_receiver()
function EquipComponent:SetEquipCollisionEnabled(NewType)
    for equip_id, equip_info in pairs(self.equipments) do
        local equip_actor = equip_info.actor
        if equip_actor then
            utils.SetActorCollisionEnabled(equip_actor, NewType)
        end
    end
end


decorator.message_receiver()
function EquipComponent:OnSetActorTimeDilation(value)
    for equip_id, equip_info in pairs(self.equipments) do
        local equip_actor = equip_info.actor
        if equip_actor then
            equip_actor.CustomTimeDilation = value
        end
    end
end


decorator.message_receiver()
function EquipComponent:OnPlayerSwitchOut()
    -- for equip_id, equip_info in pairs(self.equipments) do
    --     self:SwitchStance(equip_id, equip_const.StanceType_Normal, true)
    -- end
end


decorator.message_receiver()
function EquipComponent:InitWeaponVisibility()
    for equip_id, equip_info in pairs(self.equipments) do
        self:SwitchStance(equip_id, equip_const.StanceType_Normal, true)
    end
end


return EquipComponent