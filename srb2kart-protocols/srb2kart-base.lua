-- Common SRB2Kart protocol functionality
--
-- Protocols extend BaseProtocol and must:
--
-- 1 - call BaseProtocol.initialize(self, socket, server) in their initialize function
-- 2 - provide PT_ASKINFO, PT_SERVERINFO, PT_PLAYERINFO fields for packet numbers
-- 3 - provide MAXPLAYERS field for reading playerinfo packet (playerinfo packet is an array of length `numplayers`)
-- 4 - provide doomdata, serverinfo, playerinfo, askinfo RawPacket fields for (un)packing server packets
--
-- Note: doomdata should have checksum and packettype fields. Also, checksum is assumed to be UINT32 and to be first in every packet

local core = require("core")

local BaseProtocol = core.Object:extend()

function BaseProtocol:initialize(socket, server)
    socket:on("message", function(buf)
        local name, packet = self:analyzePacket(buf)

        if not name then return end

        server:emit(name, packet)
    end)
end

function BaseProtocol:analyzePacket(buf)
    local packet, unread = self.doomdata:unpack(buf)

    local remains = buf:sub(unread)

    local name, info

    if packet.packettype == self.PT_SERVERINFO then
        name = "serverinfo"
        info = self.serverinfo:unpack(remains)
    elseif packet.packettype == self.PT_PLAYERINFO then
        name = "playerinfo"
        info = self.playerinfo:unpackarray(remains, self.MAXPLAYERS)
    end

    return name, info
end

function BaseProtocol:netbufferChecksum(data)
    local c = 0x1234567

    for i = 1, #data do
        c = c + data:byte(i)*i
    end

    return c
end

function BaseProtocol:getAskInfoPacket()
    local data = self.doomdata:pack({ checksum = 0, packettype = self.PT_ASKINFO })..self.askinfo:pack({ version = 1 })

    data = data:sub(4+1) -- take away "checksum"

    local checksum = self:netbufferChecksum(data)

    data = string.pack("!1<I4", checksum)..data

    return data
end

return BaseProtocol
