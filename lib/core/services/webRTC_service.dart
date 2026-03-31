import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;

  MediaStream? localStream;
  RTCPeerConnection? peerConnection;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _callSub;
  StreamSubscription? _iceSub;

  WebRTCService(this.localRenderer, this.remoteRenderer);

  /// INIT
  Future<void> init() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    /// Get camera + mic
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'}
    });

    localRenderer.srcObject = localStream;

    /// Create PeerConnection
    peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    });

    /// Add local tracks
    for (var track in localStream!.getTracks()) {
      peerConnection!.addTrack(track, localStream!);
    }

    /// Remote stream
    peerConnection!.onTrack = (event) {
      print("🔥 Remote track received");
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
      }
    };
  }

  /// ================= CALLER =================

  Future<void> createOffer(String callId) async {
    final callDoc = _firestore.collection('calls').doc(callId);

    /// Create offer
    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    /// Save offer in Firestore
    await callDoc.update({
      'offer': offer.toMap(),
    });

    /// Listen for answer
    _callSub = callDoc.snapshots().listen((doc) async {
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      if (data['answer'] != null) {
        final answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        await peerConnection!.setRemoteDescription(answer);
        print("Offer: ${data['offer']}");
      }
    });

    /// Send ICE candidates
    peerConnection!.onIceCandidate = (candidate) {
      callDoc.collection('callerCandidates').add(candidate.toMap());
    };

    /// Listen remote ICE
    _iceSub = callDoc.collection('receiverCandidates').snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        peerConnection!.addCandidate(
          RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          ),
        );
      }
    });
  }

  /// ================= RECEIVER =================

  Future<void> answerCall(String callId) async {
    final callDoc = _firestore.collection('calls').doc(callId);

    final callData = await callDoc.get();
    final data = callData.data();

    if (data == null || data['offer'] == null) return;

    /// Set remote description (offer)
    final offer = RTCSessionDescription(
      data['offer']['sdp'],
      data['offer']['type'],
    );

    await peerConnection!.setRemoteDescription(offer);

    /// Create answer
    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    /// Save answer
    await callDoc.update({
      'answer': answer.toMap(),
      'status': 'accepted',
    });

    /// Send ICE
    peerConnection!.onIceCandidate = (candidate) {
      callDoc.collection('receiverCandidates').add(candidate.toMap());
    };

    /// Listen caller ICE
    _iceSub = callDoc.collection('callerCandidates').snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print("Answer: ${data['answer']}");
        peerConnection!.addCandidate(
          RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          ),
        );
      }
    });
  }

  /// ================= CAMERA =================

  Future<void> switchCamera() async {
    final videoTrack = localStream?.getVideoTracks().first;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
    }
  }

  /// ================= CLEANUP =================

  Future<void> dispose() async {
    await _callSub?.cancel();
    await _iceSub?.cancel();

    await localStream?.dispose();
    await peerConnection?.close();

    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }
}
