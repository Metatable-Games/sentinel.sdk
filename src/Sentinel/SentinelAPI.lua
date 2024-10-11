-- Copyright (c) 2024 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

local Config = require(script.Parent:WaitForChild("Config"))
local types = require(script.Parent:WaitForChild("Types"))
local enum = require(script.Parent:WaitForChild("Enum"))
local RichBan = require(script.Parent:WaitForChild("RichBan"))

local HttpService = game:GetService("HttpService")

local API: types.SentinelAPI = {}

function API:BanAsync(Player: Player, BanConfig: types.BanConfig): boolean
	return self:OfflineBanAsync(Player.UserId, BanConfig)
end

function API:BatchBanAsync(PlayerList: { Player }, BanConfig: types.BanConfig): (boolean, number, number)
	local userids = {}

	for i, v in pairs(PlayerList) do
		table.insert(userids, v.UserId)
	end

	return self:BatchOfflineBanAsync(userids, BanConfig)
end

function API:BatchOfflineBanAsync(UserIds: { number }, BanConfig: types.BanConfig): (boolean, number, number)
	local failed: number, successful: number = 0, 0

	for i, v in pairs(UserIds) do
		local ok: boolean = self:OfflineBanAsync(v, BanConfig)

		if ok then
			successful += 1
		else
			failed += 1
		end

		task.wait(5)
	end

	return failed <= 0, successful, failed
end

function API:OfflineBanAsync(UserId: number, BanConfig: types.BanConfig): boolean
	assert(HttpService.HttpEnabled == true, "HttpService must be enabled for Sentinel to properly work!")

	assert(
		string.len(BanConfig.PublicReason) > 0 and string.len(BanConfig.PublicReason) <= 400,
		"PublicReason must be 1 character, no more than 400."
	)
	assert(
		string.len(BanConfig.PrivateReason) > 0 and string.len(BanConfig.PrivateReason) <= 1000,
		"PrivateReason must be 1 character, no more than 1000."
	)

	assert(BanConfig.BanType ~= nil, "BanType cannot be nil")
	assert(BanConfig.BanLengthType ~= nil, "BanLengthType cannot be nil")

	assert(enum.BanType[BanConfig.BanType] ~= nil, "BanType is not a valid member of Sentinel.enum.BanType")
	assert(
		enum.BanLengthType[BanConfig.BanLengthType] ~= nil,
		"BanLengthType is not a valid member of Sentinel.enum.BanLengthType"
	)

	if BanConfig.BanLengthType == enum.BanLengthType.Temporary then
		assert(BanConfig.BanLength ~= nil, "BanLength cannot be nil while BanLengthType is set as 'Temporary'.")
		assert(
			table.find({ "number", "string" }, typeof(BanConfig.BanLength)),
			"BanLength must be a 'string' or 'number'."
		)
	end

	if BanConfig.Moderator == nil then
		BanConfig.Moderator = 1
	end

	if BanConfig.BanUniversal == nil then
		BanConfig.BanUniversal = true
	end

	if BanConfig.BanKnownAlts == nil then
		BanConfig.BanKnownAlts = true
	end

	if BanConfig._bypassChecks == nil then
		BanConfig._bypassChecks = false
	end

	assert(typeof(BanConfig.Moderator) == "boolean", "Moderator must be a 'number'.")
	assert(typeof(BanConfig.BanKnownAlts) == "boolean", "BanKnownAlts must be a 'boolean'.")
	assert(typeof(BanConfig.BanUniversal) == "boolean", "BanUniversal must be a 'boolean'.")

	assert(typeof(BanConfig.PublicReason) == "string", "BanUniversal must be a 'string'.")
	assert(typeof(BanConfig.PrivateReason) == "string", "BanUniversal must be a 'string'.")

	assert(typeof(BanConfig.BanLengthType) == "string", "BanLengthType must be a 'string'.")
	assert(typeof(BanConfig.BanType) == "string", "BanType must be a 'string'.")

	------

	if not BanConfig._bypassChecks and self:IsUserIdBanned(UserId) then
		if Config.DEBUG_INFO_ENABLED then
			warn("User is already banned!")
		end

		return false
	end

	local response = HttpService:RequestAsync({
		Url = Config.API_ENTRY .. "/ban-async",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["x-api-key"] = Config.API_KEY,
		},
		Body = HttpService:JSONEncode({
			overwrite = BanConfig._bypassChecks,
			userId = UserId,
			experienceId = game.PlaceId,
			banModerator = BanConfig.Moderator,
			banType = BanConfig.BanType,
			banLengthType = BanConfig.BanLengthType,
			banLength = BanConfig.BanLengthType == enum.BanLengthType.Temporary and BanConfig.BanLength or false,
			banPublicReason = BanConfig.PublicReason,
			banPrivateReason = BanConfig.PrivateReason,
		}),
	})

	if not response.Success or response.Success and response.StatusCode ~= 200 then
		if Config.DEBUG_INFO_ENABLED then
			warn(
				"An erorr occured with an HttpSerivce Request to Sentinel Web API.",
				response.StatusCode,
				response.StatusMessage
			)
		end

		return false
	end

	if BanConfig.BanLengthType == enum.BanLengthType.Temporary then
		RichBan:TempbanPlayerAsync(
			{ UserId },
			BanConfig.BanLength,
			BanConfig.PrivateReason,
			BanConfig.PublicReason,
			BanConfig.BanUniversal
		)
	else
		RichBan:PermbanPlayerAsync({ UserId }, BanConfig.PrivateReason, BanConfig.PublicReason, BanConfig.BanUniversal)
	end

	return true
