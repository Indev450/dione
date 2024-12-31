local NAME = "SRB2Kart lua discord bot"

local STATUS_PLAYERS = "%d player%s %s" -- Watches n player(s) race/battle
local STATUS_EMPTY = "an empty map" -- Watches an empty map
local STATUS_ERROR = ":AAAAAAAAAAAA:" -- :AAAAAAAAAAAA:

local STATUS_UPDATE_INTERVAL = 5*1000

local discordia = require("discordia")
local dcmd = require("discordia-slash")
local timer = require("timer")
local p = require("pretty-print")

local client = discordia.Client():useSlashCommands()

local SRB2Kart = require("./srb2kart.lua")

local server = SRB2Kart:new(os.getenv("SRB2KART_ADDRESS") or "127.0.0.1", os.getenv("SRB2KART_PROTO") or "srb2kart-16p")

local function updateStatus()
    server:askInfo()

    local numplayers = server.serverinfo.numplayers

    if server:isInfoExpired() then
        client:setStatus("dnd")
        client:setActivity({
            name = STATUS_ERROR,
            type = 0,
        })
    elseif numplayers == 0 then
        client:setStatus("online")
        client:setActivity({
            name = STATUS_EMPTY,
            type = 3,
        })
    else
        local text = STATUS_PLAYERS:format(numplayers, numplayers > 1 and 's' or '', server.serverinfo.gametype == 2 and "race" or "battle")

        --[[
        for _, p in ipairs(server.playerinfo) do
            if p.node ~= 255 then
                print(p.name, p.team)
            end
        end
        --]]

        client:setStatus("online")
        client:setActivity({
            name = text,
            type = 3,
        })
    end
end

client:on("ready", function()
    timer.setInterval(STATUS_UPDATE_INTERVAL, updateStatus)

    client:slashCommand({
        name = "players",
        description = "Get player info"
    })
end)

client:on("slashCommand", function(ia, cmd, args)
    print(args)
end)


client:run(os.getenv("DISCORD_TOKEN") or error("DISCORD_TOKEN env variable is required"))
