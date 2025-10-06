-------------------------------------------------------------------------------
--  sdlui/src/Components.lua
--

    local modComponents = {}

    local Components = {}
    local Component = {}


    Components.__index = Components
    Component.__index = Component


    Components.UI_TYPE_CONTAINER = "container"
    Components.UI_TYPE_BUTTON = "button"
    Components.UI_TYPE_INPUT = "input"


-------------------------------------------------------------------------------
--  Components:new()
--
    function Components:new(id)

        local self = setmetatable({}, Components)

        self.components = {}

        return self

    end


-------------------------------------------------------------------------------
--  Components:create()
--
    function Components:create(parent_id, id, type)

        if (self.components.id) then
            return "Components:create(): Component " .. id .. " already exists"
        end

        self.components.id = Component:new(parent_id, id, type)

        print(string.format("Created component %s (parent=%s)", id, parent_id))

        return self.components.id

    end


-------------------------------------------------------------------------------
--  Components:find()
--
    function Components:find(id)

        if (self.components.id) then
            return self.components.id
        end

        return nil

    end


-------------------------------------------------------------------------------
--  The Component class.
--
    function Component:new(parent_id, id, type)

        local self = setmetatable({}, Component)

        self.id = id
        self.parent_id = parent_id
        self.surface_id = nil

        self.absolute_x = 0
        self.absolute_y = 0

        self.hover = false
        self.visible = true
        self.cursor = "arrow"

        self.area = { x = 0, y = 0, width = 0, height = 0 }
        
        self.foreground = { red = 0, green = 0, blue = 0, alpha = 255 }
        self.background = { red = 255, green = 255, blue = 255, alpha = 255 }

        self.border = { weight = 2, red = 0, green = 0, blue = 0, alpha = 255 }

        self.components = {}

        self.type = type
        self.extended = nil

        self.callbacks = {}

        return self

    end


-------------------------------------------------------------------------------
--  Component:set_visibility()
--
    function Component:set_visibility(visible)

        self.visible = visible

    end


-------------------------------------------------------------------------------
--  Component:set_area()
--
    function Component:set_area(area)

        if (not area) then
            return
        end

        self.area.x = area.x or self.area.x
        self.area.y = area.y or self.area.y
        self.area.width = area.width or self.area.width
        self.area.height = area.height or self.area.height

    end


-------------------------------------------------------------------------------
--  Component:set_foreground()
--
    function Component:set_foreground(rgba)

        if (not rgba) then
            return
        end

        self.foreground.red = rgba.red or self.foreground.red
        self.foreground.green = rgba.green or self.foreground.green
        self.foreground.blue = rgba.blue or self.foreground.blue
        self.foreground.alpha = rgba.alpha or self.foreground.alpha

    end


-------------------------------------------------------------------------------
--  Component:set_background()
--
    function Component:set_background(rgba)

        if (not rgba) then
            return
        end

        self.background.red = rgba.red or self.background.red
        self.background.green = rgba.green or self.background.green
        self.background.blue = rgba.blue or self.background.blue
        self.background.alpha = rgba.alpha or self.background.alpha

    end


-------------------------------------------------------------------------------
--  Component:set_border()
--
    function Component:set_border(border)

        if (not border) then
            return
        end

        self.border.weight = border.weight or self.border.weight
        self.border.red = border.red or self.border.red
        self.border.green = border.green or self.border.green
        self.border.blue = border.blue or self.border.blue
        self.border.alpha = border.alpha or self.border.alpha

    end


-------------------------------------------------------------------------------
--  Component:set_cursor()
--
    function Component:set_cursor(cursor)

        if (not cursor) then
            return
        end

        self.cursor = cursor;

    end


-------------------------------------------------------------------------------
--  Component:set_callbacks()
--
    function Component:set_callbacks(callbacks)

        if (not callbacks) then
            return
        end

        for event_type, callback in pairs(callbacks) do

            -- print(string.format("Adding %s callback to component %s", event_type, self.id))

            self.callbacks[event_type] = callback

        end

    end


-------------------------------------------------------------------------------
--  Component:set_label()
--
    function Component:set_label(label)

        if (not label) then
            return "OK"
        end

        if (self.type ~= Components.UI_TYPE_BUTTON) then
            return "Component:set_label(): Can\'t attach label to non-button type"
        end

        if (label.font == nil) then
            return "Component:set_label(): No font specified"
        end
        if (label.size == nil) then
            return "Component:set_label(): No font size specified"
        end
        if (label.text == nil) then
            label.text = ""
        end

        if (label.x == nil) then
            label.x = "center"
        end
        if (label.y == nil) then
            label.y = "center"
        end

        if (label.color) then
            self.foreground = label.color
        end

        -- print("SET EXTENDED LABEL TEXT " .. label.text)
        self.extended = label

        return "OK"

    end


-------------------------------------------------------------------------------
--  Component:set_input()
--
    function Component:set_input(input)
    
        if (not input) then
            return
        end
        
        if (self.type ~= Components.UI_TYPE_INPUT) then
            return "Component:set_text(): Can\'t attach text to non-input type"
        end

        if (input.font == nil) then
            return "Component:set_text(): No font specified"
        end
        if (input.size == nil) then
            return "Component:set_text(): No font size specified"
        end
        if (input.text == nil) then
            input.text = ""
        end

        if (input.max == nil) then
            input.max = 0
        else
            if (#input.text > input.max) then
                input.text = string.sub(input.text, 0, input_max)
            end
        end
        
        if (input.position == nil) then
            input.position = #input.text
        end

        if (input.x == nil) then
            input.x = "center"
        end
        if (input.y == nil) then
            input.y = "center"
        end

        if (input.color) then
            self.foreground = input.color
        end

        self.extended = input

    end


-------------------------------------------------------------------------------
--  Component:set()
--
    function Component:set(values)

        local SDL_Error = "OK"

        if (not values) then
            return
        end

        if (values.visible ~= nil) then
            self:set_visibility(values.visible)
        end

        if (values.area) then
            self:set_area(values.area)
        end

        if (values.foreground) then
            self:set_foreground(values.foreground)
        end

        if (values.background) then
            self:set_background(values.background)
        end

        if (values.border) then
            self:set_border(values.border)
        end

        if (values.cursor) then
            self:set_cursor(values.cursor)
        end

        if (values.callbacks) then
            self:set_callbacks(values.callbacks)
        end

        if (values.label) then
            SDL_Error = self:set_label(values.label)
        end

        if (SDL_Error ~= "OK" and SDL_Error ~ nil) then
            return SDL_Error
        end

        if (values.input) then
            SDL_Error = self:set_input(values.input)
        end

        return SDL_Error

    end


    modComponents.Components = Components
    modComponents.Component = Component


    return modComponents
