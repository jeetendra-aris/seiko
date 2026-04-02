import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:spiko/core/utils/call_status.dart';

// class WebRTCService {
//   final RTCVideoRenderer localRenderer;
//   final RTCVideoRenderer remoteRenderer;
//
//   // Callback to tell the UI to call setState()
//   Function? onRemoteStream;
//
//   MediaStream? localStream;
//   RTCPeerConnection? peerConnection;
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   StreamSubscription? _callSub;
//   StreamSubscription? _iceSub;
//
//   // Buffer to hold candidates that arrive too early
//   List<RTCIceCandidate> _remoteCandidateBuffer = [];
//   bool _isRemoteDescriptionSet = false;
//
//   WebRTCService(this.localRenderer, this.remoteRenderer);
//
//   Future<void> init() async {
//     await localRenderer.initialize();
//     await remoteRenderer.initialize();
//
//     localStream = await navigator.mediaDevices.getUserMedia({
//       'audio': true,
//       'video': {'facingMode': 'user'}
//     });
//
//     localRenderer.srcObject = localStream;
//
//     peerConnection = await createPeerConnection({
//       'iceServers': [
//         {
//           'urls': "stun:stun.relay.metered.ca:80",
//         },
//         {
//           'urls': "turn:global.relay.metered.ca:80",
//           'username': "137d0fd43a8f8845f22171c7",
//           'credential': "+Ta1oGdakqmtAzvZ",
//         },
//         {
//           'urls': "turn:global.relay.metered.ca:80?transport=tcp",
//           'username': "137d0fd43a8f8845f22171c7",
//           'credential': "+Ta1oGdakqmtAzvZ",
//         },
//         {
//           'urls': "turn:global.relay.metered.ca:443",
//           'username': "137d0fd43a8f8845f22171c7",
//           'credential': "+Ta1oGdakqmtAzvZ",
//         },
//         {
//           'urls': "turns:global.relay.metered.ca:443?transport=tcp",
//           'username': "137d0fd43a8f8845f22171c7",
//           'credential': "+Ta1oGdakqmtAzvZ",
//         },
//       ],
//       // 'iceServers': [
//       //   {'urls': 'stun:stun.l.google.com:19302'},
//       //   {'urls': 'stun:stun1.l.google.com:19302'},
//       //
//       // ]
//     });
//
//     // Handle remote track
//     peerConnection!.onTrack = (event) {
//       if (event.streams.isNotEmpty) {
//         remoteRenderer.srcObject = event.streams.first;
//         if (onRemoteStream != null) onRemoteStream!();
//       }
//     };
//
//     // Add local tracks
//     localStream!.getTracks().forEach((track) {
//       peerConnection!.addTrack(track, localStream!);
//     });
//
//     // Connection State Logging
//     peerConnection!.onIceConnectionState = (state) => print("ICE State: $state");
//   }
//
//   /// Adds buffered candidates once the remote description is set
//   Future<void> _processBufferedCandidates() async {
//     for (var candidate in _remoteCandidateBuffer) {
//       await peerConnection!.addCandidate(candidate);
//     }
//     _remoteCandidateBuffer.clear();
//   }
//
//   /// ================= CALLER =================
//   Future<void> createOffer(String callId) async {
//     final callDoc = _firestore.collection('calls').doc(callId);
//
//     peerConnection!.onIceCandidate = (candidate) {
//       callDoc.collection('callerCandidates').add(candidate.toMap());
//     };
//
//     final offer = await peerConnection!.createOffer();
//     await peerConnection!.setLocalDescription(offer);
//     _isRemoteDescriptionSet = true;
//     await callDoc.update({'offer': offer.toMap()});
//
//     _callSub = callDoc.snapshots().listen((doc) async {
//       if (!doc.exists) return;
//       final data = doc.data() as Map<String, dynamic>;
//
//       if (peerConnection?.getRemoteDescription() == null && data['answer'] != null) {
//         var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
//         await peerConnection!.setRemoteDescription(answer);
//         _isRemoteDescriptionSet = true;
//         await _processBufferedCandidates(); // Process any early candidates
//       }
//     });
//
//     _listenForCandidates(callDoc, 'receiverCandidates');
//   }
//
//   /// ================= RECEIVER =================
//   Future<void> answerCall(String callId) async {
//     final callDoc = _firestore.collection('calls').doc(callId);
//     final doc = await callDoc.get();
//     final data = doc.data()!;
//
//     peerConnection!.onIceCandidate = (candidate) {
//       callDoc.collection('receiverCandidates').add(candidate.toMap());
//     };
//
//     final offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
//     await peerConnection!.setRemoteDescription(offer);
//     await _processBufferedCandidates();
//
//     final answer = await peerConnection!.createAnswer();
//     await peerConnection!.setLocalDescription(answer);
//     await callDoc.update({'answer': answer.toMap()});
//
//     _listenForCandidates(callDoc, 'callerCandidates');
//   }
//
//   void _listenForCandidates(DocumentReference callDoc, String collectionName) {
//     _iceSub = callDoc.collection(collectionName).snapshots().listen((snapshot) {
//       for (var change in snapshot.docChanges) {
//         if (change.type == DocumentChangeType.added) {
//           final data = change.doc.data()!;
//           final candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
//
//           if (_isRemoteDescriptionSet) {
//             peerConnection!.addCandidate(candidate);
//           } else {
//             _remoteCandidateBuffer.add(candidate);
//           }
//         }
//       }
//     });
//   }
//
//   Future<void> switchCamera() async {
//     final videoTrack = localStream?.getVideoTracks().first;
//     if (videoTrack != null) await Helper.switchCamera(videoTrack);
//   }
//
//   Future<void> dispose() async {
//     await _callSub?.cancel();
//     await _iceSub?.cancel();
//     localStream?.getTracks().forEach((t) => t.stop());
//     await localStream?.dispose();
//     await peerConnection?.close();
//     localRenderer.srcObject = null;
//     remoteRenderer.srcObject = null;
//   }
// }

