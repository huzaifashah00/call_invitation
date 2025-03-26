import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../utils/zegocloud_token.dart';
import '../../../zego_live_streaming_manager.dart';
import '../../../zego_sdk_key_center.dart';
import '../normal/live_command.dart';

class ZegoSwipingRoomController {
  final _data = ZegoSwipingRoomControllerData();
  var roomCommandsNotifier = ValueNotifier<Map<String, ZegoLivePageCommand>>({});

  ZegoLiveStreamingManager? liveStreamingManager;

  void init({
    required ValueNotifier<Map<String, ZegoLivePageCommand>> roomCommandsNotifier,
    required ZegoLiveStreamingManager liveStreamingManager,
  }) {
    if (_data.init) {
      debugPrint('room controller, init before');

      return;
    }

    this.roomCommandsNotifier = roomCommandsNotifier;
    this.liveStreamingManager = liveStreamingManager;

    debugPrint('room controller, init');

    _data
      ..init = true
      ..roomLoginNotifier ??= ZegoRoomLoginNotifier()
      ..roomLogoutNotifier ??= ZegoRoomLogoutNotifier();

    _data.roomLogoutNotifier?.notifier.addListener(_onLogoutRoomStateChanged);
    _data.roomLoginNotifier?.notifier.addListener(_onLoginRoomStateChanged);

    _data.currentRoomLoginDone.addListener(_onCurrentRoomLoginStateUpdated);
    _data.currentRoomLogoutDone.addListener(_onCurrentRoomLogoutStateUpdated);
  }

  void uninit() {
    if (!_data.init) {
      debugPrint('room controller, not need uninit');

      return;
    }

    debugPrint('room controller, uninit');

    _data.init = false;

    _data.roomLoginNotifier?.notifier.removeListener(_onLoginRoomStateChanged);
    _data.roomLogoutNotifier?.notifier.removeListener(_onLogoutRoomStateChanged);
    _data.currentRoomLoginDone.removeListener(_onCurrentRoomLoginStateUpdated);
    _data.currentRoomLogoutDone.removeListener(_onCurrentRoomLogoutStateUpdated);

    if (currentRoomID.isNotEmpty) {
      liveStreamingManager?.leaveRoom();
    }

    liveStreamingManager = null;
  }

  String get currentRoomID => _data.currentRoomID;

  ZIMService get zimService => ZEGOSDKManager().zimService;

  ExpressService get expressService => ZEGOSDKManager().expressService;

  set currentRoomID(String value) {
    debugPrint('room controller, set current room id:$value');
    _data.currentRoomID = value;
  }

  Future<bool> joinRoom(String roomID) async {
    if (roomID.isEmpty) {
      debugPrint('room controller, room id $currentRoomID is empty');
      return false;
    }

    if (roomID == _data.currentRoomID) {
      debugPrint('room controller, current room id $currentRoomID is same');
      return false;
    }

    if (_data.currentRoomID.isNotEmpty && !_data.currentRoomLoginDone.value) {
      debugPrint('room $currentRoomID is not login done, pending room id:$roomID');

      _data.pendingRoomID = roomID;
      return false;
    }
    if (!_data.currentRoomLogoutDone.value) {
      debugPrint('room $currentRoomID is not logout done, pending room id:$roomID');

      _data.pendingRoomID = roomID;
      return false;
    }

    currentRoomID = roomID;
    _data.currentRoomLoginDone.value = false;
    _data.roomLoginNotifier?.resetCheckingData(currentRoomID);

    return _joinRoom();
  }

  Future<bool> _joinRoom() async {
    String? token;
    if (kIsWeb) {
      // ! ** Warning: ZegoTokenUtils is only for use during testing. When your application goes live,
      // ! ** tokens must be generated by the server side. Please do not generate tokens on the client side!
      token = ZegoTokenUtils.generateToken(
        SDKKeyCenter.appID,
        SDKKeyCenter.serverSecret,
        ZEGOSDKManager().currentUser!.userID,
      );
    }

    roomCommandsNotifier.value[currentRoomID]?.registerEvent();

    return ZEGOSDKManager().loginRoom(_data.currentRoomID, ZegoScenario.Broadcast, token: token).then(
      (value) {
        if (value.errorCode != 0) {
          debugPrint('Login room failed: ${value.errorCode}');
        }

        return value.errorCode == 0;
      },
    );
  }

