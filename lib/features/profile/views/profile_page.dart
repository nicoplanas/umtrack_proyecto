import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umtrack/features/profile/views/profile_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = '';
  String email = '';
  String photoURL = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user?.uid)
        .get();
    final data = userDoc.data();
    setState(() {
      name = data?['fullName'] ?? 'Usuario';
      email = data?['email'] ?? 'Correo no disponible';
      photoURL = data?['profileImageUrl'] ?? '';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: photoURL.isNotEmpty
                  ? NetworkImage(photoURL)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(height: 20),
            Text(name, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(email),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsPage(),
                  ),
                ).then((_) => _loadUserData());
              },
              child: const Text('Editar perfil'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final uid = user.uid;

                  // Eliminar de Firestore
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(uid)
                      .delete();

                  // Eliminar de Authentication
                  await user.delete();

                  // Regresar al inicio
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}