-- common.lua
-- conky widgets common
-- by @rizado
-- original code by @wim66, thanks
-- 5 August 2025    

require("cairo")

local status, cairo_xlib = pcall(require, "cairo_xlib")

if not status then
    cairo_xlib = setmetatable({}, {
        __index = function(_, k)
            return _G[k]
        end,
    })
end

local unpack = table.unpack or unpack

-- Centralized default values for bargraph settings
local defaults_boxes = {
    x = 0,
    y = 0,
    w = conky_window and conky_window.width or 0,
    h = conky_window and conky_window.height or 0,
}

local defaults_bars = {
    x = conky_window and conky_window.width / 2 or 0, -- Default x position (middle of window)
    y = conky_window and conky_window.height / 2 or 0, -- Default y position (middle of window)
    blocks = 10,                                     -- Number of blocks in the bar
    height = 10,                                     -- Height of each block
    width = 30,                                      -- Width of each block
    space = 2,                                       -- Space between blocks
    angle = 0,
    skew_x = 0,                                      -- Rotation angle of the bar (degrees)
    cap = "b",                                       -- Line cap: "b" (butt), "r" (round), "s" (square)
    bg_colour = { 0x00FF00, 0.5 },                   -- Background color (green, half opacity)
    fg_colour = { 0x00FF00, 1 },                     -- Foreground color (green, full opacity)
    alarm_colour = nil,                              -- Alarm color (falls back to fg_colour)
    smooth = false,                                  -- Enable gradient effect
    led_effect = nil,                                -- LED effect: "r", "a", "e" or nil
    radius = 0,                                      -- Radius for circular bars
    angle_bar = 0,                                   -- Angle for circular bars
    skew_x = 0,                                      -- Skewness on x-axis
    skew_y = 0,                                      -- Skewness on y-axis
    reflection_alpha = 0,                            -- Transparency of reflection
    reflection_length = 1,                           -- Length of reflection
    reflection_scale = 1,                            -- Scale of reflection
}

local defaults_rings = {
    cx = conky_window and conky_window.width / 2 or 0, -- Default x position (middle of window)
    cy = conky_window and conky_window.height / 2 or 0, -- Default y position (middle of window)
}

local defaults_texts = {

}

-- Helper function to merge tables (default values with user settings)
function merge_tables(defaults, user_settings)
    local result = {}
    for k, v in pairs(defaults) do
        result[k] = v
    end
    for k, v in pairs(user_settings) do
        result[k] = v
    end
    return result
end

function hex_to_rgba(hex, alpha)
    return ((hex >> 16) & 0xFF) / 255, ((hex >> 8) & 0xFF) / 255, (hex & 0xFF) / 255, alpha
end

