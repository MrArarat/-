-- helpers/console.lua
-- Игровая консоль: перехватывает print() и вывод ошибок LÖVE,
-- показывает оверлей по Alt+F1.

local console = {}

-- ============================================================
-- СОСТОЯНИЕ
-- ============================================================

console.isOpen   = false
console.lines    = {}          -- { {text=, color=} , ... }
console.maxLines = 500         -- сколько строк храним в буфере
console.scroll   = 0           -- сколько строк прокручено от низа
console.visible  = true        -- рисуем ли оверлей

local FONT_SIZE  = 14
local PAD        = 10
local LINE_H     = FONT_SIZE + 4

local font       = nil

-- Сохранённый оригинальный print
local originalPrint = print

-- ============================================================
-- ЦВЕТА
-- ============================================================

local C = {
  bg      = {0, 0, 0, 0.82},
  border  = {0.35, 0.35, 0.4, 1},
  info    = {0.92, 0.92, 0.92, 1},
  warn    = {1.0, 0.85, 0.3, 1},
  error   = {1.0, 0.4, 0.4, 1},
  system  = {0.5, 0.85, 1.0, 1},
  input   = {0.6, 1.0, 0.6, 1},
}

-- ============================================================
-- ДОБАВЛЕНИЕ СТРОК
-- ============================================================

--- Добавить строку в буфер.
-- @param text string
-- @param color table|nil  {r,g,b,a}
function console.push(text, color)
  text = tostring(text)
  -- Многострочные сообщения разбиваем
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    table.insert(console.lines, { text = line, color = color or C.info })
  end

  -- Обрезаем буфер
  local overflow = #console.lines - console.maxLines
  if overflow > 0 then
    for _ = 1, overflow do table.remove(console.lines, 1) end
    console.scroll = math.max(0, console.scroll - overflow)
  end

  -- Автоскролл вниз при открытой консоли, если пользователь не отлистал
  if console.isOpen and console.scroll == 0 then
    -- ничего: scroll==0 означает "прижат к низу"
  end
end

function console.clear()
  console.lines = {}
  console.scroll = 0
end

-- ============================================================
-- ПЕРЕХВАТ PRINT
-- ============================================================

local function hookPrint(...)
  local n = select("#", ...)
  local parts = {}
  for i = 1, n do
    parts[i] = tostring(select(i, ...))
  end
  local msg = table.concat(parts, "\t")

  -- в буфер консоли
  console.push(msg, C.info)

  -- и в настоящий stdout
  return originalPrint(...)
end

-- ============================================================
-- ИНИЦИАЛИЗАЦИЯ / ХУК ОШИБОК
-- ============================================================

function console.init()
  if not font then
    -- Сначала пробуем красивый шрифт, но не падаем если нет
    local ok, f = pcall(love.graphics.newFont, "assets/fonts/YahfieHeavy.ttf", FONT_SIZE)
    if ok and f then
      font = f
    else
      font = love.graphics.newFont(FONT_SIZE)
    end
  end

  -- Перехватываем print глобально
  if print ~= hookPrint then
    print = hookPrint
  end

  -- Перехватываем love.errorhandler (вызывается при необработанной ошибке)
  local originalErrorHandler = love.errorhandler
  love.errorhandler = function(msg)
    console.push("=== LÖVE ERROR ===", C.error)
    console.push(msg, C.error)
    console.push("==================", C.error)
    -- Показываем консоль автоматически
    console.isOpen = true
    console.scroll = 0
    -- Возвращаем стандартный обработчик, чтобы игра не падала молча
    if originalErrorHandler then
      return originalErrorHandler(msg)
    end
  end

  -- Стартовое сообщение
  console.push("[console] Инициализирована. Alt+F1 — открыть/закрыть.", C.system)
end

-- ============================================================
-- ВВОД
-- ============================================================

