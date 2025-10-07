-------------------------------------------------------------------------------
--  sdlui/menu.lua
--


-------------------------------------------------------------------------------
--  Create the top-level menu component - we do this by setting the
--  parent_id parameter to nil.
--
    SDLui:new_component(nil, "menu", Components.UI_TYPE_CONTAINER)

    if (SDLui:is_error()) then
        SDLui:quit()
        os.exit(1)
    end


-------------------------------------------------------------------------------
--  Create the menu option buttons and attach them to the menu.
--
    SDLui:new_component("menu", "quit", Components.UI_TYPE_BUTTON)
    SDLui:new_component("menu", "help", Components.UI_TYPE_BUTTON)

    if (SDLui:is_error()) then
        SDLui:quit()
        os.exit(1)
    end


-------------------------------------------------------------------------------
--  Define the menu.
--
    menu_visible        = true
    menu_area           = { x = "10", y = "10", width = "80", height = "50" }
    menu_foreground     = { red = 0, green = 0, blue = 0, alpha = 255 }
    menu_background     = { red = 190, green = 190, blue = 190, alpha = 255 }
    menu_border         = { weight = 2, red = 0, green = 0, blue = 0, alpha = 255 }
    menu_callbacks      = {

        mouseenter      = function(component, event)
            print("Enter on " .. component.id)
        end,

        mouseleave      = function(component, event)
            print("Leave on " .. component.id)
        end

    }


-------------------------------------------------------------------------------
--  We can call individual methods for each table:
--
--      Menu.set_visibility(menu_visibility)
--      Menu:set_area(menu_area)
--      Menu:set_foreground(menu_foreground)
--      Menu:set_background(menu_background)
--      Menu:set_border(menu_border)
--
--  Or we can bundle everything under a single table:
--
    menu_set            =
    {
        visible         = menu_visible,
        area            = menu_area,
        foreground      = menu_foreground,
        background      = menu_background,
        border          = menu_border,
        callbacks       = menu_callbacks
    }


-------------------------------------------------------------------------------
--  Then call Menu:set to set everything at once.
--
--  We could have done:
--
--      local Menu = Window:new_component(nil, "menu", "container")
--
--  But we can also lookup a component by id using the Window:component()
--  method.
--
    local Menu = SDLui:component("menu")

    if (SDLui:is_error()) then
        SDLui:quit()
        os.exit(1)
    end

    Menu:set(menu_set)


-------------------------------------------------------------------------------
--  Define the buttons.
--
    local MenuQuit = SDLui:component("menu.quit")
    local MenuHelp = SDLui:component("menu.help")


