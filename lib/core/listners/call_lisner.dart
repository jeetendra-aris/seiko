import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spiko/presentation/screens/calls/incoming_call_screen.dart';

class CallListener {
  static bool isCallScreenOpen = false;

  static void start(BuildContext context, String currentUserId) {
    FirebaseFirestore.instance.collection('calls').where('receiverId', isEqualTo: currentUserId).where('status', isEqualTo: 'calling').snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final callDoc = snapshot.docs.first;

      if (isCallScreenOpen) return;

      isCallScreenOpen = true;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callId: callDoc.id,
            callerId: callDoc['callerId'],
          ),
        ),
      ).then((_) {
        isCallScreenOpen = false;
      });
    });
  }
}
