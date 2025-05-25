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
              return Scaffold(
                body: Center(child: Text('No se encontraron datos del usuario')),
              );
            }

            final userData = userSnapshot.data!.data()!;
            final carreraId = userData['major'] as String ?? 'Sin carrera';

            return Scaffold(
              body: ListView(
                children: [
                  Navbar(email: user.email ?? 'Usuario'),
                  Flowgram(carreraId: carreraId), // Pasa la carrera aquí
                ],
              ),
            );
          },
        );
      }
  }
  // @override
  // Widget build(BuildContext context) {
  //   return StreamBuilder<User?>(
  //     stream: FirebaseAuth.instance.authStateChanges(),
  //     builder: (context, snapshot) {
  //       final user = snapshot.data;
  //       final email = user?.email ?? 'Guest';
  //
  //       return Scaffold(
  //         body: ListView(
  //           children: [
  //             Navbar(email: email),
  //             Flowgram(),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }
