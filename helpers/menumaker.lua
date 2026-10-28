-- helpers/menumaker.lua
-- Модальные меню/диалоги для LÖVE 11.x
-- Без анимаций. Автоматически замораживает игру, пока открыто окно.
-- Поддерживает скроллируемые списки (для выбора глав).

local mmaker = {}

-- ============================================================
-- СОСТОЯНИЕ
-- ============================================================

mmaker.windows = {}
mmaker.isActive = false

local SCROLLBAR_W = 12

local fonts = {}
local function getFonts()
  if not fonts.title then
    fonts.title  = love.graphics.newFont("assets/fonts/YahfieHeavy.ttf", 28)
    fonts.text   = love.graphics.newFont("assets/fonts/YahfieHeavy.ttf", 18)
    fonts.button = love.graphics.newFont("assets/fonts/YahfieHeavy.ttf", 16)
  end
  return fonts
end

-- ============================================================
-- ЦВЕТА ПО УМОЛЧАНИЮ
-- ============================================================

local DEFAULT_COLORS = {
  shadow      = {0, 0, 0, 0.55},
  panel       = {0.12, 0.12, 0.14, 0.97},
  border      = {0.35, 0.35, 0.38, 1},
  titleBar    = {0.18, 0.18, 0.22, 1},
  titleText   = {1, 1, 1, 1},
  text        = {0.92, 0.92, 0.92, 1},
  btn         = {0.25, 0.25, 0.25, 1},
  btnHover    = {0.38, 0.38, 0.45, 1},
  btnPressed  = {0.18, 0.18, 0.56, 1},
  btnFocused  = {0.45, 0.45, 0.55, 1},
  btnText     = {1, 1, 1, 1},
  btnDanger   = {0.55, 0.20, 0.20, 1},
  btnDangerHv = {0.72, 0.28, 0.28, 1},
  btnPrimary  = {0.22, 0.42, 0.65, 1},
  btnPrimaryHv= {0.30, 0.55, 0.82, 1},
}

local function copyColors(overrides)
  local c = {}
  for k, v in pairs(DEFAULT_COLORS) do c[k] = v end
  if overrides then
    for k, v in pairs(overrides) do c[k] = v end
  end
  return c
end

-- ============================================================
-- УТИЛИТЫ
-- ============================================================

local function wrapText(font, text, maxWidth)
  local lines = {}
  for rawLine in tostring(text):gmatch("[^\n]*") do
    if rawLine == "" then
      table.insert(lines, "")
    else
      local current = ""
      for word in rawLine:gmatch("%S+") do
        local test = (current == "") and word or (current .. " " .. word)
        if font:getWidth(test) <= maxWidth then
          current = test
        else
          if current ~= "" then table.insert(lines, current) end
          if font:getWidth(word) > maxWidth then
            local chunk = ""
            for i = 1, #word do
              local c = word:sub(i, i)
              if font:getWidth(chunk .. c) > maxWidth and chunk ~= "" then
                table.insert(lines, chunk)
                chunk = c
              else
                chunk = chunk .. c
              end
            end
            current = chunk
          else
            current = word
          end
        end
      end
      if current ~= "" then table.insert(lines, current) end
    end
  end
  return lines
end

-- ============================================================
-- СОЗДАНИЕ ОКНА
-- ============================================================

function mmaker.open(opts)
  opts = opts or {}
  local F = getFonts()

  local win = {
    title     = opts.title or "",
    text      = opts.text or "",
    buttons   = {},
    width     = opts.width or 420,
    height    = opts.height,
    closable  = opts.closable or false,
    onClose   = opts.onClose,
    colors    = copyColors(opts.colors),
    modal     = (opts.modal ~= false),
    drawBehind= opts.drawBehind,

    focused   = 1,
    mx        = 0,
    my        = 0,
    hovered   = nil,
    pressed   = nil,
  }

  local srcButtons = opts.buttons or {
    { text = "OK", style = "primary" }
  }
  for i, b in ipairs(srcButtons) do
    win.buttons[i] = {
      text     = b.text or ("Кнопка " .. i),
      onClick  = b.onClick,
      style    = b.style or "default",
      w        = 0,
      h        = 34,
      x        = 0,
      y        = 0,
      hovered  = false,
      pressed  = false,
    }
  end

  mmaker._layout(win, F)

  table.insert(mmaker.windows, win)
  mmaker.isActive = true
  win.focused = 1

  return win
end

