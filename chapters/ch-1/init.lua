-- chapters/ch-1/init.lua

local Dialog = assert(love.filesystem.load(
  "chapters/ch-1/helpers/dialog.lua"))()

local Fade  = require("helpers.fade")
local Timer = require("helpers.timer")

local chapter = {}

local prevMode = nil

-- ============================================================
-- ФОНЫ
-- ============================================================

local BG_DIR = "chapters/ch-1/assets/bg/"

local bgList = {
  apteka1         = "apteka1.png",
  apteka2         = "apteka2.png",
  dom_iznutri     = "dom_iznutri.png",
  spalnya_bratiev = "spalnya_bratiev.png",
}

local bgCache = {}
local bgImage = nil   -- текущий фон

local function getBg(name)
  if bgCache[name] ~= nil then return bgCache[name] end
  local path = BG_DIR .. (bgList[name] or name)
  local ok, img = pcall(love.graphics.newImage, path)
  if ok then
    bgCache[name] = img
  else
    bgCache[name] = false
    print("[ch-1] Не удалось загрузить фон: " .. path)
  end
  return bgCache[name]
end

--- Мгновенно поставить фон
local function setBg(name)
  local img = getBg(name)
  if img then bgImage = img end
end

--- Плавно сменить фон: fadeOut -> смена -> fadeIn -> onDone
local function changeBg(name, duration, onDone)
  duration = duration or 0.8
  Fade.fadeOut(duration, function()
    setBg(name)
    Fade.fadeIn(duration, onDone)
  end)
end

-- ============================================================
-- СЦЕНАРИЙ
-- ============================================================

-- ------------------------------------------------------------
-- СЦЕНА 1
-- ------------------------------------------------------------
local function firstScene()
  Dialog.start({
    { text = "<speed 15>1880 ГОД." },
    { text = "Ох, <delay 0.4>интересный же год был!" },
    { text = "<speed 18>Фёдор Достоевский произнёс свою знаменитую фразу о Пушкине... <delay 0.2><speed 15>Завершилась Вторая <speed 12>англо-афганская война, <speed 10>началась Первая <speed 8>англо-бурская война..." },
    { text = "<speed 3>..." },
    { text = "Ну, <delay 0.4>зато 27 сентября родился Жак Тибо, <delay 0.4>французский скрипач. <delay 0.2><speed 10>Хоть что-то." },
    { text = "<speed 17>Ладно, <delay 0.4>Вы, <delay 0.4>как я вижу, <delay 0.4>собрались на другое торжество посмотреть, <delay 0.5>верно?" },
    { choices = {
        { text = "Да, конечно.",                     onClick = function() print("[ch-1] Выбор: да")  end },
        { text = "Да не, я историю забыл сделать.",  onClick = function() print("[ch-1] Выбор: нет") end },
    } },
    { text = "<speed 16>Что бы Вы не сказали, <delay 0.4>я всё равно расскажу Вам о том, <delay 0.4>как зародилась целая империя всего из 1 пары" },
  }, function()
    print("[ch-1] Сцена 1 завершена")
    secondScene()
  end)
end

