--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR PanZiBin
-- @DATE ${date} ${time}
--

require "UnLua"
local G = require("G")
local Actor = require("common.actor")

---@type ShowActorBase
local ShowActorBase = Class(Actor)

-- function M:Initialize(Initializer)
-- end

function ShowActorBase:UserConstructionScript()
    self:OnInitEvent()
end

function ShowActorBase:OnInitEvent()
    -- print("打印测试  ShowActorBase:OnInitEvent(  ",G.GetDisplayName(self),self:HasAuthority())
    self:SetReplicates(true)
    local RootComp = UE.AActor.K2_GetRootComponent(self)
    local Comps = UE.TArray(UE.USceneComponent)
    UE.USceneComponent.GetChildrenComponents(RootComp, true, Comps)
    for i = 1, Comps:Length() do
        local Comp = Comps:Get(i)
        if Comp:Cast(UE.UPrimitiveComponent) then
            Comp:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
            -- Comp:SetIsReplicated(true)
        end
        if Comp:Cast(UE.USkeletalMeshComponent) then
            Comp:SetAnimationMode(UE.EAnimationMode.AnimationSingleNode)
        end
    end
end

--外部调用
function ShowActorBase:EventAfterSpawn(Info)
    self:MeshTryPlayAnimSeq(Info)
end

--各个骨骼网格体进行动画播放  Info格式 Name + number  ,对应组件名字以及要播的第几个对应下标的动画
function ShowActorBase:MeshTryPlayAnimSeq(Info)
    local MapInfo = self.PlayAnimInfo
    if not MapInfo or not Info then return end
    local Keys = Info:Keys()
    for i = 1, Keys:Length() do
        local CompName = Keys:Get(i)
        local TheComp = self[CompName]
        local Value = MapInfo:Find(CompName)
        local Array = Value and Value.Array
        if TheComp and Array then 
            local Index = Info:Find(CompName) + 1  --动画下标(蓝图从0开始,lua从1开始)
            if Array:IsValidIndex(Index) then
                local SeqInfo = Array:Get(Index)
                self:Multicast_MeshPlayAnim(TheComp, SeqInfo.AnimSeq, SeqInfo.bLooping)
            end
        end
    end
end

--组播 播动画
function ShowActorBase:Multicast_MeshPlayAnim_RPC(SkeletalMeshComp, AnimSeq ,bLooping)
    if not SkeletalMeshComp or not AnimSeq then return end
    UE.USkeletalMeshComponent.PlayAnimation(SkeletalMeshComp, AnimSeq, bLooping or false)
end

return RegisterActor(ShowActorBase)