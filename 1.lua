-- Title: New hud based smooth ESP by @HEXA CORE 
-- BRPlayerCharacterBase NEW ESP made by @HEXA CORE 
-- Simple Rectangle Kill Counter — RED (Real) + GREEN (Bot)
-- ESP Box WHITE + Full Bypass (Lua + Anogs + Ultimate)

_G.HEXA = _G.HEXA or "@HEXA CORE "
local HEXA_credit = _G.HEXA

local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {},
  LuaEventContainer = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }

local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local ESpecialMovementType = import("ESpecialMovementType")
local ESpiderSwingMoveState = import("ESpiderSwingMoveState")
local ESurviveWeaponPropSlot = import("ESurviveWeaponPropSlot")
local EParachuteState = import("EParachuteState")
local EMovementMode = import("EMovementMode")
local EStateType = import("EStateType")
local ESTEPoseState = import("ESTEPoseState")
local EGameModeType = import("EGameModeType")
local STExtraGameStateBase = import("STExtraGameStateBase")
local UKismetSystemLibrary = import("KismetSystemLibrary")
local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local MatchModeIds = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")

-- ============================================================================
-- 1. LICENSE CONFIG + CORE
-- ============================================================================
local MasterLicenseConfig = (function()
    return {
        url = 'https://key.authapi.xyz/server', game = 'BGMI',
        timeout = 10, clockSkew = 120, expiryPath = nil,
        manualExpiry = "2026-12-31 23:59:59", tamperTolerance = 5,
        secret = 'Vm8Lk7Uj2JmsjCPVPVjrLa7zgfx3uz5E',
    }
end)()

