-- Copyright (c) 2025 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

local Config = require(script:WaitForChild("Config"))
local enum = require(script:WaitForChild("Enum"))
local Util = require(script:WaitForChild("Util"))
local API = require(script:WaitForChild("SentinelAPI")).new();
local BanTypes = require(script:WaitForChild("SentinelAPI"):WaitForChild("BanAPI"):WaitForChild("Types"))

API.BanAPI:BindEvents();

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local message_a: string =
	"U2VudGluZWwgTW9kZXJhdGlvbiBHcm91cCAoU01HKSBcblxuIFRoZSBkZXZlbG9wZXIocykgZm9yIHRoaXMgZXhwZXJpZW5jZSBuZWVkIHRvIGlucHV0IGEgcHJvcGVyIEFQSSBLZXkgaW4gU2VydmVyU2NyaXB0U2VydmljZS5TZW50aW5lbC5Db25maWcubHVhLg=="
local message_b: string =
	"WW91ciBhY2NvdW50IGlzIHN0aWxsIGN1cnJlbnRseSBiYW5uZWQgYnkgU2VudGluZWwgTW9kZXJhdGlvbiBHcm91cCAoU01HKSBPQ0FQSSBmb3IgJXMuIFRvIGFwcGVhbCB0aGlzIHBsZWFzZSBjb250YWN0IHRoZSBzZXJ2ZXIgYWRtaW5pc3RyYXRvcnMh"

local function PlayerAdded(Player: Player)
	if RunService:IsStudio() and not Config.PRODUCTION_MODE then
		warn("Sentinel is not enabled in Studio mode.")
		return
	end

	local isBanned: boolean, banInfo: BanTypes.BanInfo? = API.BanAPI:IsPlayerBanned(Player)

	if Config.API_KEY == "INPUT_API_KEY_HERE" then
		return Player:Kick(Util.Base64:Decode(message_a))
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

		return Player:Kick(Util.Base64:Decode(message_b):format(banInfo.publicReason))
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