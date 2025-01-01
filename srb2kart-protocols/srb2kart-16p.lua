-- SRB2Kart 1.6 - vanilla

local RawPacket = require("./rawpacket.lua")
local BaseProtocol = require("./srb2kart-base.lua")

local Protocol = BaseProtocol:extend()

function Protocol:initialize(socket, server)
    BaseProtocol.initialize(self, socket, server)

    -- Packet types
    self.PT_ASKINFO = 12
    self.PT_SERVERINFO = 13
    self.PT_PLAYERINFO = 14

    -- Number of players supported by server
    self.MAXPLAYERS = 32 -- Game sends MSCOMPAT_MAXPLAYERS players, which is 32

    -- Packet definitions
    self.doomdata = RawPacket:new({
        { "I4", "checksum", },

        { "xx", "padding", }, -- We don't need those

        { "I1", "packettype", },
        { "x", "padding", },

        -- Payload goes next
    })

    self.askinfo = RawPacket:new({
        { "I1", "version", 1 },
        { "I4", "time", 0 }, -- tic_t = UINT32
    })

    self.serverinfo = RawPacket:new({
        { "xx", "padding", },

        { "c16", "application", },
        { "I1", "version", },
        { "I1", "subversion", },
        { "I1", "numplayers", },
        { "I1", "maxplayers", },
        { "I1", "gametype", },
        { "I1", "modified", },
        { "I1", "cheats", },
        { "I1", "kartvars", },

        { "xxxxxxxxx", "padding", }, -- UINT8 fileneedednum, tic_t time, tic_t leveltime

        { "c32", "servername", },
        { "c8", "mapname", }, -- Something like MAP01
        { "c33", "maptitle", }, -- Something like Green Hills Zone
        { "I1", "actnum", },
        { "I1", "iszone", },

        -- We don't really need anything after (not that we need much earlier either but eh why not parse that as well)
    })

    self.playerinfo = RawPacket:new({
        { "I1", "node", },
        { "c22", "name", },
        { "I4", "address", },
        { "I1", "team", },
        { "I1", "skin", },
        { "I1", "data", }, -- 4 bits for color, hasflag, isit, and issuper one bit each, last bit is unused (wow this is weird lel)
        { "I4", "score", }, -- Oh so you've been saving up on color but for score you allocate WHOLE 4 bytes? :AAAAAAAAAAAA:
        { "I2", "timeinserver", },
    })
end

return Protocol
