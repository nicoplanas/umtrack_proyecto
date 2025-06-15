import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/landing/views/landing_page.dart';
import '../../features/career/views/career_page.dart';
import '../../features/auth/views/log_in_page.dart';
import '../../features/profile/views/profile_page.dart';
import '../../features/profile/views/profile_settings_page.dart';
import '../../features/classes/views/classes_page.dart';
import '../../features/Information/views/information_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Navbar extends StatefulWidget {
  final String? email;
  const Navbar({Key? key, this.email}) : super(key: key);

  @override
  _NavbarState createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data['profileImageUrl'] != null) {
        setState(() {
          profileImageUrl = data['profileImageUrl'];
        });
      }
    }
  }

  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo a la izquierda
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LandingPage()),
              );
            },
            child: Image.asset(
              'assets/logo.png',
              height: 70,
            ),
          ),

          // Espacio flexible en el medio
          const Spacer(),

          // Nav items + botones alineados hacia la derecha pero no pegados al borde
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navButton('Inicio', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                );
              }),
              const SizedBox(width: 8),
              _navButton('Carrera', () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    final doc = await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(user.uid)
                        .get();

                    Navigator.pop(context);

                    if (doc.exists && doc.data()?['role'] == 'student') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CareerPage(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No tienes una carrera asignada')),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debes iniciar sesión')),
                  );
                }
              }),
              const SizedBox(width: 8),
              _navButton('Clases', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClassesPage()),
                );
              }),
              const SizedBox(width: 8),
              _navButton('Información', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InformationPage()),
                );
              }),
              const SizedBox(width: 8),
              if (email != null) ...[
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B), size: 28),
                  tooltip: 'Notificaciones',
                  onPressed: () {
                    // Aquí puedes mostrar un diálogo, un dropdown o navegar a otra pantalla
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No hay notificaciones nuevas')),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _userMenu(context),
              ] else ...[
                _primaryButton('Iniciar sesión', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _navItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _navButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFD8305),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _userMenu(BuildContext context) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 12,
      icon: profileImageUrl != null && profileImageUrl!.isNotEmpty
          ? CircleAvatar(backgroundImage: NetworkImage(profileImageUrl!))
          : CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, color: Colors.black54),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              const Icon(Icons.account_circle_outlined, color: Color(0xFF1E293B)),
              const SizedBox(width: 10),
              Text("Perfil", style: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF1E293B)))
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, color: Color(0xFF1E293B)),
              const SizedBox(width: 10),
              Text("Ajustes", style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B))),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              const Icon(Icons.logout, color: Color(0xFFDC2626)),
              const SizedBox(width: 10),
              Text("Cerrar sesión", style: GoogleFonts.poppins(fontSize: 14, color: Color(0xFFDC2626))),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 0:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
            break;
          case 1:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsPage()));
            break;
          case 2:
            FirebaseAuth.instance.signOut().then((_) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            });
            break;
        }
      },
    );
  }
}