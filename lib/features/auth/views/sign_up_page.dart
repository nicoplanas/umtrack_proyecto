import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  String? _tipoUsuario;
  String? _selectedCarrera;
  List<String> _carrerasVisibles = [];
  Map<String, String> _carrerasMap = {};
  bool _isLoadingCarreras = false;

  DateTime? _selectedBirthday;

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
      final snapshot = await _firestore
          .collection('carreras_pregrado')
          .doc('sjs34UWA7WS5CzHyvRdc')
          .get();

      final data = snapshot.data();
      if (data == null || !data.containsKey('carreras')) {
        throw Exception('No se encontró el mapa de carreras');
      }

      final carrerasMap = data['carreras'] as Map<String, dynamic>;

      final Map<String, String> nombreToCodigo = {};
      final List<String> nombresVisibles = [];

      carrerasMap.forEach((codigo, contenido) {
        final nombre = contenido['nombre'] ?? codigo;
        nombreToCodigo[nombre] = codigo;
        nombresVisibles.add(nombre);
      });

      setState(() {
        _carrerasMap = nombreToCodigo;
        _carrerasVisibles = nombresVisibles..sort();
      });
    } catch (e) {
      debugPrint('Error al cargar carreras: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al cargar carreras: $e')));
      setState(() {
        _carrerasMap = {};
        _carrerasVisibles = [];
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
    final firstDate = DateTime(1900);
    final lastDate = DateTime(today.year - 10);

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
        'birthday': _selectedBirthday!,
        'profileImageUrl': '',
        'role': _tipoUsuario == 'estudiante' ? 'student' : 'professor',
        'createdAt': now,
        'lastLoginAt': now,
      };

      if (_tipoUsuario == 'estudiante') {
        final carreraCode = _carrerasMap[_selectedCarrera];
        if (carreraCode == null) throw Exception('Código de carrera no encontrado');

        userData['major'] = carreraCode;
        userData['passedCourses'] = {}; // <-- mapa vacío
        userData['dateOfEnrollment'] = now;
        userData['credits'] = 0;
      } else if (_tipoUsuario == 'profesor') {
        userData['assignedCourses'] = [];
        userData['dateOfHiring'] = now;
      }

      await _firestore.collection('usuarios').doc(user.uid).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado exitosamente')));

      // 🔁 Navegar a la landing page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
      );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Colors.orange,
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
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fecha de nacimiento:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: _pickBirthday,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      _selectedBirthday == null
                          ? 'Selecciona una fecha'
                          : '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}',
                      textAlign: TextAlign.left,
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
                  value: _selectedCarrera != null && _carrerasVisibles.contains(_selectedCarrera)
                      ? _selectedCarrera
                      : null,
                  items: _carrerasVisibles
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
                  backgroundColor: Colors.orange,
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