import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:spiko/core/enums/call_ui_enums.dart';
import 'package:spiko/core/services/webrtc_service.dart';
import 'package:spiko/core/utils/call_status.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final String receiverId;
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.callId,
    required this.receiverId,
    required this.isCaller,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final local = RTCVideoRenderer();
  final remote = RTCVideoRenderer();

  late WebRTCService webrtc;
  StreamSubscription? sub;

  bool muted = false;
  bool cameraOff = false;
  bool isFrontCamera = true;

  CallUIState uiState = CallUIState.connecting;

  @override
  void initState() {
    super.initState();
    initAll();
  }

  Future<void> initAll() async {
    webrtc = WebRTCService(local, remote);

    await webrtc.init();

    if (widget.isCaller) {
      await webrtc.createOffer(widget.callId.toString());
    } else {
      await webrtc.answerCall(widget.callId);
    }

    listenStatus();
    setState(() => uiState = CallUIState.ringing);
  }

  void listenStatus() {
    sub = FirebaseFirestore.instance.collection('calls').doc(widget.callId).snapshots().listen((doc) {
      if (!doc.exists) return;

      final status = doc['status'];

      if (status == CallStatus.connected) {
        setState(() => uiState = CallUIState.connected);
      }

      if (status == CallStatus.ended || status == CallStatus.rejected) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> endCall() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('calls').doc(widget.callId);

      final doc = await docRef.get();
      if (!doc.exists) return;

      await docRef.update({'status': CallStatus.ended});
    } catch (e) {
      debugPrint("End call error: $e");
    }
  }

  void toggleMute() {
    muted = !muted;
    webrtc.localStream?.getAudioTracks().forEach((t) => t.enabled = !muted);
    setState(() {});
  }

  void toggleCamera() {
    cameraOff = !cameraOff;
    webrtc.localStream?.getVideoTracks().forEach((t) => t.enabled = !cameraOff);
    setState(() {});
  }

  Future<void> switchCamera() async {
    isFrontCamera = !isFrontCamera;
    await webrtc.switchCamera();
    setState(() {});
  }

  String getStatusText() {
    switch (uiState) {
      case CallUIState.connecting:
        return "Connecting...";
      case CallUIState.ringing:
        return widget.isCaller ? "Ringing..." : "Incoming Call...";
      case CallUIState.connected:
        return "Connected";
      case CallUIState.ended:
        return "Call ended";
    }
  }

  @override
  void dispose() {
    sub?.cancel();
    webrtc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(
              remote,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          Positioned(
            right: 20,
            bottom: 120,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: cameraOff
                    ? const Center(
                        child: Icon(
                          Icons.account_circle,
                          color: Colors.white,
                          size: 40,
                        ),
                      )
                    : RTCVideoView(
                        local,
                        mirror: isFrontCamera,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: 20,
            child: Text(
              getStatusText(),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          Positioned(
            top: 80,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: IconButton(
                onPressed: switchCamera,
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "mute",
                  backgroundColor: Colors.grey.shade800,
                  onPressed: toggleMute,
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                ),
                FloatingActionButton(
                  heroTag: "cam",
                  backgroundColor: Colors.grey.shade800,
                  onPressed: toggleCamera,
                  child: Icon(
                    cameraOff ? Icons.videocam_off : Icons.videocam,
                    color: Colors.white,
                  ),
                ),
                FloatingActionButton(
                  heroTag: "end",
                  backgroundColor: Colors.red,
                  onPressed: endCall,
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
