-- globe.lua
-- conky widgets globe
-- by @rizado
-- original code by @wim66, thanks
-- 20 October 2025    

require("cairo")
require("widgets.common")

local status, cairo_xlib = pcall(require, "cairo_xlib")

if not status then
    cairo_xlib = setmetatable({}, {
        __index = function(_, k)
            return _G[k]
        end,
    })
end

local unpack = table.unpack or unpack

local defaults_globe = {
    rotation_speed = 60,              -- Speed for a full globe rotation, lower is faster
    pin_length = 20,                  -- Default length of the pin line from the globe to the label
    pin_radius = 5,                   -- Radius of the city pinhead (circle)
    font_name = "Ubuntu Mono",        -- Font used for city labels
    font_size = 12,                   -- Font size for labels
    bg_color = { { 1, 0x000000, 0.5 } },      -- Default text color for labels (black)
    label_color = { { 1, 0xFFFFFF, 1 } },      -- Default text color for labels (black)
    label_offset = 14,                -- Distance in pixels between the pin-head and label
    xc = 340,                         -- X-coordinate for the center of the globe
    yc = 160,                         -- Y-coordinate for the center of the globe
    radius = 90,
    globe_alpha = 0.75,
    globe_shadow = 0.2,                     -- Radius of the globe
    tilt = 23.44 * math.pi / 180,       -- Earth's axial tilt in radians
    time_bg_color = { { 1, 0x000000, 0.5 } },
    time_font_name = "Ubuntu",
    time_font_size = 12,
    time_text_color = { { 1, 0xffffff, 1 } }
}

local start_time = os.time()

local function get_rotation(config)
    local now = os.time()
    local rotation = (now - start_time) * 2 * math.pi / config.rotation_speed
    return rotation
end

local function project(lat, lon, config)
    -- Convert latitude and longitude into 3D Cartesian coordinates
    local x = math.cos(lat) * math.sin(lon)
    local y = math.sin(lat)
    local z = math.cos(lat) * math.cos(lon)

    -- Apply Earth's axial tilt to the y and z coordinates
    local y_tilt = y * math.cos(config.tilt) - z * math.sin(config.tilt)
    local z_tilt = y * math.sin(config.tilt) + z * math.cos(config.tilt)

    return x, y_tilt, z_tilt
end

local function draw_single_globe(config, cr)
    cairo_save(cr)
    cairo_set_source_rgba(cr, 0, 0, 0, config.globe_shadow)
    cairo_arc(cr, config.xc + 3, config.yc + 3, config.radius, 0, 2 * math.pi)
    cairo_fill(cr)

    local rotation = get_rotation(config)

    cairo_set_source_rgba(cr, 0, 0.5, 1, config.globe_alpha)
    cairo_arc(cr, config.xc, config.yc, config.radius, 0, 2 * math.pi)
    cairo_fill(cr)

    cairo_set_source_rgba(cr, 1, 1, 1, 0.2)
    cairo_set_line_width(cr, 1)

    for lon = -180, 150, 30 do
        local theta = (lon * math.pi / 180) + rotation
        cairo_new_path(cr)
        for phi = -90, 85, 5 do
            local phi1 = phi * math.pi / 180
            local phi2 = (phi + 5) * math.pi / 180
            local x1, y1, z1 = project(phi1, theta, config)
            local x2, y2, z2 = project(phi2, theta, config)
            if z1 > 0 and z2 > 0 then -- Only draw visible parts
                cairo_move_to(cr, config.xc + config.radius * x1, config.yc - config.radius * y1)
                cairo_line_to(cr, config.xc + config.radius * x2, config.yc - config.radius * y2)
            end
        end
        cairo_stroke(cr)
    end

    for lat = -75, 75, 15 do
        local phi = lat * math.pi / 180
        cairo_new_path(cr)
        for theta = 0, 2 * math.pi, 0.1 do
            local x1, y1, z1 = project(phi, theta + rotation, config)
            local x2, y2, z2 = project(phi, theta + rotation + 0.1, config)
            if z1 > 0 and z2 > 0 then -- Only draw visible parts
                cairo_move_to(cr, config.xc + config.radius * x1, config.yc - config.radius * y1)
                cairo_line_to(cr, config.xc + config.radius * x2, config.yc - config.radius * y2)
            end
        end
        cairo_stroke(cr)
    end

    local light_dir = { x = -1, y = 0, z = 0 }
    local offset = 60
    local shading = cairo_pattern_create_radial(
        config.xc + config.radius * light_dir.x * 0.6 + offset,
        config.yc - config.radius * light_dir.y * 0.6,
        config.radius * 0.1,
        config.xc - config.radius * light_dir.x * 0.6 + offset,
        config.yc + config.radius * light_dir.y * 0.6,
        config.radius * 1.2
    )
    cairo_pattern_add_color_stop_rgba(shading, 0.0, 0, 0, 0, 0.0)
    cairo_pattern_add_color_stop_rgba(shading, 0.5, 0, 0, 0, 0.0)
    cairo_pattern_add_color_stop_rgba(shading, 1.0, 0, 0, 0, 0.25)
    cairo_set_source(cr, shading)
    cairo_arc(cr, config.xc, config.yc, config.radius, 0, 2 * math.pi)
    cairo_fill(cr)
    cairo_pattern_destroy(shading)
    cairo_restore(cr)