  Future<bool> switchRoom(String roomID) async {
    if (roomID == _data.currentRoomID) {
      debugPrint('room controller, room id $currentRoomID is empty');
      return true;
    }

    if (_data.currentRoomLoginDone.value) {
      debugPrint('room controller, previous room login, leave pending $roomID');
      _data.pendingRoomID = roomID;

      return leaveRoom();
    } else if (_data.currentRoomLogoutDone.value) {
      debugPrint('room controller, switch to $roomID');

      return joinRoom(roomID);
    }

    debugPrint('room controller, switch pending $roomID');
    _data.pendingRoomID = roomID;

    return true;
  }

  Future<bool> leaveRoom() async {
    if (!_data.currentRoomLoginDone.value) {
      debugPrint('room controller, $currentRoomID not login done');

      return false;
    }

    debugPrint('room controller, $currentRoomID leave');

    _data.roomLogoutNotifier?.resetCheckingData(currentRoomID);
    _data.currentRoomLogoutDone.value = false;

    roomCommandsNotifier.value[currentRoomID]?.unregisterEvent();

    await liveStreamingManager?.leaveRoom();

    return true;
  }
}

class ZegoSwipingRoomControllerData {
  bool init = false;

  /// pending room id if try switch room in join process
  String pendingRoomID = '';

  ///
  String currentRoomID = '';
  var currentRoomLoginDone = ValueNotifier<bool>(false);
  var currentRoomLogoutDone = ValueNotifier<bool>(true);

  ///
  ZegoRoomLoginNotifier? roomLoginNotifier;
  ZegoRoomLogoutNotifier? roomLogoutNotifier;
}

extension ZegoSwipingRoomControllerEvent on ZegoSwipingRoomController {
  void _onLoginRoomStateChanged() {
    final expressDone = expressService.currentRoomID == currentRoomID && ZegoRoomStateChangedReason.Logined == expressService.currentRoomState;

    debugPrint('room controller, swiping page, on room state changed, '
        'target room id:$currentRoomID, '
        'express room id:${expressService.currentRoomID}, '
        'express room state:${expressService.currentRoomState}, ');

    final zimDone = zimService.currentRoomID == currentRoomID && ZIMRoomState.connected == zimService.currentRoomState;
    debugPrint('room controller, swiping page, on room state changed, '
        'ZIM room id:${zimService.currentRoomID}, '
        'ZIM room state:${zimService.currentRoomState},');

    debugPrint('swiping page, on room state changed, express done:$expressDone, ZIM done:$zimDone');
    if (expressDone && zimDone) {
      _data.currentRoomLoginDone.value = true;
    }
  }

  void _onLogoutRoomStateChanged() {
    debugPrint('swiping loading, room ${_data.roomLogoutNotifier?.checkingRoomID} state changed, logout:${_data.roomLogoutNotifier?.value}');

    if (_data.roomLogoutNotifier?.value ?? false) {
      debugPrint('swiping loading, room ${_data.roomLogoutNotifier?.checkingRoomID} had logout..');

      _data.currentRoomLogoutDone.value = true;
    }
  }

  Future<void> _onCurrentRoomLoginStateUpdated() async {
    final value = _data.currentRoomLoginDone.value;
    debugPrint('room controller, _onCurrentRoomLoginStateUpdated, '
        '${_data.currentRoomID} $value');

    if (!value) {
      return;
    }

    if (_data.pendingRoomID.isNotEmpty) {
      /// pending room, leave & join
      await leaveRoom();
    }
  }

  void _onCurrentRoomLogoutStateUpdated() {
    final value = _data.currentRoomLogoutDone.value;
    debugPrint('room controller, _onCurrentRoomLogoutStateUpdated, '
        '${_data.currentRoomID} $value');

    if (!value) {
      return;
    }

    currentRoomID = '';

    if (_data.pendingRoomID.isNotEmpty) {
      final pendingRoomID = _data.pendingRoomID;
      _data.pendingRoomID = '';
      joinRoom(pendingRoomID);
    }
  }
}
