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
            -- SDL_Setcursor(Window.cursor)
            return nil
        end

        if (event.y < absolute_y or event.y >= (absolute_y + component.translated_area.height)) then
            -- SDL_Setcursor(Window.cursor)
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
                component = Window.focused_component

                if (event.key == SDLK_LEFT) then
                    if (component.extended.position > component.extended.start_position) then
                        component.extended.position = (component.extended.position - 1)
                    else
                        if (component.extended.start_position > 1) then
                            component.extended.start_position = (component.extended.start_position - 1)
                        end
                        if (component.extended.position >= 1) then
                            component.extended.position = (component.extended.position - 1)
                        end
                        component.extended.end_position = (component.extended.end_position - 1)
                    end


                    component.surface_id = nil
                    component.extended.surface_id = nil
                    
                    -- print(
                    --     string.format("Shift left %s:\n\tStart: %d\n\tPosition: %d\n\tEnd: %d\n",
                    --         component.extended.substring,
                    --         component.extended.start_position,
                    --         component.extended.position,
                    --         component.extended.end_position
                    --     )
                    -- )
                elseif (event.key == SDLK_RIGHT) then
                    if (component.extended.position < component.extended.end_position) then
                        component.extended.position = (component.extended.position + 1)
                        component.extended.start_position = (component.extended.start_position + 1)
                    else
                        if (component.extended.end_position < #component.extended.text) then
                            component.extended.end_position = (component.extended.end_position + 1)

                            if (component.extended.position < #component.extended.text) then
                                component.extended.position = (component.extended.position + 1)
                            else
                                component.extended.start_position = (component.extended.start_position + 1)
                            end
                        end

                        component.surface_id = nil
                        component.extended.surface_id = nil
                    end

                        -- print(
                        --     string.format("Shift right:\n\tStart: %d\n\tPosition: %d\n\tEnd: %d\n",
                        --         component.extended.start_position,
                        --         component.extended.position,
                        --         component.extended.end_position
                        --     )
                        -- )
                end
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