end

function API:IsPlayerBanned(Player: Player): boolean
	return self:IsUserIdBanned(Player.UserId)
end

function API:IsUserIdBanned(UserId: number): boolean
	assert(HttpService.HttpEnabled == true, "HttpService must be enabled for Sentinel to properly work!")

	local response = HttpService:RequestAsync({
		Url = Config.API_ENTRY .. "/is-banned",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
		},
		Body = HttpService:JSONEncode({
			userId = UserId,
			experienceId = game.PlaceId,
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

	local data = HttpService:JSONDecode(response.Body)

	-- Ban automatically expired; therefore remove.
	if data.isAppealed then
		data.isActive = true
		data.expires = 1
	end

	if data.isActive and data.expires > 0 and data.expires <= os.time() then
		data.isActive = false
		self:UnbanAsync(data.robloxId, "Ban automatically expired or was appealed.")
	end

	return data.isActive, data
end

function API:ReplicateUpdatedBan(UserId: number, BanConfig: types.BanConfig): boolean
	BanConfig._bypassChecks = true
	return self:OfflineBanAsync(UserId, BanConfig)
end

function API:UnbanAsync(UserId: number, Reason: string): boolean
	assert(HttpService.HttpEnabled == true, "HttpService must be enabled for Sentinel to properly work!")

	local response = HttpService:RequestAsync({
		Url = Config.API_ENTRY .. "/unban-async",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
		},
		Body = HttpService:JSONEncode({
			userId = UserId,
            reason = Reason,
			experienceId = game.PlaceId,
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

    return true
end

function API:ProccessPendingBans()
	assert(HttpService.HttpEnabled == true, "HttpService must be enabled for Sentinel to properly work!")

	local list: types.BanList = self:GetPendingBans()
	local f: number, s: number = 0, 0

	for i, v: types.BanInfo in pairs(list) do
		if v.isAppealed then
			v.isActive = true
			v.expires = 1
		end

        -- Ban expired before chance to ban.
		if v.isActive and v.expires > 0 and v.expires <= os.time() then
			continue
		end

		local success: boolean = self:BanAsync(list.robloxId, {
			Moderator = v.moderatorId,
			BanLengthType = v.expires > 0 and enum.BanLengthType.Temporary or enum.BanLengthType.Permanent,
			BanUniversal = v.experienceUniversal,
			BanLength = v.expires > 0 and v.expires or 0,
			PrivateReason = v.privateReason,
			PublicReason = v.publicReason,
		})

		if success then
			s += 1
		else
			f += 1
		end
	end

	if Config.DEBUG_INFO_ENABLED then
		warn(
			("Sentinel: Successfully processed pending ban(s). Completed %d/%d ban(s). %d failed."):format(
				s,
				table.getn(list),
				f
			)
		)
	end
end

function API:ProccessPendingUnbans()
	assert(HttpService.HttpEnabled == true, "HttpService must be enabled for Sentinel to properly work!")

	local list: types.BanList = self:GetPendingUnbans()
	local f: number, s: number = 0, 0

	for i, v in pairs(list) do
		local success: boolean = self:UnbanAsync(list.robloxId, "Ban automatically expired or was appealed.")

		if success then
			s += 1
		else
			f += 1
		end
	end

	if Config.DEBUG_INFO_ENABLED then
		warn(
			("Sentinel: Successfully processed pending unban(s). Completed %d/%d unban(s). %d failed."):format(
				s,
				table.getn(list),
				f
			)
		)
	end
end

function API:GetPendingBans(): types.BanList
	assert(HttpService.HttpEnabled == true, "HttpService must be enabled for Sentinel to properly work!")

	local response = HttpService:RequestAsync({
		Url = Config.API_ENTRY .. "/pending-bans",
		Method = "GET",
		Headers = {
			["Content-Type"] = "application/json",
		},
		Body = HttpService:JSONEncode({
			experienceId = game.PlaceId,
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

	return HttpService:JSONDecode(response.Body).list
end

function API:GetPendingUnbans(): types.BanList
	assert(HttpService.HttpEnabled == true, "HttpService must be enabled for Sentinel to properly work!")

	local response = HttpService:RequestAsync({
		Url = Config.API_ENTRY .. "/pending-unbans",
		Method = "GET",
		Headers = {
			["Content-Type"] = "application/json",
		},
		Body = HttpService:JSONEncode({
			experienceId = game.PlaceId,
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

	return HttpService:JSONDecode(response.Body).list
end

return API