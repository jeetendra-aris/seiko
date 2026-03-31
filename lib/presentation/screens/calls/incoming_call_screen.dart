import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spiko/core/utils/call_status.dart';

import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerId;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final player = AudioPlayer();
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    playRingtone();
    listenStatus();
  }

  Future<void> playRingtone() async {
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('sounds/ringtone.mp3'));
  }

  void stop() => player.stop();

  void listenStatus() {
    sub = FirebaseFirestore.instance.collection('calls').doc(widget.callId).snapshots().listen((doc) {
      if (!doc.exists) return;

      final status = doc['status'];

      if (status == CallStatus.ended || status == CallStatus.rejected) {
        stop();
        Navigator.pop(context);
      }

      if (status == CallStatus.connected) {
        stop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              callId: widget.callId,
              receiverId: widget.callerId,
              isCaller: false,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 100, color: Colors.white),
          const SizedBox(height: 20),
          const Text("Incoming Call", style: TextStyle(color: Colors.white, fontSize: 22)),
          Text(widget.callerId, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              /// Reject
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () async {
                  stop();
                  await FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({'status': CallStatus.rejected});
                },
                child: const Icon(Icons.call_end),
              ),

              /// Accept
              FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: () async {
                  stop();
                  await FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({'status': CallStatus.connected});
                },
                child: const Icon(Icons.call),
              ),
            ],
          )
        ],
      ),
    );
  }
}
