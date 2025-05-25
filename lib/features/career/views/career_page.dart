import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/widgets/navbar.dart';
import '/features/career/widgets/flowgram.dart';

class CareerPage extends StatelessWidget {
  const CareerPage({super.key});

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
              Flowgram(),
            ],
          ),
        );
      },
    );
  }
}