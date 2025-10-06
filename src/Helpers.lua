-------------------------------------------------------------------------------
--  sdlui/src/Helpers.lua
--

    local modHelpers = {}


-------------------------------------------------------------------------------
--  split()
--
    function modHelpers.split(src, delim)
        local result = {}

        delim = delim:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")

        for match in src:gmatch("([^" .. delim .. "]+)") do
            table.insert(result, match)
        end

        return result
    end


-------------------------------------------------------------------------------
--  translate_area()
--
    function modHelpers.translate_area(component)

        if (
            type(component.area.x) ~= "string" and
            type(component.area.y) ~= "string" and
            type(component.area.height) ~= "string" and
            type(component.area.width) ~= "string"
        ) then
            return component.area
        end

        local window_area = SDL_Windowinfo()

        local parent_width = window_area.width
        local parent_height = window_area.height

        local parent = nil

        if (component.parent_id ~= nil) then
            parent = SDLui:component(component.parent_id)

            if (type(parent) == "string" or parent == nil) then
                return SDLui:set_error(
                    string.format("translate_area(): %s", parent_id)
                )
            end

            parent_width = parent.translated_area.width
            parent_height = parent.translated_area.height
        end

        local translated_area = {
            x = component.area.x,
            y = component.area.y,
            width = component.area.width,
            height = component.area.height
        }

        if (type(translated_area.x) == "string") then
            local x = tonumber(translated_area.x)
            translated_area.x = math.floor((parent_width / 100) * x)
        end
        if (type(translated_area.y) == "string") then
            local y = tonumber(translated_area.y)
            translated_area.y = math.floor((parent_height / 100) * y)
        end
        if (type(translated_area.width) == "string") then
            local width = tonumber(translated_area.width)
            translated_area.width = math.floor((parent_width / 100) * width)
        end
        if (type(translated_area.height) == "string") then
            local height = tonumber(translated_area.height)
            translated_area.height = math.floor((parent_height / 100) * height)
        end

        return translated_area

    end


    return modHelpers
