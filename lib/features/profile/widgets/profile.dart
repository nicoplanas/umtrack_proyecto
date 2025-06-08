import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String address = '';
  int selectedTabIndex = 0;
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
      phone = data?['phone'] ?? '+58 412-345-6789';
      birthDate = data?['birthday'] != null
          ? _formatDate(data?['birthday'].toDate())
          : '15/03/2001';
      address = data?['address'] ?? 'Av. Principal, Caracas, Venezuela';
      photoURL = data?['profileImageUrl'] ?? '';
      isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _confirmAndDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content:
        const Text('Esta acción eliminará tu cuenta permanentemente.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Eliminar'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .delete();
        await user.delete();
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }
  }

  Widget _buildTab(String title, int index) {
    final isSelected = selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => selectedTabIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF1E293B) : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                height: 2,
                width: 40,
                color: const Color(0xFFFD8305),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Información Personal",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Nombre Completo", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: name),
                      enabled: false,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Teléfono", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: phone),
                      enabled: false,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Dirección", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: address),
                      enabled: false,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Correo Electrónico", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: email),
                      enabled: false,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Fecha de Nacimiento", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: birthDate),
                      enabled: false,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Información de Contacto de Emergencia", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Contacto", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
                    Text("María Rodriguez (Madre)", style: GoogleFonts.poppins(color: Colors.black)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Teléfono", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
                    Text("+58 414-567-8901", style: GoogleFonts.poppins(color: Colors.black)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAcademicTab() {
    return const Center(child: Text('Información Académica (por implementar)'));
  }

  Widget _buildSettingsTab() {
    return Center(
      child: ElevatedButton(
        onPressed: _confirmAndDelete,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: const Text('Eliminar cuenta'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      color: Colors.white, // ✅ Fondo blanco para todo el contenido
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PERFIL LATERAL
            Container(
              width: 280,
              margin: const EdgeInsets.all(24),
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
                    backgroundImage: photoURL.isNotEmpty
                        ? NetworkImage(photoURL)
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                  const SizedBox(height: 16),
                  Text(name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                  Text("Ingeniería en Sistemas",
                      style: GoogleFonts.poppins(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text("8vo Semestre",
                      style: GoogleFonts.poppins(color: Color(0xFFFD8305), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("ID Estudiante", style: GoogleFonts.poppins(color: Colors.black)),
                      Text("2019-1234", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black))
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Promedio", style: GoogleFonts.poppins(color: Colors.black)),
                      Text("3.85", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Color(0xFFFD8305)))
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Créditos", style: GoogleFonts.poppins(color: Colors.black)),
                      Text("168/180", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black))
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsPage()))
                          .then((_) => _loadUserData());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFD8305),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: Text("Editar Perfil", style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ],
              ),
            ),

            // CONTENIDO
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 32, right: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tabs
                    Row(
                      children: [
                        _buildTab("Información Personal", 0),
                        _buildTab("Información Académica", 1),
                        _buildTab("Configuraciones", 2),
                      ],
                    ),
                    const Divider(height: 32, color: Colors.black12),

                    // Contenido según la pestaña seleccionada
                    if (selectedTabIndex == 0)
                      _buildPersonalTab()
                    else if (selectedTabIndex == 1)
                      _buildAcademicTab()
                    else
                      _buildSettingsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}