local MasterLicenseCore = (function()
    local Primitives = (function()
        local floor, abs, max = math.floor, math.abs, math.max
        local byte, char, format = string.byte, string.char, string.format
        local U32 = 4294967296
        local AND, XOR = {}, {}
        for a = 0, 15 do for b = 0, 15 do
            local av, bv, both, different, place = a, b, 0, 0, 1
            for _ = 1, 4 do
                local x, y = av % 2, bv % 2
                if x == 1 and y == 1 then both = both + place end
                if x ~= y then different = different + place end
                av, bv, place = floor(av / 2), floor(bv / 2), place * 2
            end
            AND[a * 16 + b], XOR[a * 16 + b] = both, different
        end end
        local function bitop(a, b, lookup)
            local value, place = 0, 1
            for _ = 1, 8 do
                value = value + lookup[(a % 16) * 16 + b % 16] * place
                a, b, place = floor(a / 16), floor(b / 16), place * 16
            end
            return value
        end
        local function band(a, b) return bitop(a, b, AND) end
        local function bxor(a, b) return bitop(a, b, XOR) end
        local function rol(value, amount)
            local divisor = 2 ^ (32 - amount)
            return (value % divisor) * 2 ^ amount + floor(value / divisor)
        end
        local function little32(value)
            return char(value % 256, floor(value / 256) % 256,
                floor(value / 65536) % 256, floor(value / 16777216) % 256)
        end
        local K = {
            0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,
            0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,0x6b901122,0xfd987193,0xa679438e,0x49b40821,
            0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,
            0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,
            0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,
            0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,
            0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,
            0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391
        }
        local SHIFT = {7,12,17,22,5,9,14,20,4,11,16,23,6,10,15,21}
        local function md5_raw(input)
            assert(type(input) == "string", "MD5 input must be a string")
            local size = #input
            local message = input .. char(128) .. string.rep(char(0), (55 - size) % 64)
                .. little32((size * 8) % U32) .. little32(floor(size / 536870912))
            local h0, h1, h2, h3 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
            local words = {}
            for offset = 1, #message, 64 do
                for j = 0, 15 do
                    local a, b, c, d = byte(message, offset + j * 4, offset + j * 4 + 3)
                    words[j] = a + b * 256 + c * 65536 + d * 16777216
                end
                local a, b, c, d = h0, h1, h2, h3
                for i = 0, 63 do
                    local f, g, shiftBase
                    if i < 16 then
                        f, g, shiftBase = band(b, c) + band(U32 - 1 - b, d), i, 0
                    elseif i < 32 then
                        f, g, shiftBase = band(d, b) + band(U32 - 1 - d, c), (5 * i + 1) % 16, 4
                    elseif i < 48 then
                        f, g, shiftBase = bxor(bxor(b, c), d), (3 * i + 5) % 16, 8
                    else
                        local bOrNotD = U32 - 1 - band(U32 - 1 - b, d)
                        f, g, shiftBase = bxor(c, bOrNotD), (7 * i) % 16, 12
                    end
                    local nextB = (b + rol((a + f + K[i + 1] + words[g]) % U32,
                        SHIFT[shiftBase + i % 4 + 1])) % U32
                    a, b, c, d = d, nextB, b, c
                end
                h0, h1, h2, h3 = (h0 + a) % U32, (h1 + b) % U32, (h2 + c) % U32, (h3 + d) % U32
            end
            return little32(h0) .. little32(h1) .. little32(h2) .. little32(h3)
        end
        local function hex(input)
            return (input:gsub(".", function(c) return format("%02x", byte(c)) end))
        end
        local function md5(input) return hex(md5_raw(input)) end
        local function form_encode(input)
            assert(type(input) == "string", "Form value must be a string")
            return (input:gsub("[^A-Za-z0-9%-%._~ ]", function(c)
                return format("%%%02X", byte(c)) end):gsub(" ", "+"))
        end
        local function constant_time_equal(a, b)
            if type(a) ~= "string" or type(b) ~= "string" then return false end
            local difference = abs(#a - #b)
            for i = 1, max(#a, #b) do
                difference = difference + abs((byte(a, i) or 0) - (byte(b, i) or 0))
            end
            return difference == 0
        end
        local function name_uuid(input)
            local digest = md5_raw(input)
            local h = hex(digest:sub(1,6) .. char(byte(digest,7) % 16 + 48)
                .. digest:sub(8,8) .. char(byte(digest,9) % 64 + 128) .. digest:sub(10))
            return h:sub(1,8) .. "-" .. h:sub(9,12) .. "-" .. h:sub(13,16)
                .. "-" .. h:sub(17,20) .. "-" .. h:sub(21,32)
        end
        return {md5 = md5, md5_raw = md5_raw, form_encode = form_encode,
                constant_time_equal = constant_time_equal, name_uuid = name_uuid}
    end)()

    local SESSION_KEY = '__MasterLicenseSession_v1'
    local function loadSession()
        local g = rawget(_G, SESSION_KEY)
        if type(g) ~= 'table' or g.authorized ~= true then return nil end
        if type(g.expiresAt) == 'number' and g.expiresAt <= os.time() then
            _G[SESSION_KEY] = nil; return nil
        end
        return g
    end
    local function saveSession(expiresAt)
        pcall(function()
            _G[SESSION_KEY] = {authorized = true, expiresAt = expiresAt, issuedAt = os.time()}
        end)
    end
    local function clearSession() pcall(function() _G[SESSION_KEY] = nil end) end

    local CreateLocalExpiry = (function()
        return function(cfg, wallReader)
            local E = {}
            local expiredText = 'Mod expired. DM @HEXA CORE for renewal.'
            local tamperText  = "Don't be over smart"
            local blockedMessage, blockedPhase
            local function finite(n)
                return type(n) == 'number' and n == n and n ~= math.huge and n ~= -math.huge
            end
            local function parse(text)
                if type(text) ~= 'string' then return nil end
                local y,m,d,h,n,s = text:match('^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d):(%d%d)$')
                y,m,d,h,n,s = tonumber(y),tonumber(m),tonumber(d),tonumber(h),tonumber(n),tonumber(s)
                if not y or y < 1970 or y > 9999 or m < 1 or m > 12 or h > 23 or n > 59 or s > 59 then return nil end
                local leap = y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)
                local months = {31, leap and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
                if d < 1 or d > months[m] then return nil end
                local prior = y - 1
                local days = 365 * (y - 1970) + math.floor(prior / 4) - math.floor(1969 / 4)
                    - math.floor(prior / 100) + math.floor(1969 / 100)
                    + math.floor(prior / 400) - math.floor(1969 / 400)
                for i = 1, m - 1 do days = days + months[i] end
                return (days + d - 1) * 86400 + h * 3600 + n * 60 + s - 6 * 3600
            end
            local configured = type(cfg.manualExpiry) == 'string'
                and cfg.manualExpiry:match('^%s*(.-)%s*$') or cfg.manualExpiry
            local expiry = parse(configured)
            local skew = cfg.clockSkew or 120
            if configured ~= nil and configured ~= '' and not expiry then
                blockedMessage, blockedPhase = 'Invalid local expiry date. Use YYYY-MM-DD HH:MM:SS.', 'error'
            end
            local function block(message, phase)
                if not blockedMessage then blockedMessage, blockedPhase = message, phase end
                return false, blockedMessage, blockedPhase
            end
            function E.Status() return not blockedMessage, blockedMessage, blockedPhase end
            function E.MarkTampered() return block(tamperText, 'tampered') end
            function E.GetExpiry() return expiry end
            function E.Accept(server, now, world, phone, rtt)
                if blockedMessage then return E.Status() end
                if not finite(server) or not finite(now) or now < 0 or world == nil
                    or not finite(rtt) or rtt < 0 or not finite(phone) then
                    return block('Clock verification unavailable.', 'error')
                end
                if math.abs(phone - server) > skew + rtt then return E.MarkTampered() end
                if expiry and server + rtt >= expiry then return block(expiredText, 'expired') end
                return true
            end
            return E
        end
    end)()

    local CreateAuth = (function()
        return function(P, cfg, deps)
            local A = {}
            local phase, message = 'locked', 'Enter your key to sign in.'
            local allowed, pending, generation = false, nil, 0
            local expiresAt
            local lastRequestLatencyMs, lastResponseTime, lastResponseWorld
            local startFn, stopFn, payloadStarted, restartRequired
            local localExpiry = deps.localExpiry
            do
                local stored = loadSession()
                if stored then
                    allowed = true; expiresAt = stored.expiresAt
                    phase, message = 'active', 'Session restored'
                end
            end
            if localExpiry then
                local ok, text, state = localExpiry.Status()
                if not ok then message, phase = text, state end
            end
            local function finite(n)
                return type(n) == 'number' and n == n and n ~= math.huge and n ~= -math.huge
            end
            local function readClock()
                local ok, n, w = pcall(deps.clock)
                if ok and finite(n) and n >= 0 and w ~= nil then return n, w end
            end
            local function notify(text, state)
                message, phase = text, state
                if type(deps.status) == 'function' then pcall(deps.status, text, state) end
            end
            local function stopPayload()
                if payloadStarted then
                    payloadStarted = false
                    local ok, accepted = pcall(stopFn)
                    if not ok or accepted == false then restartRequired = true end
                end
            end
            local function revoke(text, state)
                generation = generation + 1
                allowed, pending, expiresAt = false, nil, nil
                lastRequestLatencyMs, lastResponseTime, lastResponseWorld = nil, nil, nil
                stopPayload()
                local localDenied = false
                if localExpiry then
                    local ok, localText, localPhase = localExpiry.Status()
                    if not ok then text, state, localDenied = localText, localPhase, true end
                end
                notify(restartRequired and not localDenied
                    and 'Restart required: payload cleanup failed.' or text, state or 'error')
            end
            local function startPayload()
                if payloadStarted or not startFn then return true end
                payloadStarted = true
                local before = generation
                local ok, accepted = pcall(startFn)
                if not ok or accepted == false then
                    restartRequired = true
                    revoke('Restart required: offline script startup failed.', 'error')
                    return false
                end
                return generation == before and allowed
            end
            local function denyReason(reason)
                if type(reason) ~= 'string' then return 'Expired' end
                local lower = reason:sub(1, 120):lower():gsub('[_%s%-]+', ' ')
                if lower == 'max devices' or lower == 'maximum devices'
                    or lower == 'max devices reached' then
                    return 'Max Devices'
                end
                local clean = reason
                for _, field in ipairs({'key', 'serial'}) do
                    if pending and type(pending[field]) == 'string' and #pending[field] > 0 then
                        local needle = pending[field]:gsub('([^%w])', '%%%1')
                        clean = clean:gsub(needle, '[' .. field .. ']')
                    end
                end
                if type(cfg.secret) == 'string' and #cfg.secret > 0 then
                    clean = clean:gsub(cfg.secret:gsub('([^%w])', '%%%1'), '[credential]')
                end
                clean = clean:gsub('[%c]', ' '):sub(1, 120)
                return clean == '' and 'Expired' or ('Expired: ' .. clean)
            end
            local function configuredExpiry(result)
                if cfg.expiryPath == nil then return nil, true end
                if type(cfg.expiryPath) ~= 'table' or #cfg.expiryPath == 0 then return nil, false end
                local v = result
                for _, name in ipairs(cfg.expiryPath) do
                    if type(v) ~= 'table' then return nil, false end
                    v = rawget(v, name)
                end
                return v, finite(v) and v > 0 and v % 1 == 0
            end
            local function begin(key)
                if restartRequired or pending then return false end
                if localExpiry then
                    local ok, text, state = localExpiry.Status()
                    if not ok then revoke(text, state); return false end
                end
                if type(key) ~= 'string' then key = '' end
                key = key:match('^%s*(.-)%s*$')
                if #key == 0 or #key > 512 then
                    revoke('Expired: enter a valid key.', 'denied'); return false
                end
                local now, world = readClock()
                if not now then
                    revoke('Game clock unavailable. Try again in a match.', 'error'); return false
                end
                local okSerial, serial = pcall(deps.serial, key)
                if not okSerial or type(serial) ~= 'string' or #serial == 0 or #serial > 512 then
                    revoke('Device identifier unavailable.', 'error'); return false
                end
                generation = generation + 1
                local requestId = generation
                pending = {id = requestId, key = key, serial = serial,
                           started = now, world = world, deadline = now + cfg.timeout}
                notify('Signing in...', 'pending')
                if not pending or pending.id ~= requestId or generation ~= requestId then return false end
                local body = 'game=' .. P.form_encode(cfg.game)
                    .. '&user_key=' .. P.form_encode(key)
                    .. '&serial=' .. P.form_encode(serial)
                local function received(success, raw)
                    if not pending or pending.id ~= requestId or generation ~= requestId then return end
                    local current, worldNow = readClock()
                    if not current or worldNow ~= pending.world or current < pending.started
                        or current >= pending.deadline then
                        revoke('Request expired. Please sign in again.', 'error'); return
                    end
                    if success ~= true or type(raw) ~= 'string' or #raw == 0 or #raw > 32768 then
                        revoke('Connection failed. Please try again.', 'error'); return
                    end
                    local ok, result = pcall(deps.decode, raw)
                    if not ok or type(result) ~= 'table' then
                        revoke('Invalid server response.', 'error'); return
                    end
                    if result.status ~= true then revoke(denyReason(result.reason), 'denied'); return end
                    local data = result.data
                    if type(data) ~= 'table' or type(data.token) ~= 'string' or #data.token ~= 32
                        or not data.token:match('^[%x]+$') or not finite(data.rng) or data.rng % 1 ~= 0 then
                        revoke('Incomplete server response.', 'error'); return
                    end
                    local expected = P.md5(cfg.game .. '-' .. key .. '-' .. serial .. '-' .. cfg.secret)
                    if not P.constant_time_equal(data.token:lower(), expected) then
                        revoke('Server token verification failed.', 'denied'); return
                    end
                    local okWall, wall = pcall(deps.wall)
                    if not okWall or not finite(wall) then
                        revoke('Phone clock unavailable.', 'error'); return
                    end
                    if localExpiry then
                        local accepted, text, state = localExpiry.Accept(
                            data.rng, current, worldNow, wall, current - pending.started)
                        if not accepted then revoke(text, state); return end
                    elseif math.abs(wall - data.rng) > cfg.clockSkew then
                        revoke('Phone/server clock mismatch. Check automatic time.', 'error'); return
                    end
                    local expiry, validExpiry = configuredExpiry(result)
                    if not validExpiry then
                        revoke('Configured server expiry field is missing or invalid.', 'error'); return
                    end
                    if expiry and expiry - data.rng - (current - pending.started) <= 0 then
                        revoke('Expired', 'denied'); return
                    end
                    local fixedExpiry = localExpiry and localExpiry.GetExpiry()
                    if fixedExpiry then expiry = math.min(expiry or fixedExpiry, fixedExpiry) end
                    lastRequestLatencyMs = (current - pending.started) * 1000
                    lastResponseTime, lastResponseWorld = current, worldNow
                    pending = nil
                    allowed, expiresAt = true, expiry
                    saveSession(expiresAt)
                    if not startPayload() then return end
                    notify('Login successful.', 'active')
                end
                local ok, accepted = pcall(deps.post, cfg.url,
                    {['Content-Type'] = 'application/x-www-form-urlencoded'},
                    body, received, cfg.timeout)
                if not ok or accepted == false then
                    revoke('HTTP request could not start.', 'error'); return false
                end
                return true
            end
            function A.Login(key) if allowed then return false end; return begin(key) end
            function A.Tick()
                if not pending then return end
                local now, world = readClock()
                if not now or world ~= pending.world or now < pending.started then
                    revoke('Login interrupted by map loading. Please try again when ready.', 'locked'); return
                end
                if now >= pending.deadline then
                    revoke('Request timed out. Please try again.', 'error')
                end
            end
            function A.IsAuthorized()
                if allowed and not restartRequired then return true end
                local stored = loadSession()
                if stored and not restartRequired then
                    allowed = true; expiresAt = stored.expiresAt; return true
                end
                return false
            end
            function A.Logout() clearSession(); revoke('Expired: signed out.', 'locked') end
            function A.FailClosed(text, requiresRestart)
                if requiresRestart == true then restartRequired = true end
                revoke(text or 'Online access unavailable.', 'error')
            end
            function A.ReportClockTampering()
                if localExpiry then localExpiry.MarkTampered() end
                revoke("Don't be over smart", 'tampered')
            end
            function A.Bind(onStart, onStop)
                if type(onStart) ~= 'function' or type(onStop) ~= 'function' then
                    return false, 'START_AND_STOP_REQUIRED'
                end
                if startFn and (startFn ~= onStart or stopFn ~= onStop) then
                    return false, 'ALREADY_BOUND'
                end
                startFn, stopFn = onStart, onStop
                if A.IsAuthorized() then return startPayload() end
                return true
            end
            function A.Unbind()
                revoke('Offline script disconnected.', 'locked')
                startFn, stopFn = nil, nil
            end
            function A.GetRemainingSeconds() return nil end
            function A.GetState()
                local authorized = A.IsAuthorized()
                local sample, age
                if authorized and lastRequestLatencyMs ~= nil then
                    local now, world = readClock()
                    if now and world == lastResponseWorld and now >= lastResponseTime then
                        sample, age = lastRequestLatencyMs, now - lastResponseTime
                    end
                end
                return {
                    phase = phase, message = message, authorized = authorized,
                    sessionAuthorized = authorized, expiresAt = expiresAt,
                    accessPolicy = "game_session", expiryCheckPolicy = "login_only",
                    periodicRecheck = false, pending = pending ~= nil,
                    linked = startFn ~= nil, restartRequired = restartRequired == true,
                    lastRequestLatencyMs = sample, lastRequestLatencyAgeSeconds = age,
                    latencyScope = "license_http_round_trip"
                }
            end
            return A
        end
    end)()

    local Core = {Primitives = Primitives, createExpiry = CreateLocalExpiry}
    function Core.new(config, dependencies)
        assert(type(config) == 'table' and type(dependencies) == 'table',
            'License configuration and dependencies required')
        local deps = {}
        for key, value in pairs(dependencies) do deps[key] = value end
        if deps.localExpiry == nil then deps.localExpiry = CreateLocalExpiry(config, deps.wall) end
        return CreateAuth(Primitives, config, deps)
    end
    return Core
end)()

-- ============================================================================
-- 2. LOGIN UI
-- ============================================================================
local MasterLoginUI = (function()
    local Module = {}
    function Module.new(env)
        env = env or _G
        local require = env.require or require
        local function global(name)
            local ok, value = pcall(function() return env[name] end)
            if ok then return value end
        end
        local UI = {_status = "Enter your key", _busy = false, _data = nil}
        local function member(object, name)
            if object == nil then return nil end
            local ok, value = pcall(function() return object[name] end)
            if ok then return value end
        end
        local function valid(object)
            local check = member(global("slua"), "isValid")
            if object == nil then return false end
            if type(check) == 'function' then
                local ok, result = pcall(check, object)
                if ok and result == true then return true end
            end
            local game = global('Game')
            local fallback = member(game, 'IsValid')
            if type(fallback) == 'function' then
                local ok, result = pcall(fallback, game, object)
                return ok and result == true
            end
            return false
        end
        local function imported(name)
            local loader = global("import")
            if type(loader) ~= "function" then return nil end
            local ok, result = pcall(loader, name)
            if ok then return result end
        end
        local function construct(class, ...)
            if class == nil then return nil end
            local ok, result = pcall(class, ...)
            if ok then return result end
        end
        local function vector(x, y)
            return construct(global("FVector2D") or imported("Vector2D"), x, y)
                or {X = x, Y = y}
        end
        local function color(r, g, b, a)
            return construct(global("FLinearColor") or imported("LinearColor"), r, g, b, a)
                or {R = r, G = g, B = b, A = a}
        end
        local function visibility(widget, value)
            local setter = member(widget, "SetWidgetVisibility") or member(widget, "SetVisibility")
            assert(type(setter) == "function", "UI_VISIBILITY_UNAVAILABLE")
            setter(widget, value)
        end
        local function setTextStyle(widget, size, textColor)
            pcall(function()
                local font = widget.Font
                if font then
                    font.Size = math.max(1, math.floor(size * (UI._scale or 1) + 0.5))
                    local assigned = pcall(function() widget.Font = font end)
                    if not assigned then widget:SetFont(font) end
                end
            end)
            pcall(function() widget:SetAutoWrapText(true) end)
            pcall(function()
                local slate = construct(imported("SlateColor"), textColor)
                if slate then widget:SetColorAndOpacity(slate) end
            end)
        end
        local function detach(data)
            if not data then return end
            data.visible = false
            pcall(function() if valid(data.input) then data.input:SetText("") end end)
            if data.event and data.eventHandle ~= nil then
                pcall(function() data.event:Remove(data.eventHandle) end)
            end
            if valid(data.container) then
                pcall(function() data.container:RemoveFromParent() end)
            end
            data.onSubmit = nil
        end
        function UI.Destroy()
            local previous = UI._data; UI._data = nil; detach(previous)
        end
        function UI.Hide()
            local data = UI._data
            if not data or data.hiddenApplied then return true end
            data.visible = false
            local ok = pcall(function()
                if valid(data.input) then data.input:SetText("") end
                if valid(data.container) then visibility(data.container, data.hidden) end
            end)
            if ok then data.hiddenApplied = true end
            return ok
        end
        function UI.SetStatus(message)
            UI._status = type(message) == "string" and message:sub(1, 160) or "Login unavailable"
            local data = UI._data
            if data and data.deliveredStatus == UI._status then return true end
            if data and valid(data.status) then
                local ok = pcall(function() data.status:SetText(UI._status) end)
                if ok then data.deliveredStatus = UI._status end
                return ok
            end
            return false
        end
        function UI.SetBusy(busy)
            UI._busy = busy == true
            local data = UI._data
            if data then
                if data.deliveredBusy == UI._busy then return true end
                local buttonOK = pcall(function() data.button:SetIsEnabled(not UI._busy) end)
                local inputOK  = pcall(function() data.input:SetIsEnabled(not UI._busy) end)
                if buttonOK and inputOK then data.deliveredBusy = UI._busy; return true end
            end
            return false
        end
        local function fitScale(parent)
            local result = 1
            pcall(function()
                local size = parent:GetCachedGeometry():GetLocalSize()
                local width, height = size.X, size.Y
                if type(width) == 'number' and type(height) == 'number'
                    and width > 24 and height > 24 then
                    result = math.min(1, (width - 24) / 500, (height - 24) / 248)
                end
            end)
            return result
        end
        function UI.Show(onSubmit)
            if type(onSubmit) ~= "function" then return false, "UI_SUBMIT_REQUIRED" end
            local data = UI._data
            if data and valid(data.parent)
                and math.abs(fitScale(data.parent) - (data.scale or 1)) > 0.001 then
                UI.Destroy(); data = nil
            end
            if data and valid(data.container) and valid(data.parent) then
                local ok = data.visible or pcall(function()
                    visibility(data.container, data.visibleEnum)
                end)
                if ok then
                    data.onSubmit, data.visible, data.hiddenApplied = onSubmit, true, false
                    UI.SetStatus(UI._status); UI.SetBusy(UI._busy); return true
                end
            end
            UI.Destroy()
            local okTools, uiTools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameUITools")
            local getRoot = okTools and member(uiTools, "GetMainControlBaseUI")
            if type(getRoot) ~= "function" then return false, "UI_NOT_READY" end
            local okRoot, root = pcall(getRoot)
            if not okRoot or not valid(root) then return false, "UI_NOT_READY" end
            local parent = member(root, "CanvasPanel_0")
            if not valid(parent) then parent = member(root, "CanvasPanel_42") end
            if not valid(parent) then return false, "UI_NOT_READY" end
            local game = global("CGame")
            if type(member(game, "NewObjectFromPath")) ~= "function" then
                return false, "UI_FACTORY_UNAVAILABLE"
            end
            local enums = member(global("UEnums"), "ESlateVisibility")
            local visibleEnum, hidden = member(enums, "Visible"), member(enums, "Collapsed")
            local passive = member(enums, "SelfHitTestInvisible")
            if visibleEnum == nil or hidden == nil or passive == nil then
                return false, "UI_ENUM_UNAVAILABLE"
            end
            UI._scale = fitScale(parent)
            data = {parent = parent, visible = false, onSubmit = onSubmit,
                    visibleEnum = visibleEnum, hidden = hidden, scale = UI._scale}
            local okBuild = pcall(function()
                local function make(class, outer)
                    local widget = game:NewObjectFromPath("/Script/UMG." .. class, outer)
                    assert(valid(widget), "UI_WIDGET_UNAVAILABLE")
                    return widget
                end
                data.container = make("CanvasPanel", parent)
                local function add(widget, x, y, width, height, z)
                    local slot = data.container:AddChildToCanvas(widget)
                    slot:SetAutoSize(false)
                    slot:SetPosition(vector(x * UI._scale, y * UI._scale))
                    slot:SetSize(vector(width * UI._scale, height * UI._scale))
                    slot:SetZOrder(z)
                    return slot
                end
                local background = make("Border", data.container)
                background:SetBrushColor(color(0.0, 0.0, 0.0, 1.0))
                visibility(background, visibleEnum)
                add(background, 0, 0, 500, 248, 0)

                local borderColor = color(1.0, 1.0, 1.0, 1.0)
                local topAccent = make("Border", data.container)
                topAccent:SetBrushColor(borderColor)
                visibility(topAccent, passive); add(topAccent, 0, 0, 500, 2, 1)

                local bottomAccent = make("Border", data.container)
                bottomAccent:SetBrushColor(borderColor)
                visibility(bottomAccent, passive); add(bottomAccent, 0, 246, 500, 2, 1)

                local leftAccent = make("Border", data.container)
                leftAccent:SetBrushColor(borderColor)
                visibility(leftAccent, passive); add(leftAccent, 0, 0, 2, 248, 1)

                local rightAccent = make("Border", data.container)
                rightAccent:SetBrushColor(borderColor)
                visibility(rightAccent, passive); add(rightAccent, 498, 0, 2, 248, 1)

                local title = make("TextBlock", data.container)
                title:SetText("HEXA CORE LICENSE VERIFICATION")
                setTextStyle(title, 21, color(0.96, 0.97, 0.98, 1))
                visibility(title, passive); add(title, 22, 13, 456, 30, 2)

                local inputPanel = make("Border", data.container)
                inputPanel:SetBrushColor(color(0.72, 0.72, 0.72, 1))
                visibility(inputPanel, passive); add(inputPanel, 22, 62, 456, 42, 1)

                data.input = make("EditableTextBox", data.container)
                data.input:SetText("")
                setTextStyle(data.input, 16, color(0.08, 0.08, 0.08, 1))
                pcall(function() data.input:SetHintText("") end)
                pcall(function() data.input:SetBackgroundColor(color(0.72, 0.72, 0.72, 1)) end)
                visibility(data.input, visibleEnum); add(data.input, 30, 62, 440, 42, 2)

                data.status = make("TextBlock", data.container)
                data.status:SetText(""); data.deliveredStatus = UI._status
                setTextStyle(data.status, 12, color(1, 1, 1, 1))
                visibility(data.status, hidden)
                pcall(function() data.status:SetAutoWrapText(true) end)
                add(data.status, 23, 132, 454, 43, 2)

                data.button = make("Button", data.container)
                pcall(function() data.button:SetBackgroundColor(color(0.0, 0.18, 0.07, 1)) end)
                visibility(data.button, visibleEnum)
                local label = make("TextBlock", data.button)
                label:SetText("LOGIN")
                setTextStyle(label, 15, color(1, 1, 1, 1))
                visibility(label, passive)
                local labelSlot = data.button:AddChild(label)
                pcall(function() labelSlot:SetHorizontalAlignment(2) end)
                pcall(function() labelSlot:SetVerticalAlignment(2) end)
                add(data.button, 150, 187, 200, 40, 3)
                data.event = data.button.OnClicked
                data.eventHandle = data.event:Add(function()
                    if UI._data ~= data or not data.visible or UI._busy then return end
                    local readOK, key = pcall(function() return data.input:GetText() end)
                    if not readOK or type(key) ~= "string" then
                        UI.SetStatus("Unable to read the key"); return
                    end
                    key = key:match("^%s*(.-)%s*$")
                    if key == "" or #key > 512 then UI.SetStatus("Enter a valid key"); return end
                    local submitOK = pcall(data.onSubmit, key)
                    if not submitOK then UI.SetBusy(false); UI.SetStatus("Login could not start") end
                end)
                local slot = parent:AddChildToCanvas(data.container)
                slot:SetAutoSize(false)
                slot:SetSize(vector(500 * UI._scale, 248 * UI._scale))
                slot:SetZOrder(9000)
                local anchors = slot:GetAnchors()
                anchors.Minimum, anchors.Maximum = vector(0.5, 0.5), vector(0.5, 0.5)
                slot:SetAnchors(anchors)
                slot:SetAlignment(vector(0.5, 0.5))
                slot:SetPosition(vector(0, 0))
                visibility(data.container, passive)
            end)
            if not okBuild then
                detach(data); return false, "UI_BUILD_UNAVAILABLE"
            end
            data.visible = true; UI._data = data; UI.SetBusy(UI._busy)
            return true
        end
        function UI.ShowNotice(message)
            local shown, reason = UI.Show(function() return false end)
            if not shown then return false, reason end
            UI.SetStatus(message); UI.SetBusy(true); return true
        end
        return UI
    end
    return Module
end)()

-- ============================================================================
-- 3. WELCOME UI
-- ============================================================================
local MasterWelcomeUI = (function()
    local Module = {}
    function Module.new(env)
        env = env or _G
        local require = env.require or require
        local function global(n)
            local ok, v = pcall(function() return env[n] end)
            if ok then return v end
        end
        local function member(o, k)
            if o == nil then return nil end
            local ok, v = pcall(function() return o[k] end)
            if ok then return v end
        end
        local function valid(o)
            local c = member(global("slua"), "isValid")
            if o == nil then return false end
            if type(c) == 'function' then
                local ok, v = pcall(c, o)
                if ok and v == true then return true end
            end
            local g = global('Game'); local f = member(g, 'IsValid')
            if type(f) == 'function' then
                local ok, v = pcall(f, g, o)
                return ok and v == true
            end
            return false
        end
        local function imported(n)
            local l = global("import")
            if type(l) ~= "function" then return nil end
            local ok, v = pcall(l, n); if ok then return v end
        end
        local function construct(c, ...)
            if c == nil then return nil end
            local ok, v = pcall(c, ...); if ok then return v end
        end
        local function vector(x, y)
            return construct(global("FVector2D") or imported("Vector2D"), x, y) or {X = x, Y = y}
        end
        local function linear(v)
            v = v / 255
            if v <= 0.04045 then return v / 12.92 end
            return ((v + 0.055) / 1.055) ^ 2.4
        end
        local function color(r, g, b, a)
            r, g, b, a = linear(r), linear(g), linear(b), a or 1
            return construct(global("FLinearColor") or imported("LinearColor"), r, g, b, a)
                or {R = r, G = g, B = b, A = a}
        end
        local function visibility(w, v)
            local s = member(w, "SetWidgetVisibility") or member(w, "SetVisibility")
            if type(s) == 'function' then s(w, v) end
        end
        local WelcomeUI = {Width = 600, Height = 276}
        local WelcomeText = {
            "Welcome to HEXA CORE LUCIFER",
            "Kill limit 8-10",
            "Play smart and avoid report",
        }
        local UI = {_shown = false, _data = nil}
        local function detach(data)
            if not data then return end
            data.Visible = false
            if data.Event and data.EventHandle ~= nil then
                pcall(function() data.Event:Remove(data.EventHandle) end)
            end
            if valid(data.Container) then
                pcall(function() visibility(data.Container, data.Hidden) end)
                pcall(function() data.Container:RemoveFromParent() end)
            end
        end
        function UI:Destroy()
            local p = UI._data; UI._data = nil; detach(p)
        end
        local function parent()
            local okT, tools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameUITools")
            if not okT then return nil end
            local getRoot = member(tools, "GetMainControlBaseUI")
            if type(getRoot) ~= "function" then return nil end
            local ok, root = pcall(getRoot)
            if not ok or not valid(root) then return nil end
            local canvas = member(root, "CanvasPanel_0")
            if not valid(canvas) then canvas = member(root, "CanvasPanel_42") end
            if valid(canvas) then return root, canvas end
        end
        function UI:Show()
            if UI._shown and UI._data and valid(UI._data.Container) then
                visibility(UI._data.Container, UI._data.Passive)
                UI._data.Visible = true
                return true
            end
            UI:Destroy()
            local root, par = parent()
            if not par then return false, "WELCOME_ROOT_UNAVAILABLE" end
            local game = global("CGame")
            if type(member(game, "NewObjectFromPath")) ~= "function" then
                return false, "WELCOME_FACTORY_UNAVAILABLE"
            end
            local enums = member(global("UEnums"), "ESlateVisibility")
            local visible, hidden, passive = member(enums, "Visible"),
                member(enums, "Collapsed"), member(enums, "SelfHitTestInvisible")
            if visible == nil or hidden == nil or passive == nil then
                return false, "WELCOME_ENUM_UNAVAILABLE"
            end
            local data = {Root = root, Parent = par, Visible = false,
                          Hidden = hidden, Passive = passive}
            local ok = pcall(function()
                local function make(class, outer)
                    local w = game:NewObjectFromPath("/Script/UMG." .. class, outer)
                    assert(valid(w), "WELCOME_WIDGET_UNAVAILABLE")
                    return w
                end
                data.Container = make("CanvasPanel", par)
                visibility(data.Container, hidden)
                local function add(w, x, y, ww, hh, z)
                    local s = data.Container:AddChildToCanvas(w)
                    s:SetAutoSize(false)
                    s:SetPosition(vector(x, y))
                    s:SetSize(vector(ww, hh))
                    s:SetZOrder(z)
                    return s
                end
                local function rect(x, y, ww, hh, c, z)
                    local w = make("Border", data.Container)
                    w:SetBrushColor(c)
                    visibility(w, passive)
                    add(w, x, y, ww, hh, z)
                    return w
                end
                local slateColor
                pcall(function() slateColor = imported("SlateColor") end)
                local function textStyle(w, size, c)
                    local font = member(w, "Font")
                    if font ~= nil then
                        if type(font) == 'table' then
                            local copy = {}
                            for k, v in pairs(font) do copy[k] = v end
                            font = copy
                        end
                        font.Size = size
                        pcall(function() w:SetFont(font) end)
                    end
                    pcall(function() w:SetColorAndOpacity(slateColor and slateColor(c) or c) end)
                    pcall(function() w:SetJustification(1) end)
                    visibility(w, passive)
                end
                local function text(value, x, y, ww, hh, size, c, z)
                    local w = make("TextBlock", data.Container)
                    w:SetText(value)
                    textStyle(w, size, c)
                    pcall(function() w:SetAutoWrapText(true) end)
                    add(w, x, y, ww, hh, z)
                    return w
                end
                local W, H = WelcomeUI.Width, WelcomeUI.Height
                rect(4, 6, W, H, color(18, 5, 10, 0.25), 0)
                rect(0, 0, W, H, color(186, 137, 74), 1)
                rect(2, 2, W - 4, H - 4, color(255, 244, 214), 2)
                local stops = {{116, 16, 46}, {169, 38, 47}, {194, 105, 35}}
                local segments = 64
                for i = 0, segments - 1 do
                    local t = i / (segments - 1)
                    local left, right, blend
                    if t <= 0.5 then left, right, blend = stops[1], stops[2], t * 2
                    else left, right, blend = stops[2], stops[3], (t - 0.5) * 2 end
                    local x0 = 2 + (W - 4) * i / segments
                    local x1 = 2 + (W - 4) * (i + 1) / segments
                    rect(x0, 2, math.min(W - 2, x1 + 0.3) - x0, 76,
                        color(left[1] + (right[1] - left[1]) * blend,
                              left[2] + (right[2] - left[2]) * blend,
                              left[3] + (right[3] - left[3]) * blend), 3)
                end
                rect(18, 3, W - 36, 1, color(255, 255, 255, 0.32), 4)
                rect(2, 78, W - 4, 3, color(238, 188, 93), 4)
                local title = text(WelcomeText[1], 24, 23, W - 48, 44, 19, color(255, 253, 247), 5)
                pcall(function() title:SetShadowOffset(vector(0, 1)) end)
                pcall(function() title:SetShadowColorAndOpacity(color(40, 3, 12, 0.45)) end)
                rect(30, 100, W - 60, 54, color(255, 226, 159), 3)
                rect(30, 100, 4, 54, color(160, 33, 49), 4)
                text(WelcomeText[2], 46, 110, W - 92, 38, 23, color(115, 25, 45), 5)
                text(WelcomeText[3], 30, 168, W - 60, 32, 17, color(130, 34, 47), 5)
                local button = make("Button", data.Container)
                pcall(function() button:SetBackgroundColor(color(131, 25, 47)) end)
                visibility(button, visible)
                local label = make("TextBlock", button)
                label:SetText("OK")
                textStyle(label, 17, color(255, 251, 238))
                local ls = button:AddChild(label)
                pcall(function() ls:SetHorizontalAlignment(2) end)
                pcall(function() ls:SetVerticalAlignment(2) end)
                add(button, (W - 164) / 2, 212, 164, 42, 6)
                data.Event = member(button, "OnClicked")
                data.EventHandle = data.Event:Add(function()
                    if UI._data == data and data.Visible then UI:Destroy() end
                end)
                local slot = par:AddChildToCanvas(data.Container)
                slot:SetAutoSize(false)
                slot:SetSize(vector(W, H))
                slot:SetZOrder(9200)
                local anchors = slot:GetAnchors()
                anchors.Minimum, anchors.Maximum = vector(0.5, 0.5), vector(0.5, 0.5)
                slot:SetAnchors(anchors)
                slot:SetAlignment(vector(0.5, 0.5))
                slot:SetPosition(vector(0, 0))
                visibility(data.Container, passive)
            end)
            if not ok then detach(data); return false, "WELCOME_BUILD_FAILED" end
            data.Visible = true
            UI._data = data
            UI._shown = true
            return true
        end
        function UI:Hide() if UI._data then detach(UI._data) end; UI._data = nil end
        function UI:IsShown() return UI._shown == true end
        return UI
    end
    return Module
end)()
_G.MasterWelcomeUI = MasterWelcomeUI
-- ============================================================================
-- 4. LICENSE RUNTIME
-- ============================================================================
local MasterLicenseRuntime = (function()
    local Runtime = {}
    Runtime.__index = Runtime
    local function finite(n)
        return type(n) == 'number' and n == n and n >= 0 and n < math.huge
    end
    local function read(o, k)
        if o == nil then return nil end
        local ok, v = pcall(function() return o[k] end)
        if ok then return v end
    end
    local function static(o, k, ...)
        local fn = read(o, k)
        if type(fn) ~= 'function' then return nil end
        local ok, v = pcall(fn, ...); if ok then return v end
    end
    local function call(o, k, ...)
        local fn = read(o, k)
        if type(fn) ~= 'function' then return nil end
        local ok, v = pcall(fn, o, ...); if ok then return v end
    end
    local function validConfig(c)
        return type(c) == 'table' and type(c.url) == 'string' and c.url:match('^https://') ~= nil
            and type(c.game) == 'string' and #c.game > 0
            and type(c.secret) == 'string' and #c.secret > 0
            and finite(c.timeout) and c.timeout > 0 and finite(c.clockSkew)
    end
    function Runtime.new(env, config, Core, LoginUI)
        local self = setmetatable({
            env = env or _G, reason = 'login_required', active = false,
            ready = false, disposed = false, uiRetryAt = 0, uiFailures = 0
        }, Runtime)
        if not validConfig(config) or type(Core) ~= 'table' or type(Core.new) ~= 'function'
            or type(Core.Primitives) ~= 'table' then
            self.reason = 'license_dependencies_unavailable'; return self
        end
        local cfg = {}
        for k, v in pairs(config) do cfg[k] = v end
        self.timeout = cfg.timeout
        if type(LoginUI) == 'table' and type(LoginUI.new) == 'function' then
            local ok, ui = pcall(LoginUI.new, self.env)
            if ok and type(ui) == 'table' then self.ui = ui end
        end
        self.welcome = nil
        self.welcomeShownThisSession = true
        self.welcomeScheduledAt = nil
        self.submit = function(key) return self:login(key) end
        local ok, auth = pcall(Core.new, cfg, {
            clock = function() return self:_clock() end,
            wall = function()
                local value = static(read(self.env, 'os'), 'time')
                if finite(value) and value > 0 then return value end
            end,
            serial = function(key)
                local client = read(self.env, 'Client')
                local value = static(client, 'GetPhoneDeviceID')
                assert(type(value) == 'string' and #value > 0 and #value <= 512,
                    'DEVICE_ID_UNAVAILABLE')
                return Core.Primitives.name_uuid('MASTER-LUA-V1\0' .. key .. '\0' .. value)
            end,
            decode = function(raw)
                local json = self:_module('json', nil, 'common.json_util', 'decode')
                assert(json, 'JSON_UNAVAILABLE')
                return json.decode(raw)
            end,
            post = function(url, headers, body, callback, timeout)
                local manager = read(self.env, 'ModuleManager')
                local config = read(manager, 'CommonModuleConfig')
                local getter = read(manager, 'GetModule')
                assert(type(getter) == 'function' and config, 'HTTP_MANAGER_UNAVAILABLE')
                local http = getter(read(config, 'http_manager'))
                local post = read(http, 'Post')
                assert(type(post) == 'function', 'HTTP_POST_UNAVAILABLE')
                return post(http, url, headers, body, nil, callback, timeout)
            end,
            status = function(message, phase)
                self.active = false
                self.reason = phase == 'active' and 'waiting_maintenance' or 'login_required'
                self:_ui('SetStatus', message)
                self:_ui('SetBusy', phase == 'pending')
                if phase == 'active' then self:_ui('Hide') end
            end,
        })
        if ok and type(auth) == 'table' then self.auth = auth
        else self.reason = 'license_initialization_unavailable' end
        return self
    end
    function Runtime:_module(cache, globalName, path, method)
        local found = globalName and read(self.env, globalName)
        if type(read(found, method)) == 'function' then return found end
        found = self[cache]
        if type(read(found, method)) == 'function' then return found end
        local loader = read(self.env, 'require')
        if type(loader) == 'function' then
            local ok, value = pcall(loader, path)
            if ok and type(read(value, method)) == 'function' then
                self[cache] = value; return value
            end
        end
    end
    function Runtime:_valid(object)
        if object == nil then return false end
        if static(read(self.env, 'slua'), 'isValid', object) == true then return true end
        return call(read(self.env, 'Game'), 'IsValid', object) == true
    end
    function Runtime:_clock()
        local world = static(read(self.env, 'slua'), 'getWorld')
        if world == nil then return nil end
        local statics = read(self.env, 'GameplayStatics') or self.statics
        if type(read(statics, 'GetRealTimeSeconds')) ~= 'function' then
            local loader = read(self.env, 'import')
            if type(loader) == 'function' then
                local ok, value = pcall(loader, 'GameplayStatics')
                if ok then statics = value end
            end
        end
        if type(read(statics, 'GetRealTimeSeconds')) ~= 'function' then return nil end
        self.statics = statics
        local now = static(statics, 'GetRealTimeSeconds', world)
        if finite(now) then return now, world end
    end
    function Runtime:_readGameplay(world)
        local data = read(self.env, 'GameplayData') or self.gameplayData
        if data == nil then
            local loader = read(self.env, 'require')
            if type(loader) == 'function' then
                local ok, value = pcall(loader, 'GameLua.GameCore.Data.GameplayData')
                if ok and value ~= nil then self.gameplayData = value; data = value end
            end
        end
        local pc = static(data, 'GetPlayerController')
        if not self:_valid(pc) and not self:_valid(read(pc, 'Object')) then
            pc = call(read(self.env, 'slua_GameFrontendHUD'), 'GetPlayerController')
        end
        if not self:_valid(pc) and not self:_valid(read(pc, 'Object')) then
            return nil, 'waiting_controller'
        end
        local pawn = static(data, 'GetPlayerCharacter')
        if not self:_valid(pawn) then pawn = static(data, 'GetLocalCharacter') end
        for _, method in ipairs({'GetPlayerCharacterSafety', 'GetCurPawn', 'GetPawn'}) do
            if not self:_valid(pawn) then pawn = call(pc, method) end
            if not self:_valid(pawn) then pawn = call(read(pc, 'Object'), method) end
        end
        if not self:_valid(pawn) then return nil, 'waiting_pawn' end
        local tools = self:_module('tools', nil,
            'GameLua.Mod.BaseMod.Common.UI.InGameUITools', 'GetMainControlBaseUI')
        local root = static(tools, 'GetMainControlBaseUI')
        if not self:_valid(root) then return nil, 'waiting_control_ui' end
        local status = self:_module('gameStatus', 'GameStatus',
            'client.common.game_status', 'IsInFightingStatus')
        local loading = self:_module('loading', nil,
            'client.slua.logic.loading.logic_loading', 'IsShowing')
        if not status or not loading then return nil, 'readiness_services_unavailable' end
        if static(status, 'IsInFightingStatus') ~= true then return nil, 'waiting_gameplay' end
        if static(loading, 'IsShowing') ~= false then return nil, 'waiting_loading' end
        return {world = world, controller = pc, pawn = pawn, root = root}
    end
    local function same(a, b)
        return a and b and a.world == b.world and a.controller == b.controller
            and a.pawn == b.pawn and a.root == b.root
    end
    function Runtime:_ui(method, ...)
        local fn = read(self.ui, method)
        if type(fn) ~= 'function' then return false, 'UI_UNAVAILABLE' end
        local ok, value, reason = pcall(fn, ...)
        if not ok then return false, 'UI_TEMPORARILY_UNAVAILABLE' end
        return value, reason
    end
    function Runtime:_clearReadiness(reason)
        self.active, self.ready = false, false
        self.identity, self.readySince, self.maintenanceAt, self.maintenanceWorld = nil, nil, nil, nil
        self.reason = reason
        self:_ui('Hide')
    end
    function Runtime:_showPanel(now, state, blocked)
        if now < self.uiRetryAt then return false end
        local shown, uiReason
        if blocked then shown, uiReason = self:_ui('ShowNotice', state.message)
        else shown, uiReason = self:_ui('Show', self.submit) end
        if shown then
            self.uiFailures, self.uiError = 0, nil
            self:_ui('SetStatus', state.message)
            self:_ui('SetBusy', blocked or state.pending)
        else
            self.uiFailures = self.uiFailures + 1
            self.uiRetryAt = now + (self.uiFailures >= 10 and 5 or 1)
            self.uiError = type(uiReason) == 'string' and uiReason:match('^UI_[A-Z_]+$')
                or 'UI_UNAVAILABLE'
        end
        return shown == true
    end
    function Runtime:update()
        if self.disposed then self.reason = 'disposed'; return false end
        if not self.auth then return false end
        local tickOK = pcall(self.auth.Tick)
        if not tickOK then
            self.auth.FailClosed('License maintenance unavailable.')
            self:_clearReadiness('license_maintenance_unavailable'); return false
        end
        local now, world = self:_clock()
        if not now then self:_clearReadiness('clock_unavailable'); return false end
        local ready, reason = self:_readGameplay(world)
        if not ready then self:_clearReadiness(reason); return false end
        if not same(self.identity, ready) or not self.readySince or now < self.readySince then
            self.identity, self.readySince = ready, now
        end
        self.ready = now - self.readySince >= 3
        self.maintenanceAt, self.maintenanceWorld = now, world
        self.active = self.ready and self.auth.IsAuthorized()
        if not self.ready then
            self.reason = 'waiting_stable_gameplay'; self:_ui('Hide'); return false
        end
        local state = self.auth.GetState()
        if self.active then
            self.reason = 'active'
            self:_ui('Hide')
            return true
        end
        self.reason = 'login_required'
        if state.restartRequired or state.phase == 'expired' or state.phase == 'tampered' then
            self.reason = state.restartRequired and 'restart_required' or state.phase
            self:_showPanel(now, state, true); return false
        end
        if not self:_showPanel(now, state, false) and self.uiError then
            self.reason = 'login_ui_unavailable'
        end
        return false
    end
    function Runtime:isActive()
        if self.disposed or not self.auth or not self.active or not self.ready then return false end
        if not self.auth.IsAuthorized() then self.active = false; return false end
        local now, world = self:_clock()
        if not now or world ~= self.maintenanceWorld or not self.maintenanceAt
            or now < self.maintenanceAt or now - self.maintenanceAt >= 3 then
            self.active = false; self.reason = 'maintenance_stale'; return false
        end
        return true
    end
    function Runtime:login(key)
        if self.disposed or not self.auth then return false end
        if self.auth.IsAuthorized() then return true end
        local now, world = self:_clock()
        if not self.ready or not now or world ~= self.maintenanceWorld
            or not self.maintenanceAt or now < self.maintenanceAt
            or now - self.maintenanceAt >= 3 then return false end
        local identity = self:_readGameplay(world)
        if not same(identity, self.identity) then
            self:_clearReadiness('waiting_stable_gameplay'); return false
        end
        local ok, accepted = pcall(self.auth.Login, key)
        if not ok then self.auth.FailClosed('Login could not start.'); return false end
        return accepted == true
    end
    function Runtime:getStatus()
        local active = self:isActive()
        local state = self.auth and self.auth.GetState() or {}
        return {
            authorized = active, sessionAuthorized = state.authorized == true,
            phase = state.phase or 'locked',
            message = state.message or 'License dependencies unavailable.',
            reason = self.reason, pending = state.pending == true,
            gameplayReady = self.ready, expiresAt = state.expiresAt,
            accessPolicy = 'game_session', expiryCheckPolicy = 'login_only',
            clockProtection = 'login_only', periodicRecheck = false,
            loginDelaySeconds = 3, restartRequired = state.restartRequired == true,
            uiError = self.uiError,
            lastRequestLatencyMs = state.lastRequestLatencyMs,
            latencyScope = 'license_http_round_trip', disposed = self.disposed
        }
    end
    function Runtime:logout()
        self.active = false
        if self.auth then self.auth.Logout() end
        self.reason = 'login_required'; return true
    end
    function Runtime:dispose()
        if self.disposed then return true end
        self:logout(); self.disposed = true; self.ready = false
        self:_ui('Destroy'); self.reason = 'disposed'
        self.submit = nil
        return true
    end
    return Runtime
end)()

-- ============================================================================
-- 5. EXPIRY FALLBACK
-- ============================================================================
local EXPIRY_TIMESTAMP = os.time({year = 2026, month = 8, day = 20, hour = 0, min = 0, sec = 0})
local masterESPLicenseInstance

function CheckExpiration()
    if masterESPLicenseInstance then
        local active = false
        pcall(function() active = masterESPLicenseInstance:isActive() end)
        if active then
            _G._MOD_EXPIRED = false
            return true
        end
    end
    local now = os.time()
    local remaining = EXPIRY_TIMESTAMP - now
    if remaining <= 0 then
        _G._MOD_EXPIRED = true
        return false
    end
    _G._MOD_EXPIRED = false
    _G._MOD_REMAINING_SECONDS = remaining
    return true
end

function _G.TryShowWelcome()
    if _G.WelcomeShown then return end
    if not CheckExpiration() then return end
    _G.WelcomeShown = true
end

local function BRPlayerLicenseActive()
    if not masterESPLicenseInstance then return false end
    local active = false
    pcall(function() active = masterESPLicenseInstance:isActive() == true end)
    return active
end

local function BRPlayerLicenseEnsure()
    if masterESPLicenseInstance then return end
    local host = setmetatable({GameplayData = GameplayData}, {__index = _ENV})
    masterESPLicenseInstance = MasterLicenseRuntime.new(
        host, MasterLicenseConfig, MasterLicenseCore, MasterLoginUI)
end

local function BRPlayerLicenseTick()
    BRPlayerLicenseEnsure()
    if masterESPLicenseInstance then
        pcall(function() masterESPLicenseInstance:update() end)
    end
end

_G.MasterLicenseLogin = _G.MasterLicenseLogin or function(key)
    BRPlayerLicenseEnsure()
    if not masterESPLicenseInstance then return false, "license_unavailable" end
    local ok, result = pcall(masterESPLicenseInstance.login, masterESPLicenseInstance, key)
    if not ok then return false, "license_unavailable" end
    return result
end

_G.MasterLicenseLogout = _G.MasterLicenseLogout or function()
    if not masterESPLicenseInstance then return false end
    local ok, result = pcall(masterESPLicenseInstance.logout, masterESPLicenseInstance)
    return ok and result or false
end

_G.MasterLicenseStatus = _G.MasterLicenseStatus or function()
    BRPlayerLicenseEnsure()
    if not masterESPLicenseInstance then
        return {authorized = false, phase = "locked", message = "license_unavailable"}
    end
    local ok, value = pcall(masterESPLicenseInstance.getStatus, masterESPLicenseInstance)
    return ok and value or {authorized = false, phase = "locked"}
end

-- ============================================================================
-- 6. BRPlayerCharacterBase GAME FUNCTIONS (ORIGINAL — @HEXA CORE)
-- ============================================================================
function BRPlayerCharacterBase:ctor() end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
  self:InitAddSpecialMoveInfo()
  self.bCanNearDeathGiveup = true
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
  if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
    local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
    if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
      Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
    end
  end
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bPositiveBlowUp = true
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
      AttrName = { "bCanSelfRescue" }
    }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
    printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", self.PlayerKey)
    GameplayData.AddCharacter(self.Object)
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
      [1] = "FinishedState"
    }, self.HandleFinishedState, self)
  end
