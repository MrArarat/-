-- helpers/fade.lua
-- Универсальный чёрный fade-слой.
--   Fade.fadeIn(duration, onDone)   -- из чёрного в прозрачный
--   Fade.fadeOut(duration, onDone)  -- из прозрачного в чёрный
--   Fade.set(alpha)                 -- мгновенно выставить альфу
--   Fade.update(dt)
--   Fade.draw()

local Fade = {}

Fade.alpha    = 0        -- 1 = чёрный, 0 = прозрачный
Fade.color    = {0, 0, 0}
Fade.active   = false
Fade.mode     = nil      -- "in" | "out" | nil
Fade.timer    = 0
Fade.duration = 0
Fade.fromA    = 0
Fade.toA      = 0
Fade.onDone   = nil

-- ============================================================
-- ПУБЛИЧНОЕ API
-- ============================================================

--- Мгновенно установить альфу, без анимации.
function Fade.set(a)
  Fade.alpha    = math.max(0, math.min(1, a))
  Fade.active   = Fade.alpha > 0
  Fade.mode     = nil
  Fade.timer    = 0
  Fade.duration = 0
  Fade.onDone   = nil
end

--- Плавно убрать чёрный (из чёрного в прозрачный).
function Fade.fadeIn(duration, onDone)
  duration = duration or 1
  Fade.fromA    = Fade.alpha
  Fade.toA      = 0
  Fade.duration = duration
  Fade.timer    = 0
  Fade.mode     = "in"
  Fade.active   = true
  Fade.onDone   = onDone
end

--- Плавно наложить чёрный (из прозрачного в чёрный).
function Fade.fadeOut(duration, onDone)
  duration = duration or 1
  Fade.fromA    = Fade.alpha
  Fade.toA      = 1
  Fade.duration = duration
  Fade.timer    = 0
  Fade.mode     = "out"
  Fade.active   = true
  Fade.onDone   = onDone
end

--- Отменить текущий переход.
function Fade.cancel()
  Fade.mode   = nil
  Fade.active = Fade.alpha > 0
  Fade.onDone = nil
end

-- ============================================================
-- ОБНОВЛЕНИЕ
-- ============================================================

local function easeInOut(t)
  return t * t * (3 - 2 * t)
end

function Fade.update(dt)
  if not Fade.mode then return end

  Fade.timer = Fade.timer + dt
  local t = Fade.duration > 0 and (Fade.timer / Fade.duration) or 1
  if t > 1 then t = 1 end

  local e = easeInOut(t)
  Fade.alpha = Fade.fromA + (Fade.toA - Fade.fromA) * e

  if t >= 1 then
    Fade.alpha  = Fade.toA
    Fade.mode   = nil
    Fade.active = Fade.alpha > 0
    local cb = Fade.onDone
    Fade.onDone = nil
    if cb then cb() end
  end
end

-- ============================================================
-- ОТРИСОВКА
-- ============================================================

function Fade.draw()
  if Fade.alpha <= 0 then return end
  love.graphics.setColor(Fade.color[1], Fade.color[2], Fade.color[3], Fade.alpha)
  love.graphics.rectangle("fill", 0, 0,
    love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.setColor(1, 1, 1, 1)
end

return Fade