-- Function to draw a bargraph with multiple blocks or a single bar
function draw_multi_bar_graph(t)
    cairo_save(cr)

    -- Check if the bar should be drawn
    if t.draw_me == true then
        t.draw_me = nil
    end
    if t.draw_me ~= nil and conky_parse(tostring(t.draw_me)) ~= "1" then
        return
    end
    if t.name == nil and t.arg == nil then
        print("No input values ... use parameters 'name' with 'arg' or only parameter 'arg'")
        return
    end
    if t.max == nil then
        print("No maximum value defined, use 'max'")
        return
    end
    if t.name == nil then
        t.name = ""
    end
    if t.arg == nil then
        t.arg = ""
    end

    -- Set line cap and delta for round or square ends
    local cap = "b"
    for i, v in ipairs({ "s", "r", "b" }) do
        if v == t.cap then
            cap = v
        end
    end
    local delta = 0
    if t.cap == "r" or t.cap == "s" then
        delta = t.height
    end
    if cap == "s" then
        cap = CAIRO_LINE_CAP_SQUARE
    elseif cap == "r" then
        cap = CAIRO_LINE_CAP_ROUND
    elseif cap == "b" then
        cap = CAIRO_LINE_CAP_BUTT
    end

    -- Validate and set colors
    if #t.bg_colour ~= 2 then
        t.bg_colour = { 0x00FF00, 0.5 }
    end
    if #t.fg_colour ~= 2 then
        t.fg_colour = { 0x00FF00, 1 }
    end
    if t.alarm_colour == nil then
        t.alarm_colour = t.fg_colour
    end
    if #t.alarm_colour ~= 2 then
        t.alarm_colour = t.fg_colour
    end

    if t.mid_colour ~= nil then
        for i = 1, #t.mid_colour do
            if #t.mid_colour[i] ~= 3 then
                print("error in mid_color table")
                t.mid_colour[i] = { 1, 0xFFFFFF, 1 }
            end
        end
    end

    if t.bg_led ~= nil and #t.bg_led ~= 2 then
        t.bg_led = t.bg_colour
    end
    if t.fg_led ~= nil and #t.fg_led ~= 2 then
        t.fg_led = t.fg_colour
    end
    if t.alarm_led ~= nil and #t.alarm_led ~= 2 then
        t.alarm_led = t.fg_led
    end

    if t.led_effect ~= nil then
        if t.bg_led == nil then
            t.bg_led = t.bg_colour
        end
        if t.fg_led == nil then
            t.fg_led = t.fg_colour
        end
        if t.alarm_led == nil then
            t.alarm_led = t.fg_led
        end
    end

    if t.alarm == nil then
        t.alarm = t.max
    end
    t.angle = t.angle * math.pi / 180
    t.angle_bar = t.angle_bar * math.pi / 360
    t.skew_x = math.pi * t.skew_x / 180
    t.skew_y = math.pi * t.skew_y / 180

    -- Create a linear gradient for smooth effect
    local function create_smooth_linear_gradient(x0, y0, x1, y1)
        local pat = cairo_pattern_create_linear(x0, y0, x1, y1)
        cairo_pattern_add_color_stop_rgba(pat, 0, hex_to_rgba(t.fg_colour[1], t.fg_colour[2]))
        cairo_pattern_add_color_stop_rgba(pat, 1, hex_to_rgba(t.alarm_colour[1], t.alarm_colour[2]))
        if t.mid_colour ~= nil then
            for i = 1, #t.mid_colour do
                cairo_pattern_add_color_stop_rgba(pat, t.mid_colour[i][1], hex_to_rgba(t.mid_colour[i][2], t.mid_colour[i][3]))
            end
        end
        return pat
    end

    -- Create a radial gradient for smooth effect
    local function create_smooth_radial_gradient(x0, y0, r0, x1, y1, r1)
        local pat = cairo_pattern_create_radial(x0, y0, r0, x1, y1, r1)
        cairo_pattern_add_color_stop_rgba(pat, 0, hex_to_rgba(t.fg_colour[1], t.fg_colour[2]))
        cairo_pattern_add_color_stop_rgba(pat, 1, hex_to_rgba(t.alarm_colour[1], t.alarm_colour[2]))
        if t.mid_colour ~= nil then
            for i = 1, #t.mid_colour do
                cairo_pattern_add_color_stop_rgba(pat, t.mid_colour[i][1], hex_to_rgba(t.mid_colour[i][2], t.mid_colour[i][3]))
            end
        end
        return pat
    end

    -- Create a linear LED gradient
    local function create_led_linear_gradient(x0, y0, x1, y1, col_alp, col_led)
        local pat = cairo_pattern_create_linear(x0, y0, x1, y1)
        cairo_pattern_add_color_stop_rgba(pat, 0.0, hex_to_rgba(col_alp[1], col_alp[2]))
        cairo_pattern_add_color_stop_rgba(pat, 0.5, hex_to_rgba(col_led[1], col_led[2]))
        cairo_pattern_add_color_stop_rgba(pat, 1.0, hex_to_rgba(col_alp[1], col_alp[2]))
        return pat
    end

    -- Create a radial LED gradient
    local function create_led_radial_gradient(x0, y0, r0, x1, y1, r1, col_alp, col_led, mode)
        local pat = cairo_pattern_create_radial(x0, y0, r0, x1, y1, r1)
        if mode == 3 then
            cairo_pattern_add_color_stop_rgba(pat, 0, hex_to_rgba(col_alp[1], col_alp[2]))
            cairo_pattern_add_color_stop_rgba(pat, 0.5, hex_to_rgba(col_led[1], col_led[2]))
            cairo_pattern_add_color_stop_rgba(pat, 1, hex_to_rgba(col_alp[1], col_alp[2]))
        else
            cairo_pattern_add_color_stop_rgba(pat, 0, hex_to_rgba(col_led[1], col_led[2]))
            cairo_pattern_add_color_stop_rgba(pat, 1, hex_to_rgba(col_alp[1], col_alp[2]))
        end
        return pat
    end

    -- Draw a single bar (for blocks=1)
    local function draw_single_bar(pct)
        local function create_pattern(col_alp, col_led, bg)
            local pat
            if not t.smooth then
                if t.led_effect == "e" then
                    pat = create_led_linear_gradient(-delta, 0, delta + t.width, 0, col_alp, col_led)
                elseif t.led_effect == "a" then
                    pat = create_led_linear_gradient(t.width / 2, 0, t.width / 2, -t.height, col_alp, col_led)
                elseif t.led_effect == "r" then
                    pat = create_led_radial_gradient(t.width / 2, -t.height / 2, 0, t.width / 2, -t.height / 2, t.height / 1.5, col_alp, col_led, 2)
                else
                    pat = cairo_pattern_create_rgba(hex_to_rgba(col_alp[1], col_alp[2]))
                end
            else
                if bg then
                    pat = cairo_pattern_create_rgba(hex_to_rgba(t.bg_colour[1], t.bg_colour[2]))
                else
                    pat = create_smooth_linear_gradient(t.width / 2, 0, t.width / 2, -t.height)
                end
            end
            return pat
        end

        local y1 = -t.height * pct / 100
        local y2, y3
        if pct > (100 * t.alarm / t.max) then
            y1 = -t.height * t.alarm / 100
            y2 = -t.height * pct / 100
            if t.smooth then
                y1 = y2
            end
        end

        if t.angle_bar == 0 then
            local pat = create_pattern(t.fg_colour, t.fg_led, false)
            cairo_set_source(cr, pat)
            cairo_rectangle(cr, 0, 0, t.width, y1)
            cairo_fill(cr)
            cairo_pattern_destroy(pat)

            if not t.smooth and y2 ~= nil then
                pat = create_pattern(t.alarm_colour, t.alarm_led, false)
                cairo_set_source(cr, pat)
                cairo_rectangle(cr, 0, y1, t.width, y2 - y1)
                cairo_fill(cr)
                y3 = y2
                cairo_pattern_destroy(pat)
            else
                y2, y3 = y1, y1
            end
            cairo_rectangle(cr, 0, y2, t.width, -t.height - y3)
            pat = create_pattern(t.bg_colour, t.bg_led, true)
            cairo_set_source(cr, pat)
            cairo_pattern_destroy(pat)
            cairo_fill(cr)
        end
    end

    -- Draw multiple blocks (for blocks > 1)
    local function draw_multi_bar(pct, pcb)
        for pt = 1, t.blocks do
            local y1 = -(pt - 1) * (t.height + t.space)
            local light_on = false

            local col_alp = t.bg_colour
            local col_led = t.bg_led
            if pct >= (100 / t.blocks) or pct > 0 then
                if pct >= (pcb * (pt - 1)) then
                    light_on = true
                    col_alp = t.fg_colour
                    col_led = t.fg_led
                    if pct >= (100 * t.alarm / t.max) and (pcb * pt) > (100 * t.alarm / t.max) then
                        col_alp = t.alarm_colour
                        col_led = t.alarm_led
                    end
                end
            end

            local pat
            if not t.smooth then
                if t.angle_bar == 0 then
                    if t.led_effect == "e" then
                        pat = create_led_linear_gradient(-delta, 0, delta + t.width, 0, col_alp, col_led)
                    elseif t.led_effect == "a" then
                        pat = create_led_linear_gradient(t.width / 2, -t.height / 2 + y1, t.width / 2, 0 + t.height / 2 + y1, col_alp, col_led)
                    elseif t.led_effect == "r" then
                        pat = create_led_radial_gradient(t.width / 2, y1, 0, t.width / 2, y1, t.width / 1.5, col_alp, col_led, 2)
                    else
                        pat = cairo_pattern_create_rgba(hex_to_rgba(col_alp[1], col_alp[2]))
                    end
                else
                    if t.led_effect == "a" then
                        pat = create_led_radial_gradient(
                            0,
                            0,
                            t.radius + (t.height + t.space) * (pt - 1),
                            0,
                            0,
                            t.radius + (t.height + t.space) * pt,
                            col_alp,
                            col_led,
                            3
                        )
                    else
                        pat = cairo_pattern_create_rgba(hex_to_rgba(col_alp[1], col_alp[2]))
                    end
                end
            else
                if light_on then
                    if t.angle_bar == 0 then
                        pat = create_smooth_linear_gradient(t.width / 2, t.height / 2, t.width / 2, -(t.blocks - 0.5) * (t.height + t.space))
                    else
                        pat = create_smooth_radial_gradient(0, 0, (t.height + t.space), 0, 0, (t.blocks + 1) * (t.height + t.space), 2)
                    end
                else
                    pat = cairo_pattern_create_rgba(hex_to_rgba(t.bg_colour[1], t.bg_colour[2]))
                end
            end
            cairo_set_source(cr, pat)
            cairo_pattern_destroy(pat)

            if t.angle_bar == 0 then
                cairo_move_to(cr, 0, y1)
                cairo_line_to(cr, t.width, y1)
            else
                cairo_arc(cr, 0, 0, t.radius + (t.height + t.space) * pt - t.height / 2, -t.angle_bar - math.pi / 2, t.angle_bar - math.pi / 2)
            end
            cairo_stroke(cr)
        end
    end

    -- Set up the bargraph and draw it
    local function setup_bar_graph()
        if t.blocks ~= 1 then
            t.y = t.y - t.height / 2
        end

        local value = 0
        if t.name ~= "" then
            value = tonumber(conky_parse(string.format("${%s %s}", t.name, t.arg)))
        else
            value = tonumber(t.arg)
        end

        if value == nil then
            value = 0
        end

        local pct = 100 * value / t.max
        local pcb = 100 / t.blocks

        cairo_set_line_width(cr, t.height)
        cairo_set_line_cap(cr, cap)
        cairo_translate(cr, t.x, t.y)
        cairo_rotate(cr, t.angle)

        local matrix0 = cairo_matrix_t:create()
        tolua.takeownership(matrix0)
        cairo_matrix_init(matrix0, 1, t.skew_y, t.skew_x, 1, 0, 0)
        cairo_transform(cr, matrix0)

        if t.blocks == 1 and t.angle_bar == 0 then
            draw_single_bar(pct)
            if t.reflection == "t" or t.reflection == "b" then
                cairo_translate(cr, 0, -t.height)
            end
        else
            draw_multi_bar(pct, pcb)
        end

        -- Add reflection if set
        if t.reflection_alpha > 0 and t.angle_bar == 0 then
            local pat2
            local matrix1 = cairo_matrix_t:create()
            tolua.takeownership(matrix1)
            if t.angle_bar == 0 then
                pts = { -delta / 2, (t.height + t.space) / 2, t.width + delta, -(t.height + t.space) * t.blocks }
                if t.reflection == "t" then
                    cairo_matrix_init(
                        matrix1,
                        1,
                        0,
                        0,
                        -t.reflection_scale,
                        0,
                        -(t.height + t.space) * (t.blocks - 0.5) * 2 * (t.reflection_scale + 1) / 2
                    )
                    pat2 = cairo_pattern_create_linear(t.width / 2, -(t.height + t.space) * t.blocks, t.width / 2,
                        (t.height + t.space) / 2)
                elseif t.reflection == "r" then
                    cairo_matrix_init(matrix1, -t.reflection_scale, 0, 0, 1, delta + 2 * t.width, 0)
                    pat2 = cairo_pattern_create_linear(delta / 2 + t.width, 0, -delta / 2, 0)
                elseif t.reflection == "l" then
                    cairo_matrix_init(matrix1, -t.reflection_scale, 0, 0, 1, -delta, 0)
                    pat2 = cairo_pattern_create_linear(-delta / 2, 0, delta / 2 + t.width, -0)
                else
                    cairo_matrix_init(matrix1, 1, 0, 0, -1 * t.reflection_scale, 0, (t.height + t.space) * (t.reflection_scale + 1) / 2)
                    pat2 = cairo_pattern_create_linear(t.width / 2, (t.height + t.space) / 2, t.width / 2, -(t.height + t.space) * t.blocks)
                end
            end
            cairo_transform(cr, matrix1)

            if t.blocks == 1 and t.angle_bar == 0 then
                draw_single_bar(pct)
                cairo_translate(cr, 0, -t.height / 2)
            else
                draw_multi_bar(pct, pcb)
            end

            cairo_set_line_width(cr, 0.01)
            cairo_pattern_add_color_stop_rgba(pat2, 0, 0, 0, 0, 1 - t.reflection_alpha)
            cairo_pattern_add_color_stop_rgba(pat2, t.reflection_length, 0, 0, 0, 1)
            if t.angle_bar == 0 then
                cairo_rectangle(cr, pts[1], pts[2], pts[3], pts[4])
            end
            cairo_clip_preserve(cr)
            cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR)
            cairo_stroke(cr)
            cairo_mask(cr, pat2)
            cairo_pattern_destroy(pat2)
            cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
        end
    end

    setup_bar_graph()
    cairo_restore(cr)