class WebRTCService {
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;

  Function? onRemoteStream;

  MediaStream? localStream;
  RTCPeerConnection? peerConnection;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _callSub;
  StreamSubscription? _iceSub;

  List<RTCIceCandidate> _remoteCandidateBuffer = [];
  bool _isRemoteDescriptionSet = false;

  WebRTCService(this.localRenderer, this.remoteRenderer);

  /// ================= INIT =================
  Future<void> init() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'}
    });

    localRenderer.srcObject = localStream;

    peerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': "stun:stun.l.google.com:19302",
        },
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'iceTransportPolicy': 'all'
    });

    /// Remote stream
    peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
        if (onRemoteStream != null) onRemoteStream!();
      }
    };

    /// Add local tracks
    for (var track in localStream!.getTracks()) {
      await peerConnection!.addTrack(track, localStream!);
    }

    /// Logs
    peerConnection!.onIceConnectionState = (state) => print("ICE State: $state");

    peerConnection!.onConnectionState = (state) => print("Connection State: $state");
  }

  /// ================= BUFFER PROCESS =================
  Future<void> _processBufferedCandidates() async {
    for (var candidate in _remoteCandidateBuffer) {
      await peerConnection!.addCandidate(candidate);
    }
    _remoteCandidateBuffer.clear();
  }

  /// ================= LISTEN CANDIDATES =================
  void _listenForCandidates(DocumentReference callDoc, String collectionName) {
    _iceSub = callDoc.collection(collectionName).snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final candidate = RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        );

        if (_isRemoteDescriptionSet) {
          peerConnection!.addCandidate(candidate);
        } else {
          _remoteCandidateBuffer.add(candidate);
        }
      }
    });
  }

  /// ================= CALLER =================
  Future<void> createOffer(String callId) async {
    final callDoc = _firestore.collection('calls').doc(callId);

    /// Send ICE
    peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate != null) {
        callDoc.collection('callerCandidates').add(candidate.toMap());
      }
    };

    peerConnection!.onIceGatheringState = (state) {
      print("ICE Gathering: $state");
    };

    /// Create Offer
    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    await callDoc.set({
      'offer': offer.toMap(),
      'status': CallStatus.ringing,
    }, SetOptions(merge: true));

    /// Listen for Answer
    _callSub = callDoc.snapshots().listen((doc) async {
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      if (!_isRemoteDescriptionSet && data['answer'] != null) {
        final answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        await peerConnection!.setRemoteDescription(answer);

        _isRemoteDescriptionSet = true;

        await _processBufferedCandidates();
      }
    });

    /// Listen for receiver candidates
    _listenForCandidates(callDoc, 'receiverCandidates');
  }

  /// ================= RECEIVER =================
  Future<void> answerCall(String callId) async {
    final callDoc = _firestore.collection('calls').doc(callId);
    final doc = await callDoc.get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;

    /// Send ICE
    peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate != null) {
        callDoc.collection('receiverCandidates').add(candidate.toMap());
      }
    };

    /// Set remote offer
    final offer = RTCSessionDescription(
      data['offer']['sdp'],
      data['offer']['type'],
    );

    peerConnection!.onIceGatheringState = (state) {
      print("ICE Gathering: $state");
    };

    await peerConnection!.setRemoteDescription(offer);

    _isRemoteDescriptionSet = true;

    await _processBufferedCandidates();

    /// Create Answer
    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    await callDoc.set({'answer': answer.toMap(), 'status': CallStatus.connected}, SetOptions(merge: true));

    /// Listen for caller candidates
    _listenForCandidates(callDoc, 'callerCandidates');
  }

  /// ================= SWITCH CAMERA =================
  Future<void> switchCamera() async {
    final videoTrack = localStream?.getVideoTracks().first;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
    }
  }

  /// ================= DISPOSE =================
  Future<void> dispose() async {
    await _callSub?.cancel();
    await _iceSub?.cancel();

    localStream?.getTracks().forEach((t) => t.stop());
    await localStream?.dispose();

    await peerConnection?.close();
  }
}