end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
  if self.Object ~= uPawn then return end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
    local EDynamicSimpleQueryConfigDisableMask = import("EDynamicSimpleQueryConfigDisableMask")
    self.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(EDynamicSimpleQueryConfigDisableMask.Bit0, true)
  end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local GameModeType = CGameMode.GameModeType
    local GameModeID = tonumber(CGameState.GameModeID)
    local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
    local bModeIDSatisfy = not MatchModeIds[GameModeID]
    return bModeTypeSatisfy and bModeIDSatisfy
  end
  return false
end

function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if NewParachuteState == EParachuteState.PS_Opening then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
          uCurrentPlayerControl.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
        end
      elseif NewParachuteState == EParachuteState.PS_None then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
          uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
        end
        if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
          uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
        end
      end
    end
  end
end

function BRPlayerCharacterBase:OnLanded()
  if self.HandleOnLanded then self:HandleOnLanded(-1) end
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
      end
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI()
      end
    end
  end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then GameplayData.RemoveCharacter(self.Object) end
end

function BRPlayerCharacterBase:IsWarGameMode()
  local uGameState = GameplayData:GetGameState()
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
    return uGameState.GameModeType == EGameModeType.EWarGameMode
  end
  return false
end

function BRPlayerCharacterBase:BPOnRecycled()
  if Client then self:ResetMeshRelativeLocationAndRotation() end
end

function BRPlayerCharacterBase:BPOnRespawned()
  if Client then self:ResetMeshRelativeLocationAndRotation() end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.AddCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
  if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
    local uDefaultMeshRot = FRotator(0, -90, 0)
    local uDefaultMeshRelativeLoc = FVector(0, 0, 0)
    if self.Mesh.K2_SetRelativeRotation then
      self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false)
    end
    self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
  end
end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord() end

