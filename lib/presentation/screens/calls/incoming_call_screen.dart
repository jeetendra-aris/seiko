import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerName;

  const IncomingCallScreen({super.key, required this.callId, required this.callerName});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final player = AudioPlayer();
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    _playRingtone();
    _listenStatus();
  }

  void _playRingtone() async {
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('sounds/ringtone.mp3'));
  }

  void _listenStatus() {
    sub = FirebaseFirestore.instance.collection('calls').doc(widget.callId).snapshots().listen((doc) {
      if (!doc.exists) return;
      String status = doc['status'];
      if (status == 'ended' || status == 'rejected') {
        player.stop();
        Navigator.pop(context);
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
      backgroundColor: Colors.blueGrey[900],
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Incoming Video Call", style: TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 10),
          Text(widget.callerName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.red,
                child: const Icon(Icons.call_end),
                onPressed: () => FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({'status': 'rejected'}),
              ),
              FloatingActionButton(
                backgroundColor: Colors.green,
                child: const Icon(Icons.videocam),
                onPressed: () {
                  player.stop();
                  FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({'status': 'connected'});
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => CallScreen(callId: widget.callId, isCaller: false)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
