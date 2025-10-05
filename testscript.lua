#!/usr/bin/env sdlua

SDL_Init(SDL_INIT_VIDEO, {
    title = "Clip Test",
    width = 640,
    height = 480,
    flags = 0
})

local font = "/usr/share/fonts/TTF/Hack-Regular.ttf"
local size = 24
local long_text = "This is a long line of text to test clipping behavior in sdlua."

local input = { x = 100, y = 200, width = 300, height = 50 }

local running = true
SDL_Event("keydown", function(ev)
    if ev.key == SDLK_Q or ev.key == SDLK_ESCAPE then
        running = false
    end
end)

while running do
    SDL_Clear()

    -- Draw the textbox rectangle before clip
    SDL_Rectangle({
        x = input.x,
        y = input.y,
        width = input.width,
        height = input.height,
        red = 30, green = 60, blue = 90, alpha = 255
    })

    -- Set clip
    SDL_Cliprect({ x = input.x, y = input.y, width = input.width, height = input.height })
    print(string.format(">>> Enabling clip @ x=%d,y=%d,w=%d,h=%d",
        input.x, input.y, input.width, input.height))

    -- Measure text
    local info = SDL_Textarea({ font = font, size = size, text = long_text })
    print("text_info:", info and info.width, info and info.height)

    -- Compute vertical centering
    local ty = input.y + math.floor((input.height - (info and info.height or 0)) / 2)

    -- Use explicit id
    local text_id = "cliptest"
    local err = SDL_Text({
        id = text_id,
        font = font,
        size = size,
        text = long_text,
        x = input.x,
        y = ty,
        width = 0,
        height = 0,
        red = 255, green = 255, blue = 255, alpha = 255
    })
    if err and err ~= "OK" then
        print("SDL_Text error:", err)
    end

    print("Rendering text entity:", text_id)
    SDL_Render(text_id)

    -- Test rectangle under clip (overflow test)
    SDL_Rectangle({
        x = input.x - 50,
        y = input.y - 20,
        width = input.width + 100,
        height = input.height + 40,
        red = 255, green = 0, blue = 0, alpha = 100
    })

    -- Clear clip
    SDL_Cliprect()
    print(">>> Disabling clip")

    SDL_Present()
    SDL_Poll()
    SDL_Delay(16)
end

SDL_Quit()
