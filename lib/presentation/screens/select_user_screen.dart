import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spiko/data/models/user_model.dart';
import 'package:spiko/presentation/screens/chat_screen.dart';

class SelectUserScreen extends StatelessWidget {
  const SelectUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const currentUserId = "YOUR_USER_ID"; // replace with real

    return Scaffold(
      appBar: AppBar(title: const Text("Select User")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs.where((doc) => doc.id != currentUserId).map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();

          if (users.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.account_circle),
                ),
                title: Text(user.name),
                subtitle: Text(user.phone),
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        receiverId: user.uid,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
