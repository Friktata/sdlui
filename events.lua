-------------------------------------------------------------------------------
--  sdlui/events.lua
--

    local modEvents = {}


    function modEvents.initialise(Window)

        SDL_Event("quit", function()
            Window.initialised = false
        end)

        -- SDL_Event("keyup", function(event)
        --     if (event.key == SDLK_Q or event.char == 'q') then
        --         Window.initialised = false
        --     end
        -- end)

    end


    return modEvents
