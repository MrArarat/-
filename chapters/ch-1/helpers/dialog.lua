-- chapters/ch-1/helpers/dialog.lua
-- Минималистичное диалоговое окно для визуальной новеллы.
-- Поддерживает инлайн-маркеры: <delay 2.0>, <speed 30>, <shake>, <wave>
-- Поддерживает портреты с гибким позиционированием и масштабированием.

local Dialog = {}

-- ============================================================
-- UTF-8 ХЕЛПЕРЫ
-- ============================================================

local function utf8chars(s)
  local chars = {}
  local i = 1
  local n = #s
  while i <= n do
    local b = s:byte(i)
    local len = 1
    if b >= 0xF0 then len = 4
    elseif b >= 0xE0 then len = 3
    elseif b >= 0xC0 then len = 2 end
    chars[#chars + 1] = s:sub(i, i + len - 1)
    i = i + len
  end
  return chars
end

-- ============================================================
-- ПАРСЕР МАРКЕРОВ
-- ============================================================

local function parseMarkers(text)
  local tokens = {}
  local activeEffects = {}
  local i = 1
  local n = #text

  while i <= n do
    local lt = text:find("<", i, true)
    if not lt then
      local rest = text:sub(i)
      for _, ch in ipairs(utf8chars(rest)) do
        local eff = nil
        for k in pairs(activeEffects) do eff = eff or {}; eff[k] = true end
        tokens[#tokens + 1] = { type = "char", value = ch, effect = eff }
      end
      break
    end

    if lt > i then
      local chunk = text:sub(i, lt - 1)
      for _, ch in ipairs(utf8chars(chunk)) do
        local eff = nil
        for k in pairs(activeEffects) do eff = eff or {}; eff[k] = true end
        tokens[#tokens + 1] = { type = "char", value = ch, effect = eff }
      end
    end

    local gt = text:find(">", lt + 1, true)
    if not gt then
      tokens[#tokens + 1] = { type = "char", value = "<", effect = nil }
      i = lt + 1
    else
      local raw = text:sub(lt + 1, gt - 1)
      local cmd, arg = raw:match("^%s*(%S+)%s*(.*)$")
      cmd = (cmd or ""):lower()

      if cmd == "delay" then
        local val = tonumber(arg) or 0.5
        tokens[#tokens + 1] = { type = "delay", value = val }
      elseif cmd == "speed" then
        local val = tonumber(arg) or 45
        tokens[#tokens + 1] = { type = "speed", value = val }
      elseif cmd == "shake" then
        activeEffects.shake = true
        tokens[#tokens + 1] = { type = "effect", value = "shake", on = true }
      elseif cmd == "/shake" then
        activeEffects.shake = nil
        tokens[#tokens + 1] = { type = "effect", value = "shake", on = false }
      elseif cmd == "wave" then
        activeEffects.wave = true
        tokens[#tokens + 1] = { type = "effect", value = "wave", on = true }
      elseif cmd == "/wave" then
        activeEffects.wave = nil
        tokens[#tokens + 1] = { type = "effect", value = "wave", on = false }
      else
        -- неизвестный маркер — игнорируем
      end

      i = gt + 1
    end
  end

  return tokens
end

-- ============================================================
-- НАСТРОЙКИ ВНЕШНЕГО ВИДА
-- ============================================================

local CFG = {
  padX        = 60,
  padBottom   = 40,
  height      = 200,
  corner      = 8,

  boxColor    = {0.05, 0.05, 0.07, 0.88},
  borderColor = {0.35, 0.35, 0.4, 0.9},
  nameColor   = {0.95, 0.85, 0.55, 1},
  textColor   = {0.95, 0.95, 0.95, 1},
  hintColor   = {0.6, 0.6, 0.65, 1},

  nameSize    = 45,
  textSize    = 32,
  hintSize    = 26,

  cps         = 25,
  clickDelay  = 0.12,

  -- ============================================================
  -- НАСТРОЙКИ ПОРТРЕТА ПО УМОЛЧАНИЮ
  -- ============================================================
  -- Всё это можно переопределить в конкретной реплике:
  --   { text = "...", portrait = "path.png",
  --     portraitX = 20, portraitY = -288 + 20, portraitMode = "fit",
  --     portraitW = 300, portraitH = 288, portraitAlign = "custom" }
  portrait = {
    -- Режим масштабирования:
    --   "native"  — без масштаба, 1:1 (использует portraitW/H только для позиции)
    --   "fit"     — вписать в portraitW × portraitH, сохраняя пропорции (по умолчанию)
    --   "stretch" — растянуть ровно в portraitW × portraitH (без сохранения пропорций)
    --   "scale"   — умножить на portraitScale
    mode = "fit",

    -- Размеры бокса для "fit"/"stretch". nil = не ограничивать по этой оси.
    -- Если оба nil — работает как "native".
    w = nil,
    h = 288,

    -- Множитель для mode = "scale"
    scale = 1.0,

    -- Позиционирование относительно окна диалога (bx, by, bw, bh):
    --   "topleft" | "topright" | "bottomleft" | "bottomright" | "center"
    --   "above"   — над окном, по центру
    --   "custom"  — только X/Y
    align = "topleft",

    -- Отступы от выбранного угла/края (работают во всех align, кроме custom)
    offsetX = 20,
    offsetY = 20,

    -- Явные координаты для align = "custom" или как дополнительный сдвиг
    x = 0,
    y = 0,

    -- Пивот (origin) в долях от размера изображения: {0..1, 0..1}.
    -- (0,0) — левый верх, (1,1) — правый низ, (0.5,0.5) — центр.
    -- Нужен, если будешь анимировать масштаб/поворот.
    pivotX = 0,
    pivotY = 0,

    -- Цвет (можно тонировать)
    tint = {1, 1, 1, 1},
  },
}

-- ============================================================
-- СОСТОЯНИЕ
-- ============================================================

Dialog.isActive      = false
Dialog.queue         = {}
Dialog.current       = nil
Dialog.tokens        = {}
Dialog.visibleCount  = 0
Dialog.timer         = 0
Dialog.delayTimer    = 0
Dialog.clickTimer    = 0
Dialog.waiting       = false
Dialog.choices       = nil
Dialog.hoveredChoice = nil
Dialog.onEnd         = nil

Dialog.currentCPS    = CFG.cps

local fonts = {}
local portraits = {}

-- ============================================================
-- ЗАГРУЗКА РЕСУРСОВ
-- ============================================================

local function ensureFonts()
  if fonts.name then return end
  local ok, f = pcall(love.graphics.newFont, "assets/fonts/YahfieHeavy.ttf", CFG.nameSize)
  fonts.name = (ok and f) or love.graphics.newFont(CFG.nameSize)

  ok, f = pcall(love.graphics.newFont, "assets/fonts/YahfieHeavy.ttf", CFG.textSize)
  fonts.text = (ok and f) or love.graphics.newFont(CFG.textSize)

  ok, f = pcall(love.graphics.newFont, "assets/fonts/YahfieHeavy.ttf", CFG.hintSize)
  fonts.hint = (ok and f) or love.graphics.newFont(CFG.hintSize)
end

local function getPortrait(path)
  if not path then return nil end
  if portraits[path] == false then return nil end
  if portraits[path] then return portraits[path] end
  local ok, img = pcall(love.graphics.newImage, path)
  if ok and img then
    img:setFilter("linear", "linear")
    portraits[path] = img
  else
    portraits[path] = false
    print("[dialog] Не удалось загрузить портрет: " .. tostring(path))
  end
  return portraits[path]
end

-- ============================================================
-- ПУБЛИЧНОЕ API
-- ============================================================

function Dialog.start(lines, onEnd)
  ensureFonts()
  Dialog.queue    = {}
  for i, l in ipairs(lines or {}) do
    Dialog.queue[i] = l
  end
  Dialog.onEnd    = onEnd
  Dialog.isActive = true
  Dialog.waiting  = false
  Dialog.choices  = nil
  Dialog._advance()
end

function Dialog.stop()
  Dialog.isActive     = false
  Dialog.queue        = {}
  Dialog.current      = nil
  Dialog.tokens       = {}
  Dialog.choices      = nil
  Dialog.waiting      = false
end

function Dialog.push(line)
  if not Dialog.isActive then
    Dialog.start({line})
    return
  end
  table.insert(Dialog.queue, line)
end

-- ============================================================
-- ЛОГИКА
-- ============================================================

function Dialog._advance()
  Dialog.visibleCount = 0
  Dialog.timer        = 0
  Dialog.delayTimer   = 0
  Dialog.choices      = nil
  Dialog.waiting      = false
  Dialog.tokens       = {}
  Dialog.currentCPS   = CFG.cps

  if #Dialog.queue == 0 then
    Dialog.current  = nil
    Dialog.isActive = false
    if Dialog.onEnd then
      local cb = Dialog.onEnd
      Dialog.onEnd = nil
      cb()
    end
    return
  end

  Dialog.current = table.remove(Dialog.queue, 1)
  Dialog.tokens  = parseMarkers(Dialog.current.text or "")

  if Dialog.current.choices then
    Dialog.waiting = true
    Dialog.choices = Dialog.current.choices
    Dialog.hoveredChoice = nil
  end
end

local function isTextComplete()
  if not Dialog.current then return true end
  if Dialog.current.choices then return true end
  return Dialog.visibleCount >= #Dialog.tokens
end

local function skipTyping()
  if not Dialog.current then return end
  if Dialog.current.choices then return end
  Dialog.visibleCount = #Dialog.tokens
  Dialog.delayTimer   = 0
end

local function getVisibleTokens()
  local out = {}
  for i = 1, Dialog.visibleCount do
    out[i] = Dialog.tokens[i]
  end
  return out
end

-- ============================================================
-- ОБНОВЛЕНИЕ
-- ============================================================

function Dialog.update(dt)
  if not Dialog.isActive then return end
  if Dialog.clickTimer > 0 then Dialog.clickTimer = Dialog.clickTimer - dt end

  if Dialog.waiting then return end
  if not Dialog.current then return end

  if Dialog.delayTimer > 0 then
    Dialog.delayTimer = Dialog.delayTimer - dt
    if Dialog.delayTimer <= 0 then
      Dialog.delayTimer = 0
    end
    return
  end

  local total = #Dialog.tokens

  while Dialog.visibleCount < total do
    local nextTok = Dialog.tokens[Dialog.visibleCount + 1]

    if nextTok.type == "delay" then
      Dialog.visibleCount = Dialog.visibleCount + 1
      Dialog.delayTimer = nextTok.value
      return
    elseif nextTok.type == "speed" then
      Dialog.visibleCount = Dialog.visibleCount + 1
      Dialog.currentCPS = nextTok.value
    elseif nextTok.type == "effect" then
      Dialog.visibleCount = Dialog.visibleCount + 1
    else
      if Dialog.currentCPS > 0 then
        Dialog.timer = Dialog.timer + dt
        local step = 1 / Dialog.currentCPS
        if Dialog.timer >= step then
          Dialog.timer = Dialog.timer - step
          Dialog.visibleCount = Dialog.visibleCount + 1
        else
          break
        end
      else
        Dialog.visibleCount = Dialog.visibleCount + 1
      end
    end
  end
end

-- ============================================================
-- ВВОД
-- ============================================================

function Dialog.mousepressed(x, y, button)
  if not Dialog.isActive or button ~= 1 then return false end
  if Dialog.clickTimer > 0 then return true end
  Dialog.clickTimer = CFG.clickDelay

  if Dialog.waiting and Dialog.choices then
    local hit = Dialog._hitChoice(x, y)
    if hit then
      local c = Dialog.choices[hit]
      Dialog.choices = nil
      Dialog.waiting = false
      if c.onClick then c.onClick() end
      Dialog._advance()
    end
    return true
  end

  if isTextComplete() then
    Dialog._advance()
  else
    skipTyping()
  end
  return true
end

function Dialog.keypressed(key)
  if not Dialog.isActive then return false end
  if key == "space" or key == "return" or key == "kpenter" then
    if Dialog.clickTimer > 0 then return true end
    Dialog.clickTimer = CFG.clickDelay

    if Dialog.waiting and Dialog.choices then
      local c = Dialog.choices[1]
      if c and c.onClick then c.onClick() end
      Dialog.choices = nil
      Dialog.waiting = false
      Dialog._advance()
    elseif isTextComplete() then
      Dialog._advance()
    else
      skipTyping()
    end
    return true
  end
  return false
end

function Dialog.mousemoved(x, y)
  if not Dialog.isActive or not Dialog.waiting or not Dialog.choices then
    Dialog.hoveredChoice = nil
    return
  end
  Dialog.hoveredChoice = Dialog._hitChoice(x, y)
end

-- ============================================================
-- ГЕОМЕТРИЯ
-- ============================================================

local function getBox()
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local x = CFG.padX
  local w = sw - CFG.padX * 2
  local h = CFG.height
  local y = sh - h - CFG.padBottom
  return x, y, w, h
end

function Dialog._hitChoice(mx, my)
  if not Dialog.choices then return nil end
  local bx, by, bw, bh = getBox()
  local listTop = by + 16
  local listH   = bh - 32
  local n       = #Dialog.choices
  local gap     = 8
  local itemH   = math.min(48, (listH - gap * (n - 1)) / n)
  local startY  = listTop + (listH - (itemH * n + gap * (n - 1))) / 2

  for i = 1, n do
    local iy = startY + (i - 1) * (itemH + gap)
    if mx >= bx + 20 and mx <= bx + bw - 20
       and my >= iy and my <= iy + itemH then
      return i
    end
  end
  return nil
end

-- ============================================================
-- ОТРИСОВКА ПОРТРЕТА (гибкая)
-- ============================================================

-- Собирает эффективные настройки портрета: CFG.portrait + переопределения из реплики
local function resolvePortraitCfg(line)
  local base = CFG.portrait
  return {
    mode     = line.portraitMode     or base.mode,
    w        = line.portraitW        or base.w,
    h        = line.portraitH        or base.h,
    scale    = line.portraitScale    or base.scale,
    align    = line.portraitAlign    or base.align,
    offsetX  = line.portraitOffsetX  or base.offsetX,
    offsetY  = line.portraitOffsetY  or base.offsetY,
    x        = line.portraitX        or base.x,
    y        = line.portraitY        or base.y,
    pivotX   = line.portraitPivotX   or base.pivotX,
    pivotY   = line.portraitPivotY   or base.pivotY,
    tint     = line.portraitTint     or base.tint,
  }
end

-- Вычисляет масштаб и итоговые размеры портрета
local function computePortraitSize(img, pc)
  local iw, ih = img:getWidth(), img:getHeight()
  local sx, sy = 1, 1

  if pc.mode == "stretch" then
    if pc.w then sx = pc.w / iw end
    if pc.h then sy = pc.h / ih end
    if pc.w and not pc.h then sy = sx end
    if pc.h and not pc.w then sx = sy end
  elseif pc.mode == "scale" then
    sx, sy = pc.scale, pc.scale
  elseif pc.mode == "fit" then
    -- Вписать в бокс pc.w × pc.h, сохраняя пропорции.
    -- Если задана только одна ось — масштабируем по ней.
    local s = 1
    if pc.w and pc.h then
      s = math.min(pc.w / iw, pc.h / ih)
    elseif pc.w then
      s = pc.w / iw
    elseif pc.h then
      s = pc.h / ih
    end
    sx, sy = s, s
  else -- "native"
    sx, sy = 1, 1
  end

  return iw * sx, ih * sy, sx, sy
end

local function drawPortrait(img, line, bx, by, bw, bh)
  if not img then return end

  local pc = resolvePortraitCfg(line)
  local w, h, sx, sy = computePortraitSize(img, pc)

  -- Позиция в зависимости от align
  local x, y
  if pc.align == "topleft" then
    x = bx + pc.offsetX
    y = by + pc.offsetY
  elseif pc.align == "topright" then
    x = bx + bw - w - pc.offsetX
    y = by + pc.offsetY
  elseif pc.align == "bottomleft" then
    x = bx + pc.offsetX
    y = by + bh - h - pc.offsetY
  elseif pc.align == "bottomright" then
    x = bx + bw - w - pc.offsetX
    y = by + bh - h - pc.offsetY
  elseif pc.align == "center" then
    x = bx + (bw - w) / 2
    y = by + (bh - h) / 2
  elseif pc.align == "above" then
    x = bx + (bw - w) / 2
    y = by - h - pc.offsetY
  else -- "custom"
    x = bx + pc.x
    y = by + pc.y
  end

  -- Дополнительный сдвиг (полезно в любом режиме)
  x = x + (pc.x or 0)
  y = y + (pc.y or 0)

  -- Пивот в пикселях изображения (до масштаба)
  local ox = img:getWidth()  * pc.pivotX
  local oy = img:getHeight() * pc.pivotY

  local t = pc.tint or {1, 1, 1, 1}
  love.graphics.setColor(t[1] or 1, t[2] or 1, t[3] or 1, t[4] or 1)
  love.graphics.draw(img, x, y, 0, sx, sy, ox, oy)
  love.graphics.setColor(1, 1, 1, 1)
end

-- ============================================================
-- ОТРИСОВКА ВЫБОРА
-- ============================================================

local function drawChoiceList(bx, by, bw, bh)
  local listTop = by + 16
  local listH   = bh - 32
  local n       = #Dialog.choices
  local gap     = 8
  local itemH   = math.min(48, (listH - gap * (n - 1)) / n)
  local startY  = listTop + (listH - (itemH * n + gap * (n - 1))) / 2

  love.graphics.setFont(fonts.text)

  for i, c in ipairs(Dialog.choices) do
    local iy = startY + (i - 1) * (itemH + gap)
    local ix = bx + 20
    local iw = bw - 40
    local hovered = (Dialog.hoveredChoice == i)

    if hovered then
      love.graphics.setColor(0.25, 0.35, 0.55, 0.95)
    else
      love.graphics.setColor(0.15, 0.15, 0.2, 0.9)
    end
    love.graphics.rectangle("fill", ix, iy, iw, itemH, 5, 5)

    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.rectangle("line", ix, iy, iw, itemH, 5, 5)

    love.graphics.setColor(CFG.textColor)
    love.graphics.printf(c.text or "…", ix + 12,
      iy + (itemH - fonts.text:getHeight()) / 2,
      iw - 24, "left")
  end
end

-- ============================================================
-- ОТРИСОВКА ТЕКСТА
-- ============================================================

local function drawTextTokens(innerX, ty, innerW)
  local font = fonts.text
  love.graphics.setFont(font)

  local tokens = getVisibleTokens()
  local lineH = font:getHeight()
  local x = innerX
  local y = ty
  local maxX = innerX + innerW
  local time = love.timer.getTime()

  -- Группируем токены в "единицы переноса": слова, пробелы, переносы строк.
  -- Единица = { tokens = {...}, width = number, isSpace = bool, isNewline = bool }
  local units = {}
  local current = nil

  local function flush()
    if current then
      units[#units + 1] = current
      current = nil
    end
  end

  for _, tok in ipairs(tokens) do
    if tok.type ~= "char" then
      -- Служебные токены (delay/speed/effect) не влияют на перенос —
      -- просто пропускаем их здесь, они уже отработаны при печати.
      -- Но чтобы не потерять эффекты — их можно было бы прикрепить,
      -- однако на этапе отрисовки они уже не нужны.
      -- (Ничего не делаем.)
    else
      local ch = tok.value
      if ch == "\n" then
        flush()
        units[#units + 1] = { isNewline = true }
      elseif ch == " " or ch == "\t" then
        -- Пробел — отдельная единица, привязывается к предыдущему слову
        if current and not current.isSpace then
          -- добавляем пробел в текущее слово (хвостовой)
          current.tokens[#current.tokens + 1] = tok
          current.width = current.width + font:getWidth(ch)
          current.trailingSpace = true
        else
          flush()
          current = { tokens = { tok }, width = font:getWidth(ch), isSpace = true }
        end
      else
        if current and not current.isSpace and not current.trailingSpace then
          current.tokens[#current.tokens + 1] = tok
          current.width = current.width + font:getWidth(ch)
        else
          flush()
          current = { tokens = { tok }, width = font:getWidth(ch) }
        end
      end
    end
  end
  flush()

  -- Отрисовка с переносом по единицам
  for _, unit in ipairs(units) do
    if unit.isNewline then
      x = innerX
      y = y + lineH
    else
      -- Если единица не влезает и мы не в начале строки — переносим
      if x + unit.width > maxX and x > innerX then
        x = innerX
        y = y + lineH
        -- Если это пробел в начале строки — пропускаем его
        if unit.isSpace then
          goto continue
        end
      end

      for _, tok in ipairs(unit.tokens) do
        local ch = tok.value
        local w = font:getWidth(ch)

        local dx, dy = 0, 0
        if tok.effect then
          if tok.effect.shake then
            dx = (math.random() - 0.5) * 2.5
            dy = (math.random() - 0.5) * 2.5
          end
          if tok.effect.wave then
            dy = math.sin(time * 8 + x * 0.05) * 3
          end
        end

        love.graphics.setColor(CFG.textColor)
        love.graphics.print(ch, x + dx, y + dy)
        x = x + w
      end
    end
    ::continue::
  end

  return y + lineH
end
-- ============================================================
-- ОТРИСОВКА
-- ============================================================

function Dialog.draw()
  if not Dialog.isActive or not Dialog.current then return end
  ensureFonts()

  local bx, by, bw, bh = getBox()

  -- Портрет рисуем ДО окна, чтобы окно перекрывало его низ (если надо)
  if Dialog.current.portrait then
    drawPortrait(getPortrait(Dialog.current.portrait), Dialog.current, bx, by, bw, bh)
  end

  love.graphics.setColor(CFG.boxColor)
  love.graphics.rectangle("fill", bx, by, bw, bh, CFG.corner, CFG.corner)

  love.graphics.setColor(CFG.borderColor)
  love.graphics.rectangle("line", bx, by, bw, bh, CFG.corner, CFG.corner)

  if Dialog.waiting and Dialog.choices then
    drawChoiceList(bx, by, bw, bh)
    return
  end

  local innerX = bx + 24
  local innerW = bw - 48
  local ty     = by + 18

  if Dialog.current.name and Dialog.current.name ~= "" then
    love.graphics.setFont(fonts.name)
    love.graphics.setColor(CFG.nameColor)
    love.graphics.print(Dialog.current.name, innerX, ty)
    ty = ty + fonts.name:getHeight() + 6
  else
    ty = ty + 6
  end

  drawTextTokens(innerX, ty, innerW)

  if isTextComplete() then
    local t = love.timer.getTime()
    local alpha = 0.5 + 0.5 * math.sin(t * 4)
    love.graphics.setFont(fonts.hint)
    love.graphics.setColor(CFG.hintColor[1], CFG.hintColor[2], CFG.hintColor[3], alpha)
    local hint = "ДАЛЕЕ  (ПРОБЕЛ / ЛКМ)"
    local hw = fonts.hint:getWidth(hint)
    love.graphics.print(hint, bx + bw - hw - 16, by + bh - fonts.hint:getHeight() - 8)
  end
end

-- ============================================================
-- СБРОС
-- ============================================================

function Dialog.reset()
  Dialog.stop()
  Dialog.onEnd  = nil
  portraits     = {}
end

return Dialog