function mmaker.close(win)
  if not win then return end
  for i = #mmaker.windows, 1, -1 do
    if mmaker.windows[i] == win then
      table.remove(mmaker.windows, i)
      break
    end
  end
  if win.onClose then win.onClose() end
  mmaker.isActive = #mmaker.windows > 0
end

function mmaker.closeTop()
  local win = mmaker.windows[#mmaker.windows]
  if win then mmaker.close(win) end
end

function mmaker.closeAll()
  for i = #mmaker.windows, 1, -1 do
    local w = mmaker.windows[i]
    if w.onClose then w.onClose() end
  end
  mmaker.windows = {}
  mmaker.isActive = false
end

-- ============================================================
-- ГЕОМЕТРИЯ
-- ============================================================

function mmaker._layout(win, F)
  F = F or getFonts()
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

  local panelW = math.min(win.width, sw - 40)

  local textPad  = 20
  local titleH   = (win.title ~= "") and (F.title:getHeight() + 16) or 0
  local wrapW    = panelW - textPad * 2
  local lines    = wrapText(F.text, win.text, wrapW)
  local lineH    = F.text:getHeight() * 1.25
  local textH    = #lines * lineH

  local btnGap   = 10
  local btnPadX  = 20
  local btnPadY  = 16
  local btnH     = 34
  local btnAreaH = btnH + btnPadY * 2

  local panelH = win.height
  if not panelH then
    panelH = titleH + textPad + textH + btnAreaH + 10
    panelH = math.max(panelH, 140)
  end
  panelH = math.min(panelH, sh - 40)

  win.panelW = panelW
  win.panelH = panelH
  win.px = (sw - panelW) / 2
  win.py = (sh - panelH) / 2

  win._lines   = lines
  win._lineH   = lineH
  win._textPad = textPad
  win._titleH  = titleH

  local n = #win.buttons
  if n > 0 then
    local availW = panelW - btnPadX * 2
    local totalGap = btnGap * (n - 1)
    local bw = (availW - totalGap) / n
    bw = math.min(bw, 160)
    local totalW = bw * n + totalGap
    local startX = win.px + (panelW - totalW) / 2
    local by = win.py + panelH - btnPadY - btnH
    for i, b in ipairs(win.buttons) do
      b.w = bw
      b.h = btnH
      b.x = startX + (i - 1) * (bw + btnGap)
      b.y = by
    end
  end
end

-- ============================================================
-- ГЕОМЕТРИЯ СКРОЛЛА
-- ============================================================

function mmaker._layoutScroll(win, F)
  F = F or getFonts()
  local panelW = win.panelW
  local panelH = win.panelH

  local titleH = win._titleH or 0
  local padX   = 16

  -- Верх области списка: под заголовком + отступ
  local topY = win.py + titleH + 12

  -- Низ области списка: над кнопками (если есть) либо до низа панели
  local bottomY
  if #win.buttons > 0 then
    -- Кнопки рисуются в _layout: by = py + panelH - 16 - 34
    -- Оставляем 10px зазор над кнопками.
    bottomY = win.py + panelH - 16 - 34 - 10
  else
    bottomY = win.py + panelH - 16
  end

  win.viewH  = math.max(20, bottomY - topY)
  win._viewX = win.px + padX
  win._viewY = topY
  win._viewW = panelW - padX * 2 - SCROLLBAR_W - 6

  local n = #win.items
  local totalH = n * win.itemH + math.max(0, n - 1) * win.itemGap
  win.maxScroll = math.max(0, totalH - win.viewH)
  if win.scroll > win.maxScroll then win.scroll = win.maxScroll end
  if win.scroll < 0 then win.scroll = 0 end

  win._itemRects = {}
  for i, it in ipairs(win.items) do
    local ry = win._viewY + (i - 1) * (win.itemH + win.itemGap) - win.scroll
    it._x = win._viewX
    it._y = ry
    it._w = win._viewW
    it._h = win.itemH
    it._visible = (ry + it._h > win._viewY) and (ry < win._viewY + win.viewH)
    table.insert(win._itemRects, it)
  end

  local trackX = win.px + panelW - padX - SCROLLBAR_W
  local trackY = win._viewY
  local trackH = win.viewH
  win._trackRect = { x = trackX, y = trackY, w = SCROLLBAR_W, h = trackH }

  if win.maxScroll > 0 then
    local thumbH = math.max(30, trackH * (win.viewH / (win.viewH + win.maxScroll)))
    local t = win.scroll / win.maxScroll
    local thumbY = trackY + t * (trackH - thumbH)
    win._thumbRect = { x = trackX, y = thumbY, w = SCROLLBAR_W, h = thumbH }
  else
    win._thumbRect = nil
  end
end

function mmaker._updateScroll(win, mx, my)
  win.hoveredItem = nil

  -- Если мышь вне области списка — ничего не наводим
  local inView = mx >= win._viewX and mx <= win._viewX + win._viewW
             and my >= win._viewY and my <= win._viewY + win.viewH

  for i, it in ipairs(win.items) do
    local inside = inView and it._visible
      and mx >= it._x and mx <= it._x + it._w
      and my >= it._y and my <= it._y + it._h
    it.hovered = inside
    if inside then
      win.hoveredItem = i
      win.focused = i
      win._kbFocus = false
    end
  end

  win._thumbHover = false
  if win._thumbRect then
    local r = win._thumbRect
    win._thumbHover = mx >= r.x - 2 and mx <= r.x + r.w + 2
                  and my >= r.y and my <= r.y + r.h
  end
end

function mmaker._drawScroll(win, F)
  local C = win.colors

  -- Включаем отсечение по области списка
  love.graphics.setScissor(win._viewX - 4, win._viewY - 4,
                           win._viewW + 8, win.viewH + 8)

  -- Лёгкая подложка списка
  love.graphics.setColor(0, 0, 0, 0.15)
  love.graphics.rectangle("fill", win._viewX - 4, win._viewY - 4,
                          win._viewW + 8, win.viewH + 8, 6, 6)

  -- Элементы
  love.graphics.setFont(F.button)
  for i, it in ipairs(win.items) do
    if it._visible then
      local col = C.btn
      if it.style == "primary" then col = C.btnPrimary end
      if it.style == "danger"  then col = C.btnDanger  end

      if it.pressed then
        col = C.btnPressed
      elseif it.hovered or (win.focused == i and win._kbFocus) then
        if it.style == "primary" then col = C.btnPrimaryHv
        elseif it.style == "danger" then col = C.btnDangerHv
        else col = C.btnHover end
      end

      love.graphics.setColor(col)
      love.graphics.rectangle("fill", it._x, it._y, it._w, it._h, 4, 4)

      love.graphics.setColor(C.btnText)
      love.graphics.printf(it.text, it._x + 12,
        it._y + (it._h - F.button:getHeight()) / 2,
        it._w - 24, "left")
    end
  end

  -- Рамка области списка
  love.graphics.setColor(C.border)
  love.graphics.rectangle("line", win._viewX - 4, win._viewY - 4,
                          win._viewW + 8, win.viewH + 8, 6, 6)

  -- Выключаем scissor для скроллбара
  love.graphics.setScissor()

  -- Слайдер
  local tr = win._trackRect
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.rectangle("fill", tr.x, tr.y, tr.w, tr.h, 6, 6)

  if win._thumbRect then
    local r = win._thumbRect
    local c
    if win._thumbHover or win._dragging then
      c = {0.6, 0.6, 0.7, 1}
    else
      c = {0.45, 0.45, 0.5, 1}
    end
    love.graphics.setColor(c)
    love.graphics.rectangle("fill", r.x + 2, r.y, r.w - 4, r.h, 5, 5)
  end
end

-- ============================================================
-- ПУБЛИЧНЫЙ API: chapterSelect
-- ============================================================

--- Окно выбора глав с вертикальным скроллом.
-- @param opts table:
--   title    - заголовок окна
--   text     - описание (опционально)
--   chapters - массив { { text=, onClick=, style= }, ... }
--   buttons  - нижние кнопки (по умолч. "НАЗАД")
--   width    - ширина окна (по умолч. 460)
--   height   - высота окна (по умолч. 420)
--   itemH    - высота элемента (по умолч. 44)
--   itemGap  - отступ между элементами (по умолч. 6)
--   closable - можно ли закрыть (по умолч. true)
--   colors   - переопределение цветов
function mmaker.chapterSelect(opts)
  opts = opts or {}
  local F = getFonts()

  local win = {
    title      = opts.title or "ВЫБОР ГЛАВЫ",
    text       = opts.text or "",
    buttons    = {},
    items      = {},
    width      = opts.width  or 460,
    height     = opts.height or 420,
    closable   = opts.closable ~= false,
    onClose    = opts.onClose,
    colors     = copyColors(opts.colors),
    modal      = true,
    scrollable = true,
    itemH      = opts.itemH or 44,
    itemGap    = opts.itemGap or 6,
    scroll     = 0,
    focused    = 1,
    _kbFocus   = false,
    _dragging  = false,
    _dragOffY  = 0,
  }

  for i, ch in ipairs(opts.chapters or {}) do
    win.items[i] = {
      text    = ch.text or ("Глава " .. i),
      onClick = ch.onClick,
      style   = ch.style or "default",
      hovered = false,
      pressed = false,
    }
  end

  local srcButtons = opts.buttons or {
    { text = "НАЗАД", style = "default",
      onClick = function() mmaker.closeTop() end },
  }
  for i, b in ipairs(srcButtons) do
    win.buttons[i] = {
      text    = b.text or ("Кнопка " .. i),
      onClick = b.onClick,
      style   = b.style or "default",
      w = 0, h = 34, x = 0, y = 0,
      hovered = false, pressed = false,
    }
  end

  mmaker._layout(win, F)
  mmaker._layoutScroll(win, F)

  table.insert(mmaker.windows, win)
  mmaker.isActive = true
  return win
end

-- ============================================================
-- ОБНОВЛЕНИЕ
-- ============================================================

function mmaker.update(dt)
  if not mmaker.isActive then return end

  local F = getFonts()
  local mx, my = love.mouse.getPosition()

  for _, win in ipairs(mmaker.windows) do
    mmaker._layout(win, F)
    if win.scrollable then
      mmaker._layoutScroll(win, F)
    end
    win.mx, win.my = mx, my
    win.hovered = nil

    local isTop = (win == mmaker.windows[#mmaker.windows])

    if isTop then
      if win.scrollable then
        mmaker._updateScroll(win, mx, my)
      else
        for i, b in ipairs(win.buttons) do
          local isHover = mx >= b.x and mx <= b.x + b.w
                      and my >= b.y and my <= b.y + b.h
          b.hovered = isHover
          if isHover then win.hovered = i end
        end
      end
      -- Нижние кнопки в любом случае
      for i, b in ipairs(win.buttons) do
        b.hovered = mx >= b.x and mx <= b.x + b.w
                and my >= b.y and my <= b.y + b.h
      end
    else
      for _, b in ipairs(win.buttons) do b.hovered = false end
      if win.scrollable then
        for _, it in ipairs(win.items) do it.hovered = false end
      end
    end
  end
end

-- ============================================================
-- ОТРИСОВКА
-- ============================================================

function mmaker.draw()
  if not mmaker.isActive then return end

  local F = getFonts()

  for _, win in ipairs(mmaker.windows) do
    if win.drawBehind then
      win.drawBehind()
    elseif win.modal then
      love.graphics.setColor(win.colors.shadow)
      love.graphics.rectangle("fill", 0, 0,
        love.graphics.getWidth(), love.graphics.getHeight())
    end

    local C = win.colors

    -- Панель
    love.graphics.setColor(C.panel)
    love.graphics.rectangle("fill", win.px, win.py, win.panelW, win.panelH)

    -- Заголовок
    local y = win.py
    if win.title ~= "" then
      love.graphics.setFont(F.title)
      love.graphics.setColor(C.titleText)
      love.graphics.printf(win.title, win.px, win.py + 8, win.panelW, "center")
      y = win.py + win._titleH
    end

    -- Текст (для скролла — только если он есть)
    local drawText = true
    if win.scrollable and (not win.text or win.text == "") then
      drawText = false
    end
    if drawText then
      love.graphics.setFont(F.text)
      love.graphics.setColor(C.text)
      local ty = y + win._textPad
      for _, line in ipairs(win._lines) do
        love.graphics.printf(line, win.px + win._textPad, ty,
          win.panelW - win._textPad * 2, "center")
        ty = ty + win._lineH
      end
    end

    -- Скроллируемый список
    if win.scrollable then
      mmaker._drawScroll(win, F)
    end

    -- Нижние кнопки
    love.graphics.setFont(F.button)
    for i, b in ipairs(win.buttons) do
      local col = C.btn
      if b.style == "danger"  then col = C.btnDanger  end
      if b.style == "primary" then col = C.btnPrimary end

      if b.pressed then
        col = C.btnPressed
      elseif b.hovered then
        col = C.btnHover
      end

      love.graphics.setColor(col)
      love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)

      love.graphics.setColor(C.btnText)
      love.graphics.printf(b.text, b.x,
        b.y + (b.h - F.button:getHeight()) / 2, b.w, "center")
    end
  end
end

-- ============================================================
-- ВВОД
-- ============================================================

function mmaker.mousepressed(x, y, button)
  if not mmaker.isActive or button ~= 1 then return false end
  local win = mmaker.windows[#mmaker.windows]
  if not win then return false end

  -- 1) Слайдер
  if win.scrollable then
    if win._thumbRect then
      local r = win._thumbRect
      if x >= r.x - 4 and x <= r.x + r.w + 4
         and y >= r.y and y <= r.y + r.h then
        win._dragging = true
        win._dragOffY = y - r.y
        return true
      end
      local tr = win._trackRect
      if x >= tr.x and x <= tr.x + tr.w
         and y >= tr.y and y <= tr.y + tr.h then
        local t = (y - tr.y - (r.h / 2)) / (tr.h - r.h)
        t = math.max(0, math.min(1, t))
        win.scroll = t * win.maxScroll
        return true
      end
    end

    -- 2) Элементы списка (только если в области списка)
    local inView = x >= win._viewX and x <= win._viewX + win._viewW
               and y >= win._viewY and y <= win._viewY + win.viewH
    if inView then
      for i, it in ipairs(win.items) do
        if it._visible
           and x >= it._x and x <= it._x + it._w
           and y >= it._y and y <= it._y + it._h then
          it.pressed = true
          win.focused = i
          win._kbFocus = false
          return true
        end
      end
    end
  end

  -- 3) Нижние кнопки
  for i, b in ipairs(win.buttons) do
    if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
      b.pressed = true
      win.focused = i
      return true
    end
  end

  local inside = x >= win.px and x <= win.px + win.panelW
             and y >= win.py and y <= win.py + win.panelH
  if not inside and win.closable then
    mmaker.close(win)
  end
  return true
