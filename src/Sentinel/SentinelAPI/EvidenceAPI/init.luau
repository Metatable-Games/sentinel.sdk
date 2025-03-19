-- Copyright (c) 2025 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

local Config = require(script.Parent.Parent:WaitForChild("Config"))

local HttpService = game:GetService("HttpService")

export type API = {}

export type evidenceMetadata = {
	streamUri: string,
	evidenceGuid: string,
	worskpaceGuid: string,
	created: string,
	updated: string,
	createdBy: string,
	fileName: string,
	caseId: string,
	evidenceType: string,
	metadata: {
		comment: string,
		customS3: boolean,
	},
	archivePending: boolean,
}

local API = {}
API.__index = API

-- Usage: SentinelAPI.EvidenceAPI:Method(...)
function API.new(core)
	return setmetatable({
		core = core,
	}, API)
end

function API:GetEvidenceMetadata(EvidenceGUID: string): (boolean, evidenceMetadata?)
	assert(EvidenceGUID and typeof(EvidenceGUID) == "string", "Invalid EvidenceGUID; Must be a string")

	local response = HttpService:RequestAsync({
		Url = Config.API_ENTRY .. "/evidence/" .. EvidenceGUID .. "/metadata",
		Method = "GET",
		Headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. Config.API_KEY,
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
	local ok = body.status ~= nil and body.status == "ok"

	if ok then
		body["status"] = nil
	end

	return ok, ok and body or nil
end

return API :: typeof(API) & API