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

        SDL_Poll()

        SDL_Delay(SDLui.timeslice)

        if (SDLui.events.key_state[SDLK_Q] ~= nil) then
            if (SDLui.events.key_state[SDLK_Q]) then
                SDLui.initialised = false
            end
        end

        SDL_Present()

    end


    ::cleanup::


    SDLui:quit()
