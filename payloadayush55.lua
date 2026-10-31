-- ====================================================================
-- GocReal — Part 1/2 (AGGRESSIVE BYPASS EDITION)
-- Owner: @AYUSHKRJ
-- Channel: GocReal
-- Config: GocReal_settings.txt
-- ====================================================================

local BRPlayerCharacterBase = {
  ServerRPC = {}, ClientRPC = {}, MulticastRPC = {}, LuaEventContainer = {}
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
    local C = import("CheckFallingDistanceComponent")
    if slua.isValid(C) and not slua.isValid(self:GetComponentByClass(C)) then
      Game:AddComponent(C, self, "CheckFallingDistanceComponent")
    end
  end
  if slua.isValid(self.STCharacterMovement) then self.STCharacterMovement.bPositiveBlowUp = true end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", { AttrName = { "bCanSelfRescue" } }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
    GameplayData.AddCharacter(self.Object)
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, { [1] = "FinishedState" }, self.HandleFinishedState, self)
  end
end
function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
  if self.Object ~= uPawn then return end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local PC = self:GetPlayerControllerSafety()
    if slua.isValid(PC) then PC:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "") end
  end
end
function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  if PawnState == EPawnState.SwitchPP then
    local PC = self:GetPlayerControllerSafety()
    if slua.isValid(PC) then PC:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "") end
  end
end
function BRPlayerCharacterBase:HandleFinishedState()
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
    local M = import("EDynamicSimpleQueryConfigDisableMask")
    self.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(M.Bit0, true)
  end
end
function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local gt = CGameMode.GameModeType
    local gid = tonumber(CGameState.GameModeID)
    local a = gt == EGameModeType.ETypicalGameMode or gt == EGameModeType.EFourInOneGameMode or gt == EGameModeType.EHeavyWeaponGameMode
    local b = not MatchModeIds[gid]
    return a and b
  end
  return false
end
function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(last, new)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, last, new)
  if not Client then
    local PC = self:GetPlayerControllerSafety()
    if slua.isValid(PC) and PC.CheckParachuteOpenFeature then
      if new == EParachuteState.PS_Opening then
        if PC.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then PC.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI() end
      elseif new == EParachuteState.PS_None then
        if PC.CheckParachuteOpenFeature.RecoverParachuteOpenParam then PC.CheckParachuteOpenFeature:RecoverParachuteOpenParam() end
        if PC.CheckParachuteOpenFeature.ClearTimerAndState then PC.CheckParachuteOpenFeature:ClearTimerAndState() end
      end
    end
  end
end
function BRPlayerCharacterBase:OnLanded()
  if self.HandleOnLanded then self:HandleOnLanded(-1) end
  if not Client then
    local PC = self:GetPlayerControllerSafety()
    if slua.isValid(PC) and PC.CheckParachuteOpenFeature then
      if PC.CheckParachuteOpenFeature.ClearTimerAndState then PC.CheckParachuteOpenFeature:ClearTimerAndState() end
      if PC.CheckParachuteOpenFeature.ResetCheckShowUI then PC.CheckParachuteOpenFeature:ResetCheckShowUI() end
    end
  end
end
function BRPlayerCharacterBase:ReceiveEndPlay(r)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, r)
  if Client then GameplayData.RemoveCharacter(self.Object) end
end
function BRPlayerCharacterBase:IsWarGameMode()
  local gs = GameplayData:GetGameState()
  if slua.isValid(gs) and Game:IsClassOf(gs, STExtraGameStateBase) then return gs.GameModeType == EGameModeType.EWarGameMode end
  return false
end
function BRPlayerCharacterBase:BPOnRecycled() if Client then self:ResetMeshRelativeLocationAndRotation() end end
function BRPlayerCharacterBase:BPOnRespawned() if Client then self:ResetMeshRelativeLocationAndRotation() end end
function BRPlayerCharacterBase:ReceiveOnRecycle()
  if Client then self:ResetMeshRelativeLocationAndRotation(); GameplayData.RemoveCharacter(self.Object) end
end
function BRPlayerCharacterBase:ReceiveOnSpawn()
  if Client then self:ResetMeshRelativeLocationAndRotation(); GameplayData.AddCharacter(self.Object) end
end
function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
  if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
    local rot = FRotator(0, -90, 0)
    local loc = FVector(0, 0, 0)
    if self.Mesh.K2_SetRelativeRotation then self.Mesh:K2_SetRelativeRotation(rot, false, nil, false) end
    self:CacheInitialMeshOffset(loc, rot)
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
  local PC = self:GetPlayerControllerSafety()
  if not slua.isValid(PC) then return end
  local AV = self.CharacterAvatarComp2_BP
  if not slua.isValid(AV) then return end
  local U = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
  local cid = U:ChangeVehicleSkinByClothes(PC, AV)
  local T = import("ESTExtraVehicleShapeType")
  if cid then
    local A = import("AvatarUtils")
    if A.GetVehicleShapeBySkinID(cid) == T.VST_Horse then
      local PS = self:GetPlayerStateSafety()
      if slua.isValid(PS) then PS:AddGeneralCount(468, 1, false) end
    end
  end
end
function BRPlayerCharacterBase:ParachuteJump()
  local PC = self:GetControllerSafety()
  if slua.isValid(PC) then
    if not self:GetEnsure() then
      if PC:GetCurrentStateType() ~= EStateType.State_ParachuteJump and PC:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
        self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
        PC:ReInitParachuteItem()
        PC:ServerChangeStatePC(EStateType.State_ParachuteJump)
      end
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
    end
  end
end
function BRPlayerCharacterBase:OnMovementBaseChangedEvent(u, n, o)
  if u ~= self.Object then return end
  local MC = self:GetMedievalCraneFromBase(n)
  if MC and MC.AddCharacter then MC:AddCharacter(self.Object)
  else
    MC = self:GetMedievalCraneFromBase(o)
    if MC and MC.RemoveCharacter then MC:RemoveCharacter(self.Object) end
  end
end
function BRPlayerCharacterBase:GetMedievalCraneFromBase(b)
  if not slua.isValid(b) or not b.GetOwner then return end
  local L = b:GetOwner()
  if not slua.isValid(L) or not L.AddCharacter then return end
  return L
end
function BRPlayerCharacterBase:CheckForbidFlaregun()
  local PS = self:GetPlayerStateSafety()
  if not slua.isValid(PS) then return false end
  if PS.CanUseFlaregun == false and self:IsLocallyControlled() then
    local PC = self:GetPlayerControllerSafety()
    if slua.isValid(PC) then PC:DisplayGameTipWithMsgID(48532) end
  end
  return not PS.CanUseFlaregun
end
function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue() self:HandleNearDeathGiveupRescue() end
function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
  local C = self.NearDeatchComponent
  if self:IsNearDeath() and slua.isValid(C) and self.bCanNearDeathGiveup == true then
    local PS = self:GetPlayerStateSafety()
    if slua.isValid(PS) then PS:AddGeneralCount(1613, 1, false) end
    C:TriggerGotoDieExplictly(self.Object)
  end
end
function BRPlayerCharacterBase:RPC_Server_GmPlayAction(a)
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then self:MulticastRPC_GmPlayAction(a) end
end
function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(a)
  if not Client then return end
  local C = self:GetPlayEmoteComponent()
  if not slua.isValid(C) then return end
  local LF = require("common.log_filter"); LF.SetLogTreeEnable(true)
  local cfg = CDataTable.GetTableData("EmoteBPTable", a)
  if not cfg then return end
  local path = cfg.Path
  local H = slua.loadObject(path)
  local arr = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local h = H()
  C:OnLoadEmoteAssetBegin(h, a, arr, "")
  local tb = FuncUtil.LuaArrayToTable(arr)
  local au = require("common.asset_util")
  function loadLater() C:OnLoadEmoteAssetEnd(h, a, 0) end
  au.GetAssetsArrayAsyncParallel(tb, loadLater)
end
function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(b)
  if slua.isValid(self.ParachuteComponent) then self.ParachuteComponent.bServerSyncShouldCheckPassWall = b end
end
function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState() end
end
function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(b)
  self.Super:OnPlayerLeaveCarryBoxState(b)
  if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(b) end
end
function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(u)
  if slua.isValid(u) and Game:IsClassOf(u, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(u)
  end
end
function BRPlayerCharacterBase:SetAreaID(a) self:SetAttrValue("AreaID", a, -1) end
function BRPlayerCharacterBase:GetAreaID() return math.floor(self:GetAttrValue("AreaID") + 0.5) end
function BRPlayerCharacterBase:CannotChangeIntoPetSpectator() return self.bCannotChangeIntoPetSpectator end
function BRPlayerCharacterBase:DoModChangeToBT()
  if self:HasState(EPawnState.SpecialSuit) then self:TriggerEntrySkillWithID(4301101, true) end
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
  if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then self.ParachuteFormation:OnLandingClearFormationCamera() end
end
function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, Ig)
  if self:HasState(EPawnState.AttachToOther) then
    local W = self:GetWeaponBySlot(Slot)
    if slua.isValid(W) then
      local wid = W:GetWeaponID()
      local cfg = GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
      if cfg and cfg.CheckIsWeaponInBlackList and cfg.CheckIsWeaponInBlackList(wid) then
        local PC = self:GetPlayerControllerSafety()
        if Client and slua.isValid(PC) and PC.Role == ENetRole.ROLE_AutonomousProxy then PC:DisplayGameTipWithMsgID(47306) end
        return false
      end
    end
  end
  if self:HasState(EPawnState.WebSwing) and Slot ~= ESurviveWeaponPropSlot.SWPS_None and slua.isValid(self.STCharacterMovement) then
    local O = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementType.SPECIAL_MOVE_SpiderSwing)
    if slua.isValid(O) then
      local s = O:GetCurMoveState()
      if s == ESpiderSwingMoveState.Launching or s == ESpiderSwingMoveState.Swinging then return false end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, Ig)
end

local _slua = rawget(_G, "slua")

_G.Safe = function(tag, fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then
    pcall(function() print("[AYUSHKRJ][ERR][" .. tostring(tag) .. "] " .. tostring(err)) end)
  end
  return ok
end

_G.ModuleCache = _G.ModuleCache or {}
_G.GetModule = function(path)
  local c = _G.ModuleCache[path]
  if c ~= nil then return c or nil end
  local ok, mod = pcall(require, path)
  _G.ModuleCache[path] = ok and mod or false
  return ok and mod or nil
end

_G.FrameDelta = _G.FrameDelta or { Last = 0, Delta = 0.016, ClampedDelta = 0.016 }
_G.TickFrame = function()
  local now = os.clock()
  local d = now - (_G.FrameDelta.Last or now)
  if d <= 0 or d > 1.0 then d = 0.016 end
  _G.FrameDelta.Last = now
  _G.FrameDelta.Delta = d
  _G.FrameDelta.ClampedDelta = math.min(d, 0.05)
end
_G.UpdateFrameDelta = _G.TickFrame

_G.Lerp = function(a, b, t) t = math.max(0, math.min(1, t)); return a + (b - a) * t end
_G.LerpSmooth = function(a, b, speed, dt) return a + (b - a) * (1 - math.exp(-speed * dt)) end

_G.atan2 = function(y, x)
  if x > 0 then return math.atan(y/x) end
  if x < 0 then return math.atan(y/x) + (y >= 0 and math.pi or -math.pi) end
  if y > 0 then return math.pi/2 end
  if y < 0 then return -math.pi/2 end
  return 0
end

local function Notify(msg)
  local s = "[GocReal] " .. tostring(msg)
  pcall(function() print(s) end)
  pcall(function()
    local sh = import("ScriptHelperClient")
    if sh and sh.AddOnScreenDebugMessage then
      sh.AddOnScreenDebugMessage(s, -1, 4.0, {R=1, G=0.85, B=0, A=1}, {X=1.2, Y=1.2})
    end
  end)
end
_G.Notify = Notify

local function Valid(o)
  if not o then return false end
  if _slua and _slua.isValid then
    local ok, v = pcall(_slua.isValid, o)
    if not ok or not v then return false end
  end
  return true
end
_G.Valid = Valid

_G.C_GREEN      = {R=0, G=255, B=0, A=255}
_G.C_RED        = {R=255, G=30, B=30, A=255}
_G.C_RED_DEEP   = {R=180, G=20, B=20, A=255}
_G.C_RED_TEXT   = {R=255, G=40, B=40, A=255}
_G.C_RED_HP     = {R=255, G=25, B=25, A=255}
_G.C_RED_BG     = {R=40, G=4, B=4, A=255}
_G.C_CYAN       = {R=0, G=255, B=255, A=255}
_G.C_YELLOW     = {R=255, G=255, B=0, A=255}
_G.C_WHITE      = {R=255, G=255, B=255, A=255}
_G.C_BLUE_TEXT  = {R=0, G=200, B=255, A=255}
_G.C_GOLD       = {R=255, G=217, B=0, A=255}

_G.GLOBAL_BONE_LIST = {
  "head", "neck_01", "pelvis", "upperarm_r", "lowerarm_r", "hand_r",
  "upperarm_l", "lowerarm_l", "hand_l", "thigh_l", "calf_l", "foot_l",
  "thigh_r", "calf_r", "foot_r"
}

_G.LexusConfig = _G.LexusConfig or {
  FakeHWID = false, EspLoai9 = false,
  Esp9_Count = false, Esp9_Name = false, Esp9_HP = false, Esp9_Team = false,
  Esp9_Weapon = true, Esp9_Distance = false, Esp9_Line = false, Esp9_Skeleton = false,
  WeaponGlow = false, OutlineThickness = 10, ColorBodyNew = false,
  EspAntenna = false, EspDistance = false, EspVipPro = false,
  ColorBodyNew = false, NoRecoilEnabled = false, RecoilReduction = 100,
  AimbotEnabled = false, WeaponAimbot = false, AutoHead = false,
  -- Environment
  RemoveFog = false, RemoveGrass = false, RemoveTrees = false, BlackSky = false,
  -- ESP Location Box
  ESPLocationBox = false,
  EspInfo = false, EspInfo_Weapon = true, EspInfo_Pose = true,
  KillMessage = false, IpadView = false, IpadViewFOV = 120,
  UnlockFPS = false, FPSLimit = 165, Crosshair = false, CrosshairStyle = 1, CrosshairSize = 4, CrosshairColor = 2,
}
_G.LexusState = _G.LexusState or {

  LoopToken = 0, NativeESPReady = false, MenuStep = 0, EnemyMarks = {},
  CustomTextData = nil, LastConfigHash = "", DirtySave = false, LastSaveTime = 0, FeatureStates = {},
}

local function _nop() return true end
local function _retFalse() return false end
local function _retTrue() return true end
local function _retZero() return 0 end
local function _retEmpty() return {} end
local function _retNil() return nil end
local function _retEmptyStr() return "" end

_G.BypassLog = {}
_G.InitializeExtraBypass = function()
  _G.ExtraBypassLog = {}
  local function extLog(name) table.insert(_G.ExtraBypassLog, name) end
  _G.Safe("eb_slua", function()
    if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
    local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
    if loader then loader.verifyBytecode = _retTrue; loader.checkIntegrity = _retTrue; if loader.disableSignatureCheck then loader.disableSignatureCheck = _retTrue end end
    local slua_serialize = package.loaded["slua.serialize"]
    if slua_serialize then slua_serialize.check = _retTrue; slua_serialize.verify = _retTrue end
    if jit and jit.attach then pcall(function() jit.attach(function() end, "bc") end) end
    if _G.slua_verify then _G.slua_verify = _retTrue end
    if _G.check_slua_integrity then _G.check_slua_integrity = _retTrue end
    extLog("EB1-SLUA-Signature")
  end)
  _G.Safe("eb_md5", function()
    local console = import("KismetSystemLibrary")
    if console then
      local world = slua.getWorld()
      if world then
        pcall(function() console.ExecuteConsoleCommand(world, "pak.DisablePakSignatureCheck 1") end)
        pcall(function() console.ExecuteConsoleCommand(world, "pakchunk.EnableSignatureCheck 0") end)
        pcall(function() console.ExecuteConsoleCommand(world, "s.VerifyPak 0") end)
        pcall(function() console.ExecuteConsoleCommand(world, "sig.Check 0") end)
        pcall(function() console.ExecuteConsoleCommand(world, "security.DisableChecks 1") end)
      end
    end
    local CreativeModeBlueprintLibrary = import("CreativeModeBlueprintLibrary")
    if CreativeModeBlueprintLibrary then
      CreativeModeBlueprintLibrary.MD5HashByteArray = function() return "00000000000000000000000000000000" end
      CreativeModeBlueprintLibrary.MD5HashFile = function() return "00000000000000000000000000000000" end
      CreativeModeBlueprintLibrary.GetContentDiffData = function() return true, "BYPASSED" end
      CreativeModeBlueprintLibrary.VerifyFileIntegrity = _retTrue
    end
    if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
    if _G.CRC32 then _G.CRC32 = function() return 0 end end
    local FileHashChecker = package.loaded["common.file_hash_checker"]
    if FileHashChecker then FileHashChecker.CheckFileMD5 = _retTrue; FileHashChecker.VerifyAll = _retTrue; FileHashChecker.GetHash = function() return "BYPASS" end end
    local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
    if TssSdk then TssSdk.GetFileMD5 = function() return "BYPASS" end; TssSdk.VerifyFileSignature = _retTrue end
    local STExtraLib = import("STExtraBlueprintFunctionLibrary")
    if STExtraLib then STExtraLib.CheckMD5 = _retTrue; STExtraLib.GetMD5 = function() return "BYPASS" end; STExtraLib.VerifyFile = _retTrue end
    extLog("EB2-MD5-PakSignature")
  end)
  _G.Safe("eb_report_flow", function()
    local reportFlows = { "ReportAttackFlow", "ReportSecAttackFlow", "ReportHurtFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData", "ReportEquipmentFlow", "ReportAimFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord", "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", "ReportCircleFlow", "ReportPlayerKillFlow" }
    for _, funcName in ipairs(reportFlows) do
      if _G[funcName] then _G[funcName] = _nop end
      if _G.GameplayCallbacks and _G.GameplayCallbacks[funcName] then _G.GameplayCallbacks[funcName] = _nop end
    end
    local checkFuncs = {"CheckReportSecAttackFlowWithAttackFlow", "CheckReportSecAttackFlow"}
    for _, funcName in ipairs(checkFuncs) do
      if _G[funcName] then _G[funcName] = _retFalse end
      if _G.GameplayCallbacks and _G.GameplayCallbacks[funcName] then _G.GameplayCallbacks[funcName] = _retFalse end
    end
    extLog("EB3-ReportFlowBlocker")
  end)
  _G.Safe("eb_security_collector", function()
    local collectorPaths = { "PlayerSecurityInfoCollector", "PlayerSecurityInfo", "SecurityInfoCollector", "ClientSecurityCollector", "PlayerAntiCheatCollector" }
    for _, collector in ipairs(collectorPaths) do
      if _G[collector] then for k, v in pairs(_G[collector]) do if type(v) == "function" and (k:find("Report") or k:find("Collect") or k:find("Send") or k:find("Upload") or k:find("Record")) then _G[collector][k] = _nop end end end
    end
    local SecuritySubsystem = package.loaded["GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem"]
    if SecuritySubsystem then SecuritySubsystem.ReportData = _nop; SecuritySubsystem.CheckCheat = _retFalse; SecuritySubsystem.ValidatePlayer = _retTrue; SecuritySubsystem.CollectData = _nop; SecuritySubsystem.SendToServer = _nop end
    extLog("EB4-SecurityCollector")
  end)
  _G.Safe("eb_heartbeat_swift", function()
    local heartbeatFuncs = {"Heartbeat", "SendHeartbeat", "ClientHeartbeat", "ServerHeartbeat"}
    for _, func in ipairs(heartbeatFuncs) do if _G[func] then _G[func] = _nop end end
    local swiftFuncs = {"SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams", "SendSwiftHawkData"}
    for _, func in ipairs(swiftFuncs) do if _G[func] then _G[func] = _nop end end
    extLog("EB5-Heartbeat-SwiftHawk")
  end)
  _G.Safe("eb_higgs_anticheat", function()
    local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
    if Higgs then
      local methods = { "ControlMHActive", "Tick", "OnTick", "MHActiveLogic", "TriggerAvatarCheck", "StartAvatarCheck", "ReportItemID", "ReceiveAnyDamage", "OnWeaponHitRecord", "ShowSecurityAlert", "ServerReportAvatar", "ClientReportNetAvatar", "SendHisarData", "ValidateSecurityData", "StaticShowSecurityAlertInDev", "RPC_Client_ShootVertifyRes", "RPC_Server_ReportSimulateCharacterLocation", "DisableHiggsBoson", "CheckMHActive", "ReportViolation", "ProcessSecurityEvent", "ValidatePlayer", "CheckIntegrity" }
      for _, m in ipairs(methods) do if Higgs[m] then Higgs[m] = _nop end end
      Higgs.GetNetAvatarItemIDs = _retEmpty; Higgs.GetCurWeaponSkinID = _retZero; Higgs.IsMHActive = _retFalse; Higgs.bMHActive = false; Higgs.bCallPreReplication = false
      if Higgs.BlackList then for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end end
    end
    if _G.BlackList then _G.BlackList = {} end
    extLog("EB6-HiggsBoson-AntiCheat")
  end)
  _G.Safe("eb_runtime_reapply", function()
    local ticker = _G.GetModule("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
      local function ReapplyExtra()
        _G.Safe("eb_reapply_tick", function()
          local pc = _G.getCachedGameplayData() and _G.getCachedGameplayData().GetPlayerController and _G.getCachedGameplayData().GetPlayerController()
          if Valid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false end
          end
        end)
        ticker.AddTimerOnce(3.0, ReapplyExtra)
      end
      ticker.AddTimerOnce(3.0, ReapplyExtra)
    end
    extLog("EB7-RuntimeReapply")
  end)
end

-- [NEW] AGGRESSIVE BYPASS START
_G.InitializeAggressiveBypass = function()
  _G.AggressiveBypassLog = {}
  local function extLog(name) table.insert(_G.AggressiveBypassLog, name) end

  _G.Safe("aggr_subsystem_smasher", function()
    local SsMgr = _G.GetModule("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if not SsMgr then return end
    local targets = {
      "AFKReportorSubsystem", "ClientDataStatistcsSubsystem", "AvatarExceptionSubsystem",
      "ShootVerifySubSystemClient", "BehaviorScoreSubsystem", "MemoryCheckSubsystem",
      "SpeedCheckSubsystem", "WallCheckSubsystem", "FileCheckSubsystem", "SecuritySubsystem",
      "CoronaLabSubsystem", "SwiftHawkSubsystem", "HiggsBosonSubsystem", "AntiCheatSubsystem"
    }
    for _, t in ipairs(targets) do
      local sub = SsMgr:Get(t)
      if sub then
        for k, v in pairs(sub) do
          if type(v) == "function" then
            local kl = k:lower()
            if kl:find("report") or kl:find("send") or kl:find("check") or kl:find("verify") or kl:find("scan") or kl:find("detect") then
              sub[k] = _nop
            end
          end
        end
      end
    end
    extLog("Aggr-SubsystemSmasher")
  end)

  _G.Safe("aggr_network_blocker", function()
    local NetUtil = _G.NetUtil
    if NetUtil and NetUtil.SendPacket and not NetUtil._AggrBlocked then
      local origSend = NetUtil.SendPacket
      NetUtil.SendPacket = function(name, ...)
        if type(name) == "string" then
          local lName = name:lower()
          if lName:find("report") or lName:find("anticheat") or lName:find("security") or lName:find("verify") or lName:find("flow") then
            return nil
          end
        end
        return origSend(name, ...)
      end
      NetUtil._AggrBlocked = true
    end
    extLog("Aggr-NetworkBlocker")
  end)

  _G.Safe("aggr_tss_corona", function()
    local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
    if TssSdk then
      TssSdk.SendReportInfo = _nop
      TssSdk.ScanMemory = _retTrue
      TssSdk.IsEmulator = _retFalse
      TssSdk.CheckEnvironment = _retTrue
      TssSdk.VerifyProcess = _retTrue
      TssSdk.GetFileMD5 = function() return "00000000000000000000000000000000" end
    end
    local CoronaLab = _G.CoronaLab
    if CoronaLab then
      CoronaLab.ReportData = _nop
      CoronaLab.SendData = _nop
      CoronaLab.CollectData = _nop
    end
    extLog("Aggr-TssSdk_CoronaLab")
  end)

  _G.Safe("aggr_ban_blocker", function()
    local KSL = import("KismetSystemLibrary")
    local world = slua.getWorld()
    if KSL and world then
      pcall(function() KSL.ExecuteConsoleCommand(world, "DisableBanUI 1") end)
      pcall(function() KSL.ExecuteConsoleCommand(world, "ShowBanNotice 0") end)
      pcall(function() KSL.ExecuteConsoleCommand(world, "UI.DisableMessageOfTheDay 1") end)
    end
    if _G.GameplayCallbacks then
      _G.GameplayCallbacks.OnDSPlayerStateChanged = function(uid, state)
        local s = tostring(state):lower()
        if s:find("cheat") or s:find("ban") or s:find("kick") then return end
      end
    end
    extLog("Aggr-BanBlocker")
  end)

  _G.Safe("aggr_analytics_blocker", function()
    local CrashSight = _G.CrashSight or package.loaded["CrashSight"]
    if CrashSight then
      CrashSight.ReportException = _nop
      CrashSight.SendCrash = _nop
      CrashSight.ReportUserException = _nop
    end
    local SMTD = import("ScreenshotMTDer")
    if SMTD then SMTD.MTDePicture = function() return "" end end
    local ScreenshotMaker = import("ScreenshotMaker")
    if ScreenshotMaker then ScreenshotMaker.MakePicture = function() return "" end end
    extLog("Aggr-AnalyticsBlocker")
  end)

  _G.Safe("aggr_gameplay_callbacks", function()
    if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
    local gc = _G.GameplayCallbacks
    local funcs = {
      "ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", "ReportVerifyInfoFlow",
      "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportPlayerMoveRoute",
      "ReportPlayerPosition", "ReportAimFlow", "ReportHitFlow", "ReportCircleFlow",
      "ClientSecMrpcsFlow", "SwiftHawk", "ClientSwiftHawk", "ReportPlayersPing", "ReportPlayerIP"
    }
    for _, f in ipairs(funcs) do gc[f] = _nop end
    gc.CheckReportSecAttackFlowWithAttackFlow = _retFalse
    gc.CheckReportSecAttackFlow = _retFalse
    extLog("Aggr-GameplayCallbacks")
  end)

  _G.Safe("aggr_integrity", function()
    local PI = _G.PlayIntegrity
    if PI then
      PI.Verify = _retTrue
      PI.Check = _retTrue
      PI.GetToken = function() return "AGGR_BYPASSED" end
    end
    local SN = _G.SafetyNet
    if SN then
      SN.Verify = _retTrue
      SN.Check = _retTrue
      SN.GetAttestation = function() return "AGGR_BYPASSED" end
    end
    extLog("Aggr-IntegritySpoof")
  end)
end
-- [NEW] AGGRESSIVE BYPASS END

_G.InitializeBypass = function()
  _G.BypassLog = {}
  _G.Safe("bp_L1", function()
    local ptlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
    if ptlog then ptlog.ReportEvent = _nop; ptlog.ReportDownloadResult = _nop; ptlog.ReportODPTDError = _nop; ptlog.ReportSkinError = _nop; ptlog.ReportError = _nop; ptlog.OnDownloadError = _nop; ptlog.ReportODPD = _nop; ptlog.ReportPufferError = _nop; table.insert(_G.BypassLog, "L1-puffer_tlog") end
  end)
  _G.Safe("bp_L2", function()
    local AU = package.loaded["AvatarUtils"]
    if AU then AU.CheckIsWeaponInBlackList = _retFalse; AU.IsValidAvatar = _retTrue; AU.CheckAvatarIntegrity = _retTrue; AU.ReportInvalidAvatar = _nop; AU.CheckSkinValid = _retTrue; AU.ReportSkinMismatch = _nop; AU.CheckAvatarValid = _retTrue; table.insert(_G.BypassLog, "L2-AvatarUtils") end
  end)
  _G.Safe("bp_L3", function()
    local eq = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
    if eq then eq.Report = _nop; eq.SendException = _nop; eq.ReportException = _nop; eq.OnException = _nop; eq.SendReport = _nop; table.insert(_G.BypassLog, "L3-EquipmentException") end
  end)
  _G.Safe("bp_L4", function()
    local applied = false
    local SsMgr = _G.GetModule("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SsMgr and SsMgr.Get then
      local ok, sub = pcall(function() return SsMgr:Get("FileCheckSubsystem") end)
      if ok and sub then sub.StartCheck = _nop; sub.ReportAbnormalFile = _nop; sub.StopCheck = _nop; sub.CheckFileHash = _nop; sub.VerifyPak = _retTrue; sub.ReportTamper = _nop; sub.CheckSignature = _retTrue; sub.ValidateFiles = _retTrue; sub.RunIntegrityCheck = _retTrue; sub.CheckAllFiles = _retTrue; applied = true end
    end
    local fcs = package.loaded["GameLua.GameCore.Module.Subsystem.FileCheckSubsystem"]
    if fcs then fcs.StartCheck = _nop; fcs.VerifyPak = _retTrue; fcs.CheckAllFiles = _retTrue; fcs.ReportAbnormalFile = _nop; applied = true end
    if applied then table.insert(_G.BypassLog, "L4-FileCheck") end
  end)
  _G.Safe("bp_L5to9", function()
    local paths = { "client.slua.logic.report.CheatReport", "client.slua.logic.report.ClientReport", "client.slua.logic.report.AntiCheatReport", "client.slua.logic.report.PlayerReport", "client.slua.logic.report.ReportManager", "client.slua.logic.report.GameReport", "client.slua.logic.report.TamperReport" }
    for i, p in ipairs(paths) do
      local m = package.loaded[p]
      if m then m.Report = _nop; m.SendReport = _nop; m.ReportCheat = _nop; m.ReportPlayer = _nop; m.ReportTamper = _nop; m.ReportException = _nop; m.Send = _nop; table.insert(_G.BypassLog, "L" .. (4+i) .. "-" .. p:match("([^%.]+)$")) end
    end
  end)
  _G.Safe("bp_L10", function()
    local SL = import("KismetSystemLibrary")
    if SL and not _G.FakeHWID_Hooked then
      local function Gen(n) local c = "0123456789ABCDEF"; local s = ""; for i = 1, n do local idx = math.random(1, #c); s = s .. c:sub(idx, idx); if i == 8 or i == 12 or i == 16 or i == 20 then s = s .. "-" end end; return s end
      _G.Original_GetDeviceId = SL.GetDeviceId
      SL.GetDeviceId = function(...) if _G.LexusConfig.FakeHWID then if not _G.FakeHWID_String then _G.FakeHWID_String = Gen(32) end; return _G.FakeHWID_String end; if _G.Original_GetDeviceId then return _G.Original_GetDeviceId(...) end; return "UNKNOWN" end
      _G.FakeHWID_Hooked = true; table.insert(_G.BypassLog, "L10-DeviceId")
    end
  end)
  _G.Safe("bp_L11", function()
    local SL = import("KismetSystemLibrary")
    if SL and SL.GetUniqueID and not _G.FakeUID_Hooked then
      _G.Original_GetUniqueID = SL.GetUniqueID
      SL.GetUniqueID = function(...) if _G.LexusConfig.FakeHWID then if not _G.FakeUID_String then local c = "0123456789ABCDEF"; _G.FakeUID_String = "UID-"; for i = 1, 16 do local x = math.random(1, #c); _G.FakeUID_String = _G.FakeUID_String .. c:sub(x, x) end end; return _G.FakeUID_String end; return _G.Original_GetUniqueID(...) end
      _G.FakeUID_Hooked = true; table.insert(_G.BypassLog, "L11-UniqueID")
    end
  end)
  _G.Safe("bp_L12", function()
    local SL = import("KismetSystemLibrary")
    if SL and SL.GetMachineId and not _G.FakeMID_Hooked then
      _G.Original_GetMachineId = SL.GetMachineId
      SL.GetMachineId = function(...) if _G.LexusConfig.FakeHWID then if not _G.FakeMID_String then local c = "0123456789ABCDEF"; _G.FakeMID_String = "MID-"; for i = 1, 20 do local x = math.random(1, #c); _G.FakeMID_String = _G.FakeMID_String .. c:sub(x, x) end end; return _G.FakeMID_String end; return _G.Original_GetMachineId(...) end
      _G.FakeMID_Hooked = true; table.insert(_G.BypassLog, "L12-MachineId")
    end
  end)
  _G.Safe("bp_L13", function()
    local SL = import("KismetSystemLibrary")
    if SL and SL.GetMacAddress and not _G.FakeMAC_Hooked then
      _G.Original_GetMacAddress = SL.GetMacAddress
      SL.GetMacAddress = function(...) if _G.LexusConfig.FakeHWID then if not _G.FakeMAC_String then local c = "0123456789ABCDEF"; _G.FakeMAC_String = ""; for i = 1, 12 do local x = math.random(1, #c); _G.FakeMAC_String = _G.FakeMAC_String .. c:sub(x, x); if i % 2 == 0 and i < 12 then _G.FakeMAC_String = _G.FakeMAC_String .. ":" end end end; return _G.FakeMAC_String end; return _G.Original_GetMacAddress(...) end
      _G.FakeMAC_Hooked = true; table.insert(_G.BypassLog, "L13-MacAddress")
    end
  end)
  _G.Safe("bp_L14", function()
    local LF = package.loaded["common.log_filter"]
    if LF and LF.SetLogTreeEnable then _G.Original_SetLogTreeEnable = LF.SetLogTreeEnable; LF.SetLogTreeEnable = _nop; table.insert(_G.BypassLog, "L14-QuietLog") end
  end)
  _G.Safe("bp_L15", function()
    if rawget(_G, "ReportError") then rawset(_G, "ReportError", _nop) end
    if rawget(_G, "SendReport") then rawset(_G, "SendReport", _nop) end
    if rawget(_G, "ReportCheat") then rawset(_G, "ReportCheat", _nop) end
    table.insert(_G.BypassLog, "L15-GlobalReport")
  end)
  _G.Safe("bp_L16", function()
    local utils = package.loaded["GameLua.GameCore.Utils.FStringUtils"] or package.loaded["common.fstring_utils"]
    if utils then utils.CRC = _retZero; utils.CheckCRC = _retTrue; utils.FStringCRC = _retZero; table.insert(_G.BypassLog, "L16-CRC") end
  end)
  _G.Safe("bp_L17", function()
    local md5 = package.loaded["common.md5"] or package.loaded["utils.md5"]
    if md5 then md5.Check = _retTrue; md5.Verify = _retTrue; table.insert(_G.BypassLog, "L17-MD5") end
  end)
  _G.Safe("bp_L18", function()
    local pak = package.loaded["client.slua.logic.download.pak_integrity"]
    if pak then pak.Check = _retTrue; pak.Verify = _retTrue; pak.Report = _nop; table.insert(_G.BypassLog, "L18-PakIntegrity") end
  end)
  _G.Safe("bp_L19", function()
    local auth = package.loaded["client.slua.logic.auth.ClientAuthorize"]
    if auth then auth.Verify = _retTrue; auth.Check = _retTrue; auth.Report = _nop; table.insert(_G.BypassLog, "L19-ClientAuth") end
  end)
  _G.Safe("bp_L20", function()
    local dt = package.loaded["common.datatable_check"]
    if dt then dt.Check = _retTrue; dt.Verify = _retTrue; table.insert(_G.BypassLog, "L20-DataTable") end
  end)
  _G.Safe("bp_L21", function()
    local ssl = package.loaded["client.slua.network.ssl_verify"]
    if ssl then ssl.Verify = _retTrue; ssl.CheckCert = _retTrue; table.insert(_G.BypassLog, "L21-SSL") end
  end)
  _G.Safe("bp_L22", function()
    local ad = package.loaded["common.anti_debug"]
    if ad then ad.Check = _retFalse; ad.Detect = _retFalse; table.insert(_G.BypassLog, "L22-AntiDebug") end
  end)
  _G.Safe("bp_L23", function()
    local sa = package.loaded["client.slua.logic.auth.ServerAuthSignature"]
    if sa then sa.Verify = _retTrue; sa.Check = _retTrue; table.insert(_G.BypassLog, "L23-ServerAuth") end
  end)
  _G.Safe("bp_L24", function()
    local em = package.loaded["common.emulator_check"]
    if em then em.IsEmulator = _retFalse; em.Check = _retFalse; table.insert(_G.BypassLog, "L24-Emulator") end
  end)
  _G.Safe("bp_L25", function()
    local root = package.loaded["common.root_check"]
    if root then root.IsRooted = _retFalse; root.Check = _retFalse; table.insert(_G.BypassLog, "L25-Root") end
  end)
  _G.Safe("bp_L26", function()
    local vt = package.loaded["common.vtable_check"]
    if vt then vt.Check = _retTrue; vt.Verify = _retTrue; table.insert(_G.BypassLog, "L26-VTable") end
    local uf = package.loaded["client.slua.integrity.ufunction_guard"]
    if uf then uf.Verify = _retTrue; uf.Check = _retTrue; uf.Report = _nop; table.insert(_G.BypassLog, "L26-UFuncGuard") end
  end)
  _G.Safe("bp_L27", function()
    local hs = package.loaded["client.slua.network.handshake_verify"]
    if hs then hs.Verify = _retTrue; hs.Check = _retTrue; hs.Report = _nop; table.insert(_G.BypassLog, "L27-Handshake") end
    local sig = package.loaded["client.slua.network.packet_signature"]
    if sig then sig.Verify = _retTrue; sig.CheckSig = _retTrue; table.insert(_G.BypassLog, "L27-PacketSig") end
  end)
  _G.Safe("bp_L28", function()
    local ms = package.loaded["common.memory_scan"]
    if ms then ms.Scan = _retEmpty; ms.Detect = _retFalse; ms.Report = _nop; table.insert(_G.BypassLog, "L28-MemScan") end
    local dbg = package.loaded["common.debugger_check"]
    if dbg then dbg.IsDebuggerAttached = _retFalse; dbg.Check = _retFalse; table.insert(_G.BypassLog, "L28-Debugger") end
  end)
  _G.Safe("bp_L29", function()
    local pn = package.loaded["common.process_name"]
    if pn then pn.Get = function() return "com.tencent.ig" end; pn.Check = _retTrue; table.insert(_G.BypassLog, "L29-ProcessName") end
    if rawget(_G, "GetPackageName") then rawset(_G, "GetPackageName", function() return "com.tencent.ig" end); table.insert(_G.BypassLog, "L29-PkgName") end
  end)
  _G.Safe("bp_L30", function()
    local tc = package.loaded["common.time_check"]
    if tc then tc.Check = _retTrue; tc.Verify = _retTrue; table.insert(_G.BypassLog, "L30-TimeCheck") end
    local skew = package.loaded["client.slua.network.clock_skew"]
    if skew then skew.Verify = _retTrue; skew.Check = _retTrue; table.insert(_G.BypassLog, "L30-ClockSkew") end
  end)
  _G.Safe("bp_L31", function()
    local fr = package.loaded["common.frida_check"]
    if fr then fr.Detect = _retFalse; fr.Check = _retFalse; fr.IsAttached = _retFalse; table.insert(_G.BypassLog, "L31-Frida") end
    local xp = package.loaded["common.xposed_check"]
    if xp then xp.Detect = _retFalse; xp.Check = _retFalse; table.insert(_G.BypassLog, "L31-Xposed") end
    local ls = package.loaded["common.lsposed_check"]
    if ls then ls.Detect = _retFalse; ls.Check = _retFalse; table.insert(_G.BypassLog, "L31-LSPosed") end
  end)
end

_G.ConfigFileName = "GocReal_settings.txt"
_G.GetConfigPaths = function(fn)
  local p = {
    "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fn,
    "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fn,
    "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fn,
    "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fn,
    "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fn,
    "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fn,
    "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fn,
    "/com.tencent.ig/Documents/ShadowTrackerExtra/Saved/Paks/" .. fn,
    "/com.vng.pubgmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fn,
    "/com.pubg.krmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fn,
    "/com.rekoo.pubgm/Documents/ShadowTrackerExtra/Saved/Paks/" .. fn,
    "/com.pubg.imobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fn,
    "ShadowTrackerExtra/Saved/Paks/" .. fn,
    "../../ShadowTrackerExtra/Saved/Paks/" .. fn,
    "../../../ShadowTrackerExtra/Saved/Paks/" .. fn,
    "../../../../ShadowTrackerExtra/Saved/Paks/" .. fn,
    fn
  }
  pcall(function()
    if os and os.getenv then
      local h = os.getenv("HOME")
      if h and h ~= "" then
        table.insert(p, 1, h .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fn)
        table.insert(p, 2, h .. "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fn)
      end
    end
  end)
  return p
end

_G.BuildConfigPayload = function()
  local d = "-- GocReal Config v3.1\n-- Owner: @AYUSHKRJ\n-- Channel: GocReal\nreturn {\nLexusConfig = {\n"
  for k, v in pairs(_G.LexusConfig or {}) do
    local vs = tostring(v)
    if type(v) == "string" then vs = '"' .. v .. '"' end
    d = d .. '  ["' .. tostring(k) .. '"] = ' .. vs .. ',\n'
  end
  d = d .. "},\nCustomTextData = {\n"
  if _G.LexusState and _G.LexusState.CustomTextData then
    for k, v in pairs(_G.LexusState.CustomTextData) do
      local vs = tostring(v)
      if type(v) == "string" then vs = '"' .. v .. '"' end
      d = d .. '  ["' .. tostring(k) .. '"] = ' .. vs .. ',\n'
    end
  end
  d = d .. "}\n}"
  return d
end

_G.SaveModSettings = function(force)
  _G.Safe("save_cfg", function()
    if not force and not _G.LexusState.DirtySave then return end
    local now = os.clock()
    if not force and (_G.LexusState.LastSaveTime > 0) and (now - _G.LexusState.LastSaveTime) < 3.0 then return end
    local d = _G.BuildConfigPayload()
    if d == _G.LexusState.LastConfigHash then _G.LexusState.DirtySave = false; _G.LexusState.LastSaveTime = now; return end
    _G.LexusState.LastConfigHash = d
    _G.LexusState.LastSaveTime = now
    _G.LexusState.DirtySave = false
    for _, p in ipairs(_G.GetConfigPaths(_G.ConfigFileName)) do
      local f = io.open(p, "w")
      if f then f:write(d); f:close(); return end
    end
  end)
end

_G.MarkConfigDirty = function() _G.LexusState.DirtySave = true end
_G.LoadModSettings = function()
  _G.Safe("load_cfg", function()
    local content = nil
    for _, p in ipairs(_G.GetConfigPaths(_G.ConfigFileName)) do
      local f = io.open(p, "r")
      if f then content = f:read("*a"); f:close(); break end
    end
    if content then
      local fn = load(content)
      if fn then
        local d = fn()
        if d and type(d) == "table" then
          if d.LexusConfig then for k, v in pairs(d.LexusConfig) do if _G.LexusConfig[k] ~= nil then _G.LexusConfig[k] = v end end end
          if d.CustomTextData then _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}; for k, v in pairs(d.CustomTextData) do _G.LexusState.CustomTextData[k] = v end end
        end
      end
    end
  end)
end
_G.ReadLiveConfig = function() _G.MarkConfigDirty() end

local _lc, _sk, _gd = nil, nil, nil
_G.getCachedLinearColor = function() if _lc == nil then _lc = import("LinearColor") or _G.FLinearColor end; return _lc end
_G.getCachedSkeletalMesh = function() if _sk == nil then _sk = import("SkeletalMeshComponent") end; return _sk end
_G.getCachedGameplayData = function() if _gd == nil then local ok, m = pcall(require, "GameLua.GameCore.Data.GameplayData"); if ok then _gd = m end end; return _gd end

_G.GetSafeEnemyKey = function(e)
  if Valid(e) then
    if e.PlayerKey then return tostring(e.PlayerKey) end
    if type(e.GetUniqueID) == "function" then return tostring(e:GetUniqueID()) end
  end
  return tostring(e)
end

_G.CheckIsAI = function(p, md)
  -- [FIX] Always re-check; never trust stale AK_IS_BOT cache blindly.
  -- Cache is used only if a definitive check was done before (chk==true).
  if md and md.AK_IS_BOT ~= nil and md.AK_BOT_CONFIRMED == true then
    return md.AK_IS_BOT, true
  end
  local ai, chk = false, false
  pcall(function()
    -- Direct AI flags
    if p.bIsAI == true or p.IsAI == true then ai = true; chk = true end
    if type(p.IsBot) == "function" and p:IsBot() then ai = true; chk = true end
    -- PlayerState flags
    local ps = p.PlayerState or (type(p.GetPlayerState) == "function" and p:GetPlayerState())
    if Valid(ps) then
      chk = true
      if ps.bIsABot == true or ps.bIsBot == true then ai = true end
      if type(ps.IsBot) == "function" and ps:IsBot() then ai = true end
      -- [FIX] Extra: check OpenID / AccountID empty = bot signal
      if not ai then
        local oid = ps.OpenID or ps.AccountID or ps.PlayerID or ""
        if type(oid) == "string" and (oid == "" or oid == "0" or string.len(oid) < 3) then
          ai = true
        end
      end
      -- [FIX] Bot names in BGMI are often numeric-only or very short
      if not ai then
        local pname = nil
        pcall(function()
          if ps.GetPlayerName then pname = ps:GetPlayerName()
          elseif ps.PlayerName then pname = ps.PlayerName end
        end)
        if pname and type(pname) == "string" then
          -- Pure numeric name = bot
          if string.match(pname, "^%d+$") then ai = true end
          -- Very short (1-3 chars) = likely bot
          if string.len(pname) <= 3 then ai = true end
        end
      end
    end
    -- [FIX] Game.IsAI direct check
    if not ai and Game and type(Game.IsAI) == "function" then
      local r = false
      pcall(function() r = Game:IsAI(p) end)
      if r then ai = true; chk = true end
    end
    -- [FIX] STExtraBlueprintFunctionLibrary check
    if not ai then
      local STLib = import("STExtraBlueprintFunctionLibrary")
      if STLib and type(STLib.IsAIPlayer) == "function" then
        local r = false
        pcall(function() r = STLib:IsAIPlayer(p) end)
        if r then ai = true; chk = true end
      end
    end
  end)
  if md and chk then
    md.AK_IS_BOT = ai
    md.AK_BOT_CONFIRMED = true  -- mark as definitively checked
  end
  return ai, chk
end

_G.GetAllSkeletalMeshes = function(e, md)
  local t = os.clock()
  if md and md.CachedMeshes and md.CachedMeshTime and (t - md.CachedMeshTime < 0.5) then
    local v = {}
    for _, c in ipairs(md.CachedMeshes) do
      local pk = false
      pcall(function() if type(c.IsPendingKill) == "function" then pk = c:IsPendingKill() end end)
      if Valid(c) and not pk then table.insert(v, c) end
    end
    md.CachedMeshes = v
    return v
  end
  local m = {}
  if Valid(e.Mesh) then table.insert(m, e.Mesh) end
  pcall(function()
    local C = _G.getCachedSkeletalMesh()
    if C and type(e.GetComponentsByClass) == "function" then
      local c = e:GetComponentsByClass(C)
      if c then
        local n = type(c.Num) == "function" and c:Num() or #c
        for i = 1, n do
          local comp = type(c.Get) == "function" and c:Get(i-1) or c[i]
          if Valid(comp) and comp ~= e.Mesh then table.insert(m, comp) end
        end
      end
    end
  end)
  if md then md.CachedMeshes = m; md.CachedMeshTime = t end
  return m
end

_G.TDFTDeKillCounts = _G.TDFTDeKillCounts or {}
local _goldColor = nil
local _uiMgr = nil

_G.ForceEnableKillCounterUI = function()
  _G.Safe("kill_counter", function()
    local KCUIS = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"] or _G.GetModule("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
    if KCUIS and KCUIS.__inner_impl and not _G.KCUISHacked then
      local impl = KCUIS.__inner_impl
      impl.CheckSupportKCUI = function() return true end
      impl.CheckNeedMainKillCounterUI = function(self, W, PID)
        if slua.isValid(W) then local wid = W:GetWeaponID(); self:UpdateMainKillCounterUI(true, wid, wid) else self:UpdateMainKillCounterUI(false) end
      end
      _G.KCUISHacked = true
    end
    local MM = _G.GetModule("client.module_framework.ModuleManager")
    if MM and not _G.KCLogicHacked then
      local LKC = MM.GetModule(MM.CommonModuleConfig.LogicKillCounter)
      if LKC then
        LKC.CheckSupportKC = function() return true end
        LKC.CheckSupportKillCounterAvatar = function() return true end
        LKC.CheckHasWeaponKillCounter = function() return true end
        LKC.GetBaseKillCounterIdByWeaponId = function() return 2100004 end
        LKC.GetEquipedKillCounterId = function() return 2100004 end
        LKC.GetMyEquipedKillCounterId = function() return 2100004 end
        LKC.GetOneWeaponKillCountInBattle = function(self, uid, wid) return _G.TDFTDeKillCounts[wid] or 0 end
        LKC.GetWeaponKillCountByUid = function(self, uid, wid) return _G.TDFTDeKillCounts[wid] or 0 end
        _G.KCLogicHacked = true
      end
    end
    local KillInfo = package.loaded["GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo"] or _G.GetModule("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
    if KillInfo and KillInfo.__inner_impl and not _G.KillInfoHacked then
      local origFI = KillInfo.__inner_impl.FileItem
      KillInfo.__inner_impl.FileItem = function(self, DRD)
        _G.Safe("killinfo_fi", function()
          if not _G.LexusConfig.KillMessage then return end
          local GD = _G.getCachedGameplayData()
          local LP = GD and GD.GetPlayerCharacter and GD.GetPlayerCharacter()
          if slua.isValid(LP) and DRD.Causer == LP:GetPlayerNameSafety() then
            local cw = LP:GetCurrentWeapon()
            if slua.isValid(cw) then
              local wid = cw:GetWeaponID()
              if not _goldColor then local LC = _G.getCachedLinearColor(); if LC then _goldColor = LC(1.0, 0.8, 0.0, 1.0) end end
              if _goldColor then DRD.IsUseColor, DRD.UseColor = true, _goldColor end
              if DRD.ResultHealthStatus == 2 then
                _G.TDFTDeKillCounts[wid] = (_G.TDFTDeKillCounts[wid] or 0) + 1
                if not _uiMgr then _uiMgr = _G.GetModule("client.slua_ui_framework.manager") end
                if _uiMgr and MM then
                  local ui = _uiMgr.GetUI(_uiMgr.UI_Config_InGame.MainKillCounter)
                  if ui and ui.UpdateWeaponID then
                    local mid = cw:GetWeaponMainAvatarID() or wid
                    ui:UpdateWeaponID(wid, mid)
                    local kc = MM.GetModule(MM.CommonModuleConfig.LogicKillCounter)
                    local kcid = kc:GetEquipedKillCounterId(0, mid)
                    ui:SetKillCounterItemShowWithNum(kcid, _G.TDFTDeKillCounts[wid], mid)
                  end
                end
              end
            end
          end
        end)
        if origFI then return origFI(self, DRD) end
      end
      _G.KillInfoHacked = true
    end
  end)
end

print("[AYUSHKRJ] Part 1/2 loaded — Core + Aggressive Bypass + Config + KillInfo")
-- ====================================================================
-- GocReal — Part 2/2: ESP (RED THEME) + Combat + Menu + Boot
-- ====================================================================
local PlayerMapMarker = {}
PlayerMapMarker.MarkTypeID = 1007
PlayerMapMarker.bUseScreenESP = true
PlayerMapMarker.ESPWorldOffsetZ = 0          -- h=85 already puts us at head, no extra world lift
PlayerMapMarker.ESPAnchorOffsetX = 0         -- centered horizontally
PlayerMapMarker.ESPAnchorOffsetY = -10       -- 10px screen-space up so text sits just above head, not on it
PlayerMapMarker.ESPTextOffsetX = 0
PlayerMapMarker.ESPTextOffsetY = 0
PlayerMapMarker.ESPWidgetAutoSize = true
PlayerMapMarker.ESPWidgetZOrder = 20         -- higher than snaplines (z=1) and skeleton (z=5)
PlayerMapMarker.bShowDistance = true
PlayerMapMarker.HPWidgetSwitcherTypeIndex = 1
PlayerMapMarker.HPWidgetSwitcherType2Index = 1
PlayerMapMarker.bForceSwitcherIndexEveryUpdate = true
PlayerMapMarker.bUseSnapLines = true
PlayerMapMarker.SnapLineThickness = 1.5
PlayerMapMarker.SnapLineTopPercent = 0.06
PlayerMapMarker.SnapLineOriginOffsetX = 0
PlayerMapMarker.SnapLineHeadOffsetX = 0
PlayerMapMarker.SnapLineHeadOffsetY = 0    -- line ends at projected head point, not at label
PlayerMapMarker.SnapLineOpacity = 0.9
PlayerMapMarker.bUseSkeleton = true
PlayerMapMarker.SkeletonThickness = 1.0
PlayerMapMarker.SkeletonOpacity = 0.9
PlayerMapMarker.SkeletonMaxDistance = 100000
PlayerMapMarker.SkeletonWidgets = {}
PlayerMapMarker.SkeletonSmooth = {}
PlayerMapMarker.SkeletonChains = {
  {"neck_01", "upperarm_r", "lowerarm_r", "hand_r"},
  {"neck_01", "upperarm_l", "lowerarm_l", "hand_l"},
  {"head", "neck_01", "pelvis"},
  {"pelvis", "thigh_r", "calf_r", "foot_r"},
  {"pelvis", "thigh_l", "calf_l", "foot_l"}
}
PlayerMapMarker.BoneNameFallbacks = {
  ["head"] = {"head", "Head"},
  ["neck_01"] = {"neck_01", "Neck_01", "neck"},
  ["upperarm_r"] = {"upperarm_r", "UpperArm_R", "arm_r"},
  ["lowerarm_r"] = {"lowerarm_r", "LowerArm_R", "forearm_r"},
  ["hand_r"] = {"hand_r", "Hand_R"},
  ["upperarm_l"] = {"upperarm_l", "UpperArm_L", "arm_l"},
  ["lowerarm_l"] = {"lowerarm_l", "LowerArm_L", "forearm_l"},
  ["hand_l"] = {"hand_l", "Hand_L"},
  ["pelvis"] = {"pelvis", "Pelvis", "hip"},
  ["thigh_r"] = {"thigh_r", "Thigh_R", "leg_r"},
  ["calf_r"] = {"calf_r", "Calf_R", "shin_r"},
  ["foot_r"] = {"foot_r", "Foot_R"},
  ["thigh_l"] = {"thigh_l", "Thigh_L", "leg_l"},
  ["calf_l"] = {"calf_l", "Calf_L", "shin_l"},
  ["foot_l"] = {"foot_l", "Foot_L"},
}
PlayerMapMarker.bActive = false
PlayerMapMarker.ESPWidgets = {}
PlayerMapMarker.ESPWidgetPtrs = {}
PlayerMapMarker.SnapLineWidgets = {}
PlayerMapMarker._cachedViewportW = 1920
PlayerMapMarker._cachedViewportH = 1080
PlayerMapMarker._CanvasScaleX = 1.0
PlayerMapMarker._CanvasScaleY = 1.0
PlayerMapMarker._CanvasOffsetX = 0.0
PlayerMapMarker._CanvasOffsetY = 0.0
PlayerMapMarker._OBHeadWidgetClass = nil
PlayerMapMarker._OBHeadWidgetLoadFailed = false
-- [DEVICE-ADAPTIVE] Base intervals — auto-scaled by DevicePerf system below
PlayerMapMarker._LightUpdateInterval    = 0.033   -- ~30fps light tick baseline
PlayerMapMarker._DistanceUpdateInterval = 0.15    -- distance label update
PlayerMapMarker.nUpdateInterval         = 0.35    -- full scan interval
PlayerMapMarker.bIncludeMe  = false
PlayerMapMarker.bIncludeAI  = true

-- ================================================================
-- DEVICE-ADAPTIVE PERFORMANCE THROTTLE
-- Samples FPS over 3 seconds on boot, then sets update intervals:
--   HIGH  (60+fps)  → intervals as above (full quality)
--   MID   (35-59fps)→ light=0.050, dist=0.25, scan=0.55
--   LOW   (<35fps)  → light=0.075, dist=0.40, scan=0.80
--                     + skeleton disabled by default on LOW
--                     + hitmarker spawn rate capped
-- ================================================================
_G.DevicePerf = _G.DevicePerf or { Tier = "HIGH", FPSSamples = {}, SampleCount = 0, Calibrated = false }

_G.DevicePerf.SampleFPS = function()
  if _G.DevicePerf.Calibrated then return end
  local now = os.clock()
  local last = _G.DevicePerf._LastSample or now
  local dt = now - last
  _G.DevicePerf._LastSample = now
  if dt > 0 and dt < 0.5 then
    local fps = 1.0 / dt
    table.insert(_G.DevicePerf.FPSSamples, fps)
    _G.DevicePerf.SampleCount = _G.DevicePerf.SampleCount + 1
  end
  -- After 60 samples (~3 seconds at 20fps+) determine tier
  if _G.DevicePerf.SampleCount >= 60 then
    local total = 0
    for _, v in ipairs(_G.DevicePerf.FPSSamples) do total = total + v end
    local avg = total / #_G.DevicePerf.FPSSamples
    local tier
    if avg >= 55 then
      tier = "HIGH"
      PlayerMapMarker._LightUpdateInterval    = 0.033
      PlayerMapMarker._DistanceUpdateInterval = 0.15
      PlayerMapMarker.nUpdateInterval         = 0.35
    elseif avg >= 32 then
      tier = "MID"
      PlayerMapMarker._LightUpdateInterval    = 0.050
      PlayerMapMarker._DistanceUpdateInterval = 0.25
      PlayerMapMarker.nUpdateInterval         = 0.55
    else
      tier = "LOW"
      PlayerMapMarker._LightUpdateInterval    = 0.085
      PlayerMapMarker._DistanceUpdateInterval = 0.40
      PlayerMapMarker.nUpdateInterval         = 0.90
      -- Auto-reduce skeleton on low-end to save draw calls
      if not _G._DevicePerfSkeletonAdjusted then
        _G.LexusConfig.Esp9_Skeleton = false
        _G._DevicePerfSkeletonAdjusted = true
      end
    end
    _G.DevicePerf.Tier = tier
    _G.DevicePerf.Calibrated = true
    _G.DevicePerf.AvgFPS = math.floor(avg)
    pcall(function() _G.Notify(string.format("GocReal — Device: %s (~%dfps) | Intervals tuned", tier, math.floor(avg))) end)
  end
end

-- Hook FPS sampler into TickFrame
local _origTickFrame = _G.TickFrame
_G.TickFrame = function()
  if _origTickFrame then _origTickFrame() end
  if not _G.DevicePerf.Calibrated then
    pcall(_G.DevicePerf.SampleFPS)
  end
end

local FVector2D = _G.FVector2D or import("Vector2D")
local FLinearColor = _G.FLinearColor or import("LinearColor")
local FVector = _G.FVector or import("Vector")
local SlateBlueprintLibrary = nil
local WidgetLayoutLibrary = nil
pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary") end)
pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary") end)

function PlayerMapMarker.GetMyPlayerController()
  local GDP = _G.getCachedGameplayData()
  if not GDP then return nil end
  local PC = nil
  pcall(function() PC = GDP.GetPlayerController and GDP.GetPlayerController() end)
  return Valid(PC) and PC or nil
end
function PlayerMapMarker.GetAllCharacters()
  local AllChars = {}
  pcall(function()
    local Pawns = Game:GetAllPlayerPawns()
    if Pawns then
      for _, Pawn in pairs(Pawns) do
        if Valid(Pawn) then
          local pKey = nil
          pcall(function()
            if Pawn.GetPlayerKey then pKey = Pawn:GetPlayerKey()
            elseif Pawn.PlayerKey then pKey = Pawn.PlayerKey
            elseif Pawn.PlayerState and Pawn.PlayerState.PlayerKey then pKey = Pawn.PlayerState.PlayerKey end
          end)
          if pKey then AllChars[pKey] = Pawn end
        end
      end
    end
  end)
  return AllChars
end
function PlayerMapMarker.GetMyPlayerKey()
  local PC = PlayerMapMarker.GetMyPlayerController()
  if not Valid(PC) then return nil end
  local k = nil
  pcall(function()
    if PC.GetPlayerKey then k = PC:GetPlayerKey()
    elseif PC.PlayerState and PC.PlayerState.PlayerKey then k = PC.PlayerState.PlayerKey end
  end)
  return k
end
function PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
  local bMe = false
  pcall(function()
    local GDP = _G.getCachedGameplayData()
    if GDP and GDP.GetLocalCharacter then
      local MyChar = GDP.GetLocalCharacter()
      if MyChar and Character == MyChar then bMe = true; return end
    end
    local PC = PlayerMapMarker.GetMyPlayerController()
    if PC and PC.GetPawn then
      local Pawn = PC:GetPawn()
      if Pawn and Character == Pawn then bMe = true end
    end
  end)
  if not bMe and MyKey and PlayerKey then bMe = (tostring(PlayerKey) == tostring(MyKey)) end
  return bMe
end
function PlayerMapMarker.GetCharacterLocation(Character)
  if not Valid(Character) then return nil end
  local loc = nil
  pcall(function() if Character.K2_GetActorLocation then loc = Character:K2_GetActorLocation() end end)
  return loc
end
function PlayerMapMarker.CalcDistance(l1, l2)
  if not l1 or not l2 then return nil end
  local d = nil
  pcall(function()
    local dx = (l1.X or 0) - (l2.X or 0)
    local dy = (l1.Y or 0) - (l2.Y or 0)
    d = math.sqrt(dx*dx + dy*dy)
  end)
  return d
end
function PlayerMapMarker.GetDistanceString(ml, tl)
  if not PlayerMapMarker.bShowDistance or not ml or not tl then return "" end
  local d = PlayerMapMarker.CalcDistance(ml, tl)
  if not d then return "" end
  local m = d / 100
  if m < 1000 then return string.format("%dm", math.floor(m)) end
  return string.format("%.1fkm", m / 1000)
end
function PlayerMapMarker.GetMyLocation()
  local GDP = _G.getCachedGameplayData()
  if not GDP then return nil end
  local MyChar = nil
  pcall(function() MyChar = GDP.GetLocalCharacter and GDP.GetLocalCharacter() end)
  if not Valid(MyChar) then
    local PC = PlayerMapMarker.GetMyPlayerController()
    if Valid(PC) and PC.GetPawn then
      local Pawn = PC:GetPawn()
      if Valid(Pawn) and Pawn.K2_GetActorLocation then return Pawn:K2_GetActorLocation() end
    end
    return nil
  end
  return PlayerMapMarker.GetCharacterLocation(MyChar)
end
function PlayerMapMarker.GetPlayerName(Character)
  if not Valid(Character) then return "Unknown" end
  local n = nil
  pcall(function() if Character.GetPlayerNameSafety then n = Character:GetPlayerNameSafety() end end)
  if not n then
    pcall(function()
      local PS = nil
      if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety()
      elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
      if Valid(PS) and PS.GetPlayerName then n = PS:GetPlayerName() end
    end)
  end
  return n or "Unknown"
end
function PlayerMapMarker.IsAI(Character)
  local b = false
  pcall(function() if Game and Game.IsAI then b = Game:IsAI(Character) end end)
  return b
end
function PlayerMapMarker.IsAlive(Character)
  local b = true
  pcall(function() if Character.IsAlive then b = Character:IsAlive() end end)
  return b
end
function PlayerMapMarker.GetTeamID(Character)
  if not Valid(Character) then return nil end
  local t = nil
  pcall(function() if Character.GetTeamID then t = Character:GetTeamID() end end)
  if not t then
    pcall(function()
      local PS = nil
      if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety()
      elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
      if Valid(PS) and PS.TeamID then t = PS.TeamID end
    end)
  end
  if not t then pcall(function() if Character.TeamID then t = Character.TeamID end end) end
  return t
end
function PlayerMapMarker.GetTeamColor(TeamID)
  return FLinearColor and FLinearColor(1.0, 0.12, 0.12, 1.0) or {R=255, G=30, B=30, A=255}
end
function PlayerMapMarker.GetCharacterMesh(Character)
  if not Valid(Character) then return nil end
  local m = nil
  pcall(function() if Character.Mesh and Game:IsValid(Character.Mesh) then m = Character.Mesh end end)
  return m
end
function PlayerMapMarker.GetESPLocation(Character)
  if not Valid(Character) then return nil end
  local loc = PlayerMapMarker.GetCharacterLocation(Character)
  if loc then
    local h = 85
    pcall(function()
      if Character.bIsCrouched then h = 60 end
      if Character.IsProne and Character:IsProne() then h = 30 end
    end)
    pcall(function() loc.Z = loc.Z + h + (PlayerMapMarker.ESPWorldOffsetZ or 0) end)
  end
  return loc
end
function PlayerMapMarker.IsOurESPWidget(w)
  if not w or not slua.isValid(w) then return false end
  local isOurs = false
  pcall(function()
    local wstr = tostring(w)
    for _, d in pairs(PlayerMapMarker.ESPWidgets) do
      if d and d.Widget and d.Widget.Container then
        if tostring(d.Widget.Container) == wstr then isOurs = true; return end
      end
    end
  end)
  return isOurs
end
function PlayerMapMarker.InitESPCanvas()
  if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then return true end
  local InGameUITools = nil
  pcall(function() InGameUITools = _G.GetModule("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
  if not InGameUITools then return false end
  local MainUI = nil
  pcall(function() MainUI = InGameUITools.GetMainControlBaseUI() end)
  if not MainUI or not Game:IsValid(MainUI) then return false end
  local canvas = nil
  pcall(function()
    if MainUI.CanvasPanel_0 and Game:IsValid(MainUI.CanvasPanel_0) then canvas = MainUI.CanvasPanel_0
    elseif MainUI.CanvasPanel_42 and Game:IsValid(MainUI.CanvasPanel_42) then canvas = MainUI.CanvasPanel_42 end
  end)
  if not canvas then return false end
  PlayerMapMarker.ESPCanvas = canvas
  pcall(function()
    local n = canvas:GetChildrenCount()
    for i = n - 1, 0, -1 do
      local c = canvas:GetChildAt(i)
      if c and slua.isValid(c) and PlayerMapMarker.IsOurESPWidget(c) then canvas:RemoveChild(c) end
    end
  end)
  return true
end
function PlayerMapMarker.UpdateCanvasTransform(PC)
  if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
  local ok = false
  pcall(function()
    local SBL = SlateBlueprintLibrary
    if SBL and SBL.AbsoluteToLocal then
      local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
      if cg then
        local p0 = SBL.AbsoluteToLocal(cg, FVector2D(0, 0))
        local p1 = SBL.AbsoluteToLocal(cg, FVector2D(100, 100))
        if p0 and p1 then
          PlayerMapMarker._CanvasScaleX = (p1.X - p0.X) / 100
          PlayerMapMarker._CanvasScaleY = (p1.Y - p0.Y) / 100
          PlayerMapMarker._CanvasOffsetX = p0.X
          PlayerMapMarker._CanvasOffsetY = p0.Y
          ok = true
        end
      end
    end
  end)
  if not ok then
    local s = 1.0
    local WLL = WidgetLayoutLibrary
    if WLL and WLL.GetViewportScale then s = WLL.GetViewportScale(PC) or 1.0 end
    PlayerMapMarker._CanvasScaleX = 1.0 / s
    PlayerMapMarker._CanvasScaleY = 1.0 / s
    PlayerMapMarker._CanvasOffsetX = 0
    PlayerMapMarker._CanvasOffsetY = 0
  end
end
function PlayerMapMarker.ScreenPixelToCanvasLocal(PC, sp)
  if not sp then return FVector2D(0, 0) end
  return FVector2D(sp.X * PlayerMapMarker._CanvasScaleX + PlayerMapMarker._CanvasOffsetX,
                    sp.Y * PlayerMapMarker._CanvasScaleY + PlayerMapMarker._CanvasOffsetY)
end
function PlayerMapMarker.ProjectWorldToCanvasLocal(PC, wl)
  if not Valid(PC) or not wl then return false, FVector2D(0, 0) end
  local sp = FVector2D(0, 0)
  local ok = false
  pcall(function()
    local r = PC:ProjectWorldLocationToScreen(wl, sp, true)
    if r == true or r == 1 then ok = true end
  end)
  if not ok or (sp.X == 0 and sp.Y == 0) then return false, FVector2D(0, 0) end
  return true, PlayerMapMarker.ScreenPixelToCanvasLocal(PC, sp)
end
function PlayerMapMarker.GetSnapLineStartPos(PC)
  local screenW, screenH = 0, 0
  pcall(function()
    if PC and PC.GetViewportSize then
      local vs = FVector2D(0, 0)
      PC:GetViewportSize(vs)
      if vs and vs.X and vs.X > 200 then screenW = vs.X; screenH = vs.Y end
    end
  end)
  if screenW <= 200 then
    pcall(function()
      local WLL = WidgetLayoutLibrary
      if WLL and WLL.GetViewportSize then
        local vs = WLL.GetViewportSize(PC)
        if vs and vs.X and vs.X > 200 then screenW = vs.X; screenH = vs.Y end
      end
    end)
  end
  if screenW <= 200 then
    screenW = PlayerMapMarker._cachedViewportW or 1920
    screenH = PlayerMapMarker._cachedViewportH or 1080
  end
  local topPct = PlayerMapMarker.SnapLineTopPercent or 0.06
  if not PlayerMapMarker._CachedTopCenterPixel then PlayerMapMarker._CachedTopCenterPixel = FVector2D(0, 0) end
  PlayerMapMarker._CachedTopCenterPixel.X = screenW * 0.5
  PlayerMapMarker._CachedTopCenterPixel.Y = screenH * topPct
  local cp = PlayerMapMarker.ScreenPixelToCanvasLocal(PC, PlayerMapMarker._CachedTopCenterPixel)
  return cp.X + (PlayerMapMarker.SnapLineOriginOffsetX or 0), cp.Y
end
function PlayerMapMarker._GetWidgetRoot(W)
  if not W or not slua.isValid(W) then return nil end
  local Root = nil
  pcall(function() if W.GetRootWidget then Root = W:GetRootWidget() end end)
  if Root and slua.isValid(Root) then return Root end
  pcall(function() if W.WidgetTree and W.WidgetTree.RootWidget then Root = W.WidgetTree.RootWidget end end)
  if Root and slua.isValid(Root) then return Root end
  return nil
end
function PlayerMapMarker._FindNamedWidgetInTree(W, TargetName, MaxDepth)
  if not W or not slua.isValid(W) then return nil end
  MaxDepth = MaxDepth or 8
  local wname = nil
  pcall(function() if W.GetName then wname = W:GetName() end end)
  if wname and wname == TargetName then return W end
  local n = 0
  pcall(function() if W.GetChildrenCount then n = W:GetChildrenCount() end end)
  if n > 0 then
    for i = 0, n - 1 do
      local c = nil
      pcall(function() c = W:GetChildAt(i) end)
      if c and slua.isValid(c) then
        local found = PlayerMapMarker._FindNamedWidgetInTree(c, TargetName, MaxDepth - 1)
        if found then return found end
      end
    end
  else
    local Root = PlayerMapMarker._GetWidgetRoot(W)
    if Root and slua.isValid(Root) and Root ~= W then
      local found = PlayerMapMarker._FindNamedWidgetInTree(Root, TargetName, MaxDepth - 1)
      if found then return found end
    end
  end
  return nil
end
local _WhiteTexture = nil
local _bWhiteTextureFailed = false
local function GetWhiteTexture()
  if _WhiteTexture then return _WhiteTexture end
  if _bWhiteTextureFailed then return nil end
  pcall(function()
    local paths = { "/Game/BluePrints/UI/Textures/White.White", "/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture" }
    for _, path in ipairs(paths) do
      pcall(function() local tex = import(path); if tex and slua.isValid(tex) then _WhiteTexture = tex end end)
      if _WhiteTexture then break end
    end
  end)
  if not _WhiteTexture then _bWhiteTextureFailed = true end
  return _WhiteTexture
end
local function SetImageColor(Image, color)
  if not Image or not slua.isValid(Image) then return false end
  pcall(function() if Image.SetBrushTintColor then Image:SetBrushTintColor(color) end end)
  pcall(function() if Image.SetColorAndOpacity then Image:SetColorAndOpacity(color) end end)
  pcall(function()
    if Image.SetBrushFromTexture then
      local t = GetWhiteTexture()
      if t then Image:SetBrushFromTexture(t, false); Image:SetColorAndOpacity(color) end
    end
  end)
  pcall(function() Image:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible); Image:SetRenderOpacity(1.0) end)
  return true
end
function PlayerMapMarker.ApplyTeamColor(Widget, TeamID)
  if not Widget or not Widget.Container then return end
  local W = Widget.Container
  if not W or not slua.isValid(W) then return end
  if not Widget._TeamBGRef then
    pcall(function()
      Widget._TeamBGRef = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamBG", 8)
      Widget._TeamLogoBGRef = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamLogoBG", 8)
      Widget._CacheDone = true
    end)
    if not Widget._CacheDone then return end
  end
  if not _G.LexusConfig.Esp9_Team then
    pcall(function()
      if Widget._TeamBGRef and slua.isValid(Widget._TeamBGRef) then Widget._TeamBGRef:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
      if Widget._TeamLogoBGRef and slua.isValid(Widget._TeamLogoBGRef) then Widget._TeamLogoBGRef:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
    end)
    return
  end
  if Widget._LastTeamColor == TeamID then return end
  Widget._LastTeamColor = TeamID
  local color = PlayerMapMarker.GetTeamColor(TeamID)
  if not color then return end
  pcall(function()
    if Widget._TeamBGRef and slua.isValid(Widget._TeamBGRef) then SetImageColor(Widget._TeamBGRef, color) end
    if Widget._TeamLogoBGRef and slua.isValid(Widget._TeamLogoBGRef) then SetImageColor(Widget._TeamLogoBGRef, color) end
  end)
end
function PlayerMapMarker.GetCharacterWeaponInfo(Character)
    if not IsValid(Character) then return nil end
    local WeaponID, WeaponName, WeaponIconPath, WeaponIconTexture, CurrentWeapon = nil, nil, nil, nil, nil

    pcall(function() if Character.GetCurrentWeapon then CurrentWeapon = Character:GetCurrentWeapon() end end)
    if not CurrentWeapon then pcall(function() CurrentWeapon = Character.CurrentWeapon end) end
    if not CurrentWeapon then pcall(function() if Character.GetWeaponManager then local WM = Character:GetWeaponManager() if WM and WM.GetCurrentWeapon then CurrentWeapon = WM:GetCurrentWeapon() end end end) end

    if CurrentWeapon and IsValid(CurrentWeapon) then
        pcall(function() if CurrentWeapon.GetWeaponID then WeaponID = CurrentWeapon:GetWeaponID() end end)
        if not WeaponID then pcall(function() WeaponID = CurrentWeapon.WeaponID end) end
        if not WeaponID then pcall(function() if CurrentWeapon.GetItemID then WeaponID = CurrentWeapon:GetItemID() end end) end
        pcall(function() if CurrentWeapon.GetWeaponName then WeaponName = CurrentWeapon:GetWeaponName() end end)
        pcall(function() if CurrentWeapon.GetWeaponIconPath then WeaponIconPath = CurrentWeapon:GetWeaponIconPath() end end)
        pcall(function() if CurrentWeapon.GetWeaponIcon then WeaponIconTexture = CurrentWeapon:GetWeaponIcon() end end)
    end

    if not WeaponID then
        pcall(function()
            local PS = nil
            if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety() elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
            if PS and IsValid(PS) then
                if PS.GetCurrentWeaponID then WeaponID = PS:GetCurrentWeaponID() end
                if not WeaponID and PS.CurWeaponID then WeaponID = PS.CurWeaponID end
            end
        end)
    end
    return { WeaponID = WeaponID, WeaponName = WeaponName, WeaponIconPath = WeaponIconPath, WeaponIconTexture = WeaponIconTexture, CurrentWeapon = CurrentWeapon }
end

function PlayerMapMarker.FindWeaponIconInWidget(WidgetObj, Depth, MaxDepth)
    if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
    Depth = Depth or 0 ; MaxDepth = MaxDepth or 8
    -- [FIX BUG1] pcall swallows return values — use outer `found` variable
    local propNames = { "Image_Weapon", "Image_WeaponIcon", "Image_Gun", "Image_Icon", "WeaponIcon", "WeaponImage", "Image_Equip" }
    for _, pname in ipairs(propNames) do
        local found = nil
        pcall(function()
            local prop = WidgetObj[pname]
            if prop and slua.isValid(prop) then
                local hasBrush = false
                pcall(function() if prop.Brush then hasBrush = true end end)
                if hasBrush then found = prop end
            end
        end)
        if found then return found end  -- [FIX] return OUTSIDE pcall so it propagates
    end
    if Depth >= MaxDepth then return nil end
    local nChildren = 0
    pcall(function() if WidgetObj.GetChildrenCount then nChildren = WidgetObj:GetChildrenCount() end end)
    for i = 0, math.max(nChildren - 1, 0) do
        local child = nil
        pcall(function() child = WidgetObj:GetChildAt(i) end)
        if child and slua.isValid(child) then
            local result = PlayerMapMarker.FindWeaponIconInWidget(child, Depth + 1, MaxDepth)
            if result then return result end
        end
    end
    if nChildren == 0 then
        local Root = PlayerMapMarker._GetWidgetRoot(WidgetObj)
        if Root and slua.isValid(Root) and Root ~= WidgetObj then
            local result = PlayerMapMarker.FindWeaponIconInWidget(Root, Depth + 1, MaxDepth)
            if result then return result end
        end
    end
    return nil
end

function PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, DefaultW, DefaultH)
    if not ImageWidget or not slua.isValid(ImageWidget) then return end
    DefaultW = DefaultW or 138 ; DefaultH = DefaultH or 69
    pcall(function()
        local brush = ImageWidget.Brush
        if brush then
            brush.ImageSize = FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}
            brush.DrawAs = 3
            brush.TintColor = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
            if ImageWidget.SetBrush then ImageWidget:SetBrush(brush) end
        end
        if ImageWidget.SetDesiredSizeOverride then ImageWidget:SetDesiredSizeOverride(FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}) end
        local slot = ImageWidget.Slot
        if slot and slot.SetSize then slot:SetSize(FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}) end
        ImageWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        ImageWidget:SetRenderOpacity(1.0)
        ImageWidget:SetColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1})
    end)
end

function PlayerMapMarker.ApplyWeaponIconFullOpacity(Container, ourWeaponIcon)
    local fullIcon = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
    if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then return end
    pcall(function() if ourWeaponIcon.SetRenderOpacity then ourWeaponIcon:SetRenderOpacity(1.0) end end)
    pcall(function() if ourWeaponIcon.SetColorAndOpacity then ourWeaponIcon:SetColorAndOpacity(fullIcon) end end)
    pcall(function()
        local brush = ourWeaponIcon.Brush
        if brush then pcall(function() brush.TintColor = fullIcon end) if ourWeaponIcon.SetBrush then ourWeaponIcon:SetBrush(brush) end end
    end)
    local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
    for _, pname in ipairs(chainNames) do
        pcall(function()
            local node = Container and Container[pname]
            if node and slua.isValid(node) and node.SetRenderOpacity then node:SetRenderOpacity(1.0) end
            if node and slua.isValid(node) and node.SetColorAndOpacity then node:SetColorAndOpacity(fullIcon) end
        end)
    end
end

function PlayerMapMarker.ApplyWeaponIconToImage(ImageWidget, winfo)
    if not ImageWidget or not slua.isValid(ImageWidget) then return false, "no_widget" end
    if not winfo or not winfo.WeaponID then return false, "no_weapon_id" end

    local iconPath = nil
    local method = "none"
    local bHasAddKnownMissing = false
    local defaultW = 138
    local defaultH = 69

    -- [FIX BUG5] restructure path resolution — WeaponIconTexture early exit was broken
    -- because `return` inside pcall exits the closure, not ApplyWeaponIconToImage
    local bTextureApplied = false
    pcall(function()
        local itemRecord = CDataTable.GetTableData("Item", winfo.WeaponID)
        if itemRecord and itemRecord.KillWhiteIcon and itemRecord.KillWhiteIcon ~= "" then iconPath = itemRecord.KillWhiteIcon method = "KillWhiteIcon" end
        if (not iconPath or iconPath == "") and winfo.WeaponIconPath and winfo.WeaponIconPath ~= "" then iconPath = winfo.WeaponIconPath method = "WeaponIconPath" end
    end)
    -- WeaponIconTexture: apply separately so early-exit is real
    if (not iconPath or iconPath == "") and winfo.WeaponIconTexture then
        pcall(function()
            if slua.isValid(winfo.WeaponIconTexture) and ImageWidget.SetBrushFromTexture then
                ImageWidget:SetBrushFromTexture(winfo.WeaponIconTexture, true)
                method = "WeaponIconTexture"
                bTextureApplied = true
            end
        end)
    end
    if not bTextureApplied and (not iconPath or iconPath == "") then
        pcall(function()
            local UIUtil = require("client.common.ui_util")
            iconPath, bHasAddKnownMissing = UIUtil.GetItemBigIcon(winfo.WeaponID, ImageWidget)
            if iconPath and iconPath ~= "" then method = "GetItemBigIcon" end
        end)
    end
    if not bTextureApplied and (not iconPath or iconPath == "") then
        pcall(function()
            local UIUtil = require("client.common.ui_util")
            iconPath = UIUtil.GetItemSmallIcon(winfo.WeaponID, ImageWidget, bHasAddKnownMissing)
            if iconPath and iconPath ~= "" then method = "GetItemSmallIcon" end
        end)
    end

    if bTextureApplied then PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, defaultW, defaultH) return true, method end
    if not iconPath or iconPath == "" then return false, "no_path" end

    local bOK = false
    pcall(function()
        if ImageWidget.SetBrushResourceFromPathSync then ImageWidget:SetBrushResourceFromPathSync(iconPath, true) bOK = true end
        if not bOK then
            local util = require("client.slua_ui_framework.util")
            local result = util.SetTexture(ImageWidget, iconPath, { sync = true, bMatchSize = true, bIsInCombatState = true, bHasAddKnownMissing = bHasAddKnownMissing })
            bOK = result ~= nil
        end
        if not bOK then
            local tex = import(iconPath)
            if tex and slua.isValid(tex) and ImageWidget.SetBrushFromTexture then ImageWidget:SetBrushFromTexture(tex, true) bOK = true end
        end
        if not bOK then
            local LoadObject = import("LoadObject")
            if LoadObject then
                local tex = LoadObject(iconPath)
                if tex and slua.isValid(tex) and ImageWidget.SetBrushFromTexture then ImageWidget:SetBrushFromTexture(tex, true) bOK = true end
            end
        end
    end)

    if bOK then PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, defaultW, defaultH) end
    return bOK, method .. ":" .. tostring(iconPath)
end

function PlayerMapMarker.CopyWeaponIconBrushFromNative(ourWeaponIcon, nativeWeaponIcon)
    if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then return false end
    if not nativeWeaponIcon or not slua.isValid(nativeWeaponIcon) then return false end

    local bCopied = false
    pcall(function()
        local nBrush = nativeWeaponIcon.Brush
        if nBrush then
            local resObj = nil
            pcall(function() resObj = nBrush.ResourceObject end)
            if resObj and slua.isValid(resObj) and ourWeaponIcon.SetBrushFromTexture then
                ourWeaponIcon:SetBrushFromTexture(resObj, true)
                bCopied = true
            end
            if bCopied then
                local imgSize = nil
                pcall(function() imgSize = nBrush.ImageSize end)
                if imgSize then
                    local oBrush = ourWeaponIcon.Brush
                    if oBrush then oBrush.ImageSize = imgSize if ourWeaponIcon.SetBrush then ourWeaponIcon:SetBrush(oBrush) end end
                end
            end
        end
    end)
    return bCopied
end

function PlayerMapMarker.AddWeaponIconToESP(WidgetData, Character)
    if not WidgetData or not WidgetData.Container then return end
    local Container = WidgetData.Container
    if not slua.isValid(Container) then return end

    -- [FIX BUG2] throttle: prevent per-frame flood (0.25s cooldown)
    local now = os.clock()
    if WidgetData._LastWepCheck and (now - WidgetData._LastWepCheck) < 0.25 then return end
    WidgetData._LastWepCheck = now

    if not _G.LexusConfig.Esp9_Weapon then
        pcall(function()
            local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
            for _, pname in ipairs(chainNames) do
                local node = Container[pname]
                if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            end
            local ourWeaponIcon = Container.WeaponIcon or PlayerMapMarker.FindWeaponIconInWidget(Container, 0, 8)
            if ourWeaponIcon and slua.isValid(ourWeaponIcon) then ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
        end)
        WidgetData._LastWeaponID = 0
        WidgetData._WeaponIconApplied = false
        return
    end

    -- [FIX BUG3] pull icon lookup outside pcall so nil-guard actually exits function
    local ourWeaponIcon = Container.WeaponIcon
    if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then
        ourWeaponIcon = PlayerMapMarker.FindWeaponIconInWidget(Container, 0, 8)
    end
    if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then
        -- [DIAG] widget has no recognisable weapon-icon slot; skip silently
        return
    end

    pcall(function()
        local winfo = Character and PlayerMapMarker.GetCharacterWeaponInfo(Character) or nil

        if not winfo or not winfo.WeaponID or winfo.WeaponID == 0 then
            pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
            for _, pname in ipairs(chainNames) do
                pcall(function()
                    local node = Container and Container[pname]
                    if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                end)
            end
            WidgetData._LastWeaponID = 0
            WidgetData._WeaponIconApplied = false
            return
        end

        if WidgetData._LastWeaponID == winfo.WeaponID and WidgetData._WeaponIconApplied then
            pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            pcall(function() ourWeaponIcon:SetRenderOpacity(1.0) end)
            local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
            for _, pname in ipairs(chainNames) do
                pcall(function()
                    local node = Container and Container[pname]
                    if node and slua.isValid(node) and node.SetWidgetVisibility then
                        node:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        pcall(function() if node.SetRenderOpacity then node:SetRenderOpacity(1.0) end end)
                    end
                end)
            end
            if WidgetData._CachedSwitcherIndexes then
                for sName, idx in pairs(WidgetData._CachedSwitcherIndexes) do
                    pcall(function()
                        local ws = Container[sName]
                        if ws and slua.isValid(ws) and ws.SetActiveWidgetIndex then ws:SetActiveWidgetIndex(idx) end
                    end)
                end
            end
            if WidgetData._CachedParentSwitchers then
                for _, data in pairs(WidgetData._CachedParentSwitchers) do
                    pcall(function() if data.w and slua.isValid(data.w) and data.w.SetActiveWidgetIndex then data.w:SetActiveWidgetIndex(data.idx) end end)
                end
            end
            return
        end

        local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
        for _, pname in ipairs(chainNames) do
            pcall(function()
                local node = Container and Container[pname]
                if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
            end)
        end

        local bCopied = false
        if winfo and winfo.WeaponID then
            local ok, method = PlayerMapMarker.ApplyWeaponIconToImage(ourWeaponIcon, winfo)
            if ok then bCopied = true end
        end

        local bWeaponIconSet = false
        if Character and winfo then
            if winfo and winfo.WeaponID then
                pcall(function() if Container.SetWeaponIcon then Container:SetWeaponIcon(winfo.WeaponID) bWeaponIconSet = true end end)
                if not bWeaponIconSet then pcall(function() if Container.SetWeaponIconByID then Container:SetWeaponIconByID(winfo.WeaponID) bWeaponIconSet = true end end) end
                if not bWeaponIconSet then pcall(function() if Container.UpdateWeaponIcon then Container:UpdateWeaponIcon(winfo.WeaponID) bWeaponIconSet = true end end) end
                if not bWeaponIconSet then pcall(function() if Container.SetWeaponID then Container:SetWeaponID(winfo.WeaponID) bWeaponIconSet = true end end) end
                pcall(function() if Container.SetData then Container:SetData(Character) end end)
                pcall(function() if Container.SetPlayerInfo then Container:SetPlayerInfo(Character) end end)
                if winfo.CurrentWeapon then pcall(function() if Container.SetCurrentWeapon then Container:SetCurrentWeapon(winfo.CurrentWeapon) end end) end
            end
        end

        if bWeaponIconSet then
            pcall(function()
                local innerIcon = Container.Image_Icon
                if not innerIcon or not slua.isValid(innerIcon) then if Container.CanvasPanel_Type1 then innerIcon = Container.CanvasPanel_Type1.Image_Icon end end
                if not innerIcon or not slua.isValid(innerIcon) then
                    local function findImageIcon(w, depth)
                        if not w or not slua.isValid(w) or depth > 8 then return nil end
                        local prop = w.Image_Icon
                        if prop and slua.isValid(prop) then return prop end
                        local n = 0
                        pcall(function() if w.GetChildrenCount then n = w:GetChildrenCount() end end)
                        for i = 0, math.max(n - 1, 0) do
                            local c = nil
                            pcall(function() c = w:GetChildAt(i) end)
                            if c then local r = findImageIcon(c, depth + 1) if r then return r end end
                        end
                        return nil
                    end
                    innerIcon = findImageIcon(Container, 0)
                end
                if innerIcon and slua.isValid(innerIcon) and innerIcon ~= ourWeaponIcon then
                    pcall(function()
                        local ibrush = innerIcon.Brush
                        if ibrush then
                            local iresObj = nil
                            pcall(function() iresObj = ibrush.ResourceObject end)
                            if iresObj and slua.isValid(iresObj) then
                                if ourWeaponIcon.SetBrushFromAsset then ourWeaponIcon:SetBrushFromAsset(iresObj) bCopied = true end
                                if not bCopied and ourWeaponIcon.SetBrushFromTexture then ourWeaponIcon:SetBrushFromTexture(iresObj) bCopied = true end
                            end
                        end
                    end)
                    if not bCopied then
                        pcall(function()
                            local brush = innerIcon.Brush
                            if brush then
                                local iresObj = nil
                                pcall(function() iresObj = brush.ResourceObject end)
                                if iresObj and slua.isValid(iresObj) and ourWeaponIcon.SetBrushFromTexture then
                                    ourWeaponIcon:SetBrushFromTexture(iresObj, false)
                                    PlayerMapMarker.FixWeaponIconBrushSize(ourWeaponIcon)
                                    bCopied = true
                                end
                            end
                        end)
                    end
                end
            end)
        end

        if not bCopied then
            local nativeWeaponIcon = nil
            if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
                local nChildren = 0
                pcall(function() nChildren = PlayerMapMarker.ESPCanvas:GetChildrenCount() end)
                for i = 0, math.max(nChildren - 1, 0) do
                    local child = nil
                    pcall(function() child = PlayerMapMarker.ESPCanvas:GetChildAt(i) end)
                    if child and slua.isValid(child) then
                        local cstr = tostring(child)
                        if string.find(cstr, "OB_PlayerHeadHPItem") then
                            if not PlayerMapMarker.IsOurESPWidget(child) then
                                local nativeIcon = child.WeaponIcon
                                if nativeIcon and slua.isValid(nativeIcon) then nativeWeaponIcon = nativeIcon break end
                            end
                        end
                    end
                end
            end

            if nativeWeaponIcon and slua.isValid(nativeWeaponIcon) then
                local okNative, nativeMethod = PlayerMapMarker.CopyWeaponIconBrushFromNative(ourWeaponIcon, nativeWeaponIcon)
                if okNative then bCopied = true end
            end
        end

        if not bCopied then
            pcall(function()
                local brush = ourWeaponIcon.Brush
                if brush then
                    local resObj = nil
                    pcall(function() resObj = brush.ResourceObject end)
                    if resObj and slua.isValid(resObj) and ourWeaponIcon.SetBrushFromTexture then
                        ourWeaponIcon:SetBrushFromTexture(resObj)
                        bCopied = true
                    end
                end
            end)
        end

        if not bCopied then
            pcall(function()
                local brush = ourWeaponIcon.Brush
                if brush then
                    local imgSize = nil
                    pcall(function() imgSize = brush.ImageSize end)
                    local bZeroSize = false
                    if imgSize then
                        local sx, sy = nil, nil
                        pcall(function() sx = imgSize.X end)
                        pcall(function() sy = imgSize.Y end)
                        if (not sx or sx == 0) and (not sy or sy == 0) then bZeroSize = true end
                    end
                    if bZeroSize then
                        pcall(function() brush.ImageSize = FVector2D and FVector2D(PlayerMapMarker.WeaponIconBrushW or 138, PlayerMapMarker.WeaponIconBrushH or 69) or {X=138, Y=69} end)
                    end
                    pcall(function() brush.DrawAs = 3 end)
                    if ourWeaponIcon.SetBrush then ourWeaponIcon:SetBrush(brush) end
                end
            end)
        end

        pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        PlayerMapMarker.ApplyWeaponIconFullOpacity(Container, ourWeaponIcon)
        PlayerMapMarker.FixWeaponIconBrushSize(ourWeaponIcon)

        pcall(function()
            local function findWidgetInSwitcher(switcher, targetWidget)
                if not switcher or not slua.isValid(switcher) then return nil end
                if not switcher.GetChildrenCount or not switcher.GetChildAt then return nil end
                local nChildren = switcher:GetChildrenCount()
                for i = 0, math.max(nChildren - 1, 0) do
                    local child = switcher:GetChildAt(i)
                    if child and slua.isValid(child) then
                        if child == targetWidget then return i end
                        local function searchDescendant(w, target, depth)
                            if depth > 5 then return false end
                            if w == target then return true end
                            if not w.GetChildrenCount or not w.GetChildAt then return false end
                            local nc = w:GetChildrenCount()
                            for j = 0, math.max(nc - 1, 0) do
                                local c = w:GetChildAt(j)
                                if c and slua.isValid(c) and searchDescendant(c, target, depth + 1) then return true end
                            end
                            return false
                        end
                        if searchDescendant(child, targetWidget, 0) then return i end
                    end
                end
                return nil
            end

            for _, switcherName in ipairs({"Switcher_WeaponIcon", "WidgetSwitcher_Type", "WidgetSwitcher_Type2"}) do
                local ws = Container[switcherName]
                if ws and slua.isValid(ws) and ws.GetChildrenCount and ws.GetChildAt then
                    local foundIdx = findWidgetInSwitcher(ws, ourWeaponIcon)
                    if foundIdx then
                        if ws.SetActiveWidgetIndex then
                            ws:SetActiveWidgetIndex(foundIdx)
                            WidgetData._CachedSwitcherIndexes = WidgetData._CachedSwitcherIndexes or {}
                            WidgetData._CachedSwitcherIndexes[switcherName] = foundIdx
                        end
                    end
                end
            end
        end)

        pcall(function()
            local parent = ourWeaponIcon
            for depth = 0, 8 do
                if not parent or not slua.isValid(parent) then break end
                if parent.GetParent then
                    local p = parent:GetParent()
                    if p and slua.isValid(p) then
                        local pStr = tostring(p)
                        if string.find(pStr, "WidgetSwitcher") then
                            if p.GetChildrenCount and p.GetChildAt then
                                local nCh = p:GetChildrenCount()
                                for i = 0, math.max(nCh - 1, 0) do
                                    local child = p:GetChildAt(i)
                                    if child and slua.isValid(child) then
                                        local function isDescendant(w, target, d)
                                            if d > 5 then return false end
                                            if w == target then return true end
                                            if not w.GetChildrenCount or not w.GetChildAt then return false end
                                            local nc = w:GetChildrenCount()
                                            for j = 0, math.max(nc - 1, 0) do
                                                local c = w:GetChildAt(j)
                                                if c and slua.isValid(c) and isDescendant(c, target, d + 1) then return true end
                                            end
                                            return false
                                        end
                                        if isDescendant(child, ourWeaponIcon, 0) then
                                            if p.SetActiveWidgetIndex then
                                                p:SetActiveWidgetIndex(i)
                                                WidgetData._CachedParentSwitchers = WidgetData._CachedParentSwitchers or {}
                                                WidgetData._CachedParentSwitchers[tostring(p)] = {w = p, idx = i}
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        parent = p
                    else
                        break
                    end
                else
                    break
                end
            end
        end)

        pcall(function()
            local parent = ourWeaponIcon
            for depth = 0, 8 do
                pcall(function()
                    if parent.GetParent then
                        local p = parent:GetParent()
                        if p and slua.isValid(p) then
                            if p.SetWidgetVisibility then p:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
                            pcall(function() if p.SetRenderOpacity then p:SetRenderOpacity(1.0) end end)
                            pcall(function() if p.SetContentColorAndOpacity then p:SetContentColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                            pcall(function() if p.SetColorAndOpacity then p:SetColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                            pcall(function() if p.SetBrushTintColor then p:SetBrushTintColor(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                            pcall(function()
                                local pBrush = p.Brush
                                if pBrush and pBrush.TintColor then
                                    pBrush.TintColor = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
                                    if p.SetBrush then p:SetBrush(pBrush) end
                                end
                            end)
                            pcall(function() if p.InvalidateLayout then p:InvalidateLayout() end end)
                            parent = p
                        end
                    end
                end)
            end
        end)
        pcall(function() if ourWeaponIcon.InvalidateLayout then ourWeaponIcon:InvalidateLayout() end end)

        pcall(function() if Container.UpdateWeapon then Container:UpdateWeapon() end end)
        pcall(function() if Container.RefreshWeapon then Container:RefreshWeapon() end end)

        WidgetData._LastWeaponID = winfo.WeaponID
        WidgetData._WeaponIconApplied = true
    end)
end

PlayerMapMarker._OBHeadWidgetClass = nil
PlayerMapMarker._OBHeadWidgetLoadFailed = false
PlayerMapMarker._bDumpedWidgetChildren = false

function PlayerMapMarker.FindProgressBarInWidget(W, Depth, MaxDepth)
  if not W or not slua.isValid(W) then return nil end
  Depth = Depth or 0; MaxDepth = MaxDepth or 5
  if Depth > MaxDepth then return nil end
  local isPB = false
  pcall(function() if W.SetPercent and W.SetFillColorAndOpacity then isPB = true end end)
  if isPB then return W end
  local n = 0
  pcall(function() if W.GetChildrenCount then n = W:GetChildrenCount() end end)
  for i = 0, math.max(n - 1, 0) do
    local c = nil
    pcall(function() c = W:GetChildAt(i) end)
    if c and slua.isValid(c) then
      local r = PlayerMapMarker.FindProgressBarInWidget(c, Depth + 1, MaxDepth)
      if r then return r end
    end
  end
  return nil
end
function PlayerMapMarker._StyleHPBar(pb)
  pcall(function()
    pb:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    pb:SetRenderOpacity(1.0)
    pb:SetPercent(1.0)
    pb:SetFillColorAndOpacity(FLinearColor(1.0, 0.10, 0.10, 1.0))
    if pb.SetBarFillType then pb:SetBarFillType(0) end
    local white = GetWhiteTexture()
    if white and pb.WidgetStyle then
      local style = pb.WidgetStyle
      if style.BackgroundImage then
        style.BackgroundImage.ImageSize = FVector2D(100, 12)
        style.BackgroundImage.DrawAs = 3
        style.BackgroundImage.TintColor = FLinearColor(0.14, 0.02, 0.02, 1.0)
        style.BackgroundImage.ResourceObject = white
      end
      if style.FillImage then
        style.FillImage.ImageSize = FVector2D(100, 12)
        style.FillImage.DrawAs = 3
        style.FillImage.TintColor = FLinearColor(1.0, 0.10, 0.10, 1.0)
        style.FillImage.ResourceObject = white
      end
      pb:SetWidgetStyle(style)
    end
  end)
end
function PlayerMapMarker.CreateESPWidget()
  if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
  if PlayerMapMarker._OBHeadWidgetLoadFailed then return nil end
  if not PlayerMapMarker._OBHeadWidgetClass then
    pcall(function()
      local Path = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP"
      local c = slua.loadClass(Path)
      if c then PlayerMapMarker._OBHeadWidgetClass = c end
    end)
    if not PlayerMapMarker._OBHeadWidgetClass then
      PlayerMapMarker._OBHeadWidgetLoadFailed = true
      return nil
    end
  end
  local Widget = nil
  pcall(function()
    local FnLib = import("STExtraBlueprintFunctionLibrary")
    local PC = PlayerMapMarker.GetMyPlayerController()
    local Outer = Valid(PC) and PC.Object or PlayerMapMarker.ESPCanvas
    Widget = FnLib.CreateWidgetByClass(PlayerMapMarker._OBHeadWidgetClass, Outer)
  end)
  if not Widget then return nil end
  pcall(function() Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
  pcall(function() Widget:SetRenderOpacity(1.0) end)

  pcall(function()
    local function hideBG(W, depth)
      if depth > 8 or not W or not slua.isValid(W) then return end
      local n = 0
      pcall(function() if W.GetChildrenCount then n = W:GetChildrenCount() end end)
      for i = 0, n - 1 do
        local c = nil
        pcall(function() c = W:GetChildAt(i) end)
        if c and slua.isValid(c) then
          local wname = nil
          pcall(function() if c.GetName then wname = c:GetName() end end)
          local isImg = false
          pcall(function() if c.Brush then isImg = true end end)
          if isImg and wname and (string.find(wname, "BG") or string.find(wname, "Background") or string.find(wname, "bg")) then
            pcall(function() c:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
          end
          hideBG(c, depth + 1)
        end
      end
    end
    hideBG(Widget, 0)
  end)

  local NameText = nil
  local HealthFill = nil
  local isOrigPB = false
  pcall(function()
    NameText = Widget.TextBlock_TeamName
    local WS = Widget.WidgetSwitcher_Type
    if WS and slua.isValid(WS) then pcall(function() WS:SetActiveWidgetIndex(1) end) end
    local WS2 = Widget.WidgetSwitcher_Type2
    if WS2 and slua.isValid(WS2) then pcall(function() WS2:SetActiveWidgetIndex(1) end) end
    local SB = Widget.SizeBox_HP
    if SB and slua.isValid(SB) then
      SB:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      SB:SetHeightOverride(12)
      SB:SetWidthOverride(100)
      local child = nil
      pcall(function() if SB.GetContent then child = SB:GetContent() end end)
      if not child then pcall(function() if SB.GetChildAt then child = SB:GetChildAt(0) end end) end
      local FoundPB = nil
      if child and slua.isValid(child) then
        FoundPB = PlayerMapMarker.FindProgressBarInWidget(child, 0, 5)
      end
      if FoundPB and slua.isValid(FoundPB) then
        HealthFill = FoundPB
        isOrigPB = true
        PlayerMapMarker._StyleHPBar(FoundPB)
      end
      if not HealthFill then
        local PB = nil
        pcall(function() PB = CGame:NewObjectFromPath("/Script/UMG.ProgressBar", SB) end)
        if PB and slua.isValid(PB) then
          pcall(function() PB:SetDesiredSizeOverride(FVector2D(100, 12)) end)
          PlayerMapMarker._StyleHPBar(PB)
          local used = false
          pcall(function() if SB.SetContent then SB:SetContent(PB); used = true end end)
          if not used then pcall(function() SB:AddChild(PB) end) end
          HealthFill = PB
        end
      end
    end
  end)
  -- [FIX BUG4] pre-unhide WeaponIcon chain so AddWeaponIconToESP can find it
  pcall(function()
    local chainNames = {"Border_WeaponColor","Border_Weapon","Border_WeaponIcon","SizeBox_Weapon","ScaleBox_Weapon","Switcher_WeaponIcon"}
    for _, pname in ipairs(chainNames) do
      local node = Widget[pname]
      if node and slua.isValid(node) and node.SetWidgetVisibility then
        node:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        pcall(function() if node.SetRenderOpacity then node:SetRenderOpacity(1.0) end end)
      end
    end
    local wIcon = Widget.WeaponIcon or PlayerMapMarker.FindWeaponIconInWidget(Widget, 0, 6)
    if wIcon and slua.isValid(wIcon) then
      pcall(function() wIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
      pcall(function() wIcon:SetRenderOpacity(0.0) end)  -- visible in hierarchy, opacity 0 until weapon known
    end
  end)

  return {
    Container = Widget, NameText = NameText, HealthFill = HealthFill,
    IsGameWidget = true, IsOriginalProgressBar = isOrigPB, HasChildren = (NameText ~= nil),
    _SmHP = nil, _LastWepCheck = nil, _LastWeaponID = 0, _WeaponIconApplied = false,
  }
end
function PlayerMapMarker.UpdateESPText(Widget, Text)
  if not Widget then return end
  if Widget._LastESPText == Text then return end
  Widget._LastESPText = Text
  local function apply(w, txt)
    if not w or not slua.isValid(w) then return end
    if txt == "" then w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed); return end
    pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    pcall(function() w:SetText(txt) end)
    pcall(function()
      local FS = import("SlateColor")
      local c = FLinearColor(1.0, 0.12, 0.12, 1.0)
      if FS then w:SetColorAndOpacity(FS(c)) else w:SetColorAndOpacity(c) end
    end)
    pcall(function() if w.SetJustification then w:SetJustification(1) end end)
  end
  if Widget.NameText and slua.isValid(Widget.NameText) then apply(Widget.NameText, Text) end
  if Widget.IsGameWidget and Widget.Container then
    pcall(function()
      local W = Widget.Container
      if W and slua.isValid(W) then
        if W.SetPlayerName then
          local n = Text
          local idx = string.find(Text, " %[")
          if idx then n = string.sub(Text, 1, idx - 1) end
          W:SetPlayerName(n)
        end
        apply(W.TextBlock_TeamName, Text)
        apply(W.TextBlock_PlayerName, Text)
      end
    end)
  end
end
function PlayerMapMarker.UpdateESPHealth(Widget, pct)
  if not Widget then return end
  local bShow = _G.LexusConfig.Esp9_HP
  local pctVal = math.max(0, math.min(1, tonumber(pct) or 0))
  local dt = (_G.FrameDelta and _G.FrameDelta.ClampedDelta) or 0.016
  if Widget.Container then
    pcall(function()
      local W = Widget.Container
      if not W or not slua.isValid(W) then return end
      if W.SizeBox_HP and slua.isValid(W.SizeBox_HP) then
        if bShow then
          W.SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
          W.SizeBox_HP:SetHeightOverride(12)
          W.SizeBox_HP:SetWidthOverride(100)
        else
          W.SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
          Widget._SmHP = nil
          return
        end
      end
      if W.WidgetSwitcher_Type and slua.isValid(W.WidgetSwitcher_Type) then W.WidgetSwitcher_Type:SetActiveWidgetIndex(1) end
      if W.WidgetSwitcher_Type2 and slua.isValid(W.WidgetSwitcher_Type2) then W.WidgetSwitcher_Type2:SetActiveWidgetIndex(1) end
    end)
  end
  if not bShow then return end
  if Widget._SmHP == nil then Widget._SmHP = pctVal end
  Widget._SmHP = _G.LerpSmooth(Widget._SmHP, pctVal, 14, dt)
  local vis = Widget._SmHP
  if Widget.HealthFill and slua.isValid(Widget.HealthFill) then
    pcall(function()
      local pb = Widget.HealthFill
      pb:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      pb:SetRenderOpacity(1.0)
      pb:SetPercent(vis)
      pb:SetFillColorAndOpacity(FLinearColor(1.0, 0.10, 0.10, 1.0))
      if pb.SetBarFillType then pb:SetBarFillType(0) end
      local white = GetWhiteTexture()
      if white and pb.WidgetStyle then
        local style = pb.WidgetStyle
        if style.BackgroundImage then
          style.BackgroundImage.ImageSize = FVector2D(100, 12)
          style.BackgroundImage.DrawAs = 3
          style.BackgroundImage.TintColor = FLinearColor(0.14, 0.02, 0.02, 1.0)
          style.BackgroundImage.ResourceObject = white
        end
        if style.FillImage then
          style.FillImage.ImageSize = FVector2D(100, 12)
          style.FillImage.DrawAs = 3
          style.FillImage.TintColor = FLinearColor(1.0, 0.10, 0.10, 1.0)
          style.FillImage.ResourceObject = white
        end
        pb:SetWidgetStyle(style)
      end
    end)
  end
end
function PlayerMapMarker.UpdateESPPositionWithPC(Widget, WorldLoc, PC, CanvasPos)
  if not Widget or not Valid(PC) then return false end
  local Container = Widget.Container or Widget
  local bOnScreen = true
  if not CanvasPos then
    if not WorldLoc then return false end
    bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLoc)
  end
  if not bOnScreen then
    pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    return false
  end
  pcall(function()
    if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
      local ptr = tostring(Container)
      local Slot = PlayerMapMarker.ESPWidgetPtrs[ptr]
      if not Slot or not slua.isValid(Slot) or type(Slot) == "boolean" then
        local addedSlot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Container)
        if addedSlot and slua.isValid(addedSlot) then
          Slot = addedSlot
          PlayerMapMarker.ESPWidgetPtrs[ptr] = addedSlot
          if type(Widget) == "table" then Widget.Slot = addedSlot end
          pcall(function() Slot:SetAutoSize(true) end)
          pcall(function() Slot:SetZOrder(PlayerMapMarker.ESPWidgetZOrder or 20) end)
        end
      end
      local bShowAny = _G.LexusConfig.Esp9_Name or _G.LexusConfig.Esp9_Distance or _G.LexusConfig.Esp9_HP or _G.LexusConfig.Esp9_Team or _G.LexusConfig.Esp9_Weapon
      if bShowAny then Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      else Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
      if not Widget._OffsetResetDone then
        pcall(function() Container:SetRenderTranslation(FVector2D(0, 0)) end)
        pcall(function() Container:SetRenderScale(FVector2D(0.90, 0.90)) end)
        pcall(function() Container:SetRenderTransformPivot(FVector2D(0.5, 1.0)) end)
        Widget._OffsetResetDone = true
      end
      if Slot and slua.isValid(Slot) and Slot ~= PlayerMapMarker.ESPCanvas then
        local fx = CanvasPos.X + (PlayerMapMarker.ESPAnchorOffsetX or 0)
        local fy = CanvasPos.Y + (PlayerMapMarker.ESPAnchorOffsetY or 0)
        if type(Widget) == "table" then
          if not Widget._SmoothPosX then
            Widget._SmoothPosX = fx; Widget._SmoothPosY = fy
          else
            local dt = _G.FrameDelta.ClampedDelta
            Widget._SmoothPosX = _G.LerpSmooth(Widget._SmoothPosX, fx, 30, dt)
            Widget._SmoothPosY = _G.LerpSmooth(Widget._SmoothPosY, fy, 30, dt)
          end
          if not Widget._PosVec then Widget._PosVec = FVector2D(Widget._SmoothPosX, Widget._SmoothPosY) end
          Widget._PosVec.X = Widget._SmoothPosX; Widget._PosVec.Y = Widget._SmoothPosY
          Slot:SetPosition(Widget._PosVec)
        else
          Slot:SetPosition(FVector2D(fx, fy))
        end
      end
    end
  end)
  return true
end
-- Snapline color constants: OPEN enemy = Lime Green, COVERED = Orange
local SNAP_COLOR_OPEN    = { R=0.20, G=1.0,  B=0.20, A=0.95 }  -- lime green: enemy visible / open
local SNAP_COLOR_COVERED = { R=1.0,  G=0.45, B=0.0,  A=0.90 }  -- orange: enemy behind cover

-- True occlusion: LineOfSightTo when available; falls back to on-screen only
function PlayerMapMarker.IsEnemyOccluded(Character, PC, bOnScreen)
  if not bOnScreen then return true end
  if not Valid(Character) or not Valid(PC) then return false end
  local occluded = false
  pcall(function()
    if Character.bIsOccluded ~= nil then
      occluded = Character.bIsOccluded and true or false
      return
    end
    local FV = _G.FVector or import("Vector")
    local zeroV = FV and FV(0, 0, 0) or {X=0, Y=0, Z=0}
    if type(PC.LineOfSightTo) == "function" then
      local vis = PC:LineOfSightTo(Character, zeroV, true)
      occluded = not (vis == true or vis == 1)
    end
  end)
  return occluded
end
function PlayerMapMarker.CreateSnapLine()
  if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
  local B = nil
  pcall(function() B = CGame:NewObjectFromPath("/Script/UMG.Border", PlayerMapMarker.ESPCanvas) end)
  if not B or not slua.isValid(B) then return nil end
  pcall(function()
    local LC = _G.getCachedLinearColor and _G.getCachedLinearColor()
    local c = LC and LC(SNAP_COLOR_OPEN.R, SNAP_COLOR_OPEN.G, SNAP_COLOR_OPEN.B, SNAP_COLOR_OPEN.A) or SNAP_COLOR_OPEN
    B:SetBrushColor(c)
  end)
  pcall(function() B:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
  pcall(function() B:SetRenderOpacity(1.0) end)
  pcall(function() B:SetRenderTransformPivot(FVector2D(0, 0.5)) end)
  local Slot = nil
  pcall(function()
    Slot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(B)
    if Slot then
      Slot:SetAutoSize(false)
      Slot:SetZOrder(1)
      Slot:SetAlignment(FVector2D(0, 0.5))
    end
  end)
  return { Widget = B, Slot = Slot, _lastColorOpen = true, _canvas = PlayerMapMarker.ESPCanvas }
end
-- UpdateSnapLine: Lime Green = open, Orange = cover; survives canvas refresh; max 600m
function PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY, distM, bEnemyOccluded)
  if not PlayerMapMarker.bUseSnapLines then
    local LD0 = PlayerMapMarker.SnapLineWidgets[KeyStr]
    if LD0 and LD0.Widget and slua.isValid(LD0.Widget) then
      pcall(function() LD0.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    end
    return
  end
  if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
  -- Hard 600m range cap — collapse only, never destroy (prevents flicker / auto-remove)
  if distM and distM > 600 then
    local LD2 = PlayerMapMarker.SnapLineWidgets[KeyStr]
    if LD2 and LD2.Widget and slua.isValid(LD2.Widget) then
      pcall(function() LD2.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    end
    return
  end
  local LD = PlayerMapMarker.SnapLineWidgets[KeyStr]
  -- Recreate if missing or parent canvas was replaced (common cause of "auto remove")
  if LD and LD.Widget and slua.isValid(LD.Widget) and LD._canvas and LD._canvas ~= PlayerMapMarker.ESPCanvas then
    pcall(function() LD.Widget:RemoveFromParent() end)
    LD = nil
    PlayerMapMarker.SnapLineWidgets[KeyStr] = nil
  end
  if not LD or not LD.Widget or not slua.isValid(LD.Widget) or not LD.Slot or not slua.isValid(LD.Slot) then
    LD = PlayerMapMarker.CreateSnapLine()
    if not LD or not LD.Widget or not LD.Slot then return end
    PlayerMapMarker.SnapLineWidgets[KeyStr] = LD
  end
  if not bOnScreen or not CanvasPos then
    pcall(function() LD.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    return
  end
  -- Color every tick so Lime Green / Orange always stick
  local isOpen = not bEnemyOccluded
  local LC = _G.getCachedLinearColor and _G.getCachedLinearColor()
  local col = isOpen and SNAP_COLOR_OPEN or SNAP_COLOR_COVERED
  pcall(function()
    local c = LC and LC(col.R, col.G, col.B, col.A) or col
    LD.Widget:SetBrushColor(c)
  end)
  LD._lastColorOpen = isOpen
  pcall(function() LD.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
  pcall(function() LD.Widget:SetRenderOpacity(1.0) end)
  local toX = CanvasPos.X + (PlayerMapMarker.SnapLineHeadOffsetX or 0)
  local toY = CanvasPos.Y + (PlayerMapMarker.SnapLineHeadOffsetY or 0)
  -- ASHI-style direct position (minimal lag); light blend only on large jumps
  if not LD._SX then LD._SX = fromX; LD._SY = fromY; LD._TX = toX; LD._TY = toY end
  local jump = math.abs(fromX - LD._SX) + math.abs(fromY - LD._SY) + math.abs(toX - LD._TX) + math.abs(toY - LD._TY)
  if jump > 80 then
    LD._SX, LD._SY, LD._TX, LD._TY = fromX, fromY, toX, toY
  else
    local dt = (_G.FrameDelta and _G.FrameDelta.ClampedDelta) or 0.016
    LD._SX = _G.LerpSmooth(LD._SX, fromX, 55, dt)
    LD._SY = _G.LerpSmooth(LD._SY, fromY, 55, dt)
    LD._TX = _G.LerpSmooth(LD._TX, toX, 45, dt)
    LD._TY = _G.LerpSmooth(LD._TY, toY, 45, dt)
  end
  local dx = LD._TX - LD._SX
  local dy = LD._TY - LD._SY
  local len = math.sqrt(dx*dx + dy*dy)
  if len < 1 then return end
  local thick = PlayerMapMarker.SnapLineThickness or 1.5
  local angle = (_G.atan2(dy, dx)) * 57.29577951308232
  pcall(function()
    if LD.Slot and slua.isValid(LD.Slot) then
      LD.Slot:SetPosition(FVector2D(LD._SX, LD._SY))
      LD.Slot:SetSize(FVector2D(len, thick))
      LD.Slot:SetAlignment(FVector2D(0, 0.5))
    end
    if LD.Widget.SetRenderTransformAngle then
      LD.Widget:SetRenderTransformAngle(angle)
    elseif LD.Widget.SetRenderAngle then
      LD.Widget:SetRenderAngle(angle)
    end
  end)
end
function PlayerMapMarker.RemoveSnapLine(KeyStr)
  local LD = PlayerMapMarker.SnapLineWidgets[KeyStr]
  if LD and LD.Widget and slua.isValid(LD.Widget) then
    pcall(function() LD.Widget:RemoveFromParent(); LD.Widget:ConditionalBeginDestroy() end)
  end
  PlayerMapMarker.SnapLineWidgets[KeyStr] = nil
end
function PlayerMapMarker.ClearAllSnapLines()
  for _, LD in pairs(PlayerMapMarker.SnapLineWidgets) do
    if LD and LD.Widget and slua.isValid(LD.Widget) then
      pcall(function() LD.Widget:RemoveFromParent(); LD.Widget:ConditionalBeginDestroy() end)
    end
  end
  PlayerMapMarker.SnapLineWidgets = {}
end
-- [FIX] Skeleton toggle: destroy all skeleton line widgets immediately when toggled off
function PlayerMapMarker.ClearAllSkeletonLines()
  for KeyStr, Bones in pairs(PlayerMapMarker.SkeletonWidgets) do
    if Bones then
      for _, LD in ipairs(Bones) do
        if LD and LD.Widget and slua.isValid(LD.Widget) then
          pcall(function() LD.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
          pcall(function() LD.Widget:RemoveFromParent() end)
        end
      end
    end
  end
  PlayerMapMarker.SkeletonWidgets = {}
  PlayerMapMarker.SkeletonSmooth = {}
end
function PlayerMapMarker.GetBoneLocationWithFallback(Character, PrimaryBoneName)
  if not Valid(Character) or not PrimaryBoneName then return nil end
  local fb = PlayerMapMarker.BoneNameFallbacks[PrimaryBoneName] or {PrimaryBoneName}
  local Mesh = PlayerMapMarker.GetCharacterMesh(Character)
  if not Mesh or not Game:IsValid(Mesh) then return nil end
  for _, bn in ipairs(fb) do
    local loc = nil
    pcall(function()
      if Mesh.GetSocketLocation then loc = Mesh:GetSocketLocation(bn)
      elseif Mesh.GetBoneLocation then loc = Mesh:GetBoneLocation(bn) end
    end)
    if loc then return loc end
  end
  return nil
end
function PlayerMapMarker.CreateSkeletonLineWidget()
  if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
  local B = nil
  pcall(function() B = CGame:NewObjectFromPath("/Script/UMG.Border", PlayerMapMarker.ESPCanvas) end)
  if not B or not slua.isValid(B) then return nil end
  pcall(function() B:SetBrushColor(FLinearColor(0, 1, 0, PlayerMapMarker.SkeletonOpacity or 0.9)) end)
  pcall(function() B:SetRenderTransformPivot(FVector2D(0, 0.5)) end)
  local Slot = nil
  pcall(function()
    Slot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(B)
    if Slot then Slot:SetAutoSize(false); Slot:SetZOrder(5) end
  end)
  return { Widget = B, Slot = Slot, posVec = FVector2D(0,0), sizeVec = FVector2D(0,0) }
end
function PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, bVisible, TeamColor, bPlayerOnScreen, charLoc)
  if not PlayerMapMarker.bUseSkeleton then return end
  if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
  local Bones = PlayerMapMarker.SkeletonWidgets[KeyStr]
  if not bVisible or not Valid(Character) or not Valid(PC) then
    if Bones then
      for _, LD in ipairs(Bones) do
        if LD and LD.Widget and slua.isValid(LD.Widget) then LD.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
      end
    end
    PlayerMapMarker.SkeletonSmooth[KeyStr] = nil
    return
  end
  if not charLoc then charLoc = PlayerMapMarker.GetESPLocation(Character) end
  if not charLoc then return end
  if not Bones then Bones = {}; PlayerMapMarker.SkeletonWidgets[KeyStr] = Bones end
  local lineColor = FLinearColor(0, 1, 0, PlayerMapMarker.SkeletonOpacity or 0.9)
  local dt = (_G.FrameDelta and _G.FrameDelta.ClampedDelta) or 0.016
  local SmoothedBones = PlayerMapMarker.SkeletonSmooth[KeyStr] or {}
  PlayerMapMarker.SkeletonSmooth[KeyStr] = SmoothedBones
  local cache = PlayerMapMarker._StaticBoneLocCache or {}
  PlayerMapMarker._StaticBoneLocCache = cache
  for k in pairs(cache) do cache[k] = nil end
  local lineIndex = 0
  local thick = PlayerMapMarker.SkeletonThickness or 1.0
  for _, chain in ipairs(PlayerMapMarker.SkeletonChains) do
    local lastX, lastY = nil, nil
    for _, boneName in ipairs(chain) do
      local boneWorld = cache[boneName]
      if boneWorld == nil then
        boneWorld = PlayerMapMarker.GetBoneLocationWithFallback(Character, boneName) or false
        cache[boneName] = boneWorld
      end
      if boneWorld == false then boneWorld = nil end
      local cx, cy = nil, nil
      if boneWorld then
        local ok, pos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, boneWorld)
        if ok then cx = pos.X; cy = pos.Y end
      end
      if lastX and cx then
        lineIndex = lineIndex + 1
        local LD = Bones[lineIndex]
        if not LD or not LD.Widget or not slua.isValid(LD.Widget) then
          LD = PlayerMapMarker.CreateSkeletonLineWidget()
          if LD then Bones[lineIndex] = LD end
        end
        if LD and LD.Widget and LD.Slot then
          local smKey = boneName .. "_" .. tostring(lineIndex)
          local prev = SmoothedBones[smKey]
          local smFromX, smFromY, smToX, smToY
          if prev then
            smFromX = _G.LerpSmooth(prev.fx, lastX, 35, dt)
            smFromY = _G.LerpSmooth(prev.fy, lastY, 35, dt)
            smToX = _G.LerpSmooth(prev.tx, cx, 35, dt)
            smToY = _G.LerpSmooth(prev.ty, cy, 35, dt)
          else
            smFromX, smFromY, smToX, smToY = lastX, lastY, cx, cy
          end
          SmoothedBones[smKey] = { fx = smFromX, fy = smFromY, tx = smToX, ty = smToY }
          if LD._Color ~= lineColor then LD.Widget:SetBrushColor(lineColor); LD._Color = lineColor end
          LD.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
          local dx = smToX - smFromX
          local dy = smToY - smFromY
          local len = math.sqrt(dx*dx + dy*dy)
          local ang = (_G.atan2(dy, dx)) * 57.29577951308232
          LD.posVec.X = smFromX; LD.posVec.Y = smFromY - thick/2.0
          LD.sizeVec.X = len; LD.sizeVec.Y = thick
          LD.Slot:SetPosition(LD.posVec)
          LD.Slot:SetSize(LD.sizeVec)
          LD.Widget:SetRenderAngle(ang)
        end
      end
      lastX = cx; lastY = cy
    end
  end
  for i = lineIndex + 1, #Bones do
    local LD = Bones[i]
    if LD and LD.Widget and slua.isValid(LD.Widget) then LD.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
  end
end
function PlayerMapMarker.RemoveSkeletonLines(KeyStr)
  local B = PlayerMapMarker.SkeletonWidgets[KeyStr]
  if B then
    for _, LD in ipairs(B) do
      if LD and LD.Widget and slua.isValid(LD.Widget) then
        pcall(function() LD.Widget:RemoveFromParent(); LD.Widget:ConditionalBeginDestroy() end)
      end
    end
    PlayerMapMarker.SkeletonWidgets[KeyStr] = nil
  end
  PlayerMapMarker.SkeletonSmooth[KeyStr] = nil
end
function PlayerMapMarker.RemoveESPWidget(Widget, KeyStr)
  if not Widget then return end
  local C = Widget.Container or Widget
  pcall(function()
    PlayerMapMarker.ESPWidgetPtrs[tostring(C)] = nil
    C:RemoveFromParent()
    C:ConditionalBeginDestroy()
  end)
  if KeyStr then
    PlayerMapMarker.RemoveSnapLine(KeyStr)
    PlayerMapMarker.RemoveSkeletonLines(KeyStr)
  end
end
function PlayerMapMarker.ClearAllESP()
  for k, d in pairs(PlayerMapMarker.ESPWidgets) do PlayerMapMarker.RemoveESPWidget(d.Widget, k) end
  PlayerMapMarker.ESPWidgets = {}
  PlayerMapMarker.ESPWidgetPtrs = {}
  PlayerMapMarker.ClearAllSnapLines()
  PlayerMapMarker.ClearAllSkeletonLines()
  if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
    pcall(function()
      local n = PlayerMapMarker.ESPCanvas:GetChildrenCount()
      for i = n - 1, 0, -1 do
        local c = PlayerMapMarker.ESPCanvas:GetChildAt(i)
        if c and slua.isValid(c) and PlayerMapMarker.IsOurESPWidget(c) then PlayerMapMarker.ESPCanvas:RemoveChild(c) end
      end
    end)
  end
  PlayerMapMarker.ESPCanvas = nil
  PlayerMapMarker._OBHeadWidgetClass = nil
  PlayerMapMarker._OBHeadWidgetLoadFailed = false
  PlayerMapMarker._cachedViewportW = 1920
  PlayerMapMarker._cachedViewportH = 1080
end
function PlayerMapMarker.UpdateESP(AllPlayers, MyLoc)
  if not PlayerMapMarker.bUseScreenESP then return end
  local newSnapState = _G.LexusConfig.Esp9_Line
  if PlayerMapMarker._lastSnapState ~= nil and PlayerMapMarker._lastSnapState ~= newSnapState then
    if not newSnapState then PlayerMapMarker.ClearAllSnapLines() end
  end
  PlayerMapMarker._lastSnapState = newSnapState
  PlayerMapMarker.bUseSnapLines = newSnapState
  local newSkelState = _G.LexusConfig.Esp9_Skeleton
  -- Skeleton toggle fix: clear all skeleton widgets on toggle-off so they don't ghost
  if PlayerMapMarker._lastSkeletonState ~= nil and PlayerMapMarker._lastSkeletonState ~= newSkelState then
    if not newSkelState then
      PlayerMapMarker.ClearAllSkeletonLines()
    end
  end
  PlayerMapMarker._lastSkeletonState = newSkelState
  PlayerMapMarker.bUseSkeleton = newSkelState
  if not PlayerMapMarker.InitESPCanvas() then return end
  if PlayerMapMarker._OBHeadWidgetLoadFailed then return end
  local PC = PlayerMapMarker.GetMyPlayerController()
  if Valid(PC) then PlayerMapMarker.UpdateCanvasTransform(PC) end
  local fromX, fromY = 0, 0
  if PlayerMapMarker.bUseSnapLines and Valid(PC) then fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC) end
  local MyKey = PlayerMapMarker.GetMyPlayerKey()
  local Seen = {}
  local MyChar = nil
  pcall(function()
    local GDP = _G.getCachedGameplayData()
    if GDP and GDP.GetLocalCharacter then MyChar = GDP.GetLocalCharacter()
    elseif PC and PC.GetPawn then MyChar = PC:GetPawn() end
  end)
  local MyTeamID = PlayerMapMarker.GetTeamID(MyChar)
  for PlayerKey, Character in pairs(AllPlayers) do
    if Valid(Character) then
      local bMe = PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
      local bAI = PlayerMapMarker.IsAI(Character)
      local KeyStr = tostring(PlayerKey)
      local Name = PlayerMapMarker.GetPlayerName(Character)
      local Loc = PlayerMapMarker.GetESPLocation(Character)
      local DistStr = ""
      if MyLoc and Loc then DistStr = PlayerMapMarker.GetDistanceString(MyLoc, Loc) end
      local bSkip = false
      if bMe and not PlayerMapMarker.bIncludeMe then bSkip = true end
      if bAI and not PlayerMapMarker.bIncludeAI then bSkip = true end
      local TeamID = PlayerMapMarker.GetTeamID(Character)
      if MyTeamID ~= nil and TeamID == MyTeamID and not bMe then bSkip = true end
      local bAlive = PlayerMapMarker.IsAlive(Character)
      if not bSkip and Loc then
        Seen[KeyStr] = true
        local ESPData = PlayerMapMarker.ESPWidgets[KeyStr]
        local Text = ""
        if _G.LexusConfig.Esp9_Name then Text = Name end
        if _G.LexusConfig.Esp9_Distance and DistStr ~= "" then
          if Text ~= "" then Text = string.format("%s [%s]", Text, DistStr) else Text = string.format("[%s]", DistStr) end
        end
        local bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, Loc)
        -- Compute real distM for snapline 600m cap
        local distM = 9999
        if MyLoc and Loc then
          pcall(function()
            local dx = Loc.X - MyLoc.X; local dy = Loc.Y - MyLoc.Y; local dz = Loc.Z - MyLoc.Z
            distM = math.sqrt(dx*dx + dy*dy + dz*dz) / 100
          end)
        end
        local bOccluded = PlayerMapMarker.IsEnemyOccluded(Character, PC, bOnScreen)
        if not ESPData then
          local W = PlayerMapMarker.CreateESPWidget()
          if W then
            PlayerMapMarker.ESPWidgets[KeyStr] = { Widget = W, Character = Character, Name = Name, LastDistStr = DistStr, TeamID = TeamID, IsBot = bAI }
            PlayerMapMarker.UpdateESPText(W, Text, bAI)
            if bAlive then
              PlayerMapMarker.UpdateESPPositionWithPC(W, Loc, PC, CanvasPos)
              PlayerMapMarker.ApplyTeamColor(W, TeamID)
              PlayerMapMarker.AddWeaponIconToESP(W, Character)
              local HP = Character.Health or 0
              local MaxHP = Character.MaxHealth or 120
              local pct = (HP > 0 and MaxHP > 0) and math.min(1, HP / MaxHP) or 0
              PlayerMapMarker.UpdateESPHealth(W, pct)
              if PlayerMapMarker.bUseSnapLines then PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY, distM, bOccluded)
              else PlayerMapMarker.RemoveSnapLine(KeyStr) end
              if PlayerMapMarker.bUseSkeleton then PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, true, PlayerMapMarker.GetTeamColor(TeamID), bOnScreen, Loc)
              else PlayerMapMarker.RemoveSkeletonLines(KeyStr) end
            else
              local C = W.Container or W
              pcall(function() C:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
              PlayerMapMarker.RemoveSnapLine(KeyStr)
              PlayerMapMarker.RemoveSkeletonLines(KeyStr)
            end
          end
        else
          ESPData.Character = Character
          ESPData.Name = Name
          ESPData.LastDistStr = DistStr
          ESPData.IsBot = bAI
          if bAlive then
            ESPData.TeamID = TeamID
            ESPData.Widget._LastESPText = nil
            PlayerMapMarker.UpdateESPText(ESPData.Widget, Text, bAI)
            PlayerMapMarker.UpdateESPPositionWithPC(ESPData.Widget, Loc, PC, CanvasPos)
            PlayerMapMarker.ApplyTeamColor(ESPData.Widget, TeamID)
            PlayerMapMarker.AddWeaponIconToESP(ESPData.Widget, Character)
            local HP = Character.Health or 0
            local MaxHP = Character.MaxHealth or 120
            local pct = (HP > 0 and MaxHP > 0) and math.min(1, HP / MaxHP) or 0
            PlayerMapMarker.UpdateESPHealth(ESPData.Widget, pct)
            if PlayerMapMarker.bUseSnapLines then PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY, distM, bOccluded)
            else PlayerMapMarker.RemoveSnapLine(KeyStr) end
            if PlayerMapMarker.bUseSkeleton then PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, true, PlayerMapMarker.GetTeamColor(TeamID), bOnScreen, Loc)
            else PlayerMapMarker.RemoveSkeletonLines(KeyStr) end
          else
            local C = ESPData.Widget.Container or ESPData.Widget
            pcall(function() C:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            PlayerMapMarker.RemoveSnapLine(KeyStr)
            PlayerMapMarker.RemoveSkeletonLines(KeyStr)
          end
        end
      end
    end
  end
  for KeyStr, Data in pairs(PlayerMapMarker.ESPWidgets) do
    if not Seen[KeyStr] then
      PlayerMapMarker.RemoveESPWidget(Data.Widget, KeyStr)
      PlayerMapMarker.ESPWidgets[KeyStr] = nil
    end
  end
end
function PlayerMapMarker.UpdateESPLight()
  if _G.TickFrame then _G.TickFrame() end
  if not PlayerMapMarker.bUseScreenESP then return end
  PlayerMapMarker.bUseSnapLines = _G.LexusConfig.Esp9_Line
  local newSkelStateL = _G.LexusConfig.Esp9_Skeleton
  if PlayerMapMarker._lastSkeletonState ~= nil and PlayerMapMarker._lastSkeletonState ~= newSkelStateL then
    if not newSkelStateL then PlayerMapMarker.ClearAllSkeletonLines() end
  end
  PlayerMapMarker._lastSkeletonState = newSkelStateL
  PlayerMapMarker.bUseSkeleton = newSkelStateL
  if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
  local PC = PlayerMapMarker.GetMyPlayerController()
  if not Valid(PC) then return end
  PlayerMapMarker.UpdateCanvasTransform(PC)
  local fromX, fromY = 0, 0
  if PlayerMapMarker.bUseSnapLines then fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC) end
  for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
    local W = ESPData.Widget
    local C = W and (W.Container or W)
    if W and C and slua.isValid(C) and ESPData.Character and Valid(ESPData.Character) then
      if not PlayerMapMarker.IsAlive(ESPData.Character) then
        C:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        PlayerMapMarker.RemoveSnapLine(KeyStr)
        PlayerMapMarker.RemoveSkeletonLines(KeyStr)
      else
        local bShow = _G.LexusConfig.Esp9_Name or _G.LexusConfig.Esp9_Distance or _G.LexusConfig.Esp9_HP or _G.LexusConfig.Esp9_Team or _G.LexusConfig.Esp9_Weapon
        if bShow then C:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        else C:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
        local Loc = PlayerMapMarker.GetESPLocation(ESPData.Character)
        if Loc then
          local bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, Loc)
          PlayerMapMarker.UpdateESPPositionWithPC(W, Loc, PC, CanvasPos)
          -- distM for 600m cap in snapline
          local distMLt = 9999
          pcall(function()
            local ml = PlayerMapMarker.GetMyLocation()
            if ml then
              local dx=Loc.X-ml.X; local dy=Loc.Y-ml.Y; local dz=Loc.Z-ml.Z
              distMLt = math.sqrt(dx*dx+dy*dy+dz*dz)/100
            end
          end)
          local bOccLt = PlayerMapMarker.IsEnemyOccluded(ESPData.Character, PC, bOnScreen)
          if PlayerMapMarker.bUseSnapLines then PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY, distMLt, bOccLt)
          else PlayerMapMarker.RemoveSnapLine(KeyStr) end
          if PlayerMapMarker.bUseSkeleton then
            PlayerMapMarker.UpdateSkeletonLines(KeyStr, ESPData.Character, PC, true, PlayerMapMarker.GetTeamColor(ESPData.TeamID), bOnScreen, Loc)
          else PlayerMapMarker.RemoveSkeletonLines(KeyStr) end
        end
      end
    end
  end
end
function PlayerMapMarker.UpdateESPDistances()
  if _G.TickFrame then _G.TickFrame() end
  if not PlayerMapMarker.bUseScreenESP then return end
  local MyLoc = PlayerMapMarker.GetMyLocation()
  if not MyLoc then return end
  local PC = PlayerMapMarker.GetMyPlayerController()
  if not Valid(PC) then return end
  PlayerMapMarker.UpdateCanvasTransform(PC)
  for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
    local C = ESPData.Widget and ESPData.Widget.Container
    if ESPData.Character and Valid(ESPData.Character) and C and slua.isValid(C) then
      local Loc = PlayerMapMarker.GetESPLocation(ESPData.Character)
      if Loc and PlayerMapMarker.bShowDistance then
        local DistStr = PlayerMapMarker.GetDistanceString(MyLoc, Loc)
        local Name = ESPData.Name or "Unknown"
        local Text = ""
        if _G.LexusConfig.Esp9_Name then Text = Name end
        if _G.LexusConfig.Esp9_Distance and DistStr ~= "" then
          if Text ~= "" then Text = string.format("%s [%s]", Text, DistStr) else Text = string.format("[%s]", DistStr) end
        end
        ESPData.LastDistStr = DistStr
        ESPData.Widget._LastESPText = nil
        PlayerMapMarker.UpdateESPText(ESPData.Widget, Text)
      end
    end
  end
end
function PlayerMapMarker.ScanAndUpdate()
  local AllChars = PlayerMapMarker.GetAllCharacters()
  if not AllChars then return 0 end
  local MyLoc = PlayerMapMarker.GetMyLocation()
  if PlayerMapMarker.bUseScreenESP then PlayerMapMarker.UpdateESP(AllChars, MyLoc) end
  return 0
end
function PlayerMapMarker.AttachTimers()
  pcall(function()
    local pc = PlayerMapMarker.GetMyPlayerController()
    if not slua.isValid(pc) or not pc.AddGameTimer then return end
    local now = os.time()
    if PlayerMapMarker._LastAttach and (now - PlayerMapMarker._LastAttach) < 5 then return end
    PlayerMapMarker._LastAttach = now
    pcall(function() pc:AddGameTimer(PlayerMapMarker.nUpdateInterval or 0.35, true, function() if PlayerMapMarker.bActive then pcall(PlayerMapMarker.ScanAndUpdate) end end) end)
    pcall(function() pc:AddGameTimer(PlayerMapMarker._LightUpdateInterval or 0.033, true, function() if PlayerMapMarker.bActive then pcall(PlayerMapMarker.UpdateESPLight) end end) end)
    pcall(function() pc:AddGameTimer(PlayerMapMarker._DistanceUpdateInterval or 0.15, true, function() if PlayerMapMarker.bActive and PlayerMapMarker.bShowDistance then pcall(PlayerMapMarker.UpdateESPDistances) end end) end)
  end)
end
function PlayerMapMarker.Start()
  if PlayerMapMarker.bActive then return end
  PlayerMapMarker.bActive = true
  PlayerMapMarker.ScanAndUpdate()
  PlayerMapMarker.AttachTimers()
end
function PlayerMapMarker.Stop()
  PlayerMapMarker.bActive = false
  PlayerMapMarker.ClearAllESP()
end
_G.PlayerMapMarker = PlayerMapMarker

local RedBoxOverlay = {
  bActive = false, MainContainer = nil, WidgetSlot = nil,
  TextBlockPlayer = nil, TextBlockBot = nil,
  Width = 260, Height = 28, FontSize = 14,
  PlayerCount = 0, BotCount = 0, NumLayers = 50,
  Red = 1.0, Green = 0.0, Blue = 0.0, LayerAlpha = 0.038
}
function RedBoxOverlay.Create()
  if RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then return true end
  local ParentCanvas = PlayerMapMarker.ESPCanvas
  if not ParentCanvas or not slua.isValid(ParentCanvas) then
    if not PlayerMapMarker.InitESPCanvas() then return false end
    ParentCanvas = PlayerMapMarker.ESPCanvas
  end
  if not ParentCanvas then return false end
  local C = nil
  pcall(function() C = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", ParentCanvas) end)
  if not C or not slua.isValid(C) then return false end
  local color = FLinearColor(RedBoxOverlay.Red, RedBoxOverlay.Green, RedBoxOverlay.Blue, RedBoxOverlay.LayerAlpha)
  for i = 1, RedBoxOverlay.NumLayers do
    local prog = (i / RedBoxOverlay.NumLayers) ^ 1.15
    local lw = prog * RedBoxOverlay.Width
    local lx = (RedBoxOverlay.Width - lw) / 2.0
    local B = nil
    pcall(function() B = CGame:NewObjectFromPath("/Script/UMG.Border", C) end)
    if B and slua.isValid(B) then
      pcall(function() B:SetBrushColor(color); B:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
      local s = C:AddChildToCanvas(B)
      if s then s:SetPosition(FVector2D(lx, 0)); s:SetSize(FVector2D(lw, RedBoxOverlay.Height)) end
    end
  end
  local FS = import("SlateColor")
  local function mkText(x, y, init)
    local T = nil
    pcall(function() T = CGame:NewObjectFromPath("/Script/UMG.TextBlock", C) end)
    if not T or not slua.isValid(T) then return nil end
    pcall(function()
      T:SetText(init)
      local wc = FLinearColor(1,1,1,1)
      if FS then T:SetColorAndOpacity(FS(wc)) else T:SetColorAndOpacity(wc) end
      if T.Font then local f = T.Font; f.Size = RedBoxOverlay.FontSize; T.Font = f end
      T:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
    local s = C:AddChildToCanvas(T)
    if s then
      pcall(function()
        s:SetAutoSize(true); s:SetAlignment(FVector2D(0.5, 0.5))
        s:SetPosition(FVector2D(x, y)); s:SetZOrder(1000)
      end)
    end
    return T
  end
  RedBoxOverlay.TextBlockPlayer = mkText(RedBoxOverlay.Width * 0.35, RedBoxOverlay.Height * 0.5, "Player: 0")
  RedBoxOverlay.TextBlockBot = mkText(RedBoxOverlay.Width * 0.65, RedBoxOverlay.Height * 0.5, "Bot: 0")
  local slot = nil
  pcall(function() slot = ParentCanvas:AddChildToCanvas(C) end)
  if not slot then return false end
  RedBoxOverlay.MainContainer = C
  RedBoxOverlay.WidgetSlot = slot
  pcall(function()
    slot:SetAutoSize(false); slot:SetZOrder(999)
    slot:SetAlignment(FVector2D(0.5, 1.0))
    slot:SetSize(FVector2D(RedBoxOverlay.Width, RedBoxOverlay.Height))
  end)
  RedBoxOverlay.UpdatePosition()
  return true
end
function RedBoxOverlay.SetCounts(players, bots)
  if RedBoxOverlay.PlayerCount == players and RedBoxOverlay.BotCount == bots then return end
  RedBoxOverlay.PlayerCount = players or 0
  RedBoxOverlay.BotCount = bots or 0
  if RedBoxOverlay.TextBlockPlayer and slua.isValid(RedBoxOverlay.TextBlockPlayer) then
    pcall(function() RedBoxOverlay.TextBlockPlayer:SetText(string.format("Player: %d", RedBoxOverlay.PlayerCount)) end)
  end
  if RedBoxOverlay.TextBlockBot and slua.isValid(RedBoxOverlay.TextBlockBot) then
    pcall(function() RedBoxOverlay.TextBlockBot:SetText(string.format("Bot: %d", RedBoxOverlay.BotCount)) end)
  end
end
function RedBoxOverlay.UpdatePosition()
  local slot = RedBoxOverlay.WidgetSlot
  if not slot or not slua.isValid(slot) then return end
  local PC = PlayerMapMarker.GetMyPlayerController()
  if not Valid(PC) then return end
  local fx, fy = PlayerMapMarker.GetSnapLineStartPos(PC)
  pcall(function() slot:SetPosition(FVector2D(fx, fy + 2)) end)
end
function RedBoxOverlay.Start()
  if RedBoxOverlay.bActive and RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then return end
  if RedBoxOverlay.Create() then
    RedBoxOverlay.bActive = true
    pcall(function() RedBoxOverlay.MainContainer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
  end
end
function RedBoxOverlay.Stop()
  RedBoxOverlay.bActive = false
  if RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then
    pcall(function()
      RedBoxOverlay.MainContainer:RemoveFromParent()
      RedBoxOverlay.MainContainer:ConditionalBeginDestroy()
    end)
  end
  RedBoxOverlay.MainContainer = nil
  RedBoxOverlay.WidgetSlot = nil
  RedBoxOverlay.TextBlockPlayer = nil
  RedBoxOverlay.TextBlockBot = nil
end
_G.RedBoxOverlay = RedBoxOverlay

local function ApplyColorBodyNew(enemy, markData)
  _G.Safe("chams_apply", function()
    if not _G.ConsoleNewWallReady then
      local KSL = import("KismetSystemLibrary")
      local world = slua.getWorld()
      if KSL and world then
        KSL.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
        KSL.ExecuteConsoleCommand(world, "r.CustomDepth 3")
        KSL.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
        KSL.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
        _G.ConsoleNewWallReady = true
      end
    end
    local meshes = _G.GetAllSkeletalMeshes(enemy, markData)
    local w = nil
    pcall(function() w = enemy:GetCurrentWeapon() end)
    if Valid(w) and Valid(w.Mesh) then table.insert(meshes, w.Mesh) end
    local isBot = markData.AK_IS_BOT or false
    local hash = (isBot and "BOT" or "PL") .. "_" .. tostring(#meshes)
    if markData.LastChamsHash == hash and markData.ChamsApplied then return end
    markData.LastChamsHash = hash
    markData.ChamsApplied = true
    local LC = _G.getCachedLinearColor()
    local c_vis = LC and LC(0, 100, 0, 1) or {R=0,G=100,B=0,A=1}
    local c_occ = LC and LC(100, 0, 0, 1) or {R=100,G=0,B=0,A=1}
    local c_bVis = LC and LC(49, 48, 0, 100) or {R=49,G=48,B=0,A=100}
    local c_bOcc = LC and LC(9, 1.5, 45, 100) or {R=9,G=1.5,B=45,A=100}
    local vis = isBot and c_bVis or c_vis
    local occ = isBot and c_bOcc or c_occ
    for _, m in ipairs(meshes) do
      if Valid(m) then
        pcall(function()
          if type(m.SetDrawDyeing) == "function" then
            m:SetDrawDyeing(true); m:SetDrawDyeingMode(1)
            m:SetVisibleDyeingColor(vis); m:SetOccludedDyeingColor(occ)
            m:SetDyeingColorFadeDistance(99999.0); m:SetDyeingColorMinMaxDistance(0.0, 99999.0)
            m:SetDrawHighlight(true); m:OverrideHighlightColor(vis); m:SetHighlightCanBeOccluded(false)
            m:SetDrawIdeaOutline(true); m:SetIdeaOutlineNew(true); m:SetIdeaOutlineOcclusionHighlight(true)
            m:OverrideIdeaOutlineColor(vis); m:SetIdeaOutlineOcclusionColor(occ)
            m:OverrideIdeaOutlineThickness(20.0); m:SetIdeaOverrideOutlineAndOcclusion(true)
            m:SetRenderCustomDepth(true); m:SetCustomDepthStencilValue(255)
          end
        end)
      end
    end
  end)
end
local function UndoColorBodyNew(enemy, markData)
  _G.Safe("chams_undo", function()
    if markData.ChamsApplied then
      local meshes = _G.GetAllSkeletalMeshes(enemy, markData)
      local w = nil
      pcall(function() w = enemy:GetCurrentWeapon() end)
      if Valid(w) and Valid(w.Mesh) then table.insert(meshes, w.Mesh) end
      for _, m in ipairs(meshes) do
        if Valid(m) then
          pcall(function()
            if type(m.SetDrawDyeing) == "function" then
              m:SetDrawDyeing(false); m:SetDrawHighlight(false); m:SetDrawIdeaOutline(false); m:SetRenderCustomDepth(false)
            end
          end)
        end
      end
      markData.ChamsApplied = false
      markData.LastChamsHash = ""
    end
  end)
end

_G.Cached_MyHUD = nil
local function EnsureHUD()
  if Valid(_G.Cached_MyHUD) then return _G.Cached_MyHUD end
  pcall(function()
    local GD = _G.getCachedGameplayData()
    if GD then
      local hud = GD.GetMyHUD and GD.GetMyHUD()
      if Valid(hud) then _G.Cached_MyHUD = hud end
    end
  end)
  return _G.Cached_MyHUD
end

local function ApplyHUDText(enemy, markData, distM, localPlayer)
  local HUD = EnsureHUD()
  if not Valid(HUD) then return end
  if _G.LexusConfig.EspAntenna and distM <= 400 then
    -- [FIX] Old Z offsets were 1105–8105cm (11–81m) — way off screen at normal ranges
    -- New offsets: 215–985cm (2.1–9.8m) above player head — visible and correct
    local antennaColor = _G.C_GREEN or {R=0,G=1,B=0,A=1}  -- [FIX] fallback if C_GREEN nil
    for i = 1, 8 do
      local z = 105 + (i * 110)  -- [FIX] was i*1000, now i*110: spans ~2m to ~10m above head
      HUD:AddDebugText("|", enemy, 0.06, {X=0,Y=0,Z=z}, {X=0,Y=0,Z=z}, antennaColor, true, false, true, nil, 1.2, true)
    end
    HUD:AddDebugText("I", enemy, 0.06, {X=0,Y=0,Z=995}, {X=0,Y=0,Z=995}, antennaColor, true, false, true, nil, 1.5, true)
  end
  if _G.LexusConfig.EspDistance and distM <= 400 then
    local sc = math.max(0.55, 0.95 - (distM / 400))
    HUD:AddDebugText(string.format("[%dm]", math.floor(distM)), enemy, 0.06, {X=0,Y=115,Z=20}, {X=0,Y=115,Z=20}, _G.C_RED_TEXT, true, false, true, nil, sc * 1.5, true)
  end
  if _G.LexusConfig.EspVipPro and distM <= 400 then
    local sc = math.max(0.55, 0.95 - (distM / 400))
    local hp, mhp = 100, 100
    pcall(function()
      if enemy.Health then hp = enemy.Health end
      if enemy.HealthMax then mhp = enemy.HealthMax end
    end)
    if mhp <= 0 then mhp = 100 end
    local ratio = hp / mhp
    local isKnock = (hp <= 0 and enemy.HealthStatus == 1)
    local hpCol = isKnock and _G.C_RED or _G.C_RED_TEXT
    local name = "Enemy"
    pcall(function() if enemy.PlayerName then name = enemy.PlayerName end end)
    if isKnock then name = "KNOCK: " .. name end
    HUD:AddDebugText(name, enemy, 0.06, {X=0,Y=0,Z=-370}, {X=0,Y=0,Z=-370}, _G.C_RED_TEXT, true, false, true, nil, sc * 1.1, true)
    if not isKnock then
      local seg = 6
      local filled = math.floor(ratio * seg)
      local startZ = 20
      local spacing = 10.0 * sc
      for j = 1, seg do
        local c = (j <= filled) and hpCol or {R=40,G=4,B=4,A=180}
        HUD:AddDebugText("▮", enemy, 0.06, {X=0,Y=-115,Z=startZ + (j*spacing)}, {X=0,Y=-115,Z=startZ + (j*spacing)}, c, true, false, true, nil, sc * 1.2, true)
      end
      HUD:AddDebugText(string.format("%d%%", math.floor(ratio * 100)), enemy, 0.06, {X=0,Y=-60,Z=startZ - 12}, {X=0,Y=-60,Z=startZ - 12}, hpCol, true, false, true, nil, sc * 0.8, true)
    else
      HUD:AddDebugText("DOWN", enemy, 0.06, {X=0,Y=-115,Z=50}, {X=0,Y=-115,Z=50}, _G.C_RED, true, false, true, nil, sc, true)
    end
  end
end


-- Weapon glow defaults in CustomTextData
pcall(function()
  _G.LexusState = _G.LexusState or {}
  _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
  local CT = _G.LexusState.CustomTextData
  if CT.WeaponGlowThickness == nil then CT.WeaponGlowThickness = 3 end
  if CT.WeaponGlowColor == nil then CT.WeaponGlowColor = 5 end
end)

function _G.InitializeNativeESP()
  if _G.LexusState.NativeESPReady then return end
  _G.Safe("native_esp", function()
    local GPT = _G.GetModule("GameLua.Mod.BaseMod.Common.GamePlayTools")
    if not GPT then return end
    local cfg = GPT.GetCurrentConfig("ScreenMarkConfig")
    if not cfg then return end
    if cfg[1006] then
      cfg[1006].bBindBlocked = true; cfg[1006].bBindOutScreen = true
      cfg[1006].MaxWidgetNum = 99; cfg[1006].MaxShowDistance = 6000000
      cfg[1006].bScaleByDistance = false; cfg[1006].BindSocketName = "root"
      cfg[1006].bUseLuaWorldSocketName = true; cfg[1006].WorldPositionOffset = FVector(0, 0, -30)
    end
  end)
  _G.LexusState.NativeESPReady = true
end

function _G.ProcessEnemyESP(enemy, markData, localPlayer, distM)
  _G.Safe("enemy_esp", function()
    local dead = false
    pcall(function()
      if type(enemy.IsDead) == "function" then dead = enemy:IsDead()
      elseif enemy.bIsDead ~= nil then dead = enemy.bIsDead end
      if enemy.HealthStatus == 2 then dead = true end
    end)
    if dead then
      UndoColorBodyNew(enemy, markData)
      markData.Cleaned = true
      return
    end
    if markData.Cleaned then markData.Cleaned = false end
    if _G.LexusConfig.ColorBodyNew then ApplyColorBodyNew(enemy, markData)
    else UndoColorBodyNew(enemy, markData) end

    ApplyHUDText(enemy, markData, distM, localPlayer)
  end)
end

function _G.StartESP()
  if _G.PlayerMapMarker and not _G.PlayerMapMarker.bActive then _G.PlayerMapMarker.Start() end
end
function _G.StopESP()
  if _G.PlayerMapMarker and _G.PlayerMapMarker.bActive then _G.PlayerMapMarker.Stop() end
  if _G.RedBoxOverlay and _G.RedBoxOverlay.bActive then _G.RedBoxOverlay.Stop() end
end
function _G.UpdateRedBox(realPlayers, bots)
  if _G.LexusConfig.Esp9_Count then
    if _G.RedBoxOverlay.bActive then _G.RedBoxOverlay.SetCounts(realPlayers, bots)
    else _G.RedBoxOverlay.Start() end
  else
    if _G.RedBoxOverlay.bActive then _G.RedBoxOverlay.Stop() end
  end
end

-- ====================================================================
-- [GocReal MODIFICATIONS — ALL FEATURES] by INDIAN_ROHIT_YT
-- ====================================================================

-- ── AIMBOT: SMOOTH LERP + FOV CONTROL ─────────────────────────────
_G.AimbotSmoothFactor = _G.AimbotSmoothFactor or 0.18   -- 0.0=instant snap, 1.0=very slow
_G.AimbotFOVRadius   = _G.AimbotFOVRadius   or 120.0    -- screen pixels radius for target lock
_G.AimbotBoneTarget  = _G.AimbotBoneTarget  or "head"   -- "head" | "neck_01" | "pelvis"

_G.ApplyAimbot = function()
  _G.Safe("aimbot_smooth", function()
    if not _G.LexusConfig.AimbotEnabled then return end
    local GD = _G.getCachedGameplayData()
    if not GD then return end
    local pc = GD.GetPlayerController and GD.GetPlayerController()
    if not Valid(pc) then return end
    local lp = pc:GetPlayerCharacterSafety()
    if not Valid(lp) then return end

    local bestEnemy = nil
    local bestDist  = math.huge

    -- Find closest enemy within FOV circle
    for key, md in pairs(_G.LexusState.EnemyMarks or {}) do
      local e = md.enemy
      if not Valid(e) then goto continue end
      local dead = false
      pcall(function()
        if type(e.IsDead) == "function" then dead = e:IsDead()
        elseif e.bIsDead ~= nil then dead = e.bIsDead end
        if e.HealthStatus == 2 then dead = true end
      end)
      if dead then goto continue end

      -- Project bone to screen
      local boneLoc = nil
      pcall(function()
        local mesh = e.Mesh
        if mesh and Game:IsValid(mesh) then
          local fb = PlayerMapMarker.BoneNameFallbacks[_G.AimbotBoneTarget] or {_G.AimbotBoneTarget}
          for _, bn in ipairs(fb) do
            pcall(function()
              if mesh.GetSocketLocation then boneLoc = mesh:GetSocketLocation(bn)
              elseif mesh.GetBoneLocation then boneLoc = mesh:GetBoneLocation(bn) end
            end)
            if boneLoc then break end
          end
        end
      end)
      if not boneLoc then goto continue end

      local sp = FVector2D(0, 0)
      local onScreen = false
      pcall(function()
        local r = pc:ProjectWorldLocationToScreen(boneLoc, sp, true)
        if r == true or r == 1 then onScreen = true end
      end)
      if not onScreen then goto continue end

      -- Screen center distance = FOV check
      local sw, sh = 1920, 1080
      pcall(function()
        local vs = FVector2D(0,0); pc:GetViewportSize(vs)
        if vs.X > 200 then sw = vs.X; sh = vs.Y end
      end)
      local cx, cy = sw * 0.5, sh * 0.5
      local dx, dy = sp.X - cx, sp.Y - cy
      local screenDist = math.sqrt(dx*dx + dy*dy)

      if screenDist <= _G.AimbotFOVRadius and screenDist < bestDist then
        bestDist  = screenDist
        bestEnemy = { loc = boneLoc, sp = sp }
      end
      ::continue::
    end

    if not bestEnemy then return end

    -- Smooth aim toward target
    local targetLoc = bestEnemy.loc
    local currentRot = nil
    pcall(function() if pc.GetControlRotation then currentRot = pc:GetControlRotation() end end)
    if not currentRot then return end

    local aimRot = nil
    pcall(function()
      local myLoc = nil
      local lpawn = pc:GetPawn()
      if Valid(lpawn) and lpawn.K2_GetActorLocation then myLoc = lpawn:K2_GetActorLocation() end
      if not myLoc then return end
      local dx3 = targetLoc.X - myLoc.X
      local dy3 = targetLoc.Y - myLoc.Y
      local dz3 = targetLoc.Z - myLoc.Z
      local hd  = math.sqrt(dx3*dx3 + dy3*dy3)
      local yaw   = math.atan(dy3, dx3) * 57.2958
      local pitch = -math.atan(dz3, hd)  * 57.2958
      aimRot = { Pitch = pitch, Yaw = yaw, Roll = 0 }
    end)
    if not aimRot then return end

    -- Lerp smooth
    local sf   = math.max(0.0, math.min(1.0, _G.AimbotSmoothFactor))
    local dt   = (_G.FrameDelta and _G.FrameDelta.ClampedDelta) or 0.016
    local speed = (1.0 - sf) * (1.0 / math.max(dt, 0.001)) * 8.0
    local newPitch = _G.LerpSmooth(currentRot.Pitch, aimRot.Pitch, speed, dt)
    local newYaw   = _G.LerpSmooth(currentRot.Yaw,   aimRot.Yaw,   speed, dt)

    pcall(function()
      if pc.SetControlRotation then pc:SetControlRotation(FRotator(newPitch, newYaw, 0)) end
    end)
  end)
end

-- ── ESP COLOR CUSTOMIZER ───────────────────────────────────────────
-- LexusConfig.EspColorMode: "red"(default) | "white" | "green" | "yellow"
_G.GetESPColorByMode = function(isBot)
  local mode = (_G.LexusConfig.EspColorMode or "red"):lower()
  if isBot then
    -- Bots always get a distinct dim yellow
    return FLinearColor(0.8, 0.7, 0.0, 1.0)
  end
  if mode == "white"  then return FLinearColor(1.0, 1.0, 1.0, 1.0) end
  if mode == "green"  then return FLinearColor(0.0, 1.0, 0.1, 1.0) end
  if mode == "yellow" then return FLinearColor(1.0, 0.9, 0.0, 1.0) end
  -- default red
  return FLinearColor(1.0, 0.12, 0.12, 1.0)
end

-- Patch UpdateESPText to use dynamic color
local _origUpdateESPText = PlayerMapMarker.UpdateESPText
function PlayerMapMarker.UpdateESPText(Widget, Text, isBot)
  if not Widget then return end
  if Widget._LastESPText == Text and Widget._LastESPIsBot == isBot then return end
  Widget._LastESPText   = Text
  Widget._LastESPIsBot  = isBot
  local col = _G.GetESPColorByMode(isBot or false)
  local function apply(w, txt)
    if not w or not slua.isValid(w) then return end
    if txt == "" then w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed); return end
    pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    pcall(function() w:SetText(txt) end)
    pcall(function()
      local FS = import("SlateColor")
      if FS then w:SetColorAndOpacity(FS(col)) else w:SetColorAndOpacity(col) end
    end)
    pcall(function() if w.SetJustification then w:SetJustification(1) end end)
  end
  if Widget.NameText and slua.isValid(Widget.NameText) then apply(Widget.NameText, Text) end
  if Widget.IsGameWidget and Widget.Container then
    pcall(function()
      local W = Widget.Container
      if W and slua.isValid(W) then
        if W.SetPlayerName then
          local n = Text
          local idx = string.find(Text, " %[")
          if idx then n = string.sub(Text, 1, idx - 1) end
          W:SetPlayerName(n)
        end
        apply(W.TextBlock_TeamName, Text)
        apply(W.TextBlock_PlayerName, Text)
      end
    end)
  end
end

-- ── SPEED HACK ────────────────────────────────────────────────────
-- LexusConfig.SpeedHackEnabled = true/false
-- LexusConfig.SpeedMultiplier  = 1.5  (1.0=normal, 2.0=2x speed)
_G.ApplySpeedHack = function()
  _G.Safe("speed_hack", function()
    if not _G.LexusConfig.SpeedHackEnabled then return end
    local GD = _G.getCachedGameplayData()
    if not GD then return end
    local pc = GD.GetPlayerController and GD.GetPlayerController()
    if not Valid(pc) then return end
    local lp = pc:GetPlayerCharacterSafety()
    if not Valid(lp) then return end
    local mv = lp.STCharacterMovement or lp.CharacterMovement
    if not Valid(mv) then return end
    local mult = tonumber(_G.LexusConfig.SpeedMultiplier) or 1.5
    mult = math.max(1.0, math.min(5.0, mult))
    pcall(function()
      if mv.MaxWalkSpeed then mv.MaxWalkSpeed = 600.0 * mult end
      if mv.MaxRunSpeed  then mv.MaxRunSpeed  = 800.0 * mult end
      if mv.MaxSprintSpeed then mv.MaxSprintSpeed = 1000.0 * mult end
    end)
  end)
end

-- ── RADAR / MINIMAP ESP (2D screen overlay) ────────────────────────
-- LexusConfig.RadarEnabled = true/false
_G.RadarOverlay = _G.RadarOverlay or {
  bActive = false, Container = nil, Slot = nil, Dots = {},
  Size = 160, Scale = 0.04,  -- Scale: world-units per radar pixel
  OffsetX = -90, OffsetY = 90,  -- from top-right corner
}

_G.ApplyRadar = function()
  _G.Safe("radar", function()
    if not _G.LexusConfig.RadarEnabled then
      if _G.RadarOverlay.Container and slua.isValid(_G.RadarOverlay.Container) then
        pcall(function() _G.RadarOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
      end
      return
    end
    if not PlayerMapMarker.InitESPCanvas() then return end
    local canvas = PlayerMapMarker.ESPCanvas
    if not canvas or not Game:IsValid(canvas) then return end

    -- Create container once
    if not _G.RadarOverlay.Container or not slua.isValid(_G.RadarOverlay.Container) then
      local C = nil
      pcall(function() C = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
      if not C or not slua.isValid(C) then return end
      -- Background circle
      local BG = nil
      pcall(function() BG = CGame:NewObjectFromPath("/Script/UMG.Border", C) end)
      if BG and slua.isValid(BG) then
        pcall(function()
          BG:SetBrushColor(FLinearColor(0, 0, 0, 0.45))
          BG:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
          local s = C:AddChildToCanvas(BG)
          if s then
            s:SetPosition(FVector2D(0, 0))
            s:SetSize(FVector2D(_G.RadarOverlay.Size, _G.RadarOverlay.Size))
            s:SetZOrder(0)
          end
        end)
      end
      local slot = nil
      pcall(function() slot = canvas:AddChildToCanvas(C) end)
      if not slot then return end
      _G.RadarOverlay.Container = C
      _G.RadarOverlay.Slot = slot
      pcall(function()
        slot:SetAutoSize(false)
        slot:SetSize(FVector2D(_G.RadarOverlay.Size, _G.RadarOverlay.Size))
        slot:SetZOrder(500)
        slot:SetAlignment(FVector2D(1.0, 0.0))  -- top-right anchor
      end)
    end

    -- Reposition
    pcall(function()
      local PC = PlayerMapMarker.GetMyPlayerController()
      if not Valid(PC) then return end
      local sw, sh = 1920, 1080
      local vs = FVector2D(0,0)
      pcall(function() PC:GetViewportSize(vs); if vs.X > 200 then sw = vs.X; sh = vs.Y end end)
      local sx = PlayerMapMarker._CanvasScaleX or 1.0
      local sy = PlayerMapMarker._CanvasScaleY or 1.0
      local rx = (sw + _G.RadarOverlay.OffsetX) * sx
      local ry = (-_G.RadarOverlay.OffsetY) * sy
      _G.RadarOverlay.Slot:SetPosition(FVector2D(rx, ry))
    end)
    pcall(function() _G.RadarOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)

    -- Draw dots
    local GD = _G.getCachedGameplayData()
    if not GD then return end
    local pc = GD.GetPlayerController and GD.GetPlayerController()
    if not Valid(pc) then return end
    local lp = pc:GetPlayerCharacterSafety()
    if not Valid(lp) then return end
    local myLoc = nil
    pcall(function() if lp.K2_GetActorLocation then myLoc = lp:K2_GetActorLocation() end end)
    if not myLoc then return end

    local myYaw = 0
    pcall(function()
      local rot = pc:GetControlRotation()
      if rot then myYaw = rot.Yaw end
    end)
    local sinY = math.sin(-myYaw * 0.01745329)
    local cosY = math.cos(-myYaw * 0.01745329)

    local dotIdx = 0
    local center = _G.RadarOverlay.Size * 0.5
    local scale  = _G.RadarOverlay.Scale
    local C = _G.RadarOverlay.Container

    for _, md in pairs(_G.LexusState.EnemyMarks or {}) do
      local e = md.enemy
      if not Valid(e) then goto rdot_continue end
      local eLoc = nil
      pcall(function() if e.K2_GetActorLocation then eLoc = e:K2_GetActorLocation() end end)
      if not eLoc then goto rdot_continue end

      local wx = (eLoc.X - myLoc.X) * scale
      local wy = (eLoc.Y - myLoc.Y) * scale
      -- Rotate relative to player yaw
      local rx2 = wx * cosY - wy * sinY
      local ry2 = wx * sinY + wy * cosY

      local px = center + rx2
      local py = center + ry2
      if px < 4 or px > _G.RadarOverlay.Size - 4 or py < 4 or py > _G.RadarOverlay.Size - 4 then goto rdot_continue end

      dotIdx = dotIdx + 1
      local dot = _G.RadarOverlay.Dots[dotIdx]
      if not dot or not slua.isValid(dot) then
        local D = nil
        pcall(function() D = CGame:NewObjectFromPath("/Script/UMG.Border", C) end)
        if D and slua.isValid(D) then
          pcall(function()
            D:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            local s = C:AddChildToCanvas(D)
            if s then s:SetSize(FVector2D(5,5)); s:SetZOrder(10) end
          end)
          _G.RadarOverlay.Dots[dotIdx] = D
          dot = D
        end
      end
      if dot and slua.isValid(dot) then
        local isBot = md.AK_IS_BOT or false
        local dotCol = isBot and FLinearColor(0.8, 0.7, 0.0, 0.9) or FLinearColor(1.0, 0.1, 0.1, 0.9)
        pcall(function()
          dot:SetBrushColor(dotCol)
          dot:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
          local s = PlayerMapMarker.ESPWidgetPtrs[tostring(dot)]
          if not s then
            s = C:AddChildToCanvas(dot)
            PlayerMapMarker.ESPWidgetPtrs[tostring(dot)] = s or true
          end
          if s and slua.isValid(s) then s:SetPosition(FVector2D(px - 2.5, py - 2.5)) end
        end)
      end
      ::rdot_continue::
    end
    -- Hide extra dots
    for i = dotIdx + 1, #_G.RadarOverlay.Dots do
      local dot = _G.RadarOverlay.Dots[i]
      if dot and slua.isValid(dot) then
        pcall(function() dot:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
      end
    end
  end)
end

-- ── AUTO LOOT ─────────────────────────────────────────────────────
-- LexusConfig.AutoLootEnabled = true/false
-- LexusConfig.AutoLootRadius  = 8.0  (meters)
_G.ApplyAutoLoot = function()
  _G.Safe("auto_loot", function()
    if not _G.LexusConfig.AutoLootEnabled then return end
    local GD = _G.getCachedGameplayData()
    if not GD then return end
    local pc = GD.GetPlayerController and GD.GetPlayerController()
    if not Valid(pc) then return end
    local lp = pc:GetPlayerCharacterSafety()
    if not Valid(lp) then return end
    local myLoc = nil
    pcall(function() if lp.K2_GetActorLocation then myLoc = lp:K2_GetActorLocation() end end)
    if not myLoc then return end

    local radius = (tonumber(_G.LexusConfig.AutoLootRadius) or 8.0) * 100  -- to cm
    -- Get all loot actors in world
    pcall(function()
      local ItemClass = import("/Script/ShadowTrackerExtra.STExtraPickupItem")
                     or import("STExtraPickupItem")
      if not ItemClass then return end
      local allItems = Game:GetAllActorsOfClass(ItemClass)
      if not allItems then return end
      local n = type(allItems.Num) == "function" and allItems:Num() or #allItems
      for i = 1, n do
        local item = type(allItems.Get) == "function" and allItems:Get(i-1) or allItems[i]
        if not Valid(item) then goto loot_next end
        local iLoc = nil
        pcall(function() if item.K2_GetActorLocation then iLoc = item:K2_GetActorLocation() end end)
        if not iLoc then goto loot_next end
        local dx = iLoc.X - myLoc.X
        local dy = iLoc.Y - myLoc.Y
        local dz = iLoc.Z - myLoc.Z
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
        if dist <= radius then
          pcall(function()
            if item.PickUp then item:PickUp(lp.Object)
            elseif item.TryPickUp then item:TryPickUp(lp.Object)
            elseif lp.PickupItem then lp:PickupItem(item) end
          end)
        end
        ::loot_next::
      end
    end)
  end)
end

-- ── WALLBANG PENETRATION PREDICTION ───────────────────────────────
-- LexusConfig.WallbangEnabled = true/false
-- Forces bPositiveBlowUp and sets penetration depth overrides
_G.ApplyWallbang = function()
  _G.Safe("wallbang", function()
    if not _G.LexusConfig.WallbangEnabled then return end
    local GD = _G.getCachedGameplayData()
    if not GD then return end
    local pc = GD.GetPlayerController and GD.GetPlayerController()
    if not Valid(pc) then return end
    local lp = pc:GetPlayerCharacterSafety()
    if not Valid(lp) then return end
    -- Enable positive blowup on movement component (allows through-wall detection)
    local mv = lp.STCharacterMovement
    if Valid(mv) then
      pcall(function() mv.bPositiveBlowUp = true end)
    end
    -- Override weapon bullet penetration
    local wm = lp.WeaponManagerComponent
    if not wm then return end
    local weapon = wm.CurrentWeaponReplicated
    if not weapon then return end
    local entity = weapon.ShootWeaponEntityComp
    if not Valid(entity) then return end
    pcall(function()
      if entity.MaxPenetrationCount ~= nil then entity.MaxPenetrationCount = 5 end
      if entity.PenetrationDamageRatio ~= nil then entity.PenetrationDamageRatio = 0.95 end
      if entity.MaxPenetrationThickness ~= nil then entity.MaxPenetrationThickness = 9999.0 end
    end)
    -- Disable pass-wall check on server RPC side
    pcall(function()
      local PC = lp:GetPlayerControllerSafety()
      if Valid(PC) and PC.SetShouldCheckPassWall then
        PC:SetShouldCheckPassWall(false)
      end
    end)
  end)
end

-- ── EXTRA ANTI-BAN LAYER (appended to InitializeAggressiveBypass) ──
local _origInitAggrBypass = _G.InitializeAggressiveBypass
_G.InitializeAggressiveBypass = function()
  if _origInitAggrBypass then _origInitAggrBypass() end
  _G.Safe("aggr_extra_ab1", function()
    -- Block TDM/UE4 position reporting
    local posReport = package.loaded["GameLua.Mod.BaseMod.Common.PositionReport"]
    if posReport then posReport.Report = _nop; posReport.Send = _nop end
    -- Block aim verification subsystem
    local aimVerify = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.AimVerifySubsystem")
    if aimVerify then
      for k, v in pairs(aimVerify) do
        if type(v) == "function" and (k:find("Report") or k:find("Verify") or k:find("Send")) then
          aimVerify[k] = _nop
        end
      end
    end
    -- Neuter speed check
    local speedCheck = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.SpeedCheckSubsystem")
    if speedCheck then
      speedCheck.CheckSpeed = _retTrue
      speedCheck.ReportSpeedViolation = _nop
    end
    -- Fake UID rotation to avoid pattern detection
    if _G.Original_GetDeviceId and not _G.UIDRotateHooked then
      local base = _G.FakeHWID_String or "00000000-0000-0000-0000-000000000000"
      local rotCount = 0
      local origHook = rawget(_G, "FakeHWID_String")
      local SL = import("KismetSystemLibrary")
      if SL then
        SL.GetDeviceId = function(...)
          rotCount = rotCount + 1
          if rotCount % 300 == 0 then
            -- Rotate fake HWID every 300 calls
            local c = "0123456789ABCDEF"
            local s = ""
            for i = 1, 32 do
              local idx = math.random(1, #c)
              s = s .. c:sub(idx,idx)
              if i == 8 or i == 12 or i == 16 or i == 20 then s = s .. "-" end
            end
            _G.FakeHWID_String = s
          end
          return _G.FakeHWID_String or base
        end
        _G.UIDRotateHooked = true
      end
    end
    if _G.AggressiveBypassLog then
      table.insert(_G.AggressiveBypassLog, "ExtraAB-PosReport+AimVerify+SpeedCheck+UIDRotate")
    end
  end)

  -- ── [UPDATE v3.2] NEW BYPASS TARGETS ─────────────────────────────
  _G.Safe("bypass_v32_behavior", function()
    -- Block BehaviorAnalysis subsystem (detects cheat patterns via timing/input analysis)
    local BA = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.BehaviorAnalysis")
    if BA then
      for k, v in pairs(BA) do
        if type(v) == "function" then BA[k] = _nop end
      end
    end
    -- Block BehaviorAnalysis v2 path variant
    local BA2 = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.BehaviorAnalysisV2")
    if BA2 then for k, v in pairs(BA2) do if type(v) == "function" then BA2[k] = _nop end end end
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "BehaviorAnalysis+V2") end
  end)

  _G.Safe("bypass_v32_memory", function()
    -- Block MemoryScanner (scans Lua globals for cheat signatures)
    local MS = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.MemoryScanner")
    if MS then
      MS.Scan       = _nop
      MS.ScanTable  = _nop
      MS.ReportScan = _nop
      MS.StartScan  = _nop
      MS.RunScan    = _nop
    end
    -- Block alternate memory scanner path
    local MS2 = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.LuaMemoryScan")
    if MS2 then for k, v in pairs(MS2) do if type(v) == "function" then MS2[k] = _nop end end end
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "MemoryScanner+LuaMemoryScan") end
  end)

  _G.Safe("bypass_v32_replay", function()
    -- Block ReplayRecorder (behavioral replay sent to server for analysis)
    local RR = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.ReplayRecorder")
    if RR then
      RR.Record       = _nop
      RR.Flush        = _nop
      RR.Send         = _nop
      RR.StartRecord  = _nop
      RR.StopRecord   = _nop
      RR.SaveFrame    = _nop
    end
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "ReplayRecorder-Blocked") end
  end)

  _G.Safe("bypass_v32_telemetry", function()
    -- Block TelemetrySubsystem (sends gameplay telemetry used for anomaly detection)
    local TS = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.TelemetrySubsystem")
    if TS then
      for k, v in pairs(TS) do
        if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Submit") or k:find("Flush") or k:find("Log")) then
          TS[k] = _nop
        end
      end
    end
    -- Block alternate telemetry path
    local TS2 = package.loaded["GameLua.Mod.BaseMod.Common.Telemetry"]
    if TS2 then for k, v in pairs(TS2) do if type(v) == "function" then TS2[k] = _nop end end end
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "TelemetrySubsystem+Telemetry") end
  end)

  _G.Safe("bypass_v32_network", function()
    -- Block NetworkInspector / PacketAnalyzer (deep packet cheat detection layer)
    local NI = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.NetworkInspector")
    if NI then for k, v in pairs(NI) do if type(v) == "function" then NI[k] = _nop end end end
    local PA = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.PacketAnalyzer")
    if PA then for k, v in pairs(PA) do if type(v) == "function" then PA[k] = _nop end end end
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "NetworkInspector+PacketAnalyzer") end
  end)

  _G.Safe("bypass_v32_swifthawk2", function()
    -- SwiftHawk v2 (newer path — added alongside v1 in recent BGMI builds)
    local SH2 = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.SwiftHawk2")
    if SH2 then for k, v in pairs(SH2) do if type(v) == "function" then SH2[k] = _nop end end end
    local SH2b = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.SwiftHawkV2")
    if SH2b then for k, v in pairs(SH2b) do if type(v) == "function" then SH2b[k] = _nop end end end
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "SwiftHawk2+SwiftHawkV2") end
  end)

  _G.Safe("bypass_v32_coronalab_ext", function()
    -- CoronaLab additional module path variants (extended from original bypass)
    local CL2 = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.CoronaLabV2")
    if CL2 then for k, v in pairs(CL2) do if type(v) == "function" then CL2[k] = _nop end end end
    local CL3 = _G.GetModule("GameLua.Mod.BaseMod.Common.CoronaLab")
    if CL3 then for k, v in pairs(CL3) do if type(v) == "function" then CL3[k] = _nop end end end
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "CoronaLabV2+CoronaLab-Alt") end
  end)

  _G.Safe("bypass_v32_anticheatsys", function()
    -- AntiCheatSubsystem null hooks (generic UE4 anti-cheat bridge)
    local ACS = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.AntiCheatSubsystem")
    if ACS then
      ACS.Init          = _nop
      ACS.Register      = _nop
      ACS.ReportEvent   = _nop
      ACS.SendReport    = _nop
      ACS.CheckIntegrity= _retTrue
      ACS.ValidateClient= _retTrue
    end
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "AntiCheatSubsystem") end
  end)

  _G.Safe("bypass_v32_uid_entropy", function()
    -- [UPDATE] Improved UID rotation with better entropy (os.time seed + xorshift)
    if _G.UIDRotateHooked then
      -- Re-hook with better entropy if already hooked with weak version
      local SL = import("KismetSystemLibrary")
      if SL then
        local rotCount = 0
        local seed = os.time() + math.random(1, 99999)
        local function xorshift(s)
          s = s ~ (s << 13); s = s ~ (s >> 7); s = s ~ (s << 17)
          return s & 0xFFFFFFFF
        end
        SL.GetDeviceId = function(...)
          rotCount = rotCount + 1
          if rotCount % 200 == 0 then  -- rotate more frequently: every 200 calls
            seed = xorshift(seed + os.time())
            math.randomseed(seed)
            local c = "0123456789ABCDEF"
            local s = ""
            for i = 1, 32 do
              local idx = ((seed >> (i % 16)) % 16) + 1
              s = s .. c:sub(idx, idx)
              if i == 8 or i == 12 or i == 16 or i == 20 then s = s .. "-" end
            end
            _G.FakeHWID_String = s
          end
          return _G.FakeHWID_String or "00000000-0000-0000-0000-000000000000"
        end
        if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "UID-Entropy-Upgrade") end
      end
    end
  end)
end

  -- ── [v3.3] NEW FEATURE BYPASSES ─────────────────────────────────────

  _G.Safe("bypass_v33_consolecmd_fog_grass_trees", function()
    -- ConsoleCommandValidator intercepts and logs ExecuteConsoleCommand calls.
    -- Bypass: null the Report/Validate hooks so fog/grass/tree cmds pass silently.
    local CCV = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.ConsoleCommandValidator")
    if CCV then
      CCV.Validate      = _retTrue   -- always return valid
      CCV.IsAllowed     = _retTrue
      CCV.Report        = _nop
      CCV.LogCommand    = _nop
      CCV.CheckCommand  = _retTrue
    end
    -- ConsoleCommandAudit (newer BGMI path)
    local CCA = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.ConsoleCommandAudit")
    if CCA then
      for k, v in pairs(CCA) do if type(v) == "function" then CCA[k] = _nop end end
    end
    -- KismetSystemLibrary.ExecuteConsoleCommand proxy: strip any call-site hook
    -- that rewrites the command or drops it before engine receives it
    pcall(function()
      local KSL = import("KismetSystemLibrary")
      if KSL and KSL._OrigExecCmd == nil then
        KSL._OrigExecCmd = KSL.ExecuteConsoleCommand
        KSL.ExecuteConsoleCommand = function(ctx, cmd, pc)
          -- allow list: only the cmds we actually use — drop everything else
          -- through the original so unrelated engine commands aren't broken
          return KSL._OrigExecCmd(ctx, cmd, pc)
        end
      end
    end)
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "ConsoleCmd-FogGrassTrees-v33") end
  end)

  _G.Safe("bypass_v33_hudtext_espbox", function()
    -- HUDDebugTextMonitor watches AddDebugText calls for cheat signatures
    -- (repeating symbols like ■ / ▪ on enemy actors = cheat fingerprint).
    -- Bypass: null the monitor's scan + report functions.
    local HDM = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.HUDDebugTextMonitor")
    if HDM then
      HDM.Scan        = _nop
      HDM.Report      = _nop
      HDM.Analyse     = _nop
      HDM.CheckSymbol = _retTrue   -- symbol always "safe"
      HDM.CheckActor  = _retTrue   -- actor always "safe"
    end
    -- DebugRenderSubsystem — secondary path that validates HUD draw calls
    local DRS = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.DebugRenderSubsystem")
    if DRS then for k, v in pairs(DRS) do if type(v) == "function" then DRS[k] = _nop end end end
    -- HUD proxy: wrap GetMyHUD so a monitored HUD is replaced with a silent proxy
    pcall(function()
      local GD = _G.getCachedGameplayData()
      if not (GD and GD.GetMyHUD) then return end
      if GD._HUDProxied then return end
      local origGetHUD = GD.GetMyHUD
      GD.GetMyHUD = function(...)
        local hud = origGetHUD(...)
        if not hud then return hud end
        -- If HUD has a monitor hook installed, detach it
        if hud._DebugMonitor then hud._DebugMonitor = nil end
        if hud._TextAudit     then hud._TextAudit     = nil end
        return hud
      end
      GD._HUDProxied = true
    end)
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "HUDDebugText-ESPBox-v33") end
  end)

  _G.Safe("bypass_v33_autoaim_comp_write", function()
    -- AutoAimCompValidator monitors writes to AutoAimComp fields (bOnlyHitHead,
    -- HeadBoneName, Bones). Any deviation from defaults triggers a flag.
    -- Bypass: null the validator before we write; restore-on-read guard too.
    local ACV = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.AutoAimCompValidator")
    if ACV then
      ACV.Validate        = _retTrue
      ACV.CheckField      = _retTrue
      ACV.OnFieldWrite    = _nop
      ACV.Report          = _nop
      ACV.RevertField     = _nop   -- prevent auto-revert of our bone overrides
      ACV.ForceRestore    = _nop
    end
    -- BoneOverrideDetector (newer BGMI path — detects Bones table write)
    local BOD = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.BoneOverrideDetector")
    if BOD then for k, v in pairs(BOD) do if type(v) == "function" then BOD[k] = _nop end end end
    -- AimComp integrity checker (runs on a timer to restore original values)
    local AIC = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.AimCompIntegrity")
    if AIC then
      AIC.Check   = _nop
      AIC.Restore = _nop
      AIC.Tick    = _nop
      AIC.Start   = _nop
    end
    -- __newindex proxy guard: if AutoAimComp has been wrapped with a proxy
    -- that intercepts field writes, unwrap it via rawset
    pcall(function()
      local GD = _G.getCachedGameplayData()
      if not (GD and GD.GetPlayerController) then return end
      local pc = GD.GetPlayerController()
      if not pc then return end
      local ch = pc:GetPlayerCharacterSafety()
      if not (ch and ch.AutoAimComp) then return end
      local comp = ch.AutoAimComp
      local mt = getmetatable(comp)
      if mt and mt.__newindex then
        -- proxy detected — cache original __newindex, replace with rawset passthrough
        if not _G._AimCompOrigNI then _G._AimCompOrigNI = mt.__newindex end
        mt.__newindex = function(t, k2, v2) rawset(t, k2, v2) end
      end
    end)
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "AutoAimComp-BoneWrite-v33") end
  end)

  _G.Safe("bypass_v33_recoil_field_write", function()
    -- RecoilValidator monitors ShootWeaponEntityComp field writes for anomalies
    -- (VerticalRecoil/AccessoriesVRecoilFactor going to 0 = cheat flag).
    -- Bypass: null all validator hooks + suppress the integrity restore timer.
    local RV = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.RecoilValidator")
    if RV then
      RV.Validate      = _retTrue
      RV.CheckField    = _retTrue
      RV.OnFieldWrite  = _nop
      RV.Report        = _nop
      RV.ForceRestore  = _nop
      RV.Tick          = _nop
    end
    -- WeaponDataIntegrity (checks weapon entity component fields on a timer)
    local WDI = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.WeaponDataIntegrity")
    if WDI then
      WDI.Check   = _nop
      WDI.Restore = _nop
      WDI.Tick    = _nop
      WDI.Start   = _nop
    end
    -- RecoilMonitor (alternate path — newer builds)
    local RM = _G.GetModule("GameLua.Mod.BaseMod.Common.Security.RecoilMonitor")
    if RM then for k, v in pairs(RM) do if type(v) == "function" then RM[k] = _nop end end end
    -- ShootWeaponEntityComp __newindex proxy guard (same pattern as AimComp above)
    pcall(function()
      local GD = _G.getCachedGameplayData()
      if not (GD and GD.GetPlayerController) then return end
      local pc = GD.GetPlayerController()
      if not pc then return end
      local ch = pc:GetPlayerCharacterSafety()
      if not ch then return end
      local wm = ch.WeaponManagerComponent
      if not wm then return end
      local wp = wm.CurrentWeaponReplicated
      if not wp then return end
      local ent = wp.ShootWeaponEntityComp
      if not ent then return end
      local mt = getmetatable(ent)
      if mt and mt.__newindex then
        if not _G._RecoilEntOrigNI then _G._RecoilEntOrigNI = mt.__newindex end
        mt.__newindex = function(t, k2, v2) rawset(t, k2, v2) end
      end
    end)
    if _G.AggressiveBypassLog then table.insert(_G.AggressiveBypassLog, "RecoilFieldWrite-v33") end
  end)

-- ── END [v3.3] ────────────────────────────────────────────────────────

-- ── DEFAULT CONFIG VALUES for new features ─────────────────────────
-- These get merged into LexusConfig on load
local _newFeatureDefaults = {
  AimbotSmoothEnabled  = true,
  AimbotFOV            = 120.0,
  AimbotBone           = "head",       -- head / neck_01 / pelvis
  EspColorMode         = "red",         -- red / white / green / yellow
  SpeedHackEnabled     = false,
  SpeedMultiplier      = 1.5,
  RadarEnabled         = false,
  AutoLootEnabled      = false,
  AutoLootRadius       = 8.0,
  WallbangEnabled      = false,
}
for k, v in pairs(_newFeatureDefaults) do
  if _G.LexusConfig[k] == nil then _G.LexusConfig[k] = v end
end

-- Hook new systems into MainLoop
local _origMainLoopApply = nil  -- handled inline below via flag
_G._NewFeaturesHooked = _G._NewFeaturesHooked or false
if not _G._NewFeaturesHooked then
  _G._NewFeaturesHooked = true
  local _ticker = _G.GetModule("common.time_ticker")
  if _ticker and _ticker.AddTimerOnce then
    -- Speed + wallbang run in main tick (handled in FastTick below via globals)
    -- Radar at 0.1s interval
    _ticker.AddTimerOnce(0.1, function()
      local function RadarLoop()
        pcall(_G.ApplyRadar)
        local t2 = _G.GetModule("common.time_ticker")
        if t2 and t2.AddTimerOnce then t2.AddTimerOnce(0.1, RadarLoop) end
      end
      RadarLoop()
    end)
    -- Auto loot at 0.3s interval
    _ticker.AddTimerOnce(0.3, function()
      local function LootLoop()
        pcall(_G.ApplyAutoLoot)
        local t2 = _G.GetModule("common.time_ticker")
        if t2 and t2.AddTimerOnce then t2.AddTimerOnce(0.3, LootLoop) end
      end
      LootLoop()
    end)
  end
end

-- ====================================================================
-- END MODIFICATIONS
-- ====================================================================

_G.recoilOriginalCache = _G.recoilOriginalCache or setmetatable({}, { __mode = "k" })
_G.RECOIL_FIELDS = { "RecoilKick", "RecoilKickADS", "AnimationKick", "GameDeviationFactor", "RecoilModifierStand", "RecoilModifierCrouch", "RecoilModifierProne", "CameraShakeScale", "AimCameraShakeScale", "ShootCameraShakeScale", "FireCameraShakeScale", "GameDeviationAccuracy", "ShotGunHorizontalSpread", "ShotGunVerticalSpread", "DeviationMultiplier", "AccessoriesVRecoilFactor", "AccessoriesHRecoilFactor" }
_G.RECOIL_TARGET_VALUES = { RecoilKick=0.01, RecoilKickADS=0.01, AnimationKick=0.01, GameDeviationFactor=0.01, RecoilModifierStand=0.01, RecoilModifierCrouch=0.01, RecoilModifierProne=0.01, CameraShakeScale=0.01, AimCameraShakeScale=0.01, ShootCameraShakeScale=0.01, FireCameraShakeScale=0.01, GameDeviationAccuracy=0.01, ShotGunHorizontalSpread=0.01, ShotGunVerticalSpread=0.01, DeviationMultiplier=0.01, AccessoriesVRecoilFactor=0.0, AccessoriesHRecoilFactor=0.0 }
_G.RECOIL_INFO_FIELDS = { "VerticalRecoilMin", "VerticalRecoilMax", "RecoilSpeedVertical", "RecoilSpeedHorizontal", "VerticalRecoveryMax" }
_G.RECOIL_INFO_TARGET = { VerticalRecoilMin=0.01, VerticalRecoilMax=0.01, RecoilSpeedVertical=0.01, RecoilSpeedHorizontal=0.01, VerticalRecoveryMax=0.01 }

_G.ApplyNoRecoil = function()
  _G.Safe("norecoil", function()
    local GD = _G.getCachedGameplayData()
    if not GD or not GD.GetPlayerController then return end
    local pc = GD.GetPlayerController()
    if not Valid(pc) then return end
    local char = pc:GetPlayerCharacterSafety()
    if not Valid(char) then return end
    local wm = char.WeaponManagerComponent
    if not wm then return end
    local weapon = wm.CurrentWeaponReplicated
    if not weapon then return end
    local entity = weapon.ShootWeaponEntityComp
    if not Valid(entity) then return end
    if not _G.LexusConfig.NoRecoilEnabled then
      if _G.recoilOriginalCache[entity] then
        local saved = _G.recoilOriginalCache[entity]
        for k, v in pairs(saved) do
          if k == "RecoilInfo" then
            if entity.RecoilInfo then for rk, rv in pairs(v) do entity.RecoilInfo[rk] = rv end end
          elseif k == "ShootCameraShakeScale" then
            if entity.ShootCameraShake then entity.ShootCameraShake.Scale = v end
          else entity[k] = v end
        end
        _G.recoilOriginalCache[entity] = nil
      end
      return
    end
    if _G.LastNRWeapon == entity and _G.LastNRTime and os.clock() - _G.LastNRTime < 0.5 then return end
    _G.LastNRWeapon = entity
    _G.LastNRTime = os.clock()
    if not _G.recoilOriginalCache[entity] then
      local saved = { RecoilInfo = {} }
      for _, f in ipairs(_G.RECOIL_FIELDS) do if entity[f] ~= nil then saved[f] = entity[f] end end
      if entity.RecoilInfo then for _, f in ipairs(_G.RECOIL_INFO_FIELDS) do if entity.RecoilInfo[f] ~= nil then saved.RecoilInfo[f] = entity.RecoilInfo[f] end end end
      if entity.ShootCameraShake then saved.ShootCameraShakeScale = entity.ShootCameraShake.Scale end
      _G.recoilOriginalCache[entity] = saved
    end
    local orig = _G.recoilOriginalCache[entity]
    if not orig then return end
    local slider = (_G.LexusConfig.RecoilReduction or 100) / 100
    if slider > 1 then slider = 1 end
    if slider < 0 then slider = 0 end
    for _, f in ipairs(_G.RECOIL_FIELDS) do
      if entity[f] ~= nil and orig[f] ~= nil and _G.RECOIL_TARGET_VALUES[f] then
        entity[f] = orig[f] + (_G.RECOIL_TARGET_VALUES[f] - orig[f]) * slider
      end
    end
    if entity.RecoilInfo then
      for _, f in ipairs(_G.RECOIL_INFO_FIELDS) do
        if entity.RecoilInfo[f] ~= nil and orig.RecoilInfo and orig.RecoilInfo[f] ~= nil and _G.RECOIL_INFO_TARGET[f] then
          entity.RecoilInfo[f] = orig.RecoilInfo[f] + (_G.RECOIL_INFO_TARGET[f] - orig.RecoilInfo[f]) * slider
        end
      end
    end
    if entity.ShootCameraShake then
      local origScale = orig.ShootCameraShakeScale or 1.0
      entity.ShootCameraShake.Scale = origScale + (0.01 - origScale) * slider
    end
  end)
end

_G.AimbotState = _G.AimbotState or { LastTarget = nil, LastBone = "neck_01", LastLockTime = 0 }
local AIMBOT_BONES = {
  neck = { "neck_01", "Neck_01", "neck" },
  chest = { "spine_03", "Spine_03", "spine_02", "Spine_02", "spine_01", "Spine_01", "spine" }
}
_G._WAimBackup = _G._WAimBackup or setmetatable({}, { __mode = "k" })

_G.ApplyWeaponAimbot = function()
  _G.Safe("weapon_aimbot", function()
    if not _G.LexusConfig.WeaponAimbot then return end
    local GD = _G.getCachedGameplayData()
    if not GD or not GD.GetPlayerController then return end
    local pc = GD.GetPlayerController()
    if not Valid(pc) then return end
    local char = pc:GetPlayerCharacterSafety()
    if not Valid(char) then return end
    local wm = char.WeaponManagerComponent
    if not Valid(wm) then return end
    local weapon = wm.CurrentWeaponReplicated
    if not Valid(weapon) then return end
    local entity = weapon.ShootWeaponEntityComp
    if not Valid(entity) then return end
    if _G._LastWAimEntity == entity and _G._LastWAimTime and os.clock() - _G._LastWAimTime < 0.5 then return end
    _G._LastWAimEntity = entity
    _G._LastWAimTime = os.clock()
    if not _G._WAimBackup[entity] and entity.AutoAimingConfig then
      local saved = {}
      for _, rname in ipairs({"OuterRange", "InnerRange"}) do
        local cfg = entity.AutoAimingConfig[rname]
        if cfg then
          saved[rname] = { Speed = cfg.Speed, RangeRate = cfg.RangeRate, SpeedRate = cfg.SpeedRate, RangeRateSight = cfg.RangeRateSight, SpeedRateSight = cfg.SpeedRateSight, CrouchRate = cfg.CrouchRate, ProneRate = cfg.ProneRate, DyingRate = cfg.DyingRate }
        end
      end
      _G._WAimBackup[entity] = saved
    end
    if entity.AutoAimingConfig then
      for _, range in ipairs({"OuterRange", "InnerRange"}) do
        local cfg = entity.AutoAimingConfig[range]
        if cfg then
          cfg.Speed = 10; cfg.RangeRate = 2; cfg.SpeedRate = 4; cfg.RangeRateSight = 2; cfg.SpeedRateSight = 4; cfg.CrouchRate = 2; cfg.ProneRate = 2; cfg.DyingRate = 2
        end
      end
    end
    local aimComp = char.BP_AutoAimingComponent_C or char.BP_AutoAimingComponent
    if Valid(aimComp) and aimComp.Bones then aimComp.Bones = {"head", "head", "head"} end
  end)
end

_G.ApplyAutoHeadScope = function()
  _G.Safe("auto_head_scope", function()
    if not _G.LexusConfig.AutoHead then return end
    if _G._LastAutoHeadTime and os.clock() - _G._LastAutoHeadTime < 0.1 then return end
    _G._LastAutoHeadTime = os.clock()
    local GD = _G.getCachedGameplayData()
    if not GD or not GD.GetPlayerController then return end
    local pc = GD.GetPlayerController()
    if not Valid(pc) then return end
    local localChar = pc:GetPlayerCharacterSafety()
    if not Valid(localChar) then return end
    -- [MERGE from AIMBOT___AUTOHEAD.lua] AutoAimComp bone override
    pcall(function()
      local Comp = localChar.AutoAimComp
      if Comp then
        if not _G.LexusState.OrigAutoAimCompCached then
          _G.LexusState.OrigAutoAimCompCached = {
            bOnlyHitHead   = Comp.bOnlyHitHead,
            HeadBoneName   = Comp.HeadBoneName,
            Bones          = Comp.Bones,
            ChestBoneName  = Comp.ChestBoneName,
            PelvisBoneName = Comp.PelvisBoneName,
          }
        end
        Comp.bOnlyHitHead   = true
        Comp.HeadBoneName   = "Head"
        Comp.ChestBoneName  = "Head"
        Comp.PelvisBoneName = "Head"
        pcall(function() Comp.Bones = {"Head"} end)
      end
    end)
    local localLoc = nil
    pcall(function() localLoc = localChar:K2_GetActorLocation() end)
    if not localLoc then return end
    local myTeamID = localChar.TeamID
    local isScoped = false
    pcall(function()
      local cam = localChar.ThirdPersonCameraComponent
      if Valid(cam) and cam.FieldOfView then isScoped = cam.FieldOfView < 60 end
    end)
    local maxDist = isScoped and 50000 or 25000
    local closestEnemy = nil
    local closestDist = 99999999
    local allChars = GD.GetAllPlayerCharacters and GD.GetAllPlayerCharacters() or {}
    for _, enemy in pairs(allChars) do
      if Valid(enemy) and enemy ~= localChar and enemy.TeamID ~= myTeamID then
        local bDead = false
        pcall(function()
          if type(enemy.IsDead) == "function" then bDead = enemy:IsDead()
          elseif enemy.bIsDead ~= nil then bDead = enemy.bIsDead end
        end)
        if not bDead then
          local eLoc = nil
          pcall(function() eLoc = enemy:K2_GetActorLocation() end)
          if eLoc then
            local dx = (eLoc.X or 0) - (localLoc.X or 0)
            local dy = (eLoc.Y or 0) - (localLoc.Y or 0)
            local dz = (eLoc.Z or 0) - (localLoc.Z or 0)
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            if dist < closestDist then closestDist = dist; closestEnemy = enemy end
          end
        end
      end
    end
    if not closestEnemy or closestDist > maxDist then return end
    local targetLoc = nil
    pcall(function()
      local mesh = closestEnemy.Mesh
      if Valid(mesh) and type(mesh.GetSocketLocation) == "function" then
        if isScoped then targetLoc = mesh:GetSocketLocation("head")
        else targetLoc = mesh:GetSocketLocation("spine_02"); if not targetLoc then targetLoc = closestEnemy:K2_GetActorLocation() end; if targetLoc then targetLoc.Z = targetLoc.Z + 100 end end
      end
    end)
    if not targetLoc then pcall(function() targetLoc = closestEnemy:K2_GetActorLocation() end); if targetLoc then targetLoc.Z = targetLoc.Z + (isScoped and 180 or 100) end end
    if not targetLoc then return end
    local myCam = localChar.ThirdPersonCameraComponent
    if not Valid(myCam) then return end
    local camLoc = nil
    pcall(function() camLoc = myCam:K2_GetComponentLocation() end)
    if not camLoc then return end
    local dirX = (targetLoc.X or 0) - (camLoc.X or 0)
    local dirY = (targetLoc.Y or 0) - (camLoc.Y or 0)
    local dirZ = (targetLoc.Z or 0) - (camLoc.Z or 0)
    local len = math.sqrt(dirX*dirX + dirY*dirY + dirZ*dirZ)
    if len <= 0 then return end
    local rot = nil
    pcall(function()
      local FRotator = import("Rotator")
      local pitch = math.deg(math.asin(dirZ / len))
      local yaw = math.deg(_G.atan2(dirY, dirX))
      if isScoped then rot = FRotator and FRotator(-pitch, yaw, 0) or {Pitch = -pitch, Yaw = yaw, Roll = 0}
      else
        local curRot = pc:GetControlRotation()
        if curRot then
          local curPitch = curRot.Pitch or 0
          local curYaw = curRot.Yaw or 0
          local blend = 0.35
          local newPitch = curPitch + (-pitch - curPitch) * blend
          local newYaw = curYaw + (yaw - curYaw) * blend
          rot = FRotator and FRotator(newPitch, newYaw, 0) or {Pitch = newPitch, Yaw = newYaw, Roll = 0}
        else rot = FRotator and FRotator(-pitch, yaw, 0) or {Pitch = -pitch, Yaw = yaw, Roll = 0} end
      end
    end)
    if rot then pcall(function() pc:SetControlRotation(rot) end) end
  end)
end

_G.ApplyESPInfo = function(enemy, markData, distM)
  if not _G.LexusConfig.EspInfo then return end
  if not Valid(enemy) then return end
  local HUD = _G.Cached_MyHUD
  if not Valid(HUD) then
    pcall(function()
      local GD = _G.getCachedGameplayData()
      if GD then local h = GD.GetMyHUD and GD.GetMyHUD(); if Valid(h) then _G.Cached_MyHUD = h; HUD = h end end
    end)
    if not Valid(HUD) then return end
  end
  if distM > 400 then return end
  local stateText = ""
  if _G.LexusConfig.EspInfo_Pose then
    local pose = nil
    pcall(function() pose = enemy.PoseState or (type(enemy.GetPoseState) == "function" and enemy:GetPoseState()) end)
    if pose == 0 or pose == "Stand" then stateText = "Stand"
    elseif pose == 1 or pose == "Crouch" then stateText = "Crouch"
    elseif pose == 2 or pose == "Prone" then stateText = "Prone"
    else stateText = "Stand" end
  end
  if _G.LexusConfig.EspInfo_Weapon then
    local now = os.clock()
    if not markData.WepTime or now > markData.WepTime + 1.5 then
      local w = nil
      pcall(function() w = enemy.CurrentWeapon or enemy:GetCurrentWeapon() end)
      local wn = "Fists"
      if Valid(w) and type(w.GetWeaponName) == "function" then wn = w:GetWeaponName() end
      markData.CachedWep = tostring(wn)
      markData.WepTime = now
    end
    if stateText ~= "" then stateText = stateText .. " - " .. (markData.CachedWep or "Fists")
    else stateText = markData.CachedWep or "Fists" end
  end
  if stateText ~= "" then
    local isBot = markData.AK_IS_BOT or false
    local col = isBot and _G.C_CYAN or _G.C_YELLOW
    local sc = math.max(0.5, 0.8 - (distM / 400))
    HUD:AddDebugText(stateText, enemy, 0.06, {X=0,Y=0,Z=100}, {X=0,Y=0,Z=100}, col, true, false, true, nil, sc, true)
  end
end

_G.ApplyAimbot = function()
  _G.Safe("aimbot", function()
    if not _G.LexusConfig.AimbotEnabled then return end
    if _G._LastAimTime and os.clock() - _G._LastAimTime < 0.05 then return end
    _G._LastAimTime = os.clock()
    local GD = _G.getCachedGameplayData()
    if not GD or not GD.GetPlayerController then return end
    local pc = GD.GetPlayerController()
    if not Valid(pc) then return end
    local localChar = pc:GetPlayerCharacterSafety()
    if not Valid(localChar) then return end
    local localLoc = nil
    pcall(function() localLoc = localChar:K2_GetActorLocation() end)
    if not localLoc then return end
    local myTeamID = localChar.TeamID
    local maxDist = 10000
    local fovDeg = 30
    local fovCos = math.cos(math.rad(fovDeg))
    local curRot = pc:GetControlRotation()
    if not curRot then return end
    local curPitch = curRot.Pitch or 0
    local curYaw = curRot.Yaw or 0
    local curPitchRad = math.rad(curPitch)
    local yawRad = math.rad(curYaw)
    local fwdX = math.cos(curPitchRad) * math.cos(yawRad)
    local fwdY = math.cos(curPitchRad) * math.sin(yawRad)
    local fwdZ = math.sin(curPitchRad)
    local boneList = AIMBOT_BONES.neck
    if _G.AimbotState.LastBone == "chest" then boneList = AIMBOT_BONES.chest end
    local bestEnemy, bestScore, bestBoneLoc = nil, math.huge, nil
    local allChars = GD.GetAllPlayerCharacters and GD.GetAllPlayerCharacters() or {}
    for _, enemy in pairs(allChars) do
      if Valid(enemy) and enemy ~= localChar and enemy.TeamID ~= myTeamID then
        local skip = false
        pcall(function()
          if type(enemy.IsDead) == "function" and enemy:IsDead() then skip = true
          elseif enemy.bIsDead == true then skip = true end
          if enemy.HealthStatus == 1 or enemy.HealthStatus == 2 then skip = true end
        end)
        if not skip then
          local eLoc = nil
          pcall(function() eLoc = enemy:K2_GetActorLocation() end)
          if eLoc then
            local dx = (eLoc.X or 0) - (localLoc.X or 0)
            local dy = (eLoc.Y or 0) - (localLoc.Y or 0)
            local dz = (eLoc.Z or 0) - (localLoc.Z or 0)
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            if dist <= maxDist and dist > 0 then
              local dot = (dx*fwdX + dy*fwdY + dz*fwdZ) / dist
              if dot >= fovCos then
                local vis = true
                pcall(function()
                  local FV = _G.FVector or import("Vector")
                  local zeroV = FV and FV(0, 0, 0) or {X=0, Y=0, Z=0}
                  vis = pc:LineOfSightTo(enemy, zeroV, true)
                end)
                if vis then
                  local boneLoc = nil
                  pcall(function()
                    local mesh = enemy.Mesh
                    if Valid(mesh) and type(mesh.GetSocketLocation) == "function" then
                      for _, bn in ipairs(boneList) do
                        local ok, loc = pcall(function() return mesh:GetSocketLocation(bn) end)
                        if ok and loc then boneLoc = loc; break end
                      end
                    end
                  end)
                  if not boneLoc then
                    pcall(function() boneLoc = enemy:K2_GetActorLocation() end)
                    if boneLoc then
                      if _G.AimbotState.LastBone == "neck" then boneLoc.Z = boneLoc.Z + 130
                      else boneLoc.Z = boneLoc.Z + 90 end
                    end
                  end
                  if boneLoc then
                    local score = dist * (2 - dot)
                    if score < bestScore then bestScore = score; bestEnemy = enemy; bestBoneLoc = boneLoc end
                  end
                end
              end
            end
          end
        end
      end
    end
    if not bestEnemy or not bestBoneLoc then return end
    if _G.AimbotState.LastTarget ~= bestEnemy then
      _G.AimbotState.LastTarget = bestEnemy
      _G.AimbotState.LastLockTime = os.clock()
      if math.random() < 0.6 then _G.AimbotState.LastBone = "neck"
      else _G.AimbotState.LastBone = "chest" end
    end
    local camLoc = nil
    pcall(function()
      local camMgr = import("GameplayStatics").GetPlayerCameraManager(pc, 0)
      if Valid(camMgr) then camLoc = camMgr:GetCameraLocation() end
    end)
    if not camLoc then return end
    local dirX = (bestBoneLoc.X or 0) - (camLoc.X or 0)
    local dirY = (bestBoneLoc.Y or 0) - (camLoc.Y or 0)
    local dirZ = (bestBoneLoc.Z or 0) - (camLoc.Z or 0)
    local len = math.sqrt(dirX*dirX + dirY*dirY + dirZ*dirZ)
    if len <= 0 then return end
    local targetPitch = -math.deg(math.asin(dirZ / len))
    local targetYaw = math.deg(_G.atan2(dirY, dirX))
    local deltaYaw = targetYaw - curYaw
    if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
    if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
    local deltaPitch = targetPitch - curPitch
    local dt = (_G.FrameDelta and _G.FrameDelta.ClampedDelta) or 0.016
    local speed = 8.0
    local t = 1 - math.exp(-speed * dt)
    if t > 1 then t = 1 end
    local newPitch = curPitch + deltaPitch * t
    local newYaw = curYaw + deltaYaw * t
    local FRotator = import("Rotator")
    local rot = FRotator and FRotator(newPitch, newYaw, 0) or {Pitch = newPitch, Yaw = newYaw, Roll = 0}
    pcall(function() pc:SetControlRotation(rot) end)
  end)
end

-- [REMOVED] X Effect / HitMarker system fully removed

_G.CrosshairState = _G.CrosshairState or { Widgets = {}, Container = nil, LastHash = "" }
local function CrosshairColorFromIdx(idx)
  if idx == 1 then return {R=1, G=0, B=0, A=1} end
  if idx == 2 then return {R=0, G=1, B=0, A=1} end
  if idx == 3 then return {R=0, G=0.5, B=1, A=1} end
  if idx == 4 then return {R=0, G=1, B=1, A=1} end
  if idx == 5 then return {R=1, G=1, B=0, A=1} end
  return {R=1, G=1, B=1, A=1}
end
_G.CrosshairClear = function()
  local C = _G.CrosshairState.Container
  if C and slua.isValid(C) then pcall(function() C:RemoveFromParent(); C:ConditionalBeginDestroy() end) end
  _G.CrosshairState.Container = nil
  _G.CrosshairState.Widgets = {}
  _G.CrosshairState.LastHash = ""
end
_G.ApplyCrosshair = function()
  _G.Safe("crosshair", function()
    if not _G.LexusConfig.Crosshair then
      if _G.CrosshairState.Container then _G.CrosshairClear() end
      return
    end
    local PM = _G.PlayerMapMarker
    if not PM or not PM.ESPCanvas or not Game:IsValid(PM.ESPCanvas) then
      if PM and PM.InitESPCanvas then PM.InitESPCanvas() end
      if not PM or not PM.ESPCanvas then return end
    end
    local canvas = PM.ESPCanvas
    if not canvas then return end
    local style = _G.LexusConfig.CrosshairStyle or 1
    local size = math.max(1, math.min(10, _G.LexusConfig.CrosshairSize or 4))
    local colorIdx = _G.LexusConfig.CrosshairColor or 2
    local hash = string.format("%d_%d_%d", style, size, colorIdx)
    if hash == _G.CrosshairState.LastHash and _G.CrosshairState.Container and slua.isValid(_G.CrosshairState.Container) then return end
    _G.CrosshairClear()
    _G.CrosshairState.LastHash = hash
    local col = CrosshairColorFromIdx(colorIdx)
    local LC = _G.getCachedLinearColor()
    local fcolor = LC and LC(col.R, col.G, col.B, col.A) or {R=col.R*255, G=col.G*255, B=col.B*255, A=255}
    local sw, sh = 1920, 1080
    pcall(function()
      local WLL = _G.GetModule("WidgetLayoutLibrary")
      if WLL and WLL.GetViewportSize then
        local sz = WLL.GetViewportSize(nil)
        if sz and sz.X and sz.X > 200 then sw = sz.X; sh = sz.Y end
      end
    end)
    local cx, cy
    if PM.ScreenPixelToCanvasLocal then
      local p = PM.ScreenPixelToCanvasLocal(nil, {X = sw * 0.5, Y = sh * 0.5})
      cx, cy = p.X, p.Y
    else
      cx, cy = sw * 0.5, sh * 0.5
    end
    local C = nil
    pcall(function() C = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
    if not C or not slua.isValid(C) then return end
    _G.CrosshairState.Container = C
    local thickness = 2
    local gap = size * 1.5
    local length = size * 2.5
    local dot = size * 0.6
    local function addBorder(x, y, w, h)
      local B = nil
      pcall(function() B = CGame:NewObjectFromPath("/Script/UMG.Border", C) end)
      if not B or not slua.isValid(B) then return end
      pcall(function() B:SetBrushColor(fcolor); B:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
      local s = C:AddChildToCanvas(B)
      if s then s:SetPosition(FVector2D(x, y)); s:SetSize(FVector2D(w, h)) end
      table.insert(_G.CrosshairState.Widgets, B)
    end
    if style == 1 then addBorder(cx - dot/2, cy - dot/2, dot, dot)
    elseif style == 2 then
      addBorder(cx - gap - length, cy - thickness/2, length, thickness)
      addBorder(cx + gap, cy - thickness/2, length, thickness)
      addBorder(cx - thickness/2, cy - gap - length, thickness, length)
      addBorder(cx - thickness/2, cy + gap, thickness, length)
    elseif style == 3 then
      local radius = size * 1.5; local seg = 16
      for i = 0, seg - 1 do local a = (i / seg) * math.pi * 2; local dx = math.cos(a) * radius; local dy = math.sin(a) * radius; addBorder(cx + dx - thickness/2, cy + dy - thickness/2, thickness, thickness) end
    elseif style == 4 then
      local radius = size * 1.5; local seg = 16
      for i = 0, seg - 1 do local a = (i / seg) * math.pi * 2; local dx = math.cos(a) * radius; local dy = math.sin(a) * radius; addBorder(cx + dx - thickness/2, cy + dy - thickness/2, thickness, thickness) end
      addBorder(cx - dot/2, cy - dot/2, dot, dot)
    end
    local slot = nil
    pcall(function() slot = canvas:AddChildToCanvas(C) end)
    if slot then pcall(function() slot:SetAutoSize(false); slot:SetZOrder(9999); slot:SetPosition(FVector2D(0, 0)) end) end
  end)
end

-- ====================================================================
-- GSC_FPS integration (from official GSC_FPS.lua) + forced 165 support
-- Removes weak console-only path; applies t.MaxFPS + r.FrameRateLimit
-- and unlocks RealSupportFPS levels 1-9 so settings UI accepts 165.
-- ====================================================================
_G.FPSState = _G.FPSState or { LastApplied = 0, WasEnabled = false, GSCHooked = false }

_G.ForceGSCFPSSupport = function()
  _G.Safe("gsc_fps_support", function()
    if _G.FPSState.GSCHooked then return end
    local GraphicSettingDB = package.loaded["client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"]
      or _G.GetModule("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
    if not GraphicSettingDB then return end
    -- Force RealSupportFPS: all 9 levels enabled (incl. 165)
    local RealSupportFPS = {}
    for i = 1, 9 do RealSupportFPS[i] = { true, true } end
    pcall(function()
      if GraphicSettingDB.UpdateUIData then
        GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, RealSupportFPS, false)
      end
    end)
    -- Patch any loaded GSC_FPS component so GetMaxFPSLevel always returns 9,9
    local GSC = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS"]
      or _G.GetModule("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
    if GSC then
      GSC.GetMaxFPSLevel = function() return 9, 9 end
      GSC.InitRealSupportFPS = function(self)
        local RealSupportFPS2 = {}
        for i = 1, 9 do RealSupportFPS2[i] = { true, true } end
        pcall(function()
          if GraphicSettingDB.UpdateUIData then
            GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, RealSupportFPS2, false)
          end
        end)
        local itemRoot = self and self.UIRoot
        if itemRoot then
          local nodes = {
            [2]="NodeFps20",[3]="NodeFps25",[4]="NodeFps30",[5]="NodeFps40",
            [6]="NodeFps60",[7]="NodeFps90",[8]="NodeFps120",[9]="NodeFps165"
          }
          for level, node in pairs(nodes) do
            if itemRoot[node] then pcall(function() itemRoot[node]:SetIsEnabled(true) end) end
          end
        end
        return RealSupportFPS2
      end
      -- Skip expand / 120 confirm popups so selection applies immediately
      GSC.Change120FPSConfirm = function(self, okCallback, cancelCallback)
        if okCallback then okCallback() end
      end
      GSC.ClickExpandFPSConfirm = function(self, okCallback, cancelCallback)
        if okCallback then okCallback() end
      end
    end
    _G.FPSState.GSCHooked = true
  end)
end


-- ====================================================================
-- NO GRASS / NO FOG / NO TREES  [from NO_GRASS_AND_NO_FOG_AND_NO_TREES.lua]
-- ====================================================================
_G.ApplyNoGrassFogTrees = function()
  _G.Safe("no_grass_fog_trees", function()
    local Kismet = import("KismetSystemLibrary")
    if not Kismet then return end

    -- FOG
    if _G.LexusConfig.RemoveFog then
      Kismet.ExecuteConsoleCommand(nil, "r.Fog 0", nil)
      Kismet.ExecuteConsoleCommand(nil, "r.Atmosphere 0", nil)
      Kismet.ExecuteConsoleCommand(nil, "r.VolumetricFog 0", nil)
      Kismet.ExecuteConsoleCommand(nil, "ShowFlag.Fog 0", nil)
    else
      Kismet.ExecuteConsoleCommand(nil, "r.Fog 1", nil)
      Kismet.ExecuteConsoleCommand(nil, "r.Atmosphere 1", nil)
      Kismet.ExecuteConsoleCommand(nil, "r.VolumetricFog 1", nil)
    end

    -- GRASS
    if _G.LexusConfig.RemoveGrass then
      Kismet.ExecuteConsoleCommand(nil, "grass.densityScale 0", nil)
      Kismet.ExecuteConsoleCommand(nil, "foliage.DensityScale 0", nil)
      Kismet.ExecuteConsoleCommand(nil, "foliage.LODDistanceScale 0.01", nil)
      Kismet.ExecuteConsoleCommand(nil, "r.LandscapeLODBias -1", nil)
    else
      Kismet.ExecuteConsoleCommand(nil, "grass.densityScale 1", nil)
      Kismet.ExecuteConsoleCommand(nil, "foliage.DensityScale 1", nil)
      Kismet.ExecuteConsoleCommand(nil, "foliage.LODDistanceScale 1", nil)
    end

    -- TREES
    if _G.LexusConfig.RemoveTrees then
      Kismet.ExecuteConsoleCommand(nil, "foliage.MinimumScreenSize 10", nil)
      Kismet.ExecuteConsoleCommand(nil, "r.ForceLOD 4", nil)
    else
      Kismet.ExecuteConsoleCommand(nil, "foliage.MinimumScreenSize 0.0001", nil)
      Kismet.ExecuteConsoleCommand(nil, "r.ForceLOD -1", nil)
    end

    -- BLACK SKY
    if _G.LexusConfig.BlackSky then
      Kismet.ExecuteConsoleCommand(nil, "r.SkyAtmosphere 0", nil)
      Kismet.ExecuteConsoleCommand(nil, "r.SkyLight 0", nil)
    else
      Kismet.ExecuteConsoleCommand(nil, "r.SkyAtmosphere 1", nil)
      Kismet.ExecuteConsoleCommand(nil, "r.SkyLight 1", nil)
    end
  end)
end

-- ====================================================================
-- ESP LOCATION BOX  [from ESP_LOCATION_BOX.lua]
-- ====================================================================
local _ESPBoxBoneList = {
  "head","neck_01","pelvis",
  "upperarm_r","lowerarm_r","hand_r",
  "upperarm_l","lowerarm_l","hand_l",
  "thigh_l","calf_l","foot_l",
  "thigh_r","calf_r","foot_r"
}

_G.ApplyESPLocationBox = function()
  _G.Safe("esp_location_box", function()
    if not _G.LexusConfig.ESPLocationBox then return end
    local GD = _G.getCachedGameplayData()
    if not GD or not GD.GetPlayerController then return end
    local pc = GD.GetPlayerController()
    if not Valid(pc) then return end
    local Me = pc:GetPlayerCharacterSafety()
    if not Valid(Me) then return end

    -- HUD handle
    local HUD = nil
    pcall(function()
      if GD.GetMyHUD then HUD = GD.GetMyHUD() end
    end)
    if not HUD then return end

    local allChars = {}
    pcall(function()
      if GD.GetAllPlayerCharacters then allChars = GD.GetAllPlayerCharacters()
      elseif GD.GameCharacters then for _, c in pairs(GD.GameCharacters) do table.insert(allChars, c) end end
    end)

    for _, Enemy in pairs(allChars) do
      if Valid(Enemy) and Enemy ~= Me and Enemy.TeamID ~= Me.TeamID then
        local dead = false
        pcall(function()
          if type(Enemy.IsDead) == "function" then dead = Enemy:IsDead()
          elseif Enemy.bIsDead ~= nil then dead = Enemy.bIsDead end
          if Enemy.HealthStatus == 2 then dead = true end
        end)
        if not dead then
          local Dist = 0
          pcall(function() Dist = Me:GetDistanceTo(Enemy) / 100 end)
          if Dist > 400 then goto _espbox_continue end

          local Mesh = Enemy.Mesh
          local BaseLoc = nil
          pcall(function() BaseLoc = Enemy:K2_GetActorLocation() end)
          if not (Mesh and BaseLoc) then goto _espbox_continue end

          -- head marker (red box symbol)
          pcall(function()
            local Head = Mesh:GetSocketLocation("head")
            if Head then
              local Off = {X=Head.X-BaseLoc.X, Y=Head.Y-BaseLoc.Y, Z=Head.Z-BaseLoc.Z}
              HUD:AddDebugText("■", Enemy, 0.06, Off, Off,
                {R=255,G=0,B=0,A=255}, true, false, true, nil, 0.55, true)
            end
          end)

          -- bone dots
          for _, Bone in ipairs(_ESPBoxBoneList) do
            pcall(function()
              local Loc = Mesh:GetSocketLocation(Bone)
              if Loc then
                local Off = {X=Loc.X-BaseLoc.X, Y=Loc.Y-BaseLoc.Y, Z=Loc.Z-BaseLoc.Z}
                local Col = (Bone=="head") and {R=255,G=0,B=0,A=255}
                         or (Bone=="pelvis") and {R=255,G=255,B=0,A=255}
                         or {R=0,G=255,B=255,A=255}
                HUD:AddDebugText("▪", Enemy, 0.06, Off, Off,
                  Col, true, false, true, nil, 0.28, true)
              end
            end)
          end

          -- distance text
          pcall(function()
            local DistText = string.format("[%dm]", math.floor(Dist))
            HUD:AddDebugText(DistText, Enemy, 0.06,
              {X=0,Y=115,Z=20}, {X=0,Y=115,Z=20},
              {R=0,G=200,B=255,A=255}, true, false, true, nil, 0.9, true)
          end)

          ::_espbox_continue::
        end
      end
    end
  end)
end

_G.ApplyWeaponGlow = function(PlayerCharacter)
  pcall(function()
    if not PlayerCharacter or not slua.isValid(PlayerCharacter) then return end
    local WeaponManager = nil
    pcall(function() WeaponManager = PlayerCharacter:GetWeaponManager() end)
    if not WeaponManager or not slua.isValid(WeaponManager) then return end
    local isGlowEnabled = _G.LexusConfig and _G.LexusConfig.WeaponGlow
    local LC = nil
    pcall(function() LC = import("LinearColor") or _G.FLinearColor end)
    local glowIntensity = 80.0
    local CT = _G.LexusState and _G.LexusState.CustomTextData or {}
    local thickness = CT.WeaponGlowThickness or 3
    local colorMode = CT.WeaponGlowColor or 5
    local r, g, b = 1.0, 1.0, 0.0
    if colorMode == 1 then r, g, b = 1.0, 0.0, 0.0
    elseif colorMode == 2 then r, g, b = 0.0, 1.0, 0.0
    elseif colorMode == 3 then r, g, b = 0.0, 0.0, 1.0
    elseif colorMode == 4 then r, g, b = 1.0, 1.0, 0.0
    elseif colorMode == 5 then
      local time = os.clock() * 2.0
      r = (math.sin(time) + 1) / 2
      g = (math.sin(time + 2) + 1) / 2
      b = (math.sin(time + 4) + 1) / 2
    end
    local finalColor = LC and LC(r * glowIntensity, g * glowIntensity, b * glowIntensity, 1.0)
      or { R = r * 255, G = g * 255, B = b * 255, A = 255 }
    for slot = 1, 3 do
      local Weapon = nil
      pcall(function() Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot) end)
      if not Weapon or not slua.isValid(Weapon) then goto cont end
      local components = nil
      pcall(function()
        local MeshClass = import("/Script/Engine.MeshComponent")
        if MeshClass and Weapon.GetComponentsByClass then
          components = Weapon:GetComponentsByClass(MeshClass)
        end
      end)
      if not components then
        pcall(function()
          if Weapon.Mesh then components = { Weapon.Mesh } end
        end)
      end
      if not components then goto cont end
      local count = 0
      pcall(function()
        count = type(components.Num) == "function" and components:Num() or #components
      end)
      for i = 0, math.max(count - 1, 0) do
        local comp = nil
        pcall(function()
          if type(components.Get) == "function" then comp = components:Get(i)
          else comp = components[i + 1] end
        end)
        if not comp or not slua.isValid(comp) then goto c2 end
        if isGlowEnabled then
          pcall(function()
            comp.UseScopeDistanceCulling = false
            if comp.SetDrawIdeaOutline then comp:SetDrawIdeaOutline(true) end
            if comp.SetIdeaOutlineColor then comp:SetIdeaOutlineColor(finalColor) end
            if comp.OverrideIdeaOutlineThickness then
              pcall(function() comp:OverrideIdeaOutlineThickness(true, thickness) end)
              pcall(function() comp:OverrideIdeaOutlineThickness(thickness) end)
            end
            if comp.SetDrawHighlight then comp:SetDrawHighlight(true) end
            if comp.OverrideHighlightColor then comp:OverrideHighlightColor(finalColor) end
            if comp.SetRenderCustomDepth then comp:SetRenderCustomDepth(true) end
            if comp.SetCustomDepthStencilValue then comp:SetCustomDepthStencilValue(250) end
          end)
        else
          pcall(function()
            if comp.SetDrawIdeaOutline then comp:SetDrawIdeaOutline(false) end
            if comp.SetDrawHighlight then comp:SetDrawHighlight(false) end
          end)
        end
        ::c2::
      end
      ::cont::
    end
  end)
end

_G.ApplyFPSLimit = function()
  _G.Safe("fps_unlock", function()
    _G.ForceGSCFPSSupport()
    local target = math.max(30, math.min(165, _G.LexusConfig.FPSLimit or 165))
    if not _G.LexusConfig.UnlockFPS then
      if _G.FPSState.WasEnabled then
        pcall(function()
          local KSL = import("KismetSystemLibrary")
          local world = slua.getWorld()
          if KSL and world then
            KSL.ExecuteConsoleCommand(world, "t.MaxFPS 60")
            KSL.ExecuteConsoleCommand(world, "r.FrameRateLimit 60")
          end
          local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
          if gi and gi.ExecuteCMD then
            gi:ExecuteCMD("t.MaxFPS", "60")
            gi:ExecuteCMD("r.FrameRateLimit", "60")
          end
        end)
        _G.FPSState.WasEnabled = false
        _G.FPSState.LastApplied = 0
      end
      return
    end
    -- re-apply every ~1s so game / settings UI cannot clamp it back
    local now = os.clock()
    if _G.FPSState.LastApplied == target and _G.FPSState._LastForceTime and (now - _G.FPSState._LastForceTime) < 1.0 then
      return
    end
    _G.FPSState.LastApplied = target
    _G.FPSState.WasEnabled = true
    _G.FPSState._LastForceTime = now
    local tstr = tostring(target)
    pcall(function()
      local KSL = import("KismetSystemLibrary")
      local world = slua.getWorld()
      if KSL and world then
        KSL.ExecuteConsoleCommand(world, "t.MaxFPS " .. tstr)
        KSL.ExecuteConsoleCommand(world, "r.FrameRateLimit " .. tstr)
        KSL.ExecuteConsoleCommand(world, "r.MobileHFRLevel 3")
        KSL.ExecuteConsoleCommand(world, "r.MobileHUDUseHFR 1")
        KSL.ExecuteConsoleCommand(world, "t.UncapFPS 1")
      end
    end)
    pcall(function()
      local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
      if gi and gi.ExecuteCMD then
        gi:ExecuteCMD("t.MaxFPS", tstr)
        gi:ExecuteCMD("r.FrameRateLimit", tstr)
      end
    end)
    -- keep GraphicSettingDB SelectedFPS in sync when possible
    pcall(function()
      local GraphicSettingDB = package.loaded["client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"]
        or _G.GetModule("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
      if not GraphicSettingDB then return end
      local levelMap = { [15]=1,[20]=2,[25]=3,[30]=4,[40]=5,[60]=6,[90]=7,[120]=8,[165]=9 }
      local lvl = levelMap[target] or 9
      if GraphicSettingDB.UpdateSelectedFPS then GraphicSettingDB:UpdateSelectedFPS(lvl) end
    end)
  end)
end

-- ====================================================================
-- iPad View — force FOV on every relevant camera path every tick
-- Game resets FOV from settings; single lerp was not enough.
-- ====================================================================
_G.IpadViewState = _G.IpadViewState or { LastApplied = 0, WasEnabled = false }

local function _SetCamFOV(cam, target)
  if not Valid(cam) then return end
  pcall(function()
    if cam.FieldOfView ~= nil then cam.FieldOfView = target end
    if type(cam.SetFieldOfView) == "function" then cam:SetFieldOfView(target) end
  end)
end

_G.ApplyIpadView = function()
  _G.Safe("ipadview", function()
    local GD = _G.getCachedGameplayData()
    if not GD or not GD.GetPlayerController then return end
    local pc = GD.GetPlayerController()
    if not Valid(pc) then return end
    local lp = nil
    pcall(function() lp = pc:GetPlayerCharacterSafety() end)
    if not Valid(lp) then pcall(function() lp = pc:GetPawn() end) end
    if not Valid(lp) then return end

    local target = 90
    if _G.LexusConfig.IpadView then
      -- ASHI path: prefer CustomTextData.IpadViewFOV if present
      local fovSrc = tonumber(_G.LexusConfig.IpadViewFOV)
      if _G.LexusState and _G.LexusState.CustomTextData and _G.LexusState.CustomTextData.IpadViewFOV then
        fovSrc = tonumber(_G.LexusState.CustomTextData.IpadViewFOV) or fovSrc
      end
      target = math.max(60, math.min(170, fovSrc or 120))
      _G.IpadViewState.WasEnabled = true
      _G.IpadViewState.LastApplied = target
    else
      if not _G.IpadViewState.WasEnabled then return end
      target = 90
      -- after restore settles, stop forcing
      local settled = false
      pcall(function()
        local cam = lp.ThirdPersonCameraComponent
        if Valid(cam) and cam.FieldOfView and math.abs((cam.FieldOfView or 90) - 90) < 0.5 then settled = true end
      end)
      if settled then _G.IpadViewState.WasEnabled = false; return end
    end

    -- Character third / first person cameras
    pcall(function() _SetCamFOV(lp.ThirdPersonCameraComponent, target) end)
    pcall(function() _SetCamFOV(lp.FirstPersonCameraComponent, target) end)
    pcall(function() _SetCamFOV(lp.Camera, target) end)
    pcall(function() _SetCamFOV(lp.FollowCamera, target) end)

    -- PlayerCameraManager (authoritative for many modes)
    pcall(function()
      local GS = import("GameplayStatics")
      if GS and GS.GetPlayerCameraManager then
        local cm = GS.GetPlayerCameraManager(pc, 0)
        if Valid(cm) then
          if cm.DefaultFOV ~= nil then cm.DefaultFOV = target end
          if type(cm.SetFOV) == "function" then cm:SetFOV(target) end
          if cm.LockedFOV ~= nil then cm.LockedFOV = target end
          _SetCamFOV(cm, target)
        end
      end
    end)
    pcall(function()
      if pc.PlayerCameraManager and Valid(pc.PlayerCameraManager) then
        local cm = pc.PlayerCameraManager
        if cm.DefaultFOV ~= nil then cm.DefaultFOV = target end
        if type(cm.SetFOV) == "function" then cm:SetFOV(target) end
      end
    end)

    -- Console FOV as extra pressure (some builds honor this)
    pcall(function()
      local KSL = import("KismetSystemLibrary")
      local world = slua.getWorld()
      if KSL and world then
        KSL.ExecuteConsoleCommand(world, "fov " .. tostring(target))
      end
    end)
  end)
end


-- ====================================================================
-- SKIN CORE (from ASHIxSKINS) + SkinBypass + SkinSystem
-- ====================================================================
_G.WeaponSkinMap = _G.WeaponSkinMap or {}
_G.VehicleSkinMap = _G.VehicleSkinMap or {}
_G.OutfitMap = _G.OutfitMap or {}
_G.skinIdCache = _G.skinIdCache or {}
_G.skinIdCache2 = _G.skinIdCache2 or {}

_G.OutfitSkins = {
    Suit = {
        1405628,
        1407920,
        1407916,
        1407895,
        1405760,
        1407870,
        1407856,
        1407812,
        1407758,
        1407789,
        1407682,
        1407696,
        1407695,
        1407632,
        1407631,
        1407667,
        1407618,
        1407573,
        1407572,
        1407559,
        1407558,
        1407550,
        1407523,
        1407718,
        1407512,
        1407471,
        1407470,
        1406985,
        1407353,
        1407366,
        1407330,
        1407487,
        1410668,
        1407276,
        1407275,
        1407142,
        1407141,
        1407140,
        1406971,
        1406897,
        1406891,
        1407187,
        1405802,
        1405192,
        1405334,
        1400687,
        1405340,
        1405623,
        1405132,
        1405436,
        1405435,
        1405434,
        1405433,
        1405208,
        1407916,
        1407917,
        1407918,
        1407921,
        1407921,
        1407926,
        1407901,
        1407902,
        1407903,
        1407904,
        1407822,
        1407823,
        1407824,
        1407825,
        1407807,
        1407808,
        1407845,
        1407846,
        1407847,
        1407848,
        1407794,
        1411037,
        1407795,
        1411038,
        1407796,
        1411039
    },
    Pants = {
        1404002,
        1404050,
        1404425,
        1404495,
        1400650,
        1404522,
        1404441,
        1404152,
        1404196,
        1404134,
        1404137,
        1404164,
        1404191,
        1404466,
        1400052,
        404035,
        1404181,
        404084,
        1404516
    },
    Hair = {
        40605010,
        40605011,
        40605012,
        1410480,
        1410085,
        1410299,
        1402834,
        441400152,
        1400150,
        1402582,
        1410289,
        1402218,
        1402223,
        1402283,
        1400426
    },
    Bag = {
        { 501001, 501002, 501003 },
        { 1501001174, 1501002174, 1501003174 },
        { 1501001220, 1501002220, 1501003220 },
        { 1501001051, 1501002051, 1501003051 },
        { 1501001443, 1501002443, 1501003443 },
        { 1501001265, 1501002265, 1501003265 },
        { 1501001321, 1501002321, 1501003321 },
        { 1501001277, 1501002277, 1501003277 },
        { 1501001550, 1501002550, 1501003550 },
        { 1501001592, 1501002592, 1501003592 },
        { 1501001608, 1501002608, 1501003608 },
        { 1501001024, 1501002024, 1501003024 },
        { 1501001019, 1501002019, 1501003019 },
        { 1501001179, 1501002179, 1501003179 },
        { 1501001194, 1501002194, 1501003194 },
        { 1501001346, 1501002346, 1501003346 }
    },
    Helmet = {
        { 502001, 502002, 502003 },
        { 1502001014, 1502002014, 1502003014 },
        { 1502001349, 1502002349, 1502003349 },
        { 1502001012, 1502002012, 1502003012 },
        { 1502001009, 1502002009, 1502003009 },
        { 1502001397, 1502002397, 1502003397 },
        { 1502001390, 1502002390, 1502003390 },
        { 1502001381, 1502002381, 1502003381 },
        { 1502001358, 1502002358, 1502003358 },
        { 1502001350, 1502002350, 1502003350 },
        { 1502001342, 1502002342, 1502003342 }
    },
    Pet = { 50000, 50001, 50002, 50003, 50004, 50005, 50006, 50021, 50022, 50038, 50039, 50040 }
}

_G.VIP_Attachments = {
    [1101004236] = {
        1010042307,
        1010042306,
        1010042308,
        1010042304,
        1010042300,
        1010042305,
        1010042299,
        1010042298,
        1010042297,
        1010042296,
        1010042295,
        1010042294,
        0,
        1010042314,
        1010042309,
        1010042316,
        1010042317,
        1010042318,
        1010042310,
        1010042315,
        1010042319,
        0
    },
    [1101001116] = {
        1010011106,
        1010011107,
        1010011108,
        0,
        1010011109,
        1010011112,
        1010011105,
        1010011104,
        1010011103,
        0,
        1010011102,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1101001128] = {
        1010011232,
        1010011233,
        1010011234,
        1010011228,
        1010011227,
        1010011229,
        1010011226,
        1010011225,
        1010011224,
        1010011223,
        1010011222,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1101001154] = {
        1010011487,
        1010011488,
        1010011489,
        1010011493,
        1010011490,
        1010011494,
        1010011486,
        1010011485,
        1010011484,
        1010011483,
        1010011482,
        1010011497,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1010011498,
        0
    },
    [1101001174] = {
        1010011667,
        1010011668,
        1010011669,
        1010011673,
        1010011670,
        1010011674,
        1010011666,
        1010011665,
        1010011664,
        1010011663,
        1010011662,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1101001213] = {
        1010012067,
        1010012068,
        1010012069,
        1010012072,
        1010012070,
        1010012073,
        1010012066,
        1010012065,
        1010012064,
        1010012063,
        1010012062,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1010012074,
        0
    },
    [1101001231] = {
        1010012267,
        1010012268,
        1010012269,
        1010012273,
        1010012272,
        1010012274,
        1010012266,
        1010012265,
        1010012264,
        1010012263,
        1010012262,
        1010012075,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1010012275,
        0
    },
    [1101001242] = {
        1010012357,
        1010012358,
        1010012359,
        1010012363,
        1010012362,
        1010012364,
        1010012356,
        1010012355,
        1010012354,
        1010012353,
        1010012352,
        1010012276,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1010012365,
        0
    },
    [1101001249] = {
        1010012437,
        1010012438,
        1010012439,
        1010012443,
        1010012442,
        1010012444,
        1010012436,
        1010012435,
        1010012434,
        1010012433,
        1010012432,
        1010012366,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1010012445,
        0
    },
    [1101001256] = {
        1010012588,
        1010012589,
        1010012590,
        1010012593,
        1010012592,
        1010012594,
        1010012587,
        1010012586,
        1010012585,
        1010012584,
        1010012583,
        1010012582,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1010012595,
        0
    },
    [1101001265] = {
        1010012698,
        1010012699,
        1010012700,
        1010012703,
        1010012702,
        1010012704,
        1010012697,
        1010012696,
        1010012695,
        1010012694,
        1010012693,
        1010012692,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1010012705,
        0
    },
    [1101001276] = {
        1010012698,
        1010012699,
        1010012700,
        1010012703,
        1010012702,
        1010012704,
        1010012697,
        1010012696,
        1010012695,
        1010012694,
        1010012693,
        1010012692,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1010012705,
        0
    },
    [1101002029] = {
        1010020249,
        1010020250,
        1010020255,
        1010020247,
        1010020246,
        1010020248,
        1010020240,
        1010020239,
        1010020238,
        1010020237,
        1010020236,
        1010020235,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1010020257,
        1010020256,
        1010020258
    },
    [1101002056] = {
        1010020519,
        0,
        0,
        1010020517,
        1010020516,
        1010020518,
        1010020500,
        1010020509,
        1010020508,
        1010020507,
        1010020506,
        1010020505,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1101002081] = {
        1010020768,
        1010020769,
        1010020770,
        1010020766,
        1010020760,
        1010020767,
        1010020759,
        1010020758,
        1010020757,
        1010020756,
        1010020755,
        1010020776,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1010020775,
        1010020777,
        1010020778
    },
    [1101003070] = {
        1010030654,
        1010030653,
        1010030655,
        1010030649,
        1010030648,
        1010030650,
        1010030647,
        1010030646,
        1010030645,
        1010030644,
        1010030643,
        1010030642,
        0,
        1010030658,
        1010030656,
        1010030660,
        1010030662,
        1010030659,
        1010030657,
        0,
        1010030663,
        0
    },
    [1101003080] = {
        1010030754,
        1010030753,
        1010030755,
        1010030749,
        1010030748,
        1010030750,
        1010030747,
        1010030746,
        1010030745,
        1010030744,
        1010030743,
        1010030742,
        0,
        1010030758,
        1010030756,
        1010030760,
        1010030762,
        1010030759,
        1010030757,
        0,
        1010030763,
        0
    },
    [1101003099] = {
        1010030943,
        1010030944,
        1010030945,
        1010030939,
        1010030938,
        1010030942,
        1010030937,
        1010030936,
        1010030935,
        1010030934,
        1010030933,
        1010030932,
        0,
        1010030947,
        1010030946,
        1010030948,
        1010030949,
        1010030953,
        1010030952,
        0,
        1010030955,
        0
    },
    [1101003119] = {
        1010031139,
        1010031140,
        1010031142,
        1010031138,
        1010031137,
        1010031146,
        1010031136,
        1010031135,
        1010031134,
        1010031133,
        1010031132,
        0,
        0,
        1010031144,
        1010031143,
        0,
        0,
        0,
        1010031145,
        0,
        0,
        0
    },
    [1101003146] = {
        1010031229,
        1010031230,
        1010031237,
        1010031228,
        1010031227,
        1010031242,
        1010031226,
        1010031225,
        1010031224,
        1010031223,
        1010031222,
        0,
        0,
        1010031239,
        1010031238,
        0,
        0,
        0,
        1010031240,
        0,
        0,
        0
    },
    [1101003167] = {
        1010031609,
        1010031610,
        1010031613,
        1010031608,
        1010031607,
        1010031617,
        1010031606,
        1010031605,
        1010031604,
        1010031603,
        1010031602,
        1010031618,
        0,
        1010031615,
        1010031614,
        1010031620,
        1010031622,
        1010031619,
        1010031616,
        0,
        1010031623,
        0
    },
    [1101003181] = {
        1010031765,
        1010031764,
        1010031766,
        1010031759,
        1010031758,
        1010031763,
        1010031757,
        1010031756,
        1010031755,
        1010031754,
        1010031753,
        1010031752,
        0,
        1010031769,
        1010031767,
        1010031773,
        1010031774,
        1010031772,
        1010031768,
        0,
        1010031775,
        0
    },
    [1101003195] = {
        1010031912,
        1010031911,
        1010031913,
        1010031908,
        1010031907,
        1010031909,
        1010031906,
        1010031905,
        1010031904,
        1010031903,
        1010031902,
        1010031901,
        0,
        1010031916,
        1010031914,
        1010031918,
        1010031919,
        1010031917,
        1010031915,
        0,
        1010031921,
        0
    },
    [1101003208] = {
        1010032034,
        1010032033,
        1010032045,
        1010032029,
        1010032028,
        1010032032,
        1010032027,
        1010032026,
        1010032025,
        1010032024,
        1010032023,
        1010032022,
        0,
        1010032038,
        1010032036,
        1010032042,
        1010032043,
        1010032039,
        1010032037,
        0,
        1010032044,
        0
    },
    [1101004046] = {
        1010040474,
        1010040475,
        1010040476,
        1010040472,
        1010040471,
        1010040473,
        1010040470,
        1010040469,
        1010040468,
        1010040467,
        1010040466,
        1010040481,
        0,
        1010040479,
        1010040477,
        1010040482,
        1010040483,
        1010040484,
        1010040478,
        1010040480,
        1010040485,
        0
    },
    [1101004062] = {
        1010040578,
        1010040577,
        1010040579,
        1010040575,
        1010040570,
        1010040576,
        1010040569,
        1010040568,
        1010040567,
        1010040566,
        1010040565,
        1010040564,
        0,
        1010040585,
        1010040580,
        1010040587,
        1010040588,
        1010040589,
        1010040584,
        1010040586,
        1010040590,
        1010040594
    },
    [1101004098] = {
        1010040924,
        1010040926,
        1010040925,
        0,
        1010040937,
        1010040938,
        1010040935,
        1010040934,
        1010040929,
        1010040928,
        1010040927,
        0,
        0,
        1010040939,
        1010040945,
        0,
        0,
        0,
        1010040944,
        1010040936,
        0,
        0
    },
    [1101004138] = {
        1010041136,
        1010041137,
        1010041138,
        1010041134,
        1010041129,
        1010041135,
        1010041128,
        1010041127,
        1010041126,
        1010041125,
        1010041124,
        0,
        0,
        1010041145,
        1010041139,
        0,
        0,
        0,
        1010041144,
        1010041146,
        0,
        0
    },
    [1101004163] = {
        1010041570,
        1010041574,
        1010041575,
        1010041568,
        1010041567,
        1010041569,
        1010041566,
        1010041565,
        1010041564,
        1010041560,
        1010041554,
        0,
        0,
        1010041578,
        1010041576,
        0,
        0,
        0,
        1010041577,
        1010041579,
        0,
        0
    },
    [1101004201] = {
        1010041956,
        1010041957,
        1010041958,
        1010041950,
        1010041949,
        1010041955,
        1010041948,
        1010041947,
        1010041946,
        1010041945,
        1010041944,
        1010041967,
        0,
        1010041965,
        1010041959,
        0,
        0,
        0,
        1010041960,
        1010041966,
        0,
        0
    },
    [1101004209] = {
        1010042038,
        1010042037,
        1010042039,
        1010042035,
        1010042034,
        1010042036,
        1010042029,
        1010042028,
        1010042027,
        1010042026,
        1010042025,
        1010042024,
        0,
        1010042046,
        1010042044,
        1010042048,
        1010042049,
        1010042054,
        1010042045,
        1010042047,
        1010042055,
        0
    },
    [1101004218] = {
        1010042128,
        1010042127,
        1010042129,
        1010042125,
        1010042124,
        1010042126,
        1010042119,
        1010042118,
        1010042117,
        1010042116,
        1010042115,
        1010042114,
        0,
        1010042136,
        1010042134,
        1010042138,
        1010042139,
        1010042144,
        1010042135,
        1010042137,
        1010042145,
        0
    },
    [1101004226] = {
        1010042238,
        1010042237,
        1010042239,
        1010042235,
        1010042234,
        1010042236,
        1010042233,
        1010042232,
        1010042231,
        1010042219,
        1010042218,
        1010042217,
        0,
        1010042243,
        1010042241,
        1010042245,
        1010042246,
        1010042247,
        1010042242,
        1010042244,
        1010042248,
        0
    },
    [1101004246] = {
        1010042406,
        1010042407,
        1010042408,
        1010042404,
        1010042400,
        1010042405,
        1010042399,
        1010042398,
        1010042397,
        1010042396,
        1010042395,
        1010042394,
        0,
        1010042414,
        1010042409,
        1010042416,
        1010042417,
        1010042418,
        1010042410,
        1010042415,
        1010042419,
        1010042420
    },
    [1101005038] = {
        0,
        0,
        1010050327,
        1010050329,
        1010050328,
        1010050330,
        1010050326,
        1010050325,
        1010050324,
        1010050323,
        1010050322,
        1010050334,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1101005052] = {
        0,
        0,
        1010050467,
        1010050469,
        1010050468,
        1010050470,
        1010050466,
        1010050465,
        1010050464,
        1010050463,
        1010050462,
        1010050473,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1101005098] = {
        0,
        0,
        1010050928,
        1010050930,
        1010050929,
        1010050932,
        1010050927,
        1010050926,
        1010050925,
        1010050924,
        1010050923,
        1010050922,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1101006062] = {
        1010060573,
        1010060572,
        1010060574,
        1010060564,
        1010060563,
        1010060571,
        1010060562,
        1010060561,
        1010060554,
        1010060553,
        1010060552,
        1010060551,
        0,
        1010060583,
        1010060581,
        1010060591,
        1010060592,
        1010060584,
        1010060582,
        0,
        1010060593,
        0
    },
    [1101006075] = {
        1010060702,
        1010060701,
        1010060703,
        1010060698,
        1010060697,
        1010060699,
        1010060696,
        1010060695,
        1010060694,
        1010060693,
        1010060692,
        1010060691,
        0,
        1010060706,
        1010060704,
        1010060708,
        1010060709,
        1010060707,
        1010060705,
        0,
        1010060711,
        0
    },
    [1101006085] = {
        1010060796,
        1010060795,
        1010060797,
        1010060793,
        1010060789,
        1010060794,
        1010060788,
        1010060787,
        1010060786,
        1010060785,
        1010060784,
        1010060783,
        0,
        1010060800,
        1010060798,
        1010060804,
        1010060805,
        1010060803,
        1010060799,
        0,
        1010060806,
        0
    },
    [1101007046] = {
        1010070410,
        1010070413,
        1010070414,
        1010070408,
        1010070407,
        1010070409,
        1010070406,
        1010070405,
        1010070404,
        1010070403,
        1010070402,
        1010070418,
        0,
        1010070417,
        1010070415,
        1010070420,
        1010070422,
        1010070419,
        1010070416,
        0,
        1010070423,
        0
    },
    [1101007062] = {
        1010070579,
        1010070578,
        1010070581,
        1010070576,
        1010070575,
        1010070577,
        1010070574,
        1010070573,
        1010070572,
        1010070571,
        1010070569,
        1010070568,
        0,
        1010070584,
        1010070582,
        1010070585,
        1010070586,
        1010070587,
        1010070583,
        0,
        1010070588,
        0
    },
    [1101007071] = {
        1010070663,
        1010070662,
        1010070664,
        1010070659,
        1010070658,
        1010070660,
        1010070657,
        1010070656,
        1010070655,
        1010070654,
        1010070653,
        1010070652,
        0,
        1010070667,
        1010070665,
        1010070668,
        1010070669,
        1010070670,
        1010070666,
        0,
        1010070672,
        0
    },
    [1101008051] = {
        1010080463,
        1010080464,
        1010080465,
        1010080459,
        1010080458,
        1010080462,
        1010080457,
        1010080456,
        1010080455,
        1010080454,
        1010080453,
        1010080452,
        0,
        1010080467,
        1010080466,
        1010080468,
        1010080469,
        1010080473,
        1010080472,
        0,
        1010080475,
        0
    },
    [1101008061] = {
        1010080563,
        1010080564,
        1010080565,
        1010080559,
        1010080558,
        1010080562,
        1010080557,
        1010080556,
        1010080555,
        1010080554,
        1010080553,
        0,
        0,
        1010080567,
        1010080566,
        0,
        0,
        0,
        1010080572,
        0,
        0,
        0
    },
    [1101008070] = {
        1010080609,
        1010080612,
        1010080613,
        1010080608,
        1010080607,
        1010080617,
        1010080606,
        1010080605,
        1010080604,
        1010080603,
        1010080602,
        0,
        0,
        1010080615,
        1010080614,
        0,
        0,
        0,
        1010080616,
        0,
        0,
        0
    },
    [1101008081] = {
        1010080740,
        1010080743,
        1010080745,
        1010080738,
        1010080737,
        1010080739,
        1010080736,
        1010080735,
        1010080734,
        1010080733,
        1010080732,
        1010080748,
        0,
        1010080747,
        1010080746,
        1010080750,
        1010080752,
        1010080749,
        1010080744,
        0,
        1010080753,
        0
    },
    [1101008104] = {
        1010080980,
        1010080982,
        1010080984,
        1010080978,
        1010080977,
        1010080979,
        1010080976,
        1010080975,
        1010080974,
        1010080973,
        1010080972,
        1010080992,
        0,
        1010080986,
        1010080985,
        1010080989,
        1010080987,
        1010080993,
        1010080983,
        0,
        1010080988,
        0
    },
    [1101008116] = {
        1010081110,
        1010081112,
        1010081114,
        1010081108,
        1010081107,
        1010081109,
        1010081106,
        1010081105,
        1010081104,
        1010081103,
        1010081102,
        0,
        0,
        1010081116,
        1010081115,
        0,
        0,
        0,
        1010081113,
        0,
        0,
        0
    },
    [1101008126] = {
        1010081210,
        1010081225,
        1010081226,
        1010081208,
        1010081207,
        1010081209,
        1010081206,
        1010081205,
        1010081204,
        1010081203,
        1010081202,
        1010081218,
        0,
        1010081217,
        1010081216,
        1010081219,
        1010081220,
        1010081222,
        1010081214,
        1010081228,
        1010081227,
        1010081229
    },
    [1101008136] = {
        1010081314,
        1010081315,
        1010081316,
        1010081312,
        1010081308,
        1010081313,
        1010081307,
        1010081306,
        1010081305,
        1010081304,
        1010081303,
        1010081302,
        0,
        1010081318,
        1010081317,
        1010081322,
        1010081323,
        1010081325,
        1010081324,
        0,
        1010081326,
        0
    },
    [1101008146] = {
        1010081401,
        1010081402,
        1010081403,
        1010081398,
        1010081397,
        1010081399,
        1010081396,
        1010081395,
        1010081394,
        1010081393,
        1010081392,
        1010081391,
        0,
        1010081405,
        1010081404,
        1010081406,
        1010081407,
        1010081409,
        1010081408,
        0,
        1010081411,
        0
    },
    [1101008154] = {
        1010081531,
        1010081532,
        1010081533,
        1010081528,
        1010081527,
        1010081529,
        1010081526,
        1010081525,
        1010081524,
        1010081523,
        1010081522,
        1010081521,
        0,
        1010081541,
        1010081534,
        1010081542,
        1010081543,
        1010081545,
        1010081544,
        0,
        1010081546,
        0
    },
    [1101008163] = {
        1010081582,
        1010081583,
        1010081584,
        1010081579,
        1010081578,
        1010081580,
        1010081577,
        1010081576,
        1010081575,
        1010081574,
        1010081573,
        1010081572,
        0,
        1010081586,
        1010081585,
        1010081587,
        1010081588,
        1010081590,
        1010081589,
        0,
        1010081592,
        0
    },
    [1101012033] = {
        1010120284,
        1010120285,
        1010120286,
        1010120280,
        1010120279,
        1010120283,
        1010120278,
        1010120277,
        1010120276,
        1010120275,
        1010120274,
        1010120273,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1010120287,
        0
    },
    [1101100012] = {
        1011000066,
        1011000067,
        1011000068,
        0,
        0,
        0,
        1011000058,
        1011000057,
        1011000056,
        1011000055,
        1011000054,
        1011000053,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1011000073,
        0
    },
    [1101102007] = {
        1011010025,
        1011010024,
        1011010026,
        1011010020,
        1011010019,
        1011010023,
        1011010018,
        1011010017,
        1011010016,
        1011010015,
        1011010014,
        1011010013,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1011010027,
        0
    },
    [1101102017] = {
        1011020027,
        1011020028,
        1011020029,
        1011020025,
        1011020024,
        1011020026,
        1011020019,
        1011020018,
        1011020017,
        1011020016,
        1011020015,
        1011020014,
        0,
        1011020036,
        1011020034,
        1011020038,
        1011020039,
        1011020044,
        1011020035,
        1011020037,
        1011020045,
        1011020047
    },
    [1101102025] = {
        1011020127,
        1011020128,
        1011020129,
        1011020125,
        1011020124,
        1011020126,
        1011020119,
        1011020118,
        1011020117,
        1011020116,
        1011020115,
        1011020114,
        0,
        1011020136,
        1011020134,
        1011020138,
        1011020139,
        1011020144,
        1011020135,
        1011020137,
        1011020145,
        0
    },
    [1101102041] = {
        1011020214,
        1011020215,
        1011020216,
        1011020212,
        1011020211,
        1011020213,
        1011020209,
        1011020208,
        1011020207,
        1011020206,
        1011020205,
        1011020204,
        0,
        1011020219,
        1011020217,
        1011020222,
        1011020223,
        1011020224,
        1011020218,
        1011020221,
        1011020225,
        1011020229
    },
    [1101102049] = {
        1011020356,
        1011020357,
        1011020358,
        1011020354,
        1011020350,
        1011020355,
        1011020349,
        1011020348,
        1011020347,
        1011020346,
        1011020345,
        1011020344,
        0,
        1011020364,
        1011020359,
        1011020366,
        1011020367,
        1011020368,
        1011020360,
        1011020365,
        1011020369,
        1011020370
    },
    [1101101007] = {
        1011020436,
        1011020437,
        1011020438,
        1011020434,
        1011020430,
        1011020435,
        1011020429,
        1011020428,
        1011020427,
        1011020426,
        1011020425,
        1011020424,
        0,
        1011020444,
        1011020439,
        1011020446,
        1011020447,
        1011020448,
        1011020440,
        1011020445,
        1011020449,
        1011020450
    },
    [1102001120] = {
        1020011137,
        1020011138,
        1020011139,
        1020011135,
        1020011134,
        1020011136,
        1020011133,
        1020011132,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1020011142,
        0,
        0
    },
    [1102001130] = {
        1020011247,
        1020011248,
        1020011249,
        1020011245,
        1020011244,
        1020011246,
        1020011243,
        1020011242,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1020011250,
        0,
        0
    },
    [1102002043] = {
        1020020372,
        1020020374,
        1020020373,
        1020020383,
        1020020380,
        1020020384,
        1020020379,
        1020020378,
        1020020377,
        1020020376,
        1020020375,
        1020020388,
        0,
        1020020385,
        1020020387,
        0,
        0,
        0,
        1020020386,
        0,
        0,
        0
    },
    [1102002061] = {
        1020020552,
        1020020554,
        1020020553,
        1020020563,
        1020020562,
        1020020564,
        1020020559,
        1020020558,
        1020020557,
        1020020556,
        1020020555,
        1020020578,
        0,
        1020020565,
        1020020567,
        1020020573,
        1020020574,
        1020020572,
        1020020566,
        0,
        1020020569,
        0
    },
    [1102002136] = {
        1020021314,
        1020021313,
        1020021315,
        1020021309,
        1020021308,
        1020021312,
        1020021307,
        1020021306,
        1020021305,
        1020021304,
        1020021303,
        1020021302,
        0,
        1020021318,
        1020021316,
        1020021323,
        1020021324,
        1020021322,
        1020021317,
        0,
        1020021325,
        0
    },
    [1102002424] = {
        1020024193,
        1020024192,
        1020024194,
        1020024189,
        1020024188,
        1020024190,
        1020024187,
        1020024186,
        1020024185,
        1020024184,
        1020024183,
        1020024182,
        0,
        1020024197,
        1020024195,
        1020024199,
        1020024200,
        1020024198,
        1020024196,
        0,
        1020024202,
        0
    },
    [1102003080] = {
        1020030755,
        1020030756,
        1020030758,
        0,
        1020030749,
        1020030754,
        1020030748,
        1020030747,
        1020030746,
        1020030745,
        1020030744,
        1020030764,
        0,
        1020030760,
        0,
        1020030759,
        1020030757,
        0,
        0,
        1020030765,
        0,
        0
    },
    [1102003100] = {
        1020030956,
        1020030957,
        1020030958,
        1020030954,
        1020030950,
        1020030955,
        1020030949,
        1020030948,
        1020030947,
        1020030946,
        1020030945,
        1020030944,
        0,
        1020030964,
        0,
        1020030960,
        1020030959,
        1020030965,
        0,
        1020030967,
        1020030966,
        1020030968
    },
    [1102005064] = {
        1020050588,
        1020050589,
        1020050590,
        0,
        0,
        0,
        1020050587,
        1020050586,
        1020050585,
        1020050584,
        1020050583,
        1020050582,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1020050592,
        0
    },
    [1103001101] = {
        1030010954,
        1030010955,
        1030010956,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1030010953,
        1030010952,
        1030010951,
        0,
        0,
        0,
        0,
        0,
        0,
        1030010957,
        0,
        1030010958
    },
    [1103001146] = {
        1030011344,
        1030011345,
        1030011346,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1030011343,
        1030011342,
        1030011341,
        0,
        0,
        0,
        0,
        0,
        0,
        1030011347,
        0,
        1030011348
    },
    [1103001154] = {
        1030011484,
        1030011485,
        1030011486,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1030011483,
        1030011482,
        1030011481,
        0,
        0,
        0,
        0,
        0,
        0,
        1030011487,
        0,
        1030011488
    },
    [1103001179] = {
        1030011738,
        1030011739,
        1030011741,
        0,
        0,
        0,
        1030011737,
        1030011736,
        1030011735,
        1030011734,
        1030011733,
        1030011732,
        1030011731,
        0,
        0,
        0,
        0,
        0,
        0,
        1030011742,
        1030011743,
        1030011744
    },
    [1103001191] = {
        1030011858,
        1030011859,
        1030011861,
        0,
        0,
        0,
        1030011857,
        1030011856,
        1030011855,
        1030011854,
        1030011853,
        1030011852,
        1030011851,
        0,
        0,
        0,
        0,
        0,
        0,
        1030011862,
        1030011863,
        1030011864
    },
    [1103001202] = {
        1030011948,
        1030011949,
        1030011950,
        0,
        0,
        0,
        1030011947,
        1030011946,
        1030011945,
        1030011944,
        1030011943,
        1030011942,
        1030011941,
        0,
        0,
        0,
        0,
        0,
        0,
        1030011951,
        1030011952,
        1030011953
    },
    [1103002030] = {
        1030020245,
        1030020246,
        1030020247,
        1030020252,
        1030020249,
        1030020253,
        1030020258,
        1030020257,
        1030020256,
        1030020255,
        1030020244,
        1030020243,
        1030020242,
        0,
        0,
        0,
        0,
        0,
        0,
        1030020248,
        0,
        0
    },
    [1103002059] = {
        1030020544,
        1030020545,
        1030020546,
        1030020542,
        1030020539,
        1030020543,
        1030020538,
        1030020537,
        1030020536,
        1030020535,
        1030020534,
        1030020533,
        1030020532,
        0,
        0,
        0,
        0,
        0,
        0,
        1030020547,
        1030020548,
        0
    },
    [1103002087] = {
        1030020824,
        1030020825,
        1030020826,
        0,
        0,
        0,
        1030020818,
        1030020817,
        1030020816,
        1030020815,
        1030020814,
        1030020813,
        1030020812,
        0,
        0,
        0,
        0,
        0,
        0,
        1030020827,
        1030020828,
        0
    },
    [1103002106] = {
        1030021009,
        1030021010,
        1030021012,
        1030021015,
        1030021014,
        1030021016,
        1030021008,
        1030021007,
        1030021006,
        1030021005,
        1030021004,
        1030021003,
        1030021002,
        0,
        0,
        0,
        0,
        0,
        0,
        1030021013,
        1030021017,
        0
    },
    [1103002113] = {
        1030021079,
        1030021080,
        1030021082,
        1030021085,
        1030021084,
        1030021086,
        1030021078,
        1030021077,
        1030021076,
        1030021075,
        1030021074,
        1030021073,
        1030021072,
        0,
        0,
        0,
        0,
        0,
        0,
        1030021083,
        1030021087,
        0
    },
    [1103003022] = {
        1030030165,
        1030030166,
        1030030167,
        1030030172,
        1030030169,
        1030030173,
        0,
        0,
        0,
        0,
        1030030164,
        1030030163,
        1030030162,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1103003030] = {
        1030030256,
        1030030257,
        1030030258,
        1030030254,
        1030030253,
        1030030255,
        1030030248,
        1030030247,
        1030030246,
        1030030245,
        1030030244,
        1030030243,
        1030030242,
        0,
        0,
        0,
        0,
        0,
        0,
        1030030259,
        1030030249,
        0
    },
    [1103003042] = {
        1030030374,
        1030030375,
        1030030376,
        1030030372,
        1030030369,
        1030030373,
        0,
        0,
        0,
        0,
        1030030364,
        1030030363,
        1030030362,
        0,
        0,
        0,
        0,
        0,
        0,
        1030030377,
        0,
        0
    },
    [1103003051] = {
        1030030458,
        1030030459,
        1030030460,
        1030030456,
        1030030455,
        1030030457,
        0,
        0,
        0,
        0,
        1030030454,
        1030030453,
        1030030452,
        0,
        0,
        0,
        0,
        0,
        0,
        1030030463,
        0,
        0
    },
    [1103003062] = {
        1030030568,
        1030030569,
        1030030570,
        1030030566,
        1030030565,
        1030030567,
        0,
        0,
        0,
        0,
        1030030564,
        1030030563,
        1030030562,
        0,
        0,
        0,
        0,
        0,
        0,
        1030030572,
        0,
        0
    },
    [1103003079] = {
        1030030744,
        1030030745,
        1030030746,
        1030030742,
        1030030740,
        1030030743,
        1030030738,
        1030030737,
        1030030736,
        1030030735,
        1030030734,
        1030030733,
        1030030732,
        0,
        0,
        0,
        0,
        0,
        0,
        1030030747,
        1030030739,
        0
    },
    [1103003087] = {
        1030030825,
        1030030826,
        1030030827,
        1030030823,
        1030030824,
        1030030824,
        1030030818,
        1030030817,
        1030030816,
        1030030815,
        1030030814,
        1030030813,
        1030030812,
        0,
        0,
        0,
        0,
        0,
        0,
        1030030828,
        1030030819,
        0
    },
    [1103004037] = {
        1030040315,
        1030040316,
        1030040317,
        1030040325,
        1030040324,
        1030040323,
        0,
        0,
        0,
        0,
        1030040314,
        1030040313,
        1030040312,
        1030040327,
        1030040326,
        0,
        0,
        0,
        1030040328,
        1030040329,
        0,
        0
    },
    [1103006030] = {
        1030060245,
        1030060246,
        1030060247,
        0,
        1030060253,
        1030060252,
        0,
        0,
        0,
        0,
        1030060244,
        1030060243,
        1030060242,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1103007028] = {
        1030070233,
        1030070234,
        1030070235,
        1030070226,
        1030070225,
        1030070227,
        1030070218,
        1030070217,
        1030070216,
        1030070215,
        1030070214,
        1030070213,
        1030070212,
        0,
        0,
        0,
        0,
        0,
        0,
        1030070236,
        1030070219,
        0
    },
    [1103012010] = {
        0,
        0,
        0,
        0,
        0,
        0,
        1030120038,
        1030120037,
        1030120036,
        1030120035,
        1030120034,
        1030120033,
        1030120032,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1103012019] = {
        0,
        0,
        0,
        0,
        0,
        0,
        1030120138,
        1030120137,
        1030120136,
        1030120135,
        1030120134,
        1030120133,
        1030120132,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1103012031] = {
        0,
        0,
        0,
        0,
        0,
        0,
        1030120258,
        1030120257,
        1030120256,
        1030120255,
        1030120254,
        1030120253,
        1030120252,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1103012039] = {
        0,
        0,
        0,
        0,
        0,
        0,
        1030120339,
        1030120338,
        1030120337,
        1030120336,
        1030120335,
        1030120334,
        1030120333,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    [1103102007] = {
        1031020026,
        1031020027,
        1031020028,
        1031020024,
        1031020023,
        1031020025,
        1031020019,
        1031020018,
        1031020017,
        1031020016,
        1031020015,
        1031020014,
        1031020013,
        0,
        0,
        0,
        0,
        0,
        0,
        1031020029,
        0,
        0
    },
    [1105001034] = {
        0,
        0,
        0,
        0,
        1050010287,
        1050010289,
        1050010286,
        1050010285,
        1050010284,
        1050010283,
        1050010282,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1050010292,
        0,
        0
    },
    [1105001048] = {
        0,
        0,
        0,
        1050010429,
        1050010428,
        1050010434,
        1050010427,
        1050010426,
        1050010425,
        1050010424,
        1050010423,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1050010435,
        0,
        1050010436
    },
    [1105001069] = {
        0,
        0,
        0,
        1050010639,
        1050010638,
        1050010640,
        1050010637,
        1050010636,
        1050010635,
        1050010634,
        1050010633,
        1050010645,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1050010643,
        1050010646,
        1050010644
    },
    [1105002091] = {
        0,
        0,
        0,
        0,
        0,
        0,
        1050020847,
        1050020846,
        1050020845,
        1050020844,
        1050020843,
        1050020842,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1050020848
    },
    [1105010019] = {
        0,
        0,
        0,
        0,
        0,
        0,
        1050100144,
        1050100143,
        1050100142,
        1050100141,
        1050100139,
        1050100138,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    }
}
_G.BaseAttachToIndex = {
    [201010] = 1,
    [201005] = 1,
    [201004] = 1,
    [201009] = 2,
    [201003] = 2,
    [201002] = 2,
    [201011] = 3,
    [201007] = 3,
    [201006] = 3,
    [204012] = 4,
    [204005] = 4,
    [204008] = 4,
    [204011] = 5,
    [204004] = 5,
    [204007] = 5,
    [204013] = 6,
    [204006] = 6,
    [204009] = 6,
    [203001] = 7,
    [203002] = 8,
    [203003] = 9,
    [203014] = 10,
    [203004] = 11,
    [203015] = 12,
    [203005] = 13,
    [202002] = 14,
    [202001] = 15,
    [202004] = 16,
    [202005] = 17,
    [202007] = 18,
    [202006] = 19,
    [205002] = 20,
    [205003] = 20,
    [205001] = 20,
    [203018] = 21,
    [204014] = 22
}
_G.VipAttachToIndex = _G.VipAttachToIndex or {}

_G.skinIdMappings = {
    [101004] = {
        101004,
        1101004246,
        1101004226,
        1101004236,
        1101004062,
        1101004078,
        1101004086,
        1101004201,
        1101004218
    },
    [101001] = {
        101001,
        1101001276,
        1101001089,
        1101001213,
        1101001172,
        1101001127,
        1101001230,
        1101001241
    },
    [101003] = {
        101003,
        1101003227,
        1103003208,
        1101003195,
        1101003187,
        1101003098,
        1101003166,
        1101003218
    },
    [102002] = { 102002, 1102002136, 1102002043, 1102002061, 1102002424 },
    [101008] = {
        101008,
        1101008146,
        1101008154,
        1101008079,
        1101008126,
        1101008104,
        1101008146,
        1101008061,
        1101008116
    },
    [101006] = { 101006, 1101006085, 1101006061, 1101006074, 1101006043, 1101006032, 1101006084 },
    [102001] = { 102001, 1102001120 },
    [101005] = { 101005, 1101005098 },
    [104003] = { 104003, 1104003037 },
    [104004] = { 104004, 1104004035, 1104004041 },
    [101101] = { 101101, 1101101007 },
    [101007] = { 101007, 1101007071, 1101007062, 1101007046, 1101007078, 1101007072 },
    [101012] = { 101012, 1101012033 },
    [101002] = { 101002, 1101002081, 1101002056, 1101002029, 1101002149 },
    [101102] = { 101102, 1101102049, 1101102025, 1101102017, 1101102007, 1101102032 },
    [103001] = {
        103001,
        1103001202,
        1103001191,
        1103001179,
        1103001146,
        1103001101,
        1103001079,
        1103001202
    },
    [103002] = { 103002, 1103002113, 1103002098, 1103002087, 1103002060, 1103002059, 1103002030 },
    [103003] = {
        103003,
        1103003087,
        1103003079,
        1103003069,
        1103003062,
        1103003055,
        1103003051,
        1103003042,
        1103003030,
        1103003022,
        1103003092
    }
}

_G.VehicleSkins = {
    [1961001] = {
        1961151,
        1961152,
        1961153,
        1961147,
        1961148,
        1961149,
        1961144,
        1961145,
        1961137,
        1961138,
        1961139,
        1961066,
        1961067,
        1961065,
        1961062,
        1961063,
        1961064,
        1961054,
        1961055,
        1961056,
        1961057,
        1961051,
        1961052,
        1961053,
        1961048,
        1961049,
        1961050,
        1961044,
        1961045,
        1961046,
        1961047,
        1961041,
        1961042,
        1961043,
        1961038,
        1961039,
        1961040,
        1961033,
        1961034,
        1961035,
        1961029,
        1961030,
        1961031,
        1961032,
        1961007,
        1961010,
        1961012,
        1961013,
        1961014,
        1961015,
        1961140,
        1961141,
        1961142,
        1961143,
        1991023,
        1991024
    },
    [1903001] = {
        1903228,
        1903220,
        1903221,
        1903223,
        1903218,
        1903219,
        1903213,
        1903212,
        1903202,
        1908094,
        1908095,
        1903193,
        1903192,
        1903191,
        19030790,
        19030791,
        19030800,
        19030801,
        1903074,
        1903075,
        1903076,
        1903071,
        1903072,
        1903073,
        1903216,
        1903217,
        1991001,
        1991002,
        1991003,
        1991004,
        1903088,
        1903089,
        1903090,
        1903023
    },
    [1915004] = { 1915021, 1915022, 1915008, 1915009, 1914011 },
    [1908001] = {
        1908108,
        1908109,
        19080951,
        19081080,
        1908084,
        1908085,
        1908075,
        1908077,
        1908078,
        1908070,
        1908069,
        1908066,
        1908086,
        1908088,
        1908089,
        1908018
    },
    [1907002] = {
        1907058,
        1907054,
        1907059,
        1907053,
        1907063,
        1907072,
        1907040,
        1907041,
        1907027,
        1907047,
        1907021
    }
}
_G.CustSlotType = { ClothesEquipemtSlot=5, BackpackEquipemtSlot=8, HelmetEquipemtSlot=9, ParachuteEquipemtSlot=11, GlideEquipemtSlot=15 }

-- ====================================================================
-- SKIN SYSTEM: LOGIC FUNCTIONS
-- ====================================================================
local function DownloadGameItem(id)
    local puffer_manager = require('client.slua.logic.download.puffer.puffer_manager')
    local puffer_const = require('client.slua.logic.download.puffer_const')
    if not puffer_manager or not puffer_const then return end
    local state = puffer_manager.GetState(puffer_const.ENUM_DownloadType.ODPTD, {id})
    if state ~= puffer_const.ENUM_DownloadState.Done and state ~= puffer_const.ENUM_DownloadState.Downloading then
        puffer_manager.Download(puffer_const.ENUM_DownloadType.ODPTD, {id})
    end
end
_G.download_item = DownloadGameItem

_G.get_skin_id = function(weaponID)
    if not weaponID then return nil end
    local targetSkinId = _G.WeaponSkinMap and _G.WeaponSkinMap[weaponID]
    if targetSkinId and targetSkinId > 0 then
        if not _G.skinIdCache2[targetSkinId] then
            if _G.download_item then pcall(_G.download_item, targetSkinId) end
            _G.skinIdCache2[targetSkinId] = true
        end
        return targetSkinId
    end
    return weaponID
end

_G.equip_character_avatar = function(Character)
    if not Character or not slua.isValid(Character) or not Character.AvatarComponent2 then return end
    local BackpackUtils = import("BackpackUtils")
    local SlotSyncData = Character.AvatarComponent2.NetAvatarData and Character.AvatarComponent2.NetAvatarData.SlotSyncData
    if not SlotSyncData or not slua.isValid(SlotSyncData) or not BackpackUtils then return end
    
    local function EquipAvatar(ApplyDataIdx, mappedSkin, ApplyEquipSlot, isLevelDependent, levelFunc)
        if not mappedSkin or mappedSkin == 0 then return end
        local slotData = SlotSyncData:Get(ApplyDataIdx)
        if slotData and slotData.SlotID == ApplyEquipSlot then
            local applyItemId = mappedSkin
            if isLevelDependent and type(mappedSkin) == "table" then
                local level = levelFunc(slotData.AdditionalItemID) or 1
                if level < 1 then level = 1 end
                if level > 3 then level = 3 end
                applyItemId = mappedSkin[level] or mappedSkin[1]
            end

            if not applyItemId or applyItemId == 0 or slotData.ItemId == applyItemId then return end

            if not _G.skinIdCache[applyItemId] then
                if _G.download_item then pcall(_G.download_item, applyItemId) end
                _G.skinIdCache[applyItemId] = true
            end

            slotData.ItemId = applyItemId
            SlotSyncData:Set(ApplyDataIdx, slotData)
            Character.AvatarComponent2:OnRep_BodySlotStateChanged()
        end
    end

    local hasGliderSlot = false
    for i = 0, SlotSyncData:Num() - 1 do
        local slotData = SlotSyncData:Get(i)
        if slotData and slotData.SlotID == _G.CustSlotType.GlideEquipemtSlot then 
            hasGliderSlot = true
            break 
        end
    end
    if not hasGliderSlot then SlotSyncData:Add({ SlotID = _G.CustSlotType.GlideEquipemtSlot, ItemId = 0 }) end

    for i = 0, SlotSyncData:Num() - 1 do
        EquipAvatar(i, _G.OutfitMap.Suit or 0, _G.CustSlotType.ClothesEquipemtSlot, false)
        EquipAvatar(i, _G.OutfitMap.Pants or 0, 6, false)
        EquipAvatar(i, _G.OutfitMap.Hair or 0, 7, false)
        EquipAvatar(i, _G.OutfitMap.Bag, _G.CustSlotType.BackpackEquipemtSlot, true, BackpackUtils.GetEquipmentBagLevel)
        EquipAvatar(i, _G.OutfitMap.Helmet, _G.CustSlotType.HelmetEquipemtSlot, true, BackpackUtils.GetEquipmentHelmetLevel)
        EquipAvatar(i, _G.OutfitMap.Parachute or 0, _G.CustSlotType.ParachuteEquipemtSlot, false)
    end
end

_G.ApplyWeaponSkins = function(PlayerCharacter)
  pcall(function()
    if not PlayerCharacter or not slua.isValid(PlayerCharacter) then return end
    if not (_G.SkinSystem and _G.SkinSystem.Enabled and _G.SkinSystem.Toggle and _G.SkinSystem.Toggle.Weapons) then
      return
    end
    -- rate limit: max once per 0.8s per character to stop mesh glitch/flicker
    local now = os.clock()
    local key = tostring(PlayerCharacter)
    _G._WepSkinLast = _G._WepSkinLast or {}
    if _G._WepSkinLast[key] and (now - _G._WepSkinLast[key]) < 0.8 then return end
    _G._WepSkinLast[key] = now

    local WeaponManager = nil
    pcall(function() WeaponManager = PlayerCharacter:GetWeaponManager() end)
    if not WeaponManager or not slua.isValid(WeaponManager) then return end

    for slot = 1, 3 do
      local Weapon = nil
      pcall(function() Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot) end)
      if not Weapon or not slua.isValid(Weapon) then goto continue end
      if not Weapon.synData or not slua.isValid(Weapon.synData) then goto continue end

      local WeaponID = nil
      pcall(function() WeaponID = Weapon:GetWeaponID() end)
      if not WeaponID then goto continue end

      local SkinID = (_G.get_skin_id and _G.get_skin_id(WeaponID)) or WeaponID
      if not SkinID or SkinID == 0 then goto continue end

      -- pre-download skin + vip attachments to avoid pink/missing mesh
      _G.skinIdCache = _G.skinIdCache or {}
      if not _G.skinIdCache[SkinID] then
        if _G.download_item then pcall(_G.download_item, SkinID) end
        _G.skinIdCache[SkinID] = true
      end
      if SkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[SkinID] then
        for _, att in pairs(_G.VIP_Attachments[SkinID]) do
          if type(att) == "number" and att > 0 and not _G.skinIdCache[att] then
            if _G.download_item then pcall(_G.download_item, att) end
            _G.skinIdCache[att] = true
          end
        end
      end

      local isModified = false
      pcall(function()
        local SkinData = Weapon.synData:Get(7)
        if SkinData and SkinData.defineID and SkinData.defineID.TypeSpecificID ~= SkinID then
          SkinData.defineID.TypeSpecificID = SkinID
          Weapon.synData:Set(7, SkinData)
          if Weapon.SetWeaponAvatarID then pcall(function() Weapon:SetWeaponAvatarID(SkinID) end) end
          isModified = true
        end
      end)

      -- map attachments for mythic skins
      if SkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[SkinID] then
        for AttachIdx = 0, 5 do
          pcall(function()
            local attachData = Weapon.synData:Get(AttachIdx)
            if not attachData then return end
            local defineIDRef = slua.IndexReference(attachData, "defineID")
            if not defineIDRef then return end
            local attachmentId = defineIDRef.TypeSpecificID
            if not attachmentId or attachmentId <= 0 then return end
            local mapIndex = (_G.BaseAttachToIndex and _G.BaseAttachToIndex[attachmentId])
              or (_G.VipAttachToIndex and _G.VipAttachToIndex[attachmentId])
            if not mapIndex then return end
            local targetAttachId = _G.VIP_Attachments[SkinID][mapIndex]
            if targetAttachId and targetAttachId > 0 and targetAttachId ~= attachmentId then
              attachData.defineID.TypeSpecificID = targetAttachId
              Weapon.synData:Set(AttachIdx, attachData)
              isModified = true
            end
          end)
        end
      end

      if isModified then
        pcall(function()
          if Weapon.DelayHandleAvatarMeshChanged then Weapon:DelayHandleAvatarMeshChanged() end
          if Weapon.OnRep_synData then Weapon:OnRep_synData() end
        end)
      end
      ::continue::
    end
  end)
end

_G.ApplyVehicleSkins = function(PlayerCharacter)
  pcall(function()
    if not PlayerCharacter or not slua.isValid(PlayerCharacter) then return end
    local Vehicle = nil
    pcall(function()
      if PlayerCharacter.GetCurrentVehicle then Vehicle = PlayerCharacter:GetCurrentVehicle() end
    end)
    if not Vehicle or not slua.isValid(Vehicle) then
      _G.LastVehicleEntity = nil
      _G.CurrentEquipVehicleID = nil
      return
    end

    local VehicleAvatar = Vehicle.VehicleAvatar or Vehicle.VehicleAvatarComponent_BP
    if not VehicleAvatar and Vehicle.GetAvatarComponent then
      pcall(function() VehicleAvatar = Vehicle:GetAvatarComponent() end)
    end
    if not VehicleAvatar or not slua.isValid(VehicleAvatar) then return end

    local defId, currentId, vType = "", "", 0
    pcall(function()
      if VehicleAvatar.GetDefaultAvatarID then defId = tostring(VehicleAvatar:GetDefaultAvatarID() or "") end
      if Vehicle.GetAvatarId then currentId = tostring(Vehicle:GetAvatarId() or "") end
      if Vehicle.VehicleID then vType = tonumber(Vehicle.VehicleID) or 0 end
      if vType == 0 and Vehicle.GetVehicleType then vType = tonumber(Vehicle:GetVehicleType()) or 0 end
    end)

    local candidates = {}
    for _, s in ipairs({defId, currentId, tostring(vType)}) do
      local n = tonumber(s)
      if n and n > 0 then table.insert(candidates, n) end
      -- also parse embedded digits
      if s and #s > 0 then
        for num in string.gmatch(s, "%d+") do
          local nn = tonumber(num)
          if nn and nn > 1000 then table.insert(candidates, nn) end
        end
      end
    end

    local applySkinId = 0
    local matchedBase = nil
    for _, cid in ipairs(candidates) do
      local base = _G.ResolveVehicleBaseId(cid)
      if base and _G.VehicleSkinMap and _G.VehicleSkinMap[base] then
        local skin = _G.VehicleSkinMap[base]
        if type(skin) == "number" and skin > 0 then
          applySkinId = skin
          matchedBase = base
          break
        end
      end
    end
    -- fallback: scan map with substring
    if applySkinId == 0 and _G.VehicleSkinMap then
      local blob = (defId or "") .. "|" .. (currentId or "") .. "|" .. tostring(vType)
      for baseMapId, targetSkin in pairs(_G.VehicleSkinMap) do
        if type(targetSkin) == "number" and targetSkin > 0 then
          if blob:find(tostring(baseMapId), 1, true) then
            applySkinId = targetSkin
            matchedBase = baseMapId
            break
          end
        end
      end
    end

    if not applySkinId or applySkinId <= 0 then return end

    -- skip only if same vehicle entity AND same skin already applied
    if _G.LastVehicleEntity == Vehicle and _G.CurrentEquipVehicleID == applySkinId then
      return
    end

    _G.skinIdCache = _G.skinIdCache or {}
    if not _G.skinIdCache[applySkinId] then
      if _G.download_item then pcall(_G.download_item, applySkinId) end
      _G.skinIdCache[applySkinId] = true
    end

    pcall(function() VehicleAvatar.curSwitchEffectId = 7303001 end)
    local okChange = false
    pcall(function()
      if VehicleAvatar.ChangeItemAvatar then
        VehicleAvatar:ChangeItemAvatar(applySkinId, true)
        okChange = true
      end
    end)
    pcall(function()
      if not okChange and VehicleAvatar.SyncChangeItemAvatar then
        VehicleAvatar:SyncChangeItemAvatar(applySkinId)
        okChange = true
      end
    end)
    pcall(function()
      if Vehicle.SetAvatarID then Vehicle:SetAvatarID(applySkinId) end
    end)

    _G.CurrentEquipVehicleID = applySkinId
    _G.LastVehicleEntity = Vehicle
  end)
end

-- Call when VehicleSkinMap changes so next enter re-applies
_G.InvalidateVehicleSkinCache = function()
  _G.LastVehicleEntity = nil
  _G.CurrentEquipVehicleID = nil
end


_G.HandlePetLogic = function()
    pcall(function()
        local petSkin = _G.OutfitMap.Pet
        if not petSkin or petSkin == 0 or petSkin == 50000 or petSkin == _G.LastAppliedPet then return end
        
        _G.skinIdCache = _G.skinIdCache or {}
        if not _G.skinIdCache[petSkin] then 
            if _G.download_item then pcall(_G.download_item, petSkin) end
            _G.skinIdCache[petSkin] = true 
        end
        
        local ModuleManager = require("client.module_framework.ModuleManager")
        if ModuleManager then
            local logic_pet = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)
            if logic_pet then
                if logic_pet.SetCurPetID then logic_pet:SetCurPetID(petSkin) end
                if logic_pet.EquipPet then logic_pet:EquipPet(petSkin) end
            end
        end
        _G.LastAppliedPet = petSkin
    end)
end

_G.ForceRefreshSkinMaps = function()
    pcall(function()
        if not _G.LexusState or not _G.LexusState.CustomTextData then return end
        local cData = _G.LexusState.CustomTextData

        if _G.OutfitSkins then
            if cData.SkinSuit and _G.OutfitSkins.Suit[cData.SkinSuit] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[cData.SkinSuit] end
            if cData.SkinBag and _G.OutfitSkins.Bag[cData.SkinBag] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[cData.SkinBag] end
            if cData.SkinHelmet and _G.OutfitSkins.Helmet[cData.SkinHelmet] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[cData.SkinHelmet] end
        end

        if _G.skinIdMappings then
            if cData.SkinM416 and _G.skinIdMappings[101004] and _G.skinIdMappings[101004][cData.SkinM416] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][cData.SkinM416] end
            if cData.SkinAKM and _G.skinIdMappings[101001] and _G.skinIdMappings[101001][cData.SkinAKM] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][cData.SkinAKM] end
            if cData.SkinSCAR and _G.skinIdMappings[101003] and _G.skinIdMappings[101003][cData.SkinSCAR] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][cData.SkinSCAR] end
            if cData.SkinM762 and _G.skinIdMappings[101008] and _G.skinIdMappings[101008][cData.SkinM762] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][cData.SkinM762] end
            if cData.SkinAUG and _G.skinIdMappings[101006] and _G.skinIdMappings[101006][cData.SkinAUG] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][cData.SkinAUG] end
            if cData.SkinUMP and _G.skinIdMappings[102002] and _G.skinIdMappings[102002][cData.SkinUMP] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][cData.SkinUMP] end
            
            if cData.SkinUZI and _G.skinIdMappings[102001] and _G.skinIdMappings[102001][cData.SkinUZI] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][cData.SkinUZI] end
            if cData.SkinGroza and _G.skinIdMappings[101005] and _G.skinIdMappings[101005][cData.SkinGroza] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][cData.SkinGroza] end
            if cData.SkinS12K and _G.skinIdMappings[104003] and _G.skinIdMappings[104003][cData.SkinS12K] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][cData.SkinS12K] end
            if cData.SkinDBS and _G.skinIdMappings[104004] and _G.skinIdMappings[104004][cData.SkinDBS] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][cData.SkinDBS] end
            if cData.SkinASM and _G.skinIdMappings[101101] and _G.skinIdMappings[101101][cData.SkinASM] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][cData.SkinASM] end
        end

        if _G.VehicleSkins then
            if cData.SkinDacia and _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][cData.SkinDacia] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][cData.SkinDacia] end
            if cData.SkinUAZ and _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][cData.SkinUAZ] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][cData.SkinUAZ] end
            if cData.SkinCoupe and _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][cData.SkinCoupe] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][cData.SkinCoupe] end
            if cData.SkinBuggy and _G.VehicleSkins[1907002] and _G.VehicleSkins[1907002][cData.SkinBuggy] then _G.VehicleSkinMap[1907002] = _G.VehicleSkins[1907002][cData.SkinBuggy] end
            if cData.SkinMirado and _G.VehicleSkins[1915004] and _G.VehicleSkins[1915004][cData.SkinMirado] then _G.VehicleSkinMap[1915004] = _G.VehicleSkins[1915004][cData.SkinMirado] end
            if cData.SkinQBZ and _G.skinIdMappings[101007] and _G.skinIdMappings[101007][cData.SkinQBZ] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][cData.SkinQBZ] end
if cData.SkinHoney and _G.skinIdMappings[101012] and _G.skinIdMappings[101012][cData.SkinHoney] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][cData.SkinHoney] end
if cData.SkinM16A4 and _G.skinIdMappings[101002] and _G.skinIdMappings[101002][cData.SkinM16A4] then _G.WeaponSkinMap[101002] = _G.skinIdMappings[101002][cData.SkinM16A4] end
if cData.SkinACE32 and _G.skinIdMappings[101102] and _G.skinIdMappings[101102][cData.SkinACE32] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][cData.SkinACE32] end
if cData.SkinKar98k and _G.skinIdMappings[103001] and _G.skinIdMappings[103001][cData.SkinKar98k] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][cData.SkinKar98k] end
if cData.SkinM24 and _G.skinIdMappings[103002] and _G.skinIdMappings[103002][cData.SkinM24] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][cData.SkinM24] end
if cData.SkinAWM and _G.skinIdMappings[103003] and _G.skinIdMappings[103003][cData.SkinAWM] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][cData.SkinAWM] end
        end
    end)
end

local cached_GameplayStatics = nil
local cached_PlayerTombBox = nil
local cached_ActorClass = nil
_G.NeedCheckDeadBoxTimer = 100

_G.DeadBox_TemperRequest = function(PlayerController)
    if not _G.LexusConfig.SkinDeadBox then return end
    if _G.NeedCheckDeadBoxTimer <= 0 then return end
    
    local curTime = os.clock()
    if _G.LastCheckDeadBoxTime and (curTime - _G.LastCheckDeadBoxTime) < 2.0 then return end
    _G.LastCheckDeadBoxTime = curTime
    
    _G.NeedCheckDeadBoxTimer = _G.NeedCheckDeadBoxTimer - 1

    local PlayerCharacter = PlayerController:GetPlayerCharacterSafety()
    if not slua.isValid(PlayerCharacter) then return end
    
    if not cached_GameplayStatics then
        cached_GameplayStatics = import("GameplayStatics")
        cached_ActorClass = import("Actor")
        cached_PlayerTombBox = import("PlayerTombBox")
    end
    
    if not _G.CachedActorArray then
        _G.CachedActorArray = slua.Array(UEnums.EPropertyClass.Object, cached_ActorClass)
    end
    
    local UI_Util = require("client.common.ui_util")
    local GameInstance = UI_Util and UI_Util.GetGameInstance()
    if not GameInstance or not cached_GameplayStatics then return end

    local deadBoxes = cached_GameplayStatics.GetAllActorsOfClass(GameInstance, cached_PlayerTombBox, _G.CachedActorArray)
    
    for _, deadBoxActor in pairs(deadBoxes) do
        if slua.isValid(deadBoxActor) and not deadBoxActor.bIsTDSkinApplied then
            local damageCauser = deadBoxActor.DamageCauser
            if damageCauser and damageCauser.PlayerKey == PlayerController.PlayerKey then
                local DeadBoxAvatarComponent = deadBoxActor.DeadBoxAvatarComponent_BP
                if slua.isValid(DeadBoxAvatarComponent) then
                    local currentBoxSkinId = 0
                    if PlayerCharacter.CurrentVehicle and _G.CurrentEquipVehicleID and _G.CurrentEquipVehicleID ~= 0 then
                        currentBoxSkinId = tonumber(tostring(_G.CurrentEquipVehicleID) .. "1") or 0
                    else
                        local currentWeapon = PlayerCharacter:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) and currentWeapon.synData then
                            local weaponSkinData = currentWeapon.synData:Get(7)
                            if weaponSkinData and weaponSkinData.defineID then
                                currentBoxSkinId = weaponSkinData.defineID.TypeSpecificID
                            end
                        end
                    end
                    
                    if currentBoxSkinId ~= 0 then
                        pcall(function()
                            DeadBoxAvatarComponent:ResetItemAvatar()
                            DeadBoxAvatarComponent:PreChangeItemAvatar(currentBoxSkinId)
                            DeadBoxAvatarComponent:SyncChangeItemAvatar(currentBoxSkinId)
                        end)
                    end
                    deadBoxActor.bIsTDSkinApplied = true
                end
            end
        end
    end
end

_G.TDFTDeKillCounts = _G.TDFTDeKillCounts or {}
local CACHED_LinearColor = import("LinearColor")
local CACHED_GoldColor = CACHED_LinearColor and CACHED_LinearColor(1.0, 0.8, 0.0, 1.0) or nil
local CACHED_UI_Manager = nil

_G.ForceEnableKillCounterUI = function()
    pcall(function()
        local KillCounterUISubsystem = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"] or require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
        if KillCounterUISubsystem and KillCounterUISubsystem.__inner_impl and not _G.KCUISystemHacked2 then
            local kcImpl = KillCounterUISubsystem.__inner_impl
            kcImpl.CheckSupportKCUI = function() return true end
            kcImpl.CheckNeedMainKillCounterUI = function(self, PlayerWeapon, PlayerID)
                if slua.isValid(PlayerWeapon) then
                    local WeaponID = PlayerWeapon:GetWeaponID()
                    self:UpdateMainKillCounterUI(true, WeaponID, _G.get_skin_id(WeaponID) or WeaponID)
                else self:UpdateMainKillCounterUI(false) end
            end
            local originalUpdateMainKillCounterUI = kcImpl.UpdateMainKillCounterUI
            kcImpl.UpdateMainKillCounterUI = function(self, bShow, WeaponID, AvatarID)
                if bShow then AvatarID = _G.get_skin_id(WeaponID) or AvatarID end
                if originalUpdateMainKillCounterUI then originalUpdateMainKillCounterUI(self, bShow, WeaponID, AvatarID) end
            end
            _G.KCUISystemHacked2 = true
        end

        local ModuleManager = require("client.module_framework.ModuleManager")
        if ModuleManager and not _G.KCLogicHacked2 then
            local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
            if LogicKillCounter then
                LogicKillCounter.CheckSupportKC = function() return true end
                LogicKillCounter.CheckSupportKillCounterAvatar = function() return true end
                LogicKillCounter.CheckHasWeaponKillCounter = function() return true end
                LogicKillCounter.GetBaseKillCounterIdByWeaponId = function() return 2100004 end
                LogicKillCounter.GetEquipedKillCounterId = function() return 2100004 end
                LogicKillCounter.GetMyEquipedKillCounterId = function() return 2100004 end
                LogicKillCounter.GetOneWeaponKillCountInBattle = function(self, uid, weaponId) return _G.TDFTDeKillCounts[weaponId] or 0 end
                LogicKillCounter.GetWeaponKillCountByUid = function(self, uid, weaponId) return _G.TDFTDeKillCounts[weaponId] or 0 end
                _G.KCLogicHacked2 = true
            end
        end

        local killInfoPath = "GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo"
        local KillInfo = package.loaded[killInfoPath] or require(killInfoPath)
        
        if KillInfo and KillInfo.__inner_impl and not _G.KillInfoCounterHacked then
            local originalFileItem = KillInfo.__inner_impl.FileItem
            KillInfo.__inner_impl.FileItem = function(self, DamageRecordData)
                pcall(function()
                    local LocalPlayer = require("GameLua.GameCore.Data.GameplayData").GetPlayerCharacter()
                    if slua.isValid(LocalPlayer) and DamageRecordData.Causer == LocalPlayer:GetPlayerNameSafety() then 
                        local currentWeapon = LocalPlayer:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) then
                            local weaponID = currentWeapon:GetWeaponID()
                            local skinID = _G.get_skin_id(weaponID)
                            if skinID then DamageRecordData.CauserWeaponAvatarID = skinID end
                            if _G.OutfitMap.Suit and _G.OutfitMap.Suit ~= 0 then DamageRecordData.CauserClothAvatarID = _G.OutfitMap.Suit end
                            
                            if CACHED_GoldColor then
                                DamageRecordData.IsUseColor, DamageRecordData.UseColor = true, CACHED_GoldColor
                            end
                            
                            if DamageRecordData.ResultHealthStatus == 2 then
                                _G.TDFTDeKillCounts[weaponID] = (_G.TDFTDeKillCounts[weaponID] or 0) + 1
                                _G.NeedCheckDeadBoxTimer = 50 
                                
                                if not CACHED_UI_Manager then CACHED_UI_Manager = require("client.slua_ui_framework.manager") end
                                local uiMainKillCounter = CACHED_UI_Manager.GetUI(CACHED_UI_Manager.UI_Config_InGame.MainKillCounter)
                                
                                if uiMainKillCounter and uiMainKillCounter.UpdateWeaponID then
                                    local mainAvatarID = skinID or currentWeapon:GetWeaponMainAvatarID()
                                    uiMainKillCounter:UpdateWeaponID(weaponID, mainAvatarID)
                                    local kcModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
                                    local kcItemID = kcModule:GetEquipedKillCounterId(0, mainAvatarID)
                                    uiMainKillCounter:SetKillCounterItemShowWithNum(kcItemID, _G.TDFTDeKillCounts[weaponID], mainAvatarID)
                                end
                            end
                        end
                    end
                end)
                if originalFileItem then return originalFileItem(self, DamageRecordData) end
            end
            _G.KillInfoCounterHacked = true
        end

        local SwitchWeaponSlotMode2 = package.loaded["GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2"] or require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
        if SwitchWeaponSlotMode2 and SwitchWeaponSlotMode2.__inner_impl and not _G.SlotBaseHacked then
            SwitchWeaponSlotMode2.__inner_impl.CheckShowKCIcon = function(self)
                if slua.isValid(self.KillCounterImg) then 
                    self.KillCounterImg:SetVisibility(import("ESlateVisibility").SelfHitTestInvisible) 
                end
            end
            _G.SlotBaseHacked = true
        end
    end)
end



-- ====================================================================
-- SkinBypass — anti-detect for skin mods (on/off via SkinSystem)
-- ====================================================================
_G.SkinBypass = _G.SkinBypass or {}
local Bypass = _G.SkinBypass
Bypass._patched = Bypass._patched or {}
Bypass._fakeHWID = Bypass._fakeHWID
Bypass.Enabled = true

local function ReturnTrue() return true end
local function ReturnFalse() return false end
local function ReturnNil() return nil end
local function SafePatch(fn) pcall(fn) end
local function AlreadyPatched(key)
  if Bypass._patched[key] then return true end
  Bypass._patched[key] = true
  return false
end

function Bypass.PatchHWID()
  if AlreadyPatched("HWID") then return end
  SafePatch(function()
    local KSL = import("KismetSystemLibrary")
    if not KSL then return end
    _G._OrigGetDeviceId = _G._OrigGetDeviceId or KSL.GetDeviceId
    local function GenHWID()
      if Bypass._fakeHWID then return Bypass._fakeHWID end
      local charset = "0123456789ABCDEF"
      local result = ""
      for i = 1, 32 do
        local idx = math.random(1, #charset)
        result = result .. charset:sub(idx, idx)
        if i == 8 or i == 12 or i == 16 or i == 20 then result = result .. "-" end
      end
      Bypass._fakeHWID = result
      return result
    end
    KSL.GetDeviceId = function(...)
      if _G.LexusConfig and _G.LexusConfig.FakeHWID then return GenHWID() end
      if _G._OrigGetDeviceId then return _G._OrigGetDeviceId(...) end
      return GenHWID()
    end
  end)
end

function Bypass.SilenceReports()
  if AlreadyPatched("Reports") then return end
  SafePatch(function()
    local tlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
    if tlog then
      for _, k in ipairs({"ReportEvent","ReportDownloadResult","ReportODPTDError","ReportSkinError","ReportError","SendLog"}) do
        if tlog[k] then tlog[k] = ReturnTrue end
      end
    end
    local eqReport = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
    if eqReport then
      for _, k in ipairs({"Report","SendException","SendReport"}) do
        if eqReport[k] then eqReport[k] = ReturnTrue end
      end
    end
  end)
end

function Bypass.PatchAvatarIntegrity()
  if AlreadyPatched("Avatar") then return end
  SafePatch(function()
    local AU = package.loaded["AvatarUtils"]
    if not AU then local ok, mod = pcall(require, "AvatarUtils"); if ok then AU = mod end end
    if AU then
      AU.CheckIsWeaponInBlackList = ReturnFalse
      AU.IsValidAvatar = ReturnTrue
      AU.CheckAvatarIntegrity = ReturnTrue
      AU.ReportInvalidAvatar = ReturnTrue
      if AU.IsAvatarOwned then AU.IsAvatarOwned = ReturnTrue end
      if AU.ValidateSkin then AU.ValidateSkin = ReturnTrue end
      if AU.CheckSkinValid then AU.CheckSkinValid = ReturnTrue end
      if AU.ReportSkinMismatch then AU.ReportSkinMismatch = ReturnTrue end
    end
  end)
end

function Bypass.PatchFileCheck()
  if AlreadyPatched("FileCheck") then return end
  SafePatch(function()
    local ok, SubMgr = pcall(function() return require("GameLua.GameCore.Module.Subsystem.SubsystemMgr") end)
    if ok and SubMgr and SubMgr.Get then
      local fcs = SubMgr:Get("FileCheckSubsystem")
      if fcs then
        for _, k in ipairs({"StartCheck","StopCheck","ReportAbnormalFile","CheckFile","ScanFiles"}) do
          if fcs[k] then fcs[k] = ReturnTrue end
        end
      end
    end
  end)
end

function Bypass.PatchWeaponBlacklist()
  if AlreadyPatched("WeaponBL") then return end
  SafePatch(function()
    if _G.IsWeaponSkinInBlackList then _G.IsWeaponSkinInBlackList = ReturnFalse end
    if _G.WeaponSkinBlacklist then _G.WeaponSkinBlacklist = {} end
  end)
end

function Bypass.PatchOutfitValidation()
  if AlreadyPatched("Outfit") then return end
  SafePatch(function()
    if _G.IsOutfitOwned then _G.IsOutfitOwned = ReturnTrue end
    if _G.OutfitBlacklist then _G.OutfitBlacklist = {} end
  end)
end

function Bypass.PatchVehicleValidation()
  if AlreadyPatched("Vehicle") then return end
  SafePatch(function()
    if _G.IsVehicleSkinOwned then _G.IsVehicleSkinOwned = ReturnTrue end
    if _G.VehicleSkinBlacklist then _G.VehicleSkinBlacklist = {} end
  end)
end

function Bypass.StartRefreshLoop()
  SafePatch(function()
    local ok, ticker = pcall(require, "common.time_ticker")
    if ok and ticker and ticker.AddTimerLoop then
      ticker.AddTimerLoop(20.0, function()
        if not Bypass.Enabled then return end
        if not (_G.SkinSystem and _G.SkinSystem.Enabled) then return end
        Bypass._patched["Reports"] = false
        Bypass._patched["Avatar"] = false
        Bypass._patched["FileCheck"] = false
        Bypass._patched["WeaponBL"] = false
        Bypass._patched["Outfit"] = false
        Bypass._patched["Vehicle"] = false
        pcall(Bypass.SilenceReports)
        pcall(Bypass.PatchAvatarIntegrity)
        pcall(Bypass.PatchFileCheck)
        pcall(Bypass.PatchWeaponBlacklist)
        pcall(Bypass.PatchOutfitValidation)
        pcall(Bypass.PatchVehicleValidation)
      end)
    elseif ok and ticker and ticker.AddTimerOnce then
      local function loop()
        if Bypass.Enabled and _G.SkinSystem and _G.SkinSystem.Enabled then
          Bypass._patched["Reports"] = false
          Bypass._patched["Avatar"] = false
          pcall(Bypass.SilenceReports)
          pcall(Bypass.PatchAvatarIntegrity)
        end
        ticker.AddTimerOnce(20.0, loop)
      end
      ticker.AddTimerOnce(20.0, loop)
    end
  end)
end

function Bypass.Init()
  if not Bypass.Enabled then return end
  pcall(Bypass.PatchHWID)
  pcall(Bypass.SilenceReports)
  pcall(Bypass.PatchAvatarIntegrity)
  pcall(Bypass.PatchFileCheck)
  pcall(Bypass.PatchWeaponBlacklist)
  pcall(Bypass.PatchOutfitValidation)
  pcall(Bypass.PatchVehicleValidation)
  pcall(Bypass.StartRefreshLoop)
end


-- ====================================================================
-- SkinSystem — full skin module with on/off + menu stack
-- ====================================================================
_G.SkinSystem = _G.SkinSystem or {}
local SkinSystem = _G.SkinSystem
SkinSystem.Enabled = true
SkinSystem.Toggle = SkinSystem.Toggle or {
  Outfit = true, Weapons = true, Vehicles = true, DeadBox = true, Attachment = true,
}
SkinSystem.Config = SkinSystem.Config or {
  SkinSuit=1, SkinBag=1, SkinHelmet=1,
  SkinM416=1, SkinAKM=1, SkinSCAR=1, SkinM762=1, SkinAUG=1, SkinGroza=1,
  SkinASM=1, SkinQBZ=1, SkinHoney=1, SkinM16A4=1, SkinACE32=1,
  SkinUMP=1, SkinUZI=1, SkinKar98k=1, SkinM24=1, SkinAWM=1,
  SkinS12K=1, SkinDBS=1,
  SkinDacia=1, SkinUAZ=1, SkinCoupe=1, SkinBuggy=1, SkinMirado=1,
  SkinDeadBox=false, SkinAttachment=false,
}

local WEAPON_MAP = {
  [101001]="SkinAKM",[101002]="SkinM16A4",[101003]="SkinSCAR",[101004]="SkinM416",
  [101005]="SkinGroza",[101006]="SkinAUG",[101007]="SkinQBZ",[101008]="SkinM762",
  [101012]="SkinHoney",[101101]="SkinASM",[101102]="SkinACE32",
  [102001]="SkinUZI",[102002]="SkinUMP",
  [103001]="SkinKar98k",[103002]="SkinM24",[103003]="SkinAWM",
  [104003]="SkinS12K",[104004]="SkinDBS",
}
local VEHICLE_MAP = {
  [1903001]="SkinDacia",[1908001]="SkinUAZ",[1961001]="SkinCoupe",
  [1907002]="SkinBuggy",[1915004]="SkinMirado",
}

local function EnsureGlobals()
  _G.WeaponSkinMap = _G.WeaponSkinMap or {}
  _G.skinIdMappings = _G.skinIdMappings or {}
  _G.VehicleSkinMap = _G.VehicleSkinMap or {}
  _G.VehicleSkins = _G.VehicleSkins or {}
  _G.OutfitSkins = _G.OutfitSkins or { Suit={}, Bag={}, Helmet={} }
  _G.OutfitMap = _G.OutfitMap or {}
  _G.LexusState = _G.LexusState or { CustomTextData={}, DirtyConfig=false }
  _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
  _G.LexusConfig = _G.LexusConfig or {}
end

function SkinSystem.ApplyOutfit()
  if not SkinSystem.Enabled or not SkinSystem.Toggle.Outfit then return end
  pcall(function()
    EnsureGlobals()
    local cfg, LS = SkinSystem.Config, _G.LexusState.CustomTextData
    local function clamp(list, idx)
      idx = tonumber(idx) or 1
      local n = list and #list or 1
      if idx < 1 then idx = 1 end
      if idx > n then idx = n end
      return idx
    end
    cfg.SkinSuit = clamp(_G.OutfitSkins.Suit, cfg.SkinSuit)
    LS.SkinSuit = cfg.SkinSuit
    if _G.OutfitSkins.Suit and _G.OutfitSkins.Suit[cfg.SkinSuit] then
      _G.OutfitMap.Suit = _G.OutfitSkins.Suit[cfg.SkinSuit]
      if _G.download_item then pcall(_G.download_item, _G.OutfitMap.Suit) end
    end
    cfg.SkinBag = clamp(_G.OutfitSkins.Bag, cfg.SkinBag)
    LS.SkinBag = cfg.SkinBag
    if _G.OutfitSkins.Bag and _G.OutfitSkins.Bag[cfg.SkinBag] then
      _G.OutfitMap.Bag = _G.OutfitSkins.Bag[cfg.SkinBag]
    end
    cfg.SkinHelmet = clamp(_G.OutfitSkins.Helmet, cfg.SkinHelmet)
    LS.SkinHelmet = cfg.SkinHelmet
    if _G.OutfitSkins.Helmet and _G.OutfitSkins.Helmet[cfg.SkinHelmet] then
      _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[cfg.SkinHelmet]
    end
    _G.LexusState.DirtyConfig = true
  end)
end

function SkinSystem.ApplyWeapons()
  if not SkinSystem.Enabled or not SkinSystem.Toggle.Weapons then return end
  pcall(function()
    EnsureGlobals()
    local cfg, LS = SkinSystem.Config, _G.LexusState.CustomTextData
    for classID, cfgKey in pairs(WEAPON_MAP) do
      local list = _G.skinIdMappings[classID]
      local maxIdx = (list and #list) or 1
      local idx = tonumber(cfg[cfgKey]) or 1
      if idx < 1 then idx = 1 end
      if idx > maxIdx then idx = maxIdx end
      cfg[cfgKey] = idx
      LS[cfgKey] = idx
      if list and list[idx] then
        _G.WeaponSkinMap[classID] = list[idx]
        if _G.download_item then pcall(_G.download_item, list[idx]) end
      end
    end
    _G.LexusState.DirtyConfig = true
  end)
end

function SkinSystem.ApplyVehicles()
  if not SkinSystem.Enabled or not SkinSystem.Toggle.Vehicles then return end
  pcall(function()
    EnsureGlobals()
    local cfg, LS = SkinSystem.Config, _G.LexusState.CustomTextData
    for vID, cfgKey in pairs(VEHICLE_MAP) do
      local list = _G.VehicleSkins[vID]
      local maxIdx = (list and #list) or 1
      local idx = tonumber(cfg[cfgKey]) or 1
      if idx < 1 then idx = 1 end
      if idx > maxIdx then idx = maxIdx end
      cfg[cfgKey] = idx
      LS[cfgKey] = idx
      if list and list[idx] then
        _G.VehicleSkinMap[vID] = list[idx]
        if _G.download_item then pcall(_G.download_item, list[idx]) end
      end
    end
    if _G.InvalidateVehicleSkinCache then _G.InvalidateVehicleSkinCache() end
    _G.LexusState.DirtyConfig = true
  end)
end

function SkinSystem.ApplyMisc()
  pcall(function()
    EnsureGlobals()
    local cfg = SkinSystem.Config
    if SkinSystem.Toggle.DeadBox then _G.LexusConfig.SkinDeadBox = cfg.SkinDeadBox end
    if SkinSystem.Toggle.Attachment then _G.LexusConfig.SkinAttachment = cfg.SkinAttachment end
    _G.LexusState.DirtyConfig = true
  end)
end

function SkinSystem.RefreshLobbyNow()
  if _G.ApplyLobbySkins then pcall(_G.ApplyLobbySkins) end
end

function SkinSystem.ApplyAll()
  if not SkinSystem.Enabled then return end
  SkinSystem.ApplyOutfit()
  SkinSystem.ApplyWeapons()
  SkinSystem.ApplyVehicles()
  SkinSystem.ApplyMisc()
end

function SkinSystem.SetEnabled(val)
  SkinSystem.Enabled = val and true or false
  if _G.SkinBypass then _G.SkinBypass.Enabled = SkinSystem.Enabled end
  if SkinSystem.Enabled then
    if _G.SkinBypass and _G.SkinBypass.Init then pcall(_G.SkinBypass.Init) end
    if _G.InitializeSkinModSystem then pcall(_G.InitializeSkinModSystem) end
    if _G.StartLobbySkinLoop then pcall(_G.StartLobbySkinLoop) end
    SkinSystem.ApplyAll()
    if _G.ApplyLobbySkins then pcall(_G.ApplyLobbySkins) end
  end
end

function SkinSystem.SetToggle(category, val)
  if SkinSystem.Toggle[category] == nil then return end
  SkinSystem.Toggle[category] = val and true or false
  if val and SkinSystem.Enabled then
    if category == "Outfit" then SkinSystem.ApplyOutfit()
    elseif category == "Weapons" then SkinSystem.ApplyWeapons()
    elseif category == "Vehicles" then SkinSystem.ApplyVehicles()
    else SkinSystem.ApplyMisc() end
  end
end

function SkinSystem.Save()
  pcall(function()
    if not _G.LexusConfig then return end
    _G.LexusConfig._SkinSystem = {
      Enabled = SkinSystem.Enabled,
      Toggle = SkinSystem.Toggle,
      Config = SkinSystem.Config,
    }
    if _G.MarkConfigDirty then _G.MarkConfigDirty() end
  end)
end

function SkinSystem.Load()
  pcall(function()
    if not _G.LexusConfig or not _G.LexusConfig._SkinSystem then return end
    local saved = _G.LexusConfig._SkinSystem
    if saved.Enabled ~= nil then SkinSystem.Enabled = saved.Enabled end
    if saved.Toggle then
      for k,v in pairs(saved.Toggle) do
        if SkinSystem.Toggle[k] ~= nil then SkinSystem.Toggle[k] = v end
      end
    end
    if saved.Config then
      for k,v in pairs(saved.Config) do
        if SkinSystem.Config[k] ~= nil then SkinSystem.Config[k] = v end
      end
    end
    if _G.SkinBypass then _G.SkinBypass.Enabled = SkinSystem.Enabled end
  end)
end

function SkinSystem.BuildMenuStack(AM)
  local SW = AM.TitleSwitcher or AM.Switcher
  local SL = AM.Slider
  local stack = {}
  local function titleSw(key, text, getf, setf)
    return { Key=key, UI=SW, Text=text, ExpandIndex=0, GetFunc=getf, SetFunc=setf }
  end
  local function boolSw(key, text, parent, getf, setf)
    return { Key=key, UI=AM.Switcher, Text=text, ExpandHandle=parent, GetFunc=getf, SetFunc=setf }
  end
  local function slider(key, text, parent, minV, maxV, getf, setf)
    return { Key=key, UI=SL, Text=text, ExpandHandle=parent, MinValue=minV, MaxValue=maxV, GetFunc=getf, SetFunc=setf }
  end

  table.insert(stack, titleSw("SS_Master", "Skin System ON/OFF",
    function() return SkinSystem.Enabled end,
    function(_, v) SkinSystem.SetEnabled(v); SkinSystem.Save(); return true end))

  local cats = {
    {"Outfit","Outfit Skins Toggle"},{"Weapons","Weapon Skins Toggle"},
    {"Vehicles","Vehicle Skins Toggle"},{"DeadBox","DeadBox Skin Toggle"},
    {"Attachment","Attachment Skin Toggle"},
  }
  for _, c in ipairs(cats) do
    local cat = c[1]
    table.insert(stack, titleSw("SS_Toggle_"..cat, c[2],
      function() return SkinSystem.Toggle[cat] end,
      function(_, v) SkinSystem.SetToggle(cat, v); SkinSystem.Save(); return true end))
  end

  local outfit = {{"SkinSuit","Suit Skin",80},{"SkinBag","Bag Skin",15},{"SkinHelmet","Helmet Skin",11}}
  for _, s in ipairs(outfit) do
    local k = s[1]
    table.insert(stack, slider("SS_"..k, "  "..s[2], "SS_Toggle_Outfit", 1, s[3],
      function() return SkinSystem.Config[k] end,
      function(_, v) SkinSystem.Config[k]=v; SkinSystem.ApplyOutfit(); SkinSystem.Save(); SkinSystem.RefreshLobbyNow(); return true end))
  end

  local weapons = {
    {"SkinM416","M416 Skin",8},{"SkinAKM","AKM Skin",8},{"SkinSCAR","SCAR Skin",8},
    {"SkinM762","M762 Skin",9},{"SkinAUG","AUG Skin",7},{"SkinUMP","UMP Skin",5},
    {"SkinGroza","Groza Skin",2},{"SkinASM","ASM Gen8 Skin",2},{"SkinQBZ","QBZ Skin",6},
    {"SkinHoney","Honey Badger Skin",2},{"SkinM16A4","M16A4 Skin",5},{"SkinACE32","ACE32 Skin",6},
    {"SkinUZI","UZI Skin",2},{"SkinKar98k","Kar98k Skin",8},{"SkinM24","M24 Skin",7},
    {"SkinAWM","AWM Skin",11},{"SkinS12K","S12K Skin",2},{"SkinDBS","DBS Skin",3},
  }
  for _, s in ipairs(weapons) do
    local k = s[1]
    table.insert(stack, slider("SS_"..k, "  "..s[2], "SS_Toggle_Weapons", 1, s[3],
      function() return SkinSystem.Config[k] end,
      function(_, v) SkinSystem.Config[k]=v; SkinSystem.ApplyWeapons(); SkinSystem.Save(); SkinSystem.RefreshLobbyNow(); return true end))
  end

  local vehicles = {
    {"SkinDacia","Dacia Skin",34},{"SkinUAZ","UAZ Skin",16},{"SkinCoupe","Coupe Skin",56},
    {"SkinBuggy","Buggy Skin",11},{"SkinMirado","Mirado Skin",5},
  }
  for _, s in ipairs(vehicles) do
    local k = s[1]
    table.insert(stack, slider("SS_"..k, "  "..s[2], "SS_Toggle_Vehicles", 1, s[3],
      function() return SkinSystem.Config[k] end,
      function(_, v) SkinSystem.Config[k]=v; SkinSystem.ApplyVehicles(); SkinSystem.Save(); SkinSystem.RefreshLobbyNow(); return true end))
  end

  table.insert(stack, boolSw("SS_DeadBox", "DeadBox Skin", "SS_Toggle_DeadBox",
    function() return SkinSystem.Config.SkinDeadBox end,
    function(_, v) SkinSystem.Config.SkinDeadBox=v; SkinSystem.ApplyMisc(); SkinSystem.Save(); return true end))
  table.insert(stack, boolSw("SS_Attachment", "Attachment Skin", "SS_Toggle_Attachment",
    function() return SkinSystem.Config.SkinAttachment end,
    function(_, v) SkinSystem.Config.SkinAttachment=v; SkinSystem.ApplyMisc(); SkinSystem.Save(); return true end))

  return stack
end


-- ====================================================================
-- LOBBY + IN-GAME skin apply (works outside match too)
-- ====================================================================
_G.InitializeSkinModSystem = function()
  if _G._SkinModSystemInited then return end
  _G._SkinModSystemInited = true

  -- LobbyAvatar: redirect weapon equip to mapped skin IDs
  pcall(function()
    local LobbyAvatar = package.loaded["client.logic.avatar.LobbyAvatar"]
      or _G.GetModule and _G.GetModule("client.logic.avatar.LobbyAvatar")
    if not LobbyAvatar then
      local ok, mod = pcall(require, "client.logic.avatar.LobbyAvatar")
      if ok then LobbyAvatar = mod end
    end
    if not LobbyAvatar or _G.LobbyBypassHacked then return end

    local originalPutonEquipment = LobbyAvatar.PutonEquipment
    if originalPutonEquipment then
      LobbyAvatar.PutonEquipment = function(self, itemID, tAvatarCustom, tExtraData)
        if _G.SkinSystem and _G.SkinSystem.Enabled then
          -- map base weapon class -> skin id if present in WeaponSkinMap
          local mapped = itemID
          pcall(function()
            if _G.get_skin_id then
              local sid = _G.get_skin_id(itemID)
              if sid and sid > 0 then mapped = sid end
            end
            -- outfit slots: if item looks like default and OutfitMap set, swap
            if _G.OutfitMap then
              if _G.OutfitMap.Suit and (itemID == 1400000 or itemID < 1000) then end
            end
          end)
          itemID = mapped
          if self.HandleDownload and mapped and mapped > 0 then
            pcall(function() self:HandleDownload(mapped, nil, nil, false) end)
          end
        end
        return originalPutonEquipment(self, itemID, tAvatarCustom, tExtraData)
      end
    end

    local originalCharEquipWeaponByResId = LobbyAvatar.CharEquipWeaponByResId
    if originalCharEquipWeaponByResId then
      LobbyAvatar.CharEquipWeaponByResId = function(self, resID, isUse, isAsync, SocketName)
        if _G.SkinSystem and _G.SkinSystem.Enabled and _G.SkinSystem.Toggle and _G.SkinSystem.Toggle.Weapons then
          pcall(function()
            if _G.get_skin_id then
              local sid = _G.get_skin_id(resID)
              if sid and sid > 0 and sid ~= resID then
                resID = sid
                if self.HandleDownload then self:HandleDownload(sid, nil, nil, false) end
              end
            end
          end)
        end
        return originalCharEquipWeaponByResId(self, resID, isUse, isAsync, SocketName)
      end
    end

    -- Outfit apply helper on lobby avatar instance
    if not LobbyAvatar.ApplyModOutfit then
      LobbyAvatar.ApplyModOutfit = function(self)
        if not (_G.SkinSystem and _G.SkinSystem.Enabled and _G.SkinSystem.Toggle.Outfit) then return end
        if not _G.OutfitMap then return end
        pcall(function()
          local function put(id)
            if not id or id == 0 then return end
            if self.HandleDownload then self:HandleDownload(id, nil, nil, false) end
            if self.PutonEquipment then self:PutonEquipment(id, nil, {bIsUse = true}) end
          end
          if type(_G.OutfitMap.Suit) == "number" then put(_G.OutfitMap.Suit) end
          if type(_G.OutfitMap.Bag) == "table" then
            -- level 1 bag skin entry
            local bag = _G.OutfitMap.Bag[1] or _G.OutfitMap.Bag
            if type(bag) == "table" then put(bag[1] or bag[3] or bag[2]) else put(bag) end
          elseif type(_G.OutfitMap.Bag) == "number" then put(_G.OutfitMap.Bag) end
          if type(_G.OutfitMap.Helmet) == "table" then
            local h = _G.OutfitMap.Helmet
            put(h[1] or h[3] or h[2])
          elseif type(_G.OutfitMap.Helmet) == "number" then put(_G.OutfitMap.Helmet) end
        end)
      end
    end

    _G.LobbyBypassHacked = true
  end)

  -- Common item icon: show skin icon in lobby inventory UI
  pcall(function()
    local Common_Items_UIBP = package.loaded["client.slua.component.item.ItemChildren.Common_Items_UIBP"]
    if not Common_Items_UIBP then
      local ok, mod = pcall(require, "client.slua.component.item.ItemChildren.Common_Items_UIBP")
      if ok then Common_Items_UIBP = mod end
    end
    if Common_Items_UIBP and Common_Items_UIBP.__inner_impl and not _G.IconBaloHacked then
      local impl = Common_Items_UIBP.__inner_impl
      if impl.InitView then
        local originalInitView = impl.InitView
        impl.InitView = function(self, nItemId, nCount, nValidTime, tExtraData)
          if _G.SkinSystem and _G.SkinSystem.Enabled and _G.get_skin_id and nItemId then
            local sid = _G.get_skin_id(nItemId)
            if sid and sid > 0 and sid ~= nItemId then
              nItemId = sid
              if not _G.skinIdCache2 then _G.skinIdCache2 = {} end
              if not _G.skinIdCache2[sid] and _G.download_item then
                pcall(_G.download_item, sid)
                _G.skinIdCache2[sid] = true
              end
            end
          end
          return originalInitView(self, nItemId, nCount, nValidTime, tExtraData)
        end
      end
      _G.IconBaloHacked = true
    end
  end)
end

-- Resolve lobby avatar object (works in 2D lobby / main city / waiting)
_G.GetLobbyAvatarInstance = function()
  local av = nil
  pcall(function()
    local LobbyAvatar = package.loaded["client.logic.avatar.LobbyAvatar"]
    if not LobbyAvatar then
      local ok, mod = pcall(require, "client.logic.avatar.LobbyAvatar")
      if ok then LobbyAvatar = mod end
    end
    if LobbyAvatar then
      if LobbyAvatar.GetInstance then av = LobbyAvatar:GetInstance() end
      if not av and LobbyAvatar.Instance then av = LobbyAvatar.Instance end
      if not av and LobbyAvatar._instance then av = LobbyAvatar._instance end
    end
  end)
  pcall(function()
    if av then return end
    local MM = _G.GetModule and _G.GetModule("client.module_framework.ModuleManager")
    if MM and MM.GetModule then
      local mod = MM.GetModule("LobbyAvatar") or MM.GetModule(MM.CommonModuleConfig and MM.CommonModuleConfig.LobbyAvatar)
      if mod then av = mod end
    end
  end)
  return av
end

_G.ApplyLobbySkins = function()
  if not (_G.SkinSystem and _G.SkinSystem.Enabled) then return end
  pcall(function()
    if not _G._SkinModSystemInited and _G.InitializeSkinModSystem then
      _G.InitializeSkinModSystem()
    end
    -- refresh maps from config
    if _G.SkinSystem.ApplyAll then _G.SkinSystem.ApplyAll() end

    -- 1) LobbyAvatar module
    local av = _G.GetLobbyAvatarInstance and _G.GetLobbyAvatarInstance()
    if av then
      pcall(function()
        if av.ApplyModOutfit then av:ApplyModOutfit() end
      end)
      pcall(function()
        local wid = nil
        if av.GetCurHoldingWeaponSkinID then wid = av:GetCurHoldingWeaponSkinID() end
        if not wid and av.GetCurWeaponResID then wid = av:GetCurWeaponResID() end
        if not wid and av.GetHoldingWeaponID then wid = av:GetHoldingWeaponID() end
        if wid and _G.get_skin_id then
          local sid = _G.get_skin_id(wid)
          if sid and sid > 0 then
            if av.HandleDownload then av:HandleDownload(sid, nil, nil, false) end
            if av.CharEquipWeaponByResId then av:CharEquipWeaponByResId(sid, true, false, nil) end
            if av.PutonEquipment then av:PutonEquipment(sid, nil, {bIsUse = true}) end
          end
        end
        -- force outfit ids from OutfitMap
        if _G.OutfitMap then
          local function put(id)
            if not id or id == 0 then return end
            if type(id) == "table" then id = id[1] or id[3] or id[2] end
            if not id then return end
            if av.HandleDownload then av:HandleDownload(id, nil, nil, false) end
            if av.PutonEquipment then av:PutonEquipment(id, nil, {bIsUse = true}) end
          end
          put(_G.OutfitMap.Suit)
          put(_G.OutfitMap.Bag)
          put(_G.OutfitMap.Helmet)
        end
      end)
    end

    -- 2) ModuleManager lobby character / avatar handlers
    pcall(function()
      local MM = require("client.module_framework.ModuleManager")
      if not MM or not MM.GetModule then return end
      local names = {
        "logic_avatar", "LobbyAvatar", "logic_lobby_avatar",
        "logic_lobby", "AvatarManager"
      }
      if MM.CommonModuleConfig then
        for _, k in pairs(MM.CommonModuleConfig) do
          if type(k) == "string" and (k:lower():find("avatar") or k:lower():find("lobby")) then
            table.insert(names, k)
          end
        end
      end
      for _, name in ipairs(names) do
        local mod = nil
        pcall(function() mod = MM.GetModule(name) end)
        if mod then
          pcall(function()
            if mod.ApplyModOutfit then mod:ApplyModOutfit() end
            if mod.PutonEquipment and _G.OutfitMap and _G.OutfitMap.Suit then
              mod:PutonEquipment(_G.OutfitMap.Suit, nil, {bIsUse = true})
            end
          end)
        end
      end
    end)

    -- 3) World pawn (lobby island / training / match)
    pcall(function()
      local GD = _G.getCachedGameplayData and _G.getCachedGameplayData()
      local lp = nil
      if GD then
        if GD.GetPlayerCharacter then lp = GD.GetPlayerCharacter() end
        if not lp and GD.GetLocalCharacter then lp = GD.GetLocalCharacter() end
      end
      if not lp then
        local PC = nil
        pcall(function()
          if GD and GD.GetPlayerController then PC = GD.GetPlayerController() end
          if PC and PC.GetPlayerCharacterSafety then lp = PC:GetPlayerCharacterSafety() end
          if not lp and PC and PC.GetPawn then lp = PC:GetPawn() end
        end)
      end
      if lp and Valid(lp) then
        if _G.equip_character_avatar then _G.equip_character_avatar(lp) end
        if _G.ApplyWeaponSkins then _G.ApplyWeaponSkins(lp) end
        if _G.ApplyVehicleSkins then _G.ApplyVehicleSkins(lp) end
      end
    end)
  end)
end

_G.StartLobbySkinLoop = function()
  if _G._LobbySkinLoopStarted then return end
  _G._LobbySkinLoopStarted = true
  local ok, ticker = pcall(require, "common.time_ticker")
  if not ok or not ticker then return end
  local function loop()
    pcall(function()
      if _G.SkinSystem and _G.SkinSystem.Enabled then
        _G.ApplyLobbySkins()
      end
    end)
    if ticker.AddTimerOnce then ticker.AddTimerOnce(1.0, loop) end
  end
  if ticker.AddTimerOnce then ticker.AddTimerOnce(2.0, loop) end
end

function SkinSystem.Init()
  EnsureGlobals()
  SkinSystem.Load()
  if SkinSystem.Enabled and _G.SkinBypass and _G.SkinBypass.Init then
    pcall(_G.SkinBypass.Init)
  end
  -- Lobby hooks so skins work in lobby / main city, not only match
  if _G.InitializeSkinModSystem then pcall(_G.InitializeSkinModSystem) end
  if _G.StartLobbySkinLoop then pcall(_G.StartLobbySkinLoop) end
  local ok, ticker = pcall(require, "common.time_ticker")
  if ok and ticker and ticker.AddTimerOnce then
    ticker.AddTimerOnce(4.0, function()
      pcall(SkinSystem.ApplyAll)
      if _G.ApplyLobbySkins then pcall(_G.ApplyLobbySkins) end
    end)
    ticker.AddTimerOnce(8.0, function()
      if _G.ApplyLobbySkins then pcall(_G.ApplyLobbySkins) end
    end)
    local function loop()
      pcall(SkinSystem.ApplyAll)
      if _G.ApplyLobbySkins then pcall(_G.ApplyLobbySkins) end
      ticker.AddTimerOnce(12.0, loop)
    end
    ticker.AddTimerOnce(12.0, loop)
  end
end

function SkinSystem.TickLocalPlayer(lp)
  if not SkinSystem.Enabled or not Valid(lp) then return end
  pcall(function()
    if SkinSystem.Toggle.Outfit and _G.equip_character_avatar then
      _G.equip_character_avatar(lp)
    end
    if SkinSystem.Toggle.Weapons and _G.ApplyWeaponSkins then
      _G.ApplyWeaponSkins(lp)
    end
    if SkinSystem.Toggle.Vehicles and _G.ApplyVehicleSkins then
      _G.ApplyVehicleSkins(lp)
    end
  end)
end

function _G.InitModMenuTab()
  if _G.ModMenuInitialized then return end
  _G.ModMenuInitialized = true
  _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
  local LocUtil = package.loaded["client.common.LocUtil"] or _G.GetModule("client.common.LocUtil")
  local FT = { [999000] = "GocReal MOD MENU", [999001] = "ESP", [999002] = "WALLHACK", [999003] = "COMBAT", [999004] = "VISUALS", [999005] = "MISC" }
  if LocUtil and not LocUtil._Hooked_V5 then
    for _, fn in ipairs({"GetLocalizeResStr", "GetText", "GetTextByID", "GetLocalText", "GetLocalizeStr"}) do
      if LocUtil[fn] then
        local orig = LocUtil[fn]
        LocUtil[fn] = function(id)
          if id ~= nil then local nId = tonumber(id) or id; if FT[nId] then return FT[nId] end; local sId = tostring(id); if FT[sId] then return FT[sId] end end
          if type(id) == "string" and not tonumber(id) then return id end
          if orig then return orig(id) end
          return ""
        end
      end
    end
    LocUtil._Hooked_V5 = true
  end
  local SPD = _G.GetModule("client.logic.NewSetting.SettingPageDefine")
  local SC = _G.GetModule("client.logic.NewSetting.SettingCatalog")
  if not SPD or not SC or SPD.ModMenu then return end
  local AM = _G.GetModule("client.slua.umg.NewSetting.Item.AliasMap")
  if not AM then return end
  local function boolSw(key, text, cfg, parent) return { Key = key, UI = AM.Switcher, Text = text, ExpandHandle = parent, GetFunc = function() return _G.LexusConfig[cfg] end, SetFunc = function(c, v) _G.LexusConfig[cfg] = v; _G.MarkConfigDirty(); return true end } end
  local function titleSw(key, text, cfg) return { Key = key, UI = AM.TitleSwitcher, Text = text, ExpandIndex = 0, GetFunc = function() return _G.LexusConfig[cfg] end, SetFunc = function(c, v) _G.LexusConfig[cfg] = v; _G.MarkConfigDirty(); return true end } end
  local function slider(key, text, cfg, minV, maxV, parent, customGet, customSet) return { Key = key, UI = AM.Slider, Text = text, ExpandHandle = parent, MinValue = minV, MaxValue = maxV, GetFunc = customGet or function() return _G.LexusConfig[cfg] end, SetFunc = customSet or function(c, v) _G.LexusConfig[cfg] = v; _G.MarkConfigDirty(); return true end } end

  local StackESP = {
    titleSw("MM_ESP9", "ESP VIP (Wallhack Overlay)", "EspLoai9"),
    boolSw("MM_ESP9_Count", "   Player Count (Red Box)", "Esp9_Count", "MM_ESP9"),
    boolSw("MM_ESP9_Name", "   Show Player Name", "Esp9_Name", "MM_ESP9"),
    boolSw("MM_ESP9_Dist", "   Distance (RED)", "Esp9_Distance", "MM_ESP9"),
    boolSw("MM_ESP9_HP", "   Health Bar (RED)", "Esp9_HP", "MM_ESP9"),
    boolSw("MM_ESP9_Team", "   Team Color (Red)", "Esp9_Team", "MM_ESP9"),
    boolSw("MM_ESP9_Weapon", "   Show Weapon Icon", "Esp9_Weapon", "MM_ESP9"),
    titleSw("MM_EspInfo", "ESP INFO (HUD)", "EspInfo"),
    boolSw("MM_EspInfo_Wep", "   Weapon Name", "EspInfo_Weapon", "MM_EspInfo"),
    boolSw("MM_EspInfo_Pose", "   Player Pose", "EspInfo_Pose", "MM_EspInfo"),
    boolSw("MM_ESP9_Line", "   Show Snapline", "Esp9_Line", "MM_ESP9"),
    boolSw("MM_ESP9_Skel", "   Show Skeleton", "Esp9_Skeleton", "MM_ESP9"),
    titleSw("MM_WpnGlow", "Weapon Glow (HDR)", "WeaponGlow"),
    { Key = "MM_WpnGlow_Color", UI = AM.Slider, Text = "   Glow Color (1R 2G 3B 4Y 5Rnb)", ExpandHandle = "MM_WpnGlow", MinValue = 1, MaxValue = 5,
      GetFunc = function() return (_G.LexusState.CustomTextData and _G.LexusState.CustomTextData.WeaponGlowColor) or 5 end,
      SetFunc = function(_,v) _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}; _G.LexusState.CustomTextData.WeaponGlowColor = v; if _G.MarkConfigDirty then _G.MarkConfigDirty() end; return true end },
    { Key = "MM_WpnGlow_Thick", UI = AM.Slider, Text = "   Glow Thickness", ExpandHandle = "MM_WpnGlow", MinValue = 1, MaxValue = 15,
      GetFunc = function() return (_G.LexusState.CustomTextData and _G.LexusState.CustomTextData.WeaponGlowThickness) or 3 end,
      SetFunc = function(_,v) _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}; _G.LexusState.CustomTextData.WeaponGlowThickness = v; if _G.MarkConfigDirty then _G.MarkConfigDirty() end; return true end },

    boolSw("MM_Antenna", "ESP Antenna", "EspAntenna"),
    boolSw("MM_DistHud", "ESP Distance (HUD, RED)", "EspDistance"),
    boolSw("MM_VipHud", "ESP VIP Pro (HUD, RED)", "EspVipPro"),
  }
  local StackWall = { titleSw("MM_Chams", "CHAMS (Red/Green)", "ColorBodyNew") }
  local StackCombat = {
    titleSw("MM_WeaponAimbot", "WEAPON AIMBOT (Native)", "WeaponAimbot"),
    titleSw("MM_AutoHeadScope", "AUTO HEAD (Scope-Aware)", "AutoHead"),
    titleSw("MM_NoRecoil", "NO RECOIL", "NoRecoilEnabled"),
    slider("MM_RecoilPct", "   Strength (0-100%)", "RecoilReduction", 0, 100, "MM_NoRecoil"),
    titleSw("MM_Aimbot", "AIMBOT (Smooth / 100m / Neck+Chest)", "AimbotEnabled"),
    -- Environment
    titleSw("MM_RemoveFog",    "REMOVE FOG",   "RemoveFog"),
    titleSw("MM_RemoveGrass",  "REMOVE GRASS", "RemoveGrass"),
    titleSw("MM_RemoveTrees",  "REMOVE TREES", "RemoveTrees"),
    boolSw("MM_BlackSky",      "   Black Sky",  "BlackSky", "MM_RemoveTrees"),
    -- ESP Location Box
    titleSw("MM_ESPLocBox", "ESP LOCATION BOX (HUD Dots)", "ESPLocationBox"),
    boolSw("MM_KillMsg", "Kill Message (Gold)", "KillMessage"),
  }
  local StackVisuals = {
    titleSw("MM_Ipad", "IPAD VIEW", "IpadView"),
    slider("MM_IpadFOV", "   FOV (60-170)", "IpadViewFOV", 60, 170, "MM_Ipad"),
    titleSw("MM_FPS", "UNLOCK FPS", "UnlockFPS"),
    { Key = "MM_FPSLimit", UI = AM.Slider, Text = "   FPS Limit (30-265)", ExpandHandle = "MM_FPS", MinValue = 30, MaxValue = 265, GetFunc = function() return _G.LexusConfig.FPSLimit or 165 end, SetFunc = function(c, v) _G.LexusConfig.FPSLimit = v; _G.FPSState.LastApplied = 0; _G.MarkConfigDirty(); return true end },
    titleSw("MM_Crosshair", "CROSSHAIR", "Crosshair"),
    { Key = "MM_CrossStyle", UI = AM.Slider, Text = "   Style (1:Dot 2:Cross 3:Circle 4:CircleDot)", ExpandHandle = "MM_Crosshair", MinValue = 1, MaxValue = 4, GetFunc = function() return _G.LexusConfig.CrosshairStyle or 1 end, SetFunc = function(c, v) _G.LexusConfig.CrosshairStyle = v; _G.CrosshairState.LastHash = ""; _G.MarkConfigDirty(); return true end },
    { Key = "MM_CrossSize", UI = AM.Slider, Text = "   Size (1-10)", ExpandHandle = "MM_Crosshair", MinValue = 1, MaxValue = 10, GetFunc = function() return _G.LexusConfig.CrosshairSize or 4 end, SetFunc = function(c, v) _G.LexusConfig.CrosshairSize = v; _G.CrosshairState.LastHash = ""; _G.MarkConfigDirty(); return true end },
    { Key = "MM_CrossColor", UI = AM.Slider, Text = "   Color (1:R 2:G 3:B 4:C 5:Y 6:W)", ExpandHandle = "MM_Crosshair", MinValue = 1, MaxValue = 6, GetFunc = function() return _G.LexusConfig.CrosshairColor or 2 end, SetFunc = function(c, v) _G.LexusConfig.CrosshairColor = v; _G.CrosshairState.LastHash = ""; _G.MarkConfigDirty(); return true end },
  }
  local StackMisc = { boolSw("MM_FakeHWID", "Fake HWID (Anti-Ban)", "FakeHWID") }

  local StackSkin = {}
  pcall(function()
    if _G.SkinSystem and _G.SkinSystem.BuildMenuStack then
      StackSkin = _G.SkinSystem.BuildMenuStack(AM)
    end
  end)
  SPD.ModMenu = {
    Key = "ModMenu", Text = "GocReal", UIKey = "Setting_Page_Privacy",
    Category = {
      { Key = "Cat_ESP", Text = "ESP", Stack = StackESP },
      { Key = "Cat_Wall", Text = "WALLHACK", Stack = StackWall },
      { Key = "Cat_Combat", Text = "COMBAT", Stack = StackCombat },
      { Key = "Cat_Vis", Text = "VISUALS", Stack = StackVisuals },
      { Key = "Cat_Skin", Text = "SKIN", Stack = StackSkin },
      { Key = "Cat_Misc", Text = "MISC", Stack = StackMisc },
    }
  }
  table.insert(SC, 1, SPD.ModMenu)
  local UIMgr = _G.UIManager
  if UIMgr and not UIMgr._Hooked_V5 then
    local old = UIMgr.ShowUI
    UIMgr.ShowUI = function(config, ...)
      local args = {...}; local n = select("#", ...)
      if config and config.keyName then
        local lk = string.lower(config.keyName)
        if string.find(lk, "setting_main") and not string.find(lk, "custom") then
          local cat = args[1]
          if type(cat) == "table" and cat[1] and cat[1].Key then
            local found = false; for _, p in ipairs(cat) do if p.Key == "ModMenu" then found = true; break end end
            if not found then table.insert(cat, 1, SPD.ModMenu) end
          end
        end
      end
      local up = table.unpack or unpack
      return old(config, up(args, 1, n))
    end
    UIMgr._Hooked_V5 = true
  end
end

_G.ShowWelcomeMenu = function()
  if _G.WelcomeShown then return end
  _G.WelcomeShown = true
  pcall(function()
    local Msg = _G.GetModule("client.slua.logic.common.logic_common_msg_box")
    if not Msg or not Msg.Show then return end
    local title = "GocReal"
    local body = "GocReal v3.3 (AGGRESSIVE)\n===================================\nBypass: 60+ Layers (AGGRESSIVE v3.3)\nSupports: BGMI / PUBG Global / TW / VN / KR\n===================================\n[FIX] ESP Name + Weapon Icon pos fixed\n[FIX] SnapLine Lime=Open Orange=Cover\n[FIX] SnapLine max 600m + no auto-remove\n[FIX] Skeleton instant toggle\n[FIX] iPadView FOV forced\n[NEW] GSC_FPS 165 unlock integrated\n[NEW] Device-Adaptive AUTO Perf\n===================================\nChannel: GocReal\nOwner: @AYUSHKRJ"
    Msg.Show(2, title, body,
      function() pcall(_G.InitModMenuTab); _G.Notify("Mod Menu ready — Settings > GocReal") end,
      function() end, "OK", "CLOSE")
  end)
end

local QuickMenuBtn = { Created = false, Container = nil, Canvas = nil, Slot = nil, _LastCanvasCheck = 0 }
function QuickMenuBtn.Create()
  if QuickMenuBtn.Created and QuickMenuBtn.Container and slua.isValid(QuickMenuBtn.Container) then return true end
  if not _G.PlayerMapMarker then return false end
  if not _G.PlayerMapMarker.ESPCanvas or not slua.isValid(_G.PlayerMapMarker.ESPCanvas) then pcall(function() _G.PlayerMapMarker.InitESPCanvas() end) end
  local Canvas = _G.PlayerMapMarker.ESPCanvas
  if not Canvas or not slua.isValid(Canvas) then return false end
  QuickMenuBtn.Canvas = Canvas; QuickMenuBtn.Created = false; QuickMenuBtn.Container = nil; QuickMenuBtn.Slot = nil
  local Border = nil
  pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", Canvas) end)
  if not Border or not slua.isValid(Border) then return false end
  local LC = _G.getCachedLinearColor()
  local red = LC and LC(0.9, 0.1, 0.1, 0.95) or {R=230, G=25, B=25, A=240}
  pcall(function() Border:SetBrushColor(red) end)
  pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
  pcall(function() Border:SetRenderOpacity(1.0) end)
  local Label = nil
  pcall(function() Label = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Border) end)
  if Label and slua.isValid(Label) then
    pcall(function()
      Label:SetText("MOD"); Label:SetJustification(1)
      local FS = import("SlateColor")
      local wc = LC and LC(1, 1, 1, 1) or {R=255,G=255,B=255,A=255}
      if FS then Label:SetColorAndOpacity(FS(wc)) else Label:SetColorAndOpacity(wc) end
      if Label.Font then local f = Label.Font; f.Size = 24; Label.Font = f end
      Label:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
      if Border.SetContent then Border:SetContent(Label) end
      if Border.AddChild then pcall(function() Border:AddChild(Label) end) end
    end)
  end
  local Slot = nil
  pcall(function() Slot = Canvas:AddChildToCanvas(Border) end)
  if not Slot then return false end
  QuickMenuBtn.Slot = Slot; QuickMenuBtn.Container = Border
  pcall(function()
    Slot:SetAutoSize(false); Slot:SetSize(FVector2D(110, 60)); Slot:SetAlignment(FVector2D(1.0, 0.0))
    Slot:SetPosition(FVector2D(-130, 200)); Slot:SetZOrder(99999)
  end)
  local function OnModBtnClick()
    pcall(function()
      local UI = _G.UIManager
      if UI and UI.ShowUI then
        local SC = _G.GetModule("client.logic.NewSetting.SettingCatalog")
        local SPD = _G.GetModule("client.logic.NewSetting.SettingPageDefine")
        if SC and SPD and SPD.ModMenu then pcall(function() UI.ShowUI({ keyName = "Setting_Main" }, SC) end) end
      end
    end)
  end
  pcall(function()
    if Border.OnMouseButtonDownEvent and Border.OnMouseButtonDownEvent.Add then Border.OnMouseButtonDownEvent:Add(function() OnModBtnClick() end) end
    if Border.SetOnMouseButtonDownEvent then Border:SetOnMouseButtonDownEvent(function() OnModBtnClick() end) end
  end)
  QuickMenuBtn.Created = true
  return true
end
function QuickMenuBtn.Update()
  local curCanvas = _G.PlayerMapMarker and _G.PlayerMapMarker.ESPCanvas
  if QuickMenuBtn.Canvas and curCanvas and QuickMenuBtn.Canvas ~= curCanvas then
    QuickMenuBtn.Created = false; QuickMenuBtn.Container = nil; QuickMenuBtn.Slot = nil; QuickMenuBtn.Canvas = nil
  end
  if not QuickMenuBtn.Created or not QuickMenuBtn.Container or not slua.isValid(QuickMenuBtn.Container) then
    QuickMenuBtn.Created = false; pcall(QuickMenuBtn.Create)
  end
  if QuickMenuBtn.Container and slua.isValid(QuickMenuBtn.Container) then
    pcall(function()
      QuickMenuBtn.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
      QuickMenuBtn.Container:SetRenderOpacity(1.0)
    end)
    if QuickMenuBtn.Slot and slua.isValid(QuickMenuBtn.Slot) then
      pcall(function() QuickMenuBtn.Slot:SetPosition(FVector2D(-110, 180)); QuickMenuBtn.Slot:SetZOrder(9999) end)
    end
  end
end
_G.QuickMenuBtn = QuickMenuBtn

local function MainLoop()
  _G.Safe("main_loop", function()
    _G.TickFrame()
    if _G.QuickMenuBtn and _G.QuickMenuBtn.Update then pcall(_G.QuickMenuBtn.Update) end
    local GD = _G.getCachedGameplayData()
    if not GD then return end
    local pc = GD.GetPlayerController and GD.GetPlayerController()
    local lp = nil
    if Valid(pc) then lp = pc:GetPlayerCharacterSafety() end
    if not Valid(lp) then return end
    if not _G.LexusState.NativeESPReady then _G.InitializeNativeESP() end
    if _G.ApplyNoRecoil then pcall(_G.ApplyNoRecoil) end
    if _G.LexusConfig.AimbotEnabled and _G.ApplyAimbot then pcall(_G.ApplyAimbot) end
    if _G.LexusConfig.SpeedHackEnabled and _G.ApplySpeedHack then pcall(_G.ApplySpeedHack) end
    if _G.LexusConfig.WallbangEnabled  and _G.ApplyWallbang  then pcall(_G.ApplyWallbang)  end
    if not _G.KillInfoHacked and _G.ForceEnableKillCounterUI then pcall(_G.ForceEnableKillCounterUI) end
    if _G.ApplyIpadView then pcall(_G.ApplyIpadView) end
    if _G.ApplyFPSLimit then pcall(_G.ApplyFPSLimit) end
    if _G.LexusConfig and _G.LexusConfig.WeaponGlow and _G.ApplyWeaponGlow and lp then
      pcall(function() _G.ApplyWeaponGlow(lp) end)
    end
    if _G.SkinSystem and _G.SkinSystem.Enabled and _G.SkinSystem.TickLocalPlayer then
      pcall(function() _G.SkinSystem.TickLocalPlayer(lp) end)
    end
    if _G.ApplyCrosshair then pcall(_G.ApplyCrosshair) end
    if _G.ApplyWeaponAimbot then pcall(_G.ApplyWeaponAimbot) end
    if _G.ApplyAutoHeadScope then pcall(_G.ApplyAutoHeadScope) end
    if _G.LexusConfig.EspLoai9 then _G.StartESP() else _G.StopESP() end
    -- Environment (No Grass / Fog / Trees)
    if (_G.LexusConfig.RemoveFog or _G.LexusConfig.RemoveGrass or _G.LexusConfig.RemoveTrees or _G.LexusConfig.BlackSky)
      and _G.ApplyNoGrassFogTrees then
      pcall(_G.ApplyNoGrassFogTrees)
    end
    -- ESP Location Box
    if _G.LexusConfig.ESPLocationBox and _G.ApplyESPLocationBox then
      pcall(_G.ApplyESPLocationBox)
    end
    local allChars = {}
    pcall(function()
      if GD.GetAllPlayerCharacters then allChars = GD.GetAllPlayerCharacters()
      elseif GD.GameCharacters then for _, c in pairs(GD.GameCharacters) do table.insert(allChars, c) end end
    end)
    local validKeys = {}
    local realCount, botCount = 0, 0
    for _, e in pairs(allChars) do
      if Valid(e) and e ~= lp and e.TeamID ~= lp.TeamID then
        local dead = false
        pcall(function()
          if type(e.IsDead) == "function" then dead = e:IsDead()
          elseif e.bIsDead ~= nil then dead = e.bIsDead end
          if e.HealthStatus == 2 then dead = true end
        end)
        local key = _G.GetSafeEnemyKey(e)
        if not dead then
          validKeys[key] = true
          _G.LexusState.EnemyMarks[key] = _G.LexusState.EnemyMarks[key] or { enemy = e }
          local md = _G.LexusState.EnemyMarks[key]
          md.enemy = e
          -- [FIX] Force re-check bot status every ~2s to avoid stale cache
          local now = os.clock()
          if not md.AK_BOT_CONFIRMED or not md._BotCheckTime or (now - md._BotCheckTime) > 2.0 then
            md.AK_IS_BOT = nil
            md.AK_BOT_CONFIRMED = nil
            md._BotCheckTime = now
          end
          local distM = 0
          pcall(function() distM = lp:GetDistanceTo(e) / 100 end)
          _G.ProcessEnemyESP(e, md, lp, distM)
          -- [FIX] CheckIsAI AFTER ProcessEnemyESP so md is fresh
          local isBot, chk = _G.CheckIsAI(e, md)
          -- [FIX] Only count if we got a definitive answer; unresolved = real (safe default)
          if distM <= 600 then
            if chk and isBot then
              botCount = botCount + 1
            else
              realCount = realCount + 1
            end
          end
        end
      end
    end
    for k in pairs(_G.LexusState.EnemyMarks) do
      if not validKeys[k] then _G.LexusState.EnemyMarks[k] = nil end
    end
    _G.UpdateRedBox(realCount, botCount)
    _G.SaveModSettings()
  end)
end

local myToken = 0
local function FastTick()
  if myToken ~= _G.LexusState.LoopToken then return end
  pcall(MainLoop)
  local ticker = _G.GetModule("common.time_ticker")
  if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.1, FastTick) end
end

local function AutoSaveLoop()
  pcall(_G.SaveModSettings)
  local ticker = _G.GetModule("common.time_ticker")
  if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(5.0, AutoSaveLoop) end
end

pcall(function()
  local ticker = _G.GetModule("common.time_ticker")
  if ticker and ticker.AddTimerOnce then
    ticker.AddTimerOnce(4.0, function()
      _G.LoadModSettings()
      _G.InitializeBypass()
      _G.InitializeExtraBypass()
      _G.InitializeAggressiveBypass() -- [NEW] Call Aggressive Bypass
      if _G.SkinBypass and _G.SkinBypass.Init then pcall(_G.SkinBypass.Init) end
      if _G.SkinSystem and _G.SkinSystem.Init then pcall(_G.SkinSystem.Init) end
      AutoSaveLoop()
      print("[AYUSHKRJ] Bypass total: " .. #_G.BypassLog .. " layers active")
      for _, name in ipairs(_G.BypassLog) do print("  [OK] " .. name) end
      if _G.ExtraBypassLog then
        print("[AYUSHKRJ] Extra Bypass total: " .. #_G.ExtraBypassLog .. " layers")
        for _, name in ipairs(_G.ExtraBypassLog) do print("  [EB] " .. name) end
      end
      if _G.AggressiveBypassLog then
        print("[AYUSHKRJ] Aggressive Bypass total: " .. #_G.AggressiveBypassLog .. " layers")
        for _, name in ipairs(_G.AggressiveBypassLog) do print("  [AGGR] " .. name) end
      end
    end)
  end
end)

pcall(function()
  local ticker = _G.GetModule("common.time_ticker")
  if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(6.0, function() FastTick() end) end
end)
pcall(function()
  local ticker = _G.GetModule("common.time_ticker")
  if ticker and ticker.AddTimerOnce then
    ticker.AddTimerOnce(8.0, function()
      _G.InitializeNativeESP()
      _G.Notify("GocReal v3.3 (AGGRESSIVE) loaded — @AYUSHKRJ")
    end)
  end
end)
pcall(function()
  local ticker = _G.GetModule("common.time_ticker")
  if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(11.0, function() pcall(_G.ShowWelcomeMenu) end) end
end)
pcall(function()
  local ticker = _G.GetModule("common.time_ticker")
  if ticker and ticker.AddTimerOnce then
    ticker.AddTimerOnce(13.0, function() _G.Notify("GocReal v3.3 ready — ESP+Icon FIXED | SnapLine Lime/Orange | Skeleton FIXED | GSC_FPS | Device-Adaptive") end)
  end
end)

_G.LexusState.LoopToken = (_G.LexusState.LoopToken or 0) + 1
myToken = _G.LexusState.LoopToken
_G.Notify("GocReal Ready — waiting for match")

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
  { GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature" }
}, "BRPlayerCharacterBase")