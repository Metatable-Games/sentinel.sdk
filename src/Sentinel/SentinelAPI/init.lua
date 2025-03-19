-- Copyright (c) 2024 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

local HttpService = game:GetService("HttpService")
local Config = require(script.Parent:WaitForChild("Config"))

local SentinelVersion = "2.0.0"

export type SentinelAPI = {}

local API = {}
API.__index = API

function API.new()
	local self = setmetatable({}, API)
	
	if not HttpService.HttpEnabled then
		return error("Sentinel requires HttpEnabled to be true.");
	end
	
	local LatestVersion = HttpService:JSONDecode(HttpService:GetAsync("https://raw.githubusercontent.com/Metatable-Games/sentinel.sdk/main/version.json")).version
	
	if SentinelVersion == LatestVersion then
		warn("Sentinel is up to date!")
	else
		warn("Sentinel is outdated; please update to the latest version!")
	end
	
	for i,v in pairs(script:GetChildren()) do
		if v:IsA("ModuleScript") then
			self[v.Name] = require(v).new(self)
		end
	end

	return self
end

function API:IsPublicKey(): boolean
	return Config.API_KEY:find("sentinelPublicAPI.") ~= nil
end

return API :: typeof(API) & SentinelAPI