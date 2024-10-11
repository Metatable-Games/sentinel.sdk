-- Copyright (c) 2024 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

export type void = nil
export type BanType = string
export type BanLengthType = string

export type BanInfo = {
    guid: string;
    workspaceGuid: string;
    isGlobal: boolean;
    isActive: boolean;
    isAppealed: boolean;
    privateReason: boolean;
    publicReason: boolean;
    experienceUniversal: boolean;
    robloxId: number;
    moderatorId: number;
    created: number;
    updated: number;
    experienceId: number;
    expires: number;
}

export type BanConfig = {
    Moderator: number;

	BanType: BanType,

	BanLengthType: BanLengthType,
	BanLength: number | string | nil,

	PublicReason: string,
	PrivateReason: string,

	BanKnownAlts: boolean,
	BanUniversal: boolean?,

	_bypassChecks: boolean?,
}

export type BanList = {
    BanInfo
}

export type SentinelAPI = {
	-- Methods
	BanAsync: (Player: Player, BanConfig: BanConfig) -> boolean,
	OfflineBanAsync: (UserId: number, BanConfig: BanConfig) -> boolean,

	BatchBanAsync: (PlayerList: { Player }, BanConfig: BanConfig) -> (boolean, number, number),
	BatchOfflineBanAsync: (UserIds: { number }, BanConfig: BanConfig) -> (boolean, number, number),

    UnbanAsync: (UserId: number, Reason: string) -> boolean,

	IsPlayerBanned: (Player: Player) -> boolean,
	IsUserIdBanned: (UserId: number) -> boolean,

    ProccessPendingUnbans: () -> void,
    ProccessPendingBans: () -> void,

    GetPendingBans: () -> BanList,
    GetPendingUnbans: () -> BanList,
}

return {}
