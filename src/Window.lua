-------------------------------------------------------------------------------
--  SDLui/src/Window.lua
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
        
    function __component_get_visible_text(component, start)

        local full_text = (component.extended.text or "")
        local area_width = component.translated_area.width
        local font = component.extended.font
        local font_size = component.extended.size
        local text_length = #full_text

        local caret_position = (component.extended.position or 0)
        if (caret_position < 0) then
            caret_position = 0
        end
        if (caret_position > (text_length + 1)) then
            caret_position = (text_length + 1)
        end

        local full_text_info = SDL_Textarea({
            font = font,
            size = font_size,
            text = full_text
        })

        if (full_text_info.width <= area_width) then
            component.extended.start_position = 0
            component.extended.end_position = text_length
            component.extended.substring = full_text

            local prefix_text = string.sub(full_text, 1, (caret_position - 1))
            local prefix_info = SDL_Textarea({
                font = font,
                size = font_size,
                text = prefix_text
            })

            component.extended.caret = {
                x = (component.area.x + prefix_info.width),
                width = Window.input_caret.width,
                height = font_size
            }

            return full_text
        end

        local function compute_window_end_from_start(start_index)
            local substring = ""
            local window_end_index = (start_index - 1)
            for current_index = start_index, text_length, 1 do
                substring = substring .. string.sub(full_text, current_index, current_index)
                local trial_info = SDL_Textarea({
                    font = font,
                    size = font_size,
                    text = substring
                })
                if (trial_info.width > area_width) then
                    break
                end
                window_end_index = current_index
            end
            if (window_end_index >= start_index) then
                return window_end_index, string.sub(full_text, math.max(start_index, 1), window_end_index)
            else
                return (start_index - 1), ""
            end
        end

        local window_start_index, window_end_index, visible_substring = 1, 0, ""

        if (start) then
            window_start_index = component.extended.start_position or 1
            if (window_start_index < 1) then
                window_start_index = 1
            end
            if (window_start_index > text_length) then
                window_start_index = text_length
            end
            window_end_index, visible_substring = compute_window_end_from_start(window_start_index)
        else
            window_end_index = component.extended.end_position or text_length
            if (window_end_index < 1) then
                window_end_index = 1
            end
            if (window_end_index > text_length) then
                window_end_index = text_length
            end

            local tmp_substring = ""
            local candidate_start_index = (window_end_index + 1)
            for i = window_end_index, 1, -1 do
                tmp_substring = string.sub(full_text, i, i) .. tmp_substring
                local trial_info = SDL_Textarea({
                    font = font,
                    size = font_size,
                    text = tmp_substring
                })
                if (trial_info.width > area_width) then
                    break
                end
                candidate_start_index = i
            end
            window_start_index = candidate_start_index
            if (window_start_index <= window_end_index) then
                visible_substring = string.sub(full_text, window_start_index, window_end_index)
            else
                visible_substring = ""
            end
        end

        while ((caret_position < window_start_index) and (window_start_index > 0)) do
            window_start_index = (window_start_index - 1)
            if (window_start_index < 0) then
                window_start_index = 0
            end
            window_end_index, visible_substring = compute_window_end_from_start(math.max(window_start_index, 1))
            if (window_end_index < math.max(window_start_index, 1)) then
                break
            end
            if ((caret_position >= window_start_index) and (caret_position <= (window_end_index + 1))) then
                break
            end
        end

        while ((caret_position > (window_end_index + 1)) and (window_end_index < text_length)) do
            window_start_index = (window_start_index + 1)
            if (window_start_index > text_length) then
                window_start_index = text_length
            end
            window_end_index, visible_substring = compute_window_end_from_start(window_start_index)
            if (window_end_index < window_start_index) then
                break
            end
        end

        if ((caret_position < window_start_index) or (caret_position > (window_end_index + 1))) then
            window_start_index = caret_position
            if (window_start_index < 0) then
                window_start_index = 0
            end
            if (window_start_index > text_length) then
                window_start_index = text_length
            end
            window_end_index, visible_substring = compute_window_end_from_start(math.max(window_start_index, 1))
            if (window_end_index < window_start_index) then
                if (window_start_index <= text_length) then
                    window_end_index = window_start_index
                    visible_substring = string.sub(full_text, math.max(window_start_index, 1), window_end_index)
                else
                    visible_substring = ""
                end
            end
        end

        component.extended.start_position = window_start_index
        component.extended.end_position = window_end_index
        component.extended.substring = visible_substring

        local prefix_count = (caret_position - window_start_index)
        if (prefix_count < 0) then
            prefix_count = 0
        end
        if (prefix_count > #visible_substring) then
            prefix_count = #visible_substring
        end

        local caret_x = component.area.x
        local prefix_text = ""
        if (prefix_count > 0) then
            prefix_text = string.sub(visible_substring, 1, prefix_count)
        end
        local prefix_info = SDL_Textarea({
            font = font,
            size = font_size,
            text = prefix_text
        })

        if (caret_position > 0) then
            caret_x = component.area.x + prefix_info.width
        else
            caret_x = component.area.x + prefix_info.width - 8
        end

        component.extended.caret = {
            x = caret_x,
            width = Window.input_caret.width,
            height = font_size
        }

        return visible_substring
    end

    function __component_enable_caret(component, clip_area)

        local caret_surface = {
            id = component.surface_id .. "__caret__",
            x = component.extended.caret.x + clip_area.x,
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


    function __component_render_caret(component, clip_area)

        -- if (Window.input_caret.ticks < (Window.input_caret.blink / 2)) then
            __component_enable_caret(component, clip_area)
        -- else
        --     __component_enable_caret(component)
        -- end

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
            display_text = __component_get_visible_text(component, true)
        else
            display_text = __component_get_visible_text(component, false)
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
