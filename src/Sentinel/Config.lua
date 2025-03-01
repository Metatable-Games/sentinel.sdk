return {
    PRODUCTION_MODE = true;
    
    DEBUG_INFO_ENABLED = true;

    API_KEY = "sentinelAPI.f29bd2c7-da37-4b01-b9b3-48496e584d0d"; -- -- To create an API key go to your guild and run /newapikey. Running this command invalidates previous key & creates a new one.
   
    API_ENTRY = "https://sentinel.metatable.dev/api/v1"; -- DO NOT EDIT API_ENTRY UNLESS YOU HOST YOUR OWN API!

    UPDATE_CYCLE = 1 * 60; -- Update cycle to proccess pending bans, pending unbans, etc.

    USE_RBLX_BANS = true; -- This uses Roblox's Banning solution to block alts, etc. Please note that
    -- a user will only be unbanned when someone else connects to the server/while someone else is in-game.
    -- otherwise the ban is "perm".

    UNBAN_LUAUCRON = true;
    BAN_LUAUCRON = true;
}