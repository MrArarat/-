-- helpers/timer.lua
local Timer = {}

local tasks = {}          -- список активных задач
local paused = false      -- глобальная пауза
local idCounter = 0       -- для уникальных id

-- ============================================================
--  Утилиты
-- ============================================================

local function newTask(props)
  idCounter = idCounter + 1
  local task = {
    id          = idCounter,
    time        = props.time or 0,
    interval    = props.interval,
    callback    = props.callback,
    onCancel    = props.onCancel,
    onFinish    = props.onFinish,
    cancelled   = false,
    paused      = false,
    repeating   = props.repeating or false,
    remaining   = props.remaining,   -- сколько раз ещё повторить (nil = бесконечно)
    elapsed     = 0,
  }
  table.insert(tasks, task)
  return task
end

-- ============================================================
--  Основные функции
-- ============================================================

--- Выполнить callback через delay секунд
function Timer.after(delay, callback, onFinish)
  return newTask({
    time     = delay,
    callback = callback,
    onFinish = onFinish,
  })
end

--- Выполнить callback через delay секунд (синоним Timer.after)
function Timer.delay(delay, callback, onFinish)
  return Timer.after(delay, callback, onFinish)
end

--- Выполнить callback каждые interval секунд
--- @param interval number
--- @param callback function
--- @param count number|nil  сколько раз выполнить (nil = бесконечно)
function Timer.every(interval, callback, count)
  return newTask({
    time      = interval,
    interval  = interval,
    callback  = callback,
    repeating = true,
    remaining = count,
  })
end

--- Выполнить callback N раз с интервалом interval
function Timer.repeat_(interval, count, callback)
  return Timer.every(interval, callback, count)
end

--- Выполнить callback один раз после задержки, затем повторять каждые interval
function Timer.afterEvery(delay, interval, callback)
  local task
  task = Timer.after(delay, function()
    callback()
    task.repeating = true
    task.interval  = interval
    task.time      = interval
  end)
  return task
end

-- ============================================================
--  Управление задачами
-- ============================================================

--- Отменить задачу
function Timer.cancel(task)
  if not task or task.cancelled then return end
  task.cancelled = true
  if task.onCancel then task.onCancel(task) end
end

--- Поставить задачу на паузу
function Timer.pause(task)
  if task then task.paused = true end
end

--- Снять задачу с паузы
function Timer.resume(task)
  if task then task.paused = false end
end

--- Проверить, активна ли задача
function Timer.isActive(task)
  return task and not task.cancelled
end

--- Найти задачу по id
function Timer.get(id)
  for _, t in ipairs(tasks) do
    if t.id == id then return t end
  end
end

-- ============================================================
--  Глобальная пауза
-- ============================================================

function Timer.pauseAll()  paused = true  end
function Timer.resumeAll() paused = false end

-- ============================================================
--  Обновление (вызывать в love.update(dt))
-- ============================================================

function Timer.update(dt)
  if paused then return end

  for i = #tasks, 1, -1 do
    local t = tasks[i]

    -- Удаление отменённых
    if t.cancelled then
      table.remove(tasks, i)
    elseif not t.paused then
      t.time    = t.time - dt
      t.elapsed = t.elapsed + dt

      if t.time <= 0 then
        -- Защита от ошибок в callback
        local ok, err = pcall(t.callback, t)
        if not ok then
          print("[Timer] Ошибка в callback #" .. t.id .. ": " .. tostring(err))
        end

        if t.repeating and not t.cancelled then
          if t.remaining then
            t.remaining = t.remaining - 1
            if t.remaining <= 0 then
              if t.onFinish then t.onFinish(t) end
              table.remove(tasks, i)
            else
              t.time = t.time + t.interval
            end
          else
            t.time = t.time + t.interval
          end
        else
          if t.onFinish then t.onFinish(t) end
          table.remove(tasks, i)
        end
      end
    end
  end
end

-- ============================================================
--  Очистка
-- ============================================================

--- Сбросить все таймеры
function Timer.clear()
  for _, t in ipairs(tasks) do
    t.cancelled = true
  end
  tasks = {}
  paused = false
end

--- Получить количество активных задач
function Timer.count()
  return #tasks
end

return Timer