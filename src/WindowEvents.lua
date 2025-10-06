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

-- Map SDL keycodes to lowercase characters
    local key_map = {
        [SDLK_A] = "a",
        [SDLK_B] = "b",
        [SDLK_C] = "c",
        [SDLK_D] = "d",
        [SDLK_E] = "e",
        [SDLK_F] = "f",
        [SDLK_G] = "g",
        [SDLK_H] = "h",
        [SDLK_I] = "i",
        [SDLK_J] = "j",
        [SDLK_K] = "k",
        [SDLK_L] = "l",
        [SDLK_M] = "m",
        [SDLK_N] = "n",
        [SDLK_O] = "o",
        [SDLK_P] = "p",
        [SDLK_Q] = "q",
        [SDLK_R] = "r",
        [SDLK_S] = "s",
        [SDLK_T] = "t",
        [SDLK_U] = "u",
        [SDLK_V] = "v",
        [SDLK_W] = "w",
        [SDLK_X] = "x",
        [SDLK_Y] = "y",
        [SDLK_Z] = "z",
        [SDLK_0] = "0",
        [SDLK_1] = "1",
        [SDLK_2] = "2",
        [SDLK_3] = "3",
        [SDLK_4] = "4",
        [SDLK_5] = "5",
        [SDLK_6] = "6",
        [SDLK_7] = "7",
        [SDLK_8] = "8",
        [SDLK_9] = "9",
        [SDLK_SPACE] = " ",
        [SDLK_COMMA] = ",",
        [SDLK_PERIOD] = ".",
        [SDLK_MINUS] = "-",
        [SDLK_EQUALS] = "=",
        [SDLK_SEMICOLON] = ";",
        [SDLK_APOSTROPHE] = "'",
        [SDLK_SLASH] = "/",
        [SDLK_BACKSLASH] = "\\",
        [SDLK_LEFTBRACKET] = "[",
        [SDLK_RIGHTBRACKET] = "]",
        [SDLK_GRAVE] = "`"
    }

    -- Shift mappings for characters that change with Shift
    local shift_map = {
        ["a"] = "A", ["b"] = "B", ["c"] = "C", ["d"] = "D", ["e"] = "E",
        ["f"] = "F", ["g"] = "G", ["h"] = "H", ["i"] = "I", ["j"] = "J",
        ["k"] = "K", ["l"] = "L", ["m"] = "M", ["n"] = "N", ["o"] = "O",
        ["p"] = "P", ["q"] = "Q", ["r"] = "R", ["s"] = "S", ["t"] = "T",
        ["u"] = "U", ["v"] = "V", ["w"] = "W", ["x"] = "X", ["y"] = "Y",
        ["z"] = "Z",
        ["1"] = "!", ["2"] = "@", ["3"] = "#", ["4"] = "$", ["5"] = "%",
        ["6"] = "^", ["7"] = "&", ["8"] = "*", ["9"] = "(", ["0"] = ")",
        ["-"] = "_", ["="] = "+", ["["] = "{", ["]"] = "}", [";"] = ":",
        ["'"] = "\"", ["\\"] = "|", [","] = "<", ["."] = ">", ["/"] = "?",
        ["`"] = "~"
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

                if (event.key == SDLK_LEFT) then
                    move_caret_left(component)
                elseif (event.key == SDLK_RIGHT) then
                    move_caret_right(component)
                elseif (event.key == SDLK_BACKSPACE or event.key == SDLK_DELETE) then
                    delete_char(component, event.key)
                else
                    local mapped_char = key_map[event.key]

                    if (mapped_char ~= nil) then
                        if (key_state[SDLK_LSHIFT] or key_state[SDLK_RSHIFT]) then
                            mapped_char = shift_map[mapped_char] or mapped_char
                        end

                        insert_char(component, mapped_char)

                        component.surface_id = nil
                        component.extended.surface_id = nil
                    end
                end

                component.extended.surface_id = nil
                component.surface_id = nil
            end
        end)

        
        SDL_Event("keyup", function(event)
            
            key_state[event.key] = false

            if (not Window.focused_component or Window.focused_component.type ~= Window.UI_TYPE_TEXT) then
                -- return
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
                else
                    Window.focused_component = nil
                end
                else
                    Window.focused_component = nil
            end

        end)

        SDL_Event("mouseup", function(event)
       
            mouse_state[event.button] = false

        end)

    end


    modWindowEvents.mouse_state = mouse_state
    modWindowEvents.key_state = key_state


    return modWindowEvents
