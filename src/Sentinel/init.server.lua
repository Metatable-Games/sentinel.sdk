-- Copyright (c) 2024 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

local Config = require(script:WaitForChild("Config"))
local enum = require(script:WaitForChild("Enum"))
local API = require(script:WaitForChild("SentinelAPI")).new();
local BanTypes = require(script:WaitForChild("SentinelAPI"):WaitForChild("BanAPI"):WaitForChild("Types"))

API.BanAPI:BindEvents();

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local message_a: string =
	"U2VudGluZWwgTW9kZXJhdGlvbiBHcm91cCAoU01HKSBcblxuIFRoZSBkZXZlbG9wZXIocykgZm9yIHRoaXMgZXhwZXJpZW5jZSBuZWVkIHRvIGlucHV0IGEgcHJvcGVyIEFQSSBLZXkgaW4gU2VydmVyU2NyaXB0U2VydmljZS5TZW50aW5lbC5Db25maWcubHVhLg=="
local message_b: string =
	"WW91ciBhY2NvdW50IGlzIHN0aWxsIGN1cnJlbnRseSBiYW5uZWQgYnkgU2VudGluZWwgTW9kZXJhdGlvbiBHcm91cCAoU01HKSBPQ0FQSSBmb3IgJXMuIFRvIGFwcGVhbCB0aGlzIHBsZWFzZSBjb250YWN0IHRoZSBzZXJ2ZXIgYWRtaW5pc3RyYXRvcnMh"
local b64chars: string = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64lookup = {}

for i = 1, #b64chars do
	b64lookup[b64chars:sub(i, i)] = i - 1
end

local function f64(input)
	input = input:gsub("[^%w+/=]", "") -- Remove any characters that are not base64 valid
	local output = {}
	local input_length = #input

	for i = 1, input_length, 4 do
		local a = b64lookup[input:sub(i, i)] or 0
		local b = b64lookup[input:sub(i + 1, i + 1)] or 0
		local c = b64lookup[input:sub(i + 2, i + 2)] or 0
		local d = b64lookup[input:sub(i + 3, i + 3)] or 0

		-- Calculate the 24-bit number from Base64 values
		local n = bit32.lshift(a, 18) + bit32.lshift(b, 12) + bit32.lshift(c, 6) + d

		-- Extract and append the bytes to the output table
		table.insert(output, string.char(bit32.rshift(n, 16) % 256))
		if input:sub(i + 2, i + 2) ~= "=" then
			table.insert(output, string.char(bit32.rshift(n, 8) % 256))
		end
		if input:sub(i + 3, i + 3) ~= "=" then
			table.insert(output, string.char(n % 256))
		end
	end

	return table.concat(output)
end

local function PlayerAdded(Player: Player)
	if RunService:IsStudio() and not Config.PRODUCTION_MODE then
		warn("Sentinel is not enabled in Studio mode.")
		return
	end

	local isBanned: boolean, banInfo: BanTypes.BanInfo? = API.BanAPI:IsPlayerBanned(Player)

	if Config.API_KEY == "INPUT_API_KEY_HERE" then
		return Player:Kick(f64(message_a))
	end

	if isBanned and banInfo then
		-- Player was offline banned remotely; therefore proccess internal banning aspect.
		API.BanAPI:ReplicateUpdatedBan(Player.UserId, {
			Moderator = banInfo.moderatorId,
			BanType = banInfo.isGlobal and enum.BanType.Global or enum.BanType.Experience,
			BanLengthType = banInfo.expires > 0 and enum.BanLengthType.Temporary or enum.BanLengthType.Permanent,
			BanUniversal = banInfo.experienceUniversal,
			BanLength = banInfo.expires > 0 and banInfo.expires or 0,
			PrivateReason = banInfo.privateReason,
			PublicReason = banInfo.publicReason,
			BanKnownAlts = true,
		})

		return Player:Kick(f64(message_b):format(banInfo.publicReason))
	end
end

Players.PlayerAdded:Connect(PlayerAdded)

for i, v in pairs(Players:GetPlayers()) do
	PlayerAdded(v)
end

for i, v in pairs(script.Plugins:GetChildren()) do
	local sentinelPlugin = require(v)

	if not sentinelPlugin.PluginEnabled then
		continue
	end

	sentinelPlugin:Init()
end

if Config.UNBAN_LUAUCRON or Config.BAN_LUAUCRON then
	while task.wait(Config.UPDATE_CYCLE) and task.wait(0.1) do
		if Config.UNBAN_LUAUCRON then
			API.BanAPI:ProccessPendingUnbans()
		end

		if Config.BAN_LUAUCRON then
			API.BanAPI:ProccessPendingBans()
		end
	end
end