function console.keypressed(key)
  -- Alt + F1 — переключение
  if key == "f1" then
    console.isOpen = not console.isOpen
    if console.isOpen then console.scroll = 0 end
    return true
  end

  if not console.isOpen then return false end

  if key == "escape" then
    console.isOpen = false
    return true
  elseif key == "c" and love.keyboard.isDown("lctrl", "rctrl") then
    console.clear()
    return true
  elseif key == "up" then
    console.scroll = math.min(console.scroll + 1, math.max(0, #console.lines - 1))
    return true
  elseif key == "down" then
    console.scroll = math.max(0, console.scroll - 1)
    return true
  elseif key == "pageup" then
    console.scroll = math.min(console.scroll + 15, math.max(0, #console.lines - 1))
    return true
  elseif key == "pagedown" then
    console.scroll = math.max(0, console.scroll - 15)
    return true
  elseif key == "home" then
    console.scroll = math.max(0, #console.lines - 1)
    return true
  elseif key == "end" then
    console.scroll = 0
    return true
  end

  -- Пока консоль открыта — глушим остальные клавиши
  return true
end

function console.wheelmoved(x, y)
  if not console.isOpen then return false end
  if y > 0 then
    console.scroll = math.min(console.scroll + 3, math.max(0, #console.lines - 1))
  elseif y < 0 then
    console.scroll = math.max(0, console.scroll - 3)
  end
  return true
end

-- ============================================================
-- ОТРИСОВКА
-- ============================================================

function console.draw()
  if not console.isOpen then return end
  if not font then return end

  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local w = sw - 40
  local h = math.floor(sh * 0.55)
  local x = 20
  local y = sh - h - 20

  -- Фон
  love.graphics.setColor(C.bg)
  love.graphics.rectangle("fill", x, y, w, h, 6, 6)

  -- Рамка
  love.graphics.setColor(C.border)
  love.graphics.rectangle("line", x, y, w, h, 6, 6)

  -- Заголовок
  love.graphics.setFont(font)
  love.graphics.setColor(C.system)
  love.graphics.print("КОНСОЛЬ  (Alt+F1 — закрыть, Ctrl+C — очистить, Стрелки — скролл)",
                      x + PAD, y + PAD - 2)

  -- Область строк
  local viewY = y + PAD + LINE_H + 4
  local viewH = h - (viewY - y) - PAD
  local viewX = x + PAD
  local viewW = w - PAD * 2 - 8  -- место под скроллбар

  local totalLines = #console.lines
  local maxVisible = math.floor(viewH / LINE_H)
  local endIndex   = totalLines - console.scroll
  local startIndex = math.max(1, endIndex - maxVisible + 1)
  endIndex         = math.min(totalLines, startIndex + maxVisible - 1)

  love.graphics.setScissor(viewX, viewY, viewW, viewH)

  local ty = viewY
  for i = startIndex, endIndex do
    local line = console.lines[i]
    love.graphics.setColor(line.color or C.info)
    -- обрезаем слишком длинные строки по ширине
    local s = line.text
    if font:getWidth(s) > viewW then
      while #s > 0 and font:getWidth(s .. "…") > viewW do
        s = s:sub(1, -2)
      end
      s = s .. "…"
    end
    love.graphics.print(s, viewX, ty)
    ty = ty + LINE_H
  end

  love.graphics.setScissor()

  -- Скроллбар
  if totalLines > maxVisible then
    local trackX = x + w - PAD - 6
    local trackY = viewY
    local trackH = viewH

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", trackX, trackY, 6, trackH, 3, 3)

    local thumbH = math.max(20, trackH * (maxVisible / totalLines))
    local t = 1 - (console.scroll / math.max(1, totalLines - maxVisible))
    t = math.max(0, math.min(1, t))
    local thumbY = trackY + t * (trackH - thumbH)

    love.graphics.setColor(0.7, 0.7, 0.75, 1)
    love.graphics.rectangle("fill", trackX, thumbY, 6, thumbH, 3, 3)
  end
end

return console