function BRPlayerCharacterBase:PreAttachedToVehicle()
  local IsDS = UKismetSystemLibrary.IsDedicatedServer(self)
  if not IsDS then return end
  local MainPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(MainPlayerController) then return end
  local CharacterAvatarComp2_BP = self.CharacterAvatarComp2_BP
  if not slua.isValid(CharacterAvatarComp2_BP) then return end
  local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
  local changedVehicleId = CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
  local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
  if changedVehicleId then
    local UAvatarUtils = import("AvatarUtils")
    if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId) == ESTExtraVehicleShapeType.VST_Horse then
      local uCurPlayerState = self:GetPlayerStateSafety()
      if slua.isValid(uCurPlayerState) then
        uCurPlayerState:AddGeneralCount(468, 1, false)
      end
    end
  end
end

function BRPlayerCharacterBase:ParachuteJump()
  local uPlayerController = self:GetControllerSafety()
  if slua.isValid(uPlayerController) then
    if not self:GetEnsure() then
      if uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
        self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
        uPlayerController:ReInitParachuteItem()
        uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
      end
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
    end
  end
end

function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
  if uCharacter ~= self.Object then return end
  local MedievalCrane = self:GetMedievalCraneFromBase(uNewMovementBase)
  if MedievalCrane and MedievalCrane.AddCharacter then
    MedievalCrane:AddCharacter(self.Object)
  else
    MedievalCrane = self:GetMedievalCraneFromBase(uOldMovementBase)
    if MedievalCrane and MedievalCrane.RemoveCharacter then
      MedievalCrane:RemoveCharacter(self.Object)
    end
  end
end

function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
  if not slua.isValid(Base) or not Base.GetOwner then return end
  local Lifter = Base:GetOwner()
  if not slua.isValid(Lifter) then return end
  if not Lifter.AddCharacter then return end
  return Lifter
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
  local uPlayerState = self:GetPlayerStateSafety()
  if not slua.isValid(uPlayerState) then return false end
  if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:DisplayGameTipWithMsgID(48532)
    end
  end
  return not uPlayerState.CanUseFlaregun
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
  self:HandleNearDeathGiveupRescue()
end

function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
  local uNearDeathComp = self.NearDeatchComponent
  if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
    local uPlayerState = self:GetPlayerStateSafety()
    if slua.isValid(uPlayerState) then
      uPlayerState:AddGeneralCount(1613, 1, false)
    end
    uNearDeathComp:TriggerGotoDieExplictly(self.Object)
  end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
    self:MulticastRPC_GmPlayAction(actionId)
  end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then return end
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then return end
  local LogFilter = require("common.log_filter")
  LogFilter.SetLogTreeEnable(true)
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then return end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")

  function HEXA_loadLater()
    uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
  end
  asset_util.GetAssetsArrayAsyncParallel(tb, HEXA_loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
  end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
  if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
  end
end

function BRPlayerCharacterBase:SetAreaID(AreaID)
  self:SetAttrValue("AreaID", AreaID, -1)
end

function BRPlayerCharacterBase:GetAreaID()
  return math.floor(self:GetAttrValue("AreaID") + 0.5)
end

function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
  return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
  if self:HasState(EPawnState.SpecialSuit) then
    self:TriggerEntrySkillWithID(4301101, true)
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
  self.Super:SwitchCameraToParachuteOpening()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
  self.Super:SwitchCameraToParachuteFalling()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
  end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
  self.Super:SwitchCameraToNormal()
  if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
    self.ParachuteFormation:OnLandingClearFormationCamera()
  end
end

function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
  if self:HasState(EPawnState.AttachToOther) then
    local Weapon = self:GetWeaponBySlot(Slot)
    if slua.isValid(Weapon) then
      local WeaponID = Weapon:GetWeaponID()
      local AttachToOtherConfig = GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
      if AttachToOtherConfig and AttachToOtherConfig.CheckIsWeaponInBlackList and AttachToOtherConfig.CheckIsWeaponInBlackList(WeaponID) then
        local uPlayerController = self:GetPlayerControllerSafety()
        if Client and slua.isValid(uPlayerController) and uPlayerController.Role == ENetRole.ROLE_AutonomousProxy then
          uPlayerController:DisplayGameTipWithMsgID(47306)
        end
        return false
      end
    end
  end
  if self:HasState(EPawnState.WebSwing) and Slot ~= ESurviveWeaponPropSlot.SWPS_None and slua.isValid(self.STCharacterMovement) then
    local SpiderSwingObj = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementType.SPECIAL_MOVE_SpiderSwing)
    if slua.isValid(SpiderSwingObj) then
      local nCurState = SpiderSwingObj:GetCurMoveState()
      if nCurState == ESpiderSwingMoveState.Launching or nCurState == ESpiderSwingMoveState.Swinging then
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end
_G.LexusConfig = _G.LexusConfig or {}
_G.LexusConfig.IpadView = _G.LexusConfig.IpadView or false
_G.LexusState = _G.LexusState or {}
_G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
_G.LexusState.CustomTextData.IpadViewFOV = _G.LexusState.CustomTextData.IpadViewFOV or 120

-- HEXA_GetLocalPlayer made by @HEXA CORE 
local function HEXA_GetLocalPlayer()
    local ok, GDP = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not ok or not GDP then return nil end
    local player = GDP.GetPlayerCharacter()
    if player and slua.isValid(player) then return player end
    return nil
end

-- HEXA_ApplyiPadView made by @HEXA CORE 
local function HEXA_ApplyiPadView()
    if not BRPlayerLicenseActive() then return end
    local player = HEXA_GetLocalPlayer()
    if not player then return end
    local cam = player.ThirdPersonCameraComponent
    if not cam or not slua.isValid(cam) then return end
    if player.bIsWeaponAiming then return end

    if _G.LexusConfig.IpadView then
        local targetFOV = _G.LexusState.CustomTextData.IpadViewFOV or 120
        if cam.FieldOfView ~= targetFOV then
            cam.FieldOfView = targetFOV
        end
    else
        if cam.FieldOfView ~= 90 then
            cam.FieldOfView = 90
        end
    end
end

-- Settings UI made by @HEXA CORE 
local function HEXA_InitHackMenu()
    if not BRPlayerLicenseActive() then return end
    if _G.HackMenuInitialized then return end
    _G.HackMenuInitialized = true

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

    local Stack = {
        { Key = "HackMenu_IpadView", UI = AliasMap.Switcher, Text = "iPad View",
          GetFunc = function() return _G.LexusConfig.IpadView end,
          SetFunc = function(c, v) _G.LexusConfig.IpadView = v return true end }
    }

    if not SettingPageDefine.HackMenu then
        SettingPageDefine.HackMenu = {
            Key = "HEXA CORE LUCIFER ",
            Text = "HEXA CORE LUCIFER ",
            UIKey = "Setting_Page_Privacy",
            Category = {
                { Key = "Cat_Hack", Text = "Hack Features", Stack = Stack }
            }
        }
        table.insert(SettingCatalog, 1, SettingPageDefine.HackMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._HackMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...)
            if config and config.keyName then
                local lowerKeyName = string.lower(config.keyName)
                if string.find(lowerKeyName, "setting_main") and not string.find(lowerKeyName, "custom") then
                    local catalog = args[1]
                    if type(catalog) == "table" and catalog[1] and type(catalog[1]) == "table" and catalog[1].Key then
                        local hasHackMenu = false
                        for _, page in ipairs(catalog) do
                            if type(page) == "table" and page.Key == "HEXA CORE LUCIFER " then
                                hasHackMenu = true
                                break
                            end
                        end
                        if not hasHackMenu then
                            table.insert(catalog, 1, SettingPageDefine.HackMenu)
                        end
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._HackMenuHooked = true
    end
end

-- ============================================================================
-- SIMPLE RECTANGLE KILL COUNTER CONFIG
-- ============================================================================
_G.HEXA_MasterShotESP = _G.HEXA_MasterShotESP or {
    Enabled = true,
    MaxRangeMeters = 400.0,
    ScanInterval = 0.35,
    UpdateInterval = 0.033,
    TransformInterval = 0.50,
    MaxRendered = 24,

    CounterY = 36.0,
    CounterWidth = 240.0,
    CounterHeight = 32.0,

    TracerThickness = 1.80,
    NameGap = 2.0,
    NameFontSize = 10,
    DistanceFontSize = 8,
    DistanceBelowFeet = 8.0,
}

_G.MasterShotESP = _G.HEXA_MasterShotESP

local HEXA_ShotESP = {
    Canvas = nil,
    Counter = nil,
    Enemies = {},
    Lines = {},
    Names = {},
    LastScanClock = -999.0,
    LastTransformClock = -999.0,
    LastWorld = nil,
    TracerOrigin = nil,
    CanvasScaleX = 1.0,
    CanvasScaleY = 1.0,
    CanvasOffsetX = 0.0,
    CanvasOffsetY = 0.0,
}

local V2 = _G.FVector2D
if not V2 then pcall(function() V2 = import("Vector2D") end) end
local LinearColor = _G.FLinearColor
if not LinearColor then pcall(function() LinearColor = import("LinearColor") end) end
local SlateBlueprintLibrary = nil
pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") end)
local WidgetLayoutLibrary = nil
pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") end)
local SlateColor = nil
pcall(function() SlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor") end)
local GameplayStaticsESP = nil
pcall(function() GameplayStaticsESP = import("GameplayStatics") end)

local function HEXA_ESPV2(x, y)
    if V2 then return V2(x, y) end
    return {X = x, Y = y}
end

local function HEXA_ESPColor(r, g, b, a)
    if LinearColor then return LinearColor(r, g, b, a or 1.0) end
    return {R=r, G=g, B=b, A=a or 1.0}
end

-- ===== SIMPLE COLORS: RED (REAL) + GREEN (BOT) =====
local ESP_REAL = HEXA_ESPColor(0.95, 0.15, 0.15, 1.0)   -- RED
local ESP_BOT  = HEXA_ESPColor(0.10, 0.85, 0.20, 1.0)   -- GREEN
local ESP_WHITE = HEXA_ESPColor(1.0, 1.0, 1.0, 1.0)
local ESP_BLACK = HEXA_ESPColor(0.0, 0.0, 0.0, 1.0)

local function HEXA_ESPValid(obj)
    if not obj then return false end
    local ok, valid = pcall(function() return slua.isValid(obj) end)
    return ok and valid == true
end

local function HEXA_ESPNow()
    local t = nil
    pcall(function()
        local w = (slua and slua.getWorld and slua.getWorld()) or nil
        if GameplayStaticsESP and w and GameplayStaticsESP.GetRealTimeSeconds then
            t = GameplayStaticsESP.GetRealTimeSeconds(w)
        end
    end)
    if tonumber(t) then return tonumber(t) end
    pcall(function() if os and os.clock then t = os.clock() end end)
    return tonumber(t) or 0.0
end

local function HEXA_ESPWorld()
    local w = nil
    pcall(function() if slua and slua.getWorld then w = slua.getWorld() end end)
    return w
end

local function HEXA_ESPGetController()
    local pc = nil
    pcall(function()
        local GDP = require("GameLua.GameCore.Data.GameplayData")
        if GDP and GDP.GetPlayerController then pc = GDP.GetPlayerController() end
    end)
    if not HEXA_ESPValid(pc) then
        pcall(function()
            if slua_GameFrontendHUD then pc = slua_GameFrontendHUD:GetPlayerController() end
        end)
    end
    return HEXA_ESPValid(pc) and pc or nil
end

local function HEXA_ESPGetLocalCharacter()
    local c = nil
    pcall(function()
        local GDP = require("GameLua.GameCore.Data.GameplayData")
        if GDP then
            if GDP.GetPlayerCharacter then c = GDP.GetPlayerCharacter() end
            if not HEXA_ESPValid(c) and GDP.GetLocalCharacter then c = GDP.GetLocalCharacter() end
        end
    end)
    if not HEXA_ESPValid(c) then
        local pc = HEXA_ESPGetController()
        pcall(function() if pc and pc.GetPawn then c = pc:GetPawn() end end)
    end
    return HEXA_ESPValid(c) and c or nil
end

local function HEXA_ESPGetPlayerState(character)
    if not HEXA_ESPValid(character) then return nil end
    local ps = nil
    pcall(function()
        if character.GetPlayerStateSafety then ps = character:GetPlayerStateSafety() end
    end)
    if not HEXA_ESPValid(ps) then
        pcall(function() if character.GetPlayerState then ps = character:GetPlayerState() end end)
    end
    if not HEXA_ESPValid(ps) then
        pcall(function() ps = character.PlayerState end)
    end
    return HEXA_ESPValid(ps) and ps or nil
end

local function HEXA_ESPNormalizeName(value)
    if value == nil or value == false then return nil end
    local ok, text = pcall(tostring, value)
    if not ok or not text then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" or text == "nil" or text == "None" or text == "NULL" then return nil end
    return text
end

local function HEXA_ESPResolvePlayerName(character)
    if not HEXA_ESPValid(character) then return nil end
    local name = nil
    local function take(value)
        if not name then name = HEXA_ESPNormalizeName(value) end
    end
    pcall(function() if character.GetPlayerNameSafety then take(character:GetPlayerNameSafety()) end end)
    pcall(function() if not name and character.GetPlayerName then take(character:GetPlayerName()) end end)
    pcall(function() if not name then take(character.PlayerName) end end)
    pcall(function() if not name then take(character.NickName) end end)
    if not name then
        local ps = HEXA_ESPGetPlayerState(character)
        if ps then
            pcall(function() if ps.GetPlayerName then take(ps:GetPlayerName()) end end)
            pcall(function() if not name then take(ps.PlayerName) end end)
            pcall(function() if not name then take(ps.PlayerNamePrivate) end end)
            pcall(function() if not name then take(ps.NickName) end end)
        end
    end
    return name
end

local function HEXA_ESPGetPlayerKey(character)
    local key = nil
    pcall(function() if character.GetPlayerKey then key = character:GetPlayerKey() end end)
    if key == nil then pcall(function() key = character.PlayerKey end) end
    if key == nil then
        local ps = HEXA_ESPGetPlayerState(character)
        if ps then pcall(function() key = ps.PlayerKey end) end
    end
    return tostring(key or character)
end

local function HEXA_ESPGetTeamID(character)
    if not HEXA_ESPValid(character) then return nil end
    local id = nil
    pcall(function() if character.GetTeamID then id = character:GetTeamID() end end)
    if id == nil then pcall(function() id = character.TeamID end) end
    if id == nil then
        local ps = HEXA_ESPGetPlayerState(character)
        if ps then
            pcall(function() if ps.GetTeamID then id = ps:GetTeamID() end end)
            if id == nil then pcall(function() id = ps.TeamID end) end
        end
    end
    return id
end

local function HEXA_ESPIsAlive(character)
    if not HEXA_ESPValid(character) then return false end
    local alive = nil
    pcall(function() if character.IsAlive then alive = character:IsAlive() end end)
    if type(alive) == "boolean" then return alive end
    local hp = nil
    pcall(function() hp = character.Health end)
    if type(hp) ~= "number" then pcall(function() hp = character.HP end) end
    if type(hp) == "number" then return hp > 0 end
    return true
end

local function HEXA_ESPIsBot(character)
    if not HEXA_ESPValid(character) then return false end
    local result = nil
    local function take(v)
        if result == nil and (v == true or v == false or v == 1 or v == 0) then result = (v == true or v == 1) end
    end
    pcall(function() if Game and Game.IsAI then take(Game:IsAI(character)) end end)
    pcall(function() take(character.bIsAI) end)
    pcall(function() if character.IsBot then take(character:IsBot()) end end)
    local ps = HEXA_ESPGetPlayerState(character)
    if ps then
        pcall(function() take(ps.bIsABot) end)
        pcall(function() take(ps.bIsBot) end)
        pcall(function() take(ps.bIsAI) end)
        pcall(function() if ps.IsBot then take(ps:IsBot()) end end)
    end
    return result == true
end

local function HEXA_ESPActorLocation(character)
    local loc = nil
    if not HEXA_ESPValid(character) then return nil end
    pcall(function()
        if character.K2_GetActorLocation then loc = character:K2_GetActorLocation()
        elseif Game and Game.GetActorLocation then loc = Game:GetActorLocation(character) end
    end)
    return loc
end

local function HEXA_ESPDistanceMeters(a, b)
    if not a or not b then return math.huge end
    local dx, dy, dz = a.X-b.X, a.Y-b.Y, a.Z-b.Z
    return math.sqrt(dx*dx + dy*dy + dz*dz) / 100.0
end

local function HEXA_ESPGetCharacterVerticalBounds(character)
    if not HEXA_ESPValid(character) then return nil, nil end
    local center, halfHeight = nil, nil
    local capsule = nil
    pcall(function()
        if character.GetCapsuleComponent then
            capsule = character:GetCapsuleComponent()
        elseif character.CapsuleComponent then
            capsule = character.CapsuleComponent
        end
    end)
    if capsule and HEXA_ESPValid(capsule) then
        pcall(function()
            if capsule.K2_GetComponentLocation then
                center = capsule:K2_GetComponentLocation()
            elseif capsule.GetComponentLocation then
                center = capsule:GetComponentLocation()
            end
            if capsule.GetScaledCapsuleHalfHeight then
                halfHeight = capsule:GetScaledCapsuleHalfHeight()
            elseif capsule.GetUnscaledCapsuleHalfHeight then
                halfHeight = capsule:GetUnscaledCapsuleHalfHeight()
            elseif capsule.CapsuleHalfHeight then
                halfHeight = capsule.CapsuleHalfHeight
            end
        end)
    end
    if not center then
        pcall(function()
            if character.K2_GetActorLocation then
                center = character:K2_GetActorLocation()
            end
        end)
    end
    if not center then
        pcall(function()
            if Game and Game.GetActorLocation then
                center = Game:GetActorLocation(character)
            end
        end)
    end
    if not center then return nil, nil end
    if not halfHeight or halfHeight < 10 or halfHeight > 200 then
        halfHeight = 85
        pcall(function()
            if character.bIsCrouched then halfHeight = 60 end
            if character.IsProne and character:IsProne() then halfHeight = 25 end
        end)
    end
    return center, halfHeight
end

local function HEXA_ESPGetCharacterBoxLocs(character)
    local center, halfHeight = HEXA_ESPGetCharacterVerticalBounds(character)
    if not center or not halfHeight then return nil, nil end
    local headLoc = { X = center.X, Y = center.Y, Z = center.Z + halfHeight }
    local feetLoc = { X = center.X, Y = center.Y, Z = center.Z - halfHeight }
    return headLoc, feetLoc
end

local function HEXA_ESPHeadLocation(character)
    local headLoc = HEXA_ESPGetCharacterBoxLocs(character)
    return headLoc
end

local function HEXA_ESPFootLocation(character)
    local _, feetLoc = HEXA_ESPGetCharacterBoxLocs(character)
    return feetLoc
end

local function HEXA_ESPDestroyWidgetData(data)
    if not data then return end
    local widget = data.Widget or data.Container
    if HEXA_ESPValid(widget) then
        pcall(function() widget:RemoveFromParent() end)
        pcall(function() widget:ConditionalBeginDestroy() end)
    end
end

local function HEXA_ESPResetWidgets()
    for _, data in pairs(HEXA_ShotESP.Lines) do HEXA_ESPDestroyWidgetData(data) end
    for _, data in pairs(HEXA_ShotESP.Names) do HEXA_ESPDestroyWidgetData(data) end
    HEXA_ShotESP.Lines = {}
    HEXA_ShotESP.Names = {}
    if HEXA_ShotESP.Counter then HEXA_ESPDestroyWidgetData(HEXA_ShotESP.Counter) end
    HEXA_ShotESP.Counter = nil
    HEXA_ShotESP.Canvas = nil
    HEXA_ShotESP.Enemies = {}
end

local function HEXA_ESPGetCanvas()
    if HEXA_ESPValid(HEXA_ShotESP.Canvas) then return HEXA_ShotESP.Canvas end
    local root = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        if InGameUITools and InGameUITools.GetMainControlBaseUI then root = InGameUITools.GetMainControlBaseUI() end
    end)
    if not HEXA_ESPValid(root) then return nil end
    local canvas = nil
    pcall(function()
        if HEXA_ESPValid(root.CanvasPanel_0) then canvas = root.CanvasPanel_0
        elseif HEXA_ESPValid(root.CanvasPanel_42) then canvas = root.CanvasPanel_42 end
    end)
    if HEXA_ESPValid(canvas) then HEXA_ShotESP.Canvas = canvas return canvas end
    return nil
