-- Copyright (c) 2024 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

local ChatCommands = {
	PluginEnabled = true,
	PluginSettings = {
		PREFIX = "/s",
		CHAT_COMMAND_PERMISSION_PARSER = function(Player: Player): boolean
			-- Server-side runtime context. Return a boolean depending on if they can run it.
			return Player:GetRankInGroup(34910499) >= 3
		end,
	},
}

ChatCommands.__index = ChatCommands

local Players = game:GetService("Players")

local function getUserByPartial(partialUsername): Player?
	for _, player in pairs(Players:GetPlayers()) do
		if string.lower(player.Name):sub(1, #partialUsername) == string.lower(partialUsername) then
			return player
		end
	end

	return nil
end

function ChatCommands:Init(Settings)
	local self = setmetatable({}, ChatCommands)

	self.Settings = Settings
	self.Enum = require(script.Parent.Parent.Enum)
	self.API = require(script.Parent.Parent.SentinelAPI)
	self:Start()

	return self
end

function ChatCommands:Start()
	local function PlayerAdded(Player: Player)
		Player.Chatted:Connect(function(message: string)
			local args = message:split(" ")

            -- /spban {partial_user} {y/n} {reason}
			if args[1] == self.PluginSettings.PREFIX .. "pban" then
				local target: Player? = getUserByPartial(args[2])
				local isGlobal: boolean = (args[3] == "true" or args[3] == "t" or args[3] == "y") and true or false
				local reason: string = table.concat(args, " ", 4)

				if
					target == nil
					or reason == nil
					or reason ~= nil and (string.len(reason) < 1 or string.len(reason) > 400)
				then
					return
				end

				self.API:BanAsync(target, {
					Moderator = Player.UserId,

					BanType = isGlobal and self.Enum.BanType.Global or self.Enum.BanType.Experience,
					BanLengthType = self.Enum.BanLengthType.Permanent,
					BanLength = 0,

					PublicReason = reason,
					PrivateReason = reason,

					BanKnownAlts = true,
					BanUniversal = true,
				})
			end

            -- /sban {partial_user} {time i.e 1d, 1y, etc.} {y/n} {reason}
			if args[1] == self.PluginSettings.PREFIX .. "ban" then
				local target: Player? = getUserByPartial(args[2])
				local banTime: string = args[3]
				local isGlobal: boolean = (args[4] == "true" or args[4] == "t" or args[4] == "y") and true or false
				local reason: string = table.concat(args, " ", 5)

				if
					target == nil
					or banTime == nil
					or reason == nil
					or reason ~= nil and (string.len(reason) < 1 or string.len(reason) > 400)
				then
					return
				end

				self.API:BanAsync(target, {
					Moderator = Player.UserId,

					BanType = isGlobal and self.Enum.BanType.Global or self.Enum.BanType.Experience,
					BanLengthType = self.Enum.BanLengthType.Temporary,
					BanLength = banTime,

					PublicReason = reason,
					PrivateReason = reason,

					BanKnownAlts = true,
					BanUniversal = true,
				})
			end
		end)
	end

	Players.PlayerAdded:Connect(PlayerAdded)

	for i, v in pairs(Players:GetPlayers()) do
		PlayerAdded(v)
	end
end

return ChatCommands
