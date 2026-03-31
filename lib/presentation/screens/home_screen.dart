import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spiko/core/listners/call_lisner.dart';
import 'package:spiko/presentation/screens/calls/chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CallListener.listen(context, userId);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const ChatListScreen();
  }
}
