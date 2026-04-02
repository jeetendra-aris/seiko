import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerName;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerName,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with SingleTickerProviderStateMixin {
  final player = AudioPlayer();
  StreamSubscription? sub;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _playRingtone();
    _listenStatus();

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
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
    _pulseController.dispose();
    super.dispose();
  }

  void _acceptCall() {
    player.stop();
    FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({'status': 'connected'});

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(callId: widget.callId, isCaller: false),
      ),
    );
  }

  void _rejectCall() {
    FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({'status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              /// 📞 Incoming text
              const Text(
                "Incoming Video Call",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 20),

              /// 👤 Animated Avatar with pulse
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, child) {
                  double scale = 1 + (_pulseController.value * 0.2);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: const CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 70, color: Colors.white),
                ),
              ),

              const SizedBox(height: 25),

              /// 👤 Caller Name
              Text(
                widget.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              /// 🎮 Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// ❌ Reject
                    _buildCallButton(
                      icon: Icons.call_end,
                      color: Colors.red,
                      label: "Decline",
                      onTap: _rejectCall,
                    ),

                    /// ✅ Accept
                    _buildCallButton(
                      icon: Icons.videocam,
                      color: Colors.green,
                      label: "Accept",
                      onTap: _acceptCall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        )
      ],
    );
  }
}
