-- Copyright (c) 2025 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

export type BanType = string
export type BanLengthType = string

export type BanInfo = {
    guid: string;
    workspaceGuid: string;
    isGlobal: boolean;
    isActive: boolean;
    isAppealed: boolean;
    privateReason: string;
    publicReason: string;
    experienceUniversal: boolean;
    experienceBanCompleted: boolean;
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

return {}