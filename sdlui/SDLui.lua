-------------------------------------------------------------------------------
--  sdlui/SDLui.lua
--

-------------------------------------------------------------------------------
--

    local SDLua = {}

    local SDLua_Window = require("core.Window")
    local SDLua_Events = require("core.WindowEvents")

    local SDLua_Components = require("core.Components")

    Component = SDLua_Components.Component
    Components = SDLua_Components.Components

    SDLua_Window.events = SDLua_Events
    SDLua_Window.Component = Component
    SDLua_Window.Components = components
    
    SDLua = SDLua_Window

    return SDLua
