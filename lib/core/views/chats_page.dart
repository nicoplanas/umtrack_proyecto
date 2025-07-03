import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/widgets/navbar.dart';
import '../../core/widgets/chats.dart'; // Asegúrate de que Chat esté definido aquí
import '../../../core/widgets/footer.dart';

class ChatsPage extends StatelessWidget {
  final String studentId;
  final String studentName;

  const ChatsPage({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final email = user?.email ?? 'Guest';

        return Scaffold(
          body: ListView(
            children: [
              Navbar(email: email),
              Chat(studentId: studentId, studentName: studentName),
              const Footer(),
            ],
          ),
        );
      },
    );
  }
}