end

local function HEXA_ESPViewport(pc)
    local w, h = 1920.0, 1080.0
    pcall(function()
        if pc and pc.GetViewportSize then
            local v = HEXA_ESPV2(0,0)
            pc:GetViewportSize(v)
            if v and tonumber(v.X) and v.X > 200 then w, h = v.X, v.Y end
        end
    end)
    return w, h
end

local function HEXA_ESPGetCanvasLocalSize()
    local canvas = HEXA_ESPGetCanvas()
    if not HEXA_ESPValid(canvas) then return nil, nil end
    local cw, ch = nil, nil
    pcall(function()
        local geo = canvas:GetCachedGeometry()
        if not geo then return end
        local size = nil
        if geo.GetLocalSize then
            size = geo:GetLocalSize()
        elseif SlateBlueprintLibrary and SlateBlueprintLibrary.GetLocalSize then
            size = SlateBlueprintLibrary.GetLocalSize(geo)
        end
        if size and tonumber(size.X) and tonumber(size.Y) and size.X > 1 and size.Y > 1 then
            cw, ch = tonumber(size.X), tonumber(size.Y)
        end
    end)
    return cw, ch
end

local function HEXA_ESPUpdateCanvasTransform(pc)
    local canvas = HEXA_ESPGetCanvas()
    if not HEXA_ESPValid(canvas) then return false end
    local calibrated = false
    pcall(function()
        if SlateBlueprintLibrary and SlateBlueprintLibrary.AbsoluteToLocal then
            local geo = canvas:GetCachedGeometry()
            if geo then
                local p0 = SlateBlueprintLibrary.AbsoluteToLocal(geo, HEXA_ESPV2(0, 0))
                local p1 = SlateBlueprintLibrary.AbsoluteToLocal(geo, HEXA_ESPV2(100, 100))
                if p0 and p1
                    and tonumber(p0.X) and tonumber(p0.Y)
                    and tonumber(p1.X) and tonumber(p1.Y)
                    and p1.X ~= p0.X and p1.Y ~= p0.Y then
                    HEXA_ShotESP.CanvasScaleX = (p1.X - p0.X) / 100.0
                    HEXA_ShotESP.CanvasScaleY = (p1.Y - p0.Y) / 100.0
                    HEXA_ShotESP.CanvasOffsetX = p0.X
                    HEXA_ShotESP.CanvasOffsetY = p0.Y
                    calibrated = true
                end
            end
        end
    end)
    if not calibrated then
        local scale = 1.0
        pcall(function()
            if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
                local s = WidgetLayoutLibrary.GetViewportScale(pc)
                if tonumber(s) and s > 0 then scale = s end
            end
        end)
        HEXA_ShotESP.CanvasScaleX = 1.0 / scale
        HEXA_ShotESP.CanvasScaleY = 1.0 / scale
        HEXA_ShotESP.CanvasOffsetX = 0.0
        HEXA_ShotESP.CanvasOffsetY = 0.0
    end
    return true
end

local function HEXA_ESPProject(pc, worldLoc)
    if not pc or not worldLoc then return nil end
    local pix = HEXA_ESPV2(0, 0)
    local ok = false
    pcall(function()
        local res = pc:ProjectWorldLocationToScreen(worldLoc, pix, true)
        ok = (res == true or res == 1 or (pix and (pix.X ~= 0 or pix.Y ~= 0)))
    end)
    if not ok then return nil end
    local sx = HEXA_ShotESP.CanvasScaleX or 1.0
    local sy = HEXA_ShotESP.CanvasScaleY or 1.0
    local ox = HEXA_ShotESP.CanvasOffsetX or 0.0
    local oy = HEXA_ShotESP.CanvasOffsetY or 0.0
    return HEXA_ESPV2(pix.X * sx + ox, pix.Y * sy + oy)
end

local function HEXA_ESPSetFont(textWidget, size, outlineSize)
    if not HEXA_ESPValid(textWidget) then return end
    pcall(function()
        local f = textWidget.Font
        if f then
            f.Size = size
            if outlineSize and outlineSize > 0 and f.OutlineSettings then
                pcall(function() f.OutlineSettings.OutlineSize = outlineSize end)
                pcall(function() f.OutlineSettings.OutlineColor = ESP_BLACK end)
            end
            textWidget:SetFont(f)
        end
        if outlineSize and outlineSize > 0 then
            if textWidget.SetShadowOffset then textWidget:SetShadowOffset(HEXA_ESPV2(1.0, 1.0)) end
            if textWidget.SetShadowColorAndOpacity then textWidget:SetShadowColorAndOpacity(ESP_BLACK) end
        end
    end)
end

local function HEXA_ESPSetTextColor(textWidget, color)
    if not HEXA_ESPValid(textWidget) then return end
    pcall(function()
        if SlateColor then textWidget:SetColorAndOpacity(SlateColor(color))
        else textWidget:SetColorAndOpacity(color) end
    end)
end

-- ============================================================
-- WHITE TRACER LINE
-- ============================================================
local function HEXA_ESPCreateLine(color)
    local canvas = HEXA_ESPGetCanvas()
    if not HEXA_ESPValid(canvas) then return nil end
    local border = nil
    pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", canvas) end)
    if not HEXA_ESPValid(border) then return nil end
    pcall(function()
        border:SetBrushColor(ESP_WHITE)
        border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        border:SetRenderTransformPivot(HEXA_ESPV2(0.0, 0.5))
    end)
    local slot = nil
    pcall(function() slot = canvas:AddChildToCanvas(border) end)
    if not slot then HEXA_ESPDestroyWidgetData({Widget=border}) return nil end
    pcall(function() slot:SetAutoSize(false) slot:SetZOrder(30) end)
    return {Widget=border, Slot=slot}
end