end

function draw_single_text(t)
    cairo_save(cr)
    if t.draw_me == true then
        t.draw_me = nil
    end
    if t.draw_me ~= nil and conky_parse(tostring(t.draw_me)) ~= "1" then
        return
    end
    local function set_pattern(te)
        --this function set the pattern
        if #t.colour == 1 then
            cairo_set_source_rgba(cr, hex_to_rgba(t.colour[1][2], t.colour[1][3]))
        else
            local pat

            if t.radial == nil then
                local pts = linear_orientation(t, te)
                pat = cairo_pattern_create_linear(pts[1], pts[2], pts[3], pts[4])
            else
                pat = cairo_pattern_create_radial(t.radial[1], t.radial[2], t.radial[3], t.radial[4], t.radial[5],
                    t.radial[6])
            end

            for i = 1, #t.colour do
                cairo_pattern_add_color_stop_rgba(pat, t.colour[i][1], hex_to_rgba(t.colour[i][2], t.colour[i][3]))
            end
            cairo_set_source(cr, pat)
            cairo_pattern_destroy(pat)
        end
    end

    --set default values if needed
    if t.text == nil then
        t.text = "Conky is good for you !"
    end
    if t.x == nil then
        t.x = conky_window.width / 2
    end
    if t.y == nil then
        t.y = conky_window.height / 2
    end
    if t.colour == nil then
        t.colour = { { 1, 0xE7660B, 1 } }
    end
    if t.font_name == nil then
        t.font_name = 'Ubuntu'
    end
    if t.font_size == nil then
        t.font_size = 14
    end
    if t.angle == nil then
        t.angle = 0
    end
    if t.italic == nil then
        t.italic = false
    end
    if t.oblique == nil then
        t.oblique = false
    end
    if t.bold == nil then
        t.bold = false
    end
    if t.radial ~= nil then
        if #t.radial ~= 6 then
            print("error in radial table")
            t.radial = nil
        end
    end
    if t.orientation == nil then
        t.orientation = "ww"
    end
    if t.h_align == nil then
        t.h_align = "l"
    end
    if t.v_align == nil then
        t.v_align = "b"
    end
    if t.reflection_alpha == nil then
        t.reflection_alpha = 0
    end
    if t.reflection_length == nil then
        t.reflection_length = 1
    end
    if t.reflection_scale == nil then
        t.reflection_scale = 1
    end
    if t.skew_x == nil then
        t.skew_x = 0
    end
    if t.skew_y == nil then
        t.skew_y = 0
    end
    cairo_translate(cr, t.x, t.y)
    cairo_rotate(cr, t.angle * math.pi / 180)
