import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _photoURL = '';
  final _photoController = TextEditingController();

  void _saveSettings() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.updateDisplayName(_name);
        await user.updateEmail(_email);

        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
          'fullName': _name,
          'email': _email,
          'profileImageUrl': _photoURL,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados exitosamente')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _photoURL.isNotEmpty
                      ? NetworkImage(_photoURL)
                      : const AssetImage('assets/placeholder.png') as ImageProvider,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                onSaved: (value) => _name = value ?? '',
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                onSaved: (value) => _email = value ?? '',
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _photoController,
                decoration: const InputDecoration(labelText: 'URL de la foto de perfil'),
                onChanged: (value) => setState(() => _photoURL = value),
                onSaved: (value) => _photoURL = value ?? '',
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Guardar cambios'),
              )
            ],
          ),
        ),
      ),
    );
  }
}




