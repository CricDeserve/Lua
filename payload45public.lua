-- ============================================================
-- INDIAN ROHIT YT 4.6 (DYNAMIC BUILD v9.0)
-- ============================================================

local BRPlayerCharacterBase = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {}, LuaEventContainer = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }

local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local EMovementMode = import("EMovementMode")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")

-- [[TESLA_CONFIG_START]]
_G.LexusConfig = _G.LexusConfig or {
    AimTouchEnable = false,
    ColorBodyNew = true,
    Esp9_Count = false,
    Esp9_Distance = false,
    Esp9_HP = false,
    Esp9_Line = false,
    Esp9_Name = false,
    Esp9_Skeleton = false,
    Esp9_Team = false,
    Esp9_Weapon = false,
    EspAntenna = false,
    EspDistance = false,
    EspLoai5 = false,
    EspLoai6 = false,
    EspLoai7 = false,
    EspLoai8 = false,
    EspLoai9 = false,
    EspOutline = false,
    EspRadar = false,
    EspVip = false,
    EspVipPro = false,
    FakeHWID = true,
    IpadView = true,
    KillCountUI = false,
    NoRecoilEnabled = false,
    AimbotMode = 1,
    AimbotBone = 1,
    AimbotFOV = 80,
    AimbotSpeed = 100,
    AimTouchIgKnock = false,
    AimTouchIgBot = false,
    AimTouchVisCheck = false,
    RecoilReduction = 100,
    IpadViewFOV = 120,
    BypassTier = 20,
}
-- [[TESLA_CONFIG_END]]

_G.LexusState = _G.LexusState or { LoopToken = 0, CustomTextData = {}, EnemyMarks = {} }
_G.TeslaLoadedFeatures = {}
_G.TeslaLoadedFeatures = {
  "Fake HWID",
  "iPad View FOV",
  "Wallhack Chams"
}

-- LAG FIX & HELPERS
_G.AkoStability = _G.AkoStability or { MainInterval = 0.05, AimbotInterval = 0.033, SlowFrameThreshold = 0.025, SlowFrameBackoff = 0.066, SlowFrameCount = 0 }
local _cached_linear, _cached_skeletal, _cached_gpdata, _cached_ticker = nil, nil, nil, nil

local function getLC() if _cached_linear == nil then _cached_linear = import("LinearColor") end return _cached_linear end
local function getSkel() if _cached_skeletal == nil then _cached_skeletal = import("SkeletalMeshComponent") end return _cached_skeletal end
local function getGD()
  if _cached_gpdata == nil then
    local ok, m = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok then _cached_gpdata = m end
  end
  return _cached_gpdata
end
local function getTicker()
  if _cached_ticker == nil then
    local ok, t = pcall(require, "common.time_ticker")
    if ok then _cached_ticker = t end
  end
  return _cached_ticker
end

local _slua = rawget(_G, "slua")
function _G.Valid(obj)
  if not obj then return false end
  if _slua and _slua.isValid then
    local ok, v = pcall(_slua.isValid, obj)
    return ok and v
  end
  return true
end

function _G.Notify(msg)
  local s = "[TESLA 10X] " .. tostring(msg)
  pcall(function() print(s) end)
  pcall(function()
    local sh = import("ScriptHelperClient")
    if sh and sh.AddOnScreenDebugMessage then
      sh.AddOnScreenDebugMessage(s, -1, 4.0, {R=1, G=0.85, B=0, A=1}, {X=1.2, Y=1.2})
    end
  end)
end

-- SAVE / LOAD CONFIG
local ConfigFileName = "TESLA_10X_settings.txt"
local function GetConfigPaths(fileName)
  return {
    "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "ShadowTrackerExtra/Saved/Paks/" .. fileName, fileName
  }
end

function _G.SaveModSettings()
  pcall(function()
    local data = "return {\n"
    for k, v in pairs(_G.LexusConfig or {}) do
      data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
    end
    data = data .. "}\n"
    for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
      local file = io.open(path, "w")
      if file then file:write(data); file:close(); break end
    end
  end)
end

function _G.LoadModSettings()
  pcall(function()
    for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
      local file = io.open(path, "r")
      if file then
        local content = file:read("*a"); file:close()
        local func = load(content)
        if func then
          local savedData = func()
          if savedData and type(savedData) == "table" then
            for k, v in pairs(savedData) do _G.LexusConfig[k] = v end
          end
        end
        break
      end
    end
  end)
end
LoadModSettings()

function _G.GetSafeEnemyKey(enemy)
  if Valid(enemy) then
    if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
    if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
  end
  return tostring(enemy)
end