--    cairo_save(cr)

    local slant = CAIRO_FONT_SLANT_NORMAL
    local weight = CAIRO_FONT_WEIGHT_NORMAL
    if t.italic then
        slant = CAIRO_FONT_SLANT_ITALIC
    end
    if t.oblique then
        slant = CAIRO_FONT_SLANT_OBLIQUE
    end
    if t.bold then
        weight = CAIRO_FONT_WEIGHT_BOLD
    end

    cairo_select_font_face(cr, t.font_name, slant, weight)

    for i = 1, #t.colour do
        if #t.colour[i] ~= 3 then
            print("error in color table")
            t.colour[i] = { 1, 0xFFFFFF, 1 }
        end
    end

    local matrix0 = cairo_matrix_t:create()
    tolua.takeownership(matrix0)
    local skew_x, skew_y = t.skew_x / t.font_size, t.skew_y / t.font_size
    cairo_matrix_init(matrix0, 1, skew_y, skew_x, 1, 0, 0)
    cairo_transform(cr, matrix0)
    cairo_set_font_size(cr, t.font_size)
    local te = cairo_text_extents_t:create()
    tolua.takeownership(te)
    t.text = conky_parse(t.text)
    cairo_text_extents(cr, t.text, te)
    set_pattern(te)

    local mx, my = 0, 0

    if t.h_align == "c" then
        mx = -te.width / 2 - te.x_bearing
    elseif t.h_align == "r" then
        mx = -te.width
    end
    if t.v_align == "m" then
        my = -te.height / 2 - te.y_bearing
    elseif t.v_align == "t" then
        my = -te.y_bearing
    end
    cairo_move_to(cr, mx, my)

    cairo_show_text(cr, t.text)

    if t.reflection_alpha ~= 0 then
        local matrix1 = cairo_matrix_t:create()
        tolua.takeownership(matrix1)
        cairo_set_font_size(cr, t.font_size)

        cairo_matrix_init(matrix1, 1, 0, 0, -1 * t.reflection_scale, 0,
            (te.height + te.y_bearing + my) * (1 + t.reflection_scale))
        cairo_set_font_size(cr, t.font_size)
        te = nil
        local te = cairo_text_extents_t:create()
        tolua.takeownership(te)
        cairo_text_extents(cr, t.text, te)

        cairo_transform(cr, matrix1)
        set_pattern(te)
        cairo_move_to(cr, mx, my)
        cairo_show_text(cr, t.text)

        local pat2 = cairo_pattern_create_linear(0, (te.y_bearing + te.height + my), 0, te.y_bearing + my)
        cairo_pattern_add_color_stop_rgba(pat2, 0, 1, 0, 0, 1 - t.reflection_alpha)
        cairo_pattern_add_color_stop_rgba(pat2, t.reflection_length, 0, 0, 0, 1)

        --line is not drawn but with a size of zero, the mask won't be nice
        cairo_set_line_width(cr, 1)
        local dy = te.x_bearing
        if dy < 0 then
            dy = dy * -1
        end
        cairo_rectangle(cr, mx + te.x_bearing, te.y_bearing + te.height + my, te.width + dy, -te.height * 1.05)
        cairo_clip_preserve(cr)
        cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR)
        --cairo_stroke(cr)
        cairo_mask(cr, pat2)
        cairo_pattern_destroy(pat2)
        cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
        te = nil
    end
    cairo_restore(cr)
