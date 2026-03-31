import 'package:cloud_firestore/cloud_firestore.dart';

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> startCall({
    required String callerId,
    required String receiverId,
    required bool isVideo,
  }) async {
    /// Prevent multiple calls
    final existing = await _firestore.collection('calls').where('callerId', isEqualTo: callerId).where('status', isEqualTo: 'calling').get();

    if (existing.docs.isNotEmpty) {
      return null;
    }

    final callDoc = _firestore.collection('calls').doc();
    final callId = callDoc.id;

    await callDoc.set({
      'callId': callId,
      'callerId': callerId,
      'receiverId': receiverId,
      'status': 'calling',
      'type': isVideo ? 'video' : 'audio',
      'createdAt': FieldValue.serverTimestamp(),
    });

    /// Timeout
    _startTimeout(callId);

    return callId;
  }

  void _startTimeout(String callId) {
    Future.delayed(const Duration(seconds: 30), () async {
      final doc = await _firestore.collection('calls').doc(callId).get();

      if (doc.exists && doc['status'] == 'calling') {
        await _firestore.collection('calls').doc(callId).update({
          'status': 'ended',
          'endedReason': 'missed',
        });
      }
    });
  }
}
