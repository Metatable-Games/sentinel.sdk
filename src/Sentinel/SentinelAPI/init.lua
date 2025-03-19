-- Copyright (c) 2024 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

local Config = require(script.Parent:WaitForChild("Config"))

export type SentinelAPI = {}

local API = {}
API.__index = API

function API.new()
	local self = setmetatable({}, API)
	
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