function _G.CheckIsAI(pawn, markData)
  if markData.AK_IS_BOT ~= nil then return markData.AK_IS_BOT, true end
  local isAI = false; local hasChecked = false
  pcall(function()
    if pawn.bIsAI == true or pawn.IsAI == true then isAI = true; hasChecked = true end
    if type(pawn.IsBot) == "function" and pawn:IsBot() then isAI = true; hasChecked = true end
    local ps = pawn.PlayerState or (type(pawn.GetPlayerState) == "function" and pawn:GetPlayerState())
    if Valid(ps) then
      hasChecked = true
      if ps.bIsABot == true or ps.bIsBot == true then isAI = true end
    end
  end)
  if hasChecked then markData.AK_IS_BOT = isAI end
  return isAI, hasChecked
end

function _G.GetAllSkeletalMeshes(enemy, markData)
  local curTime = os.clock()
  if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime < 0.5) then
    local valid = {}
    for _, m in ipairs(markData.CachedMeshes) do if Valid(m) then table.insert(valid, m) end end
    markData.CachedMeshes = valid; return valid
  end
  local meshes = {}
  if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
  pcall(function()
    local skel = getSkel()
    if skel and type(enemy.GetComponentsByClass) == "function" then
      local comps = enemy:GetComponentsByClass(skel)
      if comps then
        local n = type(comps.Num) == "function" and comps:Num() or #comps
        for i = 1, n do
          local c = type(comps.Get) == "function" and comps:Get(i-1) or comps[i]
          if Valid(c) and c ~= enemy.Mesh then table.insert(meshes, c) end
        end
      end
    end
  end)
  if markData then markData.CachedMeshes = meshes; markData.CachedMeshTime = curTime end
  return meshes
end


