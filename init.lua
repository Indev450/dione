local STATUS_PLAYERS = "%d player%s %s" -- Watches n player(s) race/battle
local STATUS_EMPTY = "an empty map" -- Watches an empty map
local STATUS_ERROR = "until you'll help me"
local STATUS_GAMEMODE = os.getenv("SRB2KART_STATUS_GAMEMODE") -- If nil, chooses between "race" or "battle"
local SLASHPLAYERS_GAMEMODE = os.getenv("SRB2KART_SLASHPLAYERS_GAMEMODE") -- If nil, chooses between "racing" or "battling"

local STATUS_UPDATE_INTERVAL = 5*1000

local discordia = require("discordia")
local dcmd = require("discordia-slash")
local dcmdtools = dcmd.util.tools()
local timer = require("timer")

local wrap = coroutine.wrap

local client = discordia.Client({
    autoReconnect = tonumber(os.getenv("DISCORD_NOAUTORECONNECT") or "0") == 0,
}):useApplicationCommands()

local SRB2Kart = require("./srb2kart.lua")

local server = SRB2Kart:new(os.getenv("SRB2KART_ADDRESS") or "127.0.0.1", os.getenv("SRB2KART_PROTO") or "srb2kart-16p", os.getenv("SRB2KART_GAMEMODEFILE"))

local function getStatusGamemode(gametype)
    if STATUS_GAMEMODE then return STATUS_GAMEMODE end

    -- Special case for DRRR
    if type(gametype) == "string" then return gametype:lower() end

    return gametype == 2 and "race" or "battle"
end

local function getSlashplayersGamemode(gametype)
    if SLASHPLAYERS_GAMEMODE then return SLASHPLAYERS_GAMEMODE end

    -- Special case for DRRR
    if type(gametype) == "string" then
        -- Just so race and battle is consistent with kart
        if gametype:find("Race") then
            gametype = 2
        elseif gametype:find("Battle") then
            gametype = 0
        else
            return "playing "..gametype
        end
    end

    return gametype == 2 and "racing" or "battling"
end

-- This prob should be done in better way. Have to use coroutine because setStatus yields and that causes error because
-- you can't do that from c function (which happens when using timer)
local function updateStatus()
    server:askInfo()

    local numplayers = server.serverinfo.numplayers

    if server:isInfoExpired() then
        client:setStatus(discordia.enums.status.doNotDisturb)
        client:setActivity({
            name = STATUS_ERROR,
            type = discordia.enums.activityType.watching,
        })
    elseif numplayers == 0 then
        client:setStatus(discordia.enums.status.online)
        client:setActivity({
            name = STATUS_EMPTY,
            type = discordia.enums.activityType.watching,
        })
    else
        local text = STATUS_PLAYERS:format(numplayers, numplayers > 1 and 's' or '', getStatusGamemode(server.serverinfo.gametype or server.serverinfo.gametypename))

        client:setStatus(discordia.enums.status.online)
        client:setActivity({
            name = text,
            type = discordia.enums.activityType.watching,
        })
    end
end

local function deleteUnsupportedCommands(supported)
    for id, cmd in pairs(client:getGlobalApplicationCommands()) do
        if not supported[cmd.name] then
            client:deleteGlobalApplicationCommand(id)
        end
    end
end

client:on("ready", function()
    timer.setInterval(STATUS_UPDATE_INTERVAL, function() wrap(updateStatus)() end)

    local supported = {}

    local function registerCmd(name, desc)
        local cmd = dcmdtools.slashCommand(name, desc)
        client:createGlobalApplicationCommand(cmd)
        supported[name] = true
    end

    -- Is it fine that i create those each restart?
    registerCmd("players", "Get player info")

    if server.gamemodefile ~= nil then
        registerCmd("gamemode", "Get current gamemode")
    end

    deleteUnsupportedCommands(supported)

    wrap(function()
        client:setStatus(discordia.enums.status.idle)
        client:setActivity()
    end)()
end)

-- Not 100% sure if this is necessary
local function fixname(name)
    local nterm = name:find('\000')

    if nterm then
        name = name:sub(1, nterm-1)
    end

    return name
end

local function joinnames(names, verb)
    if #names == 0 then return "No one is "..verb end

    local last = table.remove(names)

    if #names == 0 then
        return last.." is "..verb
    else
        return table.concat(names, ", ").." and "..last.." are "..verb
    end
end

client:on("slashCommand", function(ia, cmd, args)
    if server:isInfoExpired() then
        ia:reply("Server is currently unavailable.")
        return
    end

    if cmd.name == "players" then
        local playing = {}
        local spec = {}
        local resp = ""
        local verb = getSlashplayersGamemode(server.serverinfo.gametype or server.serverinfo.gametypename)

        local map = "Unknown"

        if server.serverinfo.maptitle then
            map = fixname(server.serverinfo.maptitle):gsub('^%s*(.-)%s*$', '%1') -- Remove embedded zeros and trim the title

            -- Append zone, if needed
            if server.serverinfo.iszone ~= 0 then
                map = map.." Zone"
            end
        end

        for _, p in ipairs(server.playerinfo) do
            if p.node ~= 255 then
                table.insert(p.team == 0 and playing or spec, fixname(p.name))
            end
        end

        -- This is ugly lol
        if #playing == 0 then
            if #spec == 0 then
                resp = "No one is "..verb..", map is "..map.."."
            else
                resp = joinnames(spec, "watching").." at "..map.."."
            end
        else
            if #spec == 0 then
                resp = joinnames(playing, verb).." at "..map.."."
            else
                resp = joinnames(playing, verb)..", "..joinnames(spec, "watching").." at "..map.."."
            end
        end

        ia:reply(resp)
    elseif cmd.name == "gamemode" then
        local gamemodes = server:getGamemodes()

        if gamemodes == nil then
            ia:reply("Unable to fetch gamemodes right now.")
        else
            ia:reply(string.format("Current gamemode%s: %s.", #gamemodes > 1 and "s are" or " is", table.concat(gamemodes, ", ")))
        end
    end
end)

client:run("Bot "..(os.getenv("DISCORD_TOKEN") or error("DISCORD_TOKEN env variable is required")))