end

function linear_orientation(t, te)
    local w, h = te.width, te.height
    local xb, yb = te.x_bearing, te.y_bearing

    if t.h_align == "c" then
        xb = xb - w / 2
    elseif t.h_align == "r" then
        xb = xb - w
    end
    if t.v_align == "m" then
        yb = -h / 2
    elseif t.v_align == "t" then
        yb = 0
    end
    local p = 0
    if t.orientation == "nn" then
        p = { xb + w / 2, yb, xb + w / 2, yb + h }
    elseif t.orientation == "ne" then
        p = { xb + w, yb, xb, yb + h }
    elseif t.orientation == "ww" then
        p = { xb, h / 2, xb + w, h / 2 }
    elseif vorientation == "se" then
        p = { xb + w, yb + h, xb, yb }
    elseif t.orientation == "ss" then
        p = { xb + w / 2, yb + h, xb + w / 2, yb }
    elseif t.orientation == "ee" then
        p = { xb + w, h / 2, xb, h / 2 }
    elseif t.orientation == "sw" then
        p = { xb, yb + h, xb + w, yb }
    elseif t.orientation == "nw" then
        p = { xb, yb, xb + w, yb + h }
    end
    return p
end

function draw_single_ring(t)
    cairo_save(cr)

    local function calc_delta(tcol1, tcol2)
        --calculate deltas P R G B A to table_colour 1
        for x = 1, #tcol1 do
            tcol1[x].dA = 0
            tcol1[x].dP = 0
            tcol1[x].dR = 0
            tcol1[x].dG = 0
            tcol1[x].dB = 0
            if tcol2 ~= nil and #tcol1 == #tcol2 then
                local r1, g1, b1, a1 = hex_to_rgba(tcol1[x][2], tcol1[x][3])
                local r2, g2, b2, a2 = hex_to_rgba(tcol2[x][2], tcol2[x][3])
                tcol1[x].dP = (tcol2[x][1] - tcol1[x][1]) / t.sectors
                tcol1[x].dR = (r2 - r1) / t.sectors
                tcol1[x].dG = (g2 - g1) / t.sectors
                tcol1[x].dB = (b2 - b1) / t.sectors
                tcol1[x].dA = (a2 - a1) / t.sectors
            end
        end

        return tcol1
    end

    --check values
    local function setup(t)
        if t.name == nil and t.arg == nil then
            print("No input values ... use parameters 'name'" +
                " with 'arg' or only parameter 'arg' ")
            return
        end

        if t.max == nil then
            print("No maximum value defined, use 'max'")
            print("for name=" .. t.name)
            print("with arg=" .. t.arg)
            return
        end
        if t.name == nil then t.name = "" end
        if t.arg == nil then t.arg = "" end

        if t.xc == nil then t.xc = conky_window.width / 2 end
        if t.yc == nil then t.yc = conky_window.height / 2 end
        if t.thickness == nil then t.thickness = 10 end
        if t.radius == nil then t.radius = conky_window.width / 4 end
        if t.start_angle == nil then t.start_angle = 0 end
        if t.end_angle == nil then t.end_angle = 360 end
        if t.bg_colour1 == nil then
            t.bg_colour1 = { { 0, 0x00ffff, 0.1 }, { 0.5, 0x00FFFF, 0.5 }, { 1, 0x00FFFF, 0.1 } }
        end
        if t.fg_colour1 == nil then
            t.fg_colour1 = { { 0, 0x00FF00, 0.1 }, { 0.5, 0x00FF00, 1 }, { 1, 0x00FF00, 0.1 } }
        end
        if t.bd_colour1 == nil then
            t.bd_colour1 = { { 0, 0xFFFF00, 0.5 }, { 0.5, 0xFFFF00, 1 }, { 1, 0xFFFF00, 0.5 } }
        end
        if t.sectors == nil then t.sectors = 10 end
        if t.gap_sectors == nil then t.gap_sectors = 1 end
        if t.fill_sector == nil then t.fill_sector = false end
        if t.sectors == 1 then t.fill_sector = false end
        if t.border_size == nil then t.border_size = 0 end
        if t.cap == nil then t.cap = "p" end
        --some checks
        if t.thickness > t.radius then t.thickness = t.radius * 0.1 end
        t.int_radius = t.radius - t.thickness

        --check colors tables
        for i = 1, #t.bg_colour1 do
            if #t.bg_colour1[i] ~= 3 then t.bg_colour1[i] = { 1, 0xFFFFFF, 0.5 } end
        end
        for i = 1, #t.fg_colour1 do
            if #t.fg_colour1[i] ~= 3 then t.fg_colour1[i] = { 1, 0xFF0000, 1 } end
        end
        for i = 1, #t.bd_colour1 do
            if #t.bd_colour1[i] ~= 3 then t.bd_colour1[i] = { 1, 0xFFFF00, 1 } end
        end

        if t.bg_colour2 ~= nil then
            for i = 1, #t.bg_colour2 do
                if #t.bg_colour2[i] ~= 3 then t.bg_colour2[i] = { 1, 0xFFFFFF, 0.5 } end
            end
        end
        if t.fg_colour2 ~= nil then
            for i = 1, #t.fg_colour2 do
                if #t.fg_colour2[i] ~= 3 then t.fg_colour2[i] = { 1, 0xFF0000, 1 } end
            end
        end
        if t.bd_colour2 ~= nil then
            for i = 1, #t.bd_colour2 do
                if #t.bd_colour2[i] ~= 3 then t.bd_colour2[i] = { 1, 0xFFFF00, 1 } end
            end
        end

        if t.start_angle >= t.end_angle then
            local tmp_angle = t.end_angle
            t.end_angle = t.start_angle
            t.start_angle = tmp_angle
            -- print ("inversed angles")
            if t.end_angle - t.start_angle > 360 and t.start_angle > 0 then
                t.end_angle = 360 + t.start_angle
                print("reduce angles")
            end

            if t.end_angle + t.start_angle > 360 and t.start_angle <= 0 then
                t.end_angle = 360 + t.start_angle
                print("reduce angles")
            end

            if t.int_radius < 0 then t.int_radius = 0 end
            if t.int_radius > t.radius then
                local tmp_radius = t.radius
                t.radius = t.int_radius
                t.int_radius = tmp_radius
                print("inversed radius")
            end
            if t.int_radius == t.radius then
                t.int_radius = 0
                print("int radius set to 0")
            end
        end

        t.fg_colour1 = calc_delta(t.fg_colour1, t.fg_colour2)
        t.bg_colour1 = calc_delta(t.bg_colour1, t.bg_colour2)
        t.bd_colour1 = calc_delta(t.bd_colour1, t.bd_colour2)
    end

    if t.draw_me == true then t.draw_me = nil end
    if t.draw_me ~= nil and conky_parse(tostring(t.draw_me)) ~= "1" then return end
    --initialize table
    setup(t)

    --initialize cairo context
    cairo_translate(cr, t.xc, t.yc)
    cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)

    --get value
    local value = 0
    if t.name ~= "" then
        value = tonumber(conky_parse(string.format('${%s %s}', t.name, t.arg)))
    else
        value = tonumber(t.arg)
    end
    if value == nil then value = 0 end

    --initialize sectors
    --angle of a sector :
    local angleA = ((t.end_angle - t.start_angle) / t.sectors) * math.pi / 180
    --value of a sector :
    local valueA = t.max / t.sectors
    --first angle of a sector :
    local lastAngle = t.start_angle * math.pi / 180

    local function draw_sector(type_arc, angle0, angle, valpc, idx)
        --this function draws a portion of arc
        --type of arc, angle0 = strating angle, angle= angle of sector,
        --valpc = percentage inside the sector, idx = sctor number #
        local tcolor
        if type_arc == "bg" then --background
            if valpc == 1 then return end
            tcolor = t.bg_colour1
        elseif type_arc == "fg" then --foreground
            if valpc == 0 then return end
            tcolor = t.fg_colour1
        elseif type_arc == "bd" then --border
            tcolor = t.bd_colour1
        end

        --angles equivalents to gap_sector
        local ext_delta = math.atan(t.gap_sectors / (2 * t.radius))
        local int_delta = math.atan(t.gap_sectors / (2 * t.int_radius))

        --angles of arcs
        local ext_angle = (angle - ext_delta * 2) * valpc
        local int_angle = (angle - int_delta * 2) * valpc

        --define colours to use for this sector
        if #tcolor == 1 then
            --plain color
            local vR, vG, vB, vA = hex_to_rgba(tcolor[1][2], tcolor[1][3])
            cairo_set_source_rgba(cr, vR + tcolor[1].dR * idx,
                vG + tcolor[1].dG * idx,
                vB + tcolor[1].dB * idx,
                vA + tcolor[1].dA * idx)
        else
            --radient color
            local pat = cairo_pattern_create_radial(0, 0, t.int_radius, 0, 0, t.radius)
            for i = 1, #tcolor do
                local vP, vR, vG, vB, vA = tcolor[i][1], hex_to_rgba(tcolor[i][2], tcolor[i][3])
                cairo_pattern_add_color_stop_rgba(pat,
                    vP + tcolor[i].dP * idx,
                    vR + tcolor[i].dR * idx,
                    vG + tcolor[i].dG * idx,
                    vB + tcolor[i].dB * idx,
                    vA + tcolor[i].dA * idx)
            end
            cairo_set_source(cr, pat)
            cairo_pattern_destroy(pat)
        end

        --start drawing
        cairo_save(cr)
        --x axis is parrallel to start of sector
        cairo_rotate(cr, angle0 - math.pi / 2)

        local ri, re = t.int_radius, t.radius

        --point A
        local angle_a

        if t.cap == "p" then
            angle_a = int_delta
            if t.inverse_arc and type_arc ~= "bg" then
                angle_a = angle - int_angle - int_delta
            end
            if not (t.inverse_arc) and type_arc == "bg" then
                angle_a = int_delta + int_angle
            end
        else --t.cap=="r"
            angle_a = ext_delta
            if t.inverse_arc and type_arc ~= "bg" then
                angle_a = angle - ext_angle - ext_delta
            end
            if not (t.inverse_arc) and type_arc == "bg" then
                angle_a = ext_delta + ext_angle
            end
        end
        local ax, ay = ri * math.cos(angle_a), ri * math.sin(angle_a)

        --point B
        local angle_b = ext_delta
        if t.cap == "p" then
            if t.inverse_arc and type_arc ~= "bg" then
                angle_b = angle - ext_angle - ext_delta
            end
            if not (t.inverse_arc) and type_arc == "bg" then
                angle_b = ext_delta + ext_angle
            end
        else
            if t.inverse_arc and type_arc ~= "bg" then
                angle_b = angle - ext_angle - ext_delta
            end
            if not (t.inverse_arc) and type_arc == "bg" then
                angle_b = ext_delta + ext_angle
            end
        end
        local bx, by = re * math.cos(angle_b), re * math.sin(angle_b)

        -- EXTERNAL ARC B --> C
        local b0, b1
        if t.inverse_arc then
            if type_arc == "bg" then
                b0, b1 = ext_delta, angle - ext_delta - ext_angle
            else
                b0, b1 = angle - ext_angle - ext_delta, angle - ext_delta
            end
        else
            if type_arc == "bg" then
                b0, b1 = ext_delta + ext_angle, angle - ext_delta
            else
                b0, b1 = ext_delta, ext_angle + ext_delta
            end
        end

        ---POINT D
        local angle_c, angle_d
        if t.cap == "p" then
            angle_d = angle - int_delta
            if t.inverse_arc and type_arc == "bg" then
                angle_d = angle - int_delta - int_angle
            end
            if not (t.inverse_arc) and type_arc ~= "bg" then
                angle_d = int_delta + int_angle
            end
        else
            angle_d = angle - ext_delta
            if t.inverse_arc and type_arc == "bg" then
                angle_d = angle - ext_delta - ext_angle
            end
            if not (t.inverse_arc) and type_arc ~= "bg" then
                angle_d = ext_angle + ext_delta
            end
        end
        local dx, dy = ri * math.cos(angle_d), ri * math.sin(angle_d)

        -- INTERNAL ARC D --> A
        local d0, d1
        if t.cap == "p" then
            if t.inverse_arc then
                if type_arc == "bg" then
                    d0, d1 = angle - int_delta - int_angle, int_delta
                else
                    d0, d1 = angle - int_delta, angle - int_angle - int_delta
                end
            else
                if type_arc == "bg" then
                    d0, d1 = angle - int_delta, int_delta + int_angle
                else
                    d0, d1 = int_delta + int_angle, int_delta
                end
            end
        else
            if t.inverse_arc then
                if type_arc == "bg" then
                    d0, d1 = angle - ext_delta - ext_angle, ext_delta
                else
                    d0, d1 = angle - ext_delta, angle - ext_angle - ext_delta
                end
            else
                if type_arc == "bg" then
                    d0, d1 = angle - ext_delta, ext_delta + ext_angle
                else
                    d0, d1 = ext_angle + ext_delta, ext_delta
                end
            end
        end

        --draw sector
        cairo_move_to(cr, ax, ay)
        cairo_line_to(cr, bx, by)
        cairo_arc(cr, 0, 0, re, b0, b1)
        cairo_line_to(cr, dx, dy)
        cairo_arc_negative(cr, 0, 0, ri, d0, d1)
        cairo_close_path(cr);

        --stroke or fill sector
        if type_arc == "bd" then
            cairo_set_line_width(cr, t.border_size)
            cairo_stroke(cr)
        else
            cairo_fill(cr)
        end

        cairo_restore(cr)
    end
    --draw sectors
    local n0, n1, n2 = 1, t.sectors, 1
    if t.inverse_arc then n0, n1, n2 = t.sectors, 1, -1 end
    local index = 0
    for i = n0, n1, n2 do
        index = index + 1
        local valueZ = 1
        local cstA, cstB = (i - 1), i
        if t.inverse_arc then cstA, cstB = (t.sectors - i), (t.sectors - i + 1) end

        if value > valueA * cstA and value < valueA * cstB then
            if not t.fill_sector then
                valueZ = (value - valueA * cstA) / valueA
            end
        else
            if value < valueA * cstB then valueZ = 0 end
        end

        local start_angle = lastAngle + (i - 1) * angleA
        if t.foreground ~= false then
            draw_sector("fg", start_angle, angleA, valueZ, index)
        end
        if t.background ~= false then
            draw_sector("bg", start_angle, angleA, valueZ, i)
        end
        if t.border_size > 0 then draw_sector("bd", start_angle, angleA, 1, i) end
    end

    cairo_restore(cr)
