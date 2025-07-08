import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umtrack/features/landing/views/landing_page.dart'; // <-- import LandingPage
import 'package:umtrack/features/profile/views/profile_settings_page.dart';
import 'package:google_fonts/google_fonts.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String name = '';
  String email = '';
  String photoURL = '';
  String phone = '';
  String birthDate = '';
  String major = '';
  String uniCard = '';
  int trimester = 1;
  int credits = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    final data = userDoc.data()!;

    // obtener nombre de la carrera desde colección "carreras"
    final majorId = data['major'] as String?;
    String majorName = '';
    if (majorId != null && majorId.isNotEmpty) {
      final carreraDoc = await FirebaseFirestore.instance
          .collection('carreras')
          .doc(majorId)
          .get();
      majorName = carreraDoc.data()?['nombre'] ?? '';
    }

    final fetchedCredits = data['credits'] ?? 0;

    final flujoSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('flujogramas')
        .get();
    int maxTrim = 1;
    for (var doc in flujoSnap.docs) {
      final materias = doc.data();
      materias.forEach((_, value) {
        if (value is Map<String, dynamic> &&
            value['estado'] == 'aprobada' &&
            value.containsKey('trimestre')) {
          final t = (value['trimestre'] ?? 0) as int;
          if (t > maxTrim) maxTrim = t;
        }
      });
    }

    setState(() {
      name = data['fullName'] ?? 'Usuario';
      email = data['email'] ?? 'Correo no disponible';
      phone = data['phone'] ?? '+58 412-345-6789';
      birthDate = data['birthday'] != null
          ? _formatDate((data['birthday'] as Timestamp).toDate())
          : '15/03/2001';
      photoURL = data['profileImageUrl'] ?? '';
      credits = fetchedCredits;
      trimester = maxTrim;
      major = majorName;
      uniCard = data['uni_card']?.toString() ?? '';
      isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Borra recursivamente subcolecciones y luego el doc principal
  Future<void> _deleteUserAndData(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
    // 1) Subcolección "flujogramas"
    final flujos = await userRef.collection('flujogramas').get();
    for (final doc in flujos.docs) {
      await doc.reference.delete();
    }
    // 2) Subcolección "requisitos_adicionales"
    final reqs = await userRef.collection('requisitos_adicionales').get();
    for (final doc in reqs.docs) {
      await doc.reference.delete();
    }
    // 3) Documento principal
    await userRef.delete();
  }

  Future<void> _confirmAndDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          '¿Estás seguro?',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Esta acción eliminará tu cuenta permanentemente.',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.black)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Eliminar', style: GoogleFonts.poppins(color: Colors.black)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (result != true) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1) Borro subcolecciones + doc
      await _deleteUserAndData(user.uid);
      // 2) Borro usuario en Auth
      await user.delete();
      // 3) Cierro sesión
      await FirebaseAuth.instance.signOut();
      // 4) Redirijo a Landing y limpio la pila
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingPage()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar cuenta: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    }
  }

  Widget _buildPersonalTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Personal',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black
            ),
          ),
          const Divider(color: Colors.black12),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nombre Completo', style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, color: Colors.black
                    )),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: name),
                      enabled: false,
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontWeight: FontWeight.w500
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Teléfono', style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, color: Colors.black
                    )),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: phone),
                      enabled: false,
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontWeight: FontWeight.w500
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Carnet Estudiantil', style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, color: Colors.black
                    )),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: uniCard),
                      enabled: false,
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontWeight: FontWeight.w500
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Columna derecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Correo Electrónico', style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, color: Colors.black
                    )),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: email),
                      enabled: false,
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontWeight: FontWeight.w500
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Fecha de Nacimiento', style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, color: Colors.black
                    )),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: birthDate),
                      enabled: false,
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontWeight: FontWeight.w500
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: _confirmAndDelete,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Eliminar cuenta',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PERFIL LATERAL
            Container(
              width: 280,
              margin: const EdgeInsets.only(top: 32, left: 24, bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                    photoURL.isEmpty ? const Color(0xFFFD8305) : Colors.transparent,
                    backgroundImage:
                    photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                    child: photoURL.isEmpty && name.isNotEmpty
                        ? Text(
                      name[0].toUpperCase(),
                      style: GoogleFonts.poppins(fontSize: 32, color: Colors.white),
                    )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    major,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$trimesterº Semestre',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFFFD8305), fontWeight: FontWeight.w600),
                  ),
                  const Divider(color: Colors.black12),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ID Estudiante', style: GoogleFonts.poppins(color: Colors.black)),
                      Text('2019-1234',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Promedio', style: GoogleFonts.poppins(color: Colors.black)),
                      Text('3.85',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, color: Color(0xFFFD8305))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Créditos', style: GoogleFonts.poppins(color: Colors.black)),
                      Text('$credits',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileSettingsPage(),
                        ),
                      ).then((_) => _loadUserData());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFD8305),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child:
                    Text('Editar Perfil', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // CONTENIDO (solo Información Personal)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 32, right: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: _buildPersonalTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
