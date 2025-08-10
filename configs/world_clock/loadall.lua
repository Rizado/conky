_G.root_path = "../.."
package.path = package.path .. ";" .. root_path .. "/?.lua;" .. root_path .. "/?/init.lua"

local widgets = require("widgets.common")
local globe = require("widgets.globe")

config = require("config")

conky_main = function()
    widgets.conky_main(config)
    globe.conky_globe_main(config)
end
