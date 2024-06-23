--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local mission_widget_test = require('CP0032305_GH.Script.system_simulator.mission_system.mission_widget_test')
local HudTrackVMModule = require('CP0032305_GH.Script.viewmodel.ingame.hud.hud_track_vm')

---@type BP_TaskHandOverArea_C
local M = Class()

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function M:ReceiveBeginPlay()
    if not self:HasAuthority() then
        self.Cylinder.OnComponentBeginOverlap:Add(self, self.Cylinder_OnComponentBeginOverlap)
        self.Cylinder.OnComponentEndOverlap:Add(self, self.Cylinder_OnComponentEndOverlap)
        ---@type WBP_HeadInfo_C
        local HeadWidget = self.BP_BillBoardWidget:GetWidget()
        self.TrackTargetWrapper = HudTrackVMModule.ActorTrackTargetWrapper.new(self)
        if HeadWidget then
            HeadWidget:SetOnConstructDelegate(function(Widget)
                if Widget.WBP_TypeWriter and Widget.SetBubble then
                    Widget:SetBubble('任务地点测试')  
                end
            end)
        end
    end
end

function M:HudTrackSelf()
    ---@type HudTrackVM
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if HudTrackVM then
        HudTrackVM:AddTrackActor(self.TrackTargetWrapper)
    end
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param OtherBodyIndex integer
---@param bFromSweep boolean
---@param SweepResult FHitResult
function M:Cylinder_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not self:HasAuthority() then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        if HudMessageCenterVM then
            local NaggingContent = {}
            NaggingContent[1] = {TalkName = 'nil', Duration = 4, TalkContent = '碎碎念内容_1<name>一行三十二个字符</>'}
            NaggingContent[2] = {TalkName = 'NPC名字2', Duration = 5, TalkContent = '碎碎念内容_2<name>一行三十二个字符</>，时间比预想的还要紧迫，使用<name>My Power</><n>速战速决</>'}
            NaggingContent[3] = {TalkName = 'nil', Duration = 6, TalkContent = '碎碎念内容_3<name>一行三十二个字符</>，时间比预想的还要紧迫，使用<name>My Power</><n>速战速决，对话内容最多四十八个字符。</>'}
            NaggingContent[4] = {TalkName = 'NPC名字4', Duration = 5, TalkContent = '碎碎念内容_4<name>一行三十二个字符</>，时间比预想的还要紧迫，使用<name>My Power</><n>速战速决</>'}
            NaggingContent[5] = {TalkName = 'nil', Duration = 4, TalkContent = '碎碎念内容_5'}
            -- NaggingContent[2].Audio = '/Game/WwiseAudio/Events/BattleMusic/BattleMusic_Test/Play_Battle_Win_Music_Test.Play_Battle_Win_Music_Test'
            -- NaggingContent[3].Audio = '/Game/WwiseAudio/Events/BattleMusic/BattleMusic_Test/Play_Battle_Win_Music_Test.Play_Battle_Win_Music_Test'
            -- NaggingContent[4].Audio = '/Game/WwiseAudio/Events/BattleMusic/BattleMusic_Test/Play_Battle_Win_Music_Test.Play_Battle_Win_Music_Test'
            -- NaggingContent[5].Audio = '/Game/WwiseAudio/Events/BattleMusic/BattleMusic_Test/Play_Battle_Win_Music_Test.Play_Battle_Win_Music_Test'
            
            NaggingContent[1].Audio = '/Game/WwiseAudio/Events/BattleMusic/BattleMusic_Test/Play_Battle_Win_Music_Test.Play_Battle_Win_Music_Test'
            HudMessageCenterVM:ShowNagging(NaggingContent)
            NaggingContent[1].Audio = nil
            HudMessageCenterVM:ShowNagging(NaggingContent)

        end
    end
end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param OtherBodyIndex integer
function M:Cylinder_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if not self:HasAuthority() then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        if InteractVM then
            InteractVM:CloseInteractSelection()
        end
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        HudMessageCenterVM:HideNagging()
    end
end

return M