-------------------------------------------------------------------------------
--  Our buttons will all share the same attributes except for the area
--  attribute which defines the butten dimensions and placement.
--
    button_visible      = true
    button_foreground   = { red = 255, green = 255, blue = 255, alpha = 255 }
    button_background   = { red = 255, green = 0, blue = 0, alpha = 255 }
    button_border       = { weight = 2, red = 0, green = 0, blue = 0, alpha = 255 }
    button_cursor       = "hand"

    MenuQuit_area       = { x = "10", y = "15", width = "25", height = 32 }
    MenuHelp_area       = { x = "65", y = "15", width = "25", height = 32 }

    MenuQuit_label      = {
        font            = "/usr/share/fonts/TTF/Hack-Bold.ttf",
        size            = 14,
        text            = "Quit",
        x               = "center",
        y               = "center"
    }

    MenuHelp_label      = {
        font            = "/usr/share/fonts/TTF/Hack-Bold.ttf",
        size            = 14,
        text            = "Help",
        x               = "center",
        y               = "center"
    }

    button_callbacks    = {

        mouseenter      = function(component, event)

            if (component.border) then
                component.border.red = 255
                component.border.green = 255
                component.border.blue = 255
            end

            if (component.background) then
                component.background.red = 0
                component.background.green = 0
                component.background.blue = 0
            end
            
            if (component.foreground) then
                component.foreground.red = 255
                component.foreground.green = 255
                component.foreground.blue = 0
            end

            SDLui:refresh(component)
        end,

        mouseleave      = function(component, event)

            if (component.border) then
                component.border.red = 0
                component.border.green = 0
                component.border.blue = 0
            end

            if (component.background) then
                component.background.red = 255
                component.background.green = 0
                component.background.blue = 0
            end
            
            if (component.foreground) then
                component.foreground.red = 255
                component.foreground.green = 255
                component.foreground.blue = 255
            end

            SDLui:refresh(component)
        end,

        click           = function(component, event)
            print("Click on " .. component.id)

            if (component.id == 'quit') then
                SDLui.initialised = false
            end
        end

    }

    local SDL_Error = MenuQuit:set({
        visible         = button_visible,
        foreground      = button_foreground,
        background      = button_background,
        border          = button_border,
        area            = MenuQuit_area,
        label           = MenuQuit_label,
        cursor          = button_cursor,
        callbacks       = button_callbacks
    })

    if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
        SDLui:set_error(SDL_Error)
        SDLui:quit()
        os.exit(1)
    end

    SDL_Error = MenuHelp:set({
        visible         = button_visible,
        foreground      = button_foreground,
        background      = button_background,
        border          = button_border,
        area            = MenuHelp_area,
        label           = MenuHelp_label,
        cursor          = button_cursor,
        callbacks       = button_callbacks
    })

    if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
        SDLui:set_error(SDL_Error)
        SDLui:quit()
        os.exit(1)
    end

    if (SDLui:is_error()) then
        SDLui:quit()
        os.exit(1)
    end


    input_visible       = true
    input_foreground    = { red = 255, green = 255, blue = 255, alpha = 255 }
    input_background    = { red = 0, green = 0, blue = 180, alpha = 255 }
    input_border        = { weight = 2, red = 255, green = 255, blue = 255, alpha = 255 }
    input_cursor        = "hand"

    input_area          = { x = "10", y = "50", width = "80", height = 32 }
    input2_area          = { x = "10", y = "70", width = "80", height = 32 }
    input_cursor        = "ibeam"
    
    input_text          = {
        font = "/usr/share/fonts/TTF/Hack-Regular.ttf",
        size = 18,
        text = "Just a random string of text to display in the text input box, lot of junk/nonsense for testing purposes"
    }
    input2_text          = {
        font = "/usr/share/fonts/TTF/Hack-Regular.ttf",
        size = 24,
        text = "Loo, ma - a bigger font! M...mawr-mawr?!"
    }

    input_callbacks     = {
        mouseenter      = function(component, event)

            SDL_Setcursor("ibeam")

        end,
        mouseleave      = function(component, event)

            SDL_Setcursor("default")

        end
    }

    local TextBox = SDLui:new_component("menu", "textbox", Components.UI_TYPE_INPUT)
    local TextBox2 = SDLui:new_component("menu", "textbox2", Components.UI_TYPE_INPUT)

    if (SDLui:is_error()) then
        SDLui:quit()
        os.exit(1)
    end

    SDL_Error = TextBox:set({
        visible         = true,
        foreground      = input_foreground,
        background      = input_background,
        border          = input_border,
        cursor          = input_cursor,
        area            = input_area,
        input           = input_text
    })

    SDL_Error = TextBox2:set({
        visible         = true,
        foreground      = input_foreground,
        background      = input_background,
        border          = input_border,
        cursor          = input_cursor,
        area            = input2_area,
        input           = input2_text
    })

    if (SDL_Error ~= "OK" and SDL_Error ~= nil) then
        SDLui:set_error(SDL_Error)
        SDLui:quit()
        os.exit(1)
    end

    if (SDLui:is_error()) then
        SDLui:quit()
        os.exit(1)
    end

    SDL_Setcursor("hand")

    return Menu