end

local function draw_cities(config, cr)
    cairo_save(cr)
    local rotation = get_rotation(config)
    for _, city in ipairs(config.cities) do
        local phi = city.lat * math.pi / 180
        local theta = (city.lon * math.pi / 180) + rotation
        local x, y, z = project(phi, theta, config)

        if z > 0 then
            local px = config.xc + config.radius * x
            local py = config.yc - config.radius * y

            -- Draw a small dot where the pin touches the globe
            local dot_radius = 2.5
            cairo_arc(cr, px, py, dot_radius, 0, 2 * math.pi)
            cairo_set_source_rgba(cr, hex_to_rgba(city.color[1][2], city.color[1][3]))
            cairo_fill(cr)

            -- Calculate pin endpoint
            local angle = math.rad(city.pin_angle or -90)
            local length = city.pin_length or config.pin_length
            local pin_x = px + math.cos(angle) * length
            local pin_y = py + math.sin(angle) * length

            -- Draw the pin line
            cairo_set_source_rgba(cr, hex_to_rgba(city.color[1][2], city.color[1][3]))
            cairo_set_line_width(cr, 1)
            cairo_move_to(cr, px, py)
            cairo_line_to(cr, pin_x, pin_y)
            cairo_stroke(cr)

            -- Draw the pin head
            cairo_arc(cr, pin_x, pin_y, config.pin_radius, 0, 2 * math.pi)
            cairo_fill(cr)

            -- Optionally add a border around the pin head for better visibility
            cairo_set_source_rgba(cr, 0, 0, 0, 0.5) -- Dark border
            cairo_set_line_width(cr, 1)
            cairo_arc(cr, pin_x, pin_y, config.pin_radius, 0, 2 * math.pi)
            cairo_stroke(cr)


            local padding = 4
            local flag_file = "/images/flags/" .. city.flag .. ".png"
            local scale = 0.3 -- Scale factor, если draw_image принимает ширину/высоту

            cairo_select_font_face(cr, config.font_name, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
            cairo_set_font_size(cr, config.font_size)
            local extents = cairo_text_extents_t:create()
            cairo_text_extents(cr, city.name, extents)
            tolua.takeownership(extents)

            local flag_surface = nil
            local original_flag_width, original_flag_height = 0, 0
            local scaled_flag_width, scaled_flag_height = 0, 0
            local flag_path = root_path .. flag_file
            if flag_path then
                flag_surface = cairo_image_surface_create_from_png(flag_path)
                if flag_surface and cairo_surface_status(flag_surface) == 0 then
                    original_flag_width = cairo_image_surface_get_width(flag_surface)
                    original_flag_height = cairo_image_surface_get_height(flag_surface)
                    scaled_flag_width = original_flag_width * scale
                    scaled_flag_height = original_flag_height * scale
                else
                    flag_surface = nil
                end
            end

            local total_width = (scaled_flag_width > 0 and scaled_flag_width + 4 or 0) + extents.width + 2 * padding
            local total_height = math.max(extents.height, scaled_flag_height) + 2 * padding

            local box_x = pin_x - (total_width / 2)
            local box_y = pin_y - (config.label_offset or 0) - (total_height / 2) - padding
            local box_w = total_width
            local box_h = total_height

            draw_custom_rounded_rectangle(cr, box_x, box_y, box_w, box_h, {4, 4, 4, 4})
            cairo_set_source_rgba(cr, hex_to_rgba(config.bg_color[1][2], config.bg_color[1][3]))
            cairo_fill_preserve(cr)
            cairo_set_source_rgba(cr, 0, 0, 0, 0.4)
            cairo_set_line_width(cr, 1)
            cairo_stroke(cr)

            if flag_surface then -- Если флаг загружен
                local flag_img_x = box_x + padding
                local flag_img_y = box_y + (box_h - scaled_flag_height) / 2
                draw_image(cr, flag_file, flag_img_x, flag_img_y, scaled_flag_width, scaled_flag_height, 0)
            end

            local text_x = (scaled_flag_width > 0 and (box_x + padding + scaled_flag_width + 4) or (box_x + total_width / 2))
            local text_y = box_y + box_h / 2 + extents.height / 2 -- Приблизительно baseline

            local label_text_config = {
                text = city.name,
                x = text_x,
                y = text_y,
                h_align = "l",
                v_align = "b",
                color = config.label_color,
                font_name = config.font_name,
                font_size = config.font_size,
                bold = false,
                italic = false,
                angle = 0,
                skew_x = 0,
                skew_y = 0,
                radial = nil,
                orientation = "ww",
                reflection_alpha = 0,
                reflection_length = 1,
                reflection_scale = 1,
                draw_me = true,
            }
            draw_single_text(label_text_config, cr)

        end
    end
     cairo_restore(cr)
end

local function draw_time(config, cr)
    cairo_save(cr)
    local cnt = #config.cities
    -- max 6 lines with time!!!
    local item_first = 1
    local item_last = cnt
    local offset = 0
    if cnt > 6 then
        offset = ((os.time() - start_time) // 3) % (cnt - 5)
        item_first = 1 + offset
        item_last = 6 + offset
    end
    for i = item_first, item_last do
        -- Rectangle for background of time
        draw_custom_rounded_rectangle(cr, 200, 10 + 30 * i, 180, 24, {3, 3, 3, 3})
        cairo_set_source_rgba(cr, hex_to_rgba(config.time_bg_color[1][2], config.time_bg_color[1][3]))
        cairo_fill_preserve(cr)

        -- Flag
        local flag_file = "/images/flags/" .. config.cities[i].flag .. ".png"
        draw_image(cr, flag_file, 203, 13 + 30 * i, 24, 18, 0)

        -- Text label
        local lbl = config.cities[i].name .. ": " .. conky_parse("${tztime " .. config.cities[i].zone .. " %H:%M}")

        local time_text_config = {
            text = lbl,
            x = 233,
            y = 29 + 30 * i,
            h_align = "l",
            v_align = "b",
            color = config.time_text_color,
            font_name = config.time_font_name,
            font_size = config.time_font_size,
            bold = false,
            italic = false,
            angle = 0,
            skew_x = 0,
            skew_y = 0,
            radial = nil,
            orientation = "ww",
            reflection_alpha = 0,
            reflection_length = 1,
            reflection_scale = 1,
            draw_me = true,
        }
        draw_single_text(time_text_config, cr)
    end
    cairo_restore(cr)
end

function conky_globe_main(config, cr, widgets_module)
    if not config then
        print("Error: config was not passed")
        return
    end

    config.globes = config.globes or {}

    if conky_window == nil then
        return
    end
    if tonumber(conky_parse("$updates")) < 3 then
        return
    end

    for i, v in pairs(config.globes) do
        draw_single_globe(merge_tables(defaults_globe, v), cr)
        draw_cities(merge_tables(defaults_globe, v), cr)
        draw_time(merge_tables(defaults_globe, v), cr)
    end
end

return {
    conky_globe_main = conky_globe_main,
}