end

function mmaker.mousereleased(x, y, button)
  if not mmaker.isActive or button ~= 1 then return false end
  local win = mmaker.windows[#mmaker.windows]
  if not win then return false end

  -- Ползунок
  if win.scrollable and win._dragging then
    win._dragging = false
    return true
  end

  -- Элементы
  if win.scrollable then
    for _, it in ipairs(win.items) do
      if it.pressed then
        it.pressed = false
        local inside = it._visible
          and x >= it._x and x <= it._x + it._w
          and y >= it._y and y <= it._y + it._h
        if inside and it.onClick then it.onClick() end
        return true
      end
    end
  end

  -- Нижние кнопки
  for _, b in ipairs(win.buttons) do
    if b.pressed then
      b.pressed = false
      local inside = x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h
      if inside and b.onClick then b.onClick() end
      return true
    end
  end
  return true
end

function mmaker.wheelmoved(x, y)
  if not mmaker.isActive then return false end
  local win = mmaker.windows[#mmaker.windows]
  if not win then return false end

  if win.scrollable then
    win.scroll = win.scroll - y * (win.itemH + win.itemGap)
    win.scroll = math.max(0, math.min(win.maxScroll, win.scroll))
    return true
  end

  if y ~= 0 and #win.buttons > 0 then
    win.focused = win.focused + (y > 0 and -1 or 1)
    if win.focused < 1 then win.focused = #win.buttons end
    if win.focused > #win.buttons then win.focused = 1 end
  end
  return true
end

function mmaker.keypressed(key)
  if not mmaker.isActive then return false end
  local win = mmaker.windows[#mmaker.windows]
  if not win then return false end

  -- Скроллируемый список
  if win.scrollable then
    local n = #win.items
    if key == "up" or key == "w" then
      win._kbFocus = true
      win.focused = math.max(1, win.focused - 1)
      mmaker._scrollToFocused(win)
      return true
    elseif key == "down" or key == "s" then
      win._kbFocus = true
      win.focused = math.min(n, win.focused + 1)
      mmaker._scrollToFocused(win)
      return true
    elseif key == "pageup" then
      win._kbFocus = true
      win.scroll = math.max(0, win.scroll - win.viewH)
      return true
    elseif key == "pagedown" then
      win._kbFocus = true
      win.scroll = math.min(win.maxScroll, win.scroll + win.viewH)
      return true
    elseif key == "home" then
      win._kbFocus = true
      win.focused = 1
      win.scroll = 0
      return true
    elseif key == "end" then
      win._kbFocus = true
      win.focused = n
      mmaker._scrollToFocused(win)
      return true
    elseif key == "return" or key == "kpenter" or key == "space" then
      local it = win.items[win.focused]
      if it and it.onClick then it.onClick() end
      return true
    elseif key == "escape" then
      if win.closable then mmaker.close(win) end
      return true
    end
    return true
  end

  -- Обычное окно с кнопками
  if key == "left" or key == "a" then
    win.focused = win.focused - 1
    if win.focused < 1 then win.focused = #win.buttons end
    return true
  elseif key == "right" or key == "d" then
    win.focused = win.focused + 1
    if win.focused > #win.buttons then win.focused = 1 end
    return true
  elseif key == "tab" then
    win.focused = win.focused + 1
    if win.focused > #win.buttons then win.focused = 1 end
    return true
  elseif key == "return" or key == "kpenter" or key == "space" then
    local b = win.buttons[win.focused]
    if b and b.onClick then b.onClick() end
    return true
  elseif key == "escape" then
    if win.closable then mmaker.close(win) end
    return true
  end
  return true
end

function mmaker.mousemoved(x, y, dx, dy)
  if not mmaker.isActive then return false end
  local win = mmaker.windows[#mmaker.windows]
  if win and win.scrollable and win._dragging and win._thumbRect then
    local tr = win._trackRect
    local t = (y - tr.y - win._dragOffY) / (tr.h - win._thumbRect.h)
    t = math.max(0, math.min(1, t))
    win.scroll = t * win.maxScroll
    return true
  end
  return mmaker.isActive
end

function mmaker.textinput(text)
  return mmaker.isActive
end

-- Автоскролл к выбранному элементу
function mmaker._scrollToFocused(win)
  local it = win.items[win.focused]
  if not it then return end
  local top    = (win.focused - 1) * (win.itemH + win.itemGap)
  local bottom = top + win.itemH

  if top < win.scroll then
    win.scroll = top
  elseif bottom > win.scroll + win.viewH then
    win.scroll = bottom - win.viewH
  end
  win.scroll = math.max(0, math.min(win.maxScroll, win.scroll))
end

-- ============================================================
-- ПРЕСЕТЫ
-- ============================================================

function mmaker.dialogMenu(name, text, butt1, butt2, butt3, butt4, opts)
  local buttons = {}
  local function add(b)
    if not b then return end
    if type(b) == "string" then
      table.insert(buttons, { text = b, style = "default" })
    elseif type(b) == "table" then
      table.insert(buttons, b)
    end
  end
  add(butt1); add(butt2); add(butt3); add(butt4)

  opts = opts or {}
  opts.title   = name
  opts.text    = text
  opts.buttons = buttons
  if opts.closable == nil then opts.closable = true end
  return mmaker.open(opts)
end

function mmaker.errorDefault(errorText, butt1, butt2, opts)
  opts = opts or {}
  opts.title = opts.title or "Ошибка"
  opts.text  = errorText
  opts.buttons = {
    { text = butt1 or "ОК", style = "primary",
      onClick = function() mmaker.closeTop() end },
  }
  if butt2 then
    table.insert(opts.buttons, {
      text = butt2, style = "default",
      onClick = function() mmaker.closeTop() end,
    })
  end
  opts.closable = true
  return mmaker.open(opts)
end

function mmaker.errorFatal(errorText, exitButt, opts)
  opts = opts or {}
  opts.title = opts.title or "Критическая ошибка"
  opts.text  = errorText
  opts.buttons = {
    { text = exitButt or "ВЫЙТИ", style = "danger",
      onClick = function() love.event.quit() end },
  }
  opts.closable = false
  return mmaker.open(opts)
end

function mmaker.info(text, opts)
  opts = opts or {}
  opts.title = opts.title or "Информация"
  opts.text  = text
  opts.buttons = opts.buttons or {
    { text = "ОК", style = "primary",
      onClick = function() mmaker.closeTop() end },
  }
  opts.closable = true
  return mmaker.open(opts)
end

function mmaker.confirm(text, onYes, onNo, opts)
  opts = opts or {}
  opts.title = opts.title or "Подтверждение"
  opts.text  = text
  opts.buttons = {
    { text = opts.yesText or "ДА", style = "primary",
      onClick = function()
        mmaker.closeTop()
        if onYes then onYes() end
      end },
    { text = opts.noText or "НЕТ", style = "default",
      onClick = function()
        mmaker.closeTop()
        if onNo then onNo() end
      end },
  }
  opts.closable = true
  return mmaker.open(opts)
end

return mmaker