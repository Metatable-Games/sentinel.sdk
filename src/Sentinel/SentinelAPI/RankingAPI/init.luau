-- Copyright (c) 2025 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

local Config = require(script.Parent.Parent:WaitForChild("Config"))

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

export type API = {}

local API = {}
API.__index = API

-- Usage: SentinelAPI.RankingAPI:Method(...)
function API.new(core)
	return setmetatable({
        core = core
    }, API)
end

function API:SetRankAsync(UserId: number, GroupId: number, RankId: number): boolean
	assert(UserId and typeof(UserId) == "number", "Invalid UserId; expected number")
	assert(GroupId and typeof(GroupId) == "number", "Invalid GroupId; expected number")
	assert(RankId and typeof(RankId) == "number", "Invalid RankId; expected number")

	assert(
		Players:GetUserIdFromNameAsync(Players:GetNameFromUserIdAsync(UserId)) == UserId,
		"Invalid UserId; User does not exist"
	)
	assert(GroupService:GetGroupInfoAsync(GroupId), "Invalid GroupId; Group does not exist")
	assert(RankId >= 1 and RankId <= 255, "Invalid RankId; Must be between 1 and 255")

	assert(HttpService.HttpEnabled == true, "HttpService must be enabled for Sentinel to properly work!")

	local response = HttpService:RequestAsync({
		Url = Config.API_ENTRY .. "/group-role",
		Method = "PATCH",
		Headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. Config.API_KEY,
		},
		Body = {
			userId = UserId,
			groupId = GroupId,
			rankId = RankId,
		},
	})

	if not response.Success or response.Success and response.StatusCode ~= 200 then
		if Config.DEBUG_INFO_ENABLED then
			warn(
				"An error occured with an HttpSerivce Request to Sentinel Web API.",
				response.StatusCode,
				response.StatusMessage
			)
		end

		return false
	end

	local body = HttpService:JSONDecode(response.Body)

	return body.status ~= nil and body.status == "ok"
end

return API :: typeof(API) & API