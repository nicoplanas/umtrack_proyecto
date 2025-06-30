import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/widgets/navbar.dart';
import '../widgets/manage_student.dart';
import '../../../core/widgets/footer.dart';

class ManageStudentPage extends StatelessWidget {
  final String claseId;
  final String studentId;

  const ManageStudentPage({
    super.key,
    required this.claseId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final email = user?.email ?? 'Guest';

        return Scaffold(
          body: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('clases')
                .doc(claseId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Clase no encontrada.'));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final estudiantes = data['estudiantes'] as Map<String, dynamic>? ?? {};
              final studentData = estudiantes[studentId];

              if (studentData == null) {
                return const Center(child: Text('Estudiante no encontrado.'));
              }

              return ListView(
                children: [
                  Navbar(email: email),
                  ManageStudent(
                    claseId: claseId,
                    studentId: studentId,
                    studentData: Map<String, dynamic>.from(studentData),
                  ),
                  Footer(),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
