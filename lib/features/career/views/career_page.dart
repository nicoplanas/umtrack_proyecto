import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/widgets/navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/features/career/widgets/flowgram.dart';

class CareerPage extends StatelessWidget {
  const CareerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Debes iniciar sesión')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Usuario no encontrado')),
          );
        }

        final data = userSnapshot.data!.data()!;
        final carreraId = data['carrera'] ?? 'Sin carrera';
        final email = user.email ?? 'Sin email';

        return Scaffold(
          body: Column(
            children: [
              Navbar(email: email),
              Expanded(
                child: Flowgram(carreraId: carreraId),
              ),
            ],
          ),
        );
      },
    );
  }
}