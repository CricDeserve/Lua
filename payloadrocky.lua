-- file: <unknown>
-- dialect: lua5.3
-- encoding: auto
-- decompiled by unluac-rs

local r0_0 = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {}, LuaEventContainer = {} }
r0_0.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
r0_0.ServerRPC.ServerRPC_CarryDeadBox = {
    Reliable = true,
    Params = { UEnums.EPropertyClass.Object }
}
r0_0.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
r0_0.MulticastRPC.MulticastRPC_GmPlayAction = {
    Reliable = true,
    Params = { UEnums.EPropertyClass.Int }
}
r0_0.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
    Reliable = true,
    Params = { UEnums.EPropertyClass.Bool }
}
local r0_1 = import("ENetRole")
local r0_2 = import("EPawnState")
local r0_3 = import("ESpecialMovementType")
local r0_4 = import("ESpiderSwingMoveState")
local r0_5 = import("ESurviveWeaponPropSlot")
local r0_6 = import("EParachuteState")
local r0_7 = import("EMovementMode")
local r0_8 = import("EStateType")
local r0_9 = import("ESTEPoseState")
local r0_10 = import("EGameModeType")
local r0_11 = import("STExtraGameStateBase")
local r0_12 = import("KismetSystemLibrary")
local r0_13 = import("STExtraBlueprintFunctionLibrary")
local r0_14 = require("GameLua.GameCore.Data.GameplayData")
local r0_15 = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local r0_16 = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")

-- line 52-53
-- proto#1 params=1 locals=0 upvalues=0 vararg=false
function r0_0.ctor(p1_0)

end

-- line 55-60
-- proto#2 params=1 locals=1 upvalues=2 vararg=false
function r0_0._PostConstruct(p2_0)
    r0_0.__super._PostConstruct(p2_0)
    p2_0:InitAddSpecialMoveInfo()
    p2_0.bCanNearDeathGiveup = true
    print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
end

-- line 62-92
-- proto#3 params=1 locals=6 upvalues=4 vararg=false
function r0_0.ReceiveBeginPlay(p3_0)
    r0_0.__super.ReceiveBeginPlay(p3_0)
    p3_0:AddControlEvent(p3_0, "MovementModeChangedDelegate", p3_0.HandleOnMovementModeChangedNew, p3_0)
    if p3_0:HasAuthority() and p3_0:CheckAddCheckFallingDistanceComponent() then
        local r3_0 = import("CheckFallingDistanceComponent")
        if slua.isValid(r3_0) and not slua.isValid(p3_0:GetComponentByClass(r3_0)) then
            print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
            Game:AddComponent(r3_0, p3_0, "CheckFallingDistanceComponent")
        end
    end
    if slua.isValid(p3_0.STCharacterMovement) then
        p3_0.STCharacterMovement.bPositiveBlowUp = true
    end
    local r3_1 = p3_0.Role
    local r3_2 = r0_1.ROLE_AutonomousProxy
    if r3_1 == r3_2 then
        p3_0:AddControlEvent(p3_0, "OnPawnStateDisabled", p3_0.OnPawnStateChange, p3_0)
        p3_0:AddControlEvent(p3_0, "OnPawnStateEnabled", p3_0.OnPawnStateChange, p3_0)
        p3_0:AddControlEventConditionOnly(p3_0, "OnAttrChangeEventDelegate", {
            AttrName = { "bCanSelfRescue" }
        }, p3_0.CharacterAttrChangeEvent, p3_0)
    end
    if Client then
        printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", p3_0.PlayerKey)
        r0_14.AddCharacter(p3_0.Object)
    else
        p3_0:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
            "FinishedState"
        }, p3_0.HandleFinishedState, p3_0)
    end
end

-- line 94-105
-- proto#4 params=4 locals=2 upvalues=3 vararg=false
function r0_0.CharacterAttrChangeEvent(p4_0, p4_1, p4_2, p4_3)
    r0_0.__super.CharacterAttrChangeEvent(p4_0, p4_1, p4_2, p4_3)
    if p4_0.Object ~= p4_1 then
        return
    end
    local r4_0 = p4_0.Role
    local r4_1 = r0_1.ROLE_AutonomousProxy
    if r4_0 == r4_1 and p4_2 == "bCanSelfRescue" then
        local r4_2 = p4_0:GetPlayerControllerSafety()
        if slua.isValid(r4_2) then
            r4_2:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
        end
    end
end

-- line 107-115
-- proto#5 params=2 locals=1 upvalues=2 vararg=false
function r0_0.OnPawnStateChange(p5_0, p5_1)
    print("BRPlayerCharacterBase:OnPawnStateChange:", p5_1)
    local r5_0 = r0_2.SwitchPP
    if p5_1 == r5_0 then
        local r5_1 = p5_0:GetPlayerControllerSafety()
        if slua.isValid(r5_1) then
            r5_1:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
        end
    end
end

-- line 117-123
-- proto#6 params=1 locals=1 upvalues=1 vararg=false
function r0_0.HandleFinishedState(p6_0)
    print(bWriteLog and "BRPlayerCharacterBase:HandleFinishedState", p6_0.STCharacterMovement)
    if slua.isValid(p6_0.STCharacterMovement) and p6_0.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
        local r6_0 = import("EDynamicSimpleQueryConfigDisableMask")
        p6_0.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(r6_0.Bit0, true)
    end
end

-- line 125-135
-- proto#7 params=1 locals=7 upvalues=3 vararg=false
function r0_0:CheckAddCheckFallingDistanceComponent()
    if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
        local r7_0 = CGameMode.GameModeType
        local r7_1 = tonumber(CGameState.GameModeID)
        local r7_2 = r0_10.ETypicalGameMode
        local r7_3
        if r7_0 == r7_2 then
            r7_3 = true
        else
            local r7_4 = r0_10.EFourInOneGameMode
            if r7_0 == r7_4 then
                r7_3 = true
            else
                local r7_5 = r0_10.EHeavyWeaponGameMode
                r7_3 = r7_0 == r7_5
            end
        end
        print(bWriteLog and "BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent:", r7_0, r7_1, r7_3, not r0_16[r7_1])
        local r7_6 = r7_3 and r7_7
        return r7_6
    end
    return false
end

-- line 137-156
-- proto#8 params=3 locals=2 upvalues=3 vararg=false
function r0_0.LuaHandleParachuteStateChanged(p8_0, p8_1, p8_2)
    r0_0.__super.LuaHandleParachuteStateChanged(p8_0, p8_1, p8_2)
    if not Client then
        local r8_0 = p8_0:GetPlayerControllerSafety()
        if slua.isValid(r8_0) and r8_0.CheckParachuteOpenFeature then
            local r8_1 = r0_6.PS_Opening
            if p8_2 == r8_1 then
                if r8_0.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
                    r8_0.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
                end
            else
                local r8_2 = r0_6.PS_None
                if p8_2 == r8_2 then
                    if r8_0.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
                        r8_0.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
                    end
                    if r8_0.CheckParachuteOpenFeature.ClearTimerAndState then
                        r8_0.CheckParachuteOpenFeature:ClearTimerAndState()
                    end
                end
            end
        end
    end
end

-- line 158-174
-- proto#9 params=1 locals=1 upvalues=1 vararg=false
function r0_0.OnLanded(p9_0)
    printf("BRPlayerCharacterBase:OnLanded PlayerKey:%d", p9_0.PlayerKey)
    if p9_0.HandleOnLanded then
        p9_0:HandleOnLanded(-1)
    end
    if not Client then
        local r9_0 = p9_0:GetPlayerControllerSafety()
        if slua.isValid(r9_0) and r9_0.CheckParachuteOpenFeature then
            if r9_0.CheckParachuteOpenFeature.ClearTimerAndState then
                r9_0.CheckParachuteOpenFeature:ClearTimerAndState()
            end
            if r9_0.CheckParachuteOpenFeature.ResetCheckShowUI then
                r9_0.CheckParachuteOpenFeature:ResetCheckShowUI()
            end
        end
    end
end

-- line 176-181
-- proto#10 params=2 locals=1 upvalues=3 vararg=false
function r0_0.ReceiveEndPlay(p10_0, p10_1)
    r0_0.__super.ReceiveEndPlay(p10_0, p10_1)
    if Client then
        r0_14.RemoveCharacter(p10_0.Object)
    end
end

-- line 183-190
-- proto#11 params=1 locals=3 upvalues=4 vararg=false
function r0_0.IsWarGameMode(p11_0)
    local r11_0 = r0_14:GetGameState()
    if slua.isValid(r11_0) and Game:IsClassOf(r11_0, r0_11) then
        local r11_1 = r11_0.GameModeType
        local r11_2 = r0_10.EWarGameMode
        return r11_1 == r11_2
    end
    return false
end

-- line 192-197
-- proto#12 params=1 locals=2 upvalues=1 vararg=false
function r0_0.BPOnRecycled(p12_0)
    local r12_0 = print
    local r12_1 = bWriteLog and string.format("%s BPOnRecycled()", Game:GetPlainName(p12_0.Object))
    r12_0(r12_1)
    if Client then
        p12_0:ResetMeshRelativeLocationAndRotation()
    end
end

-- line 199-204
-- proto#13 params=1 locals=2 upvalues=1 vararg=false
function r0_0.BPOnRespawned(p13_0)
    local r13_0 = print
    local r13_1 = bWriteLog and string.format("%s BPOnRespawned()", Game:GetPlainName(p13_0.Object))
    r13_0(r13_1)
    if Client then
        p13_0:ResetMeshRelativeLocationAndRotation()
    end
end

-- line 206-212
-- proto#14 params=1 locals=2 upvalues=2 vararg=false
function r0_0.ReceiveOnRecycle(p14_0)
    local r14_0 = print
    local r14_1 = bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()", Game:GetPlainName(p14_0.Object))
    r14_0(r14_1)
    if Client then
        p14_0:ResetMeshRelativeLocationAndRotation()
        r0_14.RemoveCharacter(p14_0.Object)
    end
end

-- line 214-220
-- proto#15 params=1 locals=2 upvalues=2 vararg=false
function r0_0.ReceiveOnSpawn(p15_0)
    local r15_0 = print
    local r15_1 = bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()", Game:GetPlainName(p15_0.Object))
    r15_0(r15_1)
    if Client then
        p15_0:ResetMeshRelativeLocationAndRotation()
        r0_14.AddCharacter(p15_0.Object)
    end
end

-- line 222-235
-- proto#16 params=1 locals=9 upvalues=1 vararg=false
function r0_0:ResetMeshRelativeLocationAndRotation()
    if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
        local r16_0 = FRotator(0, -90, 0)
        local r16_1 = FVector(0, 0, 0)
        if self.Mesh.K2_SetRelativeRotation then
            self.Mesh:K2_SetRelativeRotation(r16_0, false, nil, false)
        end
        self:CacheInitialMeshOffset(r16_1, r16_0)
        local r16_2 = self.Mesh.RelativeRotation
        local r16_3 = Game:QuatToRotator(self.BaseRotationOffset)
        local r16_4, r16_5 = print, bWriteLog
        local r16_6
        if r16_5 then
            local r16_7 = bWriteLog
            if r16_7 then
                r16_6 = string.format("%s ResetMeshRelativeLocationAndRotation() Mesh.RelativeRotation: %s %s %s   Pawn.BaseRotationOffset:%s %s %s ", Game:GetPlainName(self.Object), tostring(r16_2.Pitch), tostring(r16_2.Yaw), tostring(r16_2.Roll), tostring(r16_3.Pitch), tostring(r16_3.Yaw), tostring(r16_3.Roll))
            else
                r16_6 = r16_7
            end
        else
            r16_6 = r16_5
        end
        r16_4(r16_6)
    end
end

-- line 237-247
-- proto#17 params=1 locals=2 upvalues=3 vararg=false
function r0_0.HandleOnMovementModeChangedNew(p17_0)
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
    if Game:IsValid(p17_0.STCharacterMovement) then
        local r17_0 = p17_0.STCharacterMovement.MovementMode
        local r17_1 = r0_7.MOVE_Swimming
        if r17_0 == r17_1 and p17_0:CheckBaseIsMoveable() then
            print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
            p17_0.CharacterMovement:SetBase(nil, "", true)
        end
    end
    local r17_2 = p17_0.Role
    local r17_3 = r0_1.ROLE_AutonomousProxy
    if r17_2 == r17_3 and Game:IsValid(p17_0.STCharacterMovement) then
        local r17_4 = p17_0.STCharacterMovement.MovementMode
        local r17_5 = r0_7.MOVE_Walking
        if r17_4 == r17_5 and UIManager.UI_Config_InGame.ParachuteOpenUI then
            print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
            UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
        end
    end
end

-- line 249-250
-- proto#18 params=1 locals=0 upvalues=0 vararg=false
function r0_0.BPOnMissPlayerDamageRecord(p18_0)

end

-- line 252-278
-- proto#19 params=1 locals=12 upvalues=2 vararg=false
function r0_0.PreAttachedToVehicle(p19_0)
    if not r0_12.IsDedicatedServer(p19_0) then
        return
    end
    local r19_0 = p19_0:GetPlayerControllerSafety()
    if not slua.isValid(r19_0) then
        return
    end
    local r19_1 = p19_0.CharacterAvatarComp2_BP
    if not slua.isValid(r19_1) then
        return
    end
    local r19_2 = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil"):ChangeVehicleSkinByClothes(r19_0, r19_1)
    local r19_3 = import("ESTExtraVehicleShapeType")
    if r19_2 then
        local r19_4 = import("AvatarUtils").GetVehicleShapeBySkinID(r19_2)
        local r19_5 = r19_3.VST_Horse
        if r19_4 == r19_5 then
            local r19_6 = p19_0:GetPlayerStateSafety()
            if slua.isValid(r19_6) then
                local r19_7, r19_8 = print, bWriteLog
                local r19_9
                if r19_8 then
                    local r19_10 = "  BRPlayerCharacterBase:PreAttachedToVehicle. changedVehicleId: "
                    local r19_11 = tostring(r19_2)
                    r19_9 = r19_10 .. r19_11
                else
                    r19_9 = r19_8
                end
                r19_7(r19_9)
                r19_6:AddGeneralCount(468, 1, false)
            end
        end
    end
end

-- line 280-295
-- proto#20 params=1 locals=1 upvalues=3 vararg=false
function r0_0.ParachuteJump(p20_0)
    local r20_0 = p20_0:GetControllerSafety()
    if slua.isValid(r20_0) then
        if p20_0:GetEnsure() then
            EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, p20_0.Object)
            print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump AI JUMP over, Loc=", tostring(p20_0:K2_GetActorLocation():ToString()))
        else
            local r20_1 = r20_0:GetCurrentStateType()
            local r20_2 = r0_8.State_ParachuteJump
            if not (r20_1 == r20_2 or r20_0:GetCurrentStateType() == r0_8.State_ParachuteOpen) then
                p20_0:SwitchPoseState(r0_9.Stand, true, true, true, false)
                r20_0:ReInitParachuteItem()
                r20_0:ServerChangeStatePC(r0_8.State_ParachuteJump)
            end
            print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump over")
        end
    end
end

-- line 297-311
-- proto#21 params=4 locals=4 upvalues=1 vararg=false
function r0_0.OnMovementBaseChangedEvent(p21_0, p21_1, p21_2, p21_3)
    local r21_0 = p21_0.Object
    if p21_1 ~= r21_0 then
        return
    end
    local r21_1 = print
    local r21_2 = bWriteLog and string.format("BRPlayerCharacterBase:OnMovementBaseChangedEvent %s, Base: %s -> %s", p21_1, p21_3, p21_2)
    r21_1(r21_2)
    local r21_3 = p21_0:GetMedievalCraneFromBase(p21_2)
    if r21_3 and r21_3.AddCharacter then
        r21_3:AddCharacter(p21_0.Object)
    else
        local r21_4 = p21_0:GetMedievalCraneFromBase(p21_3)
        if r21_4 and r21_4.RemoveCharacter then
            r21_4:RemoveCharacter(p21_0.Object)
        end
    end
end

-- line 313-325
-- proto#22 params=2 locals=1 upvalues=1 vararg=false
function r0_0:GetMedievalCraneFromBase(p22_1)
    if not (slua.isValid(p22_1) and p22_1.GetOwner) then
        return
    end
    local r22_0 = p22_1:GetOwner()
    if not slua.isValid(r22_0) then
        return
    end
    if not r22_0.AddCharacter then
        return
    end
    return r22_0
end

-- line 327-339
-- proto#23 params=1 locals=3 upvalues=1 vararg=false
function r0_0.CheckForbidFlaregun(p23_0)
    local r23_0 = p23_0:GetPlayerStateSafety()
    if slua.isValid(r23_0) then
        if r23_0.CanUseFlaregun == false and p23_0:IsLocallyControlled() then
            local r23_1 = p23_0:GetPlayerControllerSafety()
            if slua.isValid(r23_1) then
                r23_1:DisplayGameTipWithMsgID(48532)
            end
        end
        return not r23_0.CanUseFlaregun
    end
    return false
end

-- line 341-343
-- proto#24 params=1 locals=0 upvalues=0 vararg=false
function r0_0.ServerRPC_NearDeathGiveupRescue(p24_0)
    p24_0:HandleNearDeathGiveupRescue()
end

-- line 345-354
-- proto#25 params=1 locals=2 upvalues=1 vararg=false
function r0_0:HandleNearDeathGiveupRescue()
    local r25_0 = self.NearDeatchComponent
    if self:IsNearDeath() and slua.isValid(r25_0) and self.bCanNearDeathGiveup == true then
        local r25_1 = self:GetPlayerStateSafety()
        if slua.isValid(r25_1) then
            r25_1:AddGeneralCount(1613, 1, false)
        end
        r25_0:TriggerGotoDieExplictly(self.Object)
    end
end

-- line 356-362
-- proto#26 params=2 locals=10 upvalues=2 vararg=false
function r0_0.RPC_Server_GmPlayAction(p26_0, p26_1)
    local r26_0, r26_1 = log, bWriteLog
    local r26_2
    if r26_1 then
        local r26_3 = "  BRPlayerCharacterBase:RPC_Server_GmPlayAction.  actionId: "
        local r26_4 = tostring(p26_1)
        r26_2 = r26_3 .. r26_4
    else
        r26_2 = r26_1
    end
    r26_0(r26_2)
    if r0_13.IsDevelopment() then
        local r26_5, r26_6 = log, bWriteLog
        local r26_7
        if r26_6 then
            local r26_8 = "  BRPlayerCharacterBase:RPC_Server_GmPlayAction. IsDevelopment actionId: "
            local r26_9 = tostring(p26_1)
            r26_7 = r26_8 .. r26_9
        else
            r26_7 = r26_6
        end
        r26_5(r26_7)
        p26_0:MulticastRPC_GmPlayAction(p26_1)
    end
end

-- line 364-393
-- proto#27 params=2 locals=24 upvalues=1 vararg=false
function r0_0:MulticastRPC_GmPlayAction(p27_1)
    if not Client then
        return
    end
    local r27_0, r27_1 = log, bWriteLog
    local r27_2
    if r27_1 then
        local r27_3 = "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction.  actionId: "
        local r27_4 = tostring(p27_1)
        r27_2 = r27_3 .. r27_4
    else
        r27_2 = r27_1
    end
    r27_0(r27_2)
    local r27_5 = self:GetPlayEmoteComponent()
    if not slua.isValid(r27_5) then
        return
    end
    local r27_6 = require("common.log_filter")
    r27_6.SetLogTreeEnable(true)
    local r27_7 = CDataTable.GetTableData("EmoteBPTable", p27_1)
    if not r27_7 then
        return
    end
    local r27_8 = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
    local r27_9 = slua.loadObject(r27_7.Path)()
    r27_5:OnLoadEmoteAssetBegin(r27_9, p27_1, r27_8, "")
    local r27_10, r27_11 = log, bWriteLog
    local r27_12
    if r27_11 then
        local r27_13 = "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction. assetsArray:Num(): "
        local r27_14 = tostring(r27_8:Num())
        r27_12 = r27_13 .. r27_14
    else
        r27_12 = r27_11
    end
    r27_10(r27_12)
    local r27_15 = FuncUtil.LuaArrayToTable(r27_8)
    local r27_16 = require("common.asset_util")

    -- line 388-390
    -- proto#28 params=0 locals=0 upvalues=3 vararg=false
    function loadLater()
        r27_5:OnLoadEmoteAssetEnd(r27_9, p27_1, 0)
    end

    r27_16.GetAssetsArrayAsyncParallel(r27_15, loadLater)
end

-- line 395-400
-- proto#29 params=2 locals=5 upvalues=1 vararg=false
function r0_0.RPC_Client_SetShouldCheckPassWall(p29_0, p29_1)
    local r29_0, r29_1 = print, bWriteLog
    local r29_2
    if r29_1 then
        local r29_3 = "BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall "
        local r29_4 = tostring(p29_1)
        r29_2 = r29_3 .. r29_4
    else
        r29_2 = r29_1
    end
    r29_0(r29_2)
    if slua.isValid(p29_0.ParachuteComponent) then
        p29_0.ParachuteComponent.bServerSyncShouldCheckPassWall = p29_1
    end
end

-- line 402-409
-- proto#30 params=1 locals=5 upvalues=1 vararg=false
function r0_0:OnPlayerEnterCarryBoxState()
    self.Super:OnPlayerEnterCarryBoxState()
    local r30_0 = self:GetPlayerNameSafety()
    local r30_1, r30_2 = print, bWriteLog
    local r30_3
    if r30_2 then
        r30_3 = string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerEnterCarryBoxState Role:%s PlayerKey:%s Name:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(r30_0))
    else
        r30_3 = r30_2
    end
    r30_1(r30_3)
    if self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
    end
end

-- line 411-418
-- proto#31 params=2 locals=5 upvalues=1 vararg=false
function r0_0:OnPlayerLeaveCarryBoxState(p31_1)
    self.Super:OnPlayerLeaveCarryBoxState(p31_1)
    local r31_0 = self:GetPlayerNameSafety()
    local r31_1, r31_2 = print, bWriteLog
    local r31_3
    if r31_2 then
        r31_3 = string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState Role:%s PlayerKey:%s Name:%s bInIsInterrupt:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(r31_0), tostring(p31_1))
    else
        r31_3 = r31_2
    end
    r31_1(r31_3)
    if self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(p31_1)
    end
end

-- line 420-424
-- proto#32 params=2 locals=0 upvalues=1 vararg=false
function r0_0.ServerRPC_CarryDeadBox(p32_0, p32_1)
    if slua.isValid(p32_1) and Game:IsClassOf(p32_1, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and p32_0.CarryDeadBoxFeature then
        p32_0.CarryDeadBoxFeature:CarryDeadBox(p32_1)
    end
end

-- line 426-428
-- proto#33 params=2 locals=0 upvalues=0 vararg=false
function r0_0.SetAreaID(p33_0, p33_1)
    p33_0:SetAttrValue("AreaID", p33_1, -1)
end

-- line 430-432
-- proto#34 params=1 locals=2 upvalues=1 vararg=false
function r0_0.GetAreaID(p34_0)
    local r34_0 = math.floor
    local r34_1 = p34_0:GetAttrValue("AreaID")
    return r34_0(r34_1 + 0.5)
end

-- line 434-437
-- proto#35 params=1 locals=0 upvalues=1 vararg=false
function r0_0.CannotChangeIntoPetSpectator(p35_0)
    print(bWriteLog and "BRPlayerCharacterBase:CannotChangeIntoPetSpectator")
    return p35_0.bCannotChangeIntoPetSpectator
end

-- line 439-445
-- proto#36 params=1 locals=4 upvalues=2 vararg=false
function r0_0.DoModChangeToBT(p36_0)
    local r36_0 = print
    local r36_1 = bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s", tostring(p36_0.PlayerKey))
    r36_0(r36_1)
    if p36_0:HasState(r0_2.SpecialSuit) then
        p36_0:TriggerEntrySkillWithID(4301101, true)
        local r36_2 = print
        local r36_3 = bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s, HasState(EPawnState.SpecialSuit)", tostring(p36_0.PlayerKey))
        r36_2(r36_3)
    end
end

-- line 447-454
-- proto#37 params=1 locals=0 upvalues=1 vararg=false
function r0_0:SwitchCameraToParachuteOpening()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening")
    self.Super:SwitchCameraToParachuteOpening()
    if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
        self.ParachuteFormation:OverlayFormationCameraParams()
        print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening - Formation camera overlaid")
    end
end

-- line 456-463
-- proto#38 params=1 locals=0 upvalues=1 vararg=false
function r0_0:SwitchCameraToParachuteFalling()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling")
    self.Super:SwitchCameraToParachuteFalling()
    if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
        self.ParachuteFormation:OverlayFormationCameraParams()
        print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling - Formation camera overlaid")
    end
end

-- line 465-471
-- proto#39 params=1 locals=0 upvalues=1 vararg=false
function r0_0:SwitchCameraToNormal()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToNormal")
    self.Super:SwitchCameraToNormal()
    if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
        self.ParachuteFormation:OnLandingClearFormationCamera()
    end
end

-- line 473-500
-- proto#40 params=3 locals=16 upvalues=7 vararg=false
function r0_0:SwitchWeaponCheck(p40_1, p40_2)
    if self:HasState(r0_2.AttachToOther) then
        local r40_0 = self:GetWeaponBySlot(p40_1)
        if slua.isValid(r40_0) then
            local r40_1 = r40_0:GetWeaponID()
            local r40_2 = r0_15.GetCurrentConfig("AttachToOtherConfig")
            if r40_2 and r40_2.CheckIsWeaponInBlackList and r40_2.CheckIsWeaponInBlackList(r40_1) then
                local r40_3, r40_4 = print, bWriteLog
                local r40_5
                if r40_4 then
                    local r40_6 = "BRPlayerCharacterBase:SwitchWeaponCheck not allow switch weapon in AttachToOther, WeaponID: "
                    local r40_7 = tostring(r40_1)
                    r40_5 = r40_6 .. r40_7
                else
                    r40_5 = r40_4
                end
                r40_3(r40_5)
                local r40_8 = self:GetPlayerControllerSafety()
                if Client and slua.isValid(r40_8) and r40_8.Role == r0_1.ROLE_AutonomousProxy then
                    r40_8:DisplayGameTipWithMsgID(47306)
                end
                return false
            end
        end
    end
    if self:HasState(r0_2.WebSwing) then
        local r40_9 = r0_5.SWPS_None
        if p40_1 ~= r40_9 and slua.isValid(self.STCharacterMovement) then
            local r40_10 = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(r0_3.SPECIAL_MOVE_SpiderSwing)
            if slua.isValid(r40_10) then
                local r40_11 = r40_10:GetCurMoveState()
                local r40_12 = r0_4.Launching
                if r40_11 == r40_12 or r40_11 == r0_4.Swinging then
                    local r40_13, r40_14 = print, bWriteLog
                    local r40_15
                    if r40_14 then
                        local r40_16 = "BRPlayerCharacterBase:SwitchWeaponCheck blocked by SpiderSwing state: "
                        local r40_17 = tostring(r40_11)
                        r40_15 = r40_16 .. r40_17
                    else
                        r40_15 = r40_14
                    end
                    r40_13(r40_15)
                    return false
                end
            end
        end
    end
    return self.Super:SwitchWeaponCheck(p40_1, p40_2)
end

-- line 502-506
-- proto#41 params=1 locals=3 upvalues=1 vararg=false
local function r0_17(p41_0)
    local r41_0 = "[ROCKYBHAI711 VIP New] "
    local r41_1 = tostring(p41_0)
    local r41_2 = r41_0 .. r41_1
    pcall(function()
        if _G.LexusNotify then
            _G.LexusNotify(r41_2)
        end
    end)
    pcall(function()
        local r43_0 = import("ScriptHelperClient")
        if r43_0 and r43_0.AddOnScreenDebugMessage then
            r43_0.AddOnScreenDebugMessage(r41_2, -1, 3.0, { R = 1, G = 1, B = 0, A = 1 }, {
                X = 1.2,
                Y = 1.2
            })
        end
    end)
    print(r41_2)
end

local r0_18 = rawget(_G, "slua")

-- line 510-512
-- proto#44 params=1 locals=0 upvalues=2 vararg=false
local function r0_19(p44_0)
    if p44_0 then
        if r0_18 and r0_18.isValid then
            local r44_0, r44_1 = pcall(r0_18.isValid, p44_0)
            if not r44_0 then
                return false
            end
            if not r44_1 then
                return false
            end
        end
        return true
    end
    return false
end

_G.LexusConfig = _G.LexusConfig or {}
_G.LexusState = _G.LexusState or {}
local r0_20 = os.time
local r0_21 = { year = 2026, month = 9, day = 3, hour = 23, min = 59, sec = 0 }
local r0_22 = r0_20(r0_21)
local r0_23 = os.time(os.date("!*t"))
pcall(function()
    local r45_0 = ".sys_time_cache"
    local r45_1 = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. r45_0,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. r45_0,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. r45_0,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. r45_0,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. r45_0,
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. r45_0,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. r45_0,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. r45_0,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. r45_0,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. r45_0,
        "Documents/ShadowTrackerExtra/Saved/SaveGames/" .. r45_0,
        "Documents/ShadowTrackerExtra/Saved/Gamelet/logs/" .. r45_0,
        "/Documents/ShadowTrackerExtra/Saved/SaveGames/" .. r45_0,
        "/Documents/ShadowTrackerExtra/Saved/Gamelet/logs/" .. r45_0,
        "ShadowTrackerExtra/Saved/SaveGames/" .. r45_0,
        "ShadowTrackerExtra/Saved/Gamelet/logs/" .. r45_0,
        "../../ShadowTrackerExtra/Saved/SaveGames/" .. r45_0,
        "../../ShadowTrackerExtra/Saved/Gamelet/logs/" .. r45_0
    }
    if os and os.getenv then
        local r45_2 = os.getenv("HOME")
        if r45_2 and r45_2 ~= "" then
            table.insert(r45_1, 1, r45_2 .. "/Documents/ShadowTrackerExtra/Saved/SaveGames/" .. r45_0)
            table.insert(r45_1, 2, r45_2 .. "/Documents/ShadowTrackerExtra/Saved/Gamelet/logs/" .. r45_0)
        end
    end
    local r45_3 = package.loaded["client.logic.common.TimeManager"]
    local r45_4
    if r45_3 then
        r45_4 = r45_3
    else
        local r45_5, r45_6 = pcall(require, "client.logic.common.TimeManager")
        if r45_5 then
            if r45_6 then
                r45_4 = r45_6
            else
                r45_4 = r45_6
            end
        else
            r45_4 = r45_5
        end
    end
    if r45_4 and type(r45_4.GetServerTime) == "function" then
        local r45_7 = r45_4.GetServerTime()
        if r45_7 and r45_7 > 1700000000 then
            r0_23 = r45_7
        end
    end
    local r45_8 = 0
    for r45_9, r45_10 in ipairs(r45_1) do
        local r45_11 = io.open(r45_10, "r")
        if r45_11 then
            local r45_12 = tonumber(r45_11:read("*a"))
            if not r45_12 then
                r45_12 = 0
            end
            if r45_8 < r45_12 then
                r45_8 = r45_12
            end
            r45_11:close()
        end
    end
    if r0_23 < r45_8 then
        r0_23 = r45_8
    else
        for r45_13, r45_14 in ipairs(r45_1) do
            local r45_15 = io.open(r45_14, "w")
            if r45_15 then
                r45_15:write(tostring(r0_23))
                r45_15:close()
            end
        end
    end
end)
local r0_24 = r0_22 < r0_23

-- line 610-610
-- proto#46 params=0 locals=0 upvalues=0 vararg=false
local function r0_25()
    return true
end

-- line 611-611
-- proto#47 params=0 locals=0 upvalues=0 vararg=false
local function r0_26()
    return false
end

-- line 612-612
-- proto#48 params=0 locals=0 upvalues=0 vararg=false
local function r0_27()
    return 0
end

-- line 613-613
-- proto#49 params=0 locals=0 upvalues=0 vararg=false
local function r0_28()
    return {}
end

-- line 614-614
-- proto#50 params=0 locals=0 upvalues=0 vararg=false
local function r0_29()
    return nil
end

-- line 615-615
-- proto#51 params=0 locals=0 upvalues=0 vararg=false
local function r0_30()
    return true
end

-- line 616-616
-- proto#52 params=0 locals=0 upvalues=0 vararg=false
local function r0_31()
    return ""
end

-- line 618-633
-- proto#53 params=0 locals=0 upvalues=2 vararg=false
local function r0_32()
    pcall(function()
        if slua and slua.getSignature then
            -- line 620-620
            -- proto#55 params=0 locals=0 upvalues=0 vararg=false
            function slua.getSignature()
                return 3735928559
            end
        end
        local r54_0 = package.loaded["slua.loader"]
        if not r54_0 then
            r54_0 = rawget(_G, "slua_loader")
        end
        if r54_0 then
            r54_0.verifyBytecode = r0_30
            r54_0.checkIntegrity = r0_30
            if r54_0.disableSignatureCheck then
                r54_0.disableSignatureCheck = r0_30
            end
        end
        local r54_1 = package.loaded["slua.serialize"]
        if r54_1 then
            r54_1.check = r0_30
            r54_1.verify = r0_30
        end
        if jit and jit.attach then
            jit.attach(function()

            end, "bc")
        end
        if _G.slua_verify then
            _G.slua_verify = r0_30
        end
        if _G.check_slua_integrity then
            _G.check_slua_integrity = r0_30
        end
    end)
end

-- line 635-665
-- proto#57 params=0 locals=0 upvalues=2 vararg=false
local function r0_33()
    pcall(function()
        local r58_0 = import("KismetSystemLibrary")
        if r58_0 then
            r58_0.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            r58_0.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            r58_0.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            r58_0.ExecuteConsoleCommand(nil, "sig.Check 0")
            r58_0.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
        end
        local r58_1 = import("CreativeModeBlueprintLibrary")
        if r58_1 then
            -- line 647-647
            -- proto#59 params=0 locals=0 upvalues=0 vararg=false
            function r58_1.MD5HashByteArray()
                return "00000000000000000000000000000000"
            end

            -- line 648-648
            -- proto#60 params=0 locals=0 upvalues=0 vararg=false
            function r58_1.MD5HashFile()
                return "00000000000000000000000000000000"
            end

            -- line 649-649
            -- proto#61 params=0 locals=0 upvalues=0 vararg=false
            function r58_1.GetContentDiffData()
                return true, "BYPASSED"
            end

            r58_1.VerifyFileIntegrity = r0_30
        end
        if _G.MD5Hash then
            -- line 652-652
            -- proto#62 params=0 locals=0 upvalues=0 vararg=false
            function _G.MD5Hash()
                return "00000000000000000000000000000000"
            end
        end
        if _G.CRC32 then
            -- line 653-653
            -- proto#63 params=0 locals=0 upvalues=0 vararg=false
            function _G.CRC32()
                return 0
            end
        end
        if _G.SHA1 then
            -- line 654-654
            -- proto#64 params=0 locals=0 upvalues=0 vararg=false
            function _G.SHA1()
                return "BYPASS"
            end
        end
        local r58_2 = package.loaded["common.file_hash_checker"]
        if r58_2 then
            r58_2.CheckFileMD5 = r0_30
            r58_2.VerifyAll = r0_30

            -- line 658-658
            -- proto#65 params=0 locals=0 upvalues=0 vararg=false
            function r58_2.GetHash()
                return "BYPASS"
            end
        end
        local r58_3 = package.loaded.TssSdk
        if not r58_3 then
            local r58_4
            r58_3 = r58_4.TssSdk
        end
        if r58_3 then
            -- line 661-661
            -- proto#66 params=0 locals=0 upvalues=0 vararg=false
            function r58_3.GetFileMD5()
                return "BYPASS"
            end

            r58_3.VerifyFileSignature = r0_30
        end
        local r58_5 = import("STExtraBlueprintFunctionLibrary")
        if r58_5 then
            r58_5.CheckMD5 = r0_30

            -- line 663-663
            -- proto#67 params=0 locals=0 upvalues=0 vararg=false
            function r58_5.GetMD5()
                return "BYPASS"
            end

            r58_5.VerifyFile = r0_30
        end
    end)
end


-- ============================================================
-- BYPASS: BGMI 4.6 Updated Anti-Cheat Neutralizer
-- ============================================================
local function r0_bypass_46_termination()
    pcall(function()
        -- BGMI 4.6: Block new TerminationManager / BanProtocol
        local r_termMgr = package.loaded["GameLua.Mod.BaseMod.Common.Security.TerminationManager"]
        if not r_termMgr then
            local ok, m = pcall(require, "GameLua.Mod.BaseMod.Common.Security.TerminationManager")
            if ok then r_termMgr = m end
        end
        if r_termMgr then
            for k, v in pairs(r_termMgr) do
                if type(v) == "function" and (
                    k:find("Terminate") or k:find("Ban") or
                    k:find("Kill") or k:find("Kick") or
                    k:find("Report") or k:find("Notify") or
                    k:find("Detect") or k:find("Suspend")
                ) then
                    pcall(function() r_termMgr[k] = r0_25 end)
                end
            end
        end

        -- BGMI 4.6: Block new PlayerViolationSubsystem
        local r_violSys = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("PlayerViolationSubsystem")
        if r_violSys then
            r_violSys.ReportViolation = r0_25
            r_violSys.HandleViolation = r0_25
            r_violSys.SendViolationData = r0_25
            r_violSys.TriggerTermination = r0_25
            r_violSys.BanPlayer = r0_25
        end

        -- BGMI 4.6: Block AntiModSubsystem (new in 4.6)
        local r_antiMod = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("AntiModSubsystem")
        if r_antiMod then
            r_antiMod.DetectMod = r0_25
            r_antiMod.ReportMod = r0_25
            r_antiMod.ScanLuaEnv = r0_25
            r_antiMod.CheckLuaIntegrity = r0_25
            r_antiMod.ValidateLuaFiles = r0_25
        end

        -- BGMI 4.6: Block new RuntimeScannerSubsystem
        local r_rtScan = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("RuntimeScannerSubsystem")
        if r_rtScan then
            r_rtScan.ScanMemory = r0_25
            r_rtScan.ScanProcess = r0_25
            r_rtScan.ScanLua = r0_25
            r_rtScan.Report = r0_25
            r_rtScan.Tick = r0_25
        end

        -- BGMI 4.6: Null new GameplayIntegrityChecker
        local r_intChk = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("GameplayIntegrityChecker")
        if r_intChk then
            r_intChk.CheckIntegrity = r0_25
            r_intChk.VerifyGameplay = r0_25
            r_intChk.ReportAnomaly = r0_25
        end

        -- BGMI 4.6: Hook new ClientBehaviorMonitor
        local r_behMon = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("ClientBehaviorMonitor")
        if r_behMon then
            r_behMon.RecordBehavior = r0_25
            r_behMon.AnalyzeBehavior = r0_25
            r_behMon.ReportAbnormal = r0_25
            r_behMon.FlagPlayer = r0_25
        end

        -- BGMI 4.6: HawkEye v2 (upgraded from 4.5)
        local r_hawkV2 = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("ClientHawkEyeV2Subsystem")
        if r_hawkV2 then
            r_hawkV2.ReportData = r0_25
            r_hawkV2.CollectData = r0_25
            r_hawkV2.ScanPlayer = r0_25
            r_hawkV2.UploadResult = r0_25
            r_hawkV2.PatrolTick = r0_25
        end

        -- BGMI 4.6: AimVerifySubsystem (new aimbot detector)
        local r_aimVerify = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("AimVerifySubsystem")
        if r_aimVerify then
            r_aimVerify.VerifyAimData = r0_25
            r_aimVerify.ReportAimAnomaly = r0_25
            r_aimVerify.CheckAimPattern = r0_25
            r_aimVerify.FlagAimBot = r0_25
        end

        -- BGMI 4.6: Block new lua_sandbox_checker
        local r_luaSB = package.loaded["client.slua.sandbox.lua_sandbox_checker"]
        if not r_luaSB then
            local ok, m = pcall(require, "client.slua.sandbox.lua_sandbox_checker")
            if ok then r_luaSB = m end
        end
        if r_luaSB then
            r_luaSB.CheckSandbox = r0_25
            r_luaSB.VerifyEnvironment = r0_25
            r_luaSB.DetectInjection = r0_25
            r_luaSB.ReportInjection = r0_25
        end

        -- BGMI 4.6: GameplayCallbacks new entries
        if _G.GameplayCallbacks then
            local r_newCBs_46 = {
                "ReportAimVerify",
                "ReportBehaviorAnomaly",
                "ReportRuntimeScan",
                "OnAntiModDetected",
                "OnTerminationTrigger",
                "ReportViolation",
                "OnPlayerViolation",
                "ReportHawkEyeV2Data",
                "OnLuaIntegrityFail",
                "ReportAimBotDetected",
                "OnRuntimeAnomalyDetected",
                "ReportModInjection",
                "OnGameplayIntegrityFail",
                "SendBehaviorScore",
                "ReportSandboxViolation"
            }
            for _, cbName in ipairs(r_newCBs_46) do
                _G.GameplayCallbacks[cbName] = r0_25
            end
        end

        -- BGMI 4.6: NetUtil packet filter additions
        if NetUtil and NetUtil.SendPacket and NetUtil.IsBypassed then
            -- Already patched by r0_46, but add 4.6 new packet types
        end
    end)
end

-- ============================================================
-- BYPASS: BGMI 4.6 Termination/Kill-Switch Blocker
-- ============================================================
local function r0_bypass_46_killswitch()
    pcall(function()
        -- Block game-level kill switch via GameplayCallbacks
        if _G.GameplayCallbacks then
            local r_orig_dspc = _G.GameplayCallbacks.OnDSPlayerStateChanged
            function _G.GameplayCallbacks.OnDSPlayerStateChanged(pc, reason, p3, p4, p5)
                if reason then
                    local r_low = string.lower(tostring(reason))
                    local r_blocked = {
                        cheatdetected=1, banned=1, kicked=1, suspended=1,
                        violationdetected=1, integrityfailure=1, securityviolation=1,
                        moddetected=1, luaviolation=1, abnormalbehavior=1,
                        terminationrequest=1, killswitch=1, remoteterminate=1,
                        anticheat=1, hawkeyedetected=1, aimverify=1
                    }
                    if r_blocked[r_low] then return end
                end
                if r_orig_dspc then
                    pcall(r_orig_dspc, pc, reason, p3, p4, p5)
                end
            end
        end

        -- Block direct UE4 termination console commands
        local r_ksl = import("KismetSystemLibrary")
        if r_ksl then
            local r_origExec = r_ksl.ExecuteConsoleCommand
            function r_ksl.ExecuteConsoleCommand(ctx, cmd, ...)
                if cmd then
                    local r_lc = string.lower(tostring(cmd))
                    if r_lc:find("quit") or r_lc:find("exit") or
                       r_lc:find("disconnect") or r_lc:find("ban") or
                       r_lc:find("terminate") or r_lc:find("kill") then
                        -- check if it's anti-cheat driven
                        if r_lc:find("anticheat") or r_lc:find("cheat") or
                           r_lc:find("security") or r_lc:find("violation") then
                            return
                        end
                    end
                end
                if r_origExec then
                    return r_origExec(ctx, cmd, ...)
                end
            end
        end

        -- BGMI 4.6: Block new server-side termination RPC
        if _G.SendRPC then
            local r_origRPC = _G.SendRPC
            local r_blocked_rpcs_46 = {
                "RPC_Server_ClientSecMrpcsFlow", "RPC_Server_SwiftHawk",
                "RPC_Server_ClientSwiftHawkWithParams",
                "RPC_Server_ReportSimulateCharacterLocation",
                "RPC_Client_ShootVertifyRes", "RPC_ClientCoronaLab",
                -- 4.6 new RPCs
                "RPC_Server_AimVerifyData", "RPC_Server_BehaviorScore",
                "RPC_Server_AntiModReport", "RPC_Server_TerminatePlayer",
                "RPC_Server_ViolationReport", "RPC_Client_ForceKick",
                "RPC_Client_ForceBan", "RPC_Server_HawkEyeV2Data",
                "RPC_Server_LuaIntegrityFail", "RPC_Server_SandboxViolation"
            }
            function _G.SendRPC(name, ...)
                for _, v in ipairs(r_blocked_rpcs_46) do
                    if name == v then return nil end
                end
                return r_origRPC(name, ...)
            end
        end

        -- BGMI 4.6: NetUtil packet additions
        if NetUtil and NetUtil.SendPacket and NetUtil.IsBypassed then
            local r_orig_sp = NetUtil.SendPacket
            local r_new_blocked = {
                report_aim_verify = 1, report_behavior_score = 1,
                report_anti_mod = 1, force_terminate_player = 1,
                report_violation_v2 = 1, hawkeye_v2_data = 1,
                lua_integrity_fail = 1, sandbox_violation = 1,
                ReportAimVerify = 1, ReportBehaviorScore = 1,
                AntiModReport = 1, TerminatePlayer = 1,
                ViolationReportV2 = 1, HawkEyeV2Data = 1,
                LuaIntegrityFail = 1, SandboxViolation = 1
            }
            function NetUtil.SendPacket(pkt, ...)
                if r_new_blocked[pkt] then return nil end
                return r_orig_sp(pkt, ...)
            end
        end
    end)
end

-- line 666-677
-- proto#68 params=0 locals=0 upvalues=4 vararg=false
local function r0_34()
    pcall(function()
        local r69_0 = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if r69_0 then
            r69_0.ReportEvent = r0_25
            r69_0.ReportDownloadResult = r0_25
            r69_0.ReportODPTDError = r0_25
            r69_0.ReportSkinError = r0_25
        end
        local r69_1 = package.loaded.AvatarUtils
        if r69_1 then
            r69_1.CheckIsWeaponInBlackList = r0_26
            r69_1.IsValidAvatar = r0_30
            r69_1.CheckAvatarIntegrity = r0_30
            r69_1.ReportInvalidAvatar = r0_25
        end
        local r69_2 = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("FileCheckSubsystem")
        if r69_2 then
            r69_2.StartCheck = r0_25
            r69_2.ReportAbnormalFile = r0_25
            r69_2.StopCheck = r0_25
        end
        local r69_3 = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if r69_3 then
            r69_3.Report = r0_25
            r69_3.SendException = r0_25
        end
    end)
end

-- line 678-694
-- proto#70 params=0 locals=0 upvalues=4 vararg=false
local function r0_35()
    pcall(function()
        local r71_0 = import("ScreenshotMTDer")
        if r71_0 then
            -- line 681-681
            -- proto#72 params=0 locals=0 upvalues=0 vararg=false
            function r71_0.MTDePicture()
                return ""
            end

            -- line 681-681
            -- proto#73 params=0 locals=0 upvalues=0 vararg=false
            function r71_0.ReMTDePicture()
                return ""
            end

            r71_0.HasCaptured = r0_30
            r71_0.TakeScreenshot = r0_25
        end
        local r71_1 = package.loaded.TLog
        if not r71_1 then
            local r71_2
            r71_1 = r71_2.TLog
        end
        if r71_1 then
            r71_1.Info = r0_25
            r71_1.Warning = r0_25
            r71_1.Error = r0_25
            r71_1.Debug = r0_25
            r71_1.Report = r0_25
            r71_1.Send = r0_25
            r71_1.Flush = r0_25
        end
        local r71_3 = package.loaded.CrashSight
        if not r71_3 then
            local r71_4
            r71_3 = r71_4.CrashSight
        end
        if r71_3 then
            r71_3.ReportException = r0_25
            r71_3.SetCustomData = r0_25
            r71_3.Log = r0_25
            r71_3.SendCrash = r0_25
            r71_3.ReportUserException = r0_25
        end
        local r71_5 = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if r71_5 then
            r71_5.BugglyPostExceptionFull = r0_26
            r71_5.CheckCanBugglyPostException = r0_26
            r71_5.ReplayReportData = r0_25
            r71_5.ReportGameException = r0_25
            r71_5.PostException = r0_25
        end
        local r71_6 = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if r71_6 then
            r71_6.SendReport = r0_25
            r71_6.SendException = r0_25
            r71_6.UploadLog = r0_25
        end
        for r71_7, r71_8 in ipairs({
            "Firebase",
            "Adjust",
            "AppsFlyer",
            "FacebookAnalytics",
            "GameAnalytics"
        }) do
            local r71_9 = _G[r71_8]
            if r71_9 then
                r71_9.logEvent = r0_25
                r71_9.trackEvent = r0_25
                r71_9.setEnabled = r0_26
                r71_9.sendEvent = r0_25
                r71_9.report = r0_25
            end
        end
    end)
end

-- line 696-720
-- proto#74 params=0 locals=0 upvalues=5 vararg=false
local function r0_36()
    pcall(function()
        local r75_0 = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if r75_0 then
            local r75_1 = {
                "AFKReportorSubsystem",
                "ClientDataStatistcsSubsystem",
                "AvatarExceptionSubsystem",
                "ShootVerifySubSystemClient",
                "MemoryCheckSubsystem",
                "SpeedCheckSubsystem",
                "WallCheckSubsystem",
                "FileCheckSubsystem",
                "BehaviorScoreSubsystem"
            }
            for r75_2, r75_3 in ipairs(r75_1) do
                local r75_4 = r75_0:Get(r75_3)
                if r75_4 then
                    for r75_5, r75_6 in pairs(r75_4) do
                        if type(r75_6) == "function" and (r75_5:find("Report") or r75_5:find("Send") or r75_5:find("Upload") or r75_5:find("Verify") or r75_5:find("Check") or r75_5:find("Validate") or r75_5:find("Scan") or r75_5:find("Detect")) then
                            pcall(function()
                                r75_4[r75_5] = r0_25
                            end)
                        end
                    end
                    if r75_4.ReportPingDelayTimer then
                        r75_4:RemoveGameTimer(r75_4.ReportPingDelayTimer)
                        r75_4.ReportPingDelayTimer = nil
                    end
                    r75_4.DelayCount = 0
                end
            end
        end
        local r75_7 = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if r75_7 then
            r75_7.CheckAvatarException = r0_25
            r75_7.CheckAvatarExceptionOnce = r0_25
            r75_7.ReportAvatarException = r0_25
            r75_7.CheckSlotMeshVisible = r0_26
            r75_7.CheckPawnVisible = r0_26
            r75_7.CheckCanBugglyPostException = r0_26
        end
        local r75_8 = package.loaded.TssSdk
        if not r75_8 then
            local r75_9
            r75_8 = r75_9.TssSdk
        end
        if r75_8 then
            local r75_10 = r75_8.OnRecvData

            -- line 716-716
            -- proto#77 params=1 locals=0 upvalues=2 vararg=false
            function r75_8.OnRecvData(p77_0)
                if type(p77_0) == "string" and (p77_0:find("report", 1, true) or p77_0:find("exception", 1, true) or p77_0:find("cheat", 1, true) or p77_0:find("violation", 1, true) or p77_0:find("hack", 1, true) or p77_0:find("verify", 1, true)) then
                    return
                end
                if r75_10 then
                    r75_10(p77_0)
                end
            end

            r75_8.SendReportInfo = r0_25
            r75_8.ScanMemory = r0_30
            r75_8.IsEmulator = r0_26
            r75_8.GetTssSdkReportInfo = r0_31
            r75_8.CheckEnvironment = r0_30
            r75_8.VerifyProcess = r0_30
        end
    end)
end

-- line 722-734
-- proto#78 params=0 locals=0 upvalues=2 vararg=false
local function r0_37()
    pcall(function()
        local r79_0 = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if r79_0 then
            for r79_1, r79_2 in ipairs({ "GameReportSubsystem", "ReplaySubsystem" }) do
                local r79_3 = r79_0:Get(r79_2)
                if r79_3 then
                    for r79_4, r79_5 in pairs(r79_3) do
                        if type(r79_5) == "function" and (r79_4:find("Report") or r79_4:find("Trace") or r79_4:find("Replay") or r79_4:find("Record") or r79_4:find("Save")) then
                            pcall(function()
                                r79_3[r79_4] = r0_25
                            end)
                        end
                    end
                end
            end
        end
        local r79_6 = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if r79_6 then
            r79_6.ReportReplay = r0_25
            r79_6.SendReportReq = r0_25
            r79_6.UploadReplay = r0_25
        end
    end)
end

-- line 736-743
-- proto#81 params=0 locals=0 upvalues=3 vararg=false
local function r0_38()
    pcall(function()
        local r82_0 = {
            "ReportAimFlow",
            "ReportHitFlow",
            "ReportAttackFlow",
            "ReportSecAttackFlow",
            "ReportFireArms",
            "ReportVerifyInfoFlow",
            "ReportMrpcsFlow",
            "ReportPlayerBehavior",
            "ReportTeammatHurt",
            "ReportMisKillByTeammate",
            "ReportForbitPick",
            "ReportPlayerMoveRoute",
            "ReportPlayerPosition",
            "ReportVehicleMoveFlow",
            "ReportSecTgameMovingFlow",
            "ReportParachuteData",
            "ReportEquipmentFlow",
            "ReportPlayersPing",
            "ReportPlayerIP",
            "ReportPlayerFramePingRecord",
            "ReportDSNetSaturation",
            "ReportNetContinuousSaturate",
            "ReportDSNetRate",
            "ReportCircleFlow",
            "ReportSecMrpcsFlow"
        }
        for r82_1, r82_2 in ipairs(r82_0) do
            if _G[r82_2] then
                _G[r82_2] = r0_25
            end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[r82_2] then
                _G.GameplayCallbacks[r82_2] = r0_25
            end
        end
        for r82_3, r82_4 in ipairs({
            "CheckReportSecAttackFlowWithAttackFlow",
            "CheckReportSecAttackFlow"
        }) do
            if _G[r82_4] then
                _G[r82_4] = r0_26
            end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[r82_4] then
                _G.GameplayCallbacks[r82_4] = r0_26
            end
        end
        for r82_5, r82_6 in ipairs({
            "IsEnableReportMrpcsInCircleFlow",
            "IsEnableReportMrpcsInPartCircleFlow",
            "IsEnableReportMrpcsFlow",
            "IsEnableReportAttackFlow",
            "IsEnableReportHitFlow",
            "IsEnableReportCircleFlow"
        }) do
            if _G[r82_6] then
                _G[r82_6] = r0_26
            end
        end
    end)
end

-- line 745-753
-- proto#83 params=0 locals=0 upvalues=4 vararg=false
local function r0_39()
    pcall(function()
        for r84_0, r84_1 in ipairs({
            "PlayerSecurityInfoCollector",
            "PlayerSecurityInfo",
            "SecurityInfoCollector",
            "ClientSecurityCollector",
            "PlayerAntiCheatCollector"
        }) do
            if _G[r84_1] then
                for r84_2, r84_3 in pairs(_G[r84_1]) do
                    if type(r84_3) == "function" and (r84_2:find("Report") or r84_2:find("Collect") or r84_2:find("Send") or r84_2:find("Upload") or r84_2:find("Record")) then
                        _G[r84_1][r84_2] = r0_25
                    end
                end
            end
        end
        local r84_4 = require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
        if r84_4 then
            r84_4.ReportData = r0_25
            r84_4.CheckCheat = r0_26
            r84_4.ValidatePlayer = r0_30
            r84_4.CollectData = r0_25
            r84_4.SendToServer = r0_25
        end
    end)
end

-- line 755-762
-- proto#85 params=0 locals=0 upvalues=2 vararg=false
local function r0_40()
    pcall(function()
        for r86_0, r86_1 in ipairs({
            "ClientSecMrpcsFlow",
            "MrpcsFlow",
            "MrpcsData",
            "ClientCircleFlowSubsystem",
            "ClientKillFlowSubsystem",
            "ClientSecPlayerKillFlow"
        }) do
            local r86_2 = package.loaded[r86_1]
            if not r86_2 then
                local r86_3
                r86_2 = r86_3[r86_1]
            end
            if r86_2 then
                for r86_4, r86_5 in pairs(r86_2) do
                    if type(r86_5) == "function" and (r86_4:find("Report") or r86_4:find("Send") or r86_4:find("Flow") or r86_4:find("Record") or r86_4:find("Process")) then
                        pcall(function()
                            r86_2[r86_4] = r0_25
                        end)
                    end
                end
            end
        end
    end)
end

-- line 764-770
-- proto#88 params=0 locals=0 upvalues=2 vararg=false
local function r0_41()
    pcall(function()
        for r89_0, r89_1 in ipairs({
            "SwiftHawk",
            "ClientSwiftHawk",
            "ClientSwiftHawkWithParams",
            "SendSwiftHawkData"
        }) do
            if _G[r89_1] then
                _G[r89_1] = r0_25
            end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[r89_1] then
                _G.GameplayCallbacks[r89_1] = r0_25
            end
        end
        local r89_2 = package.loaded["GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"]
        if r89_2 then
            r89_2.ReportData = r0_25
            r89_2.SendReport = r0_25
            r89_2.CollectTelemetry = r0_25
        end
    end)
end

-- line 772-778
-- proto#90 params=0 locals=0 upvalues=2 vararg=false
local function r0_42()
    pcall(function()
        if _G.CoronaLab then
            _G.CoronaLab.ReportData = r0_25
            _G.CoronaLab.SendData = r0_25
            _G.CoronaLab.CollectData = r0_25
            _G.CoronaLab.Telemetry = r0_25
        end
        local r91_0 = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("CoronaLabSubsystem")
        if r91_0 then
            r91_0.ReportData = r0_25
            r91_0.SendToServer = r0_25
            r91_0.CollectTelemetry = r0_25
            r91_0.StopCollection = r0_25
        end
    end)
end

-- line 780-786
-- proto#92 params=0 locals=0 upvalues=3 vararg=false
local function r0_43()
    pcall(function()
        if _G.bReportedModifierException then
            _G.bReportedModifierException = false
        end
        local r93_0 = require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
        if r93_0 then
            r93_0.ReportException = r0_25
            r93_0.CheckModifier = r0_30
            r93_0.ValidateModifier = r0_30
            r93_0.ReportModifierError = r0_25
        end
    end)
end

-- line 788-793
-- proto#94 params=0 locals=0 upvalues=3 vararg=false
local function r0_44()
    pcall(function()
        local r95_0 = require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
        if r95_0 then
            r95_0.ReportLocation = r0_25
            r95_0.SendLocationData = r0_25
            r95_0.VerifyLocation = r0_30
        end
    end)
end

-- line 795-801
-- proto#96 params=0 locals=0 upvalues=3 vararg=false
local function r0_45()
    pcall(function()
        local r97_0 = require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if r97_0 then
            r97_0.OnShootVerifyFailed = r0_25
            r97_0.SendVerifyData = r0_25
            r97_0.ReportBulletHit = r0_25
            r97_0.UploadHitInfo = r0_25
            r97_0.VerifyShot = r0_30
        end
        if _G.BulletHitInfoUploadData then
            _G.BulletHitInfoUploadData.Report = r0_25
            _G.BulletHitInfoUploadData.Send = r0_25
            _G.BulletHitInfoUploadData.Upload = r0_25
        end
    end)
end

-- line 803-829
-- proto#98 params=0 locals=0 upvalues=1 vararg=false
local function r0_46()
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local r99_0 = NetUtil.SendPacket
            local r99_1 = {
                ReportAttackFlow = 1,
                ReportSecAttackFlow = 1,
                ReportFireArms = 1,
                ReportVerifyInfoFlow = 1,
                ReportMrpcsFlow = 1,
                ReportPlayerBehavior = 1,
                ReportTeammatHurt = 1,
                ReportPlayerMoveRoute = 1,
                ReportPlayerPosition = 1,
                ReportSecVehicleMoveFlow = 1,
                report_parachute_data = 1,
                on_tss_sdk_anti_data = 1,
                ReportAimFlow = 1,
                ReportHitFlow = 1,
                ReportCircleFlow = 1,
                report_players_ping = 1,
                report_player_ip = 1,
                report_net_saturate = 1,
                report_speed_hack = 1,
                report_wall_hack = 1,
                report_aim_bot = 1,
                report_esp_usage = 1,
                report_modded_files = 1,
                detect_cheat = 1,
                ban_player = 1,
                client_anti_cheat_report = 1,
                ClientSecMrpcsFlow = 1,
                MrpcsData = 1,
                CheckReportSecAttackFlow = 1,
                CheckReportSecAttackFlowWithAttackFlow = 1,
                RPC_ClientCoronaLab = 1,
                CoronaLabReport = 1,
                CoronaLabData = 1,
                PlayerSecurityInfo = 1,
                ReportSecurityInfo = 1,
                SendSecurityData = 1,
                ClientCircleFlow = 1,
                IsEnableReportMrpcsInCircleFlow = 1,
                IsEnableReportMrpcsInPartCircleFlow = 1,
                bReportedModifierException = 1,
                ReportModifierException = 1,
                RPC_Server_ReportSimulateCharacterLocation = 1,
                ReportSimulateCharacterLocation = 1,
                RPC_Client_ShootVertifyRes = 1,
                BulletHitInfoUploadData = 1,
                ShootVerifyFailed = 1,
                report_unrealnet_exception = 1,
                tss_sdk_report = 1,
                SwiftHawk = 1,
                ClientSwiftHawk = 1,
                ClientSwiftHawkWithParams = 1,
                SwiftHawkReport = 1,
                SwiftHawkData = 1,
                AntiCheatReport = 1,
                CheatDetection = 1,
                ViolationReport = 1,
                SecurityViolation = 1,
                IntegrityCheck = 1,
                SignatureVerify = 1
            }

            -- line 820-820
            -- proto#100 params=1 locals=0 upvalues=2 vararg=true
            function NetUtil.SendPacket(p100_0, ...)
                if r99_1[p100_0] then
                    return nil
                end
                return r99_0(p100_0, ...)
            end

            NetUtil.IsBypassed = true
        end
        if _G.SendRPC then
            local r99_2 = _G.SendRPC
            local r99_3 = {
                "RPC_Server_ClientSecMrpcsFlow",
                "RPC_Server_SwiftHawk",
                "RPC_Server_ClientSwiftHawkWithParams",
                "RPC_Server_ReportSimulateCharacterLocation",
                "RPC_Client_ShootVertifyRes",
                "RPC_ClientCoronaLab"
            }

            -- line 826-826
            -- proto#101 params=1 locals=2 upvalues=3 vararg=true
            function _G.SendRPC(p101_0, ...)
                for r101_0, r101_1 in ipairs(r99_3) do
                    if p101_0 == r101_1 then
                        return nil
                    end
                end
                return r99_2(p101_0, ...)
            end
        end
    end)
end

-- line 831-848
-- proto#102 params=0 locals=0 upvalues=5 vararg=false
local function r0_47()
    pcall(function()
        local r103_0 = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if r103_0 then
            for r103_1, r103_2 in ipairs({
                "ControlMHActive",
                "Tick",
                "OnTick",
                "MHActiveLogic",
                "TriggerAvatarCheck",
                "StartAvatarCheck",
                "ReportItemID",
                "ReceiveAnyDamage",
                "OnWeaponHitRecord",
                "ShowSecurityAlert",
                "ServerReportAvatar",
                "ClientReportNetAvatar",
                "SendHisarData",
                "ValidateSecurityData",
                "StaticShowSecurityAlertInDev",
                "RPC_Client_ShootVertifyRes",
                "RPC_Server_ReportSimulateCharacterLocation",
                "DisableHiggsBoson",
                "CheckMHActive",
                "ReportViolation",
                "ProcessSecurityEvent",
                "ValidatePlayer",
                "CheckIntegrity"
            }) do
                if r103_0[r103_2] then
                    r103_0[r103_2] = r0_25
                end
            end
            r103_0.GetNetAvatarItemIDs = r0_28
            r103_0.GetCurWeaponSkinID = r0_27
            r103_0.IsMHActive = r0_26
            r103_0.bMHActive = false
            r103_0.bCallPreReplication = false
            if r103_0.BlackList then
                for r103_3 in pairs(r103_0.BlackList) do
                    r103_0.BlackList[r103_3] = nil
                end
            end
        end
        _G.BlackList = {}
        local r103_4 = slua_GameFrontendHUD
        if r103_4 then
            r103_4 = slua_GameFrontendHUD:GetPlayerController()
        end
        if slua.isValid(r103_4) then
            if r103_4.HiggsBoson then
                r103_4.HiggsBoson.bMHActive = false
                r103_4.HiggsBoson.bCallPreReplication = false
                if r103_4.HiggsBoson.ControlMHActive then
                    r103_4.HiggsBoson:ControlMHActive(0)
                end
            end
            if r103_4.HiggsBosonComponent then
                r103_4.HiggsBosonComponent.bMHActive = false
                r103_4.HiggsBosonComponent.bCallPreReplication = false
                r103_4.HiggsBosonComponent:ControlMHActive(0)
            end
        end
    end)
end

-- line 850-861
-- proto#104 params=0 locals=0 upvalues=2 vararg=false
local function r0_48()
    pcall(function()
        local r105_0 = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if r105_0 and r105_0.StaticShowSecurityAlertInDev then
            r105_0.StaticShowSecurityAlertInDev = r0_25
        end
    end)
    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = r0_25
        _G.AvatarCheckCallback.OnReportItemID = r0_25

        -- line 857-859
        -- proto#106 params=1 locals=0 upvalues=1 vararg=false
        function _G.AvatarCheckCallback.PostPlayerControllerLoginInit(p106_0)
            if slua.isValid(p106_0) and p106_0.HiggsBosonComponent then
                p106_0.HiggsBosonComponent:ControlMHActive(0)
                p106_0.HiggsBosonComponent.bMHActive = false
            end
        end
    end
end

-- line 863-870
-- proto#107 params=0 locals=0 upvalues=2 vararg=false
local function r0_49()
    pcall(function()
        for r108_0, r108_1 in ipairs({
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "Client.Security.ClientReportPlayerSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"
        }) do
            local r108_2 = package.loaded[r108_1]
            local r108_3
            if r108_2 then
                r108_3 = r108_2
            else
                local r108_4, r108_5 = pcall(require, r108_1)
                if r108_4 then
                    if r108_5 then
                        r108_3 = r108_5
                    else
                        r108_3 = r108_5
                    end
                else
                    r108_3 = r108_4
                end
            end
            if r108_3 then
                for r108_6, r108_7 in pairs(r108_3) do
                    if type(r108_7) == "function" and (r108_6:find("Report") or r108_6:find("Record") or r108_6:find("Send") or r108_6:find("Upload") or r108_6:find("Notify")) then
                        pcall(function()
                            r108_3[r108_6] = r0_25
                        end)
                    end
                end
            end
        end
    end)
end

-- line 872-889
-- proto#110 params=0 locals=0 upvalues=3 vararg=false
local function r0_50()
    pcall(function()
        if not _G.GameplayCallbacks then
            _G.GameplayCallbacks = {}
        end
        if _G.GameplayCallbacks.IsBypassed then
            return
        end
        local r111_0 = _G.GameplayCallbacks
        local r111_1 = {
            "ReportAttackFlow",
            "ReportSecAttackFlow",
            "ReportFireArms",
            "ReportVerifyInfoFlow",
            "ReportMrpcsFlow",
            "ReportPlayerBehavior",
            "ReportTeammatHurt",
            "ReportMisKillByTeammate",
            "ReportForbitPick",
            "ReportPlayerMoveRoute",
            "ReportPlayerPosition",
            "ReportVehicleMoveFlow",
            "ReportSecTgameMovingFlow",
            "ReportParachuteData",
            "SendTssSdkAntiDataToLobby",
            "ReportEquipmentFlow",
            "ReportAimFlow",
            "ReportPlayersPing",
            "ReportPlayerIP",
            "ReportPlayerFramePingRecord",
            "OnDSConnectionSaturated",
            "ReportDSNetSaturation",
            "ReportNetContinuousSaturate",
            "ReportDSNetRate",
            "SendClientStats",
            "SendServerAvgTickDelta",
            "ReportCircleFlow",
            "ClientSecMrpcsFlow",
            "SwiftHawk",
            "ClientSwiftHawk",
            "ClientSwiftHawkWithParams"
        }
        for r111_2, r111_3 in ipairs(r111_1) do
            r111_0[r111_3] = r0_25
        end
        r111_0.CheckReportSecAttackFlowWithAttackFlow = r0_26
        r111_0.CheckReportSecAttackFlow = r0_26
        local r111_4 = r111_0.OnDSPlayerStateChanged

        -- line 881-886
        -- proto#112 params=5 locals=0 upvalues=2 vararg=false
        function r111_0.OnDSPlayerStateChanged(p112_0, p112_1, p112_2, p112_3, p112_4)
            local r112_0 = p112_1 and string.lower(tostring(p112_1)) or ""
            local r112_1 = {
                cheatdetected = 1,
                connectionlost = 1,
                connectiontimeout = 1,
                connectionexception = 1,
                netdrivererror = 1,
                banned = 1,
                kicked = 1,
                suspended = 1,
                violationdetected = 1,
                integrityfailure = 1,
                securityviolation = 1
            }
            if r112_1[r112_0] then
                return
            end
            if r111_4 then
                pcall(r111_4, p112_0, p112_1, p112_2, p112_3, p112_4)
            end
        end

        r111_0.OnPlayerNetConnectionClosed = r0_25
        r111_0.OnPlayerActorChannelError = r0_25
        r111_0.OnPlayerRPCValidateFailed = r0_25
        r111_0.OnPlayerSpectateException = r0_25
        r111_0.OnShutdownAfterError = r0_25
        r111_0.IsBypassed = true
    end)
end

-- line 891-906
-- proto#113 params=0 locals=0 upvalues=2 vararg=false
local function r0_51()
    pcall(function()
        local r114_0 = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not r114_0 then
            return
        end
        local r114_1 = {
            "CoronaLabSubsystem",
            "PlayerSecurityInfoSubsystem",
            "ClientCircleFlowSubsystem",
            "ModifierExceptionSubsystem",
            "SimulateCharacterSubsystem",
            "ShootVerifySubSystemClient",
            "HiggsBosonComponent",
            "ClientReportPlayerSubsystem",
            "DSReportPlayerSubsystem",
            "ClientHawkEyePatrolSubsystem",
            "DSHawkEyePatrolSubsystem",
            "ClientDataStatistcsSubsystem",
            "AFKReportorSubsystem",
            "BehaviorScoreSubsystem",
            "FileCheckSubsystem",
            "MemoryCheckSubsystem",
            "SpeedCheckSubsystem",
            "WallCheckSubsystem",
            "AvatarExceptionSubsystem",
            "GameReportSubsystem",
            "ClientSecMrpcsFlowSubsystem",
            "MrpcsFlowSubsystem",
            "CircleFlowSubsystem",
            "SwiftHawkSubsystem",
            "AntiCheatSubsystem",
            "IntegrityCheckSubsystem",
            "SignatureVerifySubsystem",
            "MD5CheckSubsystem",
            "PakVerifySubsystem"
        }
        for r114_2, r114_3 in ipairs(r114_1) do
            local r114_4 = r114_0:Get(r114_3)
            if r114_4 then
                for r114_5, r114_6 in pairs(r114_4) do
                    if type(r114_6) == "function" and (r114_5:find("Report") or r114_5:find("Send") or r114_5:find("Upload") or r114_5:find("Verify") or r114_5:find("Check") or r114_5:find("Validate") or r114_5:find("Scan") or r114_5:find("Detect") or r114_5:find("Collect") or r114_5:find("Flow") or r114_5:find("Heartbeat")) then
                        pcall(function()
                            r114_4[r114_5] = r0_25
                        end)
                    end
                end
                if r114_4.timer then
                    pcall(function()
                        r114_4:RemoveGameTimer(r114_4.timer)
                    end)
                end
                if r114_4.heartbeatTimer then
                    pcall(function()
                        r114_4:RemoveGameTimer(r114_4.heartbeatTimer)
                    end)
                end
                if r114_4.reportTimer then
                    pcall(function()
                        r114_4:RemoveGameTimer(r114_4.reportTimer)
                    end)
                end
            end
        end
    end)
end

-- line 908-915
-- proto#119 params=0 locals=0 upvalues=1 vararg=false
local function r0_52()
    pcall(function()
        for r120_0, r120_1 in ipairs({
            "ENABLE_REPORT",
            "ENABLE_ANTI_CHEAT",
            "ENABLE_SECURITY",
            "ENABLE_TELEMETRY",
            "ENABLE_ANALYTICS",
            "ENABLE_CRASH_REPORT",
            "ENABLE_PERFORMANCE_REPORT"
        }) do
            if _G[r120_1] then
                _G[r120_1] = false
            end
        end
        local r120_2 = require
        local r120_3 = {
            "HiggsBosonComponent",
            "PlayerSecurityInfoSubsystem",
            "CoronaLabSubsystem",
            "ClientCircleFlowSubsystem",
            "ModifierExceptionSubsystem",
            "ShootVerifySubSystemClient",
            "ClientReportPlayerSubsystem",
            "DSReportPlayerSubsystem"
        }

        -- line 913-913
        -- proto#121 params=1 locals=2 upvalues=3 vararg=false
        function _G.require(p121_0)
            for r121_0, r121_1 in ipairs(r120_3) do
                if p121_0:find(r121_1) then
                    return {}
                end
            end
            return r120_2(p121_0)
        end
    end)
end

-- line 917-938
-- proto#122 params=0 locals=0 upvalues=2 vararg=false
local function r0_53()
    pcall(function()
        local r123_0 = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local r123_1
        if r123_0 then
            local r123_2 = r123_0:Get("OperationalStatsSubsystem")
            if r123_2 then
                r123_1 = r123_2
            else
                r123_1 = _G.OperationalStatsSubsystem
            end
        else
            r123_1 = _G.OperationalStatsSubsystem
        end
        if r123_1 then
            r123_1.ReportOperationalStats = r0_25
            r123_1.AddOperationalStats = r0_25
            r123_1.HandleTouchBegin = r0_25
            r123_1.HandleTouchEnd = r0_25
            r123_1.OnInit = r0_25
            r123_1.HandleEnterFighting = r0_25
            r123_1.OnBattleResult = r0_25
            if r123_1.TimerHandle then
                pcall(function()
                    r123_1:RemoveGameTimer(r123_1.TimerHandle)
                end)
                r123_1.TimerHandle = nil
            end
            r123_1.StatsData = {}
            print("[ULTIMATE BYPASS] OperationalStatsSubsystem blocked!")
        end
    end)
end

-- line 940-967
-- proto#125 params=0 locals=0 upvalues=23 vararg=false
function _G.StartBypass_VIP_v3()
    pcall(function()
        print("[ULTIMATE BYPASS] Starting initialization...")
        r0_32()
        r0_33()
        r0_34()
        r0_35()
        r0_36()
        r0_37()
        r0_38()
        r0_39()
        r0_40()
        r0_41()
        r0_42()
        r0_43()
        r0_44()
        r0_45()
        r0_46()
        r0_47()
        r0_48()
        r0_49()
        r0_50()
        r0_51()
        r0_53()
        r0_52()
        r0_bypass_46_termination()
        r0_bypass_46_killswitch()
        print("[ULTIMATE BYPASS] Complete - All Security Systems Disabled (BGMI 4.6)")
    end)
end

-- line 969-979
-- proto#127 params=6 locals=1 upvalues=1 vararg=false
local function r0_54(p127_0, p127_1, p127_2, p127_3, p127_4, p127_5)
    local r127_0 = nil
    pcall(function()
        local r128_0 = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if r128_0 and r128_0.ClientAddMapMark then
            r127_0 = r128_0.ClientAddMapMark(p127_0, p127_1, p127_2, p127_3, p127_4, p127_5)
            if r127_0 then
                local r128_1 = _G.LexusState
                r128_1.TrackedMarks[r127_0] = true
            end
        end
    end)
    return r127_0
end

-- line 981-993
-- proto#129 params=1 locals=1 upvalues=1 vararg=false
local function r0_55(p129_0)
    if not p129_0 then
        return
    end
    pcall(function()
        local r130_0 = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if r130_0 and r130_0.HideMapMark then
            r130_0.HideMapMark(p129_0)
        end
        if r130_0 and r130_0.RemoveMapMark then
            r130_0.RemoveMapMark(p129_0)
        end
    end)
    local r129_0 = _G.LexusState
    r129_0.TrackedMarks[p129_0] = nil
end

-- line 995-1001
-- proto#131 params=1 locals=0 upvalues=2 vararg=false
local function r0_56(p131_0)
    if r0_19(p131_0) then
        if p131_0.PlayerKey then
            return tostring(p131_0.PlayerKey)
        end
        if type(p131_0.GetUniqueID) == "function" then
            return tostring(p131_0:GetUniqueID())
        end
    end
    return tostring(p131_0)
end

-- line 1003-1029
-- proto#132 params=2 locals=2 upvalues=2 vararg=false
local function r0_57(p132_0, p132_1)
    if p132_1.AK_IS_BOT == nil then
        local r132_0, r132_1 = false, false
        pcall(function()
            if p132_0.bIsAI == true or p132_0.IsAI == true then
                r132_0 = true
                r132_1 = true
            end
            if type(p132_0.IsBot) == "function" and p132_0:IsBot() then
                r132_0 = true
                r132_1 = true
            end
            local r133_0 = p132_0.PlayerState
            local r133_1
            if r133_0 then
                r133_1 = r133_0
            elseif type(p132_0.GetPlayerState) == "function" then
                r133_1 = p132_0:GetPlayerState()
            else
                r133_1 = false
            end
            if r0_19(r133_1) then
                r132_1 = true
                if r133_1.bIsABot == true or r133_1.bIsBot == true then
                    r132_0 = true
                end
                if type(r133_1.IsBot) == "function" and r133_1:IsBot() then
                    r132_0 = true
                end
            end
            if not r132_0 then
                local r133_2 = p132_0.PlayerName
                if not r133_2 then
                    r133_2 = type(p132_0.GetPlayerName) == "function" and p132_0:GetPlayerName() or ""
                end
                if r133_2 ~= "" and (r133_2:find("Cobra") or r133_2:find("Target") or r133_2:find("bot_") or r133_2:find("b_")) then
                    r132_0 = true
                    r132_1 = true
                end
            end
        end)
        if r132_1 then
            p132_1.AK_IS_BOT = r132_0
        end
        return r132_0, r132_1
    end
    return p132_1.AK_IS_BOT, true
end

-- line 1031-1061
-- proto#134 params=1 locals=1 upvalues=1 vararg=false
local function r0_58(p134_0)
    local r134_0 = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "/Documents/ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. p134_0,
        "/com.tencent.ig/Documents/ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "/com.vng.pubgmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "/com.pubg.krmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "/com.rekoo.pubgm/Documents/ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "/com.pubg.imobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "../../ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "../../../ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        "../../../../ShadowTrackerExtra/Saved/Paks/" .. p134_0,
        p134_0
    }
    pcall(function()
        if os and os.getenv then
            local r135_0 = os.getenv("HOME")
            if r135_0 and r135_0 ~= "" then
                table.insert(r134_0, 1, r135_0 .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. p134_0)
                table.insert(r134_0, 2, r135_0 .. "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. p134_0)
            end
        end
    end)
    return r134_0
end

local r0_59 = "ROCKYBHAI711_settings.txt"
_G.LastConfigSaveStr = ""

-- line 1066-1093
-- proto#136 params=0 locals=0 upvalues=3 vararg=false
function _G.SaveModSettings()
    pcall(function()
        local r137_0 = [[return {
LexusConfig = {
]]
        for r137_1, r137_2 in pairs(_G.LexusConfig or {}) do
            local r137_3 = tostring(r137_1)
            local r137_4 = tostring(r137_2)
            r137_0 = r137_0 .. '  ["' .. r137_3 .. '"] = ' .. r137_4 .. [[,
]]
        end
        local r137_5 = r137_0 .. [[},
CustomTextData = {
]]
        if _G.LexusState and _G.LexusState.CustomTextData then
            local r137_6 = pairs
            local r137_7 = _G.LexusState
            local r137_8, r137_9, r137_10 = r137_6(r137_7.CustomTextData)
            r137_5 = r137_5
            for r137_11, r137_12 in r137_8, r137_9, r137_10 do
                local r137_13 = tostring(r137_11)
                local r137_14 = tostring(r137_12)
                r137_5 = r137_5 .. '  ["' .. r137_13 .. '"] = ' .. r137_14 .. [[,
]]
            end
        end
        local r137_15 = r137_5 .. [[}
}]]
        local r137_16 = _G.LastConfigSaveStr
        if r137_15 == r137_16 then
            return
        end
        _G.LastConfigSaveStr = r137_15
        for r137_17, r137_18 in ipairs(r0_58(r0_59)) do
            local r137_19 = io.open(r137_18, "w")
            if r137_19 then
                r137_19:write(r137_15)
                r137_19:close()
                break
            end
        end
    end)
end

-- line 1095-1129
-- proto#138 params=0 locals=0 upvalues=3 vararg=false
function _G.LoadModSettings()
    pcall(function()
        local r139_0 = r0_58(r0_59)
        local r139_1 = nil
        for r139_2, r139_3 in ipairs(r139_0) do
            local r139_4 = io.open(r139_3, "r")
            if r139_4 then
                r139_1 = r139_4:read("*a")
                r139_4:close()
                break
            end
        end
        if r139_1 then
            local r139_5 = load(r139_1)
            if r139_5 then
                local r139_6 = r139_5()
                if r139_6 and type(r139_6) == "table" then
                    if r139_6.LexusConfig then
                        for r139_7, r139_8 in pairs(r139_6.LexusConfig) do
                            _G.LexusConfig[r139_7] = r139_8
                        end
                    end
                    if r139_6.CustomTextData then
                        _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
                        for r139_9, r139_10 in pairs(r139_6.CustomTextData) do
                            local r139_11 = _G.LexusState
                            r139_11.CustomTextData[r139_9] = r139_10
                        end
                    end
                end
            end
        end
        _G.SaveModSettings()
    end)
end

-- line 1131-1139
-- proto#140 params=0 locals=0 upvalues=2 vararg=false
local function r0_60()
    pcall(function()
        if _G.SaveModSettings then
            _G.SaveModSettings()
        end
    end)
    pcall(function()
        local r142_0, r142_1 = pcall(require, "common.time_ticker")
        if r142_0 and r142_1 and r142_1.AddTimerOnce then
            r142_1.AddTimerOnce(3.0, r0_60)
        end
    end)
end

if not _G.ModConfigLoaded then
    _G.LoadModSettings()
    r0_60()
    _G.ModConfigLoaded = true
end

-- line 1147-1149
-- proto#143 params=0 locals=0 upvalues=1 vararg=false
function _G.ReadLiveConfig()
    if _G.SaveModSettings then
        _G.SaveModSettings()
    end
end

-- line 1151-1253
-- proto#144 params=0 locals=27 upvalues=1 vararg=false
function _G.InitModMenuTab()
    if _G.ModMenuInitialized then
        return
    end
    _G.ModMenuInitialized = true

    -- line 1155-1157
    -- proto#145 params=2 locals=1 upvalues=1 vararg=false
    local function r144_0(p145_0, p145_1)
        return _G.LexusLang == "EN" and p145_1 or p145_0
    end

    _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
    local r144_1 = _G.LocUtil
    local r144_2
    if r144_1 then
        r144_2 = r144_1
    else
        local r144_3 = package.loaded["client.common.LocUtil"]
        if r144_3 then
            r144_2 = require("client.common.LocUtil")
        else
            r144_2 = r144_3
        end
    end
    local r144_4 = {
        [999000] = r144_0("ROCKY BHAI ESP"),
        [999006] = r144_0("ESP V2 (VIP) ", "ESP V2 (VIP) MADE BY @ROCKYBHAI711")
    }
    if r144_2 and not r144_2._IsModMenuHooked_V2 then
        for r144_5, r144_6 in ipairs({
            "GetLocalizeResStr",
            "GetText",
            "GetTextByID",
            "GetLocalText",
            "GetLocalizeStr"
        }) do
            if r144_2[r144_6] then
                local r144_7 = r144_2[r144_6]
                r144_2[r144_6] = function(p146_0)
                    if r144_4[p146_0] then
                        return r144_4[p146_0]
                    end
                    if type(p146_0) == "string" and not tonumber(p146_0) then
                        return p146_0
                    end
                    if r144_7 then
                        return r144_7(p146_0)
                    end
                    return ""
                end
            end
        end
        r144_2._IsModMenuHooked_V2 = true
    end
    local r144_8 = require("client.logic.NewSetting.SettingPageDefine")
    local r144_9 = require("client.logic.NewSetting.SettingCatalog")
    if not r144_8.ModMenu then
        local r144_10 = require("client.slua.umg.NewSetting.Item.AliasMap")
        local r144_11 = {
            {
                Key = "ModMenu_ESP9_Ex",
                UI = r144_10.TitleSwitcher,
                Text = r144_0("▶ ESP VIP (RedBox & Marker)", "▶ ESP VIP (RedBox & Marker)"),
                ExpandIndex = 0,
                GetFunc = function()
                    return _G.LexusConfig.EspLoai9
                end,
                SetFunc = function(p148_0, p148_1)
                    _G.LexusConfig.EspLoai9 = p148_1
                    return true
                end
            },
            {
                Key = "ModMenu_ESP9_Count",
                UI = r144_10.Switcher,
                Text = r144_0("   Show Player Count", "   Show Player Count"),
                ExpandHandle = "ModMenu_ESP9_Ex",
                GetFunc = function()
                    return _G.LexusConfig.Esp9_Count
                end,
                SetFunc = function(p150_0, p150_1)
                    _G.LexusConfig.Esp9_Count = p150_1
                    return true
                end
            },
            {
                Key = "ModMenu_ESP9_Name",
                UI = r144_10.Switcher,
                Text = r144_0("   Show Player Name", "   Show Player Name"),
                ExpandHandle = "ModMenu_ESP9_Ex",
                GetFunc = function()
                    return _G.LexusConfig.Esp9_Name
                end,
                SetFunc = function(p152_0, p152_1)
                    _G.LexusConfig.Esp9_Name = p152_1
                    return true
                end
            },
            {
                Key = "ModMenu_ESP9_Dist",
                UI = r144_10.Switcher,
                Text = r144_0("   Show Distance", "   Show Distance"),
                ExpandHandle = "ModMenu_ESP9_Ex",
                GetFunc = function()
                    return _G.LexusConfig.Esp9_Distance
                end,
                SetFunc = function(p154_0, p154_1)
                    _G.LexusConfig.Esp9_Distance = p154_1
                    return true
                end
            },
            {
                Key = "ModMenu_ESP9_HP",
                UI = r144_10.Switcher,
                Text = r144_0("   Show Health Bar", "   Show Health Bar"),
                ExpandHandle = "ModMenu_ESP9_Ex",
                GetFunc = function()
                    return _G.LexusConfig.Esp9_HP
                end,
                SetFunc = function(p156_0, p156_1)
                    _G.LexusConfig.Esp9_HP = p156_1
                    return true
                end
            },
            {
                Key = "ModMenu_ESP9_Team",
                UI = r144_10.Switcher,
                Text = r144_0("   Show Team Color Box", "   Show Team Color Box"),
                ExpandHandle = "ModMenu_ESP9_Ex",
                GetFunc = function()
                    return _G.LexusConfig.Esp9_Team
                end,
                SetFunc = function(p158_0, p158_1)
                    _G.LexusConfig.Esp9_Team = p158_1
                    return true
                end
            },
            {
                Key = "ModMenu_ESP9_Weapon",
                UI = r144_10.Switcher,
                Text = r144_0("   Show Weapon Icon", "   Show Weapon Icon"),
                ExpandHandle = "ModMenu_ESP9_Ex",
                GetFunc = function()
                    return _G.LexusConfig.Esp9_Weapon
                end,
                SetFunc = function(p160_0, p160_1)
                    _G.LexusConfig.Esp9_Weapon = p160_1
                    return true
                end
            },
            {
                Key = "ModMenu_ESP9_Line",
                UI = r144_10.Switcher,
                Text = r144_0("   Show Snapline", "   Show Snapline"),
                ExpandHandle = "ModMenu_ESP9_Ex",
                GetFunc = function()
                    return _G.LexusConfig.Esp9_Line
                end,
                SetFunc = function(p162_0, p162_1)
                    _G.LexusConfig.Esp9_Line = p162_1
                    return true
                end
            },
            {
                Key = "ModMenu_ESP9_Skeleton",
                UI = r144_10.Switcher,
                Text = r144_0("   Show Skeleton (not recommended on low-end devices because it may cause lag)", "   Show Skeleton ( It's not recommended for weak computers as it will cause significant lag )"),
                ExpandHandle = "ModMenu_ESP9_Ex",
                GetFunc = function()
                    return _G.LexusConfig.Esp9_Skeleton
                end,
                SetFunc = function(p164_0, p164_1)
                    _G.LexusConfig.Esp9_Skeleton = p164_1
                    return true
                end
            }
        }
        r144_8.ModMenu = {
            Key = "ModMenu",
            Text = 999000,
            UIKey = "Setting_Page_Privacy",
            Category = { { Key = "Cat_ESPV2", Text = 999006, Stack = r144_11 } }
        }
        table.insert(r144_9, 1, r144_8.ModMenu)
    end
    local r144_12 = _G.UIManager
    if r144_12 and not r144_12._IsModMenuHooked then
        local r144_13 = r144_12.ShowUI

        -- line 1226-1250
        -- proto#165 params=1 locals=7 upvalues=3 vararg=true
        function r144_12.ShowUI(p165_0, ...)
            local r165_0 = { ... }
            local r165_1 = select("#", ...)
            if p165_0 and p165_0.keyName and string.find(string.lower(p165_0.keyName), "setting_main") and not string.find(string.lower(p165_0.keyName), "custom") then
                local r165_2 = r165_0[1]
                if type(r165_2) == "table" and r165_2[1] and type(r165_2[1]) == "table" and r165_2[1].Key then
                    local r165_3 = false
                    for r165_4, r165_5 in ipairs(r165_2) do
                        if type(r165_5) == "table" and r165_5.Key == "ModMenu" then
                            r165_3 = true
                            break
                        end
                    end
                    if not r165_3 then
                        table.insert(r165_2, 1, r144_8.ModMenu)
                    end
                end
            end
            local r165_6 = table.unpack
            return r144_13(p165_0, (r165_6 or unpack)(r165_0, 1, r165_1))
        end

        r144_12._IsModMenuHooked = true
    end
end

-- line 1255-1305
-- proto#166 params=0 locals=0 upvalues=2 vararg=false
local function r0_61()
    if _G.LexusMenuAlreadyShown then
        return
    end
    if _G.LexusState.MenuStep ~= 0 then
        return
    end
    pcall(function()
        local r167_0 = require("client.slua.logic.common.logic_common_msg_box")
        if not (r167_0 and r167_0.Show) then
            return
        end

        -- line 1263-1274
        -- proto#168 params=0 locals=6 upvalues=2 vararg=false
        local function r167_1()
            local r168_0 = _G.LexusLang
            r167_0.Show(1, _G.LexusLang == "EN" and "SCAM ALERT" or "MOD SCAM ALERT", _G.LexusLang == "EN" and "Join my Telegram to avoid scammers selling free mods.  TELE @ROCKYBHAI711" or [[Join my Telegram to avoid scammers selling free mods.  TELE @ROCKYBHAI711
Beware of fake sellers and impersonators. I have only one Telegram account and one Zalo account.]], function()
                local r169_0 = require("client.slua.logic.url.logic_webview_sdk")
                if r169_0 and r169_0.OpenURL then
                    r169_0:OpenURL("https://t.me/Rockybhai7111")
                end
            end, function()

            end, _G.LexusLang == "EN" and "JOIN" or "THAM GIA", "CLOSE")
            _G.LexusState.MenuStep = 99
            _G.LexusMenuAlreadyShown = true
        end

        -- line 1276-1295
        -- proto#171 params=0 locals=5 upvalues=4 vararg=false
        local function r167_2()
            local r171_0 = _G.LexusLang
            local r171_1 = _G.LexusLang
            r167_0.Show(1, _G.LexusLang == "EN" and "WELCOME TO VIP MOD" or "WELCOME", _G.LexusLang == "EN" and [[Hi, Dung here. The VIP MENU is now inside Game Settings!
IMPORTANT: Enable fewer features to avoid lag. Play safe!]] or [[Hi, this is Dung. You no longer need external combos or configs because the VIP MENU is now in Game Settings!
IMPORTANT: Enable only a few features to avoid lag, and use the mod carefully.]], function()
                _G.InitModMenuTab()
                if _G.LexusLang == "EN" then
                    r0_17([[VIP MOD MENU ADDED!
Open Settings (Gear icon) -> VIP MOD MENU to toggle features.]])
                else
                    r0_17([['VIP MOD MENU' HAS BEEN ADDED TO GAME SETTINGS!
Open Settings (Gear icon) -> VIP MOD MENU to toggle features.]])
                end
                r167_1()
            end, function()

            end, "OPEN GAME MENU", "CLOSE")
        end

        -- line 1297-1300
        -- proto#174 params=0 locals=0 upvalues=2 vararg=false
        local function r167_3()
            _G.LexusLang = "EN"
            r167_2()
        end

        _G.LexusState.MenuStep = 1
        r167_3()
    end)
end

-- line 1307-1360
-- proto#175 params=0 locals=0 upvalues=2 vararg=false
local function r0_62()
    if _G.LexusState.NativeESPReady then
        return
    end
    pcall(function()
        local r176_0 = require("GameLua.Mod.BaseMod.Common.GamePlayTools").GetCurrentConfig("ScreenMarkConfig")

        -- line 1312-1350
        -- proto#177 params=1 locals=8 upvalues=1 vararg=false
        local function r176_1(p177_0)
            if not p177_0 then
                return
            end
            if p177_0[1006] then
                p177_0[1006].bBindBlocked = true
                p177_0[1006].bBindOutScreen = true
                p177_0[1006].MaxWidgetNum = 99
                p177_0[1006].MaxShowDistance = 6000000
                p177_0[1006].bScaleByDistance = false
                p177_0[1006].BindSocketName = "root"
                p177_0[1006].bUseLuaWorldSocketName = true
                local r177_0 = p177_0[1006]
                r177_0.WorldPositionOffset = FVector(0, 0, -30)
            end
            p177_0[8888] = {
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99,
                MaxShowDistance = 6000000,
                bBindOutScreen = true,
                bBindBlocked = true,
                bIsBindingActor = true,
                BindSocketName = "head",
                bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0, 0, 30),
                bNeedPreLoad = true,
                Priority = 2
            }
            p177_0[9999] = {
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99,
                MaxShowDistance = 6000000,
                bBindOutScreen = true,
                bBindBlocked = true,
                bIsBindingActor = true,
                BindSocketName = "head",
                bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0, 0, 50),
                bNeedPreLoad = true,
                Priority = 2
            }
        end

        r176_1(r176_0)
        for r176_2, r176_3 in pairs(package.loaded) do
            if type(r176_2) == "string" and string.find(r176_2, "ScreenMarkConfig") and type(r176_3) == "table" then
                r176_1(r176_3)
            end
        end
    end)
    _G.LexusState.NativeESPReady = true
    r0_17("Native ESP System Initialized")
end

-- line 1362-1395
-- proto#178 params=2 locals=6 upvalues=2 vararg=false
local function r0_63(p178_0, p178_1)
    local r178_0 = os.clock()
    if p178_1 and p178_1.CachedMeshes and p178_1.CachedMeshTime and r178_0 - p178_1.CachedMeshTime < 3.0 then
        local r178_1 = {}
        for r178_2, r178_3 in ipairs(p178_1.CachedMeshes) do
            if r0_19(r178_3) then
                table.insert(r178_1, r178_3)
            end
        end
        p178_1.CachedMeshes = r178_1
        return r178_1
    end
    local r178_4 = {}
    if r0_19(p178_0.Mesh) then
        table.insert(r178_4, p178_0.Mesh)
    end
    pcall(function()
        local r179_0 = import("SkeletalMeshComponent")
        if r179_0 and type(p178_0.GetComponentsByClass) == "function" then
            local r179_1 = p178_0:GetComponentsByClass(r179_0)
            if r179_1 then
                local r179_2 = type(r179_1.Num) == "function" and r179_1:Num() or #r179_1
                for r179_3 = 1, r179_2 do
                    local r179_4
                    if type(r179_1.Get) == "function" then
                        local r179_5 = r179_1:Get(r179_3 - 1)
                        if r179_5 then
                            r179_4 = r179_5
                        else
                            r179_4 = r179_1[r179_3]
                        end
                    else
                        r179_4 = r179_1[r179_3]
                    end
                    if r0_19(r179_4) and r179_4 ~= p178_0.Mesh then
                        table.insert(r178_4, r179_4)
                    end
                end
            end
        end
    end)
    if p178_1 then
        p178_1.CachedMeshes = r178_4
        p178_1.CachedMeshTime = r178_0
    end
    return r178_4
end

-- line 1397-1416
-- proto#180 params=2 locals=0 upvalues=3 vararg=false
local function r0_64(p180_0, p180_1)
    pcall(function()
        if p180_1.WallhackApplied then
            for r181_0, r181_1 in ipairs(r0_63(p180_0, p180_1)) do
                if r0_19(r181_1) then
                    pcall(function()
                        if type(r181_1.SetRenderCustomDepth) == "function" then
                            r181_1:SetRenderCustomDepth(false)
                        end
                    end)
                    for r181_2 = 0, 10 do
                        local r181_3 = r181_1:GetMaterial(r181_2)
                        if r0_19(r181_3) then
                            local r181_4 = r181_3:GetBaseMaterial()
                            if r0_19(r181_4) then
                                r181_4.bDisableDepthTest = false
                            end
                        end
                    end
                end
            end
            p180_1.WallhackApplied = false
        end
    end)
end

-- line 1418-1443
-- proto#183 params=2 locals=0 upvalues=3 vararg=false
local function r0_65(p183_0, p183_1)
    pcall(function()
        for r184_0, r184_1 in ipairs(r0_63(p183_0, p183_1)) do
            if r0_19(r184_1) then
                pcall(function()
                    if type(r184_1.SetRenderCustomDepth) == "function" then
                        r184_1:SetRenderCustomDepth(true)
                    end
                    if type(r184_1.SetCustomDepthStencilValue) == "function" then
                        r184_1:SetCustomDepthStencilValue(252)
                    end
                end)
                for r184_2 = 0, 10 do
                    local r184_3 = r184_1:GetMaterial(r184_2)
                    if not r0_19(r184_3) then
                        break
                    end
                    local r184_4 = r184_3:GetBaseMaterial()
                    if r0_19(r184_4) then
                        r184_4.bDisableDepthTest = true
                        r184_4.BlendMode = 2
                    end
                end
            end
        end
    end)
end

-- line 1445-1482
-- proto#186 params=2 locals=0 upvalues=3 vararg=false
local function r0_66(p186_0, p186_1)
    pcall(function()
        if p186_1.ColorApplied then
            for r187_0, r187_1 in ipairs(r0_63(p186_0, p186_1)) do
                if r0_19(r187_1) then
                    pcall(function()
                        r187_1.PrimitiveShadingStrategy = 0
                        r187_1.ShadingRate = 1
                    end)
                    local r187_2 = "Mesh_"
                    local r187_3 = tostring(r187_0)
                    local r187_4 = r187_2 .. r187_3
                    if p186_1.MIDs and p186_1.MIDs[r187_4] then
                        for r187_5, r187_6 in pairs(p186_1.MIDs[r187_4]) do
                            if r0_19(r187_6) then
                                local r187_7 = { R = 1, G = 1, B = 1, A = 1 }
                                r187_6:SetVectorParameterValue("颜色", r187_7)
                                r187_6:SetVectorParameterValue("Extra Light Color", r187_7)
                                r187_6:SetVectorParameterValue("Para_Color", r187_7)
                                r187_6:SetVectorParameterValue("Para_ColorTint", r187_7)
                                r187_6:SetVectorParameterValue("Para_Color_1", r187_7)
                                r187_6:SetVectorParameterValue("Tint", r187_7)
                                r187_6:SetVectorParameterValue("Color", r187_7)
                                r187_6:SetVectorParameterValue("BaseColor", r187_7)
                                r187_6:SetVectorParameterValue("BodyColor", r187_7)
                                r187_6:SetVectorParameterValue("MainColor", r187_7)
                                r187_6:SetVectorParameterValue("DiffuseColor", r187_7)
                                r187_6:SetVectorParameterValue("EmissiveColor", r187_7)
                            end
                        end
                    end
                end
            end
            p186_1.ColorApplied = false
            p186_1.LastColorHash = ""
            p186_1.LastHiddenState = nil
        end
    end)
end

-- line 1484-1570
-- proto#189 params=3 locals=0 upvalues=3 vararg=false
local function r0_67(p189_0, p189_1, p189_2)
    pcall(function()
        local r190_0 = r0_63(p189_0, p189_2)
        if #r190_0 == 0 then
            return
        end
        local r190_1 = os.clock()
        if p189_2.LastVisCheckTime == nil or r190_1 - p189_2.LastVisCheckTime > 0.3 then
            p189_2.LastVisCheckTime = r190_1
            local r190_2 = true
            pcall(function()
                if r0_19(p189_1) and type(p189_1.LineOfSightTo) == "function" then
                    r190_2 = not p189_1:LineOfSightTo(p189_0)
                end
            end)
            p189_2.CachedHiddenState = r190_2
        end
        local r190_3 = p189_2.CachedHiddenState
        if r190_3 == nil then
            r190_3 = true
        end
        local r190_4 = _G.LexusState.CustomTextData
        if not r190_4 then
            r190_4 = {}
        end
        local r190_5 = {
            R = r190_4.HiddenR or 150,
            G = r190_4.HiddenG or 0,
            B = r190_4.HiddenB or 0,
            A = r190_4.HiddenA or 25
        }
        local r190_6 = {
            R = r190_4.VisibleR or 0,
            G = r190_4.VisibleG or 150,
            B = r190_4.VisibleB or 0,
            A = r190_4.VisibleA or 25
        }
        local r190_7 = r190_3 and r190_5 or r190_6
        local r190_8 = string.format("%d_%d_%d_%d", r190_7.R, r190_7.G, r190_7.B, r190_7.A)
        local r190_9 = #r190_0
        local r190_10 = p189_2.LastMeshCount ~= r190_9
        if not r190_10 and p189_2.LastHiddenState == r190_3 and p189_2.LastColorHash == r190_8 then
            return
        end
        if r190_10 and p189_2.MIDs then
            p189_2.MIDs = {}
        end
        p189_2.LastHiddenState = r190_3
        p189_2.LastMeshCount = r190_9
        p189_2.LastColorHash = r190_8
        p189_2.ColorApplied = true
        for r190_11, r190_12 in ipairs(r190_0) do
            if r0_19(r190_12) then
                pcall(function()
                    r190_12.LDMaxDrawDistance = -99999
                    r190_12.MaxDrawDistanceOffset = -99999
                    r190_12.CachedMaxDrawDistance = -99999
                    r190_12.UseScopeDistanceCulling = true
                    r190_12.PrimitiveShadingStrategy = 1
                    r190_12.ShadingRate = 6
                end)
                for r190_13 = 0, 10 do
                    local r190_14 = r190_12:GetMaterial(r190_13)
                    if not r0_19(r190_14) then
                        break
                    end
                    local r190_15 = r190_14:GetBaseMaterial()
                    if r0_19(r190_15) then
                        local r190_16 = tostring(r190_15)
                        local r190_17 = string.find(r190_16, "Master_Mask", 1, true)
                        if r190_17 then
                            if not p189_2.MIDs then
                                p189_2.MIDs = {}
                            end
                            local r190_18 = "Mesh_"
                            local r190_19 = tostring(r190_11)
                            local r190_20 = r190_18 .. r190_19
                            if not p189_2.MIDs[r190_20] then
                                p189_2.MIDs[r190_20] = {}
                            end
                            local r190_21 = p189_2.MIDs[r190_20]
                            local r190_22 = r190_21[r190_13]
                            if not r0_19(r190_22) then
                                local r190_23
                                r190_22 = r190_23
                            end
                            if r0_19(r190_22) then
                                r190_22:SetVectorParameterValue("颜色", r190_7)
                                r190_22:SetVectorParameterValue("Extra Light Color", r190_7)
                                r190_22:SetVectorParameterValue("Para_Color", r190_7)
                                r190_22:SetVectorParameterValue("Para_ColorTint", r190_7)
                                r190_22:SetVectorParameterValue("Para_Color_1", r190_7)
                                r190_22:SetVectorParameterValue("Tint", r190_7)
                                r190_22:SetVectorParameterValue("Color", r190_7)
                                r190_22:SetVectorParameterValue("BaseColor", r190_7)
                                r190_22:SetVectorParameterValue("BodyColor", r190_7)
                                r190_22:SetVectorParameterValue("MainColor", r190_7)
                                r190_22:SetVectorParameterValue("DiffuseColor", r190_7)
                                r190_22:SetVectorParameterValue("EmissiveColor", r190_7)
                                local r190_24 = { R = 3, G = 3, B = 0, A = 0 }
                                r190_22:SetVectorParameterValue("ParaScaleOffset", r190_24)
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- line 1572-1685
-- proto#193 params=2 locals=0 upvalues=3 vararg=false
local function r0_68(p193_0, p193_1)
    pcall(function()
        local r194_0 = r0_63(p193_0, p193_1)
        if #r194_0 == 0 then
            return
        end
        local r194_1 = _G.LexusState.CustomTextData
        if not r194_1 then
            r194_1 = {}
        end
        local r194_2 = r194_1.ColorV3Hidden
        if not r194_2 then
            r194_2 = 1
        end
        local r194_3 = r194_1.ColorV3Visible
        if not r194_3 then
            r194_3 = 2
        end
        local r194_4 = r194_1.ColorV3Thickness
        if not r194_4 then
            r194_4 = 4
        end
        local r194_5 = string.format("%d_%d_%d", r194_2, r194_3, r194_4)
        local r194_6 = p193_1.LastColorV3Hash ~= r194_5
        p193_1.LastColorV3Hash = r194_5

        -- line 1586-1594
        -- proto#195 params=1 locals=0 upvalues=0 vararg=false
        local function r194_7(p195_0)
            if p195_0 == 1 then
                return 255, 0, 0
            end
            if p195_0 == 2 then
                return 0, 255, 0
            end
            if p195_0 == 3 then
                return 0, 0, 255
            end
            if p195_0 == 4 then
                return 255, 255, 0
            end
            if p195_0 == 5 then
                return 255, 0, 255
            end
            if p195_0 == 6 then
                return 255, 255, 255
            end
            return 255, 0, 0
        end

        local r194_8, r194_9, r194_10 = r194_7(r194_2)
        local r194_11, r194_12, r194_13 = r194_7(r194_3)
        local r194_14 = {
            R = r194_8,
            G = r194_9,
            B = r194_10,
            A = 255,
            r = r194_8,
            g = r194_9,
            b = r194_10,
            a = 255
        }
        local r194_15 = 80.0
        local r194_16 = import("LinearColor")
        if not r194_16 then
            local r194_17
            r194_16 = r194_17.FLinearColor
        end
        local r194_18 = r194_16 and (r194_16(r194_11 / 255 * r194_15, r194_12 / 255 * r194_15, r194_13 / 255 * r194_15, 1.0) or {
            R = r194_11 * r194_15,
            G = r194_12 * r194_15,
            B = r194_13 * r194_15,
            A = 255
        }) or { R = r194_11 * r194_15, G = r194_12 * r194_15, B = r194_13 * r194_15, A = 255 }
        local r194_19 = { R = 3.0, G = 3.0, B = 0.0, A = 0.0, r = 3.0, g = 3.0, b = 0.0, a = 0.0 }
        local r194_20 = p193_1.MIDs_V3
        p193_1.MIDs_V3 = r194_20 or {}
        for r194_21, r194_22 in ipairs(r194_0) do
            if r0_19(r194_22) then
                local r194_23 = "MeshV3_"
                local r194_24 = tostring(r194_21)
                local r194_25 = r194_23 .. r194_24
                p193_1.MIDs_V3[r194_25] = p193_1.MIDs_V3[r194_25] or {}
                pcall(function()
                    if r194_22.PrimitiveShadingStrategy ~= 1 then
                        r194_22.UseScopeDistanceCulling = false
                        r194_22.PrimitiveShadingStrategy = 1
                        r194_22.ShadingRate = 6
                    end
                end)
                for r194_26 = 0, 10 do
                    local r194_27 = r194_22:GetMaterial(r194_26)
                    if not r0_19(r194_27) then
                        break
                    end
                    local r194_28 = r194_27:GetBaseMaterial()
                    if r0_19(r194_28) then
                        if r194_28.bDisableDepthTest ~= true then
                            r194_28.bDisableDepthTest = true
                        end
                        if r194_28.BlendMode ~= 2 then
                            r194_28.BlendMode = 2
                        end
                    end
                    local r194_29 = p193_1.MIDs_V3[r194_25][r194_26]
                    local r194_30 = r0_19(r194_29)
                    local r194_31, r194_32, r194_33
                    if r194_30 then
                        if r194_6 then
                            r194_31 = true
                        else
                            r194_31 = r194_6
                        end
                    else
                        local r194_34 = r194_22:CreateAndSetMaterialInstanceDynamic(r194_26)
                        r194_32 = r0_19(r194_34)
                        if r194_32 then
                            p193_1.MIDs_V3[r194_25][r194_26] = r194_34
                            r194_33 = r194_34
                            r194_31 = true
                        else
                            r194_31 = r194_32
                        end
                    end
                    local r194_35
                    if r194_30 then
                        r194_35 = r194_29
                    elseif r194_32 then
                        r194_35 = r194_33
                    else
                        r194_35 = r194_29
                    end
                    if r0_19(r194_35) and r194_31 then
                        pcall(function()
                            r194_35:SetVectorParameterValue("颜色", r194_14)
                            r194_35:SetVectorParameterValue("Extra Light Color", r194_14)
                            r194_35:SetVectorParameterValue("Para_Color", r194_14)
                            r194_35:SetVectorParameterValue("Para_ColorTint", r194_14)
                            r194_35:SetVectorParameterValue("Para_Color_1", r194_14)
                            r194_35:SetVectorParameterValue("Tint", r194_14)
                            r194_35:SetVectorParameterValue("Color", r194_14)
                            r194_35:SetVectorParameterValue("BaseColor", r194_14)
                            r194_35:SetVectorParameterValue("BodyColor", r194_14)
                            r194_35:SetVectorParameterValue("MainColor", r194_14)
                            r194_35:SetVectorParameterValue("DiffuseColor", r194_14)
                            r194_35:SetVectorParameterValue("EmissiveColor", r194_14)
                            r194_35:SetVectorParameterValue("CustomColor", r194_14)
                            r194_35:SetVectorParameterValue("OverlayColor", r194_14)
                            r194_35:SetVectorParameterValue("GlowColor", r194_14)
                            r194_35:SetVectorParameterValue("EdgeColor", r194_14)
                            r194_35:SetVectorParameterValue("LightColor", r194_14)
                            r194_35:SetVectorParameterValue("OutlineColor", r194_14)
                            r194_35:SetVectorParameterValue("ParaScaleOffset", r194_19)
                            r194_35:SetScalarParameterValue("Opacity", 0.7)
                            r194_35:SetScalarParameterValue("Alpha", 0.7)
                            r194_35:SetScalarParameterValue("GlowIntensity", 1.0)
                            r194_35:SetScalarParameterValue("Intensity", 1.0)
                        end)
                    end
                end
                pcall(function()
                    if r194_22.SetDrawIdeaOutline then
                        r194_22:SetDrawIdeaOutline(true)
                        if r194_22.OverrideIdeaOutlineColor then
                            r194_22:OverrideIdeaOutlineColor(true, r194_18)
                        end
                        if r194_22.OverrideIdeaOutlineThickness then
                            r194_22:OverrideIdeaOutlineThickness(true, r194_4)
                        end
                    end
                end)
            end
        end
        p193_1.ColorV3Applied = true
    end)
end

-- line 1687-1738
-- proto#199 params=2 locals=0 upvalues=3 vararg=false
local function r0_69(p199_0, p199_1)
    pcall(function()
        if p199_1.ColorV3Applied then
            for r200_0, r200_1 in ipairs(r0_63(p199_0, p199_1)) do
                if r0_19(r200_1) then
                    pcall(function()
                        r200_1.PrimitiveShadingStrategy = 0
                        r200_1.ShadingRate = 1
                    end)
                    for r200_2 = 0, 10 do
                        local r200_3, r200_4 = pcall(function()
                            return r200_1:GetMaterial(r200_2)
                        end)
                        if r200_3 and r0_19(r200_4) then
                            local r200_5, r200_6 = pcall(function()
                                return r200_4:GetBaseMaterial()
                            end)
                            if r200_5 and r0_19(r200_6) then
                                r200_6.bDisableDepthTest = false
                                r200_6.BlendMode = 1
                            end
                        end
                    end
                    local r200_7 = "MeshV3_"
                    local r200_8 = tostring(r200_0)
                    local r200_9 = r200_7 .. r200_8
                    if p199_1.MIDs_V3 and p199_1.MIDs_V3[r200_9] then
                        for r200_10, r200_11 in pairs(p199_1.MIDs_V3[r200_9]) do
                            if r0_19(r200_11) then
                                pcall(function()
                                    local r204_0 = {
                                        R = 1,
                                        G = 1,
                                        B = 1,
                                        A = 1,
                                        r = 1,
                                        g = 1,
                                        b = 1,
                                        a = 1
                                    }
                                    r200_11:SetVectorParameterValue("颜色", r204_0)
                                    r200_11:SetVectorParameterValue("Extra Light Color", r204_0)
                                    r200_11:SetVectorParameterValue("Para_Color", r204_0)
                                    r200_11:SetVectorParameterValue("Tint", r204_0)
                                    r200_11:SetVectorParameterValue("BaseColor", r204_0)
                                    r200_11:SetVectorParameterValue("Color", r204_0)
                                end)
                            end
                        end
                    end
                    pcall(function()
                        if r200_1.SetDrawIdeaOutline then
                            r200_1:SetDrawIdeaOutline(false)
                        end
                    end)
                end
            end
            p199_1.ColorV3Applied = false
            p199_1.LastMeshCountV3 = 0
            if p199_1.MIDs_V3 then
                p199_1.MIDs_V3 = nil
            end
        end
    end)
end

-- line 1740-1810
-- proto#206 params=2 locals=0 upvalues=3 vararg=false
local function r0_70(p206_0, p206_1)
    pcall(function()
        if not _G.ConsoleNewWallReady then
            local r207_0 = import("KismetSystemLibrary")
            local r207_1 = slua.getWorld()
            if r207_0 and r207_1 then
                r207_0.ExecuteConsoleCommand(r207_1, "r.EnableDrawDyeingColor 1")
                r207_0.ExecuteConsoleCommand(r207_1, "r.CustomDepth 3")
                r207_0.ExecuteConsoleCommand(r207_1, "r.IdeaOutline.Enable 1")
                r207_0.ExecuteConsoleCommand(r207_1, "r.Highlight.Enable 1")
                _G.ConsoleNewWallReady = true
            end
        end
        local r207_2 = r0_63(p206_0, p206_1)
        local r207_3 = nil
        pcall(function()
            r207_3 = p206_0:GetCurrentWeapon()
        end)
        if slua.isValid(r207_3) and slua.isValid(r207_3.Mesh) then
            table.insert(r207_2, r207_3.Mesh)
        end
        local r207_4 = p206_1.AK_IS_BOT
        if not r207_4 then
            r207_4 = false
        end
        local r207_5 = #r207_2
        local r207_6 = tostring(r207_5)
        local r207_7 = (r207_4 and "BOT" or "PLAYER") .. "_" .. r207_6
        if p206_1.LastColorNewHash == r207_7 and p206_1.ColorNewApplied then
            return
        end
        p206_1.LastColorNewHash = r207_7
        p206_1.ColorNewApplied = true
        local r207_8 = import("LinearColor")
        if not r207_8 then
            local r207_9
            r207_8 = r207_9.FLinearColor
        end
        local r207_10 = r207_8 and (r207_8(0, 100, 0, 1) or { R = 0, G = 100, B = 0, A = 1 }) or {
            R = 0,
            G = 100,
            B = 0,
            A = 1
        }
        local r207_11 = r207_8 and (r207_8(100, 0, 0, 1) or { R = 100, G = 0, B = 0, A = 1 }) or {
            R = 100,
            G = 0,
            B = 0,
            A = 1
        }
        local r207_12 = r207_8 and (r207_8(49, 48, 0, 100) or { R = 49, G = 48, B = 0, A = 100 }) or {
            R = 49,
            G = 48,
            B = 0,
            A = 100
        }
        local r207_13 = r207_8 and (r207_8(9, 1.5, 45, 100) or { R = 9, G = 1.5, B = 45, A = 100 }) or {
            R = 9,
            G = 1.5,
            B = 45,
            A = 100
        }
        local r207_14 = r207_4 and r207_12 or r207_10
        local r207_15 = r207_4 and r207_13 or r207_11
        for r207_16, r207_17 in ipairs(r207_2) do
            if r0_19(r207_17) then
                pcall(function()
                    if type(r207_17.SetDrawDyeing) == "function" then
                        r207_17:SetDrawDyeing(true)
                        r207_17:SetDrawDyeingMode(1)
                        r207_17:SetVisibleDyeingColor(r207_14)
                        r207_17:SetOccludedDyeingColor(r207_15)
                        r207_17:SetDyeingColorFadeDistance(99999.0)
                        r207_17:SetDyeingColorMinMaxDistance(0.0, 99999.0)
                        r207_17:SetDrawHighlight(true)
                        r207_17:OverrideHighlightColor(r207_14)
                        r207_17:SetHighlightCanBeOccluded(false)
                        r207_17:SetDrawIdeaOutline(true)
                        r207_17:SetIdeaOutlineNew(true)
                        r207_17:SetIdeaOutlineOcclusionHighlight(true)
                        r207_17:OverrideIdeaOutlineColor(r207_14)
                        r207_17:SetIdeaOutlineOcclusionColor(r207_15)
                        r207_17:OverrideIdeaOutlineThickness(20.0)
                        r207_17:SetIdeaOverrideOutlineAndOcclusion(true)
                        r207_17:SetRenderCustomDepth(true)
                        r207_17:SetCustomDepthStencilValue(255)
                    end
                end)
            end
        end
    end)
end

-- line 1812-1838
-- proto#210 params=2 locals=0 upvalues=3 vararg=false
local function r0_71(p210_0, p210_1)
    pcall(function()
        if p210_1.ColorNewApplied then
            local r211_0 = r0_63(p210_0, p210_1)
            local r211_1 = nil
            pcall(function()
                r211_1 = p210_0:GetCurrentWeapon()
            end)
            if slua.isValid(r211_1) and slua.isValid(r211_1.Mesh) then
                table.insert(r211_0, r211_1.Mesh)
            end
            for r211_2, r211_3 in ipairs(r211_0) do
                if r0_19(r211_3) then
                    pcall(function()
                        if type(r211_3.SetDrawDyeing) == "function" then
                            r211_3:SetDrawDyeing(false)
                            r211_3:SetDrawHighlight(false)
                            r211_3:SetDrawIdeaOutline(false)
                            r211_3:SetRenderCustomDepth(false)
                        end
                    end)
                end
            end
            p210_1.ColorNewApplied = false
            p210_1.LastColorNewHash = ""
        end
    end)
end

local r0_72 = {}
local r0_73 = {
    bActive = false,
    MainContainer = nil,
    WidgetSlot = nil,
    TextBlockPlayer = nil,
    TextBlockBot = nil,
    Width = 260,
    Height = 25,
    OffsetY = 10,
    PlayerCount = 0,
    BotCount = 0,
    FontSize = 14,
    TextScaleValue = 1.0,
    NumLayers = 50,
    Red = 0.7,
    Green = 0.3,
    Blue = 1.0,
    LayerAlpha = 0.06,
    _CachedTextPlayer = "",
    _CachedTextBot = "",
    _CachedPosVec = nil
}

-- line 1865-1991
-- proto#214 params=0 locals=1 upvalues=3 vararg=false
function r0_73.Create()
    local r214_0, r214_1, r214_2, r214_3
    if r0_73.MainContainer and slua.isValid(r0_73.MainContainer) then
        return true
    end
    local r214_4 = r0_72.ESPCanvas
    if r214_4 and slua.isValid(r214_4) then
        r214_0 = r214_4
    else
        if not r0_72.InitESPCanvas() then
            return false
        end
        r214_0 = r0_72.ESPCanvas
    end
    if not (r214_0 and slua.isValid(r214_0)) then
        return false
    end
    local r214_5 = nil
    pcall(function()
        r214_5 = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", r214_0)
    end)
    if not (r214_5 and slua.isValid(r214_5)) then
        return false
    end
    local r214_6 = import("LinearColor")
    if r214_6 then
        r214_1 = r214_6
    else
        r214_1 = FLinearColor
    end
    local r214_7 = import("Vector2D")
    if r214_7 then
        r214_2 = r214_7
    else
        r214_2 = FVector2D
    end
    local r214_8 = r214_1(r0_73.Red, r0_73.Green, r0_73.Blue, r0_73.LayerAlpha)
    local r214_9, r214_10 = r0_73.NumLayers, r0_73.Width
    local r214_11, r214_12 = nil --[[ [unluac error] HIR proto#214 still contains residual unresolved expr during AST lowering ]]
    if not nil --[[ [unluac error] HIR proto#214 still contains residual unresolved expr during AST lowering ]] then
        goto L27
    end
    ::L19::
    r214_13 = (r214_14 / r214_9) ^ 1.15 * r214_10
    r214_15 = (r214_10 - r214_13) / 2.0
    r214_16 = nil
    pcall(function()
        r214_16 = CGame:NewObjectFromPath("/Script/UMG.Border", r214_5)
    end)
    if r214_16 then
        if slua.isValid(r214_16) then
            pcall(function()
                r214_16:SetBrushColor(r214_8)
                r214_16:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            r214_17 = r214_5:AddChildToCanvas(r214_16)
            if r214_17 then
                r214_17:SetPosition(r214_2(r214_15, 0))
                r214_17:SetSize(r214_2(r214_13, r0_73.Height))
                -- [unluac error] HIR proto#214 still contains explicit close semantics that AST lowering cannot absorb yet
            else
                -- [unluac error] HIR proto#214 still contains explicit close semantics that AST lowering cannot absorb yet
            end
        else
            -- [unluac error] HIR proto#214 still contains explicit close semantics that AST lowering cannot absorb yet
        end
    else
        -- [unluac error] HIR proto#214 still contains explicit close semantics that AST lowering cannot absorb yet
    end
    r214_18, r214_19 = nil --[[ [unluac error] HIR proto#214 still contains residual unresolved expr during AST lowering ]]
    if nil --[[ [unluac error] HIR proto#214 still contains residual unresolved expr during AST lowering ]] then
        goto L19
    end
    ::L27::
    local r214_20 = import("SlateColor")
    if r214_20 then
        r214_3 = r214_20
        goto L29
    end
    r214_3 = import("/Script/SlateCore.SlateColor")
    ::L29::
    local r214_21 = nil
    pcall(function()
        r214_21 = CGame:NewObjectFromPath("/Script/UMG.TextBlock", r214_5)
    end)
    if r214_21 and slua.isValid(r214_21) then
        pcall(function()
            local r219_0 = string.format("Player: %d", r0_73.PlayerCount)
            r214_21:SetText(r219_0)
            r0_73._CachedTextPlayer = r219_0
            local r219_1 = r214_1(1.0, 0.0, 0.0, 1.0)
            if r214_3 then
                r214_21:SetColorAndOpacity(r214_3(r219_1))
            else
                r214_21:SetColorAndOpacity(r219_1)
            end
            if r214_21.Font then
                local r219_2 = r214_21.Font
                r219_2.Size = r0_73.FontSize
                r214_21.Font = r219_2
            end
            r214_21:SetRenderScale(r214_2(r0_73.TextScaleValue, r0_73.TextScaleValue))
            r214_21:SetRenderTransformPivot(r214_2(0.5, 0.5))
            r214_21:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local r214_22 = r214_5:AddChildToCanvas(r214_21)
        if r214_22 then
            pcall(function()
                r214_22:SetAutoSize(true)
                r214_22:SetAlignment(r214_2(0.5, 0.5))
                local r220_0 = r214_10 * 0.35
                r214_22:SetPosition(r214_2(r220_0, r0_73.Height * 0.5))
                r214_22:SetZOrder(1000)
            end)
        end
        r0_73.TextBlockPlayer = r214_21
        -- [unluac error] HIR proto#214 still contains explicit close semantics that AST lowering cannot absorb yet
    end
    local r214_23 = nil
    pcall(function()
        r214_23 = CGame:NewObjectFromPath("/Script/UMG.TextBlock", r214_5)
    end)
    if r214_23 and slua.isValid(r214_23) then
        pcall(function()
            local r222_0 = string.format("Bot: %d", r0_73.BotCount)
            r214_23:SetText(r222_0)
            r0_73._CachedTextBot = r222_0
            local r222_1 = r214_1(0.0, 1.0, 0.0, 1.0)
            if r214_3 then
                r214_23:SetColorAndOpacity(r214_3(r222_1))
            else
                r214_23:SetColorAndOpacity(r222_1)
            end
            if r214_23.Font then
                local r222_2 = r214_23.Font
                r222_2.Size = r0_73.FontSize
                r214_23.Font = r222_2
            end
            r214_23:SetRenderScale(r214_2(r0_73.TextScaleValue, r0_73.TextScaleValue))
            r214_23:SetRenderTransformPivot(r214_2(0.5, 0.5))
            r214_23:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local r214_24 = r214_5:AddChildToCanvas(r214_23)
        if r214_24 then
            pcall(function()
                r214_24:SetAutoSize(true)
                r214_24:SetAlignment(r214_2(0.5, 0.5))
                local r223_0 = r214_10 * 0.65
                r214_24:SetPosition(r214_2(r223_0, r0_73.Height * 0.5))
                r214_24:SetZOrder(1000)
            end)
        end
        r0_73.TextBlockBot = r214_23
        -- [unluac error] HIR proto#214 still contains explicit close semantics that AST lowering cannot absorb yet
    end
    local r214_25 = nil
    pcall(function()
        r214_25 = r214_0:AddChildToCanvas(r214_5)
    end)
    if not r214_25 then
        return false
    end
    r0_73.MainContainer = r214_5
    r0_73.WidgetSlot = r214_25
    pcall(function()
        r214_25:SetAutoSize(false)
        r214_25:SetZOrder(999)
        r214_25:SetAlignment(r214_2(0.5, 0.0))
        r214_25:SetSize(r214_2(r0_73.Width, r0_73.Height))
    end)
    r0_73.UpdatePosition()
    return true
end

-- line 1993-2016
-- proto#226 params=2 locals=2 upvalues=2 vararg=false
function r0_73.SetCounts(p226_0, p226_1)
    if r0_73.PlayerCount == p226_0 and r0_73.BotCount == p226_1 then
        return
    end
    local r226_0 = p226_0 or 0
    r0_73.PlayerCount = r226_0
    local r226_1 = p226_1 or 0
    r0_73.BotCount = r226_1
    if r0_73.TextBlockPlayer and slua.isValid(r0_73.TextBlockPlayer) then
        pcall(function()
            local r227_0 = string.format("Player: %d", r0_73.PlayerCount)
            if r0_73._CachedTextPlayer ~= r227_0 then
                r0_73.TextBlockPlayer:SetText(r227_0)
                r0_73._CachedTextPlayer = r227_0
            end
        end)
    end
    if r0_73.TextBlockBot and slua.isValid(r0_73.TextBlockBot) then
        pcall(function()
            local r228_0 = string.format("Bot: %d", r0_73.BotCount)
            if r0_73._CachedTextBot ~= r228_0 then
                r0_73.TextBlockBot:SetText(r228_0)
                r0_73._CachedTextBot = r228_0
            end
        end)
    end
end

-- line 2018-2035
-- proto#229 params=0 locals=6 upvalues=3 vararg=false
function r0_73.UpdatePosition()
    local r229_0 = r0_73.WidgetSlot
    if not (r229_0 and slua.isValid(r229_0)) then
        return
    end
    local r229_1 = r0_72.GetMyPlayerController()
    if not slua.isValid(r229_1) then
        return
    end
    local r229_2, r229_3 = r0_72.GetSnapLineStartPos(r229_1)
    local r229_4 = import("Vector2D") or FVector2D
    pcall(function()
        if r0_73._CachedPosVec then
            r0_73._CachedPosVec.X = r229_2
            r0_73._CachedPosVec.Y = r229_3
        else
            r0_73._CachedPosVec = r229_4(r229_2, r229_3)
        end
        r229_0:SetPosition(r0_73._CachedPosVec)
    end)
end

-- line 2037-2043
-- proto#231 params=0 locals=0 upvalues=2 vararg=false
function r0_73.Start()
    if r0_73.bActive and r0_73.MainContainer and slua.isValid(r0_73.MainContainer) then
        return
    end
    if r0_73.Create() then
        r0_73.bActive = true
        pcall(function()
            r0_73.MainContainer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
    end
end

-- line 2045-2058
-- proto#233 params=0 locals=0 upvalues=2 vararg=false
function r0_73.Stop()
    r0_73.bActive = false
    if r0_73.MainContainer and slua.isValid(r0_73.MainContainer) then
        pcall(function()
            r0_73.MainContainer:RemoveFromParent()
            r0_73.MainContainer:ConditionalBeginDestroy()
        end)
    end
    r0_73.MainContainer = nil
    r0_73.WidgetSlot = nil
    r0_73.TextBlockPlayer = nil
    r0_73.TextBlockBot = nil
    r0_73._CachedPosVec = nil
end

_G.RedBoxOverlay = r0_73
local r0_74 = nil
pcall(function()
    r0_74 = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
end)
local r0_75, r0_76, r0_77, r0_78 = nil, nil, nil, nil
pcall(function()
    local r236_0 = import("SlateBlueprintLibrary")
    r0_75 = r236_0 or import("/Script/UMG.SlateBlueprintLibrary")
end)
pcall(function()
    local r237_0 = import("WidgetLayoutLibrary")
    r0_76 = r237_0 or import("/Script/UMG.WidgetLayoutLibrary")
end)
pcall(function()
    r0_77 = import("KismetMathLibrary")
end)
pcall(function()
    r0_78 = import("KismetSystemLibrary")
end)
local r0_79 = _G.FVector2D
if not r0_79 then
    r0_79 = import("Vector2D")
end
local r0_80 = _G.FLinearColor
if not r0_80 then
    r0_80 = import("LinearColor")
end
local r0_81 = _G.FVector
if not r0_81 then
    r0_81 = import("Vector")
end
r0_72.MarkTypeID = 1007
r0_72.bUseScreenESP = true
r0_72.bUseScreenMark = false
r0_72.bUseQuickSign = false
r0_72.bUseNavigator = false
r0_72.bUseWidgetComponent = false
r0_72.QuickSignConfigKey = "C_MarkPos"
r0_72.WidgetCompUIPath = "/Game/BluePrints/ControlInput/NewbieItem/NewbieTips_ConsumeTips.NewbieTips_ConsumeTips"
r0_72.WidgetCompBoneName = "head"
local r0_82 = r0_81 and (r0_81(0, 0, 80) or { X = 0, Y = 0, Z = 80 }) or { X = 0, Y = 0, Z = 80 }
r0_72.WidgetCompOffset = r0_82
local r0_83 = r0_79 and (r0_79(210, 35) or { X = 210, Y = 35 }) or { X = 210, Y = 35 }
r0_72.WidgetCompDrawSize = r0_83
r0_72.ESPBoneName = "head"
r0_72.ESPWorldOffsetZ = 0
r0_72.ESPScreenOffsetY = 0
r0_72.ESPAnchorOffsetX = 35
r0_72.ESPAnchorOffsetY = 0
r0_72.ESPTextOffsetX = 0
r0_72.ESPTextOffsetY = 0
local r0_84 = r0_79 and (r0_79(0.5, 1.0) or { X = 0.5, Y = 1.0 }) or { X = 0.5, Y = 1.0 }
r0_72.ESPWidgetAlignment = r0_84
local r0_85 = r0_79 and (r0_79(70, 21) or { X = 70, Y = 21 }) or { X = 70, Y = 21 }
r0_72.ESPWidgetSize = r0_85
r0_72.ESPWidgetAutoSize = true
r0_72.ESPWidgetZOrder = 2
r0_72.bShowDistance = true
r0_72.DistanceUnit = "m"
r0_72.WeaponIconBrushW = 96
r0_72.WeaponIconBrushH = 48
r0_72.HPWidgetSwitcherTypeIndex = 0
r0_72.HPWidgetSwitcherType2Index = 0
r0_72.bForceSwitcherIndexEveryUpdate = true
r0_72.bUseSnapLines = true
r0_72.SnapLineThickness = 1.0
r0_72.SnapLineOriginY = 50
r0_72.SnapLineOriginOffsetX = 0
r0_72.SnapLineHeadOffsetX = 0
r0_72.SnapLineHeadOffsetY = -14
local r0_86 = r0_80 and (r0_80(0.6, 0.0, 0.0, 1.0) or { R = 150, G = 0, B = 0, A = 255 }) or {
    R = 150,
    G = 0,
    B = 0,
    A = 255
}
r0_72.SnapLineColor = r0_86
r0_72.SnapLineOpacity = 0.7
r0_72.bUseSkeleton = true
r0_72.SkeletonThickness = 0.8
r0_72.SkeletonColor = nil
r0_72.SkeletonOpacity = 0.8
r0_72.SkeletonMaxDistance = 100000
r0_72.bUseVisibilityColor = true
local r0_87 = r0_80 and (r0_80(0.0, 1.0, 0.0, 0.8) or { R = 0, G = 255, B = 0, A = 200 }) or {
    R = 0,
    G = 255,
    B = 0,
    A = 200
}
r0_72.SkeletonVisibleColor = r0_87
local r0_88 = r0_80 and (r0_80(0.9, 0.0, 0.0, 0.6) or { R = 230, G = 0, B = 0, A = 150 }) or {
    R = 230,
    G = 0,
    B = 0,
    A = 150
}
r0_72.SkeletonCoverColor = r0_88
r0_72.SkeletonWidgets = {}
r0_72._StaticBoneLocCache = {}
r0_72.SkeletonChains = {
    { "neck_01", "lowerarm_r", "hand_r" },
    { "neck_01", "lowerarm_l", "hand_l" },
    { "head", "neck_01", "pelvis" },
    { "pelvis", "calf_r", "foot_r" },
    { "pelvis", "calf_l", "foot_l" }
}
r0_72.BoneNameFallbacks = {
    head = { "head", "Head", "head_socket" },
    neck_01 = { "neck_01", "Neck_01", "neck", "Neck" },
    clavicle_r = { "clavicle_r", "Clavicle_R", "clavicle_R" },
    upperarm_r = { "upperarm_r", "UpperArm_R", "arm_r", "arm_r_01" },
    lowerarm_r = { "lowerarm_r", "LowerArm_R", "forearm_r" },
    hand_r = { "hand_r", "Hand_R", "hand_r_socket" },
    clavicle_l = { "clavicle_l", "Clavicle_L", "clavicle_L" },
    upperarm_l = { "upperarm_l", "UpperArm_L", "arm_l", "arm_l_01" },
    lowerarm_l = { "lowerarm_l", "LowerArm_L", "forearm_l" },
    hand_l = { "hand_l", "Hand_L", "hand_l_socket" },
    spine_03 = { "spine_03", "Spine_03", "spine_02", "spine" },
    spine_02 = { "spine_02", "Spine_02", "spine_01" },
    pelvis = { "pelvis", "pelvis", "hip" },
    thigh_r = { "thigh_r", "Thigh_R", "leg_r" },
    calf_r = { "calf_r", "Calf_R", "shin_r" },
    foot_r = { "foot_r", "Foot_R", "foot_r_socket" },
    thigh_l = { "thigh_l", "Thigh_L", "leg_l" },
    calf_l = { "calf_l", "Calf_L", "shin_l" },
    foot_l = { "foot_l", "Foot_L", "foot_l_socket" }
}
r0_72.MapAddedFlag = 4
r0_72.nUpdateInterval = 0.5
r0_72.bUseFrameTick = false
r0_72.nHeavyScanFrameInterval = 15
r0_72.nDistanceUpdateFrameInterval = 5
r0_72.bIncludeMe = false
r0_72.bIncludeAI = true
r0_72.bUseServerMarks = false
r0_72.bActive = false
r0_72.MarkMap = {}
r0_72.PlayerInfo = {}
r0_72.ESPCanvas = nil
r0_72.ESPWidgets = {}
r0_72.ESPWidgetPtrs = {}
r0_72.SnapLineWidgets = {}
r0_72._cachedViewportW = 1920
r0_72._cachedViewportH = 1080
r0_72._FrameCount = 0
r0_72._bTickRegistered = false
r0_72._CachedAllChars = nil
r0_72._CachedMyLoc = nil
r0_72._CachedMyKey = nil
r0_72.WidgetComps = {}
r0_72._bAllPathsFailed = false
r0_72._bLightUpdateScheduled = false
r0_72._LightUpdateInterval = 0.02
r0_72._bDistanceUpdateScheduled = false
r0_72._DistanceUpdateInterval = 0.1
r0_72._bScreenMarkConfigSetup = false

-- line 2196-2200
-- proto#240 params=1 locals=1 upvalues=1 vararg=false
local function r0_89(p240_0)
    if p240_0 == nil then
        return false
    end
    if slua and slua.isValid then
        return slua.isValid(p240_0)
    end
    return p240_0 ~= nil
end

-- line 2202-2225
-- proto#241 params=0 locals=1 upvalues=3 vararg=false
function r0_72.SetupScreenMarkConfig()
    if r0_72._bScreenMarkConfigSetup then
        return true
    end
    local r241_0 = false
    pcall(function()
        local r242_0 = require("GameLua.Mod.BaseMod.Common.GamePlayTools").GetCurrentConfig("ScreenMarkConfig")
        if r242_0 then
            r242_0[1007] = {
                UIPathName = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP_C",
                MaxWidgetNum = 100,
                MaxShowDistance = 6000000,
                bBindOutScreen = false,
                bBindBlocked = true,
                bNeedPreLoad = true,
                bIsBindingActor = true,
                BindSocketName = "HelmetSocket",
                WorldPositionOffset = r0_81 and (r0_81(0, 0, 80) or { X = 0, Y = 0, Z = 80 }) or {
                    X = 0,
                    Y = 0,
                    Z = 80
                }
            }
            r0_72._bScreenMarkConfigSetup = true
            r241_0 = true
        end
    end)
    return r241_0
end

-- line 2227-2232
-- proto#243 params=0 locals=0 upvalues=2 vararg=false
function r0_72.GetGameplayData()
    if r0_72._CachedGameplayData then
        return r0_72._CachedGameplayData
    end
    local r243_0, r243_1 = pcall(function()
        return require("GameLua.GameCore.Data.GameplayData")
    end)
    if r243_0 and r243_1 then
        r0_72._CachedGameplayData = r243_1
        return r243_1
    end
    return nil
end

-- line 2234-2242
-- proto#245 params=0 locals=3 upvalues=3 vararg=false
function r0_72.GetMyPlayerController()
    local r245_0 = r0_72._CachedPC
    if r245_0 and r0_89(r245_0) then
        return r245_0
    end
    local r245_1 = r0_72.GetGameplayData()
    if r245_1 then
        pcall(function()
            local r246_0 = r245_1.GetPlayerController
            r245_0 = r246_0 and r245_1.GetPlayerController()
        end)
        if r245_0 and r0_89(r245_0) then
            r0_72._CachedPC = r245_0
            return r245_0
        end
        return nil
    end
    return nil
end

-- line 2244-2250
-- proto#247 params=0 locals=0 upvalues=3 vararg=false
function r0_72.GetCGameState()
    if CGameState and r0_89(CGameState) then
        return CGameState
    end
    if r0_72._CachedCGameState and r0_89(r0_72._CachedCGameState) then
        return r0_72._CachedCGameState
    end
    local r247_0, r247_1 = pcall(function()
        return require("GameLua.GameCore.Data.CGameState")
    end)
    if r247_0 and r247_1 then
        r0_72._CachedCGameState = r247_1
        return r247_1
    end
    return nil
end

-- line 2252-2273
-- proto#249 params=0 locals=3 upvalues=2 vararg=false
function r0_72.GetAllCharacters()
    local r249_0 = {}
    pcall(function()
        local r250_0 = Game:GetAllPlayerPawns()
        if r250_0 then
            for r250_1, r250_2 in pairs(r250_0) do
                if r250_2 and slua.isValid(r250_2) then
                    local r250_3 = nil
                    if r250_2.GetPlayerKey then
                        r250_3 = r250_2:GetPlayerKey()
                    end
                    local r250_4
                    if r250_3 then
                        r250_4 = r250_3
                    else
                        local r250_5 = r250_2.PlayerKey
                        if r250_5 then
                            r250_4 = r250_2.PlayerKey
                        else
                            r250_4 = r250_5
                        end
                    end
                    local r250_6
                    if r250_4 then
                        r250_6 = r250_4
                    else
                        local r250_7 = r250_2.PlayerState
                        if r250_7 then
                            local r250_8 = r250_2.PlayerState.PlayerKey
                            if r250_8 then
                                r250_6 = r250_2.PlayerState.PlayerKey
                            else
                                r250_6 = r250_8
                            end
                        else
                            r250_6 = r250_7
                        end
                    end
                    if r250_6 then
                        r249_0[r250_6] = r250_2
                    end
                end
            end
        end
    end)
    if not next(r249_0) then
        local r249_1 = r0_72.GetCGameState()
        if r249_1 and r249_1.GetAllCharacters then
            pcall(function()
                r249_0 = r249_1:GetAllCharacters()
            end)
        end
    end
    return r249_0
end

-- line 2275-2284
-- proto#252 params=0 locals=3 upvalues=3 vararg=false
function r0_72.GetMyPlayerKey()
    local r252_0 = r0_72.GetMyPlayerController()
    if r0_89(r252_0) then
        local r252_1 = nil
        pcall(function()
            if r252_0.GetPlayerKey then
                r252_1 = r252_0:GetPlayerKey()
            elseif r252_0.PlayerState and r252_0.PlayerState.PlayerKey then
                r252_1 = r252_0.PlayerState.PlayerKey
            end
        end)
        return r252_1
    end
    return nil
end

-- line 2286-2302
-- proto#254 params=3 locals=2 upvalues=2 vararg=false
function r0_72.IsMe(p254_0, p254_1, p254_2)
    local r254_0 = false
    pcall(function()
        local r255_0 = r0_72.GetGameplayData()
        if r255_0 and r255_0.GetLocalCharacter and r255_0.GetLocalCharacter() and p254_0 == r255_0.GetLocalCharacter() then
            r254_0 = true
            return
        end
        local r255_1 = r0_72.GetMyPlayerController()
        if not (r255_1 and r255_1.GetPawn and r255_1:GetPawn() and p254_0 == r255_1:GetPawn()) then
            return
        end
        r254_0 = true
    end)
    local r254_1
    if r254_0 then
        r254_1 = r254_0
    elseif p254_2 == nil then
        r254_1 = r254_0
    elseif p254_1 == nil then
        r254_1 = r254_0
    else
        local r254_2 = tostring(p254_1)
        local r254_3 = tostring(p254_2)
        if r254_2 == r254_3 then
            r254_0 = true
            r254_1 = r254_0
        else
            r254_0 = false
            r254_1 = r254_0
        end
    end
    return r254_1
end

-- line 2304-2310
-- proto#256 params=1 locals=1 upvalues=2 vararg=false
function r0_72.GetCharacterLocation(p256_0)
    if r0_89(p256_0) then
        local r256_0 = nil
        pcall(function()
            if p256_0.K2_GetActorLocation then
                r256_0 = p256_0:K2_GetActorLocation()
            end
        end)
        if not r256_0 then
            pcall(function()
                if Game and Game.GetActorLocation then
                    r256_0 = Game:GetActorLocation(p256_0)
                end
            end)
        end
        return r256_0
    end
    return nil
end

-- line 2312-2324
-- proto#259 params=2 locals=1 upvalues=2 vararg=false
function r0_72.CalcDistance(p259_0, p259_1)
    if p259_0 and p259_1 then
        local r259_0 = nil
        pcall(function()
            if r0_81 and r0_81.Dist2D then
                r259_0 = r0_81.Dist2D(p259_0, p259_1)
            end
        end)
        if not r259_0 then
            pcall(function()
                local r261_0 = p259_0.X or 0
                local r261_1 = p259_1.X
                local r261_2 = r261_0 - (r261_1 or 0)
                local r261_3 = (p259_0.Y or 0) - (p259_1.Y or 0)
                r259_0 = math.sqrt(r261_2 * r261_2 + r261_3 * r261_3)
            end)
        end
        return r259_0
    end
    return nil
end

-- line 2326-2334
-- proto#262 params=2 locals=7 upvalues=2 vararg=false
function r0_72.GetDistanceString(p262_0, p262_1)
    if r0_72.bShowDistance then
        if p262_0 and p262_1 then
            local r262_0 = r0_72.CalcDistance(p262_0, p262_1)
            if r262_0 then
                local r262_1 = r262_0 / 100
                if r262_1 < 1000 then
                    return string.format("%dm", math.floor(r262_1))
                end
                return string.format("%.1fkm", r262_1 / 1000)
            end
            return ""
        end
        return ""
    end
    return ""
end

-- line 2336-2354
-- proto#263 params=0 locals=6 upvalues=3 vararg=false
function r0_72.GetMyLocation()
    local r263_0 = r0_72.GetGameplayData()
    if r263_0 then
        local r263_1 = nil
        pcall(function()
            local r264_0 = r263_0.GetLocalCharacter
            r263_1 = r264_0 and r263_0.GetLocalCharacter()
        end)
        if r0_89(r263_1) then
            return r0_72.GetCharacterLocation(r263_1)
        end
        local r263_2 = r0_72.GetMyPlayerController()
        if r0_89(r263_2) then
            pcall(function()
                if r263_2.GetPawn then
                    local r265_0 = r263_2:GetPawn()
                    if r0_89(r265_0) and r265_0.K2_GetActorLocation then
                        return r265_0:K2_GetActorLocation()
                    end
                end
            end)
        end
        return nil
    end
    return nil
end

-- line 2356-2369
-- proto#266 params=1 locals=2 upvalues=2 vararg=false
function r0_72:GetPlayerName()
    if r0_89(self) then
        local r266_0 = nil
        pcall(function()
            if self.GetPlayerNameSafety then
                r266_0 = self:GetPlayerNameSafety()
            end
        end)
        if not r266_0 then
            pcall(function()
                local r268_0
                if self.GetPlayerStateSafety then
                    r268_0 = self:GetPlayerStateSafety()
                else
                    local r268_1 = self.GetPlayerState
                    if r268_1 then
                        r268_0 = self:GetPlayerState()
                    else
                        r268_0 = r268_1
                    end
                end
                if r0_89(r268_0) and r268_0.GetPlayerName then
                    r266_0 = r268_0:GetPlayerName()
                end
            end)
        end
        local r266_1 = r266_0 or "Unknown"
        return r266_1
    end
    return "Unknown"
end

-- line 2371-2375
-- proto#269 params=1 locals=1 upvalues=1 vararg=false
function r0_72:IsAI()
    local r269_0 = false
    pcall(function()
        if Game and Game.IsAI then
            r269_0 = Game:IsAI(self)
        end
    end)
    return r269_0
end

-- line 2377-2381
-- proto#271 params=1 locals=1 upvalues=1 vararg=false
function r0_72:IsAlive()
    local r271_0 = true
    pcall(function()
        if self.IsAlive then
            r271_0 = self:IsAlive()
        end
    end)
    return r271_0
end

-- line 2383-2418
-- proto#273 params=1 locals=1 upvalues=2 vararg=false
function r0_72.IsOurESPWidget(p273_0)
    if p273_0 and slua.isValid(p273_0) then
        local r273_0 = false
        pcall(function()
            local r274_0 = tostring(p273_0)
            for r274_1, r274_2 in pairs(r0_72.ESPWidgets) do
                if r274_2 and r274_2.Widget and r274_2.Widget.Container and tostring(r274_2.Widget.Container) == r274_0 then
                    r273_0 = true
                    return
                end
            end
        end)
        if r273_0 then
            return true
        end
        pcall(function()
            if p273_0.GetChildrenCount then
                local r275_0 = p273_0:GetChildrenCount()
                for r275_1 = 0, r275_0 - 1 do
                    local r275_2 = p273_0:GetChildAt(r275_1)
                    if r275_2 and slua.isValid(r275_2) and string.find(tostring(r275_2), "Border") then
                        r273_0 = true
                        break
                    end
                end
            end
        end)
        if not r273_0 then
            pcall(function()
                local r276_0 = p273_0.Slot
                if r276_0 and r276_0.GetPosition then
                    local r276_1 = r276_0:GetPosition()
                    if r276_1 then
                        local r276_2 = math.abs(r276_1.X or 0)
                        if r276_2 > 1 then
                            r273_0 = true
                        else
                            local r276_3 = math.abs(r276_1.Y or 0)
                            if r276_3 > 1 then
                                r273_0 = true
                            end
                        end
                    end
                end
            end)
        end
        return r273_0
    end
    return false
end

-- line 2420-2484
-- proto#277 params=3 locals=24 upvalues=4 vararg=false
function r0_72.ApplyAnchorBasedPosition(p277_0, p277_1, p277_2)
    if p277_0 and p277_1 then
        local r277_0 = p277_1.X
        if not r277_0 then
            r277_0 = 0
        end
        local r277_1 = p277_1.Y
        if not r277_1 then
            r277_1 = 0
        end
        local r277_2 = r0_72.ESPWidgetSize or r0_79 and (r0_79(100, 30) or { X = 100, Y = 30 }) or {
            X = 100,
            Y = 30
        }
        local r277_3 = r0_72.ESPWidgetAlignment or r0_79 and (r0_79(0.5, 1.0) or {
            X = 0.5,
            Y = 1.0
        }) or { X = 0.5, Y = 1.0 }
        local r277_4, r277_5, r277_6 = 0, 0, r0_72._cachedViewportW
        local r277_7, r277_8, r277_9, r277_10
        if r277_6 then
            r277_9 = r0_72._cachedViewportW
            if r277_9 > 200 then
                local r277_11 = r0_72._cachedViewportW
                r277_10 = r0_72._cachedViewportH
                r277_7 = r277_11
                r277_8 = r277_10
            else
                r277_7 = r277_4
                r277_8 = r277_5
            end
        else
            r277_7 = r277_4
            r277_8 = r277_5
        end
        r277_8 = r277_6 and r277_9 > 200 and r277_10 or r277_5
        if r277_7 < 200 then
            pcall(function()
                local r278_0 = r0_72.GetMyPlayerController()
                if r0_89(r278_0) and r278_0.GetViewportSize then
                    local r278_1 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
                    r278_0:GetViewportSize(r278_1)
                    if r278_1 and r278_1.X and r278_1.X > 200 then
                        r277_7 = r278_1.X
                        r277_8 = r278_1.Y
                        r0_72._cachedViewportW = r277_7
                        r0_72._cachedViewportH = r277_8
                    end
                end
            end)
        end
        if r277_7 > 200 and r277_8 > 200 then
            r277_6 = r0_72.ESPAnchorOffsetX
            r277_6 = (r277_0 + (r277_6 or 0)) / r277_7
            local r277_12 = r0_72.ESPAnchorOffsetY
            local r277_13 = (r277_1 + (r277_12 or 0)) / r277_8
            r277_6 = math.max(0, math.min(1, r277_6))
            local r277_14 = math.max(0, math.min(1, r277_13))
            local r277_15 = false
            pcall(function()
                local r279_0 = import("Anchors")
                if not r279_0 then
                    r279_0 = import("/Script/SlateCore.Anchors")
                end
                if p277_0.SetAnchors and r279_0 then
                    local r279_1 = r279_0(r277_6, r277_14, r277_6, r277_14)
                    if r279_1 then
                        p277_0:SetAnchors(r279_1)
                        local r279_2 = p277_0
                        local r279_3 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or {
                            X = 0,
                            Y = 0
                        }
                        r279_2:SetPosition(r279_3)
                        r277_15 = true
                    end
                end
            end)
            if not r277_15 then
                pcall(function()
                    if p277_0.SetAnchors then
                        p277_0:SetAnchors(r277_6, r277_14, r277_6, r277_14)
                        local r280_0 = p277_0
                        local r280_1 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or {
                            X = 0,
                            Y = 0
                        }
                        r280_0:SetPosition(r280_1)
                        r277_15 = true
                    end
                end)
            end
            if r277_15 then
                pcall(function()
                    if p277_0.SetOffsets and import("Margin") then
                        p277_0:SetOffsets(import("Margin")(0, 0, r277_2.X, r277_2.Y))
                    end
                end)
                pcall(function()
                    p277_0:SetSize(r277_2)
                end)
                pcall(function()
                    p277_0:SetAlignment(r277_3)
                end)
                pcall(function()
                    if p277_0.SetAutoSize then
                        p277_0:SetAutoSize(r0_72.ESPWidgetAutoSize or true)
                    end
                end)
                pcall(function()
                    if p277_0.SetZOrder then
                        p277_0:SetZOrder(r0_72.ESPWidgetZOrder or 2)
                    end
                end)
                return true
            end
        end
        pcall(function()
            local r286_0 = p277_0
            local r286_1 = r0_79 and (r0_79(r277_0, r277_1) or { X = r277_0, Y = r277_1 }) or {
                X = r277_0,
                Y = r277_1
            }
            r286_0:SetPosition(r286_1)
            pcall(function()
                p277_0:SetSize(r277_2)
            end)
            pcall(function()
                p277_0:SetAlignment(r277_3)
            end)
            pcall(function()
                if p277_0.SetAutoSize then
                    p277_0:SetAutoSize(r0_72.ESPWidgetAutoSize or true)
                end
            end)
            pcall(function()
                if p277_0.SetZOrder then
                    p277_0:SetZOrder(r0_72.ESPWidgetZOrder or 2)
                end
            end)
        end)
        return false
    end
    return false
end

-- line 2486-2514
-- proto#291 params=0 locals=3 upvalues=2 vararg=false
function r0_72.InitESPCanvas()
    if r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas) then
        return true
    end
    local r291_0 = nil
    pcall(function()
        r291_0 = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
    end)
    if r291_0 then
        local r291_1 = nil
        pcall(function()
            r291_1 = r291_0.GetMainControlBaseUI()
        end)
        if r291_1 and Game:IsValid(r291_1) then
            local r291_2 = nil
            pcall(function()
                if r291_1.CanvasPanel_0 and Game:IsValid(r291_1.CanvasPanel_0) then
                    r291_2 = r291_1.CanvasPanel_0
                elseif r291_1.CanvasPanel_42 and Game:IsValid(r291_1.CanvasPanel_42) then
                    r291_2 = r291_1.CanvasPanel_42
                end
            end)
            if r291_2 then
                r0_72.ESPCanvas = r291_2
                pcall(function()
                    local r295_0 = r291_2:GetChildrenCount()
                    for r295_1 = r295_0 - 1, 0, -1 do
                        local r295_2 = r291_2:GetChildAt(r295_1)
                        if r295_2 and slua.isValid(r295_2) and r0_72.IsOurESPWidget(r295_2) then
                            pcall(function()
                                r291_2:RemoveChild(r295_2)
                            end)
                        end
                    end
                end)
                return true
            end
            return false
        end
        return false
    end
    return false
end

-- line 2516-2537
-- proto#297 params=3 locals=9 upvalues=2 vararg=false
function r0_72.FindProgressBarInWidget(p297_0, p297_1, p297_2)
    if p297_0 and slua.isValid(p297_0) then
        local r297_0 = p297_1
        if not p297_1 then
            r297_0 = 0
        end
        local r297_1 = p297_2
        if not p297_2 then
            r297_1 = 5
        end
        if r297_1 < r297_0 then
            return nil
        end
        local r297_2 = false
        pcall(function()
            if p297_0.SetPercent and p297_0.SetFillColorAndOpacity then
                r297_2 = true
            end
        end)
        if r297_2 then
            return p297_0
        end
        local r297_3 = 0
        pcall(function()
            if p297_0.GetChildrenCount then
                r297_3 = p297_0:GetChildrenCount()
            end
        end)
        local r297_4 = math.max
        for r297_5 = 0, r297_4(r297_3 - 1, 0) do
            local r297_6 = nil
            pcall(function()
                r297_6 = p297_0:GetChildAt(r297_5)
            end)
            if r297_6 and slua.isValid(r297_6) then
                local r297_7 = r0_72.FindProgressBarInWidget(r297_6, r297_0 + 1, r297_1)
                if r297_7 then
                    return r297_7
                end
            end
        end
        return nil
    end
    return nil
end

-- line 2539-2554
-- proto#301 params=1 locals=1 upvalues=2 vararg=false
function r0_72:GetTeamID()
    if r0_89(self) then
        local r301_0 = nil
        pcall(function()
            if self.GetTeamID then
                r301_0 = self:GetTeamID()
            end
        end)
        if not r301_0 then
            pcall(function()
                local r303_0
                if self.GetPlayerStateSafety then
                    r303_0 = self:GetPlayerStateSafety()
                else
                    local r303_1 = self.GetPlayerState
                    if r303_1 then
                        r303_0 = self:GetPlayerState()
                    else
                        r303_0 = r303_1
                    end
                end
                if r0_89(r303_0) and r303_0.GetTeamID then
                    r301_0 = r303_0:GetTeamID()
                elseif r0_89(r303_0) and r303_0.TeamID then
                    r301_0 = r303_0.TeamID
                end
            end)
        end
        if not r301_0 then
            pcall(function()
                if self.TeamID then
                    r301_0 = self.TeamID
                end
            end)
        end
        return r301_0
    end
    return nil
end

-- line 2556-2584
-- proto#305 params=1 locals=8 upvalues=1 vararg=false
function r0_72.GetTeamColor(p305_0)
    if p305_0 == nil or p305_0 == 0 then
        local r305_0 = r0_80 and (r0_80(0.2, 0.4, 1.0, 1.0) or { R = 50, G = 100, B = 255, A = 255 }) or {
            R = 50,
            G = 100,
            B = 255,
            A = 255
        }
        return r305_0
    end
    local r305_1 = {
        { R = 255, G = 50, B = 50, A = 255, fR = 1.0, fG = 0.2, fB = 0.2 },
        { R = 50, G = 255, B = 50, A = 255, fR = 0.2, fG = 1.0, fB = 0.2 },
        { R = 50, G = 100, B = 255, A = 255, fR = 0.2, fG = 0.4, fB = 1.0 },
        { R = 255, G = 255, B = 50, A = 255, fR = 1.0, fG = 1.0, fB = 0.2 },
        { R = 255, G = 50, B = 255, A = 255, fR = 1.0, fG = 0.2, fB = 1.0 },
        { R = 50, G = 255, B = 255, A = 255, fR = 0.2, fG = 1.0, fB = 1.0 },
        { R = 255, G = 150, B = 50, A = 255, fR = 1.0, fG = 0.6, fB = 0.2 },
        { R = 150, G = 50, B = 255, A = 255, fR = 0.6, fG = 0.2, fB = 1.0 },
        { R = 200, G = 255, B = 50, A = 255, fR = 0.8, fG = 1.0, fB = 0.2 },
        { R = 50, G = 150, B = 255, A = 255, fR = 0.2, fG = 0.6, fB = 1.0 },
        { R = 255, G = 100, B = 150, A = 255, fR = 1.0, fG = 0.4, fB = 0.6 },
        { R = 100, G = 255, B = 150, A = 255, fR = 0.4, fG = 1.0, fB = 0.6 },
        { R = 150, G = 150, B = 50, A = 255, fR = 0.6, fG = 0.6, fB = 0.2 },
        { R = 50, G = 200, B = 150, A = 255, fR = 0.2, fG = 0.8, fB = 0.6 },
        { R = 255, G = 200, B = 50, A = 255, fR = 1.0, fG = 0.8, fB = 0.2 }
    }
    local r305_2 = p305_0 % 15
    local r305_3 = r305_2 == 0 and 15 or r305_2
    local r305_4 = r305_1[r305_3]
    local r305_5 = r0_80 and (r0_80(r305_4.fR, r305_4.fG, r305_4.fB, 1.0) or {
        R = r305_4.R,
        G = r305_4.G,
        B = r305_4.B,
        A = r305_4.A
    }) or { R = r305_4.R, G = r305_4.G, B = r305_4.B, A = r305_4.A }
    return r305_5
end

local r0_90 = nil
local r0_91 = false

-- line 2588-2600
-- proto#306 params=0 locals=0 upvalues=3 vararg=false
local function r0_92()
    if r0_90 then
        return r0_90
    end
    if r0_91 then
        return nil
    end
    pcall(function()
        for r307_0, r307_1 in ipairs({
            "/Game/BluePrints/UI/Textures/White.White",
            "/Game/BluePrints/UI/Textures/Common/White.White",
            "/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture"
        }) do
            pcall(function()
                local r308_0 = import(r307_1)
                if not (r308_0 and slua.isValid(r308_0)) then
                    return
                end
                r0_90 = r308_0
            end)
            if r0_90 then
                break
            end
        end
    end)
    if not r0_90 then
        r0_91 = true
    end
    return r0_90
end

-- line 2602-2619
-- proto#309 params=2 locals=1 upvalues=2 vararg=false
local function r0_93(p309_0, p309_1)
    if p309_0 and slua.isValid(p309_0) then
        local r309_0 = false
        pcall(function()
            if p309_0.SetBrushTintColor then
                p309_0:SetBrushTintColor(p309_1)
                r309_0 = true
            end
        end)
        pcall(function()
            if p309_0.SetColorAndOpacity then
                p309_0:SetColorAndOpacity(p309_1)
                r309_0 = true
            end
        end)
        pcall(function()
            if p309_0.SetBrushFromTexture then
                local r312_0 = r0_92()
                if r312_0 then
                    p309_0:SetBrushFromTexture(r312_0, false)
                    if p309_0.SetColorAndOpacity then
                        p309_0:SetColorAndOpacity(p309_1)
                    end
                    r309_0 = true
                end
            end
        end)
        pcall(function()
            p309_0:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            p309_0:SetRenderOpacity(1.0)
        end)
        return r309_0
    end
    return false
end

-- line 2621-2630
-- proto#314 params=1 locals=1 upvalues=1 vararg=false
function r0_72._GetWidgetRoot(p314_0)
    if p314_0 and slua.isValid(p314_0) then
        local r314_0 = nil
        pcall(function()
            if p314_0.GetRootWidget then
                r314_0 = p314_0:GetRootWidget()
            end
        end)
        if r314_0 and slua.isValid(r314_0) then
            return r314_0
        end
        pcall(function()
            if p314_0.WidgetTree and p314_0.WidgetTree.RootWidget then
                r314_0 = p314_0.WidgetTree.RootWidget
            end
        end)
        if r314_0 and slua.isValid(r314_0) then
            return r314_0
        end
        pcall(function()
            if p314_0.RootWidget and slua.isValid(p314_0.RootWidget) then
                r314_0 = p314_0.RootWidget
            end
        end)
        return r314_0
    end
    return nil
end

-- line 2632-2671
-- proto#318 params=3 locals=14 upvalues=2 vararg=false
function r0_72._FindNamedWidgetInTree(p318_0, p318_1, p318_2)
    if not (p318_0 and slua.isValid(p318_0)) then
        return nil
    end
    local r318_0 = p318_2
    if not p318_2 then
        r318_0 = 8
    end
    local r318_1 = nil
    pcall(function()
        if p318_0.GetName then
            r318_1 = p318_0:GetName()
        end
    end)
    if r318_1 and r318_1 == p318_1 then
        return p318_0
    end
    local r318_2 = tostring(p318_0)
    if r318_2 then
        local r318_3 = string.find(r318_2, p318_1, 1, true)
        if r318_3 then
            if r318_1 and r318_1 == p318_1 then
                return p318_0
            end
            if not r318_1 or r318_1 == "" then
                local r318_4, r318_5 = string.find(r318_2, p318_1, 1, true)
                if r318_5 and string.sub(r318_2, r318_5 + 1, r318_5 + 1) ~= "_" and string.sub(r318_2, r318_5 + 1, r318_5 + 1) ~= "" then
                    return p318_0
                end
            end
        end
    end
    local r318_6 = 0
    pcall(function()
        if p318_0.GetChildrenCount then
            r318_6 = p318_0:GetChildrenCount()
        end
    end)
    if r318_6 > 0 then
        for r318_7 = 0, r318_6 - 1 do
            local r318_8 = nil
            pcall(function()
                r318_8 = p318_0:GetChildAt(r318_7)
            end)
            if r318_8 and slua.isValid(r318_8) then
                local r318_9 = r0_72._FindNamedWidgetInTree(r318_8, p318_1, r318_0 - 1)
                if r318_9 then
                    return r318_9
                end
            end
        end
        return nil
    end
    local r318_10 = r0_72._GetWidgetRoot(p318_0)
    if not (r318_10 and slua.isValid(r318_10) and r318_10 ~= p318_0) then
        return
    end
    local r318_11 = r0_72._FindNamedWidgetInTree(r318_10, p318_1, r318_0 - 1)
    if r318_11 then
        return r318_11
    end
    return nil
end

-- line 2673-2727
-- proto#322 params=2 locals=2 upvalues=4 vararg=false
function r0_72.ApplyTeamColor(p322_0, p322_1)
    if not (p322_0 and p322_0.Container) then
        return
    end
    if _G.LexusConfig.Esp9_Team then
        local r322_0 = r0_72.GetTeamColor(p322_1)
        if r322_0 then
            pcall(function()
                local r324_0 = p322_0.Container
                if not (r324_0 and slua.isValid(r324_0)) then
                    return
                end
                local r324_1 = r0_72._FindNamedWidgetInTree(r324_0, "Image_TeamBG", 8)
                if r324_1 and slua.isValid(r324_1) then
                    local r324_2 = r0_93(r324_1, r322_0)
                end
                local r324_3 = r0_72._FindNamedWidgetInTree(r324_0, "Image_TeamLogoBG", 8)
                if r324_3 and slua.isValid(r324_3) then
                    r0_93(r324_3, r322_0)
                end
                if r324_0.SetTeamColor then
                    pcall(function()
                        r324_0:SetTeamColor(p322_1)
                    end)
                end
                if p322_0.TeamBgBorder and slua.isValid(p322_0.TeamBgBorder) then
                    pcall(function()
                        p322_0.TeamBgBorder:SetBrushColor(r322_0)
                        p322_0.TeamBgBorder:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        p322_0.TeamBgBorder:SetRenderOpacity(0.7)
                    end)
                else
                    pcall(function()
                        local r326_0 = CGame:NewObjectFromPath("/Script/UMG.Border", r324_0)
                        if r326_0 and slua.isValid(r326_0) then
                            pcall(function()
                                r326_0:SetBrushColor(r322_0)
                            end)
                            pcall(function()
                                r326_0:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            end)
                            pcall(function()
                                r326_0:SetRenderOpacity(0.7)
                            end)
                            pcall(function()
                                local r330_0 = r326_0
                                local r330_1 = r0_79 and (r0_79(120, 20) or { X = 120, Y = 20 }) or {
                                    X = 120,
                                    Y = 20
                                }
                                r330_0:SetDesiredSizeOverride(r330_1)
                            end)
                            pcall(function()
                                if r324_0.AddChild then
                                    r324_0:AddChild(r326_0)
                                end
                            end)
                            pcall(function()
                                if r326_0.SetZOrder then
                                    r326_0:SetZOrder(-1)
                                end
                            end)
                            p322_0.TeamBgBorder = r326_0
                        end
                    end)
                end
            end)
            return
        end
        return
    end
    pcall(function()
        local r323_0 = p322_0.Container
        if r323_0 and slua.isValid(r323_0) then
            local r323_1 = r0_72._FindNamedWidgetInTree(r323_0, "Image_TeamBG", 8)
            if r323_1 and slua.isValid(r323_1) then
                r323_1:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
            local r323_2 = r0_72._FindNamedWidgetInTree(r323_0, "Image_TeamLogoBG", 8)
            if r323_2 and slua.isValid(r323_2) then
                r323_2:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
            if p322_0.TeamBgBorder and slua.isValid(p322_0.TeamBgBorder) then
                p322_0.TeamBgBorder:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end
    end)
end

-- line 2729-2735
-- proto#334 params=1 locals=1 upvalues=2 vararg=false
function r0_72.GetCharacterMesh(p334_0)
    if r0_89(p334_0) then
        local r334_0 = nil
        pcall(function()
            if p334_0.Mesh and Game:IsValid(p334_0.Mesh) then
                r334_0 = p334_0.Mesh
            end
        end)
        if not r334_0 then
            pcall(function()
                r334_0 = p334_0:GetComponentByClass(import("/Script/Engine.SkeletalMeshComponent"))
            end)
        end
        return r334_0
    end
    return nil
end

-- line 2737-2749
-- proto#337 params=1 locals=3 upvalues=3 vararg=false
function r0_72.GetESPLocation(p337_0)
    if r0_89(p337_0) then
        local r337_0 = r0_72.GetCharacterLocation(p337_0)
        if r337_0 then
            local r337_1 = 85
            pcall(function()
                if p337_0.bIsCrouched then
                    r337_1 = 60
                end
                if p337_0.IsProne and p337_0:IsProne() then
                    r337_1 = 30
                end
            end)
            pcall(function()
                r337_0.Z = r337_0.Z + r337_1 + (r0_72.ESPWorldOffsetZ or 0)
            end)
        end
        return r337_0
    end
    return nil
end

-- line 2751-2779
-- proto#340 params=1 locals=1 upvalues=2 vararg=false
function r0_72.GetCharacterWeaponInfo(p340_0)
    if r0_89(p340_0) then
        local r340_0, r340_1, r340_2, r340_3, r340_4 = nil, nil, nil, nil, nil
        pcall(function()
            if p340_0.GetCurrentWeapon then
                r340_4 = p340_0:GetCurrentWeapon()
            end
        end)
        if not r340_4 then
            pcall(function()
                r340_4 = p340_0.CurrentWeapon
            end)
        end
        if not r340_4 then
            pcall(function()
                if p340_0.GetWeaponManager then
                    local r343_0 = p340_0:GetWeaponManager()
                    if r343_0 and r343_0.GetCurrentWeapon then
                        r340_4 = r343_0:GetCurrentWeapon()
                    end
                end
            end)
        end
        if r340_4 and r0_89(r340_4) then
            pcall(function()
                if r340_4.GetWeaponID then
                    r340_0 = r340_4:GetWeaponID()
                end
            end)
            if not r340_0 then
                pcall(function()
                    r340_0 = r340_4.WeaponID
                end)
            end
            if not r340_0 then
                pcall(function()
                    if r340_4.GetItemID then
                        r340_0 = r340_4:GetItemID()
                    end
                end)
            end
            pcall(function()
                if r340_4.GetWeaponName then
                    r340_1 = r340_4:GetWeaponName()
                end
            end)
            pcall(function()
                if r340_4.GetWeaponIconPath then
                    r340_2 = r340_4:GetWeaponIconPath()
                end
            end)
            pcall(function()
                if r340_4.GetWeaponIcon then
                    r340_3 = r340_4:GetWeaponIcon()
                end
            end)
        end
        if not r340_0 then
            pcall(function()
                local r350_0
                if p340_0.GetPlayerStateSafety then
                    r350_0 = p340_0:GetPlayerStateSafety()
                else
                    local r350_1 = p340_0.GetPlayerState
                    if r350_1 then
                        r350_0 = p340_0:GetPlayerState()
                    else
                        r350_0 = r350_1
                    end
                end
                if r350_0 and r0_89(r350_0) then
                    if r350_0.GetCurrentWeaponID then
                        r340_0 = r350_0:GetCurrentWeaponID()
                    end
                    if not r340_0 and r350_0.CurWeaponID then
                        r340_0 = r350_0.CurWeaponID
                    end
                end
            end)
        end
        return {
            WeaponID = r340_0,
            WeaponName = r340_1,
            WeaponIconPath = r340_2,
            WeaponIconTexture = r340_3,
            CurrentWeapon = r340_4
        }
    end
    return nil
end

-- line 2781-2814
-- proto#351 params=3 locals=15 upvalues=2 vararg=false
function r0_72.FindWeaponIconInWidget(p351_0, p351_1, p351_2)
    if p351_0 and slua.isValid(p351_0) then
        local r351_0 = p351_1
        if not p351_1 then
            r351_0 = 0
        end
        local r351_1 = p351_2
        if not p351_2 then
            r351_1 = 8
        end
        local r351_2 = {
            "Image_Weapon",
            "Image_WeaponIcon",
            "Image_Gun",
            "Image_Icon",
            "WeaponIcon",
            "WeaponImage",
            "Image_Equip"
        }
        for r351_3, r351_4 in ipairs(r351_2) do
            pcall(function()
                local r352_0 = p351_0[r351_4]
                if r352_0 and slua.isValid(r352_0) then
                    local r352_1 = false
                    pcall(function()
                        if r352_0.Brush then
                            r352_1 = true
                        end
                    end)
                    if r352_1 then
                        return r352_0
                    end
                end
            end)
        end
        if r351_1 <= r351_0 then
            return nil
        end
        local r351_5 = 0
        pcall(function()
            if p351_0.GetChildrenCount then
                r351_5 = p351_0:GetChildrenCount()
            end
        end)
        local r351_6 = math.max
        for r351_7 = 0, r351_6(r351_5 - 1, 0) do
            local r351_8 = nil
            pcall(function()
                r351_8 = p351_0:GetChildAt(r351_7)
            end)
            if r351_8 and slua.isValid(r351_8) then
                local r351_9 = r0_72.FindWeaponIconInWidget(r351_8, r351_0 + 1, r351_1)
                if r351_9 then
                    return r351_9
                end
            end
        end
        if r351_5 == 0 then
            local r351_10 = r0_72._GetWidgetRoot(p351_0)
            if r351_10 and slua.isValid(r351_10) and r351_10 ~= p351_0 then
                local r351_11 = r0_72.FindWeaponIconInWidget(r351_10, r351_0 + 1, r351_1)
                if r351_11 then
                    return r351_11
                end
            end
        end
        return nil
    end
    return nil
end

-- line 2816-2834
-- proto#356 params=3 locals=2 upvalues=3 vararg=false
function r0_72.FixWeaponIconBrushSize(p356_0, p356_1, p356_2)
    if not (p356_0 and slua.isValid(p356_0)) then
        return
    end
    local r356_0 = p356_1
    if not p356_1 then
        r356_0 = 138
    end
    local r356_1 = p356_2
    if not p356_2 then
        r356_1 = 69
    end
    pcall(function()
        local r357_0 = p356_0.Brush
        if r357_0 then
            local r357_1 = r0_79 and (r0_79(r356_0, r356_1) or { X = r356_0, Y = r356_1 }) or {
                X = r356_0,
                Y = r356_1
            }
            r357_0.ImageSize = r357_1
            r357_0.DrawAs = 3
            local r357_2 = r0_80 and (r0_80(1.0, 1.0, 1.0, 1.0) or { R = 1, G = 1, B = 1, A = 1 }) or {
                R = 1,
                G = 1,
                B = 1,
                A = 1
            }
            r357_0.TintColor = r357_2
            if p356_0.SetBrush then
                p356_0:SetBrush(r357_0)
            end
        end
        if p356_0.SetDesiredSizeOverride then
            local r357_3 = p356_0
            local r357_4 = r0_79 and (r0_79(r356_0, r356_1) or { X = r356_0, Y = r356_1 }) or {
                X = r356_0,
                Y = r356_1
            }
            r357_3:SetDesiredSizeOverride(r357_4)
        end
        local r357_5 = p356_0.Slot
        if r357_5 and r357_5.SetSize then
            local r357_6 = r357_5
            local r357_7 = r0_79 and (r0_79(r356_0, r356_1) or { X = r356_0, Y = r356_1 }) or {
                X = r356_0,
                Y = r356_1
            }
            r357_6:SetSize(r357_7)
        end
        p356_0:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        p356_0:SetRenderOpacity(1.0)
        local r357_8 = p356_0
        local r357_9 = r0_80 and (r0_80(1.0, 1.0, 1.0, 1.0) or { R = 1, G = 1, B = 1, A = 1 }) or {
            R = 1,
            G = 1,
            B = 1,
            A = 1
        }
        r357_8:SetColorAndOpacity(r357_9)
    end)
end

-- line 2836-2853
-- proto#358 params=2 locals=5 upvalues=2 vararg=false
function r0_72.ApplyWeaponIconFullOpacity(p358_0, p358_1)
    local r358_0 = r0_80 and (r0_80(1.0, 1.0, 1.0, 1.0) or { R = 1, G = 1, B = 1, A = 1 }) or {
        R = 1,
        G = 1,
        B = 1,
        A = 1
    }
    if not (p358_1 and slua.isValid(p358_1)) then
        return
    end
    pcall(function()
        if p358_1.SetRenderOpacity then
            p358_1:SetRenderOpacity(1.0)
        end
    end)
    pcall(function()
        if p358_1.SetColorAndOpacity then
            p358_1:SetColorAndOpacity(r358_0)
        end
    end)
    pcall(function()
        local r361_0 = p358_1.Brush
        if r361_0 then
            pcall(function()
                r361_0.TintColor = r358_0
            end)
            if p358_1.SetBrush then
                p358_1:SetBrush(r361_0)
            end
        end
    end)
    local r358_1 = {
        "Border_WeaponColor",
        "Border_Weapon",
        "Border_WeaponIcon",
        "SizeBox_Weapon",
        "ScaleBox_Weapon",
        "Switcher_WeaponIcon"
    }
    for r358_2, r358_3 in ipairs(r358_1) do
        pcall(function()
            local r363_0 = p358_0
            if p358_0 then
                r363_0 = p358_0[r358_3]
            end
            if r363_0 and slua.isValid(r363_0) and r363_0.SetRenderOpacity then
                r363_0:SetRenderOpacity(1.0)
            end
            if r363_0 and slua.isValid(r363_0) and r363_0.SetColorAndOpacity then
                r363_0:SetColorAndOpacity(r358_0)
            end
        end)
    end
end

-- line 2855-2910
-- proto#364 params=2 locals=10 upvalues=2 vararg=false
function r0_72.ApplyWeaponIconToImage(p364_0, p364_1)
    if p364_0 and slua.isValid(p364_0) then
        if p364_1 and p364_1.WeaponID then
            local r364_0, r364_1, r364_2, r364_3, r364_4 = nil, "none", false, 138, 69
            pcall(function()
                local r365_0 = CDataTable.GetTableData("Item", p364_1.WeaponID)
                if r365_0 and r365_0.KillWhiteIcon and r365_0.KillWhiteIcon ~= "" then
                    r364_0 = r365_0.KillWhiteIcon
                    r364_1 = "KillWhiteIcon"
                end
                if (not r364_0 or r364_0 == "") and p364_1.WeaponIconPath and p364_1.WeaponIconPath ~= "" then
                    r364_0 = p364_1.WeaponIconPath
                    r364_1 = "WeaponIconPath"
                end
                if (not r364_0 or r364_0 == "") and p364_1.WeaponIconTexture and slua.isValid(p364_1.WeaponIconTexture) and p364_0.SetBrushFromTexture then
                    p364_0:SetBrushFromTexture(p364_1.WeaponIconTexture, true)
                    r364_1 = "WeaponIconTexture"
                    return
                end
                if not r364_0 or r364_0 == "" then
                    local r365_1 = require("client.common.ui_util")
                    local r365_2, r365_3 = r365_1.GetItemBigIcon(p364_1.WeaponID, p364_0)
                    r364_2 = r365_3
                    r364_0 = r365_2
                    if r364_0 and r364_0 ~= "" then
                        r364_1 = "GetItemBigIcon"
                    end
                end
                if not r364_0 or r364_0 == "" then
                    r364_0 = require("client.common.ui_util").GetItemSmallIcon(p364_1.WeaponID, p364_0, r364_2)
                    if r364_0 and r364_0 ~= "" then
                        r364_1 = "GetItemSmallIcon"
                    end
                end
            end)
            if r364_1 == "WeaponIconTexture" then
                r0_72.FixWeaponIconBrushSize(p364_0, r364_3, r364_4)
                return true, r364_1
            end
            if r364_0 and r364_0 ~= "" then
                local r364_5 = false
                pcall(function()
                    if p364_0.SetBrushResourceFromPathSync then
                        p364_0:SetBrushResourceFromPathSync(r364_0, true)
                        r364_5 = true
                    end
                    if not r364_5 then
                        local r366_0 = require("client.slua_ui_framework.util")
                        local r366_1 = {
                            sync = true,
                            bMatchSize = true,
                            bIsInCombatState = true,
                            bHasAddKnownMissing = r364_2
                        }
                        r364_5 = r366_0.SetTexture(p364_0, r364_0, r366_1) ~= nil
                    end
                    if not r364_5 then
                        local r366_2 = import(r364_0)
                        if r366_2 and slua.isValid(r366_2) and p364_0.SetBrushFromTexture then
                            p364_0:SetBrushFromTexture(r366_2, true)
                            r364_5 = true
                        end
                    end
                    if not r364_5 then
                        local r366_3 = import("LoadObject")
                        if r366_3 then
                            local r366_4 = r366_3(r364_0)
                            if r366_4 and slua.isValid(r366_4) and p364_0.SetBrushFromTexture then
                                p364_0:SetBrushFromTexture(r366_4, true)
                                r364_5 = true
                            end
                        end
                    end
                end)
                if r364_5 then
                    r0_72.FixWeaponIconBrushSize(p364_0, r364_3, r364_4)
                end
                local r364_6 = tostring(r364_0)
                return r364_5, r364_1 .. ":" .. r364_6
            end
            local r364_7 = false
            return r364_7, "no_path"
        end
        return false, "no_weapon_id"
    end
    return false, "no_widget"
end

-- line 2912-2937
-- proto#367 params=2 locals=1 upvalues=1 vararg=false
function r0_72.CopyWeaponIconBrushFromNative(p367_0, p367_1)
    if p367_0 and slua.isValid(p367_0) then
        if p367_1 and slua.isValid(p367_1) then
            local r367_0 = false
            pcall(function()
                local r368_0 = p367_1.Brush
                if r368_0 then
                    local r368_1 = nil
                    pcall(function()
                        r368_1 = r368_0.ResourceObject
                    end)
                    if r368_1 and slua.isValid(r368_1) and p367_0.SetBrushFromTexture then
                        p367_0:SetBrushFromTexture(r368_1, true)
                        r367_0 = true
                    end
                    if r367_0 then
                        local r368_2 = nil
                        pcall(function()
                            r368_2 = r368_0.ImageSize
                        end)
                        if r368_2 then
                            local r368_3 = p367_0.Brush
                            if r368_3 then
                                r368_3.ImageSize = r368_2
                                if p367_0.SetBrush then
                                    p367_0:SetBrush(r368_3)
                                end
                            end
                        end
                    end
                end
            end)
            return r367_0
        end
        return false
    end
    return false
end

-- line 2939-3274
-- proto#371 params=2 locals=1 upvalues=4 vararg=false
function r0_72.AddWeaponIconToESP(p371_0, p371_1)
    if not (p371_0 and p371_0.Container) then
        return
    end
    local r371_0 = p371_0.Container
    if not slua.isValid(r371_0) then
        return
    end
    if _G.LexusConfig.Esp9_Weapon then
        pcall(function()
            local r373_0 = r371_0.WeaponIcon
            local r373_1
            if r373_0 then
                local r373_2 = slua.isValid(r373_0)
                if r373_2 then
                    r373_1 = r373_2
                else
                    r373_1 = r0_72.FindWeaponIconInWidget(r371_0, 0, 8)
                end
            else
                r373_1 = r0_72.FindWeaponIconInWidget(r371_0, 0, 8)
            end
            if not (r373_1 and slua.isValid(r373_1)) then
                return
            end
            local r373_3 = p371_1 and r0_72.GetCharacterWeaponInfo(p371_1) or nil
            if r373_3 and r373_3.WeaponID and r373_3.WeaponID ~= 0 then
                local r373_4 = p371_0._LastWeaponID
                local r373_5 = r373_3.WeaponID
                if r373_4 == r373_5 and p371_0._WeaponIconApplied then
                    pcall(function()
                        r373_1:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                    pcall(function()
                        r373_1:SetRenderOpacity(1.0)
                    end)
                    local r373_6 = {
                        "Border_WeaponColor",
                        "Border_Weapon",
                        "Border_WeaponIcon",
                        "SizeBox_Weapon",
                        "ScaleBox_Weapon",
                        "Switcher_WeaponIcon"
                    }
                    for r373_7, r373_8 in ipairs(r373_6) do
                        pcall(function()
                            local r378_0 = r371_0
                            if r371_0 then
                                r378_0 = r371_0[r373_8]
                            end
                            if r378_0 and slua.isValid(r378_0) and r378_0.SetWidgetVisibility then
                                r378_0:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                pcall(function()
                                    if r378_0.SetRenderOpacity then
                                        r378_0:SetRenderOpacity(1.0)
                                    end
                                end)
                            end
                        end)
                    end
                    if p371_0._CachedSwitcherIndexes then
                        for r373_9, r373_10 in pairs(p371_0._CachedSwitcherIndexes) do
                            pcall(function()
                                local r380_0 = r371_0[r373_9]
                                if r380_0 and slua.isValid(r380_0) and r380_0.SetActiveWidgetIndex then
                                    r380_0:SetActiveWidgetIndex(r373_10)
                                end
                            end)
                        end
                    end
                    if p371_0._CachedParentSwitchers then
                        for r373_11, r373_12 in pairs(p371_0._CachedParentSwitchers) do
                            pcall(function()
                                if r373_12.w and slua.isValid(r373_12.w) and r373_12.w.SetActiveWidgetIndex then
                                    r373_12.w:SetActiveWidgetIndex(r373_12.idx)
                                end
                            end)
                        end
                    end
                    return
                end
                local r373_13 = {
                    "Border_WeaponColor",
                    "Border_Weapon",
                    "Border_WeaponIcon",
                    "SizeBox_Weapon",
                    "ScaleBox_Weapon",
                    "Switcher_WeaponIcon"
                }
                for r373_14, r373_15 in ipairs(r373_13) do
                    pcall(function()
                        local r382_0 = r371_0
                        if r371_0 then
                            r382_0 = r371_0[r373_15]
                        end
                        if r382_0 and slua.isValid(r382_0) and r382_0.SetWidgetVisibility then
                            r382_0:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        end
                    end)
                end
                local r373_16 = false
                local r373_17
                if r373_3 then
                    local r373_18 = r373_3.WeaponID
                    if r373_18 then
                        local r373_19, r373_20 = r0_72.ApplyWeaponIconToImage(r373_1, r373_3)
                        if r373_19 then
                            r373_17 = true
                        else
                            r373_17 = r373_19
                        end
                    else
                        r373_17 = r373_18
                    end
                else
                    r373_17 = r373_16
                end
                local r373_21 = false
                if p371_1 and r373_3 and r373_3 and r373_3.WeaponID then
                    pcall(function()
                        if r371_0.SetWeaponIcon then
                            r371_0:SetWeaponIcon(r373_3.WeaponID)
                            r373_21 = true
                        end
                    end)
                    if not r373_21 then
                        pcall(function()
                            if r371_0.SetWeaponIconByID then
                                r371_0:SetWeaponIconByID(r373_3.WeaponID)
                                r373_21 = true
                            end
                        end)
                    end
                    if not r373_21 then
                        pcall(function()
                            if r371_0.UpdateWeaponIcon then
                                r371_0:UpdateWeaponIcon(r373_3.WeaponID)
                                r373_21 = true
                            end
                        end)
                    end
                    if not r373_21 then
                        pcall(function()
                            if r371_0.SetWeaponID then
                                r371_0:SetWeaponID(r373_3.WeaponID)
                                r373_21 = true
                            end
                        end)
                    end
                    pcall(function()
                        if r371_0.SetData then
                            r371_0:SetData(p371_1)
                        end
                    end)
                    pcall(function()
                        if r371_0.SetPlayerInfo then
                            r371_0:SetPlayerInfo(p371_1)
                        end
                    end)
                    if r373_3.CurrentWeapon then
                        pcall(function()
                            if r371_0.SetCurrentWeapon then
                                r371_0:SetCurrentWeapon(r373_3.CurrentWeapon)
                            end
                        end)
                    end
                end
                if r373_21 then
                    pcall(function()
                        local r390_0, r390_1, r390_2, r390_3
                        local r390_4 = r371_0.Image_Icon
                        local r390_5, r390_6
                        if r390_4 then
                            r390_0 = slua.isValid(r390_4)
                            if r390_0 then
                                r390_5 = r390_0
                                r390_6 = r390_0
                            else
                                r390_1 = r371_0.CanvasPanel_Type1
                                if r390_1 then
                                    r390_2 = r371_0.CanvasPanel_Type1
                                    r390_5 = r390_2.Image_Icon
                                    r390_6 = r390_2
                                else
                                    r390_5 = r390_1
                                    r390_6 = r390_1
                                end
                            end
                        else
                            r390_1 = r371_0.CanvasPanel_Type1
                            if r390_1 then
                                r390_2 = r371_0.CanvasPanel_Type1
                                r390_5 = r390_2.Image_Icon
                                r390_6 = r390_2
                            else
                                r390_5 = r390_1
                                r390_6 = r390_1
                            end
                        end
                        r390_6 = r390_4 and r390_0 or r390_1 and r390_2
                        local r390_7
                        if r390_5 then
                            local r390_8 = slua.isValid(r390_5)
                            if r390_8 then
                                r390_7 = r390_8
                            else
                                r390_3 = function(p391_0, p391_1)
                                    if p391_0 and slua.isValid(p391_0) and not (p391_1 > 8) then
                                        local r391_0 = p391_0.Image_Icon
                                        if r391_0 and slua.isValid(r391_0) then
                                            return r391_0
                                        end
                                        local r391_1 = 0
                                        pcall(function()
                                            if p391_0.GetChildrenCount then
                                                r391_1 = p391_0:GetChildrenCount()
                                            end
                                        end)
                                        local r391_2 = math.max
                                        for r391_3 = 0, r391_2(r391_1 - 1, 0) do
                                            local r391_4 = nil
                                            pcall(function()
                                                r391_4 = p391_0:GetChildAt(r391_3)
                                            end)
                                            if r391_4 then
                                                local r391_5 = r390_3(r391_4, p391_1 + 1)
                                                if r391_5 then
                                                    return r391_5
                                                end
                                            end
                                        end
                                        return nil
                                    end
                                    return nil
                                end
                                r390_7 = r390_3(r371_0, 0)
                            end
                        else
                            r390_3 = function(p391_0, p391_1)
                                if p391_0 and slua.isValid(p391_0) and not (p391_1 > 8) then
                                    local r391_0 = p391_0.Image_Icon
                                    if r391_0 and slua.isValid(r391_0) then
                                        return r391_0
                                    end
                                    local r391_1 = 0
                                    pcall(function()
                                        if p391_0.GetChildrenCount then
                                            r391_1 = p391_0:GetChildrenCount()
                                        end
                                    end)
                                    local r391_2 = math.max
                                    for r391_3 = 0, r391_2(r391_1 - 1, 0) do
                                        local r391_4 = nil
                                        pcall(function()
                                            r391_4 = p391_0:GetChildAt(r391_3)
                                        end)
                                        if r391_4 then
                                            local r391_5 = r390_3(r391_4, p391_1 + 1)
                                            if r391_5 then
                                                return r391_5
                                            end
                                        end
                                    end
                                    return nil
                                end
                                return nil
                            end
                            r390_7 = r390_3(r371_0, 0)
                        end
                        if r390_7 and slua.isValid(r390_7) and r390_7 ~= r373_1 then
                            pcall(function()
                                local r394_0 = r390_7.Brush
                                if r394_0 then
                                    local r394_1 = nil
                                    pcall(function()
                                        r394_1 = r394_0.ResourceObject
                                    end)
                                    if r394_1 and slua.isValid(r394_1) then
                                        if r373_1.SetBrushFromAsset then
                                            r373_1:SetBrushFromAsset(r394_1)
                                            r373_17 = true
                                        end
                                        if not r373_17 and r373_1.SetBrushFromTexture then
                                            r373_1:SetBrushFromTexture(r394_1)
                                            r373_17 = true
                                        end
                                    end
                                end
                            end)
                            if not r373_17 then
                                pcall(function()
                                    local r396_0 = r390_7.Brush
                                    if r396_0 then
                                        local r396_1 = nil
                                        pcall(function()
                                            r396_1 = r396_0.ResourceObject
                                        end)
                                        if r396_1 and slua.isValid(r396_1) and r373_1.SetBrushFromTexture then
                                            r373_1:SetBrushFromTexture(r396_1, false)
                                            r0_72.FixWeaponIconBrushSize(r373_1)
                                            r373_17 = true
                                        end
                                    end
                                end)
                            end
                        end
                    end)
                end
                local r373_22 = r373_17
                if not r373_17 then
                    local r373_23 = nil
                    if r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas) then
                        local r373_24 = 0
                        pcall(function()
                            r373_24 = r0_72.ESPCanvas:GetChildrenCount()
                        end)
                        local r373_25 = math.max
                        for r373_26 = 0, r373_25(r373_24 - 1, 0) do
                            local r373_27 = nil
                            pcall(function()
                                r373_27 = r0_72.ESPCanvas:GetChildAt(r373_26)
                            end)
                            if r373_27 and slua.isValid(r373_27) then
                                local r373_28 = tostring(r373_27)
                                if string.find(r373_28, "OB_PlayerHeadHPItem") and not r0_72.IsOurESPWidget(r373_27) then
                                    local r373_29 = r373_27.WeaponIcon
                                    if r373_29 and slua.isValid(r373_29) then
                                        r373_23 = r373_29
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if r373_23 and slua.isValid(r373_23) then
                        local r373_30, r373_31 = r0_72.CopyWeaponIconBrushFromNative(r373_1, r373_23)
                        if r373_30 then
                            r373_22 = true
                        end
                    end
                end
                if not r373_22 then
                    pcall(function()
                        local r400_0 = r373_1.Brush
                        if r400_0 then
                            local r400_1 = nil
                            pcall(function()
                                r400_1 = r400_0.ResourceObject
                            end)
                            if r400_1 and slua.isValid(r400_1) and r373_1.SetBrushFromTexture then
                                r373_1:SetBrushFromTexture(r400_1)
                                r373_22 = true
                            end
                        end
                    end)
                end
                if not r373_22 then
                    pcall(function()
                        local r402_0 = r373_1.Brush
                        if r402_0 then
                            local r402_1 = nil
                            pcall(function()
                                r402_1 = r402_0.ImageSize
                            end)
                            local r402_2 = false
                            if r402_1 then
                                local r402_3, r402_4 = nil, nil
                                pcall(function()
                                    r402_3 = r402_1.X
                                end)
                                pcall(function()
                                    r402_4 = r402_1.Y
                                end)
                                if not (r402_3 and r402_3 ~= 0) and not (r402_4 and r402_4 ~= 0) then
                                    r402_2 = true
                                end
                            end
                            if r402_2 then
                                pcall(function()
                                    local r406_0
                                    if r0_79 then
                                        local r406_1 = r0_72.WeaponIconBrushW or 138
                                        local r406_2 = r0_79(r406_1, r0_72.WeaponIconBrushH or 69)
                                        if not r406_2 then
                                            r406_2 = { X = 138, Y = 69 }
                                        end
                                    else
                                        local r406_3 = { X = 138, Y = 69 }
                                    end
                                    r402_0.ImageSize = r406_0
                                end)
                            end
                            pcall(function()
                                r402_0.DrawAs = 3
                            end)
                            if r373_1.SetBrush then
                                r373_1:SetBrush(r402_0)
                            end
                        end
                    end)
                end
                pcall(function()
                    r373_1:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                end)
                r0_72.ApplyWeaponIconFullOpacity(r371_0, r373_1)
                r0_72.FixWeaponIconBrushSize(r373_1)
                pcall(function()
                    -- line 3153-3176
                    -- proto#410 params=2 locals=4 upvalues=1 vararg=false
                    local function r409_0(p410_0, p410_1)
                        if p410_0 and slua.isValid(p410_0) then
                            if p410_0.GetChildrenCount and p410_0.GetChildAt then
                                local r410_0 = p410_0:GetChildrenCount()
                                local r410_1 = math.max
                                for r410_2 = 0, r410_1(r410_0 - 1, 0) do
                                    local r410_3 = p410_0:GetChildAt(r410_2)
                                    if r410_3 and slua.isValid(r410_3) then
                                        if r410_3 == p410_1 then
                                            return r410_2
                                        end

                                        -- line 3161-3171
                                        -- proto#411 params=3 locals=3 upvalues=2 vararg=false
                                        local function r410_4(p411_0, p411_1, p411_2)
                                            if p411_2 > 5 then
                                                return false
                                            end
                                            if p411_0 == p411_1 then
                                                return true
                                            end
                                            if p411_0.GetChildrenCount and p411_0.GetChildAt then
                                                local r411_0 = p411_0:GetChildrenCount()
                                                local r411_1 = math.max
                                                for r411_2 = 0, r411_1(r411_0 - 1, 0) do
                                                    local r411_3 = p411_0:GetChildAt(r411_2)
                                                    if r411_3 and slua.isValid(r411_3) and r410_4(r411_3, p411_1, p411_2 + 1) then
                                                        return true
                                                    end
                                                end
                                                return false
                                            end
                                            return false
                                        end

                                        if r410_4(r410_3, p410_1, 0) then
                                            return r410_2
                                        end
                                    end
                                end
                                return nil
                            end
                            return nil
                        end
                        return nil
                    end

                    for r409_1, r409_2 in ipairs({
                        "Switcher_WeaponIcon",
                        "WidgetSwitcher_Type",
                        "WidgetSwitcher_Type2"
                    }) do
                        local r409_3 = r371_0[r409_2]
                        if r409_3 and slua.isValid(r409_3) and r409_3.GetChildrenCount and r409_3.GetChildAt then
                            local r409_4 = r409_0(r409_3, r373_1)
                            if r409_4 and r409_3.SetActiveWidgetIndex then
                                r409_3:SetActiveWidgetIndex(r409_4)
                                local r409_5 = p371_0._CachedSwitcherIndexes
                                p371_0._CachedSwitcherIndexes = r409_5 or {}
                                p371_0._CachedSwitcherIndexes[r409_2] = r409_4
                            end
                        end
                    end
                end)
                pcall(function()
                    local r412_0, r412_1, r412_2, r412_3, r412_4, r412_5, r412_6, r412_7, r412_8, r412_9, r412_10, r412_11, r412_12, r412_13, r412_14
                    local r412_15, r412_16 = nil --[[ [unluac error] HIR proto#412 still contains residual unresolved expr during AST lowering ]]
                    if not nil --[[ [unluac error] HIR proto#412 still contains residual unresolved expr during AST lowering ]] then
                        goto L22
                    end
                    ::L1::
                    if not r412_13 then
                        goto L22
                    end
                    if not slua.isValid(r412_13) then
                        goto L22
                    end
                    if not r412_13.GetParent then
                        goto L22
                    end
                    r412_0 = r412_13:GetParent()
                    if not r412_0 then
                        goto L22
                    end
                    if not slua.isValid(r412_0) then
                        goto L22
                    end
                    r412_1 = tostring(r412_0)
                    if not string.find(r412_1, "WidgetSwitcher") then
                        goto L20
                    end
                    if not r412_0.GetChildrenCount then
                        goto L20
                    end
                    if not r412_0.GetChildAt then
                        goto L20
                    end
                    r412_2 = r412_0:GetChildrenCount()
                    r412_3 = math.max(r412_2 - 1, 0)
                    r412_4, r412_5 = nil --[[ [unluac error] HIR proto#412 still contains residual unresolved expr during AST lowering ]]
                    if not nil --[[ [unluac error] HIR proto#412 still contains residual unresolved expr during AST lowering ]] then
                        goto L20
                    end
                    ::L10::
                    r412_6 = r412_0:GetChildAt(r412_17)
                    if not r412_6 then
                        goto L19
                    end
                    if not slua.isValid(r412_6) then
                        goto L19
                    end
                    r412_7 = function(p413_0, p413_1, p413_2)
                        if p413_2 > 5 then
                            return false
                        end
                        if p413_0 == p413_1 then
                            return true
                        end
                        if p413_0.GetChildrenCount and p413_0.GetChildAt then
                            local r413_0 = p413_0:GetChildrenCount()
                            local r413_1 = math.max
                            for r413_2 = 0, r413_1(r413_0 - 1, 0) do
                                local r413_3 = p413_0:GetChildAt(r413_2)
                                if r413_3 and slua.isValid(r413_3) and r412_7(r413_3, p413_1, p413_2 + 1) then
                                    return true
                                end
                            end
                            return false
                        end
                        return false
                    end
                    if not r412_7(r412_6, r373_1, 0) then
                        -- [unluac error] HIR proto#412 still contains explicit close semantics that AST lowering cannot absorb yet
                        goto L19
                    end
                    if not r412_0.SetActiveWidgetIndex then
                        -- [unluac error] HIR proto#412 still contains explicit close semantics that AST lowering cannot absorb yet
                        goto L20
                    end
                    r412_0:SetActiveWidgetIndex(r412_17)
                    r412_8 = p371_0._CachedParentSwitchers
                    if r412_8 then
                        r412_14 = r412_8
                        goto L18
                    end
                    r412_14 = {}
                    ::L18::
                    p371_0._CachedParentSwitchers = r412_14
                    p371_0._CachedParentSwitchers[tostring(r412_0)] = { w = r412_0, idx = r412_17 }
                    -- [unluac error] HIR proto#412 still contains explicit close semantics that AST lowering cannot absorb yet
                    goto L20
                    ::L19::
                    r412_9, r412_10 = nil --[[ [unluac error] HIR proto#412 still contains residual unresolved expr during AST lowering ]]
                    if nil --[[ [unluac error] HIR proto#412 still contains residual unresolved expr during AST lowering ]] then
                        goto L10
                    end
                    ::L20::
                    r412_11, r412_12 = nil --[[ [unluac error] HIR proto#412 still contains residual unresolved expr during AST lowering ]]
                    if nil --[[ [unluac error] HIR proto#412 still contains residual unresolved expr during AST lowering ]] then
                        goto L1
                    end
                    ::L22::
                end)
                pcall(function()
                    local r414_0 = r373_1
                    for r414_1 = 0, 8 do
                        pcall(function()
                            if r414_0.GetParent then
                                local r415_0 = r414_0:GetParent()
                                if r415_0 and slua.isValid(r415_0) then
                                    if r415_0.SetWidgetVisibility then
                                        r415_0:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                    end
                                    pcall(function()
                                        if r415_0.SetRenderOpacity then
                                            r415_0:SetRenderOpacity(1.0)
                                        end
                                    end)
                                    pcall(function()
                                        if r415_0.SetContentColorAndOpacity then
                                            local r417_0 = r415_0
                                            local r417_1 = r0_80 and (r0_80(1.0, 1.0, 1.0, 1.0) or {
                                                R = 1,
                                                G = 1,
                                                B = 1,
                                                A = 1
                                            }) or { R = 1, G = 1, B = 1, A = 1 }
                                            r417_0:SetContentColorAndOpacity(r417_1)
                                        end
                                    end)
                                    pcall(function()
                                        if r415_0.SetColorAndOpacity then
                                            local r418_0 = r415_0
                                            local r418_1 = r0_80 and (r0_80(1.0, 1.0, 1.0, 1.0) or {
                                                R = 1,
                                                G = 1,
                                                B = 1,
                                                A = 1
                                            }) or { R = 1, G = 1, B = 1, A = 1 }
                                            r418_0:SetColorAndOpacity(r418_1)
                                        end
                                    end)
                                    pcall(function()
                                        if r415_0.SetBrushTintColor then
                                            local r419_0 = r415_0
                                            local r419_1 = r0_80 and (r0_80(1.0, 1.0, 1.0, 1.0) or {
                                                R = 1,
                                                G = 1,
                                                B = 1,
                                                A = 1
                                            }) or { R = 1, G = 1, B = 1, A = 1 }
                                            r419_0:SetBrushTintColor(r419_1)
                                        end
                                    end)
                                    pcall(function()
                                        local r420_0 = r415_0.Brush
                                        if r420_0 and r420_0.TintColor then
                                            local r420_1 = r0_80 and (r0_80(1.0, 1.0, 1.0, 1.0) or {
                                                R = 1,
                                                G = 1,
                                                B = 1,
                                                A = 1
                                            }) or { R = 1, G = 1, B = 1, A = 1 }
                                            r420_0.TintColor = r420_1
                                            if r415_0.SetBrush then
                                                r415_0:SetBrush(r420_0)
                                            end
                                        end
                                    end)
                                    pcall(function()
                                        if r415_0.InvalidateLayout then
                                            r415_0:InvalidateLayout()
                                        end
                                    end)
                                    r414_0 = r415_0
                                end
                            end
                        end)
                    end
                end)
                pcall(function()
                    if r373_1.InvalidateLayout then
                        r373_1:InvalidateLayout()
                    end
                end)
                pcall(function()
                    if r371_0.UpdateWeapon then
                        r371_0:UpdateWeapon()
                    end
                end)
                pcall(function()
                    if r371_0.RefreshWeapon then
                        r371_0:RefreshWeapon()
                    end
                end)
                p371_0._LastWeaponID = r373_3.WeaponID
                p371_0._WeaponIconApplied = true
                return
            end
            pcall(function()
                r373_1:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end)
            local r373_32 = {
                "Border_WeaponColor",
                "Border_Weapon",
                "Border_WeaponIcon",
                "SizeBox_Weapon",
                "ScaleBox_Weapon",
                "Switcher_WeaponIcon"
            }
            for r373_33, r373_34 in ipairs(r373_32) do
                pcall(function()
                    local r375_0 = r371_0
                    if r371_0 then
                        r375_0 = r371_0[r373_34]
                    end
                    if r375_0 and slua.isValid(r375_0) and r375_0.SetWidgetVisibility then
                        r375_0:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    end
                end)
            end
            p371_0._LastWeaponID = 0
            p371_0._WeaponIconApplied = false
        end)
        return
    end
    pcall(function()
        local r372_0 = {
            "Border_WeaponColor",
            "Border_Weapon",
            "Border_WeaponIcon",
            "SizeBox_Weapon",
            "ScaleBox_Weapon",
            "Switcher_WeaponIcon"
        }
        for r372_1, r372_2 in ipairs(r372_0) do
            local r372_3 = r371_0[r372_2]
            if r372_3 and slua.isValid(r372_3) and r372_3.SetWidgetVisibility then
                r372_3:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
        end
        local r372_4 = r371_0.WeaponIcon
        if not r372_4 then
            r372_4 = r0_72.FindWeaponIconInWidget(r371_0, 0, 8)
        end
        if r372_4 and slua.isValid(r372_4) then
            r372_4:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
    end)
    p371_0._LastWeaponID = 0
    p371_0._WeaponIconApplied = false
end

r0_72._OBHeadWidgetClass = nil
r0_72._OBHeadWidgetLoadFailed = false
r0_72._bDumpedWidgetChildren = false

-- line 3280-3390
-- proto#425 params=0 locals=4 upvalues=5 vararg=false
function r0_72.CreateESPWidget()
    if r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas) then
        if r0_72._OBHeadWidgetLoadFailed then
            return nil
        end
        if r0_72._OBHeadWidgetClass then
            local r425_0 = false
            pcall(function()
                r425_0 = slua.isValid(r0_72._OBHeadWidgetClass)
            end)
            if not r425_0 then
                r0_72._OBHeadWidgetLoadFailed = true
                r0_72._OBHeadWidgetClass = nil
                return nil
            end
        else
            pcall(function()
                local r426_0 = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP"
                local r426_1 = slua.loadClass(r426_0)
                if r426_1 then
                    r0_72._OBHeadWidgetClass = r426_1
                end
            end)
            if not r0_72._OBHeadWidgetClass then
                r0_72._OBHeadWidgetLoadFailed = true
                return nil
            end
        end
        local r425_1 = nil
        pcall(function()
            local r428_0 = import("STExtraBlueprintFunctionLibrary")
            local r428_1 = r0_72.GetMyPlayerController()
            local r428_2
            if r0_89(r428_1) then
                local r428_3 = r428_1.Object
                if r428_3 then
                    r428_2 = r428_3
                else
                    r428_2 = r0_72.ESPCanvas
                end
            else
                r428_2 = r0_72.ESPCanvas
            end
            r425_1 = r428_0.CreateWidgetByClass(r0_72._OBHeadWidgetClass, r428_2)
        end)
        if r425_1 then
            pcall(function()
                r425_1:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            pcall(function()
                r425_1:SetRenderOpacity(1.0)
            end)
            local r425_2, r425_3 = nil, nil
            local r425_4 = false
            pcall(function()
                r425_2 = r425_1.TextBlock_TeamName
                if r425_2 and slua.isValid(r425_2) then
                    pcall(function()
                        r425_2:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                end
                if r425_1.TextBlock_PlayerName and slua.isValid(r425_1.TextBlock_PlayerName) then
                    pcall(function()
                        r425_1.TextBlock_PlayerName:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                end
                local r431_0, r431_1 = r425_1.WidgetSwitcher_Type, r425_1.WidgetSwitcher_Type2
                if r431_0 and slua.isValid(r431_0) then
                    pcall(function()
                        if r431_0.SetActiveWidgetIndex then
                            r431_0:SetActiveWidgetIndex(r0_72.HPWidgetSwitcherTypeIndex)
                        end
                    end)
                end
                if r431_1 and slua.isValid(r431_1) then
                    pcall(function()
                        if r431_1.SetActiveWidgetIndex then
                            r431_1:SetActiveWidgetIndex(r0_72.HPWidgetSwitcherType2Index)
                        end
                    end)
                end
                local r431_2 = r425_1.SizeBox_HP
                if r431_2 and slua.isValid(r431_2) then
                    pcall(function()
                        r431_2:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                    pcall(function()
                        r431_2:SetHeightOverride(6)
                    end)
                    pcall(function()
                        r431_2:SetWidthOverride(100)
                    end)
                    local r431_3 = nil
                    pcall(function()
                        if r431_2.GetContent then
                            r431_3 = r431_2:GetContent()
                        end
                    end)
                    if not r431_3 then
                        pcall(function()
                            if r431_2.GetChildAt then
                                r431_3 = r431_2:GetChildAt(0)
                            end
                        end)
                    end
                    if r431_3 and slua.isValid(r431_3) then
                        pcall(function()
                            r431_3:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        end)
                        pcall(function()
                            r431_3:SetRenderOpacity(1.0)
                        end)
                        local r431_4 = r0_72.FindProgressBarInWidget(r431_3, 0, 5)
                        if r431_4 and slua.isValid(r431_4) then
                            r425_3 = r431_4
                            r425_4 = true
                            pcall(function()
                                r431_4:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            end)
                            pcall(function()
                                r431_4:SetRenderOpacity(1.0)
                            end)
                        else
                            local r431_5 = CGame:NewObjectFromPath("/Script/UMG.ProgressBar", r431_3)
                            if r431_5 then
                                pcall(function()
                                    local r445_0 = r431_5
                                    local r445_1 = r0_80 and (r0_80(0, 1, 0, 1) or {
                                        R = 0,
                                        G = 1,
                                        B = 0,
                                        A = 1
                                    }) or { R = 0, G = 1, B = 0, A = 1 }
                                    r445_0:SetFillColorAndOpacity(r445_1)
                                end)
                                pcall(function()
                                    r431_5:SetPercent(1.0)
                                end)
                                pcall(function()
                                    r431_5:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                end)
                                pcall(function()
                                    r431_5:SetRenderOpacity(1.0)
                                end)
                                pcall(function()
                                    local r449_0 = r431_5
                                    local r449_1 = r0_79 and (r0_79(100, 6) or { X = 100, Y = 6 }) or {
                                        X = 100,
                                        Y = 6
                                    }
                                    r449_0:SetDesiredSizeOverride(r449_1)
                                end)
                                pcall(function()
                                    r431_3:AddChild(r431_5)
                                end)
                                r425_3 = r431_5
                            end
                        end
                    else
                        local r431_6 = CGame:NewObjectFromPath("/Script/UMG.ProgressBar", r431_2)
                        if r431_6 then
                            pcall(function()
                                local r451_0 = r431_6
                                local r451_1 = r0_80 and (r0_80(0, 1, 0, 1) or {
                                    R = 0,
                                    G = 1,
                                    B = 0,
                                    A = 1
                                }) or { R = 0, G = 1, B = 0, A = 1 }
                                r451_0:SetFillColorAndOpacity(r451_1)
                            end)
                            pcall(function()
                                r431_6:SetPercent(1.0)
                            end)
                            pcall(function()
                                r431_6:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            end)
                            pcall(function()
                                r431_6:SetRenderOpacity(1.0)
                            end)
                            pcall(function()
                                local r455_0 = r431_6
                                local r455_1 = r0_79 and (r0_79(100, 6) or { X = 100, Y = 6 }) or {
                                    X = 100,
                                    Y = 6
                                }
                                r455_0:SetDesiredSizeOverride(r455_1)
                            end)
                            local r431_7 = false
                            pcall(function()
                                if r431_2.SetContent then
                                    r431_2:SetContent(r431_6)
                                    r431_7 = true
                                end
                            end)
                            if not r431_7 then
                                pcall(function()
                                    r431_2:AddChild(r431_6)
                                end)
                            end
                            r425_3 = r431_6
                        end
                    end
                end
            end)
            return {
                Container = r425_1,
                NameText = r425_2,
                HealthFill = r425_3,
                IsGameWidget = true,
                IsOriginalProgressBar = r425_4,
                HasChildren = r425_2 ~= nil
            }
        end
        return nil
    end
    return nil
end

r0_72._CanvasScaleX = 1.0
r0_72._CanvasScaleY = 1.0
r0_72._CanvasOffsetX = 0.0
r0_72._CanvasOffsetY = 0.0

-- line 3397-3447
-- proto#458 params=1 locals=7 upvalues=5 vararg=false
function r0_72.UpdateCanvasTransform(p458_0)
    if not (r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas)) then
        return
    end
    local r458_0 = false
    pcall(function()
        local r459_0 = r0_75
        if r459_0 and r459_0.AbsoluteToLocal then
            local r459_1 = r0_72.ESPCanvas:GetCachedGeometry()
            if r459_1 then
                local r459_2 = r459_0.AbsoluteToLocal
                local r459_3 = r459_1
                local r459_4 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
                local r459_5 = r459_2(r459_3, r459_4)
                local r459_6 = r0_79 and (r0_79(100, 100) or { X = 100, Y = 100 }) or {
                    X = 100,
                    Y = 100
                }
                local r459_7 = r459_0.AbsoluteToLocal(r459_1, r459_6)
                if r459_5 and r459_7 then
                    r0_72._CanvasScaleX = (r459_7.X - r459_5.X) / 100
                    r0_72._CanvasScaleY = (r459_7.Y - r459_5.Y) / 100
                    r0_72._CanvasOffsetX = r459_5.X
                    r0_72._CanvasOffsetY = r459_5.Y
                    r458_0 = true
                end
            end
        end
    end)
    if not r458_0 then
        pcall(function()
            local r460_0 = r0_76
            if r460_0 and r460_0.ScreenToWidgetLocal then
                local r460_1 = r0_72.ESPCanvas:GetCachedGeometry()
                if r460_1 then
                    local r460_2 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
                    local r460_3 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
                    local r460_4 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
                    r460_0.ScreenToWidgetLocal(p458_0, r460_1, r460_4, r460_2)
                    local r460_5 = r0_79 and (r0_79(100, 100) or { X = 100, Y = 100 }) or {
                        X = 100,
                        Y = 100
                    }
                    r460_0.ScreenToWidgetLocal(p458_0, r460_1, r460_5, r460_3)
                    r0_72._CanvasScaleX = (r460_3.X - r460_2.X) / 100
                    r0_72._CanvasScaleY = (r460_3.Y - r460_2.Y) / 100
                    r0_72._CanvasOffsetX = r460_2.X
                    r0_72._CanvasOffsetY = r460_2.Y
                    r458_0 = true
                end
            end
        end)
    end
    if not r458_0 then
        local r458_1, r458_2 = 1.0, r0_76
        local r458_3
        if r458_2 then
            local r458_4 = r458_2.GetViewportScale
            if r458_4 then
                local r458_5 = r458_2.GetViewportScale(p458_0)
                if r458_5 then
                    r458_3 = r458_5
                else
                    r458_3 = 1.0
                end
            else
                r458_3 = r458_4
            end
        else
            r458_3 = r458_1
        end
        r0_72._CanvasScaleX = 1.0 / r458_3
        r0_72._CanvasScaleY = 1.0 / r458_3
        r0_72._CanvasOffsetX = 0
        r0_72._CanvasOffsetY = 0
    end
end

-- line 3449-3456
-- proto#461 params=2 locals=12 upvalues=2 vararg=false
function r0_72.ScreenPixelToCanvasLocal(p461_0, p461_1)
    if p461_1 then
        local r461_0 = r0_72._CanvasScaleX
        if not r461_0 then
            r461_0 = 1.0
        end
        local r461_1 = r0_72._CanvasScaleY
        if not r461_1 then
            r461_1 = 1.0
        end
        local r461_2 = r0_72._CanvasOffsetX
        if not r461_2 then
            r461_2 = 0
        end
        local r461_3 = r0_72._CanvasOffsetY
        if not r461_3 then
            r461_3 = 0
        end
        local r461_4
        if r0_79 then
            local r461_5 = p461_1.X * r461_0 + r461_2
            local r461_6 = r0_79(r461_5, p461_1.Y * r461_1 + r461_3)
            if r461_6 then
                r461_4 = r461_6
            else
                r461_4 = { X = p461_1.X * r461_0 + r461_2, Y = p461_1.Y * r461_1 + r461_3 }
            end
        else
            r461_4 = { X = p461_1.X * r461_0 + r461_2, Y = p461_1.Y * r461_1 + r461_3 }
        end
        return r461_4
    end
    local r461_7 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
    return r461_7
end

-- line 3458-3469
-- proto#462 params=2 locals=10 upvalues=4 vararg=false
function r0_72.ProjectWorldToCanvasLocal(p462_0, p462_1)
    if r0_89(p462_0) and p462_1 then
        local r462_0 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
        local r462_1 = false
        pcall(function()
            local r463_0 = p462_0:ProjectWorldLocationToScreen(p462_1, r462_0, true)
            if r463_0 == true or r463_0 == 1 or r462_0 and (r462_0.X ~= 0 or r462_0.Y ~= 0) then
                r462_1 = true
            end
        end)
        if not r462_1 or not r462_0 or r462_0.X == 0 and r462_0.Y == 0 then
            local r462_2 = false
            local r462_3 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
            return r462_2, r462_3
        end
        local r462_4 = r0_72.ScreenPixelToCanvasLocal(p462_0, r462_0)
        return true, r462_4
    end
    local r462_5 = false
    local r462_6 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
    return r462_5, r462_6
end

-- line 3471-3501
-- proto#464 params=1 locals=5 upvalues=3 vararg=false
function r0_72.GetDynamicViewportSize(p464_0)
    local r464_0, r464_1 = 0, 0
    if r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas) then
        pcall(function()
            local r465_0 = r0_72.ESPCanvas:GetCachedGeometry()
            if r465_0 and r465_0.GetLocalSize then
                local r465_1 = r465_0:GetLocalSize()
                if r465_1 and r465_1.X and r465_1.X > 200 then
                    r464_0 = r465_1.X
                    r464_1 = r465_1.Y
                end
            end
        end)
    end
    if r464_0 > 200 then
        return r464_0, r464_1
    end
    pcall(function()
        local r466_0 = r0_76
        if r466_0 and r466_0.GetViewportSize then
            local r466_1 = r466_0.GetViewportSize(p464_0 or r0_72.GetMyPlayerController())
            if r466_1 and r466_1.X and r466_1.X > 200 then
                r464_0 = r466_1.X
                r464_1 = r466_1.Y
            end
        end
    end)
    if r464_0 > 200 then
        pcall(function()
            local r467_0 = r0_76
            if r467_0 and r467_0.GetViewportScale then
                local r467_1 = r467_0.GetViewportScale(p464_0 or r0_72.GetMyPlayerController())
                if r467_1 and type(r467_1) == "number" and r467_1 > 0 and r467_1 ~= 1.0 then
                    r464_0 = r464_0 / r467_1
                    r464_1 = r464_1 / r467_1
                end
            end
        end)
        return r464_0, r464_1
    end
    local r464_2 = r0_72._cachedViewportW or 1920
    local r464_3 = r0_72._cachedViewportH
    return r464_2, r464_3 or 1080
end

-- line 3503-3573
-- proto#468 params=4 locals=2 upvalues=4 vararg=false
function r0_72.UpdateESPPositionWithPC(p468_0, p468_1, p468_2, p468_3)
    if p468_0 and r0_89(p468_2) then
        local r468_0 = p468_0.Container
        if not r468_0 then
            r468_0 = p468_0
        end
        local r468_1, r468_2 = p468_3, true
        if not p468_3 then
            if not p468_1 then
                return false
            end
            local r468_3, r468_4 = r0_72.ProjectWorldToCanvasLocal(p468_2, p468_1)
            r468_1 = r468_4
            r468_2 = r468_3
        end
        if r468_2 then
            pcall(function()
                if r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas) then
                    local r470_0 = tostring(r468_0)
                    local r470_1 = r0_72.ESPWidgetPtrs[r470_0]
                    if not r470_1 or not slua.isValid(r470_1) or type(r470_1) == "boolean" then
                        local r470_2 = r0_72.ESPCanvas:AddChildToCanvas(r468_0)
                        if r470_2 and slua.isValid(r470_2) then
                            r470_1 = r470_2
                            r0_72.ESPWidgetPtrs[r470_0] = r470_2
                            if type(p468_0) == "table" then
                                p468_0.Slot = r470_2
                            end
                            pcall(function()
                                r470_1:SetAutoSize(true)
                            end)
                            pcall(function()
                                r470_1.bAutoSize = true
                            end)
                            local r470_3 = r0_79 and (r0_79(0.5, 1.0) or { X = 0.5, Y = 1.0 }) or {
                                X = 0.5,
                                Y = 1.0
                            }
                            pcall(function()
                                r470_1.Alignment = r470_3
                            end)
                            pcall(function()
                                r470_1:SetAlignment(r470_3)
                            end)
                            pcall(function()
                                r470_1:SetAlignment(0.5, 1.0)
                            end)
                            pcall(function()
                                r470_1:SetZOrder(r0_72.ESPWidgetZOrder or 20)
                            end)
                        end
                    end
                    local r470_4 = _G.LexusConfig.Esp9_Name or _G.LexusConfig.Esp9_Distance or _G.LexusConfig.Esp9_HP or _G.LexusConfig.Esp9_Team or _G.LexusConfig.Esp9_Weapon
                    if r470_4 then
                        r468_0:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    else
                        r468_0:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    end
                    if not p468_0._OffsetResetDone then
                        pcall(function()
                            local r477_0 = r468_0
                            local r477_1 = r0_79 and (r0_79(0.0, 0.0) or { X = 0, Y = 0 }) or {
                                X = 0,
                                Y = 0
                            }
                            r477_0:SetRenderTranslation(r477_1)
                        end)
                        pcall(function()
                            local r478_0 = r468_0
                            local r478_1 = r0_79 and (r0_79(0.9, 0.9) or { X = 0.9, Y = 0.9 }) or {
                                X = 0.9,
                                Y = 0.9
                            }
                            r478_0:SetRenderScale(r478_1)
                        end)
                        if p468_0 and type(p468_0) == "table" then
                            if p468_0.NameText and slua.isValid(p468_0.NameText) then
                                pcall(function()
                                    local r479_0 = p468_0.NameText
                                    local r479_1 = r0_79 and (r0_79(0.0, 0.0) or { X = 0, Y = 0 }) or {
                                        X = 0,
                                        Y = 0
                                    }
                                    r479_0:SetRenderTranslation(r479_1)
                                end)
                            end
                            if p468_0.HealthFill and slua.isValid(p468_0.HealthFill) then
                                pcall(function()
                                    local r480_0 = p468_0.HealthFill
                                    local r480_1 = r0_79 and (r0_79(0.0, 0.0) or { X = 0, Y = 0 }) or {
                                        X = 0,
                                        Y = 0
                                    }
                                    r480_0:SetRenderTranslation(r480_1)
                                end)
                            end
                        end
                        pcall(function()
                            local r481_0 = r0_79 and (r0_79(0.5, 1.0) or { X = 0.5, Y = 1.0 }) or {
                                X = 0.5,
                                Y = 1.0
                            }
                            r468_0.RenderTransformPivot = r481_0
                        end)
                        pcall(function()
                            local r482_0 = r468_0
                            local r482_1 = r0_79 and (r0_79(0.5, 1.0) or { X = 0.5, Y = 1.0 }) or {
                                X = 0.5,
                                Y = 1.0
                            }
                            r482_0:SetRenderTransformPivot(r482_1)
                        end)
                        p468_0._OffsetResetDone = true
                    end
                    local r470_5
                    if r470_1 then
                        if slua.isValid(r470_1) then
                            local r470_6 = r0_72.ESPCanvas
                            if r470_1 == r470_6 then
                                if p468_0 then
                                    if type(p468_0) == "table" then
                                        if p468_0.Slot then
                                            if slua.isValid(p468_0.Slot) then
                                                r470_5 = p468_0.Slot
                                            else
                                                local r470_7 = r468_0.Slot
                                                if r470_7 then
                                                    local r470_8 = slua.isValid(r468_0.Slot)
                                                    if r470_8 then
                                                        r470_5 = r468_0.Slot
                                                    else
                                                        r470_5 = r470_8
                                                    end
                                                else
                                                    r470_5 = r470_7
                                                end
                                            end
                                        else
                                            local r470_9 = r468_0.Slot
                                            if r470_9 then
                                                local r470_10 = slua.isValid(r468_0.Slot)
                                                if r470_10 then
                                                    r470_5 = r468_0.Slot
                                                else
                                                    r470_5 = r470_10
                                                end
                                            else
                                                r470_5 = r470_9
                                            end
                                        end
                                    else
                                        local r470_11 = r468_0.Slot
                                        if r470_11 then
                                            local r470_12 = slua.isValid(r468_0.Slot)
                                            if r470_12 then
                                                r470_5 = r468_0.Slot
                                            else
                                                r470_5 = r470_12
                                            end
                                        else
                                            r470_5 = r470_11
                                        end
                                    end
                                else
                                    local r470_13 = r468_0.Slot
                                    if r470_13 then
                                        local r470_14 = slua.isValid(r468_0.Slot)
                                        if r470_14 then
                                            r470_5 = r468_0.Slot
                                        else
                                            r470_5 = r470_14
                                        end
                                    else
                                        r470_5 = r470_13
                                    end
                                end
                            else
                                r470_5 = r470_1
                            end
                        elseif p468_0 then
                            if type(p468_0) == "table" then
                                if p468_0.Slot then
                                    if slua.isValid(p468_0.Slot) then
                                        r470_5 = p468_0.Slot
                                    else
                                        local r470_15 = r468_0.Slot
                                        if r470_15 then
                                            local r470_16 = slua.isValid(r468_0.Slot)
                                            if r470_16 then
                                                r470_5 = r468_0.Slot
                                            else
                                                r470_5 = r470_16
                                            end
                                        else
                                            r470_5 = r470_15
                                        end
                                    end
                                else
                                    local r470_17 = r468_0.Slot
                                    if r470_17 then
                                        local r470_18 = slua.isValid(r468_0.Slot)
                                        if r470_18 then
                                            r470_5 = r468_0.Slot
                                        else
                                            r470_5 = r470_18
                                        end
                                    else
                                        r470_5 = r470_17
                                    end
                                end
                            else
                                local r470_19 = r468_0.Slot
                                if r470_19 then
                                    local r470_20 = slua.isValid(r468_0.Slot)
                                    if r470_20 then
                                        r470_5 = r468_0.Slot
                                    else
                                        r470_5 = r470_20
                                    end
                                else
                                    r470_5 = r470_19
                                end
                            end
                        else
                            local r470_21 = r468_0.Slot
                            if r470_21 then
                                local r470_22 = slua.isValid(r468_0.Slot)
                                if r470_22 then
                                    r470_5 = r468_0.Slot
                                else
                                    r470_5 = r470_22
                                end
                            else
                                r470_5 = r470_21
                            end
                        end
                    elseif p468_0 then
                        if type(p468_0) == "table" then
                            if p468_0.Slot then
                                if slua.isValid(p468_0.Slot) then
                                    r470_5 = p468_0.Slot
                                else
                                    local r470_23 = r468_0.Slot
                                    if r470_23 then
                                        local r470_24 = slua.isValid(r468_0.Slot)
                                        if r470_24 then
                                            r470_5 = r468_0.Slot
                                        else
                                            r470_5 = r470_24
                                        end
                                    else
                                        r470_5 = r470_23
                                    end
                                end
                            else
                                local r470_25 = r468_0.Slot
                                if r470_25 then
                                    local r470_26 = slua.isValid(r468_0.Slot)
                                    if r470_26 then
                                        r470_5 = r468_0.Slot
                                    else
                                        r470_5 = r470_26
                                    end
                                else
                                    r470_5 = r470_25
                                end
                            end
                        else
                            local r470_27 = r468_0.Slot
                            if r470_27 then
                                local r470_28 = slua.isValid(r468_0.Slot)
                                if r470_28 then
                                    r470_5 = r468_0.Slot
                                else
                                    r470_5 = r470_28
                                end
                            else
                                r470_5 = r470_27
                            end
                        end
                    else
                        local r470_29 = r468_0.Slot
                        if r470_29 then
                            local r470_30 = slua.isValid(r468_0.Slot)
                            if r470_30 then
                                r470_5 = r468_0.Slot
                            else
                                r470_5 = r470_30
                            end
                        else
                            r470_5 = r470_29
                        end
                    end
                    if r470_5 and slua.isValid(r470_5) then
                        local r470_31 = r0_72.ESPCanvas
                        if r470_5 ~= r470_31 then
                            local r470_32 = r468_1.X
                            local r470_33 = r0_72.ESPAnchorOffsetX
                            local r470_34 = r470_32 + (r470_33 or 0)
                            local r470_35 = r468_1.Y + (r0_72.ESPAnchorOffsetY or 0)
                            if p468_0 and type(p468_0) == "table" then
                                if p468_0._CachedPosVec then
                                    p468_0._CachedPosVec.X = r470_34
                                    p468_0._CachedPosVec.Y = r470_35
                                else
                                    local r470_36 = r0_79 and (r0_79(r470_34, r470_35) or {
                                        X = r470_34,
                                        Y = r470_35
                                    }) or { X = r470_34, Y = r470_35 }
                                    p468_0._CachedPosVec = r470_36
                                end
                                pcall(function()
                                    r470_5:SetPosition(p468_0._CachedPosVec)
                                end)
                            else
                                pcall(function()
                                    local r484_0 = r470_5
                                    local r484_1 = r0_79 and (r0_79(r470_34, r470_35) or {
                                        X = r470_34,
                                        Y = r470_35
                                    }) or { X = r470_34, Y = r470_35 }
                                    r484_0:SetPosition(r484_1)
                                end)
                            end
                        end
                    end
                end
            end)
            return true
        end
        pcall(function()
            r468_0:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end)
        return false
    end
    return false
end

-- line 3575-3651
-- proto#485 params=2 locals=1 upvalues=4 vararg=false
function r0_72.UpdateESPText(p485_0, p485_1)
    if not p485_0 then
        return
    end
    if p485_0._LastESPText == p485_1 then
        return
    end
    p485_0._LastESPText = p485_1

    -- line 3580-3601
    -- proto#486 params=2 locals=0 upvalues=4 vararg=false
    local function r485_0(p486_0, p486_1)
        if not (p486_0 and slua.isValid(p486_0)) then
            return
        end
        if p486_1 == "" then
            pcall(function()
                p486_0:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end)
            return
        end
        pcall(function()
            p486_0:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        pcall(function()
            p486_0:SetText(p486_1)
        end)
        pcall(function()
            local r490_0 = import("SlateColor")
            if not r490_0 then
                r490_0 = import("/Script/SlateCore.SlateColor")
            end
            local r490_1 = r0_80 and (r0_80(1.0, 1.0, 1.0, 1.0) or {
                R = 255,
                G = 255,
                B = 255,
                A = 255
            }) or { R = 255, G = 255, B = 255, A = 255 }
            if p486_0.SetColorAndOpacity then
                if r490_0 then
                    p486_0:SetColorAndOpacity(r490_0(r490_1))
                else
                    p486_0:SetColorAndOpacity(r490_1)
                end
            end
        end)
        pcall(function()
            if p486_0.SetJustification then
                p486_0:SetJustification(1)
            end
        end)
        pcall(function()
            local r492_0 = p486_0.Slot
            if r492_0 and r492_0.SetHorizontalAlignment then
                r492_0:SetHorizontalAlignment(1)
            end
        end)
        pcall(function()
            local r493_0
            local r493_1 = p486_0
            if r0_79 and r0_79(r0_72.ESPTextOffsetX or 0, r0_72.ESPTextOffsetY or 0) then
                r493_1:SetRenderTranslation(r493_0)
                return
            end
            local r493_2 = { X = r0_72.ESPTextOffsetX or 0, Y = r0_72.ESPTextOffsetY or 0 }
            r493_1:SetRenderTranslation(r493_0)
        end)
    end

    if p485_0.NameText and slua.isValid(p485_0.NameText) then
        r485_0(p485_0.NameText, p485_1)
    end
    if p485_0.IsGameWidget and p485_0.Container then
        pcall(function()
            local r494_0 = p485_0.Container
            if r494_0 and slua.isValid(r494_0) then
                if r494_0.SetPlayerName then
                    local r494_1 = p485_1
                    local r494_2 = string.find(p485_1, " %[")
                    local r494_3
                    if r494_2 then
                        r494_3 = string.sub(p485_1, 1, r494_2 - 1)
                    else
                        r494_3 = r494_1
                    end
                    r494_0:SetPlayerName(r494_3)
                end
                r485_0(r494_0.TextBlock_TeamName, p485_1)
                r485_0(r494_0.TextBlock_PlayerName, p485_1)
                pcall(function()
                    if not p485_0._CachedVBChildren then
                        local r495_0 = {}
                        local r495_1 = r0_72._FindNamedWidgetInTree(r494_0, "VerticalBox_0", 8)
                        if r495_1 and slua.isValid(r495_1) and r495_1.GetChildrenCount then
                            local r495_2 = r495_1:GetChildrenCount()
                            for r495_3 = 0, r495_2 - 1 do
                                local r495_4 = r495_1:GetChildAt(r495_3)
                                if r495_4 and slua.isValid(r495_4) and r495_4.SetText then
                                    table.insert(r495_0, r495_4)
                                end
                            end
                        end
                        p485_0._CachedVBChildren = r495_0
                    end
                    for r495_5, r495_6 in ipairs(p485_0._CachedVBChildren) do
                        r485_0(r495_6, p485_1)
                    end
                end)
                pcall(function()
                    if not p485_0._CachedHBChildren then
                        local r496_0 = {}
                        local r496_1 = r0_72._FindNamedWidgetInTree(r494_0, "HorizontalBox_TeamName", 8)
                        if r496_1 and slua.isValid(r496_1) and r496_1.GetChildrenCount then
                            local r496_2 = r496_1:GetChildrenCount()
                            for r496_3 = 0, r496_2 - 1 do
                                local r496_4 = r496_1:GetChildAt(r496_3)
                                if r496_4 and slua.isValid(r496_4) and r496_4.SetText then
                                    table.insert(r496_0, r496_4)
                                end
                            end
                        end
                        p485_0._CachedHBChildren = r496_0
                    end
                    for r496_5, r496_6 in ipairs(p485_0._CachedHBChildren) do
                        r485_0(r496_6, p485_1)
                    end
                end)
            end
        end)
    end
end

-- line 3653-3723
-- proto#497 params=2 locals=5 upvalues=3 vararg=false
function r0_72.UpdateESPHealth(p497_0, p497_1)
    if not p497_0 then
        return
    end
    p497_0.LastPct = p497_1
    local r497_0 = _G.LexusConfig.Esp9_HP
    if r0_72.bForceSwitcherIndexEveryUpdate and p497_0.Container then
        pcall(function()
            local r498_0 = p497_0.Container
            if r498_0 and slua.isValid(r498_0) then
                if r498_0.WidgetSwitcher_Type and slua.isValid(r498_0.WidgetSwitcher_Type) then
                    pcall(function()
                        if r498_0.WidgetSwitcher_Type.SetActiveWidgetIndex then
                            r498_0.WidgetSwitcher_Type:SetActiveWidgetIndex(r0_72.HPWidgetSwitcherTypeIndex)
                        end
                    end)
                end
                if r498_0.WidgetSwitcher_Type2 and slua.isValid(r498_0.WidgetSwitcher_Type2) then
                    pcall(function()
                        if r498_0.WidgetSwitcher_Type2.SetActiveWidgetIndex then
                            r498_0.WidgetSwitcher_Type2:SetActiveWidgetIndex(r0_72.HPWidgetSwitcherType2Index)
                        end
                    end)
                end
                if r498_0.SizeBox_HP and slua.isValid(r498_0.SizeBox_HP) then
                    if r497_0 then
                        r498_0.SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    else
                        r498_0.SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    end
                end
            end
        end)
    end
    if not r497_0 then
        return
    end
    if not p497_0.HealthFill then
        return
    end
    local r497_1 = false
    pcall(function()
        r497_1 = slua.isValid(p497_0.HealthFill)
    end)
    if r497_1 then
        local r497_2 = false
        pcall(function()
            r497_2 = p497_0.HealthFill.SetPercent ~= nil
        end)
        if not r497_2 then
            local r497_3 = r0_72.FindProgressBarInWidget(p497_0.HealthFill, 0, 5)
            if not r497_3 then
                return
            end
            if not slua.isValid(r497_3) then
                return
            end
            p497_0.HealthFill = r497_3
        end
        pcall(function()
            if p497_0.HealthFill.SetWidgetVisibility then
                p497_0.HealthFill:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end
            if p497_0.HealthFill.SetRenderOpacity then
                p497_0.HealthFill:SetRenderOpacity(1.0)
            end
            if p497_0.HealthFill.SetPercent then
                p497_0.HealthFill:SetPercent(p497_1)
                local r503_0
                if p497_1 > 0.5 then
                    if r0_80 then
                        local r503_1 = r0_80(0.0, 1.0, 0.0, 1.0)
                        if r503_1 then
                            r503_0 = r503_1
                            r503_0 = r503_0
                        else
                            r503_0 = { R = 0, G = 255, B = 0, A = 255 }
                            r503_0 = r503_0
                        end
                    else
                        r503_0 = { R = 0, G = 255, B = 0, A = 255 }
                        r503_0 = r503_0
                    end
                elseif p497_1 > 0.25 then
                    if r0_80 then
                        local r503_2 = r0_80(1.0, 0.5, 0.0, 1.0)
                        if r503_2 then
                            r503_0 = r503_2
                            r503_0 = r503_0
                        else
                            r503_0 = { R = 255, G = 128, B = 0, A = 255 }
                            r503_0 = r503_0
                        end
                    else
                        r503_0 = { R = 255, G = 128, B = 0, A = 255 }
                        r503_0 = r503_0
                    end
                elseif r0_80 then
                    local r503_3 = r0_80(1.0, 0.0, 0.0, 1.0)
                    if r503_3 then
                        r503_0 = r503_3
                    else
                        r503_0 = { R = 255, G = 0, B = 0, A = 255 }
                    end
                else
                    r503_0 = { R = 255, G = 0, B = 0, A = 255 }
                end
                if p497_0.HealthFill.SetFillColorAndOpacity then
                    p497_0.HealthFill:SetFillColorAndOpacity(r503_0)
                end
                pcall(function()
                    if p497_0.IsOriginalProgressBar then
                        local r504_0 = p497_0.HealthFill.WidgetStyle
                        if r504_0 and r504_0.FillImage then
                            r504_0.FillImage.TintColor = r503_0
                            p497_0.HealthFill:SetWidgetStyle(r504_0)
                        end
                    end
                end)
            end
        end)
    end
end

-- line 3725-3740
-- proto#505 params=2 locals=2 upvalues=2 vararg=false
function r0_72.RemoveESPWidget(p505_0, p505_1)
    if not p505_0 then
        return
    end
    local r505_0 = p505_0.Container or p505_0
    pcall(function()
        r0_72.ESPWidgetPtrs[tostring(r505_0)] = nil
        r505_0:RemoveFromParent()
        r505_0:ConditionalBeginDestroy()
    end)
    if p505_1 then
        r0_72.RemoveSnapLine(p505_1)
        if r0_72.RemoveSkeletonLines then
            r0_72.RemoveSkeletonLines(p505_1)
        end
    end
end

-- line 3742-3760
-- proto#507 params=0 locals=8 upvalues=4 vararg=false
function r0_72.CreateSnapLine()
    if r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas) then
        local r507_0 = nil
        pcall(function()
            r507_0 = CGame:NewObjectFromPath("/Script/UMG.Border", r0_72.ESPCanvas)
        end)
        if r507_0 and slua.isValid(r507_0) then
            local r507_1 = r0_72.SnapLineColor
            if not r507_1 and r0_80 then
                r507_1 = r0_80(1.0, 1.0, 1.0, r0_72.SnapLineOpacity or 0.7)
                if not r507_1 then
                    r507_1 = { R = 1, G = 1, B = 1, A = r0_72.SnapLineOpacity or 0.7 }
                end
            end
            pcall(function()
                r507_0:SetBrushColor(r507_1)
            end)
            pcall(function()
                r507_0:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            pcall(function()
                local r511_0 = r0_79 and (r0_79(0.0, 0.5) or { X = 0, Y = 0.5 }) or {
                    X = 0,
                    Y = 0.5
                }
                r507_0.RenderTransformPivot = r511_0
            end)
            pcall(function()
                local r512_0 = r507_0
                local r512_1 = r0_79 and (r0_79(0.0, 0.5) or { X = 0, Y = 0.5 }) or {
                    X = 0,
                    Y = 0.5
                }
                r512_0:SetRenderTransformPivot(r512_1)
            end)
            local r507_2 = nil
            pcall(function()
                r507_2 = r0_72.ESPCanvas:AddChildToCanvas(r507_0)
                if r507_2 then
                    r507_2:SetAutoSize(false)
                    r507_2:SetZOrder(1)
                end
            end)
            return { Widget = r507_0, Slot = r507_2 }
        end
        return nil
    end
    return nil
end

-- line 3762-3803
-- proto#514 params=1 locals=13 upvalues=4 vararg=false
function r0_72.GetSnapLineStartPos(p514_0)
    local r514_0
    local r514_1, r514_2, r514_3 = 0, 0, 1.0
    pcall(function()
        if p514_0 and p514_0.GetViewportSize then
            local r515_0 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
            p514_0:GetViewportSize(r515_0)
            if r515_0 and r515_0.X and r515_0.X > 200 then
                r514_1 = r515_0.X
                r514_2 = r515_0.Y
            end
        end
    end)
    if r514_1 <= 200 then
        pcall(function()
            local r516_0 = r0_76
            if r516_0 and r516_0.GetViewportSize then
                local r516_1 = r516_0.GetViewportSize(p514_0)
                if r516_1 and r516_1.X and r516_1.X > 200 then
                    r514_1 = r516_1.X
                    r514_2 = r516_1.Y
                end
            end
        end)
    end
    pcall(function()
        local r517_0 = r0_76
        if r517_0 and r517_0.GetViewportScale then
            local r517_1 = r517_0.GetViewportScale(p514_0)
            if r517_1 and type(r517_1) == "number" and r517_1 > 0 then
                r514_3 = r517_1
            end
        end
    end)
    if r514_1 <= 200 then
        local r514_4 = r0_72._cachedViewportW
        r514_0 = (r514_4 or 1920) * r514_3
        local r514_5 = r0_72._cachedViewportH
        r514_2 = (r514_5 or 1080) * r514_3
    end
    if not r0_72._CachedTopCenterPixel then
        local r514_6 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
        r0_72._CachedTopCenterPixel = r514_6
    end
    r0_72._CachedTopCenterPixel.X = r514_0 / 2.0
    r0_72._CachedTopCenterPixel.Y = (r0_72.SnapLineOriginY or 50) * r514_3
    local r514_7 = r0_72.ScreenPixelToCanvasLocal(p514_0, r0_72._CachedTopCenterPixel)
    local r514_8 = r514_7.X
    local r514_9 = r0_72.SnapLineOriginOffsetX
    return r514_8 + (r514_9 or 0), r514_7.Y
end

-- line 3805-3862
-- proto#518 params=5 locals=25 upvalues=3 vararg=false
function r0_72.UpdateSnapLine(p518_0, p518_1, p518_2, p518_3, p518_4)
    if not r0_72.bUseSnapLines then
        return
    end
    if not (r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas)) then
        return
    end
    local r518_0 = r0_72.SnapLineWidgets[p518_0]
    if p518_2 and p518_1 then
        local r518_1 = false
        local r518_2
        if not r518_0 then
            r518_2 = r0_72.CreateSnapLine()
            if not r518_2 then
                return
            end
            if not r518_2.Widget then
                return
            end
            if not r518_2.Slot then
                return
            end
            r0_72.SnapLineWidgets[p518_0] = r518_2
            r518_1 = true
        end
        local r518_3 = r518_2.Widget
        local r518_4 = r518_2.Slot
        pcall(function()
            r518_3:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        if not r518_2._PivotSet then
            pcall(function()
                local r521_0 = r0_79 and (r0_79(0.0, 0.5) or { X = 0, Y = 0.5 }) or {
                    X = 0,
                    Y = 0.5
                }
                r518_3.RenderTransformPivot = r521_0
            end)
            pcall(function()
                local r522_0 = r518_3
                local r522_1 = r0_79 and (r0_79(0.0, 0.5) or { X = 0, Y = 0.5 }) or {
                    X = 0,
                    Y = 0.5
                }
                r522_0:SetRenderTransformPivot(r522_1)
            end)
            r518_2._PivotSet = true
        end
        local r518_5 = p518_1.X
        local r518_6 = r0_72.SnapLineHeadOffsetX
        local r518_7 = r518_5 + (r518_6 or 0)
        local r518_8 = p518_1.Y
        local r518_9 = r0_72.SnapLineHeadOffsetY
        local r518_10 = r518_8 + (r518_9 or 0)
        local r518_11 = r518_7 - p518_3
        local r518_12 = r518_10 - p518_4
        local r518_13 = math.sqrt(r518_11 * r518_11 + r518_12 * r518_12)
        local r518_14 = r0_72.SnapLineThickness
        if not r518_14 then
            r518_14 = 1.5
        end
        local r518_15
        if math.atan2 then
            r518_15 = math.atan2(r518_12, r518_11)
        else
            r518_15 = math.atan(r518_12, r518_11)
        end
        local r518_16 = math.pi
        local r518_17 = r518_15 * (180.0 / r518_16)
        if r518_2._CachedPosVec then
            r518_2._CachedPosVec.X = p518_3
            r518_2._CachedPosVec.Y = p518_4 - r518_14 / 2.0
            r518_2._CachedSizeVec.X = r518_13
            r518_2._CachedSizeVec.Y = r518_14
        else
            local r518_18 = r0_79 and (r0_79(p518_3, p518_4 - r518_14 / 2.0) or {
                X = p518_3,
                Y = p518_4 - r518_14 / 2.0
            }) or { X = p518_3, Y = p518_4 - r518_14 / 2.0 }
            r518_2._CachedPosVec = r518_18
            local r518_19 = r0_79 and (r0_79(r518_13, r518_14) or { X = r518_13, Y = r518_14 }) or {
                X = r518_13,
                Y = r518_14
            }
            r518_2._CachedSizeVec = r518_19
        end
        pcall(function()
            r518_4:SetPosition(r518_2._CachedPosVec)
            r518_4:SetSize(r518_2._CachedSizeVec)
            if r518_1 then
                r518_4:SetZOrder(1)
            end
        end)
        pcall(function()
            r518_3:SetRenderAngle(r518_17)
        end)
        return
    end
    if r518_0 and r518_0.Widget and slua.isValid(r518_0.Widget) then
        pcall(function()
            r518_0.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end)
    end
end

-- line 3864-3870
-- proto#525 params=1 locals=1 upvalues=2 vararg=false
function r0_72.RemoveSnapLine(p525_0)
    local r525_0 = r0_72.SnapLineWidgets[p525_0]
    if r525_0 and r525_0.Widget and slua.isValid(r525_0.Widget) then
        pcall(function()
            r525_0.Widget:RemoveFromParent()
            r525_0.Widget:ConditionalBeginDestroy()
        end)
        r0_72.SnapLineWidgets[p525_0] = nil
    end
end

-- line 3872-3879
-- proto#527 params=0 locals=2 upvalues=2 vararg=false
function r0_72.ClearAllSnapLines()
    for r527_0, r527_1 in pairs(r0_72.SnapLineWidgets) do
        if r527_1 and r527_1.Widget and slua.isValid(r527_1.Widget) then
            pcall(function()
                r527_1.Widget:RemoveFromParent()
                r527_1.Widget:ConditionalBeginDestroy()
            end)
        end
    end
    r0_72.SnapLineWidgets = {}
end

-- line 3881-3887
-- proto#529 params=3 locals=7 upvalues=1 vararg=false
function r0_72.ScreenPixelToCanvasLocalRaw(p529_0, p529_1, p529_2)
    return p529_1 * (r0_72._CanvasScaleX or 1.0) + (r0_72._CanvasOffsetX or 0), p529_2 * (r0_72._CanvasScaleY or 1.0) + (r0_72._CanvasOffsetY or 0)
end

-- line 3889-3903
-- proto#530 params=2 locals=5 upvalues=4 vararg=false
function r0_72.ProjectWorldToCanvasLocalRaw(p530_0, p530_1)
    if r0_89(p530_0) and p530_1 then
        if not r0_72._tempScreenPixelPos then
            local r530_0 = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 }
            r0_72._tempScreenPixelPos = r530_0
        end
        local r530_1, r530_2 = r0_72._tempScreenPixelPos, false
        pcall(function()
            local r531_0 = p530_0:ProjectWorldLocationToScreen(p530_1, r530_1, true)
            if r531_0 == true or r531_0 == 1 then
                r530_2 = true
            end
        end)
        if not r530_2 or r530_1.X == 0 and r530_1.Y == 0 then
            return false, 0, 0
        end
        local r530_3, r530_4 = r0_72.ScreenPixelToCanvasLocalRaw(p530_0, r530_1.X, r530_1.Y)
        return true, r530_3, r530_4
    end
    return false, 0, 0
end

-- line 3905-3936
-- proto#532 params=2 locals=6 upvalues=3 vararg=false
function r0_72.GetBoneLocationWithFallback(p532_0, p532_1)
    if r0_89(p532_0) and p532_1 then
        if p532_0._cachedBoneNames and p532_0._cachedBoneNames[p532_1] then
            local r532_0, r532_1 = p532_0._cachedBoneNames[p532_1], nil
            pcall(function()
                local r533_0 = r0_72.GetCharacterMesh(p532_0)
                if r533_0 and Game:IsValid(r533_0) then
                    if r533_0.GetSocketLocation then
                        r532_1 = r533_0:GetSocketLocation(r532_0)
                    elseif r533_0.GetBoneLocation then
                        r532_1 = r533_0:GetBoneLocation(r532_0)
                    end
                end
            end)
            if r532_1 then
                return r532_1
            end
        end
        local r532_2 = r0_72.BoneNameFallbacks[p532_1]
        for r532_3, r532_4 in ipairs(r532_2 or {}) do
            local r532_5 = nil
            pcall(function()
                local r534_0 = r0_72.GetCharacterMesh(p532_0)
                if r534_0 and Game:IsValid(r534_0) then
                    if r534_0.GetSocketLocation then
                        r532_5 = r534_0:GetSocketLocation(r532_4)
                    elseif r534_0.GetBoneLocation then
                        r532_5 = r534_0:GetBoneLocation(r532_4)
                    end
                end
            end)
            if r532_5 then
                if not p532_0._cachedBoneNames then
                    p532_0._cachedBoneNames = {}
                end
                p532_0._cachedBoneNames[p532_1] = r532_4
                return r532_5
            end
        end
        return nil
    end
    return nil
end

-- line 3938-3988
-- proto#535 params=2 locals=5 upvalues=4 vararg=false
function r0_72.IsPlayerVisible(p535_0, p535_1)
    if r0_89(p535_0) and r0_89(p535_1) then
        local r535_0 = os.clock()
        if p535_1._lastVisTime and r535_0 - p535_1._lastVisTime < 0.15 then
            return p535_1._cachedIsVisible or false
        end
        p535_1._lastVisTime = r535_0
        local r535_1 = false
        pcall(function()
            if p535_0.LineOfSightTo then
                if not r0_72._ZeroVector then
                    local r536_0 = r0_81
                    if not r0_81 then
                        r536_0 = import("/Script/CoreUObject.Vector")
                    end
                    if r536_0 then
                        r0_72._ZeroVector = r536_0(0, 0, 0)
                    end
                end
                r535_1 = p535_0:LineOfSightTo(p535_1, r0_72._ZeroVector, false)
            end
        end)
        if not r535_1 then
            local r535_2 = import("KismetSystemLibrary")
            if r535_2 and r535_2.LineTraceSingle then
                pcall(function()
                    local r537_0 = nil
                    local r537_1 = import("GameplayStatics")
                    local r537_2
                    if r537_1 then
                        local r537_3 = r537_1.GetPlayerCameraManager
                        if r537_3 then
                            r537_2 = r537_1.GetPlayerCameraManager(p535_0, 0)
                        else
                            r537_2 = r537_3
                        end
                    else
                        r537_2 = r537_0
                    end
                    local r537_4
                    if r537_2 then
                        local r537_5 = r537_2:GetCameraLocation()
                        if r537_5 then
                            r537_4 = r537_5
                        else
                            r537_4 = r0_72.GetMyLocation()
                        end
                    else
                        r537_4 = r0_72.GetMyLocation()
                    end
                    local r537_6 = r0_72.GetBoneLocationWithFallback(p535_1, "head")
                    if r537_4 and r537_6 then
                        if not r0_72._CachedHitResult then
                            local r537_7 = import("HitResult")
                            if not r537_7 then
                                r537_7 = import("/Script/Engine.HitResult")
                            end
                            local r537_8 = r537_7 and (r537_7() or {}) or {}
                            r0_72._CachedHitResult = r537_8
                        end
                        local r537_9 = r535_2.LineTraceSingle(p535_0, r537_4, r537_6, 0, false, nil, 0, r0_72._CachedHitResult, true)
                        if r537_9 then
                            local r537_10 = type
                            local r537_11 = r0_72._CachedHitResult
                            local r537_12
                            if r537_10(r537_11.GetActor) == "function" then
                                r537_12 = r0_72._CachedHitResult:GetActor()
                            else
                                local r537_13 = r0_72._CachedHitResult.Actor
                                if r537_13 then
                                    r537_12 = r0_72._CachedHitResult.Actor
                                else
                                    r537_12 = r537_13
                                end
                            end
                            if r537_12 and (r537_12 == p535_1 or type(r537_12.IsChildOf) == "function" and r537_12:IsChildOf(p535_1)) then
                                r535_1 = true
                            end
                        else
                            r535_1 = true
                        end
                    end
                end)
            end
        end
        p535_1._cachedIsVisible = r535_1
        return r535_1
    end
    return false
end

-- line 3990-4009
-- proto#538 params=0 locals=7 upvalues=3 vararg=false
function r0_72.CreateSkeletonLineWidget()
    if r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas) then
        local r538_0 = nil
        pcall(function()
            r538_0 = CGame:NewObjectFromPath("/Script/UMG.Border", r0_72.ESPCanvas)
        end)
        if r538_0 and slua.isValid(r538_0) then
            pcall(function()
                local r540_0 = r0_79 and (r0_79(0.0, 0.5) or { X = 0, Y = 0.5 }) or {
                    X = 0,
                    Y = 0.5
                }
                r538_0.RenderTransformPivot = r540_0
            end)
            pcall(function()
                local r541_0 = r538_0
                local r541_1 = r0_79 and (r0_79(0.0, 0.5) or { X = 0, Y = 0.5 }) or {
                    X = 0,
                    Y = 0.5
                }
                r541_0:SetRenderTransformPivot(r541_1)
            end)
            local r538_1 = nil
            pcall(function()
                r538_1 = r0_72.ESPCanvas:AddChildToCanvas(r538_0)
                if r538_1 then
                    r538_1:SetAutoSize(false)
                    r538_1:SetZOrder(5)
                end
            end)
            return {
                Widget = r538_0,
                Slot = r538_1,
                posVec = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 },
                sizeVec = r0_79 and (r0_79(0, 0) or { X = 0, Y = 0 }) or { X = 0, Y = 0 },
                lastFromX = -99999,
                lastFromY = -99999,
                lastToX = -99999,
                lastToY = -99999
            }
        end
        return nil
    end
    return nil
end

-- line 4011-4176
-- proto#543 params=7 locals=91 upvalues=4 vararg=false
function r0_72.UpdateSkeletonLines(p543_0, p543_1, p543_2, p543_3, p543_4, p543_5, p543_6)
    if not r0_72.bUseSkeleton then
        return
    end
    if not (r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas)) then
        return
    end
    local r543_0 = r0_72.SkeletonWidgets[p543_0]
    if p543_3 and r0_89(p543_1) and r0_89(p543_2) then
        local r543_1 = p543_6
        if not p543_6 then
            r543_1 = r0_72.GetESPLocation(p543_1)
        end
        if r543_1 then
            local r543_2 = p543_5
            if p543_5 == nil then
                local r543_3, r543_4, r543_5 = r0_72.ProjectWorldToCanvasLocalRaw(p543_2, r543_1)
                r543_2 = r543_3
            end
            if r543_2 then
                local r543_6, r543_7 = 0, r0_72._CachedMyLoc
                if not r543_7 then
                    r543_7 = r0_72.GetMyLocation()
                end
                if r543_7 and r543_1 then
                    local r543_8 = r543_1.X or 0
                    local r543_9 = r543_7.X
                    local r543_10 = r543_8 - (r543_9 or 0)
                    local r543_11 = r543_1.Y or 0
                    local r543_12 = r543_7.Y
                    local r543_13 = r543_11 - (r543_12 or 0)
                    local r543_14 = (r543_1.Z or 0) - (r543_7.Z or 0)
                    r543_6 = math.sqrt(r543_10 * r543_10 + r543_13 * r543_13 + r543_14 * r543_14)
                end
                if r0_72.SkeletonMaxDistance and r0_72.SkeletonMaxDistance > 0 and r0_72.SkeletonMaxDistance < r543_6 then
                    if r543_0 then
                        for r543_15, r543_16 in ipairs(r543_0) do
                            if r543_16 and r543_16.Widget and slua.isValid(r543_16.Widget) then
                                r543_16.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                                r543_16.Widget._isSelfHitTestVisible = false
                            end
                        end
                    end
                    return
                end
                local r543_17
                if r543_0 then
                    r543_17 = r543_0
                else
                    local r543_18 = {}
                    r0_72.SkeletonWidgets[p543_0] = r543_18
                    r543_17 = r543_18
                end
                local r543_19
                if r0_72.bUseVisibilityColor then
                    if r0_72.IsPlayerVisible(p543_2, p543_1) then
                        local r543_20 = r0_72.SkeletonVisibleColor
                        if r543_20 then
                            r543_19 = r543_20
                        else
                            r543_19 = r0_80(0.0, 1.0, 0.0, 0.8)
                        end
                    else
                        local r543_21 = r0_72.SkeletonCoverColor
                        if r543_21 then
                            r543_19 = r543_21
                        else
                            r543_19 = r0_80(0.9, 0.0, 0.0, 0.6)
                        end
                    end
                else
                    local r543_22 = r0_72.SkeletonColor
                    if r543_22 then
                        r543_19 = r543_22
                    elseif p543_4 then
                        r543_19 = p543_4
                    else
                        r543_19 = r0_80(1.0, 1.0, 1.0, r0_72.SkeletonOpacity or 0.8)
                    end
                end
                local r543_23 = r0_72._StaticBoneLocCache
                for r543_24 in pairs(r543_23) do
                    r543_23[r543_24] = nil
                end
                local r543_25, r543_26 = 0, r0_72.SkeletonThickness
                if not r543_26 then
                    r543_26 = 1.2
                end
                if not p543_1._cachedBones3D then
                    p543_1._cachedBones3D = {}
                end
                for r543_27, r543_28 in ipairs(r0_72.SkeletonChains) do
                    local r543_29, r543_30 = nil, nil
                    local r543_31, r543_32, r543_33 = ipairs(r543_28)
                    local r543_34 = r543_29
                    local r543_35 = r543_30
                    for r543_36, r543_37 in r543_31, r543_32, r543_33 do
                        local r543_38 = r543_23[r543_37]
                        if r543_38 == nil then
                            local r543_39 = r0_72.GetBoneLocationWithFallback(p543_1, r543_37)
                            if r543_39 then
                                r543_38 = r543_39
                            else
                                r543_38 = false
                            end
                            r543_23[r543_37] = r543_38
                        end
                        local r543_40 = r543_38 or nil
                        local r543_41, r543_42 = nil, nil
                        local r543_43, r543_44
                        if r543_40 then
                            local r543_45, r543_46, r543_47 = r0_72.ProjectWorldToCanvasLocalRaw(p543_2, r543_40)
                            if r543_45 then
                                local r543_48 = r543_46
                                local r543_49 = r543_47
                                r543_43 = r543_48
                                r543_44 = r543_49
                            else
                                r543_43 = r543_45
                                r543_44 = r543_45
                            end
                        else
                            r543_43 = r543_41
                            r543_44 = r543_42
                        end
                        local r543_50
                        r543_25 = r543_50
                        if r543_34 and r543_43 then
                            r543_25 = r543_25 + 1
                            local r543_51 = r543_17[r543_25]
                            local r543_52
                            if not (r543_51 and r543_51.Widget and slua.isValid(r543_51.Widget)) then
                                r543_52 = r0_72.CreateSkeletonLineWidget()
                                if r543_52 then
                                    r543_17[r543_25] = r543_52
                                end
                            end
                            if r543_52 and r543_52.Widget and r543_52.Slot then
                                local r543_53, r543_54 = r543_52.Widget, r543_52.Slot
                                if r543_53._cachedColor ~= r543_19 then
                                    r543_53:SetBrushColor(r543_19)
                                    r543_53._cachedColor = r543_19
                                end
                                if not r543_53._isSelfHitTestVisible then
                                    r543_53:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                    r543_53._isSelfHitTestVisible = true
                                end
                                local r543_55, r543_56, r543_57, r543_58 = r543_34, r543_35, r543_43, r543_44
                                local r543_59 = r543_6 > 8000 and 0.8 or r543_6 > 4000 and 0.4 or 0.15
                                local r543_60 = math.abs(r543_55 - r543_52.lastFromX)
                                if r543_59 < r543_60 or math.abs(r543_56 - r543_52.lastFromY) > r543_59 or math.abs(r543_57 - r543_52.lastToX) > r543_59 or math.abs(r543_58 - r543_52.lastToY) > r543_59 then
                                    r543_52.lastFromX = r543_55
                                    r543_52.lastFromY = r543_56
                                    r543_52.lastToX = r543_57
                                    r543_52.lastToY = r543_58
                                    local r543_61 = r543_57 - r543_55
                                    local r543_62 = r543_58 - r543_56
                                    local r543_63 = math.sqrt(r543_61 * r543_61 + r543_62 * r543_62)
                                    local r543_64
                                    if math.atan2 then
                                        local r543_65 = math.atan2(r543_62, r543_61)
                                        if r543_65 then
                                            r543_64 = r543_65
                                        else
                                            r543_64 = math.atan(r543_62, r543_61)
                                        end
                                    else
                                        r543_64 = math.atan(r543_62, r543_61)
                                    end
                                    local r543_66 = r543_64 * 57.29577951308232
                                    local r543_67 = r543_52.posVec
                                    r543_67.X = r543_55
                                    r543_67.Y = r543_56 - r543_26 / 2.0
                                    r543_54:SetPosition(r543_67)
                                    local r543_68 = r543_52.sizeVec
                                    r543_68.X = r543_63
                                    r543_68.Y = r543_26
                                    r543_54:SetSize(r543_68)
                                    r543_53:SetRenderAngle(r543_66)
                                end
                            end
                        end
                        r543_34 = r543_43
                        r543_35 = r543_44
                    end
                end
                for r543_69 = r543_25 + 1, #r543_17 do
                    local r543_70 = r543_17[r543_69]
                    if r543_70 and r543_70.Widget and slua.isValid(r543_70.Widget) then
                        r543_70.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                        r543_70.Widget._isSelfHitTestVisible = false
                    end
                end
                return
            end
            if r543_0 then
                for r543_71, r543_72 in ipairs(r543_0) do
                    if r543_72 and r543_72.Widget and slua.isValid(r543_72.Widget) then
                        r543_72.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                        r543_72.Widget._isSelfHitTestVisible = false
                    end
                end
            end
            return
        end
        return
    end
    if r543_0 then
        for r543_73, r543_74 in ipairs(r543_0) do
            if r543_74 and r543_74.Widget and slua.isValid(r543_74.Widget) then
                r543_74.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                r543_74.Widget._isSelfHitTestVisible = false
            end
        end
    end
end

-- line 4178-4191
-- proto#544 params=1 locals=3 upvalues=2 vararg=false
function r0_72.RemoveSkeletonLines(p544_0)
    local r544_0 = r0_72.SkeletonWidgets[p544_0]
    if r544_0 then
        for r544_1, r544_2 in ipairs(r544_0) do
            if r544_2 and r544_2.Widget and slua.isValid(r544_2.Widget) then
                pcall(function()
                    r544_2.Widget:RemoveFromParent()
                    r544_2.Widget:ConditionalBeginDestroy()
                end)
            end
        end
        r0_72.SkeletonWidgets[p544_0] = nil
    end
end

-- line 4193-4205
-- proto#546 params=0 locals=4 upvalues=2 vararg=false
function r0_72.ClearAllSkeletonLines()
    for r546_0, r546_1 in pairs(r0_72.SkeletonWidgets) do
        for r546_2, r546_3 in ipairs(r546_1) do
            if r546_3 and r546_3.Widget and slua.isValid(r546_3.Widget) then
                pcall(function()
                    r546_3.Widget:RemoveFromParent()
                    r546_3.Widget:ConditionalBeginDestroy()
                end)
            end
        end
    end
    r0_72.SkeletonWidgets = {}
end

-- line 4207-4233
-- proto#548 params=0 locals=2 upvalues=3 vararg=false
function r0_72.ClearAllESP()
    r0_73.Stop()
    for r548_0, r548_1 in pairs(r0_72.ESPWidgets) do
        r0_72.RemoveESPWidget(r548_1.Widget, r548_0)
    end
    r0_72.ESPWidgets = {}
    r0_72.ESPWidgetPtrs = {}
    r0_72.ClearAllSnapLines()
    r0_72.ClearAllSkeletonLines()
    if r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas) then
        pcall(function()
            local r549_0 = r0_72.ESPCanvas:GetChildrenCount()
            for r549_1 = r549_0 - 1, 0, -1 do
                local r549_2 = r0_72.ESPCanvas:GetChildAt(r549_1)
                if r549_2 and slua.isValid(r549_2) and r0_72.IsOurESPWidget(r549_2) then
                    r0_72.ESPCanvas:RemoveChild(r549_2)
                end
            end
        end)
    end
    r0_72.ESPCanvas = nil
    r0_72._OBHeadWidgetClass = nil
    r0_72._OBHeadWidgetLoadFailed = false
    r0_72._bDumpedWidgetChildren = false
    r0_72._cachedViewportW = 1920
    r0_72._cachedViewportH = 1080
end

-- line 4235-4402
-- proto#550 params=2 locals=70 upvalues=3 vararg=false
function r0_72.UpdateESP(p550_0, p550_1)
    if not r0_72.bUseScreenESP then
        return
    end
    r0_72.bUseSnapLines = _G.LexusConfig.Esp9_Line
    r0_72.bUseSkeleton = _G.LexusConfig.Esp9_Skeleton
    if not r0_72.InitESPCanvas() then
        return
    end
    if r0_72._OBHeadWidgetLoadFailed then
        return
    end
    local r550_0 = r0_72.GetMyPlayerController()
    if r0_89(r550_0) then
        r0_72.UpdateCanvasTransform(r550_0)
    end
    local r550_1, r550_2, r550_3 = 0, 0, r0_72.bUseSnapLines
    local r550_4, r550_5, r550_6, r550_7
    if r550_3 then
        r550_6 = r0_89(r550_0)
        if r550_6 then
            local r550_8, r550_9 = r0_72.GetSnapLineStartPos(r550_0)
            r550_7 = r550_9
            r550_4 = r550_8
            r550_5 = r550_7
        else
            r550_4 = r550_6
            r550_5 = r550_6
        end
    else
        r550_4 = r550_1
        r550_5 = r550_2
    end
    if r550_3 then
        if r550_6 then
            r550_5 = r550_7
        else
            r550_5 = r550_2
        end
    else
        r550_5 = r550_2
    end
    local r550_10 = r0_72.GetMyPlayerKey()
    local r550_11 = {}
    local r550_12 = nil
    pcall(function()
        local r551_0 = r0_72.GetGameplayData()
        if r551_0 and r551_0.GetLocalCharacter then
            r550_12 = r551_0.GetLocalCharacter()
        elseif r550_0 and r550_0.GetPawn then
            r550_12 = r550_0:GetPawn()
        end
    end)
    local r550_13 = r0_72.GetTeamID(r550_12)
    for r550_14, r550_15 in pairs(p550_0) do
        if r0_89(r550_15) then
            local r550_16 = r0_72.IsMe(r550_15, r550_14, r550_10)
            local r550_17 = r0_72.IsAI(r550_15)
            local r550_18 = tostring(r550_14)
            local r550_19 = r0_72.GetPlayerName(r550_15)
            local r550_20 = r0_72.GetESPLocation(r550_15)
            local r550_21 = ""
            if p550_1 then
                if r550_20 then
                    r550_21 = r0_72.GetDistanceString(p550_1, r550_20)
                else
                    r550_21 = r550_20
                end
            end
            if r550_16 then
                local r550_22 = r0_72.bIncludeMe
            end
            local r550_23 = r550_17 and (r0_72.bIncludeAI or true)
            local r550_24 = r0_72.GetTeamID(r550_15)
            local r550_25 = r550_13 ~= nil and r550_24 == r550_13 and (r550_16 or true) or r550_23
            local r550_26 = r0_72.IsAlive(r550_15)
            if not r550_25 and r550_20 then
                r550_11[r550_18] = true
                local r550_27, r550_28 = r0_72.ESPWidgets[r550_18], ""
                if _G.LexusConfig.Esp9_Name then
                    r550_28 = r550_19
                end
                local r550_29 = _G.LexusConfig.Esp9_Distance
                local r550_30
                if r550_29 then
                    if r550_21 then
                        if r550_21 == "" then
                            r550_30 = r550_28
                        elseif r550_28 == "" then
                            r550_30 = string.format("[%s]", r550_21)
                        else
                            r550_30 = string.format("%s [%s]", r550_28, r550_21)
                        end
                    else
                        r550_30 = r550_21
                    end
                else
                    r550_30 = r550_29
                end
                local r550_31, r550_32 = r0_72.ProjectWorldToCanvasLocal(r550_0, r550_20)
                if r550_27 then
                    r550_27.Character = r550_15
                    r550_27.Name = r550_19
                    r550_27.LastDistStr = r550_21
                    if r550_26 then
                        r550_27.TeamID = r550_24
                        r0_72.ApplyTeamColor(r550_27.Widget, r550_24)
                        r550_27.Widget._LastESPText = nil
                        r0_72.UpdateESPText(r550_27.Widget, r550_30)
                        r0_72.UpdateESPPositionWithPC(r550_27.Widget, r550_20, r550_0, r550_32)
                        local r550_33 = r550_15.Health
                        if not r550_33 then
                            r550_33 = 0
                        end
                        local r550_34 = r550_15.MaxHealth
                        if not r550_34 then
                            r550_34 = 120
                        end
                        local r550_35 = 0
                        if r550_33 > 0 and r550_34 > 0 then
                            r550_35 = r550_33 / r550_34
                            if r550_35 > 1 then
                                r550_35 = 1
                            else
                                r550_35 = r550_35
                            end
                            if r550_35 < 0 then
                                r550_35 = 0
                            end
                        end
                        r0_72.UpdateESPHealth(r550_27.Widget, r550_35)
                        r0_72.AddWeaponIconToESP(r550_27.Widget, r550_15)
                        if r0_72.bUseSnapLines then
                            r0_72.UpdateSnapLine(r550_18, r550_32, r550_31, r550_4, r550_5)
                        else
                            r0_72.RemoveSnapLine(r550_18)
                        end
                        if r0_72.bUseSkeleton then
                            r0_72.UpdateSkeletonLines(r550_18, r550_15, r550_0, true, r0_72.GetTeamColor(r550_24), r550_31, r550_20)
                        else
                            r0_72.RemoveSkeletonLines(r550_18)
                        end
                    else
                        local r550_36 = r550_27.Widget.Container or r550_27.Widget
                        pcall(function()
                            r550_36:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                        end)
                        r0_72.UpdateESPHealth(r550_27.Widget, 0)
                        r0_72.RemoveSnapLine(r550_18)
                        r0_72.RemoveSkeletonLines(r550_18)
                    end
                else
                    local r550_37 = r0_72.CreateESPWidget()
                    if r550_37 then
                        r0_72.ESPWidgets[r550_18] = {
                            Widget = r550_37,
                            Character = r550_15,
                            Name = r550_19,
                            LastDistStr = r550_21,
                            TeamID = r550_24
                        }
                        r0_72.UpdateESPText(r550_37, r550_30)
                        if r550_26 then
                            r0_72.UpdateESPPositionWithPC(r550_37, r550_20, r550_0, r550_32)
                            r0_72.ApplyTeamColor(r550_37, r550_24)
                            local r550_38 = r550_15.Health
                            if not r550_38 then
                                r550_38 = 0
                            end
                            local r550_39 = r550_15.MaxHealth
                            if not r550_39 then
                                r550_39 = 120
                            end
                            local r550_40 = 0
                            if r550_38 > 0 and r550_39 > 0 then
                                r550_40 = r550_38 / r550_39
                                if r550_40 > 1 then
                                    r550_40 = 1
                                else
                                    r550_40 = r550_40
                                end
                                if r550_40 < 0 then
                                    r550_40 = 0
                                end
                            end
                            r0_72.UpdateESPHealth(r550_37, r550_40)
                            r0_72.AddWeaponIconToESP(r550_37, r550_15)
                            if r0_72.bUseSnapLines then
                                r0_72.UpdateSnapLine(r550_18, r550_32, r550_31, r550_4, r550_5)
                            else
                                r0_72.RemoveSnapLine(r550_18)
                            end
                            if r0_72.bUseSkeleton then
                                r0_72.UpdateSkeletonLines(r550_18, r550_15, r550_0, true, r0_72.GetTeamColor(r550_24), r550_31, r550_20)
                            else
                                r0_72.RemoveSkeletonLines(r550_18)
                            end
                        else
                            local r550_41 = r550_37.Container or r550_37
                            pcall(function()
                                r550_41:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                            end)
                            r0_72.UpdateESPHealth(r550_37, 0)
                            r0_72.RemoveSnapLine(r550_18)
                            r0_72.RemoveSkeletonLines(r550_18)
                        end
                    end
                end
            end
        end
    end
    for r550_42, r550_43 in pairs(r0_72.ESPWidgets) do
        if not r550_11[r550_42] then
            r0_72.RemoveESPWidget(r550_43.Widget, r550_42)
            r0_72.ESPWidgets[r550_42] = nil
        end
    end
end

-- line 4404-4460
-- proto#554 params=0 locals=29 upvalues=4 vararg=false
function r0_72.UpdateESPLight()
    if r0_73 and r0_73.bActive then
        r0_73.UpdatePosition()
    end
    if not r0_72.bUseScreenESP then
        return
    end
    r0_72.bUseSnapLines = _G.LexusConfig.Esp9_Line
    r0_72.bUseSkeleton = _G.LexusConfig.Esp9_Skeleton
    if not (r0_72.ESPCanvas and Game:IsValid(r0_72.ESPCanvas)) then
        return
    end
    local r554_0 = r0_72.GetMyPlayerController()
    if not r0_89(r554_0) then
        return
    end
    r0_72.UpdateCanvasTransform(r554_0)
    local r554_1, r554_2, r554_3 = 0, 0, r0_72.bUseSnapLines
    local r554_4, r554_5
    if r554_3 then
        local r554_6, r554_7 = r0_72.GetSnapLineStartPos(r554_0)
        r554_8 = r554_7
        r554_4 = r554_6
        r554_5 = r554_8
    else
        r554_4 = r554_1
        r554_5 = r554_2
    end
    if r554_3 then
        local r554_8
        r554_5 = r554_8
    else
        r554_5 = r554_2
    end
    for r554_9, r554_10 in pairs(r0_72.ESPWidgets) do
        local r554_11, r554_12 = r554_10.Widget, r554_10.Character
        local r554_13 = r554_11 and (r554_11.Container or r554_11)
        local r554_14 = false
        pcall(function()
            r554_14 = r554_13 and slua.isValid(r554_13)
        end)
        if r554_11 and r554_14 and r554_12 and r0_89(r554_12) then
            if r0_72.IsAlive(r554_12) then
                local r554_15 = _G.LexusConfig.Esp9_Name or _G.LexusConfig.Esp9_Distance or _G.LexusConfig.Esp9_HP or _G.LexusConfig.Esp9_Team or _G.LexusConfig.Esp9_Weapon
                if r554_15 then
                    pcall(function()
                        r554_13:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    end)
                else
                    pcall(function()
                        r554_13:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    end)
                end
                pcall(function()
                    r554_13:SetRenderOpacity(1.0)
                end)
                local r554_16 = r0_72.GetESPLocation(r554_12)
                if r554_16 then
                    local r554_17, r554_18 = r0_72.ProjectWorldToCanvasLocal(r554_0, r554_16)
                    r0_72.UpdateESPPositionWithPC(r554_11, r554_16, r554_0, r554_18)
                    if r0_72.bUseSnapLines then
                        r0_72.UpdateSnapLine(r554_9, r554_18, r554_17, r554_4, r554_5)
                    else
                        r0_72.RemoveSnapLine(r554_9)
                    end
                    if r0_72.bUseSkeleton then
                        r0_72.UpdateSkeletonLines(r554_9, r554_12, r554_0, true, r0_72.GetTeamColor(r554_10.TeamID), r554_17, r554_16)
                    else
                        r0_72.RemoveSkeletonLines(r554_9)
                    end
                else
                    r0_72.RemoveSnapLine(r554_9)
                    r0_72.RemoveSkeletonLines(r554_9)
                end
            else
                pcall(function()
                    r554_13:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                end)
                r0_72.RemoveSnapLine(r554_9)
                r0_72.RemoveSkeletonLines(r554_9)
            end
        end
    end
end

-- line 4462-4506
-- proto#560 params=0 locals=28 upvalues=3 vararg=false
function r0_72.UpdateESPDistances()
    if not r0_72.bUseScreenESP then
        return
    end
    local r560_0 = r0_72.GetMyLocation()
    if not r560_0 then
        return
    end
    local r560_1 = r0_72.GetMyPlayerController()
    if not r0_89(r560_1) then
        return
    end
    r0_72.UpdateCanvasTransform(r560_1)
    for r560_2, r560_3 in pairs(r0_72.ESPWidgets) do
        local r560_4, r560_5 = r560_3.Character, r560_3.Widget
        local r560_6 = r560_5 and (r560_5.Container or r560_5)
        local r560_7 = false
        pcall(function()
            r560_7 = r560_6 and slua.isValid(r560_6)
        end)
        if r560_4 and r0_89(r560_4) and r560_5 and r560_7 then
            local r560_8 = r0_72.GetESPLocation(r560_4)
            if r560_8 then
                local r560_9 = r0_72.CalcDistance(r560_0, r560_8)
                r560_3.LastDistance = r560_9
                if r0_72.bShowDistance then
                    local r560_10 = ""
                    if r560_9 then
                        local r560_11 = r560_9 / 100
                        if r560_11 < 1000 then
                            r560_10 = string.format("%dm", math.floor(r560_11))
                        else
                            r560_10 = string.format("%.1fkm", r560_11 / 1000)
                        end
                    end
                    local r560_12 = r560_3.Name or "Unknown"
                    local r560_13 = ""
                    if _G.LexusConfig.Esp9_Name then
                        r560_13 = r560_12
                    end
                    local r560_14 = _G.LexusConfig.Esp9_Distance
                    local r560_15
                    if r560_14 then
                        if r560_10 then
                            if r560_10 == "" then
                                r560_15 = r560_13
                            elseif r560_13 == "" then
                                r560_15 = string.format("[%s]", r560_10)
                            else
                                r560_15 = string.format("%s [%s]", r560_13, r560_10)
                            end
                        else
                            r560_15 = r560_10
                        end
                    else
                        r560_15 = r560_14
                    end
                    r560_3.LastDistStr = r560_10
                    r560_5._LastESPText = nil
                    r0_72.UpdateESPText(r560_5, r560_15)
                end
            end
        end
    end
end

-- line 4508-4559
-- proto#562 params=0 locals=22 upvalues=4 vararg=false
function r0_72.ScanAndUpdate()
    local r562_0 = r0_72.GetAllCharacters()
    if r562_0 then
        local r562_1 = r0_72.GetMyPlayerKey()
        local r562_2 = r0_72.GetMyLocation()
        local r562_3 = nil
        pcall(function()
            local r563_0 = r0_72.GetGameplayData()
            if r563_0 and r563_0.GetLocalCharacter then
                r562_3 = r563_0.GetLocalCharacter()
            else
                local r563_1 = r0_72.GetMyPlayerController()
                if r563_1 and r563_1.GetPawn then
                    r562_3 = r563_1:GetPawn()
                end
            end
        end)
        local r562_4 = r0_72.GetTeamID(r562_3)
        local r562_5, r562_6 = 0, 0
        for r562_7, r562_8 in pairs(r562_0) do
            if r0_89(r562_8) then
                local r562_9 = r0_72.IsMe(r562_8, r562_7, r562_1)
                local r562_10 = r0_72.IsAI(r562_8)
                if r0_72.IsAlive(r562_8) and not r562_9 then
                    local r562_11 = false
                    if r562_4 ~= nil and r0_72.GetTeamID(r562_8) == r562_4 then
                        r562_11 = true
                    end
                    if not r562_11 then
                        if r562_10 then
                            r562_6 = r562_6 + 1
                        else
                            r562_5 = r562_5 + 1
                        end
                    end
                end
            end
        end
        if _G.LexusConfig.Esp9_Count then
            if r0_73.bActive then
                r0_73.SetCounts(r562_5, r562_6)
            else
                r0_73.Start()
            end
        elseif r0_73.bActive then
            r0_73.Stop()
        end
        if r0_72.bUseScreenESP then
            r0_72.UpdateESP(r562_0, r562_2)
            return 0
        end
        return 0
    end
    r0_73.SetCounts(0, 0)
    return 0
end

-- line 4561-4585
-- proto#564 params=0 locals=0 upvalues=2 vararg=false
function r0_72.AttachTimers()
    pcall(function()
        local r565_0 = r0_72.GetMyPlayerController()
        if slua.isValid(r565_0) and r565_0.AddGameTimer then
            r0_72._AttachPending = nil
            r0_72._AttachPendingTime = nil
            local r565_1 = os.time()
            local r565_2, r565_3 = r0_72._ActiveTimerPC, r0_72._ActiveTimerTick
            if r565_2 and slua.isValid(r565_2) and r565_2 == r565_0 and r565_3 and r565_1 - r565_3 < 5 then
                return
            end
            r0_72._ActiveTimerPC = r565_0
            r0_72._ActiveTimerTick = r565_1
            pcall(function()
                r565_0:AddGameTimer(r0_72.nUpdateInterval or 0.5, true, function()
                    local r569_0 = os.time
                    r0_72._ActiveTimerTick = r569_0()
                    if r0_72.bActive then
                        pcall(function()
                            r0_72.ScanAndUpdate()
                        end)
                    end
                end)
            end)
            pcall(function()
                r565_0:AddGameTimer(r0_72._LightUpdateInterval or 0.02, true, function()
                    local r572_0 = os.time
                    r0_72._ActiveTimerTick = r572_0()
                    if r0_72.bActive then
                        pcall(function()
                            r0_72.UpdateESPLight()
                        end)
                    end
                end)
            end)
            pcall(function()
                r565_0:AddGameTimer(r0_72._DistanceUpdateInterval or 0.1, true, function()
                    local r575_0 = os.time
                    r0_72._ActiveTimerTick = r575_0()
                    if r0_72.bActive and r0_72.bUseScreenESP and r0_72.bShowDistance then
                        pcall(function()
                            r0_72.UpdateESPDistances()
                        end)
                    end
                end)
            end)
            pcall(function()
                local r577_0 = require("timer")
                r577_0.SetGameTimer(5.0, false, r0_72.AttachTimers)
            end)
            return
        end
        local r565_4 = os.time()
        if r0_72._AttachPending and r0_72._AttachPendingTime and r565_4 - r0_72._AttachPendingTime < 2 then
            return
        end
        r0_72._AttachPending = true
        r0_72._AttachPendingTime = r565_4
        pcall(function()
            local r566_0 = require("timer")
            r566_0.SetGameTimer(1.0, false, function()
                r0_72._AttachPending = nil
                r0_72._AttachPendingTime = nil
                r0_72.AttachTimers()
            end)
        end)
    end)
end

-- line 4587-4593
-- proto#578 params=0 locals=0 upvalues=1 vararg=false
function r0_72.Start()
    if r0_72.bActive then
        return
    end
    r0_72.bActive = true
    r0_72._FrameCount = 0
    r0_72.ScanAndUpdate()
    r0_72.AttachTimers()
end

-- line 4595-4599
-- proto#579 params=0 locals=0 upvalues=1 vararg=false
function r0_72.Stop()
    r0_72.bActive = false
    r0_72._FrameCount = 0
    r0_72.ClearAllESP()
end

_ENV._G.PlayerMapMarker = r0_72

-- line 4603-5405
-- proto#580 params=0 locals=27 upvalues=19 vararg=false
local function r0_94()
    if r0_24 then
        return
    end
    pcall(function()
        local r581_0 = import("KismetSystemLibrary")
        if r581_0 and not _G.FakeHWID_Hooked then
            _G.Original_GetDeviceId = r581_0.GetDeviceId

            -- line 4610-4625
            -- proto#582 params=0 locals=10 upvalues=1 vararg=true
            function r581_0.GetDeviceId(...)
                if _G.LexusConfig.FakeHWID then
                    if not _G.FakeHWID_String then
                        local r582_0, r582_1 = "0123456789abcdef", ""
                        for r582_2 = 1, 32 do
                            local r582_3 = r582_1
                            local r582_4 = math.random(1, 16)
                            local r582_5 = r582_0:sub(r582_4, math.random(1, 16))
                            r582_1 = r582_3 .. r582_5
                        end
                        _G.FakeHWID_String = r582_1
                    end
                    return _G.FakeHWID_String
                end
                if _G.Original_GetDeviceId then
                    return _G.Original_GetDeviceId(...)
                end
                return "UNKNOWN"
            end

            _G.FakeHWID_Hooked = true
        end
    end)

    -- line 4630-4639
    -- proto#583 params=0 locals=5 upvalues=1 vararg=false
    function _G.GetOriginalHWID()
        if _G.Original_GetDeviceId then
            return tostring(_G.Original_GetDeviceId())
        end
        local r583_0 = import("KismetSystemLibrary")
        if r583_0 and type(r583_0.GetDeviceId) == "function" then
            return tostring(r583_0.GetDeviceId())
        end
        return "UNKNOWN_DEVICE"
    end

    if _G.LexusState.CustomTextData == nil then
        _G.LexusState.CustomTextData = {}
    end
    local r580_0, r580_1 = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not (r580_0 and r580_1) then
        return
    end
    local r580_2 = r580_1.GetPlayerController()
    local r580_3 = nil
    if r0_19(r580_2) then
        local r580_4
        r580_3 = r580_4
    end
    if r0_19(r580_3) then
        r0_62()
        r0_61()
        if _G.LexusConfig.EspLoai9 then
            if _G.PlayerMapMarker and not _G.PlayerMapMarker.bActive then
                _G.PlayerMapMarker.Start()
            end
        elseif _G.PlayerMapMarker and _G.PlayerMapMarker.bActive then
            _G.PlayerMapMarker.Stop()
        end
        pcall(function()
            if r580_2.HiggsBoson then
                r580_2.HiggsBoson.bMHActive = false
                r580_2.HiggsBoson.bCallPreReplication = false
            end
            if r580_2.HiggsBosonComponent then
                r580_2.HiggsBosonComponent.bMHActive = false
                r580_2.HiggsBosonComponent.bCallPreReplication = false
            end
        end)
        local r580_5, r580_6, r580_7, r580_8 = 1.0, 1.0, 1.0, false
        -- [REMOVED: Magic Bullet system]
        pcall(function()
            local r586_0 = {}
            if r580_1.GetAllPlayerCharacters then
                r586_0 = r580_1.GetAllPlayerCharacters()
            elseif r580_1.GameCharacters then
                for r586_1, r586_2 in pairs(r580_1.GameCharacters) do
                    table.insert(r586_0, r586_2)
                end
            end
            local r586_3 = {}
            for r586_4, r586_5 in pairs(r586_0) do
                if r0_19(r586_5) and r586_5 ~= r580_3 then
                    r586_3[r0_56(r586_5)] = true
                end
            end
            for r586_6, r586_7 in pairs(_G.LexusState.EnemyMarks) do
                if not r586_3[r586_6] then
                    r0_55(r586_7.radarMark)
                    r0_55(r586_7.hpMark)
                    r0_55(r586_7.distMark)
                    if _G.AimTouchVisCache and _G.AimTouchVisCache[r586_6] then
                        _G.AimTouchVisCache[r586_6] = nil
                    end
                    if r586_7.MIDs then
                        for r586_8, r586_9 in pairs(r586_7.MIDs) do
                            for r586_10, r586_11 in pairs(r586_9) do
                                r586_9[r586_10] = nil
                            end
                        end
                        r586_7.MIDs = nil
                    end
                    if r586_7.MIDs_V3 then
                        for r586_12, r586_13 in pairs(r586_7.MIDs_V3) do
                            for r586_14, r586_15 in pairs(r586_13) do
                                r586_13[r586_14] = nil
                            end
                        end
                        r586_7.MIDs_V3 = nil
                    end
                    r586_7.enemy = nil
                    r586_7.CachedMeshes = nil
                    local r586_16 = _G.LexusState
                    r586_16.EnemyMarks[r586_6] = nil
                end
            end
            local r586_17 = 0
            local r586_18 = 0

            -- line 4781-4788
            -- proto#587 params=1 locals=0 upvalues=1 vararg=false
            local function r586_19(p587_0)
                if p587_0 and type(p587_0.Num) == "function" and p587_0:Num() > 0 then
                    if type(p587_0.Get) == "function" then
                        return p587_0:Get(0)
                    end
                    return nil
                end
                if p587_0 and type(p587_0) == "table" and #p587_0 > 0 then
                    return p587_0[1]
                end
                return nil
            end

            local r586_20 = {}
            -- [REMOVED: Magic Bullet bone scale table]
            local r586_21 = nil
            pcall(function()
                if type(r580_3.K2_GetActorLocation) == "function" then
                    r586_21 = r580_3:K2_GetActorLocation()
                end
            end)
            for r586_22, r586_23 in pairs(r586_0) do
                if r0_19(r586_23) and r586_23 ~= r580_3 then
                    local r586_24 = r586_23.TeamID
                    local r586_25 = r580_3.TeamID
                    if r586_24 ~= r586_25 then
                        local r586_26 = false
                        pcall(function()
                            if type(r586_23.IsDead) == "function" then
                                r586_26 = r586_23:IsDead()
                            elseif r586_23.bIsDead == nil then
                                if r586_23.bIsDeadFlag ~= nil then
                                    r586_26 = r586_23.bIsDeadFlag
                                end
                            else
                                r586_26 = r586_23.bIsDead
                            end
                            if r586_23.HealthStatus ~= nil and r586_23.HealthStatus == 2 then
                                r586_26 = true
                            end
                        end)
                        local r586_27 = r0_56(r586_23)
                        local r586_28, r586_29 = _G.LexusState.EnemyMarks, _G.LexusState
                        local r586_30 = r586_29.EnemyMarks[r586_27]
                        r586_28[r586_27] = r586_30 or {}
                        local r586_31 = _G.LexusState
                        local r586_32 = r586_31.EnemyMarks[r586_27]
                        r586_32.enemy = r586_23
                        if r586_26 then
                            if not r586_32.IsCleanedUp then
                                r0_55(r586_32.radarMark)
                                r586_32.radarMark = nil
                                r0_55(r586_32.hpMark)
                                r586_32.hpMark = nil
                                r0_55(r586_32.hpMark8)
                                r586_32.hpMark8 = nil
                                r0_55(r586_32.distMark)
                                r586_32.distMark = nil
                                if r586_32.MIDs then
                                    for r586_33, r586_34 in pairs(r586_32.MIDs) do
                                        for r586_35, r586_36 in pairs(r586_34) do
                                            r586_34[r586_35] = nil
                                        end
                                    end
                                    r586_32.MIDs = nil
                                end
                                if r586_32.MIDs_V3 then
                                    for r586_37, r586_38 in pairs(r586_32.MIDs_V3) do
                                        for r586_39, r586_40 in pairs(r586_38) do
                                            r586_38[r586_39] = nil
                                        end
                                    end
                                    r586_32.MIDs_V3 = nil
                                end
                                pcall(function()
                                    local r609_0 = r586_32.enemy
                                    if r0_19(r609_0) then
                                        if r609_0.Replay_SetVisiableOfFrameUI then
                                            r609_0:Replay_SetVisiableOfFrameUI(false)
                                        end
                                        local r609_1 = r609_0.EnemyFrameUI
                                        local r609_2
                                        if r609_1 then
                                            r609_2 = r609_1
                                        elseif type(r609_0.GetEnemyFrameUI) == "function" then
                                            r609_2 = r609_0:GetEnemyFrameUI()
                                        else
                                            r609_2 = false
                                        end
                                        if r0_19(r609_2) then
                                            if type(r609_2.SetVisibility) == "function" then
                                                r609_2:SetVisibility(2)
                                            end
                                            if type(r609_2.SetHiddenInGame) == "function" then
                                                r609_2:SetHiddenInGame(true)
                                            end
                                        end
                                    end
                                    local r609_3 = import("PostProcessManager").GetInstance()
                                    local r609_4 = r0_19(r609_0) and type(r609_0.getAvatarComponent2) == "function" and r609_0:getAvatarComponent2() or nil
                                    if r0_19(r609_4) and r0_19(r609_3) then
                                        r609_3:EnableAvatarOutline(r609_4, false)
                                    end
                                end)
                                r586_32.IsCleanedUp = true
                            end
                        else
                            if r586_32.lastEnemyActor ~= r586_23 then
                                if r586_32.hpMark then
                                    r0_55(r586_32.hpMark)
                                    r586_32.hpMark = nil
                                end
                                if r586_32.hpMark8 then
                                    r0_55(r586_32.hpMark8)
                                    r586_32.hpMark8 = nil
                                end
                                if r586_32.distMark then
                                    r0_55(r586_32.distMark)
                                    r586_32.distMark = nil
                                end
                                if r586_32.radarMark then
                                    r0_55(r586_32.radarMark)
                                    r586_32.radarMark = nil
                                end
                                r586_32.lastEnemyActor = r586_23
                                r586_32.LastUIComp = nil
                                r586_32.LastFrameUIState = nil
                            end
                            r586_29 = nil
                            pcall(function()
                                r586_29 = r586_23.Mesh or type(r586_23.getAvatarComponent2) == "function" and r586_23:getAvatarComponent2() or nil
                            end)
                            local r586_41 = nil
                            pcall(function()
                                if type(r586_23.K2_GetActorLocation) == "function" then
                                    r586_41 = r586_23:K2_GetActorLocation()
                                end
                            end)
                            local r586_42, r586_43 = r0_57(r586_23, r586_32)
                            local r586_44 = r586_32.AK_IS_BOT or false
                            local r586_45 = 0
                            if r0_19(r586_29) then
                                local r586_46
                                r586_45 = #r586_46
                            end
                            local r586_47 = r586_32.LastMeshCountWall ~= r586_45
                            if _G.LexusConfig.WallXuyenTuong then
                                if r586_47 or not r586_32.WallhackApplied then
                                    r0_65(r586_23, r586_32)
                                    r586_32.WallhackApplied = true
                                    r586_32.LastMeshCountWall = r586_45
                                end
                            else
                                r0_64(r586_23, r586_32)
                            end
                            if _G.LexusConfig.ColorBodyV2 then
                                r0_67(r586_23, r580_2, r586_32)
                            else
                                r0_66(r586_23, r586_32)
                            end
                            if _G.LexusConfig.ColorBodyV3 then
                                r0_68(r586_23, r586_32)
                            else
                                r0_69(r586_23, r586_32)
                            end
                            if _G.LexusConfig.ColorBodyNew then
                                r0_70(r586_23, r586_32)
                            else
                                r0_71(r586_23, r586_32)
                            end
                            pcall(function()
                                if r0_19(r586_29) then
                                    local r592_0 = 1.0
                                    if _G.LexusConfig.BugManEnable and _G.LexusState.CustomTextData then
                                        r592_0 = 177.0 / (_G.LexusState.CustomTextData.BugManRatio or 133)
                                        if r592_0 < 1.0 then
                                            r592_0 = 1.0
                                        else
                                            r592_0 = r592_0
                                        end
                                        if r592_0 > 2.0 then
                                            r592_0 = 2.0
                                        end
                                    end
                                    if r586_32.LastFatScale ~= r592_0 then
                                        r586_29:SetRelativeScale3D(r0_81(r592_0, r592_0, 1.0))
                                        r586_32.LastFatScale = r592_0
                                    end
                                end
                            end)
                            -- [REMOVED: Magic Bullet PhysicsAsset hitbox manipulation]
                            local r586_48 = 0
                            pcall(function()
                                r586_48 = r580_3:GetDistanceTo(r586_23) / 100
                            end)
                            local r586_49, r586_50 = 100, 100
                            local r586_51 = _G.LexusConfig.EspLoai5 or _G.LexusConfig.EspVipPro or _G.LexusConfig.EspVip
                            local r586_52
                            if r586_51 then
                                pcall(function()
                                    if r586_23.Health then
                                        r586_49 = r586_23.Health
                                    elseif type(r586_23.GetHealth) == "function" then
                                        r586_49 = r586_23:GetHealth()
                                    end
                                    if r586_23.HealthMax then
                                        r586_50 = r586_23.HealthMax
                                    elseif type(r586_23.GetHealthMax) == "function" then
                                        r586_50 = r586_23:GetHealthMax()
                                    end
                                end)
                                if r586_50 <= 0 then
                                    r586_50 = 100
                                    r586_52 = r586_50
                                else
                                    r586_52 = r586_50
                                end
                            else
                                r586_52 = r586_51
                            end
                            local r586_53 = r586_49 / r586_52
                            if _G.LexusConfig.EspAntenna then
                                pcall(function()
                                    local r597_0 = r580_2
                                    if r580_2 then
                                        r597_0 = r580_2.MyHUD
                                    end
                                    if r0_19(r597_0) and r586_48 <= 400 then
                                        local r597_1, r597_2, r597_3 = 8, 1000, 105
                                        local r597_4 = r597_3 + r597_1 * r597_2
                                        for r597_5 = 1, r597_1 do
                                            local r597_6 = r597_3 + r597_5 * r597_2
                                            local r597_7 = { X = 0, Y = 0, Z = r597_6 }
                                            local r597_8 = { X = 0, Y = 0, Z = r597_6 }
                                            local r597_9 = { R = 0, G = 255, B = 0, A = 255 }
                                            r597_0:AddDebugText("|", r586_23, 0.06, r597_7, r597_8, r597_9, true, false, true, nil, 1.2, true)
                                        end
                                        local r597_10 = { X = 0, Y = 0, Z = r597_4 + 60 }
                                        local r597_11 = { X = 0, Y = 0, Z = r597_4 + 60 }
                                        local r597_12 = { R = 0, G = 255, B = 0, A = 255 }
                                        r597_0:AddDebugText("I", r586_23, 0.06, r597_10, r597_11, r597_12, true, false, true, nil, 1.5, true)
                                    end
                                end)
                            end
                            if _G.LexusConfig.EspLoai6 then
                                pcall(function()
                                    local r598_0 = os.clock()
                                    if r586_32.LastEsp6Time == nil or r598_0 - r586_32.LastEsp6Time >= 0.05 then
                                        r586_32.LastEsp6Time = r598_0
                                        local r598_1 = r580_2
                                        if r580_2 then
                                            r598_1 = r580_2.MyHUD
                                        end
                                        if r0_19(r598_1) and r0_19(r586_29) and r586_41 and r586_48 <= 250 and type(r586_29.GetSocketLocation) == "function" then
                                            for r598_2, r598_3 in ipairs({
                                                "head",
                                                "neck_01",
                                                "pelvis",
                                                "upperarm_r",
                                                "lowerarm_r",
                                                "hand_r",
                                                "upperarm_l",
                                                "lowerarm_l",
                                                "hand_l",
                                                "thigh_l",
                                                "calf_l",
                                                "foot_l",
                                                "thigh_r",
                                                "calf_r",
                                                "foot_r"
                                            }) do
                                                if not (r586_48 > 50 and r598_3 ~= "head" and r598_3 ~= "pelvis" and r598_3 ~= "neck_01") then
                                                    local r598_4 = r586_29:GetSocketLocation(r598_3)
                                                    if r598_4 then
                                                        local r598_5 = {
                                                            X = r598_4.X - r586_41.X,
                                                            Y = r598_4.Y - r586_41.Y,
                                                            Z = r598_4.Z - r586_41.Z
                                                        }
                                                        local r598_6 = "▪"
                                                        local r598_7 = 0.25
                                                        local r598_8 = {
                                                            R = 0,
                                                            G = 255,
                                                            B = 255,
                                                            A = 255
                                                        }
                                                        local r598_9, r598_10, r598_11
                                                        if r598_3 == "head" then
                                                            local r598_12 = "●"
                                                            local r598_13 = 0.45
                                                            local r598_14 = {
                                                                R = 255,
                                                                G = 0,
                                                                B = 0,
                                                                A = 255
                                                            }
                                                            r598_9 = r598_12
                                                            r598_10 = r598_13
                                                            r598_11 = r598_14
                                                        elseif r598_3 == "pelvis" then
                                                            local r598_15 = "▪"
                                                            local r598_16 = 0.35
                                                            local r598_17 = {
                                                                R = 255,
                                                                G = 255,
                                                                B = 0,
                                                                A = 255
                                                            }
                                                            r598_9 = r598_15
                                                            r598_10 = r598_16
                                                            r598_11 = r598_17
                                                        elseif r598_3 == "neck_01" then
                                                            local r598_18 = "▪"
                                                            local r598_19 = 0.35
                                                            local r598_20 = {
                                                                R = 255,
                                                                G = 255,
                                                                B = 0,
                                                                A = 255
                                                            }
                                                            r598_9 = r598_18
                                                            r598_10 = r598_19
                                                            r598_11 = r598_20
                                                        else
                                                            r598_9 = r598_6
                                                            r598_10 = r598_7
                                                            r598_11 = r598_8
                                                        end
                                                        r598_1:AddDebugText(r598_9, r586_23, 0.06, r598_5, r598_5, r598_11, true, false, true, nil, r598_10, true)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end)
                            end
                            if _G.LexusConfig.EspLoai7 then
                                pcall(function()
                                    local r599_0 = r580_2
                                    if r580_2 then
                                        r599_0 = r580_2.MyHUD
                                    end
                                    if r0_19(r599_0) then
                                        if r586_48 <= 600 then
                                            if r586_44 then
                                                r586_18 = r586_18 + 1
                                            else
                                                r586_17 = r586_17 + 1
                                            end
                                        end
                                        if r586_48 <= 400 then
                                            local r599_1 = ""
                                            if _G.LexusConfig.Esp7_TuThe then
                                                local r599_2 = nil
                                                if r586_23.PoseState then
                                                    r599_2 = r586_23.PoseState
                                                elseif type(r586_23.GetPoseState) == "function" then
                                                    r599_2 = r586_23:GetPoseState()
                                                end
                                                if r599_2 == 0 or r599_2 == "Stand" then
                                                    r599_1 = "Standing"
                                                elseif r599_2 == 1 or r599_2 == "Crouch" then
                                                    r599_1 = "Crouching"
                                                elseif r599_2 == 2 or r599_2 == "Prone" then
                                                    r599_1 = "Prone"
                                                else
                                                    r599_1 = "Standing"
                                                end
                                            end
                                            local r599_3 = _G.LexusConfig
                                            local r599_4
                                            if r599_3.Esp7_VuKhi then
                                                local r599_5 = os.clock()
                                                if r586_32.AK_LAST_WEP_TIME == nil or r586_32.AK_LAST_WEP_TIME + 1.5 < r599_5 then
                                                    local r599_6
                                                    if r586_23.CurrentWeapon then
                                                        r599_6 = r586_23.CurrentWeapon
                                                    elseif type(r586_23.GetCurrentWeapon) == "function" then
                                                        r599_6 = r586_23:GetCurrentWeapon()
                                                    else
                                                        local r599_7 = r586_23.WeaponManagerComponent
                                                        if r599_7 then
                                                            r599_6 = r586_23.WeaponManagerComponent.CurrentWeaponReplicated
                                                        else
                                                            r599_6 = r599_7
                                                        end
                                                    end
                                                    local r599_8 = "Unarmed"
                                                    if r0_19(r599_6) and type(r599_6.GetWeaponName) == "function" then
                                                        r599_8 = r599_6:GetWeaponName()
                                                    end
                                                    r586_32.AK_CACHED_WEP_NAME = tostring(r599_8)
                                                    r586_32.AK_LAST_WEP_TIME = r599_5
                                                end
                                                if r599_1 == "" then
                                                    local r599_9 = r586_32.AK_CACHED_WEP_NAME
                                                    if r599_9 then
                                                        r599_4 = r599_9
                                                    else
                                                        r599_4 = "Unarmed"
                                                    end
                                                else
                                                    r599_4 = r599_1 .. " - " .. (r586_32.AK_CACHED_WEP_NAME or "Unarmed")
                                                end
                                            end
                                            if r599_4 ~= "" then
                                                local r599_10 = r586_44 and ({
                                                    R = 0,
                                                    G = 255,
                                                    B = 255,
                                                    A = 255
                                                } or { R = 255, G = 255, B = 0, A = 255 }) or {
                                                    R = 255,
                                                    G = 255,
                                                    B = 0,
                                                    A = 255
                                                }
                                                local r599_11 = math.max(0.5, 0.8 - r586_48 / 400)
                                                local r599_12 = { X = 0, Y = 0, Z = 100 }
                                                local r599_13 = { X = 0, Y = 0, Z = 100 }
                                                r599_0:AddDebugText(r599_4, r586_23, 0.06, r599_12, r599_13, r599_10, true, false, true, nil, r599_11, true)
                                            end
                                        end
                                    end
                                end)
                            end
                            if r586_51 then
                                pcall(function()
                                    local r600_0 = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
                                    local r600_1 = true
                                    if r586_23.HealthStatus then
                                        if r600_0 then
                                            local r600_2 = r600_0.IsHealthStatusAlive
                                            if r600_2 then
                                                local r600_3 = r600_0.IsHealthStatusAlive(r586_23.HealthStatus)
                                                if r600_3 then
                                                    r600_1 = r600_3
                                                else
                                                    r600_1 = false
                                                end
                                            else
                                                r600_1 = r600_2
                                            end
                                        else
                                            r600_1 = r600_0
                                        end
                                    end
                                    local r600_4
                                    if r600_1 then
                                        local r600_5 = r586_21
                                        if r600_5 then
                                            local r600_6 = r586_41
                                            if r600_6 then
                                                if r600_0 then
                                                    local r600_7 = r600_0.IsVector
                                                    if r600_7 then
                                                        local r600_8 = r600_0.IsVector(r586_41)
                                                        if r600_8 then
                                                            local r600_9 = r600_0.IsVector(r586_21)
                                                            if r600_9 then
                                                                local r600_10 = r586_41.Z
                                                                if r600_10 >= 150000 then
                                                                    r600_4 = false
                                                                else
                                                                    local r600_11 = r0_81.Dist2D(r586_21, r586_41)
                                                                    if r600_11 > 50000 then
                                                                        r600_4 = false
                                                                    else
                                                                        r600_4 = r600_1
                                                                    end
                                                                end
                                                            else
                                                                r600_4 = r600_9
                                                            end
                                                        else
                                                            r600_4 = r600_8
                                                        end
                                                    else
                                                        r600_4 = r600_7
                                                    end
                                                else
                                                    r600_4 = r600_0
                                                end
                                            else
                                                r600_4 = r600_6
                                            end
                                        else
                                            r600_4 = r600_5
                                        end
                                    else
                                        r600_4 = r600_1
                                    end
                                    if r600_4 then
                                        if r586_23.Replay_IsEnemyFrameUIExisted and not r586_23:Replay_IsEnemyFrameUIExisted() then
                                            r586_23:Replay_CreateEnemyFrameUI(true, true)
                                        end
                                        if r586_23.Replay_SetVisiableOfFrameUI then
                                            r586_23:Replay_SetVisiableOfFrameUI(true)
                                        end
                                        if r586_23.Replay_UpdateEnemyFrameUI then
                                            r586_23:Replay_UpdateEnemyFrameUI(r586_53)
                                        end
                                        local r600_12 = r586_23.EnemyFrameUI
                                        local r600_13
                                        if r600_12 then
                                            r600_13 = r600_12
                                        elseif type(r586_23.GetEnemyFrameUI) == "function" then
                                            r600_13 = r586_23:GetEnemyFrameUI()
                                        else
                                            r600_13 = false
                                        end
                                        if r0_19(r600_13) and r586_32.LastFrameUIState ~= "VISIBLE" then
                                            if type(r600_13.SetVisibility) == "function" then
                                                r600_13:SetVisibility(0)
                                            end
                                            if type(r600_13.SetHiddenInGame) == "function" then
                                                r600_13:SetHiddenInGame(false)
                                            end
                                            r586_32.LastFrameUIState = "VISIBLE"
                                        end
                                    end
                                end)
                            else
                                pcall(function()
                                    if r586_23.Replay_SetVisiableOfFrameUI then
                                        r586_23:Replay_SetVisiableOfFrameUI(false)
                                    end
                                    local r601_0 = r586_23.EnemyFrameUI
                                    local r601_1
                                    if r601_0 then
                                        r601_1 = r601_0
                                    elseif type(r586_23.GetEnemyFrameUI) == "function" then
                                        r601_1 = r586_23:GetEnemyFrameUI()
                                    else
                                        r601_1 = false
                                    end
                                    if r0_19(r601_1) and r586_32.LastFrameUIState ~= "HIDDEN" then
                                        if type(r601_1.SetVisibility) == "function" then
                                            r601_1:SetVisibility(2)
                                        end
                                        if type(r601_1.SetHiddenInGame) == "function" then
                                            r601_1:SetHiddenInGame(true)
                                        end
                                        r586_32.LastFrameUIState = "HIDDEN"
                                    end
                                end)
                            end
                            if _G.LexusConfig.EspVipPro then
                                pcall(function()
                                    local r602_0 = r580_2
                                    if r580_2 then
                                        r602_0 = r580_2.MyHUD
                                    end
                                    if r0_19(r602_0) and r602_0.AddDebugText and r586_48 <= 400 then
                                        local r602_1 = math.max(0.55, 0.95 - r586_48 / 400)
                                        local r602_2 = r586_53
                                        local r602_3 = r586_49 <= 0 and r586_23.HealthStatus == 1
                                        local r602_4 = { R = 0, G = 255, B = 0, A = 255 }
                                        local r602_5
                                        if r602_2 < 0.3 then
                                            r602_5 = { R = 255, G = 0, B = 0, A = 255 }
                                        elseif r602_2 < 0.7 then
                                            r602_5 = { R = 255, G = 255, B = 0, A = 255 }
                                        end
                                        local r602_6 = r602_3 and { R = 255, G = 0, B = 0, A = 255 }
                                        if _G.LexusConfig.Esp3ShowName then
                                            local r602_7 = "Enemy"
                                            pcall(function()
                                                if r586_23.PlayerName then
                                                    r602_7 = r586_23.PlayerName
                                                elseif type(r586_23.GetPlayerName) == "function" then
                                                    r602_7 = r586_23:GetPlayerName()
                                                end
                                            end)
                                            local r602_8
                                            if r602_7 == "" then
                                                r602_7 = "Enemy"
                                                r602_8 = r602_7
                                            else
                                                r602_8 = r602_7
                                            end
                                            local r602_9
                                            if r602_3 then
                                                r602_7 = "KNOCK: " .. r602_8
                                                r602_9 = r602_7
                                            else
                                                r602_9 = r602_3
                                            end
                                            local r602_10 = { X = 0, Y = 0, Z = -370 }
                                            local r602_11 = { X = 0, Y = 0, Z = -370 }
                                            local r602_12 = { R = 255, G = 255, B = 255, A = 255 }
                                            r602_0:AddDebugText(r602_9, r586_23, 0.06, r602_10, r602_11, r602_12, true, false, true, nil, r602_1 * 1.1, true)
                                        end
                                        if _G.LexusConfig.Esp3ShowHP then
                                            if r602_3 then
                                                local r602_13 = { X = 0, Y = -115, Z = 50 }
                                                local r602_14 = { X = 0, Y = -115, Z = 50 }
                                                local r602_15 = { R = 255, G = 0, B = 0, A = 255 }
                                                r602_0:AddDebugText("DOWN", r586_23, 0.06, r602_13, r602_14, r602_15, true, false, true, nil, r602_1 * 1.0, true)
                                            else
                                                local r602_16 = 6
                                                local r602_17 = math.floor(r602_2 * r602_16)
                                                local r602_18 = 20
                                                local r602_19 = 10.0 * r602_1
                                                for r602_20 = 1, r602_16 do
                                                    local r602_21 = r602_20 <= r602_17 and (r602_6 or {
                                                        R = 30,
                                                        G = 30,
                                                        B = 30,
                                                        A = 180
                                                    }) or { R = 30, G = 30, B = 30, A = 180 }
                                                    local r602_22 = {
                                                        X = 0,
                                                        Y = -115,
                                                        Z = r602_18 + r602_20 * r602_19
                                                    }
                                                    local r602_23 = {
                                                        X = 0,
                                                        Y = -115,
                                                        Z = r602_18 + r602_20 * r602_19
                                                    }
                                                    r602_0:AddDebugText("█", r586_23, 0.06, r602_22, r602_23, r602_21, true, false, true, nil, r602_1 * 1.2, true)
                                                end
                                                local r602_24 = string.format("%d%%", math.floor(r602_2 * 100))
                                                local r602_25 = { X = 0, Y = -60, Z = r602_18 - 12 }
                                                local r602_26 = { X = 0, Y = -60, Z = r602_18 - 12 }
                                                r602_0:AddDebugText(r602_24, r586_23, 0.06, r602_25, r602_26, r602_6, true, false, true, nil, r602_1 * 0.8, true)
                                            end
                                        end
                                    end
                                end)
                            end
                            if _G.LexusConfig.EspDistance then
                                pcall(function()
                                    local r604_0 = r580_2
                                    if r580_2 then
                                        r604_0 = r580_2.MyHUD
                                    end
                                    if r0_19(r604_0) and r604_0.AddDebugText and r586_48 <= 400 then
                                        local r604_1 = math.max(0.55, 0.95 - r586_48 / 400)
                                        local r604_2 = "[%dm]"
                                        local r604_3 = { X = 0, Y = 115, Z = 20 }
                                        local r604_4 = { X = 0, Y = 115, Z = 20 }
                                        local r604_5 = { R = 0, G = 200, B = 255, A = 255 }
                                        r604_0:AddDebugText(string.format(r604_2, math.floor(r586_48)), r586_23, 0.06, r604_3, r604_4, r604_5, true, false, true, nil, r604_1 * 1.5, true)
                                    end
                                end)
                            end
                            if _G.LexusConfig.EspVip then
                                if r586_32.hpMark == nil then
                                    r586_32.hpMark = r0_54(1006, r0_81(0, 0, 0), 0, "", 4, r586_23)
                                end
                                if r586_32.distMark == nil then
                                    r586_32.distMark = r0_54(9999, r0_81(0, 0, 0), 0, "", 4, r586_23)
                                end
                            else
                                if r586_32.hpMark then
                                    r0_55(r586_32.hpMark)
                                    r586_32.hpMark = nil
                                end
                                if r586_32.distMark then
                                    r0_55(r586_32.distMark)
                                    r586_32.distMark = nil
                                end
                            end
                            if _G.LexusConfig.EspLoai8 then
                                if r586_32.hpMark8 == nil then
                                    r586_32.hpMark8 = r0_54(1006, r0_81(0, 0, 0), 0, "", 4, r586_23)
                                end
                            elseif r586_32.hpMark8 then
                                r0_55(r586_32.hpMark8)
                                r586_32.hpMark8 = nil
                            end
                            if _G.LexusConfig.EspRadar then
                                if not r586_32.radarMark or r586_32.radarMark == 0 then
                                    r586_32.radarMark = r0_54(8888, r0_81(0, 0, 0), 0, "", 4, r586_23)
                                end
                            elseif r586_32.radarMark and r586_32.radarMark ~= 0 then
                                r0_55(r586_32.radarMark)
                                r586_32.radarMark = nil
                            end
                            if _G.LexusConfig.EspOutline then
                                pcall(function()
                                    local r605_0 = _G.LexusState
                                    local r605_1 = r605_0.CustomTextData.OutlineColor
                                    if not r605_1 then
                                        r605_1 = 4
                                    end
                                    local r605_2 = _G.LexusConfig.OutlineThickness or 10
                                    local r605_3 = string.format("%d_%d", r605_2, r605_1)
                                    local r605_4 = r0_63(r586_23, r586_32)
                                    local r605_5 = #r605_4
                                    if not (r586_32.OutlineState == r605_3 and r586_32.LastMeshCountOutline == r605_5) then
                                        local r605_6 = 255
                                        local r605_7 = 255
                                        local r605_8 = 0
                                        local r605_9, r605_10, r605_11
                                        if r605_1 == 1 then
                                            local r605_12 = 255
                                            local r605_13 = 0
                                            local r605_14 = 0
                                            r605_9 = r605_12
                                            r605_10 = r605_13
                                            r605_11 = r605_14
                                        elseif r605_1 == 2 then
                                            local r605_15 = 0
                                            local r605_16 = 255
                                            local r605_17 = 0
                                            r605_9 = r605_15
                                            r605_10 = r605_16
                                            r605_11 = r605_17
                                        elseif r605_1 == 3 then
                                            local r605_18 = 0
                                            local r605_19 = 0
                                            local r605_20 = 255
                                            r605_9 = r605_18
                                            r605_10 = r605_19
                                            r605_11 = r605_20
                                        elseif r605_1 == 4 then
                                            local r605_21 = 255
                                            local r605_22 = 255
                                            local r605_23 = 0
                                            r605_9 = r605_21
                                            r605_10 = r605_22
                                            r605_11 = r605_23
                                        elseif r605_1 == 5 then
                                            local r605_24 = 255
                                            local r605_25 = 0
                                            local r605_26 = 255
                                            r605_9 = r605_24
                                            r605_10 = r605_25
                                            r605_11 = r605_26
                                        elseif r605_1 == 6 then
                                            local r605_27 = 255
                                            local r605_28 = 255
                                            local r605_29 = 255
                                            r605_9 = r605_27
                                            r605_10 = r605_28
                                            r605_11 = r605_29
                                        else
                                            r605_9 = r605_6
                                            r605_10 = r605_7
                                            r605_11 = r605_8
                                        end
                                        local r605_30 = 80.0
                                        local r605_31 = import("LinearColor")
                                        if not r605_31 then
                                            local r605_32
                                            r605_31 = r605_32.FLinearColor
                                        end
                                        local r605_33 = r605_31 and (r605_31(r605_9 / 255 * r605_30, r605_10 / 255 * r605_30, r605_11 / 255 * r605_30, 1.0) or {
                                            R = r605_9 * r605_30,
                                            G = r605_10 * r605_30,
                                            B = r605_11 * r605_30,
                                            A = 255
                                        }) or {
                                            R = r605_9 * r605_30,
                                            G = r605_10 * r605_30,
                                            B = r605_11 * r605_30,
                                            A = 255
                                        }
                                        for r605_34, r605_35 in ipairs(r605_4) do
                                            if r0_19(r605_35) then
                                                pcall(function()
                                                    r605_35.UseScopeDistanceCulling = false
                                                    r605_35.PrimitiveShadingStrategy = 1
                                                    r605_35.ShadingRate = 6
                                                end)
                                                if r605_35.SetDrawIdeaOutline then
                                                    r605_35:SetDrawIdeaOutline(true)
                                                    if r605_35.OverrideIdeaOutlineColor then
                                                        r605_35:OverrideIdeaOutlineColor(true, r605_33)
                                                    end
                                                    if r605_35.OverrideIdeaOutlineThickness then
                                                        r605_35:OverrideIdeaOutlineThickness(true, _G.LexusConfig.OutlineThickness)
                                                    end
                                                end
                                            end
                                        end
                                        r586_32.OutlineState = r605_3
                                        r586_32.LastMeshCountOutline = r605_5
                                    end
                                end)
                            else
                                pcall(function()
                                    if r586_32.OutlineState ~= "OFF" then
                                        for r607_0, r607_1 in ipairs(r0_63(r586_23, r586_32)) do
                                            if r0_19(r607_1) then
                                                pcall(function()
                                                    r607_1.PrimitiveShadingStrategy = 0
                                                    r607_1.ShadingRate = 1
                                                end)
                                                if r607_1.SetDrawIdeaOutline then
                                                    r607_1:SetDrawIdeaOutline(false)
                                                end
                                            end
                                        end
                                        r586_32.OutlineState = "OFF"
                                        r586_32.LastMeshCountOutline = 0
                                    end
                                end)
                            end
                        end
                    end
                end
            end
            if _G.LexusConfig.EspLoai7 and _G.LexusConfig.Esp7_SoLuong then
                pcall(function()
                    local r610_0 = r580_1.GetPlayerCharacter()
                    if not slua.isValid(r610_0) then
                        return
                    end
                    local r610_1 = r610_0.TeamID or type(r610_0.GetTeamID) == "function" and r610_0:GetTeamID() or 0
                    local r610_2, r610_3 = 0, 9999
                    local r610_4 = {}
                    if r580_1.GetAllPlayerCharacters then
                        r610_4 = r580_1.GetAllPlayerCharacters()
                    elseif r580_1.GameCharacters then
                        for r610_5, r610_6 in pairs(r580_1.GameCharacters) do
                            table.insert(r610_4, r610_6)
                        end
                    end
                    for r610_7, r610_8 in pairs(r610_4) do
                        if slua.isValid(r610_8) and r610_8 ~= r610_0 then
                            local r610_9
                            if r610_8.HealthStatus == nil then
                                if (r610_8.Health or 0) > 0 then
                                    r610_9 = true
                                elseif type(r610_8.IsAlive) == "function" then
                                    r610_9 = r610_8:IsAlive()
                                else
                                    r610_9 = false
                                end
                            else
                                r610_9 = r610_8.HealthStatus ~= 2
                            end
                            if r610_9 then
                                local r610_10 = r610_8.TeamID or type(r610_8.GetTeamID) == "function" and r610_8:GetTeamID() or 0
                                if r610_10 ~= r610_1 then
                                    r610_2 = r610_2 + 1
                                    local r610_11 = math.floor
                                    local r610_12 = r610_0:GetDistanceTo(r610_8)
                                    local r610_13 = r610_11(r610_12 / 100)
                                    if r610_13 < r610_3 then
                                        r610_3 = r610_13
                                    end
                                end
                            end
                        end
                    end
                    local r610_14 = require("client.slua_ui_framework.manager")
                    local r610_15 = r610_14.GetUI(r610_14.UI_Config_InGame.DrawEnemyCountUI)
                    if not r610_15 then
                        r610_14.ShowUI(r610_14.UI_Config_InGame.DrawEnemyCountUI)
                        local r610_16 = r610_14.GetUI
                        local r610_17 = r610_14.UI_Config_InGame
                        r610_15 = r610_16(r610_17.DrawEnemyCountUI)
                    end
                    if r610_15 then
                        local r610_18 = r610_2 > 0 and r610_3 or 0
                        r610_15:SetText(string.format("Nearby Enemies: %d  |  Nearest: %dm", r610_2, r610_18))
                        r610_15:SetVisible(true)
                    end
                end)
            else
                pcall(function()
                    local r611_0 = require("client.slua_ui_framework.manager")
                    local r611_1 = r611_0.GetUI(r611_0.UI_Config_InGame.DrawEnemyCountUI)
                    if r611_1 then
                        r611_1:SetVisible(false)
                    end
                end)
            end
        end)
        return
    end
    if _G.PlayerMapMarker and type(_G.PlayerMapMarker.Stop) == "function" then
        _G.PlayerMapMarker.Stop()
    end
    if _G.RedBoxOverlay and type(_G.RedBoxOverlay.Stop) == "function" then
        _G.RedBoxOverlay.Stop()
    end
    if _G.LexusState.TrackedMarks then
        for r580_9, r580_10 in pairs(_G.LexusState.TrackedMarks) do
            r0_55(r580_9)
        end
    end
    _G.LexusState.TrackedMarks = {}
    for r580_11, r580_12 in pairs(_G.LexusState.EnemyMarks) do
        if r580_12 and r580_12.MIDs then
            for r580_13, r580_14 in pairs(r580_12.MIDs) do
                for r580_15, r580_16 in pairs(r580_14) do
                    r580_14[r580_15] = nil
                end
            end
            r580_12.MIDs = nil
        end
        if r580_12 and r580_12.MIDs_V3 then
            for r580_17, r580_18 in pairs(r580_12.MIDs_V3) do
                for r580_19, r580_20 in pairs(r580_18) do
                    r580_18[r580_19] = nil
                end
            end
        end
        r580_12.MIDs_V3 = nil
    end
    _G.LexusState.EnemyMarks = {}
    _G.LexusState.PrevGraphicsState = {}
end

_ENV._G.LexusState.LoopToken = (_ENV._G.LexusState.LoopToken or 0) + 1
local r0_95 = _ENV._G.LexusState.LoopToken

-- line 5410-5432
-- proto#612 params=0 locals=0 upvalues=2 vararg=false
local function r0_96()
    if not _G.LexusNotifiedPopup then
        pcall(function()
            local r613_0 = require("client.slua.logic.common.logic_common_msg_box")
            if r613_0 and r613_0.Show then
                r613_0.Show(1, "MOD EXPIRED", [[YOUR MOD VERSION HAS EXPIRED!
PLEASE MESSAGE THE ADMIN TO RENEW IT.
Telegram: @ROCKYBHAI711. If someone else sold this to you, you may have been scammed.]], function()
                    local r614_0 = require("client.slua.logic.url.logic_webview_sdk")
                    if r614_0 and r614_0.OpenURL then
                        r614_0:OpenURL("https://t.me/ROCKYBHAI7111")
                    end
                end, function()

                end, "MESSAGE MOD ADMIN", "CLOSE")
                _G.LexusNotifiedPopup = true
            end
        end)
        if not _G.LexusNotifiedPopup then
            local r612_0, r612_1 = pcall(require, "common.time_ticker")
            if r612_0 and r612_1 and r612_1.AddTimerOnce then
                r612_1.AddTimerOnce(2.0, r0_96)
            end
        end
    end
end

-- line 5434-5450
-- proto#616 params=0 locals=0 upvalues=7 vararg=false
local function r0_97()
    if r0_24 then
        if not _G.LexusNotifiedExpire then
            r0_17([[MOD EXPIRED! PLEASE MESSAGE THE ADMIN TO RENEW IT.
Telegram: @ROCKYBHAI711. If someone else sold this to you, you may have been scammed.]])
            _G.LexusNotifiedExpire = true
            r0_96()
        end
        return
    end
    if r0_95 ~= _G.LexusState.LoopToken then
        return
    end
    pcall(r0_94)
    local r616_0, r616_1 = pcall(require, "common.time_ticker")
    if r616_0 and r616_1 and r616_1.AddTimerOnce then
        r616_1.AddTimerOnce(0.01, r0_97)
    end
end

if r0_24 then
    r0_97()
else
    r0_97()
    r0_17("You are using my VVIP 4 mod. If you do not have a key, message me on Telegram: @ROCKYBHAI711. If someone else sold this to you, you may have been scammed.")
end

-- line 5459-5479
-- proto#617 params=0 locals=1 upvalues=2 vararg=false
local function r0_98()
    if r0_24 then
        return
    end
    pcall(function()
        if _G.StartBypass_VIP_v3 then
            _G.StartBypass_VIP_v3()
        end
    end)
    local r617_0 = package.loaded["GameLua.GameCore.Data.GameplayData"]
    if not r617_0 then
        r617_0 = require("GameLua.GameCore.Data.GameplayData")
    end
    if not r617_0 then
        return
    end
    pcall(function()
        local r619_0 = r617_0.GetPlayerCharacter
        if r619_0 then
            r619_0 = r617_0.GetPlayerCharacter()
        end
        if slua.isValid(r619_0) and r619_0.bHasShownDevNotice == nil then
            r619_0.bHasShownDevNotice = false
            r619_0.bHasShownExpiredNotice = false
            r619_0.bIsDeadFlag = false
        end
    end)
end

if not r0_24 then
    _ENV.pcall(function()
        local r620_0 = require("common.time_ticker")
        r620_0.AddTimerOnce(0.5, r0_98)
    end)
end
local r0_99 = _ENV.require("class")(_ENV.require("GameLua.GameCore.Framework.CharacterBase"), nil, r0_0)
local r0_100 = _ENV.require("combine_class")
local r0_101 = r0_100.DeclareFeature
local r0_102 = {
    {
        SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature"
    },
    { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
    { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    {
        FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature"
    },
    { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    {
        BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"
    },
    {
        CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
    },
    { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" },
    {
        SpiderSenseFootprintFeature = "GameLua.Mod.Library.GamePlay.Feature.SpiderSenseFootprintFeature"
    },
    {
        GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature"
    }
}
return r0_101(r0_99, r0_102, "BRPlayerCharacterBase")
