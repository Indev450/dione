local STATUS_PLAYERS = "%d player%s %s" -- Watches n player(s) race/battle
local STATUS_EMPTY = "an empty map" -- Watches an empty map
local STATUS_ERROR = "until you'll help me"

local STATUS_UPDATE_INTERVAL = 5*1000

local discordia = require("discordia")
local dcmd = require("discordia-slash")
local dcmdtools = dcmd.util.tools()
local timer = require("timer")

local wrap = coroutine.wrap

local client = discordia.Client():useApplicationCommands()

local SRB2Kart = require("./srb2kart.lua")

local server = SRB2Kart:new(os.getenv("SRB2KART_ADDRESS") or "127.0.0.1", os.getenv("SRB2KART_PROTO") or "srb2kart-16p")

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
        local text = STATUS_PLAYERS:format(numplayers, numplayers > 1 and 's' or '', server.serverinfo.gametype == 2 and "race" or "battle")

        client:setStatus(discordia.enums.status.online)
        client:setActivity({
            name = text,
            type = discordia.enums.activityType.watching,
        })
    end
end

client:on("ready", function()
    timer.setInterval(STATUS_UPDATE_INTERVAL, function() wrap(updateStatus)() end)

    local players = dcmdtools.slashCommand("players", "Get player info")

    client:createGlobalApplicationCommand(players)

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
    if cmd.name == "players" then
        local playing = {}
        local spec = {}
        local resp = ""
        local verb = server.serverinfo.gametype == 2 and "racing" or "battling"
        local map = fixname(server.serverinfo.maptitle or "Unknown")

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
    end
end)

client:run("Bot "..(os.getenv("DISCORD_TOKEN") or error("DISCORD_TOKEN env variable is required")))
