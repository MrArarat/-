local menu     = require("main-menu")
local Timer    = require("helpers.timer")
local mmaker   = require("helpers.menumaker")
local Chapters = require("helpers.chapters")


function love.load()
  menu.load()
  Chapters.scan()
end


function love.update(dt)
  if mmaker.isActive then
    mmaker.update(dt)
    return
  end

  if Chapters.current then
    if Chapters.current.update then Chapters.current.update(dt) end
    return
  end

  Timer.update(dt)
  menu.update(dt)
end

function love.draw()
  if Chapters.current then
    if Chapters.current.draw then Chapters.current.draw() end
  else
    menu.draw()
  end
  mmaker.draw()
  
end

function love.mousemoved(x, y, dx, dy)
  
  if mmaker.mousemoved(x, y, dx, dy) then return end
  if Chapters.current and Chapters.current.mousemoved then
    Chapters.current.mousemoved(x, y, dx, dy)
  end
end

function love.mousepressed(x, y, b)
  
  if mmaker.mousepressed(x, y, b) then return end
  if Chapters.current then
    if Chapters.current.mousepressed then Chapters.current.mousepressed(x, y, b) end
    return
  end
  menu.mousepressed(x, y, b)
end

function love.keypressed(key)
  

  if key == "escape"
     and love.keyboard.isDown("lctrl", "rctrl")
     and love.keyboard.isDown("lshift", "rshift") then
    if not mmaker.isActive then
      mmaker.confirm("Выйти из игры?", function() love.event.quit() end)
    end
    return
  end

  if mmaker.keypressed(key) then return end

  if Chapters.current and key == "escape" then
    mmaker.confirm("Вернуться в главное меню?", function()
      Chapters.unload()
    end)
    return
  end

  if Chapters.current and Chapters.current.keypressed then
    Chapters.current.keypressed(key)
  end
end

function love.mousereleased(x, y, b)
  
  if mmaker.mousereleased(x, y, b) then return end
  if Chapters.current and Chapters.current.mousereleased then
    Chapters.current.mousereleased(x, y, b)
  end
end

function love.wheelmoved(x, y)
  
  if mmaker.wheelmoved(x, y) then return end
  if Chapters.current and Chapters.current.wheelmoved then
    Chapters.current.wheelmoved(x, y)
  end
end

function love.quit()
  mmaker.closeAll()
  Chapters.unload()
end