end

function draw_custom_rounded_rectangle(cr, x, y, w, h, r)
    local tl, tr, br, bl = unpack(r)
    cairo_new_path(cr)
    cairo_move_to(cr, x + tl, y)
    cairo_line_to(cr, x + w - tr, y)
    if tr > 0 then
        cairo_arc(cr, x + w - tr, y + tr, tr, -math.pi / 2, 0)
    else
        cairo_line_to(cr, x + w, y)
    end
    cairo_line_to(cr, x + w, y + h - br)
    if br > 0 then
        cairo_arc(cr, x + w - br, y + h - br, br, 0, math.pi / 2)
    else
        cairo_line_to(cr, x + w, y + h)
    end
    cairo_line_to(cr, x + bl, y + h)
    if bl > 0 then
        cairo_arc(cr, x + bl, y + h - bl, bl, math.pi / 2, math.pi)
    else
        cairo_line_to(cr, x, y + h)
    end
    cairo_line_to(cr, x, y + tl)
    if tl > 0 then
        cairo_arc(cr, x + tl, y + tl, tl, math.pi, 3 * math.pi / 2)
    else
        cairo_line_to(cr, x, y)
    end
    cairo_close_path(cr)
end

local function get_centered_x(canvas_width, box_width)
    return (canvas_width - box_width) / 2
