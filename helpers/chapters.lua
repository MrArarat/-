-- helpers/chapters.lua
-- Сканирует папку chapters/ и загружает метаданные каждой главы.

local Chapters = {}

local CHAPTERS_DIR = "chapters"
local META_FILE    = "meta.lua"
local INIT_FILE    = "init.lua"

Chapters.list        = {}
Chapters.current     = nil
Chapters.currentMeta = nil

-- ============================================================
-- СКАНИРОВАНИЕ
-- ============================================================

function Chapters.scan()
  Chapters.list = {}

  local items = love.filesystem.getDirectoryItems(CHAPTERS_DIR)
  for _, name in ipairs(items) do
    local dir = CHAPTERS_DIR .. "/" .. name
    local info = love.filesystem.getInfo(dir)
    if info and info.type == "directory" then
      local metaPath = dir .. "/" .. META_FILE
      local chunk = love.filesystem.load(metaPath)
      if chunk then
        local ok, meta = pcall(chunk)
        if ok and type(meta) == "table" then
          meta._dir  = dir
          meta._name = name
          if not meta.id    then meta.id    = name  end
          if not meta.order then meta.order = 999   end
          if not meta.title then meta.title = name  end
          table.insert(Chapters.list, meta)
        else
          print("[chapters] Ошибка чтения meta: " .. metaPath .. " — " .. tostring(meta))
        end
      end
    end
  end

  table.sort(Chapters.list, function(a, b)
    if a.order ~= b.order then return a.order < b.order end
    return tostring(a.id) < tostring(b.id)
  end)
end

-- ============================================================
-- ЗАГРУЗКА / ВЫГРУЗКА
-- ============================================================

function Chapters.load(meta)
  if not meta then return false, "meta is nil" end
  if Chapters.current then
    if Chapters.current.unload then Chapters.current.unload() end
  end

  local path = meta._dir .. "/" .. INIT_FILE
  local chunk = love.filesystem.load(path)
  if not chunk then
    print("[chapters] Не найден файл: " .. path)
    return false, "init.lua not found"
  end

  local ok, chapter = pcall(chunk)
  if not ok then
    print("[chapters] Не удалось загрузить: " .. path .. " — " .. tostring(chapter))
    return false, chapter
  end

  Chapters.current     = chapter
  Chapters.currentMeta = meta
  if chapter.load then chapter.load(meta) end
  return true
end

function Chapters.unload()
  if Chapters.current and Chapters.current.unload then
    Chapters.current.unload()
  end
  Chapters.current     = nil
  Chapters.currentMeta = nil
end

return Chapters