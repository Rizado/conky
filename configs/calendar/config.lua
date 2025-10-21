-- config.lua
-- conky clock widget
-- by @rizado
-- 20 October 2025

config = {
    boxes = {
        {
            type = "background",
            x = 0,
            y = 0,
            w = 600,
            h = 240,
            centre_x = false,
            corners = { 8, 8, 8, 8 },
            rotation = 0,
            skew_x = 0,
            skew_y = 0,
            draw_me = true,
            color = { { 1, 0x000000, 0.5 } },
        },
    },
    bars = {
    },
    rings = {
    },
    texts = {
    },
    calendar = {
        x = 8,
        y = 8,
        cell_width = 30,
        cell_hspace = 4,
        cell_height = 24,
        cell_vspace = 4,
        header_height = 30,
        font_size_header = 18,
        start_week_day = 1,
        title_format = "%B %Y",
        week_day_names = {"Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"},
        -- For some slavic languages month names are incorrect
        month_names = {"Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"},
        color_title = {{1, 0xFFFFFF, 1}},
        color_weekday_names = {{1, 0xCCCCCC, 1}},
        color_current_month = {{1, 0xFFFFFF, 1}},
        color_prev_next_month = {{1, 0x888888, 1}},
        color_weekend = {{1, 0xFF3333, 1}},
        bold_weekend = true,
        italic_weekend = false,
        font_name = "DejaVu Sans",
        font_size = 14,
        font_today = "DejaVu Sans Bold",
        font_size_today = 16,
        bold_today = true,
        italic_today = false,
        draw_month_bg = false,
        color_month_bg = {{1, 0x000000, 1}},
        draw_dayweek_bg = false,
        color_dayweek_bg = {{1, 0x666666, 1}},
        draw_days_bg = true,
        color_days_bg = {{1, 0x333333, 0}},
        color_today_bg = {{1, 0x006600, 1}},
        show_events_days = 14,
        show_events_count = 5,
        events = {
            {"01.01", "Новый год"},
            {"01.07", "Рождество (православные)"},
            {"10.31", "Самайн / Samhain", {{1, 0xffcc00, 1}}},
            {"12.25", "Рождество (католики)"},
        },
    },
}

return config
