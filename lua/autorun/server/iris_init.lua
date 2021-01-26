require "cfclogger"

local logger = CFCLogger( "IrisInterface" )
local baseURL = "https://iris.cfcservers.org/api/"
local authToken = file.Read( "cfc/iris/auth_token.txt" )
local realm = file.Read( "cfc/realm.txt" )

local function removeNewlines( s )
    s = string.Replace( s, "\n", "" )
    s = string.Replace( s, "\r", "" )
    return s
end

realm = removeNewlines( realm )
authToken = removeNewlines( authToken )

local function postJson( endpoint, data, callbackSuccess, callbackFailure )
    HTTP{
        failed = callbackFailure or function( ... ) logger:info( ... ) end,
        success = callbackSuccess or function( ... ) logger:error( ... ) end,
        method = "POST",
        url = baseURL .. endpoint,
        headers = {
            Authorization = "Bearer " .. authToken
        },
        body = util.TableToJSON( data ),
        type = "application/json"
    }
end

local function logError( err )
    print( "CFC Iris Interface HTTP error: " .. err)
end

local function sendGroupsToIris()
    local userData = {}

    for k, v in pairs( ULib.ucl.users ) do
        userData[util.SteamIDTo64( k )] = v.group
    end

    postJson( "ranks/bulk_update", {
        users = userData,
        realm = realm,
        platform = "steam"
    }, nil, logError )
end

hook.Add( "Think", "CFC_IrisInterface_BulkRankUpdate", function()
    hook.Remove( "Think", "CFC_ClAddonLoader_LoadAddons" )
    sendGroupsToIris()
end )

hook.Add( "ULibUserGroupChange", "CFC_IrisInterface_UpdateRanks", function( steamid, allows, denies, newGroup, oldGroup )
    local steamid64 = util.SteamIDTo64( steamid )
    postJson( "ranks/bulk_update", {
        users = {
            [steamid64] = newGroup
        },
        realm = realm,
        platform = "steam"
    } )
end )
