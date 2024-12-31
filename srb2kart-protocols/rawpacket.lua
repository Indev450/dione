local core = require("core")

local RawPacket = core.Object:extend()

function RawPacket:initialize(fields)
    -- fields is array of entries { type, name[, default] }, where type is single option string
    -- that can be added into string.(un)pack fmt string, and name is field name
    -- default value is assigned when it cannot be (un)packed

    -- Split those
    local fmt = {"!1<"}
    local names = {}
    local defaults = {}

    for _, entry in ipairs(fields) do
        table.insert(fmt, entry[1])

        -- Add this as a field only if its not just pad bytes
        if entry[1]:gsub("x", "") ~= "" then
            table.insert(names, entry[2])

            if entry[3] then
                defaults[entry[2]] = entry[3]
            end
        end
    end

    self.fmt = table.concat(fmt)
    self.names = names
    self.defaults = defaults
end

function RawPacket:unpack(buf)
    local s = type(buf) == "string" and buf or buf:toString()
    local values = table.pack(string.unpack(self.fmt, s))

    local result = {}

    -- string.unpack returns values AND first unread byte. We might need it but its not actually part of values
    local unread = values[#values]
    values[#values] = nil

    for i, field in ipairs(self.names) do
        local value = values[i]

        if value == nil then value = self.defaults[field] end

        result[field] = value
    end

    return result, unread
end

-- Honestly this exists only for playerinfo lel
function RawPacket:unpackarray(buf, length)
    local s = type(buf) == "string" and buf or buf:toString()

    local results = {}

    for i = 1, length do
        local result, unread = self:unpack(s)

        table.insert(results, result)

        s = s:sub(unread)
    end

    return results
end

function RawPacket:pack(data)
    local values = {}

    for i, field in ipairs(self.names) do
        local value = data[field]

        if value == nil then value = self.defaults[field] end

        assert(value ~= nil)

        values[i] = value
    end

    return string.pack(self.fmt, table.unpack(values))
end

return RawPacket