-- WALLHACK CHAMS
function _G.ApplyChams(enemy, md)
  if not _G.ConsoleNewWallReady then
    local w = slua.getWorld(); local k = import("KismetSystemLibrary")
    if k and w then
      k.ExecuteConsoleCommand(w, "r.EnableDrawDyeingColor 1")
      k.ExecuteConsoleCommand(w, "r.CustomDepth 3")
      _G.ConsoleNewWallReady = true
    end
  end
  local m = _G.GetAllSkeletalMeshes(enemy, md)
  local wep = enemy:GetCurrentWeapon()
  if Valid(wep) and Valid(wep.Mesh) then table.insert(m, wep.Mesh) end
  local isBot = md.AK_IS_BOT or false
  local h = (isBot and "B" or "P") .. "_" .. tostring(#m)
  if md.LastChams == h and md.ChamsOn then return end
  md.LastChams = h; md.ChamsOn = true
  local lc = getLC()
  local v = lc and lc(0,100,0,1) or {R=0,G=100,B=0,A=1}
  local o = lc and lc(100,0,0,1) or {R=100,G=0,B=0,A=1}
  if isBot then
    v = lc and lc(49,48,0,100) or {R=49,G=48,B=0,A=100}
    o = lc and lc(9,1,45,100) or {R=9,G=1,B=45,A=100}
  end
  for _, mesh in ipairs(m) do
    if Valid(mesh) and mesh.SetDrawDyeing then
      mesh:SetDrawDyeing(true)
      mesh:SetDrawDyeingMode(1)
      mesh:SetVisibleDyeingColor(v)
      mesh:SetOccludedDyeingColor(o)
      mesh:SetDyeingColorFadeDistance(99999)
      mesh:SetDyeingColorMinMaxDistance(0, 99999)
    end
  end
end

function _G.RemoveChams(enemy, md)
  if not md.ChamsOn then return end
  local m = _G.GetAllSkeletalMeshes(enemy, md)
  local wep = enemy:GetCurrentWeapon()
  if Valid(wep) and Valid(wep.Mesh) then table.insert(m, wep.Mesh) end
  for _, mesh in ipairs(m) do
    if Valid(mesh) and mesh.SetDrawDyeing then
      mesh:SetDrawDyeing(false)
    end
  end
  md.ChamsOn = false
  md.LastChams = nil
end



-- FAKE HWID
function _G.InitHWID()
  pcall(function()
    local l = import("KismetSystemLibrary")
    if l and not _G.HWID_Hooked then
      _G.OrigHWID = l.GetDeviceId
      l.GetDeviceId = function(...)
        if _G.LexusConfig.FakeHWID then
          if not _G.FakeHWID then
            local c = "0123456789ABCDEF"
            local s = ""
            for i = 1, 32 do s = s .. c:sub(math.random(1,16), math.random(1,16)) end
            _G.FakeHWID = s
          end
          return _G.FakeHWID
        end
        return _G.OrigHWID and _G.OrigHWID(...) or "UNKNOWN"
      end
      _G.HWID_Hooked = true
    end
  end)
end



-- IPAD VIEW
function _G.ApplyIpad(p)
  pcall(function()
    local c = p.ThirdPersonCameraComponent
    if not Valid(c) then return end
    if _G.LexusConfig.IpadView then
      local target = _G.LexusConfig.IpadViewFOV or 120
      if c.FieldOfView ~= target and not p.bIsWeaponAiming then c.FieldOfView = target end
    else
      if c.FieldOfView ~= 90 and not p.bIsWeaponAiming then c.FieldOfView = 90 end
    end
  end)
end



-- BYPASS TIER 20
pcall(function()
  local n, f, t = function() end, function() return false end, function() return true end
  local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
  if sm then
    for _, x in ipairs({"AFKReportorSubsystem","ShootVerifySubSystemClient","BehaviorScoreSubsystem","MemoryCheckSubsystem","SpeedCheckSubsystem","WallCheckSubsystem"}) do
      local s = sm:Get(x)
      if s then for k, v in pairs(s) do
        if type(v) == "function" and (k:find("Report") or k:find("Send")) then s[k] = n end
      end end
    end
  end
  local N = _G.NetUtil
  if N and N.SendPacket and not N._Byp then
    local o = N.SendPacket
    N.SendPacket = function(name, ...)
      if name:find("Report") or name:find("AntiCheat") then return nil end
      return o(name, ...)
    end
    N._Byp = true
  end
end)


-- ============================================================
-- MENU INJECTION
-- ============================================================
local _menuAttempts = 0
local _menuDone = false

local function TryInitMenu()
  if _menuDone then return end
  _menuAttempts = _menuAttempts + 1
  if _menuAttempts > 20 then return end

  local ok, err = pcall(function()
    local LocUtil = _G.LocUtil or (package.loaded["client.common.LocUtil"] and require("client.common.LocUtil"))
    if not LocUtil then error("LocUtil not ready") end
    local SPD = require("client.logic.NewSetting.SettingPageDefine")
    local SC = require("client.logic.NewSetting.SettingCatalog")
    local UIMgr = _G.UIManager
    if not UIMgr or not UIMgr.ShowUI then error("UIManager not ready") end
    local AM = require("client.slua.umg.NewSetting.Item.AliasMap")
    if not AM.Switcher or not AM.Slider then error("AliasMap missing") end
    local TitleUI = AM.TitleSwitcher or AM.Switcher

    local FakeTextMap = { [999000] = "◆ TESLA 10X 4.6 ◆" }
    if not LocUtil._Tesla10xHooked then
      for _, fn in ipairs({"GetLocalizeResStr", "GetText", "GetTextByID", "GetLocalText", "GetLocalizeStr"}) do
        if LocUtil[fn] then
          local orig = LocUtil[fn]
          LocUtil[fn] = function(id)
            if FakeTextMap[id] then return FakeTextMap[id] end
            if type(id) == "string" and not tonumber(id) then return id end
            return orig and orig(id) or ""
          end
        end
      end
      LocUtil._Tesla10xHooked = true
    end

    local Categories = {}

    local StackVisual = {
      { Key = "M_WH", UI = AM.Switcher, Text = "◆ Wallhack Chams", GetFunc = function() return _G.LexusConfig.ColorBodyNew end, SetFunc = function(c,v) _G.LexusConfig.ColorBodyNew = v return true end },
    }
    table.insert(Categories, { Key = "Cat_Visual", Text = "VISUAL", Stack = StackVisual })
    


    local StackIpad = {
      { Key = "M_Ipad", UI = AM.Switcher, Text = "◆ iPad View", GetFunc = function() return _G.LexusConfig.IpadView end, SetFunc = function(c,v) _G.LexusConfig.IpadView = v return true end },
      { Key = "M_Ipad_Fov", UI = AM.Slider, Text = "   FOV Value", MinValue = 90, MaxValue = 160, GetFunc = function() return _G.LexusConfig.IpadViewFOV or 120 end, SetFunc = function(c,v) _G.LexusConfig.IpadViewFOV = v return true end },
    }
    table.insert(Categories, { Key = "Cat_Ipad", Text = "IPAD VIEW", Stack = StackIpad })
    


    local StackMisc = {
      { Key = "M_HWID", UI = AM.Switcher, Text = "◆ Fake HWID", GetFunc = function() return _G.LexusConfig.FakeHWID end, SetFunc = function(c,v) _G.LexusConfig.FakeHWID = v return true end },
      { Key = "M_KC", UI = AM.Switcher, Text = "◆ Kill Counter UI", GetFunc = function() return _G.LexusConfig.KillCountUI end, SetFunc = function(c,v) _G.LexusConfig.KillCountUI = v return true end },
    }
    table.insert(Categories, { Key = "Cat_Misc", Text = "MISC", Stack = StackMisc })
    

    if #Categories == 0 then error("No categories built") end

    SPD.ModMenu = { Key = "ModMenu", Text = 999000, UIKey = "Setting_Page_Privacy", Category = Categories }
    if SC then
      for i = #SC, 1, -1 do
        if type(SC[i]) == "table" and SC[i].Key == "ModMenu" then table.remove(SC, i) end
      end
      table.insert(SC, 1, SPD.ModMenu)
    end

    if not UIMgr._IsModMenuHooked then
      local oldShowUI = UIMgr.ShowUI
      function UIMgr.ShowUI(cfg, ...)
        local args = {...}
        if cfg and cfg.keyName and string.find(string.lower(cfg.keyName), "setting_main")
           and not string.find(string.lower(cfg.keyName), "custom") then
          local cat = args[1]
          if type(cat) == "table" and cat[1] and type(cat[1]) == "table" and cat[1].Key then
            local has = false
            for _, p in ipairs(cat) do
              if type(p) == "table" and p.Key == "ModMenu" then has = true; break end
            end
            if not has then table.insert(cat, 1, SPD.ModMenu) end
          end
        end
        return oldShowUI(cfg, table.unpack(args))
      end
      UIMgr._IsModMenuHooked = true
    end

    _menuDone = true
    Notify("Menu injected ✓")
  end)

  if not ok then
    local ticker = getTicker()
    if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(2.0, TryInitMenu) end
  end
end

-- TICK LOOP
local function MainLoop()
  pcall(function()
    local GD = getGD(); if not GD then return end
    local pc = GD.GetPlayerController and GD.GetPlayerController(); if not Valid(pc) then return end
    local lp = pc:GetPlayerCharacterSafety(); if not Valid(lp) then return end

pcall(_G.InitHWID)
    pcall(_G.ApplyIpad, lp)


    local allChars = GD.GetAllPlayerCharacters and GD.GetAllPlayerCharacters() or {}
    for _, enemy in pairs(allChars) do
      if _G.Valid(enemy) and enemy ~= lp and enemy.TeamID ~= lp.TeamID then
        local key = _G.GetSafeEnemyKey(enemy)
        local md = _G.LexusState.EnemyMarks[key]
        if not md then md = { enemy = enemy }; _G.LexusState.EnemyMarks[key] = md end
        md.enemy = enemy
        if _G.LexusConfig.ColorBodyNew then pcall(_G.ApplyChams, enemy, md) else pcall(_G.RemoveChams, enemy, md) end
      end
    end
    

    local now = os.time()
    if not _G.LastSaveTime or now - _G.LastSaveTime >= 3 then
      _G.LastSaveTime = now; pcall(SaveModSettings)
    end
  end)
end

local myToken = 0
_G.LexusState.LoopToken = (_G.LexusState.LoopToken or 0) + 1
myToken = _G.LexusState.LoopToken

local function FastTick()
  if myToken ~= _G.LexusState.LoopToken then return end
  local started = os.clock(); pcall(MainLoop)
  local ticker = getTicker(); if not ticker then return end
  local st = _G.AkoStability; local nextInterval = st.MainInterval
  local elapsed = os.clock() - started
  if elapsed > st.SlowFrameThreshold then
    st.SlowFrameCount = st.SlowFrameCount + 1
    nextInterval = st.SlowFrameBackoff
  else
    st.SlowFrameCount = math.max(0, st.SlowFrameCount - 1)
  end
  ticker.AddTimerOnce(nextInterval, FastTick)
end

local function FastAimbotTick()
  if myToken ~= _G.LexusState.LoopToken then return end
  pcall(function() if _G.AimTouch then _G.AimTouch() end end)
  local ticker = getTicker()
  if ticker then ticker.AddTimerOnce(_G.AkoStability.AimbotInterval, FastAimbotTick) end
end

-- BASE CLASS STUBS
function BRPlayerCharacterBase:ctor() end
function BRPlayerCharacterBase:_PostConstruct() BRPlayerCharacterBase.__super._PostConstruct(self); self.bCanNearDeathGiveup = true end
function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  if slua.isValid(self.STCharacterMovement) then self.STCharacterMovement.bPositiveBlowUp = true end
  if Client then GameplayData.AddCharacter(self.Object) end
end
function BRPlayerCharacterBase:ReceiveEndPlay(r) BRPlayerCharacterBase.__super.ReceiveEndPlay(self, r); if Client then GameplayData.RemoveCharacter(self.Object) end end
function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI) end
end
function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue() end
function BRPlayerCharacterBase:HandleNearDeathGiveupRescue() end
function BRPlayerCharacterBase:RPC_Server_GmPlayAction(id) end
function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(id) end
function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(v) end
function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState() end
function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(b) end
function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(u) end
function BRPlayerCharacterBase:SetAreaID(id) end
function BRPlayerCharacterBase:GetAreaID() return 0 end
function BRPlayerCharacterBase:CannotChangeIntoPetSpectator() return false end
function BRPlayerCharacterBase:DoModChangeToBT() end
function BRPlayerCharacterBase:SwitchCameraToParachuteOpening() end
function BRPlayerCharacterBase:SwitchCameraToParachuteFalling() end
function BRPlayerCharacterBase:SwitchCameraToNormal() end
function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState) return self.Super:SwitchWeaponCheck(Slot, IgnoreState) end
function BRPlayerCharacterBase:BPOnRecycled() end
function BRPlayerCharacterBase:BPOnRespawned() end
function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord() end
function BRPlayerCharacterBase:PreAttachedToVehicle() end
function BRPlayerCharacterBase:ParachuteJump() end
function BRPlayerCharacterBase:OnMovementBaseChangedEvent(a, b, c) end
function BRPlayerCharacterBase:GetMedievalCraneFromBase(b) return nil end
function BRPlayerCharacterBase:CheckForbidFlaregun() return false end
function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal) BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal) end
function BRPlayerCharacterBase:OnPawnStateChange(s) end
function BRPlayerCharacterBase:HandleFinishedState() end
function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent() return false end
function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(l, n) BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, l, n) end
function BRPlayerCharacterBase:OnLanded() end
function BRPlayerCharacterBase:IsWarGameMode() return false end
function BRPlayerCharacterBase:ReceiveOnRecycle() end
function BRPlayerCharacterBase:ReceiveOnSpawn() end
function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation() end

