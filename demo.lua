#!/usr/bin/env sdlua

    package.path = package.path .. ";./src/?.lua"


    local modEvents = require("events")


-------------------------------------------------------------------------------
--  sdlui/demo.lua
--

    SDLui = require("src.SDLui")


    SDLui:initialise(false)


    local Menu = require("menu")


    SDLui.events.initialise(SDLui)

    modEvents.initialise(SDLui)


    gs = {
        id = "gs",
        x = 0,
        y = 0,
        width = 100,
        height = 100,
        top_left = { red = 255, green = 0, blue = 255, alpha = 255 },
        top_right = { red = 0, green = 255, blue = 0, alpha = 255 },
        bottom_left = { red = 0, green = 0, blue = 0, alpha = 255 },
        bottom_right = { red = 255, green = 255, blue = 255, alpha = 255 },
        direction = "vertical"
    }
    
    SDL_Error = SDL_Surface(gs)
    if (SDL_Error ~= "OK") then
        print(SDL_Error)
        SDLui:set_error(SDL_Error)
        SDLui.initialised = false
    end

    SDL_Error = SDL_Quadgradient(gs)
    if (SDL_Error ~= "OK") then
        print(SDL_Error)
        SDLui:set_error(SDL_Error)
        SDLui.initialised = false
    end

    SDL_Error = SDL_Drawline({
        id = "gs",
        start_x = 0,
        start_y = 0,
        end_x = 99,
        end_y = 99,
        red = 200,
        green = 32,
        blue = 240,
        alpha = 255,
        weight = 5
    })

    SDL_Error = SDL_Texture(gs)
    if (SDL_Error ~= "OK") then
        print(SDL_Error)
        SDLui:set_error(SDL_Error)
        SDLui.initialised = false
    end

    SDL_Render(gs.id)

    while (SDLui.initialised) do

        SDL_Clear()
        
        SDL_Error = SDLui:render_all()

        if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
            SDLui:set_error(SDL_Error)
            SDLui.initialised = false
        end

        if (SDLui:is_error()) then
            break
        end

        SDL_Render("gs")

        SDL_Poll()

        SDL_Delay(SDLui.timeslice)

        if (SDLui.events.key_state[SDLK_Q] ~= nil) then
            if (not SDLui.focused_component or SDLui.focused_component.type ~= Components.UI_TYPE_INPUT) then
                if (SDLui.events.key_state[SDLK_Q]) then
                    SDLui.initialised = false
                end
            end
        end
        
        SDL_Present()

    end


    ::cleanup::


    SDLui:quit()
