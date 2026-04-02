import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:spiko/core/enums/call_ui_enums.dart';
import 'package:spiko/core/services/webrtc_service.dart';
import 'package:spiko/core/utils/call_status.dart';

class CallProvider extends ChangeNotifier {
  final String callId;
  final bool isCaller;

  CallProvider({required this.callId, required this.isCaller});

  final RTCVideoRenderer local = RTCVideoRenderer();
  final RTCVideoRenderer remote = RTCVideoRenderer();

  late WebRTCService webrtc;

  StreamSubscription? sub;
  Timer? callTimer;

  int seconds = 0;

  bool muted = false;
  bool cameraOff = false;
  bool isFrontCamera = true;

  CallUIState uiState = CallUIState.connecting;

  /// INIT
  Future<void> init() async {
    webrtc = WebRTCService(local, remote);

    await webrtc.init();

    /// Remote connected
    remote.onFirstFrameRendered = () {
      uiState = CallUIState.connected;
      startTimer();
      notifyListeners();
    };

    listenStatus();

    if (isCaller) {
      await webrtc.createOffer(callId);
      uiState = CallUIState.ringing;
    } else {
      await webrtc.answerCall(callId);
      uiState = CallUIState.connecting;
    }

    notifyListeners();

    /// timeout
    Future.delayed(const Duration(seconds: 30), () {
      if ((uiState != CallUIState.connected || uiState != CallUIState.ended) && uiState == CallUIState.ringing) {
        uiState = CallUIState.ended;
        notifyListeners();
      }
    });
  }

  /// LISTEN FIRESTORE
  void listenStatus() {
    sub = FirebaseFirestore.instance.collection('calls').doc(callId).snapshots().listen((doc) {
      if (!doc.exists) return;

      final status = doc['status'];

      switch (status) {
        case CallStatus.ringing:
          uiState = CallUIState.ringing;
          break;

        case CallStatus.connected:
          uiState = CallUIState.connected;
          startTimer(); // ✅ important
          break;

        case CallStatus.ended:
          uiState = CallUIState.ended;
          cleanup();
          break;

        case CallStatus.rejected:
          uiState = CallUIState.rejected;
          cleanup();
          break;
      }

      notifyListeners();
    });
  }

  /// TIMER
  void startTimer() {
    callTimer?.cancel();
    callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;
      notifyListeners();
    });
  }

  String formatTime() {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  /// ACTIONS
  Future<void> endCall() async {
    await FirebaseFirestore.instance.collection('calls').doc(callId).update({'status': CallStatus.ended});
    cleanup();
  }

  void toggleMute() {
    muted = !muted;
    webrtc.localStream?.getAudioTracks().forEach((t) {
      t.enabled = !muted;
    });
    notifyListeners();
  }

  void toggleCamera() {
    cameraOff = !cameraOff;
    webrtc.localStream?.getVideoTracks().forEach((t) {
      t.enabled = !cameraOff;
    });
    notifyListeners();
  }

  Future<void> switchCamera() async {
    isFrontCamera = !isFrontCamera;
    await webrtc.switchCamera();
    notifyListeners();
  }

  bool _isDisposed = false;

  Future<void> cleanup() async {
    if (_isDisposed) return;
    _isDisposed = true;

    try {
      callTimer?.cancel();
      sub?.cancel();

      /// 🛑 Stop ALL tracks (MOST IMPORTANT)
      webrtc.localStream?.getTracks().forEach((track) {
        track.stop();
      });
      webrtc.localStream?.dispose();

      /// ⏳ Small delay (fix for some Android devices)
      await Future.delayed(const Duration(milliseconds: 200));

      /// 🧹 Dispose WebRTC (should close peer connection inside)
      webrtc.dispose();

      /// 🎥 Dispose renderers (AFTER stopping tracks)
      await local.dispose();
      await remote.dispose();

      debugPrint("✅ Call fully cleaned");
    } catch (e) {
      debugPrint("❌ Cleanup error: $e");
    }
  }
}
