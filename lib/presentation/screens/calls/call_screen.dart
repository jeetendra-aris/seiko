import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:spiko/core/enums/call_ui_enums.dart';
import 'package:spiko/presentation/providers/call_provider.dart';

class CallScreen extends StatelessWidget {
  final String callId;
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.callId,
    required this.isCaller,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CallProvider(
        callId: callId,
        isCaller: isCaller,
      )..init(),
      child: _CallView(),
    );
  }
}

class _CallView extends StatelessWidget {
  _CallView();

  bool _hasPopped = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, p, child) {
        /// ✅ Handle navigation safely
        /// ✅ Handle end state with delay
        if (p.uiState == CallUIState.ended && !_hasPopped) {
          _hasPopped = true;

          _ended(p); // show end UI

          Future.delayed(const Duration(seconds: 3), () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _buildBody(p),
          ),
        );
      },
    );
  }

  Widget _buildBody(CallProvider p) {
    switch (p.uiState) {
      case CallUIState.connecting:
        return _connecting();

      case CallUIState.ringing:
        return _ringing(p);

      case CallUIState.connected:
        return _connected(p);

      case CallUIState.ended:
        return _ended(p);

      default:
        return const SizedBox();
    }
  }

  Widget _connecting() {
    return const Center(
      key: ValueKey("connecting"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text(
            "Connecting...",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _ringing(CallProvider p) {
    return Container(
      width: double.infinity,
      key: const ValueKey("ringing"),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              p.isCaller ? "Calling..." : "Incoming Call...",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              "Connecting to user",
              style: TextStyle(color: Colors.white38),
            ),
            const Spacer(),

            /// Only show end button while ringing
            FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: p.endCall,
              child: const Icon(Icons.call_end),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _connected(CallProvider p) {
    return Stack(
      key: const ValueKey("connected"),
      children: [
        /// Remote Video (with fallback)
        Positioned.fill(
          child: p.remote.srcObject != null
              ? RTCVideoView(
                  p.remote,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: true,
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),

        /// ⏱ Call Timer (TOP CENTER)
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Card(
              color: Colors.black54,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
                child: Text(
                  p.formatTime(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),

        /// Switch Camera
        Positioned(
          top: 80,
          right: 20,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              onPressed: p.switchCamera,
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            ),
          ),
        ),

        /// Local Preview
        Positioned(
          right: 20,
          bottom: 140,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: p.cameraOff
                  ? const Center(
                      child: Icon(Icons.videocam_off, color: Colors.white, size: 40),
                    )
                  : RTCVideoView(
                      p.local,
                      mirror: p.isFrontCamera,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
            ),
          ),
        ),

        /// Bottom Controls (Glass effect)
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  icon: p.muted ? Icons.mic_off : Icons.mic,
                  onTap: p.toggleMute,
                ),
                _controlButton(
                  icon: p.cameraOff ? Icons.videocam_off : Icons.videocam,
                  onTap: p.toggleCamera,
                ),
                _controlButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  onTap: p.endCall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.black54,
        child: Icon(icon, color: color),
      ),
    );
  }

  Widget _ended(CallProvider p) {
    return Center(
      key: const ValueKey("ended"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.call_end, color: Colors.red, size: 60),
          const SizedBox(height: 20),
          const Text(
            "Call Ended",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          Text(
            p.formatTime(),
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ],
      ),
    );
  }
}
