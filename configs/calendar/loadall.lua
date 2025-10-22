require("cairo")

_G.root_path = "../.."
package.path = package.path .. ";" .. root_path .. "/?.lua;" .. root_path .. "/?/init.lua"

local widgets = require("widgets.common")
local calendar = require("widgets.calendar")

config = require("config")

conky_main = function()
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    cr = cairo_create(cs)

    cairo_save(cr)

    widgets.conky_main(config, cr)
    if config.calendar then
        calendar.conky_calendar_main(config, cr)
    end

    cairo_restore(cr)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end