-- ------------------------------------------------------------
-- СЦЕНА 2
-- ------------------------------------------------------------
function secondScene()
  
    Dialog.start({
      { text = "<speed 15>РОССИЙСКАЯ ИМПЕРИЯ, <delay 0.5>ДЕРПТ. <delay 0.5>12 ОКТЯБРЯ 1880 ГОДА." },
      { text = "<speed 18>Это был самый обыкновенный день, <delay 0.5>где-то час дня, <delay 0.5>как вдруг..." },
      { text = "<speed 18>На улице появилась женщина. <delay 0.5>На вид лет двадцати. <delay 0.5>Она была немкой. <delay 0.5>Несла на руках новорождённого ребёнка в пелёнках.",
        portrait = "chapters/ch-1/assets/characters/mom/baby-start.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "Она прижимала ребёнка к себе и нежно улыбалась.",
        portrait = "chapters/ch-1/assets/characters/mom/baby-start.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 16>Мимо тянулись дрожки, <delay 0.5>где-то лаяла собака, <delay 0.5>пахло сырым камнем и дымом. <delay 0.6>Обычный день. <delay 0.5>Никто и не глянул бы на неё дважды.",
        portrait = "chapters/ch-1/assets/characters/mom/baby-start.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Женщина",
        text = "<wave><speed 18>Хм..</wave>",
        portrait = "chapters/ch-1/assets/characters/mom/baby-start.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 17>Она остановилась у витрины аптеки своего отца, <delay 0.5>поправила пелёнку, <delay 0.5>и тихо, <delay 0.4>одними губами, <delay 0.4>что-то прошептала ребёнку по-немецки.",
        portrait = "chapters/ch-1/assets/characters/mom/baby-start.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "И тут... <delay 0.5>Подошёл мужчина.",
        portrait = "chapters/ch-1/assets/characters/dad/looking1.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "Лет ему было около тридцати, <delay 0.8>по внешности был с виду русским. <delay 0.8>Он удивлённо фыркнул, <delay 0.8>голос у него был глубоким и низким.",
        portrait = "chapters/ch-1/assets/characters/dad/looking1.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 16>Он перекрестился на купол вдалеке, <delay 0.5>и только потом подошёл ближе.",
        portrait = "chapters/ch-1/assets/characters/dad/looking1.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Мужчина",
        text = "<speed 18>Ну и как ты его назовёшь? <delay 0.5>Мне вот больше Дмитрий нравится.",
        portrait = "chapters/ch-1/assets/characters/dad/looking1.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Женщина",
        text = "<speed 17>Дмитрий... <delay 0.6>Это по-вашему, <delay 0.4>по-русски. <delay 0.6>А я хочу, <delay 0.4>чтобы у него было и моё тоже.",
        portrait = "chapters/ch-1/assets/characters/mom/baby-start.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Мужчина",
        text = "<speed 18>И моё, и твоё - <delay 0.5>так не бывает. <delay 0.6>Одно имя дают, <delay 0.4>одно. <delay 0.5>Перед Богом.",
        portrait = "chapters/ch-1/assets/characters/dad/looking1.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Женщина",
        text = "Мне нравится больше Дитрих... <delay 0.8>Может быть... <delay 0.5>Дитрихом всё-таки назовём?",
        portrait = "chapters/ch-1/assets/characters/mom/baby-start2.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Мужчина",
        text = "<speed 20>Дитрих... <delay 0.6><wave>Дитрих.</wave>",
        portrait = "chapters/ch-1/assets/characters/dad/looking1.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Мужчина",
        text = "<speed 25>Да что же за имя-то такое неправославное?! <delay 0.4>Крестить же надо!",
        portrait = "chapters/ch-1/assets/characters/dad/looking2.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Мужчина",
        text = "Ты слышишь себя вообще? <delay 0.6>Глупое имя какое-то...",
        portrait = "chapters/ch-1/assets/characters/dad/looking2.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Женщина",
        text = "<speed 17><wave>Не смей так говорить!</wave> <delay 0.6>Это имя моего прадеда.. <delay 0.6>Оно честное!..",
        portrait = "chapters/ch-1/assets/characters/mom/baby_sad.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Мужчина",
        text = "Ох, <delay 0.6>прости, дорогая.",
        portrait = "chapters/ch-1/assets/characters/dad/so_sorry.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Женщина",
        text = "<speed 18>Крестить - <delay 0.4>да. <delay 0.6>Пусть Дмитрий будет... <delay 0.6>Но пусть дома я буду звать его как пожелаю! <delay 0.6>А так, сам привыкнет к имени собственному.",
        portrait = "chapters/ch-1/assets/characters/mom/baby-start2.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Мужчина",
        text = "<speed 17><wave>Господи, спаси и сохрани...</wave> <delay 0.6><speed 20>Ладно, <delay 0.4>пусть будет так! <delay 0.5><speed 17>Дай хотя бы лик сына узреть.",
        portrait = "chapters/ch-1/assets/characters/dad/dissapointed.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Мужчина",
        text = "<speed 30>А ну-ка, <delay 0.5>дай мне его сюда!",
        portrait = "chapters/ch-1/assets/characters/mom/baby_sad.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Женщина",
        text = "<speed 20><wave>Фридрих!</wave>",
        portrait = "chapters/ch-1/assets/characters/mom/sad.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { name = "Фёдор (Фридрих)",
        text = "<speed 20>Какой я тебе <wave>Фридрих</wave>? <delay 0.5>Фёдор имя мне! <delay 0.5>Сто и один раз повторял тебе!",
        portrait = "chapters/ch-1/assets/characters/dad/baby_hold.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
    }, function()
      print("[ch-1] Сцена 2 завершена")
      thirdScene()
    end)
  
end

-- ------------------------------------------------------------
-- СЦЕНА 3
-- ------------------------------------------------------------
function thirdScene()
  changeBg("dom_iznutri", 1.0, function()
    Dialog.start({
      { text = "<speed 15>И всё-таки назвали сына Дмитрием. <delay 0.5>Так велела церковь да законы нынешние. <delay 0.5>Но матери было всё равно, <delay 0.4>она называла его Дитрихом." },
      { text = "<speed 15>Так имя и прижилось." },
      { text = "<speed 15>Кстати..." },
      { text = "<speed 15>Думаю, <delay 0.5>время Вам поведовать о том, <delay 0.5>кто есть кто." },
      { text = "<speed 23>Очень... <delay 0.5><speed 15>Познавательно будет, <delay 0.5>поверьте." },
      { text = "<speed 15>Как вы поняли из прошлой сцены, <delay 0.5>данного мужчину зовут... <delay 1.0>Фёдор.",
        portrait = "chapters/ch-1/assets/characters/dad/looking1.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 15>А, ой! <delay 0.5>Хорошо-хорошо! <delay 0.5>Не просто Фёдор, <delay 0.4>а Шмидт Фёдор Иванович!",
        portrait = "chapters/ch-1/assets/characters/dad/looking2.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 15>Вот... <delay 0.5>Довольны?",
        portrait = "chapters/ch-1/assets/characters/dad/looking1.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 15>В общем, <delay 0.5>человек верующий, <delay 0.5>родился 22 апреля 1848 года, в Санкт-Петербурге. <delay 0.5>Позднее переехал в Дерпт ради любви, <delay 0.5>так как сама она не могла приехать, <delay 0.5>да и в то время была зависима от отца и его аптеки.",
        portrait = "chapters/ch-1/assets/characters/dad/looking1.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 15>Также он крайне консервативен и строг, <delay 0.5>но искренне любит свою жену, <delay 0.5>хоть и причуды её ему не всегда угодны.",
        portrait = "chapters/ch-1/assets/characters/dad/looking1.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
        { text = "<speed 15>Ещё, <delay 0.5>он крайне упрямый. <delay 0.5>Зачастую стоит на своём, даже если проиграл. <delay 0.5>Уходит с лицом победителя, <delay 0.5>так сказать.",
        portrait = "chapters/ch-1/assets/characters/dad/looking1.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 15>Дальше у нас... <delay 0.7>Генриетта Вильгельмина.",
        portrait = "chapters/ch-1/assets/characters/mom/zadumchivost.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 15>Или же, <delay 0.5>по документам, <delay 0.5>Шмидт Генриетта Генриховна.",
        portrait = "chapters/ch-1/assets/characters/mom/zadumchivost.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 15>Жёнушка Фёдора, <delay 0.5>или, <delay 0.5>как она его называет, <delay 0.5>Фридрих.",
        portrait = "chapters/ch-1/assets/characters/mom/zadumchivost.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 15>По сути своей умная, добрая, <delay 0.5>но готовая заступиться за себя и близких в моменте. <delay 0.5>Она пытается бороться с предрассудками, <delay 0.5>но время, <delay 0.5>так сказать, <delay 0.5>не её.",
        portrait = "chapters/ch-1/assets/characters/mom/zadumchivost.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
      { text = "<speed 15>Родилась 30 августа 1858 года. <delay 0.5>Вы удивитесь: <delay 0.5>«Что это за разница в возрасте?! <delay 0.5>Как это так?» <delay 0.5>Но тогда это было <wave>абсолютно</wave> нормально.",
        portrait = "chapters/ch-1/assets/characters/mom/zadumchivost.png",
        portraitMode = "fit",
        portraitW = 300, portraitH = 288,
        portraitAlign = "topleft",
        portraitOffsetX = 20, portraitOffsetY = -285 },
    }, function()
      print("[ch-1] Сцена 3 завершена")
      -- Здесь позже можно запустить fourthScene()
      -- fourthScene()
    end)
  end)
end

-- ============================================================
-- LÖVE CALLBACKS
-- ============================================================

function chapter.load()
  local w, h, flags = love.window.getMode()
  prevMode = {
    width      = w,
    height     = h,
    fullscreen = love.window.getFullscreen(),
    flags      = flags,
  }

  love.window.setMode(1080, 720, {
    fullscreen = true,
    borderless = false,
    resizable  = false,
    vsync      = 1,
    msaa       = 0,
    centered   = true,
  })

  -- Кэш фонов и стартовый фон
  setBg("apteka1")

  -- Старт с чёрного экрана, затем плавное появление и первая сцена
  Fade.set(1)
  Fade.fadeIn(1.5, function()
    firstScene()
  end)
end

function chapter.update(dt)
  Fade.update(dt)
  Dialog.update(dt)
end

function chapter.draw()
  if bgImage then
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local iw, ih = bgImage:getWidth(), bgImage:getHeight()
    local scale  = math.max(sw / iw, sh / ih)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bgImage,
      (sw - iw * scale) / 2, (sh - ih * scale) / 2,
      0, scale, scale)
  else
    love.graphics.clear(0.1, 0.1, 0.12)
  end

  Dialog.draw()
  Fade.draw()
end

function chapter.mousepressed(x, y, b)
  if Fade.active then return end
  if Dialog.mousepressed(x, y, b) then return end
end

function chapter.mousemoved(x, y, dx, dy)
  if Fade.active then return end
  Dialog.mousemoved(x, y)
end

function chapter.mousereleased(x, y, b)
  -- если понадобится — обработка отпускания мыши
end

function chapter.keypressed(key)
  if Fade.active then return end
  if Dialog.keypressed(key) then return end
end

function chapter.unload()
  Dialog.reset()
  Fade.cancel()

  bgCache = {}
  bgImage = nil

  if prevMode then
    love.window.setMode(prevMode.width, prevMode.height, {
      fullscreen = prevMode.fullscreen,
      borderless = true,
      resizable  = false,
      vsync      = 1,
      msaa       = 0,
    })
    prevMode = nil
  end
end

return chapter