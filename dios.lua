local cfg = CONFIG or _G.CONFIG or {}

local WEBHOOK_URL         = cfg.WEBHOOK_URL or "https://discord.com/api/webhooks/1503455298742915293/2ZpPAgFHwmB9VnyBSpua1rNlZ799BFda7qxGI7dqIsyAUgYJKL5W7kNYDDO8CW3Fd3Ui"
local ENABLE_WEBHOOK      = (cfg.ENABLE_WEBHOOK ~= nil and cfg.ENABLE_WEBHOOK) or true
local HUMAN_DELAY_MIN     = cfg.HUMAN_DELAY_MIN or 180
local HUMAN_DELAY_MAX     = cfg.HUMAN_DELAY_MAX or 270
local MAX_CONCURRENT_BOTS = cfg.MAX_CONCURRENT_BOTS or 10
local SCRIPT_RAW_URL      = cfg.RAW_URL or "https://raw.githubusercontent.com/YagizDemirTR/Gtpr/refs/heads/main/dios.lua"

local BOTS_LIST           = cfg.BOTS_LIST or [[
]]
local BOTS_FILE           = cfg.BOTS_FILE or "bots.txt"
local QUEUE_FILE          = cfg.QUEUE_FILE or "level_queue.txt"
local COMPLETED_FILE      = cfg.COMPLETED_FILE or "level_completed.txt"

local FARM_FILE           = cfg.FARM_FILE or "farm.txt"
local SEED_STORAGE_WORLD  = cfg.SEED_STORAGE_WORLD or "sunwokok:shit"
local SEED_STORAGE_FILE   = cfg.SEED_STORAGE_FILE or "seed_storage.txt"
local PACK_STORAGE_FILE   = cfg.PACK_STORAGE_FILE or "pack_storage.txt"
local SEED_ID             = cfg.SEED_ID or 955
local MAX_LEVEL           = cfg.MAX_LEVEL or 12

local HARVEST_INTERVAL    = cfg.HARVEST_INTERVAL or 0.18
local BREAK_INTERVAL      = cfg.BREAK_INTERVAL or 0.20
local PLANT_INTERVAL      = cfg.PLANT_INTERVAL or 0.17
local WARP_INTERVAL       = cfg.WARP_INTERVAL or 12

function log(txt, b)
    local name = "Bot"
    pcall(function()
        if b and b.name then name = b.name end
    end)
    print("[" .. name .. "] " .. txt)
end

function sendLogWebhook(text)
    if not ENABLE_WEBHOOK or WEBHOOK_URL == "" or WEBHOOK_URL == "YOUR_WEBHOOK_URL_HERE" then return end
    pcall(function()
        local wh = Webhook.new(WEBHOOK_URL)
        wh.username = "Level-Logs"
        wh.content = text
        wh:send()
    end)
end

function fetchUrlContent(url)
    if not url or url == "" then return "" end
    local content = ""
    pcall(function()
        local client = HttpClient.new()
        client.url = url
        if Method and Method.get then
            client:setMethod(Method.get)
        end
        local res = client:request()
        if res and res.body and res.body ~= "" then
            content = res.body
        end
    end)
    return content
end

function safeRead(filePath)
    local content = ""
    pcall(function()
        content = read(filePath) or ""
    end)
    return content
end

function safeWrite(filePath, content)
    local ok = false
    pcall(function()
        write(filePath, content)
        ok = true
    end)
    return ok
end

function safeAppend(filePath, content)
    local ok = false
    pcall(function()
        append(filePath, content)
        ok = true
    end)
    return ok
end

function getTargetBot()
    if type(getBot) == "function" then
        local ok, b = pcall(getBot)
        if ok and b then return b end
    end
    return nil
end

