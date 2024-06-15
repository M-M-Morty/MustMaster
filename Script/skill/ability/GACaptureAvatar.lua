local G = require("G")
local GACapture = require("skill.ability.GACapture")
local GACaptureAvatar = Class(GACapture)


function GACaptureAvatar:HandleActivateAbility()
    Super(GACaptureAvatar).HandleActivateAbility(self)
end

function GACaptureAvatar:OnCapture()
    G.log:debug(self.__TAG__, "%s OnCaptureEvent, IsServer: %s.", G.GetDisplayName(self), self:IsServer())
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(self.OwnerActor)
    local Targets = UE.TArray(UE.AActor)

    UE.UHiCollisionLibrary.SphereOverlapActors(self.OwnerActor, ObjectTypes, self.OwnerActor:K2_GetActorLocation(),
            self.CaptureRadius, self.CaptureRadius, self.CaptureRadius, nil, ActorsToIgnore, Targets)

    -- Filter interactable targets.
    local InteractTargets = UE.TArray(UE.AActor)
    for Ind = 1, Targets:Length() do
        local CurTarget = Targets:Get(Ind)
        if SkillUtils.IsInteractable(CurTarget) then
            InteractTargets:AddUnique(CurTarget)
        end
    end

    G.log:debug(self.__TAG__, "Find capture actor count: %d", InteractTargets:Length())
    if InteractTargets:Length() > 0 then
        local MinDis
        local CaptureTarget

        for Ind = 1, InteractTargets:Length() do
            local CurTarget = InteractTargets:Get(Ind)
            if not CaptureTarget then
                CaptureTarget = CurTarget
                MinDis = utils.GetDisSquare(CurTarget:K2_GetActorLocation(), self.OwnerActor:K2_GetActorLocation())
            else
                local CurDis = utils.GetDisSquare(CurTarget:K2_GetActorLocation(), self.OwnerActor:K2_GetActorLocation())
                if CurDis < MinDis then
                    MinDis = CurDis
                    CaptureTarget = CurTarget
                end
            end
        end
        
        G.log:debug(self.__TAG__, "Find nearest capture target: %s", G.GetDisplayName(CaptureTarget))
        self.OwnerActor.InteractionComponent:CaptureTarget(CaptureTarget)
    end
end


return GACaptureAvatar
