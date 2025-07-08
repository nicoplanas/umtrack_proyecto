import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/widgets/navbar.dart';
import '../../../core/widgets/footer.dart';
import '../../../features/profile/widgets/profile_student.dart';
import '../../../features/profile/widgets/profile_professor.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Usuario no encontrado')),
          );
        }

        final data = snapshot.data!.data()!;
        final email = user.email ?? 'Sin email';
        final role = (data['role'] as String?)?.toLowerCase();

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Navbar(email: email),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        if (role == 'student')
                          const Profile()
                        else if (role == 'professor')
                          const ProfileProfessor()
                        else
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'Rol de usuario desconocido',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),

                        const Footer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