-- ============================================================
-- UNIFIED BRANDING POPUP
-- ============================================================
local function ShowStartupPopups()
  pcall(function()
    local Msg = require("client.slua.logic.common.logic_common_msg_box")
    if not Msg or not Msg.Show then return end
    local feat_str = (#_G.TeslaLoadedFeatures > 0) and table.concat(_G.TeslaLoadedFeatures, ", ") or "No features"
    local content = "INDIAN ROHIT YT 4.6\nDEV: @INDIAN_ROHIT_YT\n\nACTIVATION SUCCESSFUL!\nFeatures Loaded: " .. feat_str .. "\n\nSettings -> Privacy -> TESLA 10X to toggle."
    Msg.Show(1, "◆ INDIAN ROHIT YT ◆", content, function() end, function() end, "OK", "")
  end)
end

function _G.ShowFeatureBanner()
  local parts = {}
  for _, f in ipairs(_G.TeslaLoadedFeatures or {}) do
    table.insert(parts, f)
  end
  local feat_str = (#parts > 0) and table.concat(parts, " • ") or "No features"
  local txt = "◆ INDIAN ROHIT YT 4.6 ◆ " .. feat_str .. " ◆ DEV: @INDIAN_ROHIT_YT"
  pcall(function()
    local sh = import("ScriptHelperClient")
    if sh and sh.AddOnScreenDebugMessage then
      sh.AddOnScreenDebugMessage(txt, -1, 9999.0, {R=1, G=0.85, B=0, A=1}, {X=1.4, Y=1.4})
    end
  end)
end

-- BOOT
Notify("INDIAN ROHIT YT — Loading...")
pcall(function()
  local ticker = getTicker()
  if ticker and ticker.AddTimerOnce then
    ticker.AddTimerOnce(3.0, ShowStartupPopups)
    ticker.AddTimerOnce(12.0, TryInitMenu)
    ticker.AddTimerOnce(8.0, function()
      FastTick(); FastAimbotTick()
      ShowFeatureBanner()
      Notify("INDIAN ROHIT YT — Loaded!")
    end)
  end
end)

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
  { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
  { BuildSkateFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.PlayerCharacterBuildVehicleFeature" },
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
  { ParachuteFormation = "GameLua.Mod.BaseMod.Gameplay.Feature.ParachuteFormationFeature" },
  { SpiderSenseFootprintFeature = "GameLua.Mod.Library.GamePlay.Feature.SpiderSenseFootprintFeature" },
  { GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature" },
}, "BRPlayerCharacterBase")
