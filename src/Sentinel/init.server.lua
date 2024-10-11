-- Copyright (c) 2024 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

local Config = require(script:WaitForChild("Config"))
local API = require(script:WaitForChild("SentinelAPI"))

local Players = game:GetService("Players")

local function PlayerAdded(Player: Player)
    local isBanned: boolean, banInfo: any = API:IsPlayerBanned(Player);
end

Players.PlayerAdded:Connect(PlayerAdded)

for i,v in pairs(Players:GetPlayers()) do
    PlayerAdded(v);
end

while Config.UPDATE_CYCLE and task.wait(.1) do
    API:ProccessPendingUnbans();
    API:ProccessPendingBans();
end