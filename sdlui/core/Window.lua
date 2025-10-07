-------------------------------------------------------------------------------
--  sdlui/core/Window.lua
--

    modHelpers = require("Helpers")


    local modComponents = require("Components")
    local Components = modComponents.Components


    local Window = {}


    Window.__index = Window


    Window.id = "Window"

    Window.init_flags = SDL_INIT_VIDEO

    Window.title = "SDLui Demo"
    Window.width = 640
    Window.height = 480
    Window.flags = 0

    Window.cursor = "hand"

    Window.color = {
        red = 32,
        green = 64,
        blue = 220,
        alpha = 255
    }

    Window.hovered_component = nil
    Window.focused_component = nil

    Window.input_caret = {
        x = 0,
        y = 0,
        width = 2,
        type = "block",
        blink = 1000,
        ticks = 0,
        state = false
    }


-------------------------------------------------------------------------------
--
    local function __component_surface_border(component)

        component.translated_area = modHelpers.translate_area(component)

        local SDL_Error = SDL_Surface({
            id = component.surface_id,
            width = component.translated_area.width,
            height = component.translated_area.height
        })

        if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
            return SDL_Error
        end

        if (component.border.weight <= 0) then
            return "OK"
        end
    
        SDL_Error = SDL_Rectangle({
            id = component.surface_id,
            x = 0,
            y = 0,
            width = component.translated_area.width,
            height = component.translated_area.height,
            red = component.border.red,
            green = component.border.green,
            blue = component.border.blue,
            alpha = component.border.alpha
        })

        return SDL_Error

    end


    local function __component_surface_face(component)

        local border_weight = component.border.weight

        local SDL_Error = SDL_Rectangle({
            id = component.surface_id,
            x = border_weight,
            y = border_weight,
            width = (component.translated_area.width - (border_weight * 2)),
            height = (component.translated_area.height - (border_weight * 2)),
            red = component.background.red,
            green = component.background.green,
            blue = component.background.blue,
            alpha = component.background.alpha
        })

        return SDL_Error

    end


    local function __component_surface_label(component)

        if (component.extended == nil) then
            return "OK"
        end

        local font_id = component.surface_id .. "__font__"

        local text_info = SDL_Textarea({
            font = component.extended.font,
            size = component.extended.size,
            text = component.extended.text
        })

        if (type(text_info) == "string") then
            return SDLui:set_error(string.format("__component_surface_label(): %s", text_info))
        end

        local text_surface = {
            id = font_id,
            font = component.extended.font,
            size = component.extended.size,
            text = component.extended.text,
            x = 100,
            y = 100,
            width = text_info.width,
            height = text_info.height,
            red =  component.foreground.red,
            green = component.foreground.green,
            blue = component.foreground.blue,
            alpha = component.foreground.alpha
        }

        component.extended.surface_id = font_id

        print(string.format("text_info: width=%d, height=%d", text_info.width, text_info.height))

        local SDL_Error = SDL_Text(text_surface)
        if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
            return SDL_Error
        end

        if (type(component.extended.x) == "string") then
            if (component.extended.x == "center") then
                text_surface.x = ((component.translated_area.width - text_info.width) / 2)
            elseif (component.extended.x == "left") then
                text_surface.x = 0
            elseif (component.extended.x == "right") then
                text_surface.x = (component.translated_area.width - text_info.width)
            end
        else
            text_surface.x = component.extended.x
        end

        if (type(component.extended.y) == "string") then
            if (component.extended.y == "center") then
                text_surface.y = ((component.translated_area.height - text_info.height) / 2)
            elseif (component.extended.y == "top") then
                text_surface.y = 0
            elseif (component.extended.y == "bottom") then
                text_surface.y = (component.translated_area.height - text_info.height)
            end
        else
            text_surface.y = component.extended.y
        end

        if not text_info or not text_info.width or not text_info.height then
            return SDLui:set_error("Window:render(): SDL_Surfaceinfo failed to return width/height")
        end
        
        text_surface.x = math.floor(text_surface.x + component.absolute_x + component.translated_area.x)
        text_surface.y = math.floor(text_surface.y + component.absolute_y + component.translated_area.y)

        SDL_Error = SDL_Texture(text_surface)
        if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
            return SDL_Error
        end
        
        SDL_Render(font_id)

        return "OK"

    end
            
    local function compute_window_end_from_start(full_text, start_index, area_width, font, font_size, cache)
        
        local text_length = #full_text

        if (text_length == 0 or start_index > text_length) then
            return start_index, ""
        end

        cache = cache or {}

        local cache_key = font .. "|" .. font_size .. "|" .. full_text
        local width_cache = cache[cache_key] or {}

        local function measure_substring_width(str)
            if width_cache[str] then
                return width_cache[str]
            end

            local info = SDL_Textarea({
                font = font,
                size = font_size,
                text = str
            })

            width_cache[str] = info.width
            return info.width
        end

        cache[cache_key] = width_cache

        local low = start_index
        local high = text_length
        local best_fit = start_index
        local substring = ""

        while (low <= high) do
            local mid = math.floor((low + high) / 2)
            local candidate = string.sub(full_text, start_index, mid)
            local w = measure_substring_width(candidate)

            if (w <= area_width) then
                best_fit = mid
                substring = candidate
                low = mid + 1
            else
                high = mid - 1
            end
        end

        return best_fit, substring

    end

    function __component_get_visible_text(component)

        local full_text = (component.extended.text or "")
        local area_width = component.translated_area.width
        local font = component.extended.font
        local font_size = component.extended.size
        local text_length = #full_text

        local caret_position = (component.extended.position or 0)

        if (caret_position < 0) then
            caret_position = 0
        end

        if (caret_position > text_length) then
            caret_position = text_length
        end

        component.extended.position = caret_position

        if (component.extended.start_position == nil) then
            component.extended.start_position = 0
        end

        local start_index = component.extended.start_position

        if (start_index < 0) then
            start_index = 0
        end

        local visible_substring = ""
        local current_width = 0
        local last_visible_index = start_index

        for i = (start_index + 1), text_length do
            local char = string.sub(full_text, i, i)
            local char_info = SDL_Textarea({ font = font, size = font_size, text = char })

            if ((current_width + char_info.width) > area_width) then
                break
            end

            visible_substring = visible_substring .. char
            current_width = current_width + char_info.width
            last_visible_index = i
        end

        component.extended.substring = visible_substring
        component.extended.end_position = last_visible_index

        if (caret_position < start_index) then
            component.extended.start_position = caret_position
            return __component_get_visible_text(component)
        end

        if (caret_position > last_visible_index) then
            component.extended.start_position = math.max(caret_position - #visible_substring, 0)
            return __component_get_visible_text(component)
        end

        local prefix_text = ""

        if (caret_position > start_index) then
            prefix_text = string.sub(full_text, start_index + 1, caret_position)
        end

        local prefix_info = SDL_Textarea({ font = font, size = font_size, text = prefix_text })

        component.extended.caret = {
            x = component.area.x + prefix_info.width,
            width = Window.input_caret.width,
            height = font_size
        }

        return visible_substring

    end

    function move_caret_left(component)

        component.extended = component.extended or {}

        local text = component.extended.text or ""
        local text_len = #text
        local pos = component.extended.position or 0
        local start_pos = component.extended.start_position or 1

        if (pos > 0) then
            component.extended.position = (pos - 1)
        end

        if (component.extended.position < start_pos) then
            if (start_pos > 1) then
                component.extended.start_position = (start_pos - 1)
            else
                component.extended.start_position = 1
            end
        end

        component.surface_id = nil
        component.extended.surface_id = nil

        __component_get_visible_text(component, false, false)

    end

    function move_caret_right(component)

        component.extended = component.extended or {}

        local text = component.extended.text or ""
        local text_len = #text
        local pos = component.extended.position or 0
        local end_pos = component.extended.end_position or text_len

        if (pos < text_len) then
            component.extended.position = (pos + 1)
        end

        if (component.extended.position > (end_pos + 1)) then
            component.extended.start_position = (component.extended.start_position or 1) + 1
        end

        component.surface_id = nil
        component.extended.surface_id = nil

        __component_get_visible_text(component, false, false)

    end
        
    function __component_click_update_caret(component, event)
        if (component == nil or component.extended == nil) then
            return
        end

        local visible_substring = component.extended.substring or ""
        local font = component.extended.font
        local font_size = component.extended.size
        local area_x = component.translated_area.x
        local click_x = event.x

        if (component.absolute_x) then
            area_x = component.translated_area.x + component.absolute_x
        end

        local local_x = click_x - area_x
        if (local_x < 0) then
            local_x = 0
        end

        local cumulative_width = 0
        local caret_offset = 0
        local found_position = false

        for i = 1, #visible_substring do
            local char = string.sub(visible_substring, i, i)
            local char_info = SDL_Textarea({ font = font, size = font_size, text = char })
            cumulative_width = cumulative_width + char_info.width

            if (local_x < cumulative_width) then
                caret_offset = i - 1
                found_position = true
                break
            end
        end

        if (not found_position) then
            caret_offset = #visible_substring
        end

        component.extended.position = (component.extended.start_position or 1) + caret_offset
    end

    function insert_char(component, ch)

        component.extended = component.extended or {}

        local text = component.extended.text or ""
        local pos = component.extended.position or 0

        local before = string.sub(text, 1, pos)
        local after  = string.sub(text, pos + 1)

        component.extended.text = (before .. ch .. after)
        component.extended.position = (pos + 1)

        component.surface_id = nil
        component.extended.surface_id = nil

        __component_get_visible_text(component, false, true)

    end

    function delete_char(component, key)

        component.extended = component.extended or {}

        local text = component.extended.text or ""
        local pos = component.extended.position or 0
        local text_len = #text

        if (key == SDLK_BACKSPACE) then
            if (pos <= 0) then
                return
            end

            local before = string.sub(text, 1, pos - 1)
            local after  = string.sub(text, pos + 1)

            component.extended.text = (before .. after)
            component.extended.position = (pos - 1)
        elseif (key == SDLK_DELETE) then
            if (pos >= text_len) then
                return
            end
            local before = string.sub(text, 1, pos)
            local after  = string.sub(text, pos + 2)

            component.extended.text = (before .. after)
        else
            return
        end

        component.surface_id = nil
        component.extended.surface_id = nil

        __component_get_visible_text(component, false, false)
    end

    function __component_render_caret(component, clip_area)

        if (component == nil or component.extended == nil) then
            return
        end

        local full_text = component.extended.text or ""
        local visible_substring = component.extended.substring or ""
        local caret_position = component.extended.position or 0
        local start_position = component.extended.start_position or 1
        local font = component.extended.font
        local font_size = component.extended.size
        local area_x = component.translated_area.x

        local prefix_count = (caret_position - start_position)
        if (prefix_count < 0) then
            prefix_count = 0
        end
        if (prefix_count > #visible_substring) then
            prefix_count = #visible_substring
        end

        local prefix_text = ""
        if (prefix_count > 0) then
            prefix_text = string.sub(visible_substring, 1, prefix_count)
        end

        local prefix_info = SDL_Textarea({
            font = font,
            size = font_size,
            text = prefix_text
        })

        local caret_x = area_x + prefix_info.width

        local first_glyph_info = SDL_Textarea({
            font = font,
            size = font_size,
            text = string.sub(visible_substring, 1, 1)
        })

        -- component.extended.glyph_info = first_glyph_info
        caret_x = caret_x - (first_glyph_info.width + 2)

        component.extended.caret.x = component.extended.caret.x
        component.extended.caret.width = Window.input_caret.width
        component.extended.caret.height = font_size

        local caret_surface = {
            id = component.surface_id .. "__caret__",
            x = component.extended.caret.x + (clip_area.x - (first_glyph_info.width - 2)),
            y = component.extended.caret.y,
            width = component.extended.caret.width,
            height = component.extended.caret.height,
            red = 255,
            green = 255,
            blue = 255,
            alpha = 255
        }

        Window.input_caret.surface_id = caret_surface.id

        print("CARET : " .. component.extended.caret.x .. ", " .. component.extended.caret.y)

        local SDL_Error = SDL_Surface(caret_surface)

        if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
            return Window:set_error(SDL_Error)
        end

        SDL_Fill(caret_surface)

        SDL_Error = SDL_Texture(caret_surface)

        if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
            return Window:set_error(SDL_Error)
        end

        SDL_Render(caret_surface.id)

    end


    function __component_surface_input(component)

        local absolute_x = component.absolute_x or 0
        local absolute_y = component.absolute_y or 0

        local parent_id = component.parent_id or ""

        if (parent_id ~= "") then
            parent_id = parent_id .. "."
        end

        local display_text = nil
        local surface_id = parent_id .. component.id .. "__font__"

        if (component.extended.start_position ~= nil and component.extended.start_position == 1) then
            display_text = __component_get_visible_text(component, true, false)
        else
            display_text = __component_get_visible_text(component, false, false)
        end

        component.extended.surface_id = surface_id

        local clip_area = {
            x           = (absolute_x + component.translated_area.x),
            y           = (absolute_y + component.translated_area.y),
            width       = component.translated_area.width,
            height      = component.translated_area.height 
        }

        local text_area = SDL_Textarea({
            font        = component.extended.font,
            size        = component.extended.size,
            text        = component.extended.text
        })

        local text_top = math.floor((component.translated_area.height - text_area.height) / 2)

        component.extended.caret.y = clip_area.y + text_top

        SDL_Error = SDL_Text({
            id          = surface_id,
            font        = component.extended.font,
            size        = component.extended.size,
            text        = display_text,
            x           = clip_area.x,
            y           = (clip_area.y + text_top),
            width       = 0,
            height      = 0,
            red         = component.foreground.red,
            green       = component.foreground.green,
            blue        = component.foreground.blue,
            alpha       = component.foreground.alpha
        })

        __component_render_caret(component, clip_area)

    end


    local function __component_surface(component)

        local window_info = SDL_Windowinfo()

        if (type(component.area.width) == "number" and component.area.width <= 0) then
            component.area.width = window_info.width
        end

        if (type(component.area.height) == "number" and component.area.height <= 0) then
            component.area.height = window_info.height
        end

        SDL_Error = __component_surface_border(component)
        
        if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
            return SDL_Error
        end
        
        SDL_Error = __component_surface_face(component)

        if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
            return SDL_Error
        end

        SDL_Error = SDL_Texture({
            id = component.surface_id,
            x = (component.absolute_x + component.translated_area.x),
            y = (component.absolute_y + component.translated_area.y),
            width = component.translated_area.width,
            height = component.translated_area.height
        })

        if (component.type == Components.UI_TYPE_BUTTON) then
            SDL_Error = __component_surface_label(component)

            if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
                return SDL_Error
            end
        end

        print("Component " .. component.id .. " type = " .. component.type)

        if (component.type == Components.UI_TYPE_INPUT) then
            SDL_Error = __component_surface_input(component)

            if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
                return SDL_Error
            end
        end

        return SDL_Error

    end



-------------------------------------------------------------------------------
--  Window:new()
--
    function Window:new()

        local self = setmetatable({}, Window)

        self.id = Window.id
        self.timeslice = 1
        self.init_flags = Window.init_flags

        self.initialised = false
        self.fullscreen = Window.fullscreen

        self.display = nil
        self.cursor = Window.cursor

        self.title = Window.title
        self.width = Window.width
        self.height = Window.height
        self.flags = Window.flags

        self.err_msg = nil

        self.components = Components.new()

        return self

    end


-------------------------------------------------------------------------------
--  Window:set_error()
--
    function Window:set_error(err_msg)

        self.err_msg = err_msg or "OK"
        return nil

    end


-------------------------------------------------------------------------------
--  Window:is_error()
--
    function Window:is_error()

        return self.err_msg and self.err_msg ~= "OK"

    end


-------------------------------------------------------------------------------
--  Window:init()
--
    function Window:initialise(fullscreen)

        if (self.initialised) then
            return self:set_error("Window.init(): SDLua already initialised")
        end

        if (type(fullscreen) ~= "boolean") then
            fullscreen = false
        end

        self.fullscreen = fullscreen

        if (fullscreen) then
            self.flags = (self.flags | SDL_WINDOW_FULLSCREEN)
        end

        SDL_Error = SDL_Init(
            self.init_flags,
            {
                title = self.title,
                width = self.width,
                height = self.height,
                flags = self.flags
            }
        )

        self.display = SDL_Info()
        self.initialised = true

        if (self.cursor) then
            SDL_Error = SDL_Setcursor(self.cursor)

            if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
                return self:set_error(
                    string.format("Window:initialise(): %s", SDL_Error)
                )
            end
        end

        SDL_Drawcolor(self.color)

        if (SDL_Error ~= "OK") then
            return self:set_error("Window.init(): " .. SDL_Error)
        end

        return self

    end


-------------------------------------------------------------------------------
--  Window:quit()
--
    function Window:quit()

        if (not self.initialised) then
            return self:set_error("Window.quit(): SDLua is not initialised")
        end

        SDL_Quit()
        self.initialised = false

        if (self.err_msg ~= "OK" and self.err_msg ~= nil) then
            print(self.err_msg)
            os.exit(1)
        end

    end


-------------------------------------------------------------------------------
--  Window:component()
--
    function Window:component(id)

        if (id == nil) then
            return self.components
        end

        local tokens = modHelpers.split(id, ".")
        local current = self.components[tokens[1]]

        if (not current) then
            return self:set_error("Window:component(): Component " .. tokens[1] .. " not found")
        end

        for i = 2, #tokens do
            local key = tokens[i]
            
            if (not current.components or not current.components[key]) then
                return self:set_error("Window:component(): Component " .. table.concat(tokens, ".", 1, i) .. " not found")
            end

            current = current.components[key]
        end

        return current
        
    end


-------------------------------------------------------------------------------
--  Window:new_component()
--
    function Window:new_component(parent_id, id, type)

        if (not id) then
            return self:set_error("Window:new_component(): Missing component id")
        end

        if (not self.components) then
            self.components = {}
        end

        if (not parent_id )then
            if (self.components[id]) then
                return self:set_error("Window:new_component(): Root component '" .. id .. "' already exists")
            end

            print(string.format("Creating %s component %s", type, id))

            local root = Component:new(nil, id, type)
            self.components[id] = root

            return root
        end

        local parent = self:component(parent_id)

        if (not parent or self:is_error()) then
            return nil
        end

        if (parent.components and parent.components[id]) then
            return self:set_error("Window:new_component(): Component '" .. id .. "' already exists in '" .. parent_id .. "'")
        end

        print(string.format("Creating %s component %s", type, id))
        local new_component = Component:new(parent_id, id, type)

        if (not parent.components) then
            parent.components = {}
        end

        parent.components[id] = new_component

        return new_component

    end


-------------------------------------------------------------------------------
--  Window:parent_component()
--
    function Window:parent_component(id)

        if (not id) then
            return nil
        end

        local tokens = modHelpers.split(id, ".")

        if (#tokens <= 1) then
            return nil
        end

        table.remove(tokens)

        local parent_id = table.concat(tokens, ".")

        return self:component(parent_id)

    end



-------------------------------------------------------------------------------
--  Window:render()
--
    function Window:render(id, propagate)
        
        local component = self:component(id, nil, nil)

        if (self:is_error()) then
            return nil
        end

        if (component.visible == false) then
            return "OK"
        end

        if (component.surface_id == nil) then
            if (component.parent_id == nil) then
                component.surface_id = id
            else
                local parent = self:component(component.parent_id)
                
                component.absolute_x = parent.translated_area.x + parent.absolute_x
                component.absolute_y = parent.translated_area.y + parent.absolute_y

                local split_id = modHelpers.split(id, ".");

                component.surface_id = component.parent_id .. "." .. split_id[#split_id]
            end

            SDL_Error = __component_surface(component)

            if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
                return self:set_error(
                    string.format("Window:render(): %s", SDL_Error)
                )
            end
        end

        SDL_Render(component.surface_id)

        if (component.type == Components.UI_TYPE_BUTTON) then
            if (component.extended and component.extended.surface_id) then
                SDL_Render(component.extended.surface_id)
            end
        end
        if (component.type == Components.UI_TYPE_INPUT) then
            if (component.extended and component.extended.surface_id) then
                SDL_Render(component.extended.surface_id)
            end
        end

        if (propagate and component.components) then
            for _, components in pairs(component.components) do
                SDL_Error = self:render(id .. "." .. components.id, propagate)

                if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
                    return self:set_error(
                        string.format("Window:render(): %s", SDL_Error)
                    )
                end
            end
        end

        if (Window.focused_component and Window.focused_component.id == component.id) then
            if (component.type == Components.UI_TYPE_INPUT) then
                -- __component_render_caret(component)
                SDL_Render(Window.input_caret.surface_id)
            end
        end

        return "OK"

    end


-------------------------------------------------------------------------------
--  Window:render_all()
--
    function Window:render_all()
        
        for id, components in pairs(self.components) do
            if (id == "components") then
                goto continue
            end

            SDL_Error = self:render(id, true)

            if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
                return self:set_error(
                    string.format("Window:render(): %s", SDL_Error)
                )
            end

            ::continue::
        end

        return "OK"

    end


-------------------------------------------------------------------------------
--  Window:refresh()
--
    function Window:refresh(component_ref)

        local component = component_ref

        if (type(component_ref) == "string") then
            component = self:component(component_ref)

            if (component == nil) then
                return self:set_error(
                    string.format("Window:refresh(): Component \"%s\" not found", component_ref)
                )
            end
        end

        local id = component.id

        if (component.parent_id) then
            id = component.parent_id .. "." .. id
        end

        if (component.extended) then
            if (component.extended.surface_id) then
                print("Deleting extended surface: " .. component.extended.surface_id)
                SDL_Destroy(component.extended.surface_id)
                component.extended.surface_id = nil
            end
        end
            
        print("Deleting primary surface: " .. id)

        SDL_Destroy(id)
        component.surface_id = nil

        -- if (Window.focused_component and window.focused_component.id == component.id) then
        --     Window.extended.caret.y = component.
        --     __component_render_caret(component)
        -- end

        return "OK"

    end


    return Window
