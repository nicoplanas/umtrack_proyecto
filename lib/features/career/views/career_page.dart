import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/widgets/navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/features/career/widgets/flowgram.dart';
import '../../../core/widgets/footer.dart';

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
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Navbar(email: email),
                        Flowgram(carreraId: carreraId),
                        Footer(), // Ahora se muestra solo al final, no está fijo
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}