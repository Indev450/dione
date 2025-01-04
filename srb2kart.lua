local ASKINFO_TIMEOUT = 5
local EXPIRED_TIMEOUT = ASKINFO_TIMEOUT*2 -- If we didn't get any info for this long time, consider server unavailable

local core = require("core")
local dgram = require("dgram")
local protocols = require("./srb2kart-protocols")

local SRB2Kart = core.Emitter:extend()

function SRB2Kart:initialize(addr, protocol, gamemodefile)
    local host = addr
    local port = 5029

    local colon = addr:find(':')
    if colon then
        host = addr:sub(1, colon-1)
        port = tonumber(addr:sub(colon+1)) or error("Port must be a number")
    end

    self.lastinfotime = 0
    self.host = host
    self.port = port
    self.socket = dgram.createSocket('upd4')
    self.socket:bind(0, "0.0.0.0")
    self.protocol = assert(protocols[protocol], "Protocol "..protocol.." does not exist"):new(self.socket, self)
    self.gamemodefile = gamemodefile

    self.serverinfo = {
        numplayers = 0,
        maxplayers = 0,
        gametype = 0,
        mapname = "MAP00",
        maptitle = "Unknown",
    }

    -- List of players
    self.playerinfo = {}

    self:on("serverinfo", function(info)
        self.serverinfo = info
        self.lastinfotime = os.time()
    end)

    self:on("playerinfo", function(info)
        self.playerinfo = info
        self.lastinfotime = os.time()
    end)

    print(string.format("SRB2Kart server: connecting to %s:%d", host, port))

    -- Just so we don't start with empty info
    self:askInfo()
end

function SRB2Kart:isInfoExpired()
    return os.difftime(os.time(), self.lastinfotime) > EXPIRED_TIMEOUT
end

function SRB2Kart:askInfo()
    local buf = self.protocol:getAskInfoPacket()

    self.socket:send(buf, self.port, self.host)
end

function SRB2Kart:getGamemodes()
    if self.gamemodefile == nil then return end

    local file = io.open(self.gamemodefile)

    if file == nil then return end

    local gamemodes = {}

    for line in file:lines() do
        table.insert(gamemodes, line)
    end

    if #gamemodes == 0 then
        gamemodes[1] = "vanilla"
    end

    return gamemodes
end

return SRB2Kart
