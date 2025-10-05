-------------------------------------------------------------------------------
--  sdlui/src/WindowEvents.lua
--

    modWindowEvents = {}


--  SDL3 indexes buttons as:
--
--      1       - Left mouse button
--      2       - Middle button/scroll wheel
--      3       - Right mouse button
--
--  So we can check if a button is pressed like:
--
--      if (mouse_state[1]) then
--          ...
--      end
--
    local mouse_state = {
        false,
        false,
        false
    }


    local key_state = {}

    function __find_active_component(event, component)
        local absolute_x = component.translated_area.x + component.absolute_x
        local absolute_y = component.translated_area.y + component.absolute_y

        if (event.x < absolute_x or event.x >= (absolute_x + component.translated_area.width)) then
            return nil
        end

        if (event.y < absolute_y or event.y >= (absolute_y + component.translated_area.height)) then
            return nil
        end

        if (not component.visible) then
            return nil
        end

        if (component.components) then
            for id, child in pairs(component.components) do
                local found = __find_active_component(event, child)
                if (found) then
                    component.hover = false
                    SDL_Setcursor(component.cursor)
                    return found
                end
            end
        end

        return component
    end


    function modWindowEvents.initialise(Window)

-------------------------------------------------------------------------------
--  Keyboard events - there's a whole bunch of SDLK_* key codes
--  that we can use, too many to list here.
--
--  Some xamples:
--
--      SDLK_A - SDLK_Z
--      SDLK_0 - SDLK_9
--      SDLK_ESCAPE
--      SDLK_LSHIFT & SDLK_RSHIFT
--      SDLK_LALT & SDLK_RALT
--      SDLK_LCTRL & SDLK_RCTRL
--      SDLK_UP, SDLK_DOWN, SDLK_LEFT & SDLK_RIGHT
--      SDLK_F1 - SDLK_F12
--
--  For a comprehensive list see the sdlua source - specifically the
--  file:
--
--      sdlua/src/sdl_lib.c
--
--  Point is, none of these will be defined in key_state until they've
--  actually been pressed, so we need to check first if a key is set at
--  all:
--
--      if (Window.events.key_state[SDLK_ESCAPE] ~= nil) then
--      -- Key SDLK_ESCAPE exists, is it true or false?
--          if (Window.events.key_state[SDLK_ESCAPE]) then
--              print("Escape key is pressed")
--          end
--      end
--
--  Before we attempt to resd the value there.
--
        SDL_Event("keydown", function(event)
    
            key_state[event.key] = true

            if (Window.focused_component.type == Components.UI_TYPE_INPUT) then
                local component = Window.focused_component
                local caret_pos = component.extended.position or 0
                local start_pos = component.extended.start_position or 0
                local end_pos = component.extended.end_position or #component.extended.text
                local text_len = #component.extended.text

                if (event.key == SDLK_LEFT) then
                    if (caret_pos > 0) then
                        caret_pos = (caret_pos - 1)
                    end

                    if (caret_pos < start_pos) then
                        if (start_pos > 0) then
                            start_pos = (start_pos - 1)
                        end
                        if (end_pos > start_pos) then
                            end_pos = (end_pos - 1)
                        end
                    end

                elseif (event.key == SDLK_RIGHT) then
                    if (caret_pos < text_len) then
                        caret_pos = (caret_pos + 1)
                    end

                    if (caret_pos > end_pos) then
                        if (end_pos < text_len) then
                            end_pos = (end_pos + 1)
                        end
                        if (start_pos < end_pos) then
                            start_pos = (start_pos + 1)
                        end
                    end
                end

                component.extended.position = caret_pos
                component.extended.start_position = start_pos
                component.extended.end_position = end_pos

                component.surface_id = nil
                component.extended.surface_id = nil
            end
        end)

        
        SDL_Event("keyup", function(event)
            
            key_state[event.key] = false

            if (not Window.focused_component or Window.focused_component.type ~= Window.UI_TYPE_TEXT) then
                
            end

        end)

        SDL_Event("mousemove", function(event)

            local new_hovered = nil

            for _, components in pairs(Window.components) do
                new_hovered = __find_active_component(event, components)
                if (new_hovered) then
                    break
                end
            end

            if (Window.hovered_component and Window.hovered_component ~= new_hovered) then
                Window.hovered_component.hover = false

                if (Window.hovered_component.callbacks and Window.hovered_component.callbacks["mouseleave"]) then
                    Window.hovered_component.callbacks["mouseleave"](Window.hovered_component, event)
                end
            end

            Window.hovered_component = new_hovered

            if (new_hovered) then
                if (not new_hovered.hover) then
                    if (new_hovered.callbacks and new_hovered.callbacks["mouseenter"]) then
                        new_hovered.callbacks["mouseenter"](new_hovered, event)
                    end
                end

                new_hovered.hover = true
                SDL_Setcursor(new_hovered.cursor)
            else
                SDL_Setcursor(Window.cursor)
            end
            
        end)


        SDL_Event("mousedown", function(event)
       
            mouse_state[event.button] = true

            local new_hovered = nil

            for _, components in pairs(Window.components) do
                new_hovered = __find_active_component(event, components)
                if (new_hovered)then
                    break
                end
            end

            Window.hovered_component = new_hovered

            if (new_hovered) then
                if (new_hovered.hover) then
                    Window.focused_component = new_hovered

                    if (new_hovered.callbacks and new_hovered.callbacks["click"]) then
                        new_hovered.callbacks["click"](new_hovered, event)
                    end

                    if (new_hovered.type == Components.UI_TYPE_INPUT) then
                        print("Set focus to " .. new_hovered.id)
                        Window.focused_component = new_hovered
                    end
                end
            end

        end)

        SDL_Event("mouseup", function(event)
       
            mouse_state[event.button] = false

        end)

    end


    modWindowEvents.mouse_state = mouse_state
    modWindowEvents.key_state = key_state


    return modWindowEvents