end

function draw_image(cr, image_path, x, y, w, h, rotation)
    cairo_save(cr)
    local image_surface = cairo_image_surface_create_from_png(root_path .. image_path)
    local status = cairo_surface_status(image_surface)
    if status ~= 0 then
        print("Failed to load image: " .. image_path)
        return
    end

    local img_w = cairo_image_surface_get_width(image_surface)
    local img_h = cairo_image_surface_get_height(image_surface)

    local scale_x = w / img_w
    local scale_y = h / img_h

    local cx, cy = x + w / 2, y + h / 2
    local angle = (rotation or 0) * math.pi / 180

    cairo_translate(cr, cx, cy)
    cairo_rotate(cr, angle)
    cairo_scale(cr, scale_x, scale_y)
    cairo_translate(cr, -img_w / 2, -img_h / 2)
    cairo_set_source_surface(cr, image_surface, 0, 0)
    cairo_paint(cr)
    cairo_restore(cr)
    cairo_surface_destroy(image_surface)
end

function draw_single_box(box)
    if conky_window == nil then
        return
    end

    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)
    local canvas_width = conky_window.width

    if box.draw_me then
        local x, y, w, h = box.x, box.y, box.w, box.h
        if box.centre_x then
            x = get_centered_x(canvas_width, w)
        end

        local cx, cy = x + w / 2, y + h / 2
        local angle = (box.rotation or 0) * math.pi / 180
        local skew_x = (box.skew_x or 0) * math.pi / 180 -- Convert degrees to radians
        local skew_y = (box.skew_y or 0) * math.pi / 180 -- Convert degrees to radians

        -- Save context and apply transformations
        cairo_save(cr)
        cairo_translate(cr, cx, cy)
        cairo_rotate(cr, angle)
        -- Apply skew transformation
        local matrix = cairo_matrix_t:create()
        cairo_matrix_init(matrix, 1, math.tan(skew_y), math.tan(skew_x), 1, 0, 0)
        cairo_transform(cr, matrix)
        cairo_translate(cr, -cx, -cy)

        if box.type == "background" then
            cairo_set_source_rgba(cr, hex_to_rgba(box.colour[1][2], box.colour[1][3]))
            draw_custom_rounded_rectangle(cr, x, y, w, h, box.corners)
            cairo_fill(cr)
        elseif box.type == "layer2" then
            local grad = cairo_pattern_create_linear(unpack(box.linear_gradient))
            for _, color in ipairs(box.colours) do
                cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
            end
            cairo_set_source(cr, grad)
            draw_custom_rounded_rectangle(cr, x, y, w, h, box.corners)
            cairo_fill(cr)
            cairo_pattern_destroy(grad)
        elseif box.type == "border" then
            local grad = cairo_pattern_create_linear(unpack(box.linear_gradient))
            for _, color in ipairs(box.colour) do
                cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
            end
            cairo_set_source(cr, grad)
            cairo_set_line_width(cr, box.border)
            draw_custom_rounded_rectangle(cr, x + box.border / 2, y + box.border / 2, w - box.border, h - box.border, {
                math.max(0, box.corners[1] - box.border / 2),
                math.max(0, box.corners[2] - box.border / 2),
                math.max(0, box.corners[3] - box.border / 2),
                math.max(0, box.corners[4] - box.border / 2),
            })
            cairo_stroke(cr)
            cairo_pattern_destroy(grad)
        elseif box.type == "image" then
            draw_image(cr, box.image, box.x, box.y, box.w, box.h, box.rotation)
        end

        cairo_restore(cr)
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

-- Основная функция отрисовки (вызывается из Conky)
function conky_main(config)
        -- Проверка структуры конфига
    if not config then
        print("Ошибка: конфигурация не передана")
        return
    end

    config.boxes = config.boxes or {}
    config.bars = config.bars or {}
    config.rings = config.rings or {}
    config.texts = config.texts or {}

    if conky_window == nil then
        return
    end
    if tonumber(conky_parse("$updates")) < 3 then
        return
    end

    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    cr = cairo_create(cs)

    for i, v in pairs(config.boxes) do
        draw_single_box(merge_tables(defaults_boxes, v))
    end
    for i, v in pairs(config.bars) do
        draw_multi_bar_graph(merge_tables(defaults_bars, v))
    end
    for i, v in pairs(config.rings) do
        draw_single_ring(merge_tables(defaults_rings, v))
    end
    for i, v in pairs(config.texts) do
        draw_single_text(merge_tables(defaults_texts, v))
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end

-- Возвращаем таблицу функций для внешнего использования
return {
    conky_main = conky_main,
}