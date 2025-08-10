-- config.lua
-- conky clock widget
-- by @rizado
-- 5 August 2025

config = {
    boxes = {
        {
            type = "background",
            x = 0,
            y = 0,
            w = 400,
            h = 240,
            centre_x = true,
            corners = { 8, 8, 8, 8 },
            rotation = 0,
            skew_x = 0,
            skew_y = 0,
            draw_me = true,
            colour = { { 1, 0x000000, 0.5 } },
        },
    },
    bars = {
    },
    rings = {
        {
            name = "time",
            arg = "%I",
            max = 12,
            xc = 120,
            yc = 120,
            radius = 70,
            thickness = 10,
            start_angle = 0,
            end_angle = 360,
            sectors = 12,
            gap_sectors = 3,
            cap = "p",
            fill_sector = true,
            background = true,
            foreground = true,
            border_size = 1,
            bg_colour1 = { { 0, 0x333333, 0.3 }, { 1, 0x333333, 0.3 } },
            fg_colour1 = { { 0, 0x00FF00, 0.8 }, { 1, 0x00FF00, 0.8 } },
            bd_colour1 = { { 0, 0x00FF00, 0.5 }, { 1, 0x00FF00, 0.5 } },
        },
        {
            name = "time",
            arg = "%M",
            max = 60,
            xc = 120,
            yc = 120,
            radius = 85,
            thickness = 10,
            start_angle = 0,
            end_angle = 360,
            sectors = 60,
            gap_sectors = 2,
            fill_sector = true,
            bg_colour1 = { { 0, 0x222222, 0.2 }, { 1, 0x222222, 0.2 } },
            fg_colour1 = { { 0, 0x00AAFF, 0.7 }, { 1, 0x00AAFF, 0.7 } },
        },
        {
            name = "time",
            arg = "%S",
            max = 60,
            xc = 120,
            yc = 120,
            radius = 100,
            thickness = 10,
            start_angle =0,
            end_angle = 360,
            sectors = 60,
            gap_sectors = 2,
            fill_sector = true,
            bg_colour1 = { { 0, 0x111111, 0.1 }, { 1, 0x111111, 0.1 } },
            fg_colour1 = { { 0, 0xFF0000, 0.9 }, { 1, 0xFF0000, 0.9 } },
        },
    },
    texts = {
        {
            text = "${time %l:%M}",
            font_name = "Ubuntu",
            font_size = 32,
            bold = true,
            x = 140,
            y = 120,
            h_align = "r",
            v_align = "m",
            colour = { { 1, 0xFFFFFF, 1 } },
        },
        {
            text = "${time %S}",
            font_name = "Ubuntu",
            font_size = 20,
            bold = true,
            x = 150,
            y = 115,
            h_align = "l",
            v_align = "b",
            colour = { { 1, 0xFFFFFF, 1 } },
        },

    }
}

return config
