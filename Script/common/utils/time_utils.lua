require "UnLua"
local G = require("G")

local TimeUtils = {}

TimeUtils.MONTHS_PER_YEAR = 12
TimeUtils.DAYS_PER_WEEK = 7
TimeUtils.HOURS_PER_DAY = 24
TimeUtils.MINUTES_PER_HOUR = 60
TimeUtils.SECONDS_PER_MINUTE = 60

TimeUtils.MINUTES_PER_DAY = TimeUtils.MINUTES_PER_HOUR * TimeUtils.HOURS_PER_DAY
TimeUtils.SECONDS_PER_HOUR = TimeUtils.SECONDS_PER_MINUTE * TimeUtils.MINUTES_PER_HOUR
TimeUtils.SECONDS_PER_DAY = TimeUtils.SECONDS_PER_HOUR * TimeUtils.HOURS_PER_DAY


return TimeUtils