function getBotStatusString(status)
    if not status then return "Unknown" end
    if status == BotStatus.online then return "Online" end
    if status == BotStatus.offline then return "Offline" end
    if status == BotStatus.account_banned then return "Account Banned" end
    if status == BotStatus.location_banned then return "Location Banned" end
    if status == BotStatus.account_restricted then return "Account Restricted" end
    if status == BotStatus.wrong_password then return "Wrong Password" end
    if status == BotStatus.invalid_account then return "Invalid Account" end
    if status == BotStatus.bypassing_server_data then return "Bypassing Server Data" end
    if status == BotStatus.getting_server_data then return "Getting Server Data" end
    if status == BotStatus.changing_subserver then return "Changing Subserver" end
    if status == BotStatus.captcha_requested then return "Captcha Requested" end
    if status == BotStatus.too_many_login then return "Too Many Logins" end
    if status == BotStatus.maintenance then return "Maintenance" end
    if status == BotStatus.server_overload then return "Server Overload" end
    if status == BotStatus.server_busy then return "Server Busy" end
    if status == BotStatus.error_connecting then return "Error Connecting" end
    if status == BotStatus.logon_fail then return "Logon Fail" end
    if status == BotStatus.high_load then return "High Load" end
    if status == BotStatus.high_ping then return "High Ping" end
    if status == BotStatus.stopped then return "Stopped" end
    return tostring(status)
end

function findItem(b, id)
    local count = 0
    pcall(function()
        local inv = b:getInventory()
        if inv then count = inv:findItem(id) or 0 end
    end)
    return count
end

function getLockTile(b)
    local lx, ly = nil, nil
    pcall(function()
        local world = b:getWorld()
        if world then
            local tiles = world:getTilesSafe()
            if tiles then
                for _, tile in pairs(tiles) do
                    if tile.fg == 9640 then
                        lx = tile.x
                        ly = tile.y
                        break
                    end
                end
            end
        end
    end)
    return lx, ly
end

function wrenchWl(b, x, y)
    sleep(math.random(800, 1500))
    pcall(function() b:wrench(x, y) end)
    sleep(math.random(1000, 1500))

    pcall(function()
        b:sendPacket(2,
            "action|dialog_return\n" ..
            "dialog_name|lock_edit\n" ..
            "tilex|" .. x .. "|\n" ..
            "tiley|" .. y .. "|\n" ..
            "checkbox_public|0\n" ..
            "checkbox_disable_music|0\n" ..
            "tempo|100\n" ..
            "checkbox_disable_music_render|0\n" ..
            "buttonClicked|set_as_home_world"
        )
    end)

    sleep(math.random(1000, 1500))
    log("Set as home world success", b)
end

