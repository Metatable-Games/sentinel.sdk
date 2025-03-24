-- Copyright (c) 2025 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

local Config = require(script.Parent.Parent:WaitForChild("Config"))
local Util = require(script.Parent.Parent:WaitForChild("Util"))

local HttpService = game:GetService("HttpService")

export type API = {}

export type EvidenceGUID = string;
export type CaseGUID = string;
export type EvidenceType = "File" | "Metadata";

export type evidenceMetadata = {
	streamUri: string,
	evidenceGuid: EvidenceGUID,
	worskpaceGuid: string,
	created: string,
	updated: string,
	createdBy: string,
	fileName: string,
	caseId: CaseGUID,
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

function API:DeleteEvidence(EvidenceGUID: EvidenceGUID): boolean
	assert(EvidenceGUID and typeof(EvidenceGUID) == "string", "Invalid EvidenceGUID; Must be a string")

	local response = HttpService:RequestAsync({
		Url = Config.API_ENTRY .. "/evidence/" .. EvidenceGUID,
		Method = "DELETE",
		Headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. Config.API_KEY,
		}
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

function API:CreateEvidence(CaseGUID: CaseGUID, EvidenceType: EvidenceType, EvidenceContent: string): (boolean, EvidenceGUID?)
	assert(CaseGUID and typeof(CaseGUID) == "string", "Invalid CaseGUID; Must be a string")
	assert(EvidenceType and typeof(EvidenceType) == "string", "Invalid EvidenceType; Must be a string")
	assert(EvidenceContent and typeof(EvidenceContent) == "string", "Invalid EvidenceContent; Must be a string")
	assert(EvidenceType == "Metadata", "Invalid EvidenceType; EvidenceType can only be a 'Metadata'. Roblox does not support file uploading.")

	local response = HttpService:RequestAsync({
		Url = Config.API_ENTRY .. "/evidence/create",
		Method = "PATCH",
		Headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. Config.API_KEY,
		},
		Body = HttpService:JSONEncode({
			caseId = CaseGUID,
			evidenceType = EvidenceType,
			evidenceContent = Util.Base64:Encode(EvidenceContent), -- API expects encoded contents
		}),
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

function API:EditEvidenceMetadata(EvidenceGUID: EvidenceGUID, Metadata: { [string]: any }): boolean
	assert(EvidenceGUID and typeof(EvidenceGUID) == "string", "Invalid EvidenceGUID; Must be a string")
	assert(Metadata and typeof(Metadata) == "table", "Invalid Metadata; Must be a table")

	local response = HttpService:RequestAsync({
		Url = Config.API_ENTRY .. "/evidence/" .. EvidenceGUID .. "/metadata",
		Method = "PATCH",
		Headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. Config.API_KEY,
		},
		Body = HttpService:JSONEncode(Metadata),
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

function API:GetEvidenceMetadata(EvidenceGUID: EvidenceGUID): (boolean, evidenceMetadata?)
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