-- config.lua
-- conky system info widget
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
            corners = { 8, 8, 8, 8 },
            rotation = 0,
            skew_x = 0,
            skew_y = 0,
            draw_me = true,
            color = { { 1, 0x000000, 0.5 } },
        },
        {
            type = "image",
            x = 8,
            y = 8,
            w = 384,
            h = 224,
            rotation = 0,
            draw_me = true,
            image = "/images/earth.png"
        },
    },
    bars = {
    },
    rings = {
    },
    texts = {
        {
            text = "World clock",
            font_name = "Ubuntu",
            font_size = 20,
            bold = true,
            x = 200,
            y = 15,
            h_align = "c",
            v_align = "t",
            color = { { 1, 0xFFFFFF, 1 } },
        },
    },
    globes = {
        {
            xc = 100,
            yc = 140,
            radius = 80,
            city_line_height = 30,
            city_line_space = 5,
            cities = {
                {
                    name = "Simferopol",
                    lat = 44.948,
                    lon = 34.104,
                    flag = "RU",
                    zone = "Europe/Simferopol",
                    color = { { 1, 0x00D1FF, 1 } },
                },
                {
                    name = "Coronel Suárez",
                    lat = -37.455,
                    lon = -61.933,
                    flag = "AR",
                    zone = "America/Argentina/Buenos_Aires",
                    color = { { 1, 0x00FFEF, 1 } },
                },
                {
                    name = "Beijing",
                    lat = 39.904,
                    lon = 116.408,
                    flag = "CN",
                    zone = "Asia/Shanghai",
                    color = { { 1, 0x3333cc, 1 } },
                },
                {
                    name = "Madrid",
                    lat = 40.400,
                    lon = -3.683,
                    flag = "ES",
                    zone = "Europe/Madrid",
                    color = { { 1, 0x3333cc, 1 } },
                },
            },
        },
    },
}

return config
