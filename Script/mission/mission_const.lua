local _M = {}

local EMissionType = {}
EMissionType.Main = 1
EMissionType.Activity = 2
EMissionType.Daily = 3
EMissionType.Guide = 4

local EMissionTrackIconType = {}
EMissionTrackIconType.None = 0
EMissionTrackIconType.Receive = 1
EMissionTrackIconType.Track = 2
EMissionTrackIconType.Submit = 3

local EMissionBlockReason = {}
EMissionBlockReason.PreMissionBlock = 1  -- 前置任务/前置任务幕阻塞


---Export
_M.EMissionType = EMissionType
_M.EMissionTrackIconType = EMissionTrackIconType
_M.EMissionBlockReason = EMissionBlockReason
-- 追踪限制距离，单位米
_M.MissionTrackHorizontalDistanceLimit = 80
_M.MissionTrackVerticalDistanceLimit = 3
-- Exit对话分支最大id
_M.MAX_EXIT_DIALOGUE_ID = 9

return _M
