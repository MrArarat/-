function love.conf(t)
    t.window.title = "ПРОЕКТ «ФЕВРАЛЬ»"   -- заголовок окна
    t.window.width = 800          -- ширина
    t.window.height = 600         -- высота
    t.window.resizable = false    -- можно ли менять размер
    t.window.fullscreen = false   -- полноэкранный режим
    t.window.vsync = 1            -- вертикальная синхронизация (0/1)
    t.window.msaa = 0             -- сглаживание (0, 2, 4, 8, 16)
    t.window.borderless = true   -- рамка
    t.window.icon = nil           -- путь к иконке
end