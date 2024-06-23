--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local tb = {}

--- 定义VMInfoClass给提供EmmyLua提示
---@class VMUniqueInfoClass
---@field UniqueName string
---@field ViewModelClassPath string
local VMUniqueInfoClass = {}

local UniqueVMInfo = {}
tb.UniqueVMInfo = UniqueVMInfo

--[[
    ---@type VMUniqueInfoClass
    UniqueVMInfo.VM_Example =
    {
        UniqueName = 'GlobalUniqueVMExample',
        ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.unique_vm_example',
    }
]]

---@type VMUniqueInfoClass
UniqueVMInfo.TaskMainVM =
{
    UniqueName = 'GlobalTaskMainVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.task.task_main_vm',
}

UniqueVMInfo.TaskActVM =
{
    UniqueName = 'GlobalMissionActVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.task.task_act_vm',
}

UniqueVMInfo.InteractVM =
{
    UniqueName = 'GlobalInteractVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.communication.interact_vm',
}

UniqueVMInfo.DialogueVM =
{
    UniqueName = 'GlobalDialogueVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.communication.dialogue_vm',
}

UniqueVMInfo.HudTrackVM =
{
    UniqueName = 'GlobalHudTrackVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.hud.hud_track_vm',
}

UniqueVMInfo.HudMessageCenterVM =
{
    UniqueName = 'GlobalHudMessageCenterVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.hud.hud_message_center_vm',
}

UniqueVMInfo.SkillBuffVM = {
    UniqueName = 'SkillBuffVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.hud.skill_buff_vm',
}

UniqueVMInfo.BagVM =
{
    UniqueName = 'BagVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.bag.bag_vm',
}

UniqueVMInfo.AreaAbilityVM =
{
    UniqueName = 'AreaAbilityVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.hud.area_ability_vm',
}

UniqueVMInfo.ThrowSkillVM =
{
    UniqueName = 'ThrowSkillVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.hud.throw_skill_vm',
}
UniqueVMInfo.PlayerSkillVM =
{
    UniqueName = 'PlayerSkillVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.hud.player_skill_vm',
}
UniqueVMInfo.BarrageVM =
{
    UniqueName = 'BarrageVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.hud.barrage_vm',
}
UniqueVMInfo.HudStaminaVM =
{
    UniqueName = 'HudStaminaVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.hud.hud_stamina_vm',
}
UniqueVMInfo.MusicGameVM =
{
    UniqueName = 'MusicGameVM',
    ViewModelClassPath = 'CP0032305_GH.Script.viewmodel.ingame.mini_game.music_game_vm',
}

return tb