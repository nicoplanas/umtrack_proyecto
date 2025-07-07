import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/widgets/navbar.dart';
import '../widgets/info_section.dart';
import '../../../core/widgets/footer.dart';
import '../widgets/dashboard_student.dart';
import '../widgets/dashboard_professor.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // Función para obtener el tipo de usuario (profesor o estudiante) desde Firestore
  Future<String> _getUserType(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get(); // Cambiado a 'usuarios'
      final userData = userDoc.data();

      // Verificar si los datos del usuario son nulos o si falta el campo 'role'
      if (userData == null || !userData.containsKey('role')) {
        print('El campo tipo no está disponible para este usuario.');
        return 'estudiante'; // Valor por defecto si el campo 'role' no está presente
      }

      return userData['role'] ?? 'estudiante'; // Si 'role' está disponible, lo retorna, de lo contrario 'estudiante'
    } catch (e) {
      print('Error al obtener el tipo de usuario: $e');
      return 'estudiante'; // Valor por defecto en caso de error
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final email = user?.email ?? 'Guest';

        // Si el usuario está autenticado, buscamos el tipo
        if (user != null) {
          return FutureBuilder<String>(
            future: _getUserType(user.uid),  // Obtenemos el tipo de usuario
            builder: (context, userTypeSnapshot) {
              if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator())); // Cargando
              }

              if (userTypeSnapshot.hasData) {
                // Mostrar Dashboard según el tipo de usuario
                final userType = userTypeSnapshot.data ?? 'estudiante';
                if (userType == 'professor') {
                  return Scaffold(
                    body: ListView(
                      children: [
                        Navbar(email: email),
                        const DashboardProfessor(), // Widget para el profesor
                        const Footer(),
                      ],
                    ),
                  );
                } else {
                  return Scaffold(
                    body: ListView(
                      children: [
                        Navbar(email: email),
                        const DashboardStudent(), // Widget para el estudiante
                        const Footer(),
                      ],
                    ),
                  );
                }
              } else {
                return const Scaffold(body: Center(child: Text('Error al cargar el tipo de usuario')));
              }
            },
          );
        }

        // Si el usuario no está autenticado, mostramos la sección de información
        return Scaffold(
          body: ListView(
            children: [
              Navbar(email: email),
              const InfoSection(),
              const Footer(),
            ],
          ),
        );
      },
    );
  }
}