function generateRandomWorld()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local str = ""
    for i = 1, 8 do
        local idx = math.random(1, #chars)
        str = str .. chars:sub(idx, idx)
    end
    return str
end

function hasOtherPlayers(b)
    local found = false
    pcall(function()
        local world = b:getWorld()
        if world then
            local players = world:getPlayers()
            if players then
                for _, player in pairs(players) do
                    if not player.isLocalPlayer and player.name:lower() ~= b.name:lower() then
                        found = true
                        break
                    end
                end
            end
        end
    end)
    return found
end

function findStandablePosition(b, world, tx, ty)
    local offsets = {
        { x = tx,     y = ty - 1 },
        { x = tx - 1, y = ty     },
        { x = tx + 1, y = ty     },
        { x = tx,     y = ty + 1 }
    }

    for _, pos in ipairs(offsets) do
        local isFree = false
        pcall(function()
            local t = world:getTile(pos.x, pos.y)
            if t and t.fg == 0 then
                isFree = true
            end
        end)
        if isFree then
            return pos.x, pos.y
        end
    end

    for _, pos in ipairs(offsets) do
        local isValid = false
        pcall(function()
            local t = world:getTile(pos.x, pos.y)
            if t and t.fg ~= 10 and t.fg ~= 6 and t.fg ~= 9640 and t.fg ~= 242 and t.fg ~= 3760 then
                isValid = true
            end
        end)
        if isValid then
            return pos.x, pos.y
        end
    end

    return tx, ty - 1
end

function getBotPos(b)
    local bx, by = -1, -1
    pcall(function()
        if b.x and b.y then
            local rawX = b.x
            local rawY = b.y
            if rawX > 100 or rawY > 100 then
                bx = math.floor(rawX / 32)
                by = math.floor(rawY / 32)
            else
                bx = math.floor(rawX)
                by = math.floor(rawY)
            end
        end
    end)
    return bx, by
end

function breakBlockAt(b, world, x, y)
    local hitCount = 0
    local maxHits = 15
    
    while hitCount < maxHits do
        if hasOtherPlayers(b) then
            return false
        end

        local shouldStop = false
        pcall(function()
            local t = world:getTile(x, y)
            if not t then shouldStop = true return end
            if t.fg == 10 or t.fg == 6 or t.fg == 9640 or t.fg == 242 or t.fg == 3760 then shouldStop = true return end
            if t.fg ~= 2 and t.bg ~= 14 then shouldStop = true return end
        end)

        if shouldStop then break end

        hitCount = hitCount + 1
        pcall(function() b:hit(x, y) end)
        sleep(math.random(HUMAN_DELAY_MIN, HUMAN_DELAY_MAX))
    end

    if hitCount > 0 then
        log(string.format("Cleared tile (%d, %d)", x, y), b)
    end

    return true
end

function clearSingleWorld(b)
    local world = nil
    pcall(function() world = b:getWorld() end)
    if not world then return "INVALID_WORLD" end

    local wName = ""
    pcall(function() wName = world.name end)
    if wName:lower() == "exit" then return "INVALID_WORLD" end

    local bName = "bot"
    pcall(function() if b and b.name then bName = b.name:lower() end end)
    local botTxtFile = bName .. ".txt"

    pcall(function() write(botTxtFile, wName) end)
    log("Clearing world: " .. wName, b)

    local tiles = nil
    pcall(function() tiles = world:getTilesSafe() end)
    if not tiles then return "INVALID_WORLD" end

    for _, tile in pairs(tiles) do
        local botLevel = 1
        pcall(function() botLevel = b.level or 1 end)
        if botLevel >= 7 then
            log("Level 7 reached!", b)
            return "LEVEL_7"
        end

        if hasOtherPlayers(b) then
            log("Player detected! Leaving world...", b)
            pcall(function() b:leaveWorld() end)
            sleep(2000)
            return "PLAYER_DETECTED"
        end

        local currentTile = tile
        pcall(function()
            local t = world:getTile(tile.x, tile.y)
            if t then currentTile = t end
        end)

        local fg = currentTile.fg or 0
        local bg = currentTile.bg or 0
        local isIndestructible = (fg == 10 or fg == 6 or fg == 9640 or fg == 242 or fg == 3760)

        if not isIndestructible and (fg == 2 or bg == 14) then
            local botX, botY = getBotPos(b)

            if not (botX ~= -1 and math.abs(botX - currentTile.x) <= 2 and math.abs(botY - currentTile.y) <= 2) then
                local sides = {
                    { x = currentTile.x,     y = currentTile.y - 1 },
                    { x = currentTile.x - 1, y = currentTile.y     },
                    { x = currentTile.x + 1, y = currentTile.y     },
                    { x = currentTile.x,     y = currentTile.y + 1 }
                }

                local reached = false
                for _, side in ipairs(sides) do
                    pcall(function() b:findPath(side.x, side.y) end)
                    sleep(math.random(150, 250))
                    
                    botX, botY = getBotPos(b)
                    if botX ~= -1 and math.abs(botX - currentTile.x) <= 2 and math.abs(botY - currentTile.y) <= 2 then
                        reached = true
                        break
                    end
                end

                if not reached then
                    local standX, standY = findStandablePosition(b, world, currentTile.x, currentTile.y)
                    pcall(function() b:findPath(standX, standY) end)
                    sleep(math.random(200, 350))
                end
            end

            if not breakBlockAt(b, world, currentTile.x, currentTile.y) then
                log("Player detected while breaking! Leaving...", b)
                pcall(function() b:leaveWorld() end)
                sleep(2000)
                return "PLAYER_DETECTED"
            end
        end
    end

    sendLogWebhook("Cleared world: " .. wName)
    return "CLEARED"
end

function clearUntilLevel7(b)
    while true do
        local botLevel = 1
        pcall(function() botLevel = b.level or 1 end)
        if botLevel >= 7 then break end

        local res = clearSingleWorld(b)

        if res == "LEVEL_7" then break end

        if res == "CLEARED" or res == "PLAYER_DETECTED" or res == "INVALID_WORLD" then
            local lvl = 1
            pcall(function() lvl = b.level or 1 end)
            if lvl < 7 then
                local newWorld = generateRandomWorld()
                log("Warping to new random world: " .. newWorld, b)
                pcall(function() b:warp(newWorld) end)
                sleep(math.random(4500, 7000))
            end
        end
    end
end

function warpToWorld(b, targetWorld)
    local wName, doorId = targetWorld:match("^([^:|]+)[:|]?(.*)$")
    if not wName or wName == "" then wName = targetWorld end
    if not doorId then doorId = "" end
    wName = wName:gsub("%s+", "")
    doorId = doorId:gsub("%s+", "")

    for attempt = 1, 6 do
        pcall(function()
            if b.status ~= BotStatus.online then
                b:connect()
                sleep(3000)
            end
        end)

        local inTarget = false
        pcall(function()
            if b:isInWorld(wName) then
                inTarget = true
            else
                local w = b:getWorld()
                if w and w.name and w.name:lower() == wName:lower() then
                    inTarget = true
                end
            end
        end)

        if inTarget then
            log(string.format("Already in target world: %s", wName), b)
            return true
        end

        log(string.format("Warping to storage: %s (attempt %d/6)...", targetWorld, attempt), b)
        pcall(function()
            if doorId ~= "" then
                b:warp(wName, doorId)
            else
                b:warp(wName)
            end
        end)

        sleep(math.random(5000, 7000))

        pcall(function()
            if b:isInWorld(wName) then
                inTarget = true
            else
                local w = b:getWorld()
                if w and w.name and w.name:lower() == wName:lower() then
                    inTarget = true
                end
            end
        end)

        if inTarget then
            log(string.format("Successfully arrived at storage world: %s", wName), b)
            return true
        end
    end

    log("Failed to enter storage world " .. targetWorld .. " after 6 attempts.", b)
    return false
end

function dropSeedsToStorage(b)
    local seedCount = findItem(b, SEED_ID)
    log(string.format("Checking inventory for Seed ID %d: %d seed(s) found.", SEED_ID, seedCount), b)

    if seedCount <= 0 then
        log("No seeds found in inventory to drop. Skipping storage drop.", b)
        return
    end

    local targetStorage = SEED_STORAGE_WORLD
    if not targetStorage or targetStorage == "" then
        local seedContent = safeRead(SEED_STORAGE_FILE)
        if seedContent and seedContent ~= "" then
            for line in seedContent:gmatch("[^\r\n]+") do
                line = line:match("^%s*(.-)%s*$")
                if line ~= "" and not line:match("^#") then
                    targetStorage = line
                    break
                end
            end
        end
    end

    if not targetStorage or targetStorage == "" then
        log("No seed storage world defined in SEED_STORAGE_WORLD or " .. SEED_STORAGE_FILE .. "! Cannot drop seeds.", b)
        return
    end

    log(string.format("Going to drop %d seeds in storage world: %s", seedCount, targetStorage), b)

    local entered = warpToWorld(b, targetStorage)
    if not entered then
        log("Could not warp to storage world. Skipping drop.", b)
        return
    end

    sleep(2500)

    local dropAttempts = 0
    while findItem(b, SEED_ID) > 0 and dropAttempts < 10 do
        local count = findItem(b, SEED_ID)
        log(string.format("Dropping %d seed(s) on ground...", count), b)

        pcall(function() b:drop(SEED_ID, count) end)
        pcall(function() b:fastDrop(SEED_ID, count) end)

        sleep(1500)

        if findItem(b, SEED_ID) > 0 then
            pcall(function() b:moveRight(1) end)
            sleep(1000)
        end

        dropAttempts = dropAttempts + 1
    end

    local remaining = findItem(b, SEED_ID)
    if remaining == 0 then
        log("All seeds successfully dropped in storage world!", b)
        sendLogWebhook(string.format("[%s] Level %d reached. Dropped all seeds in %s.", b.name or "Bot", MAX_LEVEL, targetStorage))
    else
        log(string.format("Drop finished with %d seeds remaining.", remaining), b)
    end

    sleep(2000)
end

function startNativeRotationFarm(b)
    log("==================================================", b)
    log("LEVEL 7 REACHED! STARTING LUCIFER NATIVE ROTATION...", b)
    log("==================================================", b)

    local world_manager = getWorldManager()
    if not world_manager then
        log("ERROR: WorldManager not available!", b)
        return
    end

    local content = safeRead(FARM_FILE)
    if not content or content == "" then
        log("ERROR: " .. FARM_FILE .. " is empty or missing!", b)
        return
    end

    pcall(function() world_manager:unselectAll() end)

    local farmCount = 0
    for line in content:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then
            local formattedLine = line:gsub("|", ":")
            world_manager:addFarm(formattedLine, SEED_ID)
            farmCount = farmCount + 1
        end
    end
    log(string.format("Successfully added %d farm worlds to WorldManager with Seed ID %d.", farmCount, SEED_ID), b)

    local seedStorageCount = 0
    if SEED_STORAGE_WORLD and SEED_STORAGE_WORLD ~= "" then
        local formattedStorage = SEED_STORAGE_WORLD:gsub("|", ":")
        world_manager:addStorage(formattedStorage, StorageType.seed, SEED_ID)
        seedStorageCount = seedStorageCount + 1
        log(string.format("Added manual seed storage world: %s (Seed ID %d)", formattedStorage, SEED_ID), b)
    end

    local seedContent = safeRead(SEED_STORAGE_FILE)
    if seedContent and seedContent ~= "" then
        for line in seedContent:gmatch("[^\r\n]+") do
            line = line:match("^%s*(.-)%s*$")
            if line ~= "" and not line:match("^#") then
                local formattedLine = line:gsub("|", ":")
                if formattedLine ~= SEED_STORAGE_WORLD:gsub("|", ":") then
                    world_manager:addStorage(formattedLine, StorageType.seed, SEED_ID)
                    seedStorageCount = seedStorageCount + 1
                end
            end
        end
    end
    log(string.format("Total %d seed storage worlds added for Seed ID %d.", seedStorageCount, SEED_ID), b)

    local packStorageCount = 0
    local packContent = safeRead(PACK_STORAGE_FILE)
    if packContent and packContent ~= "" then
        for line in packContent:gmatch("[^\r\n]+") do
            line = line:match("^%s*(.-)%s*$")
            if line ~= "" and not line:match("^#") then
                local formattedLine = line:gsub("|", ":")
                world_manager:addStorage(formattedLine, StorageType.pack, 0)
                packStorageCount = packStorageCount + 1
            end
        end
        log(string.format("Successfully added %d pack storage worlds.", packStorageCount), b)
    end

    world_manager:selectAll()

    pcall(function()
        if b.status ~= BotStatus.online then
            b:connect()
            sleep(3000)
        end

        local rot = b.rotation
        if rot then
            rot.enabled              = true
            rot.visit_random_worlds  = true
            rot.dynamic_delay        = true
            rot.auto_leave_on_player = true
            rot.seed_drop_amount     = 200
            rot.harvest_interval     = HARVEST_INTERVAL
            rot.break_interval       = BREAK_INTERVAL
            rot.plant_interval       = PLANT_INTERVAL
            rot.warp_interval        = WARP_INTERVAL
            log("Native Rotation enabled with storage & optimized intervals for bot: " .. b.name, b)
        else
            log("ERROR: Rotation object not found on bot!", b)
        end
    end)

    log("Monitoring bot level... (Bot will drop seeds to storage and switch account at Level 12)", b)

    while true do
        sleep(5000)

        local lvl = 1
        pcall(function() lvl = b.level or 1 end)

        if lvl >= MAX_LEVEL then
            log(string.format("=================================================="), b)
            log(string.format("LEVEL %d REACHED! STOPPING ROTATION & DROPPING SEEDS...", lvl), b)
            log(string.format("=================================================="), b)

            pcall(function()
                if b.rotation then b.rotation.enabled = false end
            end)
            sleep(1500)

            dropSeedsToStorage(b)
            break
        else
            local isBanned = false
            pcall(function()
                if b.status == BotStatus.account_banned or b.status == BotStatus.location_banned or b.status == BotStatus.account_restricted then
                    isBanned = true
                end
            end)

            if isBanned then
                log("Bot detected as banned (" .. getBotStatusString(b.status) .. ") during rotation.", b)
                break
            end

            pcall(function()
                if b.status ~= BotStatus.online then
                    b:connect()
                    sleep(2000)
                end
                if b.rotation and not b.rotation.enabled then
                    b.rotation.enabled = true
                end
            end)
        end
    end
end

function initLevelQueue()
    local currentQueue = safeRead(QUEUE_FILE)
    if not currentQueue or currentQueue:match("^%s*$") then
        local count = 0
        local lines = {}

        if BOTS_LIST and BOTS_LIST ~= "" then
            for line in BOTS_LIST:gmatch("[^\r\n]+") do
                local trimmed = line:match("^%s*(.-)%s*$")
                if trimmed ~= "" and not trimmed:match("^#") and not trimmed:match("^//") then
                    table.insert(lines, trimmed)
                    count = count + 1
                end
            end
        end

        if count == 0 and BOTS_FILE and BOTS_FILE ~= "" then
            local fileContent = safeRead(BOTS_FILE)
            if fileContent and fileContent ~= "" then
                for line in fileContent:gmatch("[^\r\n]+") do
                    local trimmed = line:match("^%s*(.-)%s*$")
                    if trimmed ~= "" and not trimmed:match("^#") and not trimmed:match("^//") then
                        table.insert(lines, trimmed)
                        count = count + 1
                    end
                end
            end
        end

        if count > 0 then
            safeWrite(QUEUE_FILE, table.concat(lines, "\n"))
            log(string.format("Level queue initialized with %d account(s) (%s)", count, QUEUE_FILE))
        end
    end
end

function claimNextAccount(workerName)
    sleep(math.random(150, 750))

    local content = safeRead(QUEUE_FILE)
    if not content or content:match("^%s*$") then
        return nil, 0
    end

    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" and not trimmed:match("^#") and not trimmed:match("^//") then
            table.insert(lines, trimmed)
        end
    end

    if #lines == 0 then
        return nil, 0
    end

    local claimed = lines[1]
    table.remove(lines, 1)

    safeWrite(QUEUE_FILE, table.concat(lines, "\n"))

    return claimed, #lines
end

function parseAccountPayload(accountLine)
    accountLine = accountLine:match("^%s*(.-)%s*$")
    if not accountLine or accountLine == "" then return nil end

    local platformID = 0
    if Platform and Platform.windows ~= nil then
        platformID = Platform.windows
    end

    local email, sisa = accountLine:match("([^|]+)|(.+)")
    if email and sisa then
        local mac, rid, wk, ltoken = sisa:match("([^:]+):([^:]+):([^:]+):(.+)")
        if mac and rid and wk and ltoken then
            return {
                ["display"]  = email,
                ["secret"]   = email,
                ["name"]     = ltoken,
                ["rid"]      = rid,
                ["mac"]      = mac,
                ["wk"]       = wk,
                ["platform"] = platformID,
            }
        end
    else
        local mac, rid, wk, ltoken = accountLine:match("([^:]+):([^:]+):([^:]+):(.+)")
        if mac and rid and wk and ltoken then
            return {
                ["name"]     = ltoken,
                ["rid"]      = rid,
                ["mac"]      = mac,
                ["wk"]       = wk,
                ["platform"] = platformID,
            }
        end
    end

    return nil
end

function switchBotAccount(b, accountLine)
    accountLine = accountLine:match("^%s*(.-)%s*$")
    if not accountLine or accountLine == "" or accountLine:match("^#") or accountLine:match("^//") then
        return false
    end

    log("Updating current bot to account: " .. accountLine, b)

    pcall(function() b:disconnect() end)
    sleep(1500)

    local payload = parseAccountPayload(accountLine)

    if payload then
        pcall(function() b:updateBot(payload) end)
        pcall(function()
            if payload.name then b:updateBot(payload.name) end
            if payload.mac then b:setMac(payload.mac) end
            if payload.rid then b:setRid(payload.rid) end
        end)
    else
        local u, p = accountLine:match("^([^:|]+)[:|](.+)$")
        if u and p then
            pcall(function() b:updateBot(u, p) end)
        else
            pcall(function() b:updateBot(accountLine) end)
        end
    end

    pcall(function()
        b.bypass_logon = true
        b.auto_reconnect = true
        if b.getConsole and b:getConsole() then
            b:getConsole().enabled = true
        end
    end)

    sleep(1500)
    log("Connecting with updated credentials...", b)
    pcall(function() b:connect() end)

    local maxWaitSeconds = 60
    local lastStatus = nil

    for second = 1, maxWaitSeconds do
        sleep(1000)

        local currentStatus = nil
        pcall(function() currentStatus = b.status end)

        if currentStatus ~= lastStatus then
            lastStatus = currentStatus
            local statusName = getBotStatusString(currentStatus)
            log(string.format("Status: %s (waiting %d/%ds)...", statusName, second, maxWaitSeconds), b)
        end

        if currentStatus == BotStatus.online then
            log("Bot is now ONLINE!", b)
            return true
        end

        if currentStatus == BotStatus.account_banned or
           currentStatus == BotStatus.location_banned or
           currentStatus == BotStatus.wrong_password or
           currentStatus == BotStatus.account_restricted or
           currentStatus == BotStatus.invalid_account then
            log("Permanent error detected (" .. getBotStatusString(currentStatus) .. ")! Skipping account: " .. accountLine, b)
            return false
        end

        if second % 15 == 0 and currentStatus == BotStatus.offline then
            log("Still offline, retrying connect...", b)
            pcall(function() b:connect() end)
        end
    end

    if b.status == BotStatus.online then
        return true
    else
        log("Connection timeout (60s). Final status: " .. getBotStatusString(b.status), b)
        return false
    end
end

function runBotLeveling(b)
    local botLevel = 1
    pcall(function() botLevel = b.level or 1 end)

    if botLevel < 7 then
        if findItem(b, 9640) == 0 then
            log("Bot does not have 9640 in inventory. Skipping /home warp.", b)
        else
            log("Warping home (/home) to start tutorial...", b)
            pcall(function() b:say("/home") end)
            sleep(3000)
        end

        local x, y = getLockTile(b)

        if not x then
            if findItem(b, 9640) > 0 then
                local bx, by = getBotPos(b)
                pcall(function() b:place(bx, by - 1, 9640) end)
                sleep(1000)

                x, y = getLockTile(b)

                if x then
                    log("9640 placed at " .. x .. "," .. y, b)
                    wrenchWl(b, x, y)
                else
                    log("Failed to detect placed 9640", b)
                end
            else
                log("9640 not found in inventory", b)
            end
        else
            log("9640 already at " .. x .. "," .. y, b)
            wrenchWl(b, x, y)
        end

        local res = clearSingleWorld(b)
        if res == "CLEARED" or res == "INVALID_WORLD" or res == "PLAYER_DETECTED" then
            local lvl = 1
            pcall(function() lvl = b.level or 1 end)
            if lvl < 7 then
                local newWorld = generateRandomWorld()
                log("Home world clean/done. Warping to new random world: " .. newWorld, b)
                pcall(function() b:warp(newWorld) end)
                sleep(math.random(4500, 7000))
                clearUntilLevel7(b)
            end
        elseif res ~= "LEVEL_7" then
            clearUntilLevel7(b)
        end
    end

    startNativeRotationFarm(b)
end

function getScriptSource()
    if SCRIPT_RAW_URL and SCRIPT_RAW_URL ~= "" then
        local remote = fetchUrlContent(SCRIPT_RAW_URL)
        if remote and remote ~= "" then
            log("Successfully fetched latest script from GitHub Raw URL!")
            return remote
        end
        log("Failed to fetch script from GitHub Raw URL. Trying local file...")
    end

    local scriptContent = safeRead("level.lua")
    if scriptContent == "" then scriptContent = safeRead("Scripts/level.lua") end
    return scriptContent
end

function serializeConfig(tbl)
    if not tbl or type(tbl) ~= "table" then return "" end
    local s = "CONFIG = {\n"
    for k, v in pairs(tbl) do
        if type(v) == "string" then
            s = s .. string.format("    [%q] = %q,\n", k, v)
        elseif type(v) == "number" or type(v) == "boolean" then
            s = s .. string.format("    [%q] = %s,\n", k, tostring(v))
        end
    end
    s = s .. "}\n\n"
    return s
end

function createBotInstance(account)
    local bot = nil
    local plat = 0
    pcall(function()
        if Platform and Platform.windows ~= nil then
            plat = Platform.windows
        end
    end)

    local payload = parseAccountPayload(account)
    if payload then
        pcall(function() bot = addBot(payload) end)
    end

    if not bot then
        pcall(function()
            bot = addBot({
                name = account,
                platform = plat,
                connect = false
            })
        end)
    end

    if not bot then
        pcall(function()
            bot = addBot({
                name = account,
                connect = false
            })
        end)
    end

    if not bot then
        local u, p = account:match("^([^:|]+)[:|](.+)$")
        if u and p then
            pcall(function() bot = addBot(u, p, "", "", plat) end)
            if not bot then pcall(function() bot = addBot(u, p) end) end
        else
            pcall(function() bot = addBot(account, "", "", "", plat) end)
            if not bot then pcall(function() bot = addBot(account) end) end
        end
    end

    if not bot then
        pcall(function() bot = getBot(account) end)
    end
    if not bot then
        pcall(function() bot = getBot() end)
    end

    return bot
end

function spawnAndExecuteWorkers()
    local scriptContent = getScriptSource()
    local fullScript = scriptContent
    if CONFIG or _G.CONFIG then
        fullScript = serializeConfig(CONFIG or _G.CONFIG) .. scriptContent
    end

    local queueContent = safeRead(QUEUE_FILE)
    local totalQueueCount = 0
    for line in queueContent:gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" and not trimmed:match("^#") and not trimmed:match("^//") then
            totalQueueCount = totalQueueCount + 1
        end
    end

    if totalQueueCount == 0 then
        log("No accounts found in queue to spawn bots.")
        return
    end

    local maxWorkers = MAX_CONCURRENT_BOTS or 10
    local toSpawn = math.min(maxWorkers, totalQueueCount)
    if toSpawn <= 0 then toSpawn = 1 end

    log(string.format("No active bot found! Auto-spawning %d bot(s) into Lucifer...", toSpawn))

    for i = 1, toSpawn do
        local account, remaining = claimNextAccount("AutoSpawner")
        if not account then break end

        local bot = createBotInstance(account)

        if bot then
            pcall(function()
                bot.bypass_logon = true
                bot.auto_reconnect = true
                if bot.getConsole and bot:getConsole() then
                    bot:getConsole().enabled = true
                end
                bot:connect()
            end)

            sleep(1000)

            if fullScript ~= "" then
                pcall(function()
                    bot:runScript(fullScript)
                end)
                log(string.format("Spawned & started level.lua on bot [%d/%d]: %s", i, toSpawn, bot.name or account))
            else
                log(string.format("Spawned bot [%d/%d]: %s (level.lua script content is empty)", i, toSpawn, bot.name or account))
            end
        else
            log(string.format("Failed to add bot for account: %s", account))
        end

        sleep(1500)
    end

    log("Auto-spawner completed launching all bot workers!")
end

function main()
    initLevelQueue()

    local b = getTargetBot()
    if not b then
        log("No parent bot detected. Starting Auto-Spawner mode...")
        spawnAndExecuteWorkers()
        return
    end

    local workerId = b.name or "Bot"
    log("Leveling worker started! Current Bot: " .. workerId, b)

    while true do
        local account, remaining = claimNextAccount(workerId)

        if not account then
            log("No more accounts left in queue. All accounts completed!", b)
            sendLogWebhook(string.format("[%s] Queue empty, all accounts leveled to %d!", workerId, MAX_LEVEL))
            break
        end

        log("==================================================", b)
        log(string.format(">>> [%s] CLAIMED ACCOUNT: %s (Remaining: %d)", workerId, account, remaining), b)
        log("==================================================", b)
        sendLogWebhook(string.format("[%s] Switching account: %s (Remaining: %d)", workerId, account, remaining))

        local success = switchBotAccount(b, account)

        if success then
            runBotLeveling(b)
            safeAppend(COMPLETED_FILE, account .. " (Completed by " .. workerId .. ")\n")
            log(string.format(">>> Account %s reached Level %d & dropped seeds to storage!", account, MAX_LEVEL), b)
        else
            log(string.format(">>> Account %s failed or banned (%s). Moving to next account...", account, getBotStatusString(b.status)), b)
            safeAppend(COMPLETED_FILE, account .. " (FAILED: " .. getBotStatusString(b.status) .. ")\n")
        end

        sleep(3000)
    end
end

main()
