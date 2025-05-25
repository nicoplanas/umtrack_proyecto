import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/features/auth/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/features/landing/views/landing_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _tipoUsuario; // 'estudiante' o 'profesor'
  String? _selectedCarrera;
  List<String> _carreras = [];
  bool _isLoadingCarreras = false;

  DateTime? _selectedBirthday; // NUEVO campo para fecha de nacimiento

  @override
  void initState() {
    super.initState();
    _loadCarreras();
  }

  Future<void> _loadCarreras() async {
    setState(() {
      _isLoadingCarreras = true;
    });
    try {
      final snapshot = await _firestore.collection('carreras').get();

      if (snapshot.docs.isEmpty) {
        debugPrint('No hay carreras disponibles');
        setState(() {
          _carreras = [];
        });
        return;
      }

      final carreras = <String>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('nombre') && data['nombre'] != null) {
          carreras.add(data['nombre'].toString());
        } else {
          debugPrint('Documento ${doc.id} no tiene campo nombre válido');
        }
      }

      setState(() {
        _carreras = carreras..sort(); // Ordena alfabéticamente
      });
    } catch (e) {
      debugPrint('Error al cargar carreras: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar carreras: $e')));
      setState(() {
        _carreras = [];
      });
    } finally {
      setState(() {
        _isLoadingCarreras = false;
      });
    }
  }

  Future<void> _pickBirthday() async {
    final today = DateTime.now();
    final initialDate = _selectedBirthday ?? DateTime(today.year - 18, today.month, today.day);
    final firstDate = DateTime(1900); // límite inferior año nacimiento
    final lastDate = DateTime(today.year - 10); // límite superior año nacimiento (mínimo 10 años)

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBirthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione fecha de nacimiento')));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden')));
      return;
    }

    if (_tipoUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona un tipo de usuario')));
      return;
    }

    if (_tipoUsuario == 'estudiante' && _selectedCarrera == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una carrera')));
      return;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim());

      final user = userCredential.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al crear usuario')));
        return;
      }

      final now = DateTime.now();

      final userData = {
        'userId': user.uid,
        'fullName': '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
        'username': _emailController.text.split('@')[0],
        'email': _emailController.text.trim(),
        'birthday': _selectedBirthday!, // Aquí guardamos DateTime directo
        'profileImageUrl': '',
        'role': _tipoUsuario == 'estudiante' ? 'student' : 'professor',
        'createdAt': now,
        'lastLoginAt': now,
      };

      if (_tipoUsuario == 'estudiante') {
        userData['major'] = _selectedCarrera!;
        userData['passedCourses'] = [];
        userData['dateOfEnrollment'] = now;
        userData['credits'] = 0;
      } else if (_tipoUsuario == 'profesor') {
        userData['assignedCourses'] = [];
        userData['dateOfHiring'] = now;
      }

      await _firestore.collection('usuarios').doc(user.uid).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado exitosamente')));

      // Opcional: limpiar formulario o navegar

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Cambio 2: Fondo blanco
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Colors.orange, // Cambio 3: Morado → Naranja
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Ingrese su nombre' : null,
              ),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Ingrese su apellido' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese su email';
                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!regex.hasMatch(value)) return 'Email inválido';
                  return null;
                },
              ),

              // Cambio 1: Botón de fecha centrado
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Alineación izquierda
                children: [
                  const Text('Fecha de nacimiento:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: _pickBirthday,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, // Elimina padding interno
                      alignment: Alignment.centerLeft, // Alinea texto a la izquierda
                    ),
                    child: Text(
                      _selectedBirthday == null
                          ? 'Selecciona una fecha'
                          : '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}',
                      textAlign: TextAlign.left, // Alineación de texto
                    ),
                  ),
                ],
              ),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese contraseña';
                  if (value.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Confirme contraseña';
                  if (value != _passwordController.text) return 'No coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoUsuario,
                items: const [
                  DropdownMenuItem(value: 'estudiante', child: Text('Estudiante')),
                  DropdownMenuItem(value: 'profesor', child: Text('Profesor')),
                ],
                onChanged: (val) {
                  setState(() {
                    _tipoUsuario = val;
                    _selectedCarrera = null;
                  });
                },
                decoration: const InputDecoration(labelText: 'Tipo de usuario'),
                validator: (value) =>
                value == null ? 'Seleccione tipo de usuario' : null,
              ),
              if (_tipoUsuario == 'estudiante') ...[
                const SizedBox(height: 16),
                _isLoadingCarreras
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                  value: _selectedCarrera != null && _carreras.contains(_selectedCarrera)
                      ? _selectedCarrera
                      : null,
                  items: _carreras
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCarrera = val;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Carrera'),
                  validator: (value) =>
                  value == null ? 'Seleccione carrera' : null,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Cambio 3: Morado → Naranja
                ),
                child: const Text('Registrarse'),
              )
            ],
          ),
        ),
      ),
    );
  }
}