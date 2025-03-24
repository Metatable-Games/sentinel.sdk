-- Copyright (c) 2025 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

export type void = nil;

for i,v in pairs(script.Parent:WaitForChild("SentinelAPI"):GetChildren()) do
    if not v:IsA("ModuleScript") then
        continue
    end

    if v:FindFirstChild("Types") and v.Types:IsA("ModuleScript") then
        require(v.Types)
    end
end

return {}