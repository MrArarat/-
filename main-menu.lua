-- main-menu.lua

local menu = {}

-- Загрузка внешних хэлперов
local Timer = require("helpers.timer")
local mmaker = require("helpers.menumaker")
local Chapters = require("helpers.chapters")

-- Переменные
local titleText = "ПРОЕКТ\nФЕВРАЛЬ"
local bgColor, btnColor, btnHoverColor, textColor

-- Картинки в сцене
local bgPic = love.graphics.newImage("assets/media/bg.png")

  -- Шрифты сцены
menu.titleFont  = love.graphics.newFont("assets/fonts/Title.ttf", 50) 
menu.buttonFont = love.graphics.newFont("assets/fonts/YahfieHeavy.ttf", 24)

-- Хелпер для создания кнопки
local function newButton(x, y, w, h, text, onClick)
  return {
    x = x, y = y, w = w, h = h,
    text = text,
    isHover = false,
    onClick = onClick,
  }
end

function menu.load()
  bgColor       = {0.3, 0.3, 0.3}
  btnColor      = {0.5, 0.5, 0.5, 0.7}
  btnHoverColor = {0.6, 0.6, 0.6, 0.7}
  textColor     = {1, 1, 1}
  
  -- Персонажи
  menu.images = {
    love.graphics.newImage("assets/media/fil-slp-mm-01.png"),
    love.graphics.newImage("assets/media/vilg-sch-mm-01.png"),
    love.graphics.newImage("assets/media/dtr-sch-mm-01.png")
  }

  -- Параметры выезда
  menu.slide = {
    x = -300,
    targetX = -70,
    spacing = -290,
    scale = 400 / menu.images[1]:getWidth(),
    y = 200,
    fadeTime = 0.8,
    delay = 0.3,
    shown = 0,
    timer = 0,
  }

  Chapters.scan()
  
  -- КНОПКИ
  menu.buttons = {
    newButton(520, 180, 240, 40, "ВЫБОР ГЛАВЫ", function()
  local items = {}
  for _, ch in ipairs(Chapters.list) do
    table.insert(items, {
      text = (ch.subtitle and (ch.subtitle .. " — ") or "") .. ch.title,
      style = ch.locked and "danger" or "default",
      onClick = function()
        if ch.locked then
          mmaker.info("Глава заблокирована.")
          return
        end
        mmaker.closeTop()
        local ok, err = Chapters.load(ch)
        if not ok then
          mmaker.errorDefault("Не удалось загрузить главу:\n" .. tostring(err))
        end
      end,
    })
  end

  if #items == 0 then
    mmaker.info("Главы не найдены.\nПроверьте папку chapters/.")
    return
  end

  mmaker.chapterSelect({
    title    = "ВЫБОР ГЛАВЫ",
    text     = "Выберите главу",
    chapters = items,
    width    = 480,
    height   = 460,
    itemH    = 46,
  })
end),
    newButton(520, 240, 240, 40, "ПОМОЩЬ", function()
        
    end),
    newButton(520, 300, 240, 40, "ВЫХОД", function()
      mmaker.confirm("Выйти из игры?", function()
        love.event.quit()
      end)
    end),
  }
end

local function easeOutCubic(t)
  return 1 - (1 - t) ^ 3
end

function menu.update(dt)
  local mx, my = love.mouse.getPosition()

  for _, b in ipairs(menu.buttons) do
    b.isHover = mx > b.x and mx < b.x + b.w and my > b.y and my < b.y + b.h
  end

  local s = menu.slide
  if s.shown < #menu.images then
    s.timer = s.timer + dt
    if s.timer >= s.fadeTime + s.delay then
      s.timer = 0
      s.shown = s.shown + 1
    end
  end
end

function menu.draw()
  -- Фон
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local iw, ih = bgPic:getWidth(), bgPic:getHeight()
  local scale = math.max(sw / iw, sh / ih)

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(bgPic, 0, 0, 0, scale, scale)

  -- Карточка Меню
  love.graphics.setColor(0, 0, 0, 0.4)
  love.graphics.rectangle("fill", 500, 0, 280, 900, 0, 0)

  -- Заголовок
  love.graphics.setFont(menu.titleFont)
  love.graphics.setColor(textColor)
  local tw = menu.titleFont:getWidth(titleText)
  love.graphics.print(titleText, love.graphics.getWidth() - tw - 50, 50)

  -- Кнопки
  love.graphics.setFont(menu.buttonFont)
  for _, b in ipairs(menu.buttons) do
    if b.isHover then
      love.graphics.setColor(btnHoverColor)
    else
      love.graphics.setColor(btnColor)
    end
    love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 5, 5)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(b.text, b.x + 10, b.y + 10)
  end

  -- Персонажи выезд
  local s = menu.slide
  local w = menu.images[1]:getWidth()  * s.scale
  local h = menu.images[1]:getHeight() * s.scale

  for i = 1, #menu.images do
    local finalX = s.targetX + (i - 1) * (w + s.spacing)

    local progress
    if i <= s.shown then
      progress = 1
    elseif i == s.shown + 1 then
      progress = math.min(s.timer / s.fadeTime, 1)
    else
      progress = 0
    end

    if progress > 0 then
      local p = easeOutCubic(progress)
      local x = s.x + (finalX - s.x) * p
      love.graphics.setColor(1, 1, 1, p)
      love.graphics.draw(menu.images[i], x, s.y, 0, s.scale, s.scale)
    end
  end
end

function menu.mousepressed(x, y, btn)
  if btn ~= 1 then return end
  for _, b in ipairs(menu.buttons) do
    if b.isHover then
      -- Анимация нажатия
      b.w = b.w - 1
      b.h = b.h - 1
      b.x = b.x + 1
      b.y = b.y + 1
      Timer.after(0.1, function()
        b.w = b.w + 1
        b.h = b.h + 1
        b.x = b.x - 1
        b.y = b.y - 1
      end)

      if b.onClick then b.onClick() end
      break
    end
  end
end

return menu