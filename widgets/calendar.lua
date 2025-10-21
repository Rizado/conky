-- widgets/calendar.lua
-- conky widgets calendar
-- by @rizado
-- 21 October 2025   

local unpack = table.unpack or unpack

-- Значения по умолчанию. Редактировать только здесь!
-- Default values. Edit here only!
local defaults_cal = {
        x = 0,
        y = 0,
        cell_width = 30,
        cell_hspace = 4,
        cell_height = 24,
        cell_vspace = 4,
        header_height = 30,
        font_size_header = 18,
        start_week_day = 1,
        title_format = "%B %Y",
        week_day_names = {"Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"},
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
        draw_days_bg = false,
        color_days_bg = {{1, 0x333333, 1}},
        color_today_bg = {{1, 0x006600, 1}},
        show_events_days = 7,
        show_events_count = 5,
        events = {
        },
        font_name_events = "DejaVu Sans",
        events_item_height = 20,
        font_size_events = 14,
        color_events = {{1, 0xccffcc, 1}},
        bold_events = false,
        italic_events = false,
        events_pos_x = 12, -- relatively to right side of calendar 
        events_pos_y = 0, -- relatively to top of calendar
        events_spacing = 8,
        events_date_format = "%d.%m",
}

-- Функция для получения дня недели (0 = воскресенье, 1 = понедельник, ..., 6 = суббота)
-- Function to get the day of the week (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
local function get_weekday(year, month, day)
    local t = os.time({year = year, month = month, day = day})
    return os.date("%w", t)
end

local function get_days_in_month(year, month)
    local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    if month == 2 and (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) then
        return 29
    end
    return days_in_month[month]
end

local function get_month_name(month_num, cal_config)
    if cal_config and cal_config.month_names and #cal_config.month_names == 12 then
        return cal_config.month_names[month_num]
    else
        local current_date_for_name = os.time({year = 2025, month = month_num, day = 1})
        return os.date("%B", current_date_for_name)
    end
end

local function get_event_list(cal_config, current_date)
    local events_config = cal_config.events
    local days_ahead = cal_config.show_events_days
    local max_count = cal_config.show_events_count

    local start_date_time = os.time(current_date)
    -- Вычисляем end_date_time: добавляем days_ahead дней к start_date_time
    -- Calculate end_date_time: add days_ahead days to start_date_time
    local end_date_time = os.time({
        year = current_date.year,
        month = current_date.month,
        day = current_date.day + days_ahead
    })

    local filtered_events = {}

    for _, event_data in ipairs(events_config) do
        local event_date_str, event_text = event_data[1], event_data[2]
        -- Опциональный цвет: event_data[3]
        -- Optional color: event_data[3]
        local event_color = event_data[3]

        if event_date_str and event_text then
            local month_str, day_str = event_date_str:match("^(%d%d)[%.%/](%d%d)$")

            if month_str and day_str then
                local month = tonumber(month_str)
                local day = tonumber(day_str)

                if day >= 1 and day <= 31 and month >= 1 and month <= 12 then
                    local days_in_month_current_year = get_days_in_month(current_date.year, month)
                    local days_in_month_next_year = get_days_in_month(current_date.year + 1, month)

                    local event_time = nil
                    if day <= days_in_month_current_year then
                        event_time = os.time({
                            year = current_date.year, month = month, day = day,
                            hour = 0, min = 0, sec = 0
                        })
                        if event_time < start_date_time then
                            if day <= days_in_month_next_year then
                                event_time = os.time({
                                    year = current_date.year + 1, month = month, day = day,
                                    hour = 0, min = 0, sec = 0
                                })
                            else
                                event_time = nil
                            end
                        end
                    else
                        if day <= days_in_month_next_year then
                            event_time = os.time({
                                year = current_date.year + 1,
                                month = month,
                                day = day,
                                hour = 0, min = 0, sec = 0
                            })
                        end
                    end

                    if event_time and event_time >= start_date_time and event_time <= end_date_time then
                        table.insert(filtered_events, {
                            time = event_time,
                            text = event_text,
                            color = event_color -- Может быть nil // May be nil
                        })
                    end
                end
            end
        end
    end

    table.sort(filtered_events, function(a, b) return a.time < b.time end)

    local result = {}
    for i = 1, math.min(max_count, #filtered_events) do
        result[i] = filtered_events[i]
    end

    return result
end

local function render_event_list(cr, cal_config, events)
    local ex = cal_config.x + 7 * cal_config.cell_width + 6 * cal_config.cell_hspace + cal_config.events_pos_x
    local ey = cal_config.y + cal_config.events_pos_y
    for i = 1, #events do
        local event_text = {
            text =  os.date(cal_config.events_date_format, events[i].time) .. ": " .. events[i].text,
            font_name = cal_config.font_name_events,
            font_size = cal_config.font_size_events,
            bold = cal_config.bold_events,
            italic = cal_config.italic_events,
            v_align = "m",
            h_align = "l",
            color = events[i].color or cal_config.color_events,
            x = ex,
            y = ey + (cal_config.events_item_height + cal_config.events_spacing) * (i - 1) + cal_config.events_item_height / 2,
            draw_me = true,
        }
        draw_single_text(event_text, cr)
    end
end

local function draw_calendar_day(cal_config, day_num, x, y, is_current_month, is_weekend, is_today, cr)
    if cal_config.draw_days_bg then
        local color_bg = is_today and cal_config.color_today_bg or cal_config.color_days_bg
        local day_bg = {
            x = x,
            y = y,
            w = cal_config.cell_width,
            h = cal_config.cell_height,
            type = "background",
            color = color_bg,
            corners = {2, 2, 2, 2},
            draw_me = true,
        }
        draw_single_box(day_bg, cr)
    end

    local text_color = cal_config.color_current_month
    if not is_current_month then
        text_color = cal_config.color_prev_next_month
    elseif is_weekend then
        text_color = cal_config.color_weekend
    end

    local font_name = cal_config.font_name
    local font_size = cal_config.font_size
    local bold = cal_config.bold or false
    local italic = cal_config.italic or false
    if is_weekend then
        bold = cal_config.bold_weekend or bold
        italic = cal_config.italic_weekend or italic
    elseif is_today then
        font_name = cal_config.font_today or font_name
        font_size = cal_config.font_size_today or font_size
        bold = cal_config.bold_today or bold
        italic = cal_config.italic_today or italic
    end

    local day_text = {
        text = string.format("%2d", day_num),
        x = x + cal_config.cell_width - 3,
        y = y + cal_config.cell_height / 2,
        h_align = "r",
        v_align = "m",
        color = text_color,
        font_name = font_name,
        font_size = font_size,
        bold = bold,
        italic = italic,
        draw_me = true,
    }

    draw_single_text(day_text, cr)
end


function conky_calendar_main(config, cr)
    if not config then
        print("Error: config was not passed")
        return
    end

    local cal_config = merge_tables(defaults_cal, config.calendar or {})

    local current_date = os.date("*t")
    local current_year = current_date.year
    local current_month = current_date.month
    local current_day = current_date.day

    local year = cal_config.year or current_year
    local month = cal_config.month or current_month

    local days_in_month = get_days_in_month(year, month)
    local first_day_of_month_weekday = tonumber(get_weekday(year, month, 1))

    local offset = (first_day_of_month_weekday - cal_config.start_week_day + 7) % 7

    local days_in_prev_month = get_days_in_month(year, month - 1)
    local start_day_prev = days_in_prev_month - offset + 1

    local month_name = get_month_name(month, cal_config)
    local title_text = month_name .. " " .. year
    if cal_config.draw_month_bg then
        local month_bg = {
            x = cal_config.x,
            y = cal_config.y,
            w = 7 * cal_config.cell_width + 6 * cal_config.cell_hspace,
            h = cal_config.header_height,
            type = "background",
            color = cal_config.color_month_bg,
            corners = {2, 2, 2, 2},
            draw_me = true,
        }
        draw_single_box(month_bg, cr)
    end
    local title_config = {
        text = title_text,
        x = cal_config.x + (7 * cal_config.cell_width + 6 * cal_config.cell_hspace) / 2,
        y = cal_config.y + cal_config.header_height / 2,
        h_align = "c",
        v_align = "m",
        color = cal_config.color_title,
        font_name = cal_config.font_name,
        font_size = cal_config.font_size_header,
        bold = true,
        italic = false,
        draw_me = true,
    }
    draw_single_text(title_config, cr)

    for i = 0, 6 do
        if cal_config.draw_dayweek_bg then
            local dayweek_bg = {
                x = cal_config.x + i * (cal_config.cell_width + cal_config.cell_hspace),
                y = cal_config.y + cal_config.header_height + cal_config.cell_vspace,
                w = cal_config.cell_width,
                h = cal_config.cell_height,
                type = "background",
                color = cal_config.color_dayweek_bg,
                corners = {2, 2, 2, 2},
                draw_me = true,
            }
            draw_single_box(dayweek_bg, cr)
        end
        local day_name = cal_config.week_day_names[(i + cal_config.start_week_day) % 7 + 1]
        local name_config = {
            text = day_name,
            x = cal_config.x + i * (cal_config.cell_width + cal_config.cell_hspace) + cal_config.cell_width / 2,
            y = cal_config.y + cal_config.header_height + cal_config.cell_vspace + cal_config.cell_height / 2,
            h_align = "c",
            v_align = "m",
            color = cal_config.color_weekday_names,
            font_name = cal_config.font_name,
            font_size = cal_config.font_size,
            bold = false,
            italic = false,
            draw_me = true,
        }
        draw_single_text(name_config, cr)
    end

    local day_num = 1
    for row = 0, 5 do
        for col = 0, 6 do
            local grid_x = cal_config.x + col * (cal_config.cell_width + cal_config.cell_hspace)
            local grid_y = cal_config.y + cal_config.header_height + (row + 1) * (cal_config.cell_height + cal_config.cell_vspace)

            local day_to_draw = nil
            local is_current_month = false
            local is_today = false

            if row == 0 and col < offset then
                day_to_draw = start_day_prev + col
            elseif day_num <= days_in_month then
                day_to_draw = day_num
                is_current_month = true
                if year == current_year and month == current_month and day_num == current_day then
                    is_today = true
                end
                day_num = day_num + 1
            else
                day_to_draw = day_num - days_in_month
                day_num = day_num + 1
            end

            if day_to_draw then
                local is_weekend = ((col + cal_config.start_week_day) % 7 == 0) or ((col + cal_config.start_week_day) % 7 == 6) -- Вс, Сб (для start_week_day=1)
                draw_calendar_day(cal_config, day_to_draw, grid_x, grid_y, is_current_month, is_weekend, is_today, cr)
            end

            if day_num > days_in_month and row > 0 then
                 local last_drawn_col = col
                 local last_drawn_row = row
                 if (last_drawn_col + 1) % 7 ~= 0 then
                     for remaining_col = last_drawn_col + 1, 6 do
                         local grid_x_rem = cal_config.x + remaining_col * (cal_config.cell_width + cal_config.cell_hspace)
                         local grid_y_rem = cal_config.y + cal_config.header_height + (last_drawn_row + 1) * (cal_config.cell_height + cal_config.cell_vspace)
                         local day_to_draw_rem = day_num - days_in_month
                         local is_weekend_rem = ((remaining_col + cal_config.start_week_day) % 7 == 0) or ((remaining_col + cal_config.start_week_day) % 7 == 6)
                         draw_calendar_day(cal_config, day_to_draw_rem, grid_x_rem, grid_y_rem, false, is_weekend_rem, false, cr) -- is_current_month = false
                         day_num = day_num + 1
                     end
                 end
                 break
            end
        end
        if day_num > days_in_month then
             break
        end
    end
    events = get_event_list(cal_config, current_date)
    render_event_list(cr, cal_config, events)
end

return {
    conky_calendar_main = conky_calendar_main,
}
