local baseURL = "http://iris.cfcservers.org/api"

local function postJson( endpoint, data, callbackSuccess, callbackFailure )
    HTTP{
        failed = callbackFailure,
        success = callbackSuccess,
        method = "POST",
        url = baseURL .. endpoint,
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
        userData[util.SteamIDTo64(k)] = v
    end

    postJson( "/ranks/bulk_update", {
        users = userData,
        realm = "cfc3",
    }, nil, logError )
end

hook.Add( "InitPostEntity", "CFC_IrisInterface_BulkRankUpdate", sendGroupsToIris )

hook.Add( "ULibUserGroupChange", "CFC_IrisInterface_UpdateRanks", function( steamid, allows, denies, newGroup, oldGroup )
    local steamid64 = util.SteamIDTo64( steamid )
    postJson( "/ranks/bulk_update", {
        users = {
            [steamid64] = {
                group = newGroup
            }
        },
        realm = "cfc3"
    } )
end )
