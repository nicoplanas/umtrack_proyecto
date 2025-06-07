import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _photoUrl;
  bool _isLoading = true;
  bool _isUploadingImage = false;

  final String imgbbApiKey = '7afcb4a264a098ae15c3e660daed2b55';

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
    if (data != null) {
      _nameController.text = data['fullName'] ?? '';
      _emailController.text = data['email'] ?? '';
      _photoUrl = data['profileImageUrl'];
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploadingImage = true);

    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
      body: {
        'image': base64Image,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _photoUrl = data['data']['url'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la imagen')),
      );
    }

    setState(() => _isUploadingImage = false);
  }

  void _saveSettings() async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
          'fullName': _nameController.text,
          'email': _emailController.text,
          'profileImageUrl': _photoUrl,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados')),
        );

        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_photoUrl != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(_photoUrl!),
                ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                child: _isUploadingImage
                    ? const CircularProgressIndicator()
                    : const Text('Cambiar foto de perfil'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




