local protocols = {}

local function addProtocol(name)
    protocols[name] = require("./"..name..".lua")
end

addProtocol("srb2kart-16p")
addProtocol("saturn-32p")
addProtocol("saturn-126p")
addProtocol("ringracers-16p")

return protocols
