_G.root_path = "../.."
package.path = package.path .. ";" .. root_path .. "/?.lua;" .. root_path .. "/?/init.lua"

local widgets = require("widgets.common")
conky_main = widgets.conky_main

config = require("config")

conky_main = function()
    widgets.conky_main(config)
end
