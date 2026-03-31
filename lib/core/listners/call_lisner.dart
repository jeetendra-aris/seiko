import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spiko/presentation/screens/calls/incoming_call_screen.dart';

// class CallListener {
//   static bool _isOpen = false;
//
//   static void listen(BuildContext context, String userId) {
//     FirebaseFirestore.instance.collection('calls').where('receiverId', isEqualTo: userId).where('status', isEqualTo: CallStatus.calling).snapshots().listen((snapshot) {
//       if (snapshot.docs.isEmpty) return;
//       if (_isOpen) return;
//
//       _isOpen = true;
//
//       final doc = snapshot.docs.first;
//
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => IncomingCallScreen(
//             callId: doc.id,
//             callerId: doc['callerId'],
//           ),
//         ),
//       ).then((_) => _isOpen = false);
//     });
//   }
// }

class CallListener {
  static void listen(BuildContext context, String currentUserId) {
    FirebaseFirestore.instance.collection('calls').where('receiverId', isEqualTo: currentUserId).where('status', isEqualTo: 'calling').snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final callDoc = snapshot.docs.first;

      final callId = callDoc.id;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callId: callId,
            callerId: callDoc['callerId'],
          ),
        ),
      );
    });
  }
}
