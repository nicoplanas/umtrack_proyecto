import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umtrack/features/profile/views/profile_settings_page.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileProfessor extends StatefulWidget {
  const ProfileProfessor({Key? key}) : super(key: key);

  @override
  State<ProfileProfessor> createState() => _ProfileProfessorState();
}

class _ProfileProfessorState extends State<ProfileProfessor> {
  String name = '';
  String email = '';
  String photoURL = '';
  String phone = '';
  String birthDate = '';
  String department = '';        // nombre del departamento
  String uniCard = '';           // carnet de profesor
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
    final deptId = data['departamento'] as String?; // <-- campo corregido

    String deptName = '';
    if (deptId != null && deptId.isNotEmpty) {
    final deptDoc = await FirebaseFirestore.instance
        .collection('departamentos')
        .doc(deptId)
        .get();
    deptName = deptDoc.data()?['nombre'] ?? '';
    }

    setState(() {
    name       = data['fullName'] ?? 'Profesor';
    email      = data['email']    ?? 'Correo no disponible';
    phone      = data['phone']    ?? '+58 412-345-6789';
    birthDate  = data['birthday'] != null
    ? _formatDate((data['birthday'] as Timestamp).toDate())
        : 'DD/MM/YYYY';
    photoURL   = data['profileImageUrl'] ?? '';
    department = deptName;    // ahora sí vendrá el nombre
    uniCard    = data['uni_card']?.toString() ?? '';
    isLoading  = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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

    if (result == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .delete();
        await user.delete();
        Navigator.of(context).pushNamedAndRemoveUntil('/landing', (route) => false);
      }
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
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Divider(color: Colors.black12),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COLUMNA IZQUIERDA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nombre Completo',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: name),
                      enabled: false,
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Teléfono',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: phone),
                      enabled: false,
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Carnet de Profesor',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: uniCard),
                      enabled: false,
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontWeight: FontWeight.w500),
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
              // COLUMNA DERECHA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Correo Electrónico',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: email),
                      enabled: false,
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Fecha de Nacimiento',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: birthDate),
                      enabled: false,
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontWeight: FontWeight.w500),
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TARJETA LATERAL
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
                    backgroundColor: photoURL.isEmpty
                        ? const Color(0xFFFD8305)
                        : Colors.transparent,
                    backgroundImage:
                    photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                    child: photoURL.isEmpty && name.isNotEmpty
                        ? Text(
                      name[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                          fontSize: 32, color: Colors.white),
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
                    department,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                  const Divider(color: Colors.black12),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Carnet Profesor',
                          style: GoogleFonts.poppins(color: Colors.black)),
                      Text(uniCard,
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
                            builder: (_) => const ProfileSettingsPage()),
                      ).then((_) => _loadUserData());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFD8305),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: Text('Editar Perfil',
                        style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // FORMULARIO DE INFORMACIÓN PERSONAL
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
