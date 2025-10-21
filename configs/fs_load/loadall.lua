require("cairo")

_G.root_path = "../.."
package.path = package.path .. ";" .. root_path .. "/?.lua;" .. root_path .. "/?/init.lua"

local widgets = require("widgets.common")
conky_main = widgets.conky_main

config = require("config")

conky_main = function()
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    cr = cairo_create(cs)

    cairo_save(cr)

    widgets.conky_main(config, cr)

    cairo_restore(cr)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end