local function HEXA_ESPDrawLine(data, x1, y1, x2, y2, thickness)
    if not data or not HEXA_ESPValid(data.Widget) or not data.Slot then return false end
    local dx, dy = x2-x1, y2-y1
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 1 then return false end
    local angle = ((math.atan2 and math.atan2(dy, dx)) or math.atan(dy, dx)) * 180.0 / math.pi
    pcall(function()
        data.Slot:SetPosition(HEXA_ESPV2(x1, y1 - thickness*0.5))
        data.Slot:SetSize(HEXA_ESPV2(len, thickness))
        data.Widget:SetRenderAngle(angle)
        data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
    return true
end

local function HEXA_ESPCreateNameTag(isBot)
    local canvas = HEXA_ESPGetCanvas()
    if not HEXA_ESPValid(canvas) then return nil end
    local container, nameText, distanceText = nil, nil, nil
    pcall(function() container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
    if not HEXA_ESPValid(container) then return nil end
    pcall(function() nameText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
    pcall(function() distanceText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
    if not HEXA_ESPValid(nameText) or not HEXA_ESPValid(distanceText) then
        HEXA_ESPDestroyWidgetData({Widget=container})
        return nil
    end
    pcall(function()
        nameText:SetText("")
        distanceText:SetText("")
        nameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        distanceText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        if nameText.SetJustification then nameText:SetJustification(1) end
        if distanceText.SetJustification then distanceText:SetJustification(1) end
    end)
    HEXA_ESPSetTextColor(nameText, ESP_WHITE)
    HEXA_ESPSetTextColor(distanceText, ESP_WHITE)
    HEXA_ESPSetFont(nameText, tonumber(_G.HEXA_MasterShotESP.NameFontSize) or 10, 1)
    HEXA_ESPSetFont(distanceText, tonumber(_G.HEXA_MasterShotESP.DistanceFontSize) or 8, 1)
    local nameSlot, distanceSlot, mainSlot = nil, nil, nil
    pcall(function() nameSlot = container:AddChildToCanvas(nameText) end)
    pcall(function() distanceSlot = container:AddChildToCanvas(distanceText) end)
    pcall(function() mainSlot = canvas:AddChildToCanvas(container) end)
    if not nameSlot or not distanceSlot or not mainSlot then
        HEXA_ESPDestroyWidgetData({Widget=container})
        return nil
    end
    pcall(function()
        nameSlot:SetAutoSize(true)
        nameSlot:SetAlignment(HEXA_ESPV2(0.5, 0.5))
        nameSlot:SetZOrder(2)
        distanceSlot:SetAutoSize(true)
        distanceSlot:SetAlignment(HEXA_ESPV2(0.5, 0.5))
        distanceSlot:SetZOrder(2)
        mainSlot:SetAutoSize(false)
        mainSlot:SetZOrder(35)
    end)
    return {
        Widget = container,
        Text = nameText,
        DistanceText = distanceText,
        TextSlot = nameSlot,
        DistanceSlot = distanceSlot,
        Slot = mainSlot,
        IsBot = isBot
    }
end

local function HEXA_ESPUpdateNameTag(key, character, headScreen, footScreen, isBot, distance)
    local data = HEXA_ShotESP.Names[key]
    local name = data and data.CachedName or nil
    if not name then
        name = HEXA_ESPResolvePlayerName(character)
        if data and name then data.CachedName = name end
    end
    if not name or not headScreen then
        if data and HEXA_ESPValid(data.Widget) then
            pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        end
        return
    end
    if not data or not HEXA_ESPValid(data.Widget) then
        HEXA_ESPDestroyWidgetData(data)
        data = HEXA_ESPCreateNameTag(isBot)
        HEXA_ShotESP.Names[key] = data
        if data then data.CachedName = name end
    end
    if not data then return end
    local dist = math.max(0, math.floor((tonumber(distance) or 0) + 0.5))
    local distanceLabel = string.format("[%d m]", dist)
    local chars = math.max(#name, #distanceLabel)
    local width = math.max(78.0, math.min(220.0, 18.0 + chars * 6.0))
    local nameHeight = 18.0
    local gap = tonumber(_G.HEXA_MasterShotESP.NameGap) or 2.0
    local x = headScreen.X - width * 0.5
    local y = headScreen.Y - nameHeight - gap
    local distanceY = nameHeight + 4.0
    if footScreen and tonumber(footScreen.X) and tonumber(footScreen.Y) then
        distanceY = (footScreen.Y - y) + (tonumber(_G.HEXA_MasterShotESP.DistanceBelowFeet) or 8.0)
    end
    local totalHeight = math.max(34.0, distanceY + 12.0)
    pcall(function()
        if data.LastName ~= name then
            data.Text:SetText(name)
            data.LastName = name
        end
        if data.LastDistance ~= distanceLabel then
            data.DistanceText:SetText(distanceLabel)
            data.LastDistance = distanceLabel
        end
        data.Slot:SetPosition(HEXA_ESPV2(x, y))
        data.Slot:SetSize(HEXA_ESPV2(width, totalHeight))
        data.TextSlot:SetPosition(HEXA_ESPV2(width * 0.5, nameHeight * 0.5))
        local distX = width * 0.5
        if footScreen and tonumber(footScreen.X) then
            distX = footScreen.X - x
        end
        data.DistanceSlot:SetPosition(HEXA_ESPV2(distX, distanceY))
        data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
end

-- ============================================================
-- SIMPLE RECTANGLE COUNTER — RED (REAL) + GREEN (BOT)
-- ============================================================
local function HEXA_ESPCreateCounter()
    local canvas = HEXA_ESPGetCanvas()
    if not HEXA_ESPValid(canvas) then return nil end

    local container = nil
    pcall(function() container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
    if not HEXA_ESPValid(container) then return nil end

    local function newBorder()
        local w = nil
        pcall(function() w = CGame:NewObjectFromPath("/Script/UMG.Border", container) end)
        return w
    end
    local function newText()
        local w = nil
        pcall(function() w = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
        return w
    end

    -- RED panel (REAL) — 2 layers (dark outline + bright fill)
    local realOuter, realInner = newBorder(), newBorder()
    -- GREEN panel (BOT) — 2 layers
    local botOuter, botInner = newBorder(), newBorder()
    -- Text
    local realText, botText = newText(), newText()

    for _, w in ipairs({realOuter, realInner, botOuter, botInner, realText, botText}) do
        if not HEXA_ESPValid(w) then
            HEXA_ESPDestroyWidgetData({Widget=container})
            return nil
        end
    end

    pcall(function()
        -- RED (REAL)
        realOuter:SetBrushColor(HEXA_ESPColor(0.15, 0.02, 0.02, 1.0))
        realInner:SetBrushColor(ESP_REAL)

        -- GREEN (BOT)
        botOuter:SetBrushColor(HEXA_ESPColor(0.02, 0.15, 0.03, 1.0))
        botInner:SetBrushColor(ESP_BOT)

        for _, w in ipairs({realOuter, realInner, botOuter, botInner, realText, botText}) do
            w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end

        realText:SetText("REAL: 0")
        botText:SetText("BOT: 0")
        if realText.SetJustification then realText:SetJustification(1) end
        if botText.SetJustification then botText:SetJustification(1) end
    end)

    HEXA_ESPSetTextColor(realText, ESP_WHITE)
    HEXA_ESPSetTextColor(botText, ESP_WHITE)
    HEXA_ESPSetFont(realText, 14, 1)
    HEXA_ESPSetFont(botText, 14, 1)

    local slots = {}
    local function add(name, widget)
        local s = nil
        pcall(function() s = container:AddChildToCanvas(widget) end)
        slots[name] = s
        return s
    end

    add("realOuter", realOuter)
    add("realInner", realInner)
    add("botOuter", botOuter)
    add("botInner", botInner)
    add("realText", realText)
    add("botText", botText)

    local mainSlot = nil
    pcall(function() mainSlot = canvas:AddChildToCanvas(container) end)
    if not mainSlot then
        HEXA_ESPDestroyWidgetData({Widget=container})
        return nil
    end

    -- Simple Rectangle Layout
    local width   = 240.0
    local height  = 32.0
    local gap     = 8.0
    local panelW  = (width - gap) * 0.5

    pcall(function()
        local function setBox(slot, x, y, w, h, z)
            if slot then
                slot:SetAutoSize(false)
                slot:SetPosition(HEXA_ESPV2(x, y))
                slot:SetSize(HEXA_ESPV2(w, h))
                if z then slot:SetZOrder(z) end
            end
        end

        -- RED (left)
        setBox(slots.realOuter, 0, 0, panelW, height, 1)
        setBox(slots.realInner, 2, 2, panelW - 4, height - 4, 2)

        -- GREEN (right)
        local rx = panelW + gap
        setBox(slots.botOuter, rx, 0, panelW, height, 1)
        setBox(slots.botInner, rx + 2, 2, panelW - 4, height - 4, 2)

        -- Text centered
        slots.realText:SetAutoSize(true)
        slots.botText:SetAutoSize(true)
        slots.realText:SetAlignment(HEXA_ESPV2(0.5, 0.5))
        slots.botText:SetAlignment(HEXA_ESPV2(0.5, 0.5))
        slots.realText:SetPosition(HEXA_ESPV2(panelW * 0.5, height * 0.5))
        slots.botText:SetPosition(HEXA_ESPV2(rx + panelW * 0.5, height * 0.5))
        slots.realText:SetZOrder(10)
        slots.botText:SetZOrder(10)

        mainSlot:SetAutoSize(false)
        mainSlot:SetSize(HEXA_ESPV2(width, height))
        mainSlot:SetZOrder(60)
    end)

    return {
        Widget=container, Slot=mainSlot,
        RealText=realText, BotText=botText,
        Width=width, Height=height,
        Slots=slots
    }
end

local function HEXA_ESPUpdateCounter(realCount, botCount, pc)
    local data = HEXA_ShotESP.Counter
    if not data or not HEXA_ESPValid(data.Widget) then
        data = HEXA_ESPCreateCounter()
        HEXA_ShotESP.Counter = data
    end
    if not data then return nil end

    local cw = HEXA_ESPGetCanvasLocalSize()
    local centerX = nil
    if tonumber(cw) and cw > 1 then
        centerX = cw * 0.5
    else
        local vw = HEXA_ESPViewport(pc)
        centerX = (vw * 0.5) * (HEXA_ShotESP.CanvasScaleX or 1.0)
            + (HEXA_ShotESP.CanvasOffsetX or 0.0)
    end
    if not centerX then return nil end

    local counterY = tonumber(_G.HEXA_MasterShotESP.CounterY) or 36.0

    if data.LastReal ~= realCount then
        pcall(function() data.RealText:SetText(string.format("REAL: %d", realCount or 0)) end)
        data.LastReal = realCount
    end
    if data.LastBot ~= botCount then
        pcall(function() data.BotText:SetText(string.format("BOT: %d", botCount or 0)) end)
        data.LastBot = botCount
    end

    pcall(function()
        data.Slot:SetPosition(HEXA_ESPV2(centerX - data.Width * 0.5, counterY))
        data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)

    local anchorX = centerX
    local anchorY = counterY + data.Height + 2.0

    data.AnchorX = anchorX
    data.AnchorY = anchorY
    HEXA_ShotESP.TracerOrigin = HEXA_ESPV2(anchorX, anchorY)
    return HEXA_ShotESP.TracerOrigin
end

local function HEXA_ESPScanEnemies()
    local pc = HEXA_ESPGetController()
    local me = HEXA_ESPGetLocalCharacter()
    if not pc or not me then HEXA_ShotESP.Enemies = {} return nil, 0, 0 end
    local myLoc = HEXA_ESPActorLocation(me)
    if not myLoc then HEXA_ShotESP.Enemies = {} return pc, 0, 0 end
    local myTeam = HEXA_ESPGetTeamID(me)
    local list = {}
    local realCount, botCount = 0, 0
    local pawns = nil
    pcall(function() if Game and Game.GetAllPlayerPawns then pawns = Game:GetAllPlayerPawns() end end)
    if pawns then
        for _, character in pairs(pawns) do
            if HEXA_ESPValid(character) and character ~= me and HEXA_ESPIsAlive(character) then
                local team = HEXA_ESPGetTeamID(character)
                if myTeam == nil or team == nil or tostring(team) ~= tostring(myTeam) then
                    local loc = HEXA_ESPActorLocation(character)
                    local dist = HEXA_ESPDistanceMeters(myLoc, loc)
                    if dist <= (tonumber(_G.HEXA_MasterShotESP.MaxRangeMeters) or 400.0) then
                        local isBot = HEXA_ESPIsBot(character)
                        if isBot then botCount = botCount + 1 else realCount = realCount + 1 end
                        list[#list+1] = {Character=character, Key=HEXA_ESPGetPlayerKey(character), IsBot=isBot, Distance=dist}
                    end
                end
            end
        end
    end
    table.sort(list, function(a,b) return (a.Distance or 99999) < (b.Distance or 99999) end)
    HEXA_ShotESP.Enemies = list
    return pc, realCount, botCount
end

local function HEXA_ESPPrune(active)
    for key, data in pairs(HEXA_ShotESP.Lines) do
        if not active[key] then HEXA_ESPDestroyWidgetData(data) HEXA_ShotESP.Lines[key] = nil end
    end
    for key, data in pairs(HEXA_ShotESP.Names) do
        if not active[key] then HEXA_ESPDestroyWidgetData(data) HEXA_ShotESP.Names[key] = nil end
    end
end

local function HEXA_ESPUpdate()
    if not BRPlayerLicenseActive() then
        HEXA_ESPResetWidgets()
        return
    end
    if not _G.HEXA_MasterShotESP.Enabled then
        HEXA_ESPResetWidgets()
        return
    end
    local world = HEXA_ESPWorld()
    if world ~= HEXA_ShotESP.LastWorld then
        HEXA_ESPResetWidgets()
        HEXA_ShotESP.LastWorld = world
        HEXA_ShotESP.LastScanClock = -999.0
        HEXA_ShotESP.LastTransformClock = -999.0
        HEXA_ShotESP.TracerOrigin = nil
    end
    local canvas = HEXA_ESPGetCanvas()
    if not canvas then return end
    local now = HEXA_ESPNow()
    local pc = HEXA_ESPGetController()
    local realCount, botCount = nil, nil
    if (now - HEXA_ShotESP.LastScanClock) >= (tonumber(_G.HEXA_MasterShotESP.ScanInterval) or 0.30) then
        pc, realCount, botCount = HEXA_ESPScanEnemies()
        HEXA_ShotESP.LastScanClock = now
        HEXA_ShotESP.RealCount, HEXA_ShotESP.BotCount = realCount, botCount
    end
    pc = pc or HEXA_ESPGetController()
    if not pc then return end
    if (now - (HEXA_ShotESP.LastTransformClock or -999.0))
        >= (tonumber(_G.HEXA_MasterShotESP.TransformInterval) or 0.50) then
        HEXA_ESPUpdateCanvasTransform(pc)
        HEXA_ShotESP.LastTransformClock = now
    end
    local originCenter = HEXA_ESPUpdateCounter(
        HEXA_ShotESP.RealCount or 0,
        HEXA_ShotESP.BotCount or 0,
        pc
    )
    if not originCenter then return end
    local active = {}
    local maxRendered = math.max(1, math.floor(tonumber(_G.HEXA_MasterShotESP.MaxRendered) or 24))
    for i, item in ipairs(HEXA_ShotESP.Enemies) do
        if i > maxRendered then break end
        local c = item.Character
        local key = item.Key
        if HEXA_ESPValid(c) and HEXA_ESPIsAlive(c) then
            local head = HEXA_ESPHeadLocation(c)
            local feet = HEXA_ESPFootLocation(c)
            local headScreen = HEXA_ESPProject(pc, head)
            local footScreen = HEXA_ESPProject(pc, feet)
            if headScreen then
                active[key] = true
                -- WHITE TRACER
                local line = HEXA_ShotESP.Lines[key]
                if not line or not HEXA_ESPValid(line.Widget) then
                    HEXA_ESPDestroyWidgetData(line)
                    line = HEXA_ESPCreateLine(ESP_WHITE)
                    HEXA_ShotESP.Lines[key] = line
                end
                if line then
                    HEXA_ESPDrawLine(
                        line,
                        originCenter.X,
                        originCenter.Y,
                        headScreen.X,
                        headScreen.Y,
                        tonumber(_G.HEXA_MasterShotESP.TracerThickness) or 1.80
                    )
                end
                HEXA_ESPUpdateNameTag(key, c, headScreen, footScreen, item.IsBot, item.Distance)
            end
        end
    end
    HEXA_ESPPrune(active)
end

local function HEXA_ESPTick()
    pcall(HEXA_ESPUpdate)
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(tonumber(_G.HEXA_MasterShotESP.UpdateInterval) or 0.03, HEXA_ESPTick)
    end
end

_G.HEXA_MasterShotESPForceRefresh = function()
    HEXA_ShotESP.LastScanClock = -999.0
    pcall(HEXA_ESPUpdate)
end

local function HEXA_FastTick()
    pcall(HEXA_ApplyiPadView)
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(5.0, HEXA_FastTick)
    end
end

-- ============================================================================
-- 9. ESP BOX RENDERER (WHITE) — @HEXA CORE
-- ============================================================================
local HEXA_ESPBoxRenderer = (function()
    local M = {}
    local FVector2D    = _G.FVector2D or import("Vector2D")
    local FLinearColor = _G.FLinearColor or import("LinearColor")

    M.BoxThickness   = 1.5
    M.BoxWidthFactor = 0.40

    -- ★ DONO WHITE ★
    M.RealStrokeColor = (FLinearColor and FLinearColor(1.0, 1.0, 1.0, 0.96)) or {R=1.0, G=1.0, B=1.0, A=0.96}
    M.BotStrokeColor  = (FLinearColor and FLinearColor(1.0, 1.0, 1.0, 0.96)) or {R=1.0, G=1.0, B=1.0, A=0.96}
    M.RealTheme = {Key = "REAL", Stroke = M.RealStrokeColor}
    M.BotTheme  = {Key = "BOT",  Stroke = M.BotStrokeColor}

    M.ESPCanvas = nil
    M.BoxWidgets = {}
    M._CanvasScaleX, M._CanvasScaleY = 1.0, 1.0
    M._CanvasOffsetX, M._CanvasOffsetY = 0.0, 0.0
    M._CachedPC = nil
    M._CapsuleCache = setmetatable({}, {__mode = "k"})
    M._AITypeCache = {}
    M._AITypeRetryAt = {}
    M._Timer, M._TimerOwner, M._Active = nil, nil, false
    M._TickInterval = 0.02
    M._LastWorld = nil

    local function IsValid(obj)
        if obj == nil or slua == nil or type(slua.isValid) ~= "function" then return false end
        local ok, valid = pcall(slua.isValid, obj)
        return ok and valid == true
    end
    M.IsValid = IsValid

    function M.IsUIWidgetValid(w)
        if not w then return false end
        local ok, valid = pcall(function() return slua.isValid(w) end)
        return ok and valid == true
    end

    function M.CallUISetter(widget, method, ...)
        if not M.IsUIWidgetValid(widget) then return false end
        local setter = widget[method]
        if type(setter) ~= "function" then return false end
        return setter(widget, ...) ~= false
    end

    function M.GetMyPlayerController()
        local PC = M._CachedPC
        if PC and IsValid(PC) then return PC end
        pcall(function()
            if GameplayData and type(GameplayData.GetPlayerController) == "function" then
                PC = GameplayData.GetPlayerController()
            end
        end)
        if not (PC and IsValid(PC)) then
            pcall(function()
                if slua_GameFrontendHUD then
                    PC = slua_GameFrontendHUD:GetPlayerController()
                end
            end)
        end
        if PC and IsValid(PC) then M._CachedPC = PC end
        return PC
    end

    function M.InitESPCanvas(forceRefresh)
        local previous = M.ESPCanvas
        local previousValid = false
        pcall(function() previousValid = previous ~= nil and Game:IsValid(previous) end)
        if previousValid and not forceRefresh then return true end
        local InGameUITools = nil
        pcall(function()
            InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        end)
        if not InGameUITools then return previousValid end
        local MainControlBaseUI = nil
        pcall(function() MainControlBaseUI = InGameUITools.GetMainControlBaseUI() end)
        local uiValid = false
        pcall(function() uiValid = MainControlBaseUI ~= nil and Game:IsValid(MainControlBaseUI) end)
        if not uiValid then return previousValid end
        local ParentCanvas = nil
        pcall(function()
            local c = MainControlBaseUI.CanvasPanel_0
            if c and Game:IsValid(c) then ParentCanvas = c end
        end)
        if not ParentCanvas then
            pcall(function()
                local c = MainControlBaseUI.CanvasPanel_42
                if c and Game:IsValid(c) then ParentCanvas = c end
            end)
        end
        if not ParentCanvas then return previousValid end
        if ParentCanvas ~= previous then
            M.ClearAllBoxes()
            M.ESPCanvas = ParentCanvas
        end
        return true
    end

    function M.UpdateCanvasTransform(PC)
        if not M.ESPCanvas or not Game:IsValid(M.ESPCanvas) then return end
        local success = false
        pcall(function()
            local SBL = SlateBlueprintLibrary
            if SBL and SBL.AbsoluteToLocal then
                local cg = M.ESPCanvas:GetCachedGeometry()
                if cg then
                    local pt0 = SBL.AbsoluteToLocal(cg, FVector2D and FVector2D(0,0) or {X=0,Y=0})
                    local pt1 = SBL.AbsoluteToLocal(cg, FVector2D and FVector2D(100,100) or {X=100,Y=100})
                    if pt0 and pt1 and type(pt0.X) == "number" and type(pt1.X) == "number"
                        and pt1.X ~= pt0.X and pt1.Y ~= pt0.Y then
                        M._CanvasScaleX = (pt1.X - pt0.X) / 100
                        M._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                        M._CanvasOffsetX = pt0.X
                        M._CanvasOffsetY = pt0.Y
                        success = true
                    end
                end
            end
        end)
        if not success then
            local scale = 1.0
            pcall(function()
                local WLL = WidgetLayoutLibrary
                if WLL and WLL.GetViewportScale then
                    local c = WLL.GetViewportScale(PC)
                    if type(c) == "number" and c == c and c > 0 and c < math.huge then
                        scale = c
                    end
                end
            end)
            M._CanvasScaleX = 1.0 / scale
            M._CanvasScaleY = 1.0 / scale
            M._CanvasOffsetX = 0
            M._CanvasOffsetY = 0
        end
    end

    function M.ProjectToCanvas(PC, WorldLoc, Reuse)
        Reuse = Reuse or {}
        Reuse.Pix = Reuse.Pix or (FVector2D and FVector2D(0,0) or {X=0,Y=0})
        Reuse.Canvas = Reuse.Canvas or (FVector2D and FVector2D(0,0) or {X=0,Y=0})
        local Pix, Canvas = Reuse.Pix, Reuse.Canvas
        if not IsValid(PC) or not WorldLoc then
            Canvas.X, Canvas.Y = 0, 0
            return false, Canvas
        end
        Pix.X, Pix.Y = 0, 0
        local bOK = false
        pcall(function()
            local res = PC:ProjectWorldLocationToScreen(WorldLoc, Pix, true)
            bOK = (res == true or res == 1 or (Pix and (Pix.X ~= 0 or Pix.Y ~= 0)))
        end)
        if not bOK then
            Canvas.X, Canvas.Y = 0, 0
            return false, Canvas
        end
        local sx = M._CanvasScaleX or 1.0
        local sy = M._CanvasScaleY or 1.0
        local ox = M._CanvasOffsetX or 0
        local oy = M._CanvasOffsetY or 0
        Canvas.X = Pix.X * sx + ox
        Canvas.Y = Pix.Y * sy + oy
        return true, Canvas
    end

    function M.GetCharacterVerticalBounds(Character)
        if not IsValid(Character) then return nil, nil end
        local Center, HalfHeight = nil, nil
        local Capsule = M._CapsuleCache[Character]
        if not (Capsule and IsValid(Capsule)) then
            Capsule = nil
            pcall(function()
                if Character.GetCapsuleComponent then Capsule = Character:GetCapsuleComponent()
                elseif Character.CapsuleComponent then Capsule = Character.CapsuleComponent end
            end)
            if Capsule and IsValid(Capsule) then M._CapsuleCache[Character] = Capsule end
        end
        if Capsule and IsValid(Capsule) then
            pcall(function()
                if Capsule.K2_GetComponentLocation then Center = Capsule:K2_GetComponentLocation()
                elseif Capsule.GetComponentLocation then Center = Capsule:GetComponentLocation() end
                if Capsule.GetScaledCapsuleHalfHeight then HalfHeight = Capsule:GetScaledCapsuleHalfHeight()
                elseif Capsule.GetUnscaledCapsuleHalfHeight then HalfHeight = Capsule:GetUnscaledCapsuleHalfHeight()
                elseif Capsule.CapsuleHalfHeight then HalfHeight = Capsule.CapsuleHalfHeight end
            end)
        end
        if not Center then
            pcall(function()
                if Character.K2_GetActorLocation then Center = Character:K2_GetActorLocation() end
            end)
        end
        if not Center then
            pcall(function()
                if Game and Game.GetActorLocation then Center = Game:GetActorLocation(Character) end
            end)
        end
        if not Center then return nil, nil end
        if not HalfHeight or HalfHeight < 10 or HalfHeight > 200 then
            HalfHeight = 85
            pcall(function()
                if Character.bIsCrouched then HalfHeight = 60 end
                if Character.IsProne and Character:IsProne() then HalfHeight = 25 end
            end)
        end
        return Center, HalfHeight
    end

    function M.GetCharacterBoxLocs(Character)
        local Center, HalfHeight = M.GetCharacterVerticalBounds(Character)
        if not Center or not HalfHeight then return nil, nil end
        return {X = Center.X, Y = Center.Y, Z = Center.Z + HalfHeight},
               {X = Center.X, Y = Center.Y, Z = Center.Z - HalfHeight}
    end

    function M.IsAI(Character, KeyStr)
        if not IsValid(Character) then return false end
        KeyStr = KeyStr or tostring(Character)
        local cached = M._AITypeCache[KeyStr]
        if cached ~= nil then return cached end
        local now = os.clock()
        if now < (M._AITypeRetryAt[KeyStr] or 0) then return false end
        local bAI, hasSignal = false, false
        local function accept(v)
            if v == true or v == 1 then bAI, hasSignal = true, true
            elseif v == false or v == 0 then hasSignal = true end
        end
        local function readFlag(o, n) pcall(function() accept(o[n]) end) end
        local function callFlag(o, n)
            pcall(function()
                local m = o and o[n]
                if type(m) == "function" then accept(m(o)) end
            end)
        end
        pcall(function() if Game and Game.IsAI then accept(Game:IsAI(Character)) end end)
        if not bAI then readFlag(Character, "bIsAI") end
        if not bAI then readFlag(Character, "IsAI") end
        if not bAI then callFlag(Character, "IsBot") end
        if not bAI then
            local ps = nil
            pcall(function()
                if Character.GetPlayerStateSafety then ps = Character:GetPlayerStateSafety()
                elseif Character.GetPlayerState then ps = Character:GetPlayerState()
                elseif Character.PlayerState then ps = Character.PlayerState end
            end)
            if ps and IsValid(ps) then
                readFlag(ps, "bIsABot")
                if not bAI then readFlag(ps, "bIsBot") end
                if not bAI then readFlag(ps, "bIsAI") end
                if not bAI then callFlag(ps, "IsBot") end
            end
        end
        if hasSignal then M._AITypeCache[KeyStr] = bAI
        else M._AITypeRetryAt[KeyStr] = now + 1.0 end
        return bAI
    end

    function M.GetEnemyTheme(bIsAI)
        if bIsAI then return M.BotTheme end
        return M.RealTheme
    end

    function M.CreateLineWidget(color, zOrder)
        if not M.ESPCanvas or not Game:IsValid(M.ESPCanvas) then return nil end
        local Border = nil
        pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", M.ESPCanvas) end)
        if not Border or not slua.isValid(Border) then return nil end
        pcall(function() Border:SetBrushColor(color) end)
        pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        pcall(function()
            Border:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0, Y=0.5})
        end)
        local Slot = nil
        pcall(function()
            Slot = M.ESPCanvas:AddChildToCanvas(Border)
            if Slot then Slot:SetAutoSize(false) Slot:SetZOrder(zOrder or 1) end
        end)
        if not Slot then
            pcall(function() Border:RemoveFromParent() end)
            pcall(function() Border:ConditionalBeginDestroy() end)
            return nil
        end
        return {Widget = Border, Slot = Slot}
    end

    function M.DrawLine(ld, x1, y1, x2, y2, thickness)
        if not ld or not M.IsUIWidgetValid(ld.Widget) or not M.IsUIWidgetValid(ld.Slot) then return false end
        local dx, dy = x2 - x1, y2 - y1
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 0.5 then
            ld._x1 = nil
            if ld._visible ~= false then
                local hidden = pcall(function()
                    return M.CallUISetter(ld.Widget, 'SetWidgetVisibility',
                        UEnums.ESlateVisibility.Collapsed)
                end)
                if hidden then ld._visible = false else ld._visible = nil end
            end
            return false
        end
        local eps = 0.25
        if ld._visible == true and ld._x1 and
           math.abs(ld._x1 - x1) < eps and math.abs(ld._y1 - y1) < eps and
           math.abs(ld._x2 - x2) < eps and math.abs(ld._y2 - y2) < eps and
           math.abs((ld._thickness or 0) - thickness) < 0.01 then
            return true
        end
        local ang = (math.atan2 and math.atan2(dy, dx) or math.atan(dy, dx)) * (180.0 / math.pi)
        ld._drawPos  = ld._drawPos  or (FVector2D and FVector2D(0,0) or {X=0,Y=0})
        ld._drawSize = ld._drawSize or (FVector2D and FVector2D(0,0) or {X=0,Y=0})
        ld._drawPos.X, ld._drawPos.Y   = x1, y1 - thickness / 2
        ld._drawSize.X, ld._drawSize.Y = len, thickness
        local applied = pcall(function()
            if ld.Slot:SetPosition(ld._drawPos) == false then return false end
            if ld.Slot:SetSize(ld._drawSize) == false then return false end
            if ld.Widget:SetRenderAngle(ang) == false then return false end
            if ld._visible ~= true then
                if ld.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) == false then return false end
            end
            return true
        end)
        if not applied then ld._x1 = nil; return false end
        ld._x1, ld._y1, ld._x2, ld._y2 = x1, y1, x2, y2
        ld._thickness = thickness
        ld._visible = true
        return true
    end

    function M.ApplyLineTheme(ld, theme)
        if not ld or not M.IsUIWidgetValid(ld.Widget) or not theme then return false end
        if ld._themeKey == theme.Key then return true end
        local ok = pcall(function()
            return M.CallUISetter(ld.Widget, 'SetBrushColor', theme.Stroke)
        end)
        if ok then ld._themeKey = theme.Key; return true end
        ld._themeKey = nil
        return false
    end

    local function HideWidget(ld)
        if not ld or not M.IsUIWidgetValid(ld.Widget) then return false end
        if ld._visible == false then return true end
        local ok = pcall(function()
            return M.CallUISetter(ld.Widget, 'SetWidgetVisibility', UEnums.ESlateVisibility.Collapsed)
        end)
        if ok then ld._visible = false; return true end
        ld._visible = nil
        return false
    end
    M.HideWidget = HideWidget

    local function DestroyWidget(ld)
        if not ld then return end
        local widget = ld.Widget
        ld.Widget, ld.Slot = nil, nil
        if M.IsUIWidgetValid(widget) then
            pcall(function() widget:RemoveFromParent() end)
            pcall(function() widget:ConditionalBeginDestroy() end)
        end
    end
    M.DestroyWidget = DestroyWidget

    function M.UpdateBox(KeyStr, headCanvas, feetCanvas, bOnScreen, bIsAI)
        if not _G.HEXA_ESPBoxEnabled then
            if _G.HEXA_ESPBoxEnabled == false then M.RemoveBox(KeyStr) return end
        end
        local box = M.BoxWidgets[KeyStr]
        local boxH = bOnScreen and headCanvas and feetCanvas
            and (feetCanvas.Y - headCanvas.Y) or nil
        if not boxH or boxH < 10 then
            if box then
                box._lastL = nil
                HideWidget(box.frontTop);  HideWidget(box.frontBot)
                HideWidget(box.frontLeft); HideWidget(box.frontRight)
                HideWidget(box.backTop);   HideWidget(box.backBot)
                HideWidget(box.backLeft);  HideWidget(box.backRight)
                HideWidget(box.connTL);    HideWidget(box.connTR)
                HideWidget(box.connBL);    HideWidget(box.connBR)
            end
            return
        end
        local boxW = boxH * (M.BoxWidthFactor or 0.40)
        local cx = (headCanvas.X + feetCanvas.X) * 0.5
        local L, R = cx - boxW * 0.5, cx + boxW * 0.5
        local T, B = headCanvas.Y, feetCanvas.Y
        local depth = math.max(4.0, math.min(12.0, boxW * 0.16))
        local backDX, backDY = depth * 0.65, -depth
        local bL, bR, bT, bB = L + backDX, R + backDX, T + backDY, B + backDY
        local thick = M.BoxThickness or 1.5
        local theme = M.GetEnemyTheme(bIsAI)
        if not box then
            box = {_buildIndex = 1}
            M.BoxWidgets[KeyStr] = box
        end
        if box._buildIndex then
            local parts = {"frontTop","frontBot","frontLeft","frontRight",
                           "backTop","backBot","backLeft","backRight",
                           "connTL","connTR","connBL","connBR"}
            while box._buildIndex <= #parts do
                local index = box._buildIndex
                local part = M.CreateLineWidget(theme.Stroke, 1)
                if not part then
                    for i = 1, index - 1 do HideWidget(box[parts[i]]) end
                    return
                end
                box[parts[index]] = part
                box._buildIndex = index + 1
                HideWidget(part)
            end
            box._buildIndex = nil
        end
        local sameGeometry = box._lastL and
            math.abs(box._lastL - L) < 0.25 and math.abs(box._lastR - R) < 0.25 and
            math.abs(box._lastT - T) < 0.25 and math.abs(box._lastB - B) < 0.25 and
            math.abs(box._lastBL - bL) < 0.25 and math.abs(box._lastBT - bT) < 0.25 and
            box._lastThemeKey == theme.Key
        if sameGeometry then return end
        local complete = true
        local function ApplyTheme(ld, value)
            if not M.ApplyLineTheme(ld, value) then complete = false end
        end
        local function Draw(ld, ...)
            if not M.DrawLine(ld, ...) then complete = false end
        end
        ApplyTheme(box.frontTop, theme);  ApplyTheme(box.frontBot, theme)
        ApplyTheme(box.frontLeft, theme); ApplyTheme(box.frontRight, theme)
        ApplyTheme(box.backTop, theme);   ApplyTheme(box.backBot, theme)
        ApplyTheme(box.backLeft, theme);  ApplyTheme(box.backRight, theme)
        ApplyTheme(box.connTL, theme);    ApplyTheme(box.connTR, theme)
        ApplyTheme(box.connBL, theme);    ApplyTheme(box.connBR, theme)
        Draw(box.frontTop,   L, T, R, T, thick)
        Draw(box.frontBot,   L, B, R, B, thick)
        Draw(box.frontLeft,  L, T, L, B, thick)
        Draw(box.frontRight, R, T, R, B, thick)
        Draw(box.backTop,    bL, bT, bR, bT, thick)
        Draw(box.backBot,    bL, bB, bR, bB, thick)
        Draw(box.backLeft,   bL, bT, bL, bB, thick)
        Draw(box.backRight,  bR, bT, bR, bB, thick)
        Draw(box.connTL,     L,  T, bL, bT, thick)
        Draw(box.connTR,     R,  T, bR, bT, thick)
        Draw(box.connBL,     L,  B, bL, bB, thick)
        Draw(box.connBR,     R,  B, bR, bB, thick)
        if complete then
            box._lastL, box._lastR = L, R
            box._lastT, box._lastB = T, B
            box._lastBL, box._lastBT = bL, bT
            box._lastThemeKey = theme.Key
        else
            box._lastL = nil
        end
    end

    function M.RemoveBox(KeyStr)
        local box = M.BoxWidgets[KeyStr]
        if box then
            for _, ld in pairs(box) do
                if type(ld) == "table" and ld.Widget then DestroyWidget(ld) end
            end
        end
        M.BoxWidgets[KeyStr] = nil
    end

    function M.ClearAllBoxes()
        for _, box in pairs(M.BoxWidgets) do
            if box then
                for _, ld in pairs(box) do
                    if type(ld) == "table" and ld.Widget then DestroyWidget(ld) end
                end
            end
        end
        M.BoxWidgets = {}
    end

    local function Tick()
        if not M._Active then return end
        if not CheckExpiration() then return end
        if not M.InitESPCanvas() then return end
        local pc = M.GetMyPlayerController()
        if not IsValid(pc) then return end
        M.UpdateCanvasTransform(pc)

        local localPlayer = nil
        pcall(function()
            if GameplayData and GameplayData.GetPlayerCharacter then
                localPlayer = GameplayData.GetPlayerCharacter()
            end
        end)
        if not IsValid(localPlayer) then return end

        local myLoc = nil
        pcall(function()
            if localPlayer.K2_GetActorLocation then myLoc = localPlayer:K2_GetActorLocation() end
        end)

        local viewW = nil
        pcall(function()
            local s = FVector2D and FVector2D(0,0) or {X=0,Y=0}
            pc:GetViewportSize(s)
            if s and s.X and s.X > 200 then viewW = s.X end
        end)
        if not viewW then
            pcall(function()
                if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportSize then
                    local s = WidgetLayoutLibrary.GetViewportSize(pc)
                    if s and s.X and s.X > 200 then viewW = s.X end
                end
            end)
        end
        if not viewW then viewW = 1920 end

        local enemies = {}
        pcall(function()
            if GameplayData and GameplayData.GetAllPlayerCharacters then
                enemies = GameplayData.GetAllPlayerCharacters() or {}
            end
        end)
        local seen = {}
        local myTeam = localPlayer.TeamID
        for _, enemy in pairs(enemies) do
            if IsValid(enemy) and enemy ~= localPlayer
                and (myTeam == nil or enemy.TeamID ~= myTeam) then
                local alive = true
                pcall(function()
                    if type(enemy.IsDead) == "function" and enemy:IsDead() then alive = false
                    elseif enemy.bIsDead then alive = false end
                    if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then alive = false end
                end)
                if alive then
                    local key = tostring(enemy.PlayerKey or enemy)
                    seen[key] = true
                    local headLoc, feetLoc = M.GetCharacterBoxLocs(enemy)
                    local bHeadOK, headCanvas = false, nil
                    local bFeetOK, feetCanvas = false, nil
                    if headLoc then
                        local ok, cv = M.ProjectToCanvas(pc, headLoc); bHeadOK, headCanvas = ok, cv
                    end
                    if feetLoc then
                        local ok, cv = M.ProjectToCanvas(pc, feetLoc); bFeetOK, feetCanvas = ok, cv
                    end
                    local bOnScreen = bHeadOK and bFeetOK
                    local bIsAI = M.IsAI(enemy, key)
                    M.UpdateBox(key, headCanvas, feetCanvas, bOnScreen, bIsAI)
                end
            end
        end

        local stale = {}
        for k in pairs(M.BoxWidgets) do
            if not seen[k] then stale[#stale + 1] = k end
        end
        for _, k in ipairs(stale) do M.RemoveBox(k) end
    end

    local function EnsureWorldCache()
        local world = nil
        pcall(function() world = slua and slua.getWorld and slua.getWorld() end)
        if world ~= M._LastWorld then
            M._LastWorld = world
            M.ClearAllBoxes()
            M._CapsuleCache = setmetatable({}, {__mode = "k"})
            M._AITypeCache = {}
            M._AITypeRetryAt = {}
            M._CachedPC = nil
            M.ESPCanvas = nil
        end
    end

    function M.Start()
        if M._Active then return true end
        local owner = nil
        pcall(function()
            if GameplayData and GameplayData.GetPlayerController then
                owner = GameplayData.GetPlayerController()
            end
        end)
        if not IsValid(owner) then
            pcall(function()
                if slua_GameFrontendHUD then
                    owner = slua_GameFrontendHUD:GetPlayerController()
                end
            end)
        end
        if not IsValid(owner) or type(owner.AddGameTimer) ~= "function" then
            return false
        end
        EnsureWorldCache()
        M._Active = true
        local ok, timer = pcall(function()
            return owner:AddGameTimer(M._TickInterval, true, function()
                EnsureWorldCache()
                Tick()
            end)
        end)
        if not ok or not timer then M._Active = false; return false end
        M._Timer, M._TimerOwner = timer, owner
        print("[HEXA-ESP-Box] Started (WHITE) at 0.02s")
        return true
    end

    function M.Stop()
        M._Active = false
        if M._Timer and M._TimerOwner
            and type(M._TimerOwner.RemoveGameTimer) == "function" then
            pcall(function() M._TimerOwner:RemoveGameTimer(M._Timer) end)
        end
        M._Timer, M._TimerOwner = nil, nil
        M.ClearAllBoxes()
    end

    function M.IsActive() return M._Active end
    _G.ESPBoxRenderer = M
    return M
end)()
-- ============================================================================
-- 10. MASTER BYPASS FEATURES (Lua boolean exports)
-- ============================================================================
local MasterBypassFeatures = (function()
    local Bypass={}
    Bypass.__index=Bypass
    local INTERVAL=1
    local BOOLEAN_KEYS={'CheckMD5','CheckFileMD5','CheckFileIntegrity','VerifyFileIntegrity',
        'VerifyFile','VerifyAll','VerifyFileSignature','VerifySignature','slua_verify','check_slua_integrity'}
    local SUBSYSTEMS={'MD5CheckSubsystem','FileCheckSubsystem','AssetCheckSubsystem',
        'IntegrityCheckSubsystem','SignatureVerifySubsystem','PakCheckSubsystem','PakVerifySubsystem'}
    local GROUPS={
        {kind='loaded',name='common.file_hash_checker',fallback='FileHashChecker',keys={'CheckFileMD5','VerifyAll'}},
        {kind='imported',name='CreativeModeBlueprintLibrary',keys={'VerifyFileIntegrity'}},
        {kind='imported',name='STExtraBlueprintFunctionLibrary',fallback='STExtra',keys={'CheckMD5','VerifyFile'}},
        {kind='loaded',name='TssSdk',fallback='TssSdk',keys={'VerifyFileSignature','CheckIntegrity','CheckKernel','VerifyBoot'}},
        {kind='slua',name='loader',keys={'verifyBytecode','checkIntegrity'}},
        {kind='slua',name='serialize',keys={'check','verify'}},
    }
    for i=1,#SUBSYSTEMS do GROUPS[#GROUPS+1]={kind='subsystem',name=SUBSYSTEMS[i],keys=BOOLEAN_KEYS} end
    local function finite(value) return type(value)=='number' and value==value and value>-math.huge and value<math.huge end
    local function field(owner,key) return owner[key] end
    local function assign(owner,key,value) owner[key]=value end
    local function read(owner,key)
        if type(owner)~='table' then return nil end
        local ok,value=pcall(field,owner,key)
        if ok then return value end
    end
    local function exposed(value) if type(value)=='table' then return value end end
    function Bypass.new(env)
        local slots={}
        for group=1,#GROUPS do
            local keys=GROUPS[group].keys
            for i=1,#keys do slots[#slots+1]={group=group,key=keys[i]} end
        end
        return setmetatable({env=env or _G,slots=slots,settings={bypass=true},requested=true,
            enabled=false,active=false,disposed=false,nextCheck=0,lastTime=nil,
            bypassAvailable=nil,lastStatus='inactive',matchedSlots=0,
            reconcileCount=0,updating=false},Bypass)
    end
    function Bypass:_wanted() return not self.disposed end
    function Bypass:_owners()
        local result={}
        local loaded=read(read(self.env,'package'),'loaded')
        for i=1,#GROUPS do
            local group=GROUPS[i]; local owner
            if group.kind=='loaded' then owner=exposed(read(loaded,group.name)) or exposed(read(self.env,group.fallback))
            elseif group.kind=='slua' then owner=exposed(read(read(self.env,'slua'),group.name))
            elseif group.kind=='subsystem' then owner=exposed(read(self.env,group.name)) or exposed(read(loaded,group.name))
            else
                owner=exposed(read(self.env,group.name))
                if not owner then
                    local importer=read(self.env,'import')
                    if type(importer)=='function' then local ok,value=pcall(importer,group.name); if ok then owner=exposed(value) end end
                end
                if not owner and group.fallback then owner=exposed(read(self.env,group.fallback)) end
            end
            result[i]=owner
        end
        return result
    end
    function Bypass:_recordCount()
        local count=0
        for i=1,#self.slots do if self.slots[i].record then count=count+1 end end
        return count
    end
    function Bypass:_findRecord(owner,key)
        for i=1,#self.slots do
            local record=self.slots[i].record
            if record and record.owner==owner and record.key==key then return record end
        end
    end
    function Bypass:_blocked(owner,key)
        for i=1,#self.slots do
            local slot=self.slots[i]
            if slot.blockedOwner==owner and slot.key==key then return true end
        end
        return false
    end
    function Bypass:_stillBound(owners,owner,key)
        for i=1,#self.slots do
            local slot=self.slots[i]
            if slot.key==key and owners[slot.group]==owner then return true end
        end
        return false
    end
    function Bypass:_restoreSlot(slot)
        local record=slot.record
        if not record then return true end
        record.active=false
        local ok,current=pcall(field,record.owner,record.key)
        if not ok then return false end
        if current==record.wrapper then
            pcall(assign,record.owner,record.key,record.original)
            ok,current=pcall(field,record.owner,record.key)
            if not ok or current==record.wrapper then return false end
        end
        if current~=record.original then slot.blockedOwner,slot.blockReason=record.owner,'external_replacement' end
        slot.record=nil
        return true
    end
    function Bypass:_restoreAll()
        self.enabled,self.active=false,false
        for i=1,#self.slots do local record=self.slots[i].record; if record then record.active=false end end
        local restored=true
        for i=#self.slots,1,-1 do if not self:_restoreSlot(self.slots[i])then restored=false end end
        return restored
    end
    function Bypass:_stop(reason)
        local restored=self:_restoreAll()
        self.bypassAvailable=false
        self.lastStatus=restored and reason or 'restore_pending'
        return false
    end
    function Bypass:_reconcile()
        self.reconcileCount=self.reconcileCount+1
        self.enabled,self.active=false,false
        local owners=self:_owners()
        self.matchedSlots=0
        for i=1,#self.slots do
            local slot=self.slots[i]; local record=slot.record
            if record then
                local ok,current=pcall(field,record.owner,record.key)
                if not ok then return self:_stop('export_read_failed') end
                if current~=record.wrapper then
                    record.active=false; slot.record=nil
                    slot.blockedOwner,slot.blockReason=record.owner,'external_replacement'
                elseif owners[slot.group]~=record.owner then
                    if not self:_restoreSlot(slot)then return self:_stop('restore_pending') end
                end
            end
        end
        if not self:_wanted()then return self:_stop('inactive') end
        for i=1,#self.slots do
            local slot=self.slots[i]; local owner=owners[slot.group]
            if slot.blockedOwner and not self:_stillBound(owners,slot.blockedOwner,slot.key)then slot.blockedOwner,slot.blockReason=nil,nil end
            if owner and not self:_blocked(owner,slot.key)then
                local current=read(owner,slot.key)
                if type(current)=='function'then
                    self.matchedSlots=self.matchedSlots+1
                    if not self:_findRecord(owner,slot.key)then
                        local record={owner=owner,key=slot.key,original=current,active=false}
                        record.wrapper=function(...) if self.enabled and record.active and self:_wanted()then return true end; return record.original(...) end
                        slot.record=record
                        local ok=pcall(assign,owner,slot.key,record.wrapper)
                        local readOK,value=pcall(field,owner,slot.key)
                        if not ok or not readOK or value~=record.wrapper then
                            slot.blockedOwner,slot.blockReason=owner,'install_failed'
                            return self:_stop('install_failed')
                        end
                        if not self:_wanted()then return self:_stop('inactive') end
                    end
                end
            end
        end
        for i=1,#self.slots do
            local slot=self.slots[i]; local record=slot.record
            if record then
                local ok,current=pcall(field,record.owner,record.key)
                if not ok then return self:_stop('export_read_failed') end
                if current~=record.wrapper then
                    record.active=false; slot.record=nil
                    slot.blockedOwner,slot.blockReason=record.owner,'external_replacement'
                    return self:_stop('external_replacement')
                end
            end
        end
        if not self:_wanted()then return self:_stop('inactive') end
        local count=self:_recordCount()
        if count>0 then
            local currentOwners=self:_owners()
            for i=1,#self.slots do
                local slot=self.slots[i]; local record=slot.record
                if record and currentOwners[slot.group]~=record.owner then return self:_stop('binding_changed') end
            end
            if not self:_wanted()then return self:_stop('inactive') end
        end
        self.enabled=count>0
        self.active=self.enabled
        self.bypassAvailable=self.active
        for i=1,#self.slots do local record=self.slots[i].record; if record then record.active=self.enabled end end
        self.lastStatus=count==0 and 'no_lua_boolean_exports'
            or (self.matchedSlots<#self.slots and 'partial_lua_boolean_exports' or 'lua_boolean_exports_installed')
        return self.active
    end
    function Bypass:update(settings,now)
        if self.disposed or self.updating then return false end
        local previous=self.requested
        self.settings=type(settings)=='table'and settings or self.settings or {bypass=true}
        self.requested=self:_wanted()
        if not finite(now)then
            if self.enabled or not previous then return self:_stop('clock_unavailable') end
            self.lastStatus=self:_recordCount()>0 and 'restore_pending' or 'clock_unavailable'
            return false
        end
        if self.lastTime and now<self.lastTime then self.lastTime,self.nextCheck=now,now+INTERVAL; return self.active end
        self.lastTime=now
        if not previous then self.nextCheck=now end
        if now<self.nextCheck then return self.active end
        self.nextCheck=now+INTERVAL
        self.updating=true
        local ok,value=pcall(self._reconcile,self)
        self.updating=false
        if not ok then return self:_stop('reconcile_failed') end
        return value
    end
    function Bypass:dispose()
        self.disposed,self.requested,self.enabled=true,false,false
        self.settings=nil
        local restored=self:_restoreAll()
        self.bypassAvailable=false
        self.lastStatus=restored and 'disposed' or 'restore_pending'
        return restored
    end
    function Bypass:getStatus()
        local count=self:_recordCount()
        local conflicts=0
        for i=1,#self.slots do if self.slots[i].blockedOwner then conflicts=conflicts+1 end end
        local active=self.enabled and self:_wanted()and count>0
        return {enabled=self.requested,active=active,bypassAvailable=self.bypassAvailable,
            lastStatus=self.lastStatus,ownedHooks=count,installedCount=count,
            appliedHooks=active and count or 0,pendingCleanup=not active and count or 0,
            restorePending=not active and count>0,configuredSlots=#self.slots,
            matchedSlots=self.matchedSlots,blockedSlots=conflicts,reconcileCount=self.reconcileCount,
            coverage='lua_boolean_exports_only',sourceMigration='partial',
            nativeInterceptionVerified=false,serverVerification=false}
    end
    return Bypass
end)()

-- ============================================================================
-- 11. MASTER ANOGS BYPASS (libanogs.so native patches + hooks)
-- ============================================================================
local MasterAnogsBypass = (function()
    local SH=_G.ScriptHelperClient
    if not SH then return {ready=false,reason='ScriptHelperClient unavailable'} end
    local KNOWN_PKGS={
        ["com.tencent.ig"]="/data/app/~~2U5OPyLPSNrCp3Jhv6O4Xg==/com.tencent.ig-rxZaOzwfUVAPdioMsk4emQ==/lib/arm64/",
        ["com.pubg.krmobile"]="/data/app/~~uBLiktAOPJCRfbQA01C-3Q==/com.pubg.krmobile-nhvnm6_ClIAV0J93P86daw==/lib/arm64/",
        ["com.pubg.imobile"]="/data/app/~~p9qsLKUJYSx0V20AUx9EWg==/com.pubg.imobile-oEDhX_GaHiB7HYo8hWh0Hg==/lib/arm64/",
    }
    local function detectPackage()
        if SH.GetNativePackageTag then
            local ok,p=pcall(SH.GetNativePackageTag)
            if ok and type(p)=="string" and KNOWN_PKGS[p] then return p end
        end
        for p in pairs(KNOWN_PKGS) do return p end
        return "com.tencent.ig"
    end
    local PKG=detectPackage()
    local LIBDIR=KNOWN_PKGS[PKG] or ""
    local LIBFILE=LIBDIR.."libanogs.so"
    local APPLIED_PATCH={}
    local APPLIED_HOOK={}
    local BASE_CACHE={}
    local function kdup(lib,off) return string.format("%s@0x%X",lib,off) end
    local function getBase(lib)
        if BASE_CACHE[lib] then return BASE_CACHE[lib] end
        local b=0
        local ok,r=pcall(SH.GetPUBGModuleBaseAddr,lib)
        if ok and type(r)=="number" then b=r
        elseif ok and type(r)=="table" then b=r.base or r.addr or r[1] or 0 end
        if b==0 then
            local alt=lib:gsub("%.so$","")
            local ok2,r2=pcall(SH.GetPUBGModuleBaseAddr,alt)
            if ok2 and type(r2)=="number" then b=r2 end
        end
        BASE_CACHE[lib]=b; return b
    end
    local function hex2bin(h) return (h:gsub("%x%x",function(b)return string.char(tonumber(b,16))end)) end
    local function applyPatch(lib,off,hexbytes)
        local base=getBase(lib); local addr=base>0 and (base+off) or nil
        if SH.ProcessSoPatch and addr then
            local ok=pcall(SH.ProcessSoPatch,addr,hexbytes); if ok then return true,"P1" end
        end
        if SH.ProcessSoPatch and addr then
            local ok=pcall(SH.ProcessSoPatch,addr,hex2bin(hexbytes)); if ok then return true,"P2" end
        end
        if SH.ProcessSoPatch then
            local ok=pcall(SH.ProcessSoPatch,{{module=lib,offset=off,addr=addr,bytes=hexbytes,data=hex2bin(hexbytes)}})
            if ok then return true,"P3" end
        end
        if SH.WriteFileAtPath and SH.SetUpdatedSoPatchFile and SH.ProcessSoPatch then
            local data=string.format("%s|0x%X|%s",lib,off,hexbytes)
            local paths={"/storage/emulated/0/Android/data/"..PKG.."/files/anogs.bin",
                "/sdcard/Android/data/"..PKG.."/files/anogs.bin","/data/local/tmp/anogs.bin"}
            for _,path in ipairs(paths) do
                local okW=pcall(SH.WriteFileAtPath,path,data)
                if okW then
                    pcall(SH.SetUpdatedSoPatchFile,path)
                    local okP=pcall(SH.ProcessSoPatch)
                    if okP then return true,"P4" end
                end
            end
        end
        return false,"no-path"
    end
    local function installHook(lib,off,handler)
        local base=getBase(lib)
        if _G.__FRAMEWORK_HOOK_LIB_NO_ORIG then
            local ok=pcall(_G.__FRAMEWORK_HOOK_LIB_NO_ORIG,lib,off,handler); if ok then return true,"H1" end
        end
        if SH.InstallHook then local ok=pcall(SH.InstallHook,lib,off,handler); if ok then return true,"H2a" end end
        if SH.HookFunction then local ok=pcall(SH.HookFunction,lib,off,handler); if ok then return true,"H2b" end end
        if SH.AddHook then local ok=pcall(SH.AddHook,lib,off,handler); if ok then return true,"H2c" end end
        if SH.AllocVirMem and SH.ProcessSoPatch and base>0 then
            local slot=pcall(SH.AllocVirMem,16)
            if slot and type(slot)=="number" and slot>0 then return false,"H3-no-native-bridge" end
        end
        return false,"no-hook-api"
    end
    local function PATCH_LIB(lib,offStr,bytes)
        local off=tonumber(offStr); if not off then return end
        local k=kdup(lib,off); if APPLIED_PATCH[k] then return end
        local ok,how=applyPatch(lib,off,bytes)
        if ok then APPLIED_PATCH[k]=true
        else print(string.format("[ANOGS] patch %s @0x%X FAILED (%s)",lib,off,how)) end
    end
    local function HOOK_LIB_NO_ORIG(lib,offStr,handler)
        local off=tonumber(offStr); if not off then return end
        local k=kdup(lib,off); if APPLIED_HOOK[k] then return end
        local ok,how=installHook(lib,off,handler)
        if ok then APPLIED_HOOK[k]=true
        else print(string.format("[ANOGS] hook %s @0x%X FAILED (%s)",lib,off,how)) end
    end
    local function Master(...) return 0 end
    _G.Master=Master
    local function applyAll()
        PATCH_LIB("libanogs.so","0x2328F0","C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x213360","C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x2ECE70","C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D5998","00 00 80 D2 C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D59A4","00 00 80 D2 C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D4DB4","00 00 80 D2 C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D4DD0","00 00 80 D2 C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D571C","00 00 80 D2 C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D5748","00 00 80 D2 C0 03 5F D6")
        HOOK_LIB_NO_ORIG("libanogs.so","0x371418",Master)
        HOOK_LIB_NO_ORIG("libanogs.so","0x431800",Master)
        HOOK_LIB_NO_ORIG("libanogs.so","0x39F56C",Master)
        HOOK_LIB_NO_ORIG("libanogs.so","0x3A564C",Master)
    end
    applyAll()
    return {ready=true,pkg=PKG,libfile=LIBFILE,
        applied_patch=APPLIED_PATCH,applied_hook=APPLIED_HOOK,
        PATCH_LIB=PATCH_LIB,HOOK_LIB_NO_ORIG=HOOK_LIB_NO_ORIG}
end)()
_G.__MasterAnogsBypass = MasterAnogsBypass

-- ============================================================================
-- 12. ULTIMATE DETECTION BYPASS
-- ============================================================================
local function installUltimateDetectionBypass()
    if _G.__MASTER_ULTIMATE_BYPASS then return end
    local nop=function() end
    local retTrue=function() return true end
    local retFalse=function() return false end
    local function active() return _G._WHA_BYPASS_ACTIVE and not _G._MOD_EXPIRED end
    pcall(function()
        local P=import("PrimitiveSceneProxy")
        if P and P.GetViewRelevance then
            local orig=P.GetViewRelevance
            P.GetViewRelevance=function(s,V)
                local VR=orig(s,V)
                if active() and VR then
                    VR.bRenderCustomDepth=false
                    VR.bUsesSceneDepth=false
                end
                return VR
            end
        end
    end)
    pcall(function()
        local M=import("MeshComponent")
        if M then
            M.__grd=M.GetRenderCustomDepth
            M.GetRenderCustomDepth=function(s) if not active() then return M.__grd(s) end return false end
            M.__ircd=M.IsRenderedOnCustomDepth
            M.IsRenderedOnCustomDepth=function(s) if not active() then return M.__ircd(s) end return false end
            M.__gcdsv=M.GetCustomDepthStencilValue
            M.GetCustomDepthStencilValue=function(s) if not active() then return M.__gcdsv(s) end return 0 end
            M.__sr=M.ShouldRender
            M.ShouldRender=function(s) if not active() then return M.__sr(s) end return true end
        end
        local P=import("PrimitiveComponent")
        if P then
            for _,fn in ipairs({"IsRenderedOnCustomDepth","GetRenderCustomDepth",
                "GetCustomDepthStencilValue","GetCustomDepthStencilWriteMask",
                "GetVisibleFlag"}) do
                local orig=P[fn]
                P["__o_"..fn]=orig
                local vf=(fn=="GetVisibleFlag")
                local sf=(fn=="GetCustomDepthStencilValue")
                P[fn]=function(s,...)
                    if not active() then return orig(s,...) end
                    if vf then return true end
                    if sf then return 0 end
                    return false
                end
            end
        end
    end)
    pcall(function()
        local M=import("Material")
        local MI=import("MaterialInstance")
        local MD=import("MaterialInstanceDynamic")
        if M then
            M.__ddt=M.GetDisableDepthTest
            M.GetDisableDepthTest=function(s) if not active() then return M.__ddt(s) end return false end
            M.__bm=M.GetBlendMode
            M.GetBlendMode=function(s) if not active() then return M.__bm(s) end return 0 end
            M.__mh=M.GetMaterialHash
            M.GetMaterialHash=function(s) if not active() then return M.__mh(s) end return "FAKE_HASH" end
        end
        if MI then
            MI.__ddt=MI.GetDisableDepthTest
            MI.GetDisableDepthTest=function(s) if not active() then return MI.__ddt(s) end return false end
            MI.__bm=MI.GetBlendMode
            MI.GetBlendMode=function(s) if not active() then return MI.__bm(s) end return 0 end
        end
        if MD then
            local oV=MD.K2_GetVectorParameterValue
            MD.K2_GetVectorParameterValue=function(s,n)
                if not active() then return oV(s,n) end
                local k=tostring(n or "")
                if k:find("Color") or k:find("Emissive") or k:find("Tint") then
                    return {R=255,G=255,B=255,A=255}
                end
                return oV(s,n)
            end
        end
    end)
    pcall(function()
        local SM=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SM then
            local kc=SM:Get("ClientKernelCheckSubsystem")
            if kc and not kc.__master then
                kc.__okc=kc.IsKernelClean
                kc.IsKernelClean=function(s) if not active() then return kc.__okc(s) end return true,{code=0} end
                kc.__okv=kc.GetKernelVersion
                kc.GetKernelVersion=function(s) if not active() then return kc.__okv(s) end return "5.4.0-generic" end
                kc.__master=true
            end
            local mg=SM:Get("ClientMemoryGuardSubsystem")
            if mg and not mg.__master then
                mg.__omc=mg.IsMemoryClean
                mg.IsMemoryClean=function(s) if not active() then return mg.__omc(s) end return true,{code=0} end
                mg.__osr=mg.ScanResult
                mg.ScanResult=function(s) if not active() then return mg.__osr(s) end return "clean" end
                mg.__master=true
            end
        end
    end)
    pcall(function()
        local W=import("ShootWeaponEntity") or import("ShootWeaponEntityComp")
        if W then
            local mt=getmetatable(W) or {}
            local oi=mt.__index
            mt.__index=function(s,k)
                if active() and type(k)=='string' then
                    if k=="RecoilKickADS" or k=="GameDeviationFactor" or k=="GameDeviationAccuracy" then
                        return 1.0
                    end
                end
                if oi then return oi(s,k) end
                return rawget(s,k)
            end
            setmetatable(W,mt)
        end
    end)
    pcall(function()
        local SM=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SM then
            local a=SM:Get("ClientAimTrackingSubsystem")
            if a then
                a.__ogad=a.GetAimData
                a.GetAimData=function(s)
                    if not active() then return a.__ogad(s) end
                    return {accuracy=math.random(40,60),headshotRate=math.random(10,25),
                        trackingTime=math.random(100,300),aimLockCount=0}
                end
                a.ReportAimData=nop
                a.SendAimStats=nop
                a.UploadAimInfo=nop
            end
        end
    end)
    pcall(function()
        if _G.TssSdk then
            _G.TssSdk.GetFileMD5=function() return "7b1c7b5608da3083097816106fc331f9" end
            _G.TssSdk.VerifyFileSignature=retTrue
            _G.TssSdk.CheckIntegrity=retTrue
            _G.TssSdk.ScanMemory=function() return true,{} end
            _G.TssSdk.IsEmulator=retFalse
        end
        if _G.IsDebuggerPresent then _G.IsDebuggerPresent=retFalse end
        local F=import("FFileHelper")
        if F and F.GetFileSize then
            local orig=F.GetFileSize
            F.GetFileSize=function(p)
                if active() and p and tostring(p):lower():match("%.pak") then return 2000000000 end
                return orig(p)
            end
        end
    end)
    pcall(function()
        if NetUtil and NetUtil.SendPacket and not NetUtil._masterBlocked then
            local orig=NetUtil.SendPacket
            NetUtil.SendPacket=function(pname,...)
                if active() and pname then
                    local l=tostring(pname):lower()
                    if l:match("report") or l:match("flow") or l:match("tlog")
                        or l:match("cheat") or l:match("security") or l:match("integrity")
                        or l:match("md5") or l:match("hash") or l:match("esp")
                        or l:match("aim") or l:match("recoil") or l:match("shoot")
                        or l:match("heartbeat") or l:match("crash") then
                        return nil
                    end
                end
                return orig(pname,...)
            end
            NetUtil._masterBlocked=true
        end
    end)
    _G.__MASTER_ULTIMATE_BYPASS=true
    print("[HEXA] Ultimate detection bypass installed")
end

installUltimateDetectionBypass()

-- ============================================================================
-- 13. BYPASS RUNTIME SYNC
-- ============================================================================
local BypassRuntime = {
    instance = nil,
    lastStatus = nil,
    nextCheck = 0,
    lastTime = nil,
    retireAt = nil,
}

local function BypassNow()
    local now = nil
    pcall(function()
        if GameplayStaticsESP and slua and slua.getWorld then
            local w = slua.getWorld()
            if w then now = GameplayStaticsESP.GetRealTimeSeconds(w) end
        end
    end)
    if type(now) == "number" and now == now and now >= 0 and now < math.huge then
        return now
    end
    return nil
end

local function BypassSync()
    if masterESPLicenseInstance then
        local active = false
        pcall(function() active = masterESPLicenseInstance:isActive() == true end)
        if not active then
            _G._WHA_BYPASS_ACTIVE = false
            if BypassRuntime.instance then
                pcall(function() BypassRuntime.instance:dispose() end)
                BypassRuntime.instance = nil
            end
            BypassRuntime.lastStatus = nil
            return
        end
    end
    _G._WHA_BYPASS_ACTIVE = true

    if not BypassRuntime.instance then
        local ok, inst = pcall(MasterBypassFeatures.new, _G)
        if ok and type(inst) == "table" then
            BypassRuntime.instance = inst
        else
            return
        end
    end

    local now = BypassNow()
    if not now then now = (os.clock and os.clock()) or 0 end
    if BypassRuntime.lastTime and now < BypassRuntime.lastTime then
        BypassRuntime.nextCheck = now
    end
    BypassRuntime.lastTime = now
    if BypassRuntime.nextCheck and now < BypassRuntime.nextCheck then
        return
    end
    BypassRuntime.nextCheck = now + 1.0

    local ok, status = pcall(function()
        return BypassRuntime.instance:update({bypass = true}, now)
    end)
    if not ok then
        pcall(function() BypassRuntime.instance:dispose() end)
        BypassRuntime.instance = nil
        return
    end
    BypassRuntime.lastStatus = BypassRuntime.instance:getStatus()
end

-- ============================================================================
-- 14. BR PLAYER START FEATURES
-- ============================================================================
local function BRPlayerStartAuthorizedFeatures()
    if not BRPlayerLicenseActive() then return false end
    HEXA_InitHackMenu()
    if not _G.__MasterShotESPFastTickStarted then
        _G.__MasterShotESPFastTickStarted = true
        HEXA_FastTick()
    end
    if not _G.__MasterShotESPTickStarted then
        _G.__MasterShotESPTickStarted = true
        HEXA_ShotESP.Running = true
        HEXA_ESPTick()
    end
    -- ★ START ESP BOX (WHITE) ★
    if not _G.__HEXA_ESPBoxStarted then
        _G.__HEXA_ESPBoxStarted = true
        pcall(function()
            if HEXA_ESPBoxRenderer and HEXA_ESPBoxRenderer.Start then
                HEXA_ESPBoxRenderer.Start()
            end
        end)
    end
    -- ★ START BYPASS SYNC ★
    pcall(BypassSync)
    return true
end

local function BRPlayerLoginMaintenanceTick()
    pcall(BRPlayerLicenseTick)
    pcall(BRPlayerStartAuthorizedFeatures)
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.50, BRPlayerLoginMaintenanceTick)
    end
end

BRPlayerLoginMaintenanceTick()

-- ============================================================================
-- 15. PUBLIC METHODS
-- ============================================================================
function BRPlayerCharacterBase:SubmitESPKey(key)
    return _G.MasterLicenseLogin(key)
end

function BRPlayerCharacterBase:LogoutESP()
    return _G.MasterLicenseLogout()
end

function BRPlayerCharacterBase:GetESPLoginStatus()
    return _G.MasterLicenseStatus()
end

function BRPlayerCharacterBase:GetESPBoxStatus()
    local state = {active = false, isWhite = true}
    pcall(function()
        if HEXA_ESPBoxRenderer and HEXA_ESPBoxRenderer.IsActive then
            state.active = HEXA_ESPBoxRenderer.IsActive() == true
        end
    end)
    return state
end

function BRPlayerCharacterBase:GetBypassStatus()
    return BypassRuntime.lastStatus or {active = false, lastStatus = "not_started"}
end

-- ============================================================================
-- 16. CLASS RETURN
-- ============================================================================
local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
  { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
  { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
  { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
  { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
  { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
  { CampFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.Camp.PlayerCharacterCampFeature" },
  { BuildSkateFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.PlayerCharacterBuildVehicleFeature" },
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
  { ParachuteFormation = "GameLua.Mod.BaseMod.Gameplay.Feature.ParachuteFormationFeature" },
  { SpiderSenseFootprintFeature = "GameLua.Mod.Library.GamePlay.Feature.SpiderSenseFootprintFeature" },
  { GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature" }
}, "BRPlayerCharacterBase")
