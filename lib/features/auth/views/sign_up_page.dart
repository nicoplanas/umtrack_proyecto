import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/features/landing/views/landing_page.dart';
import 'package:flutter/cupertino.dart';
import '../../auth/views/log_in_page.dart';

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
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  String? _tipoUsuario;
  String? _selectedCarrera;
  List<String> _carrerasVisibles = [];
  Map<String, String> _carrerasMap = {};
  bool _isLoadingCarreras = false;

  String? _selectedDepartamento;
  List<String> _departamentosVisibles = [];
  Map<String, String> _departamentosMap = {};
  bool _isLoadingDepartamentos = false;

  DateTime? _selectedBirthday;
  bool _obscurePasswords = true;

  @override
  void initState() {
    super.initState();
    _loadCarreras();
    _loadDepartamentos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthdayController.dispose();
    _carnetController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: const Color(0xFF64748B),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFD8305), width: 2),
      ),
    );
  }

  void _updateBirthdayController() {
    if (_selectedBirthday != null) {
      _birthdayController.text =
      '${_selectedBirthday!.day.toString().padLeft(2, '0')}/'
          '${_selectedBirthday!.month.toString().padLeft(2, '0')}/'
          '${_selectedBirthday!.year}';
    }
  }

  Future<void> _loadCarreras() async {
    setState(() => _isLoadingCarreras = true);
    try {
      final qs = await _firestore.collection('carreras').get();
      final m = <String,String>{};
      final v = <String>[];
      for (var d in qs.docs) {
        final nombre = d.data()['nombre'] ?? d.id;
        m[nombre] = d.id;
        v.add(nombre);
      }
      v.sort();
      setState(() {
        _carrerasMap = m;
        _carrerasVisibles = v;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar carreras: $e')));
      setState(() {
        _carrerasMap = {};
        _carrerasVisibles = [];
      });
    } finally {
      setState(() => _isLoadingCarreras = false);
    }
  }

  Future<void> _loadDepartamentos() async {
    setState(() => _isLoadingDepartamentos = true);
    try {
      final qs = await _firestore.collection('departamentos').get();
      final m = <String,String>{};
      final v = <String>[];
      for (var d in qs.docs) {
        final nombre = d.data()['nombre'] ?? d.id;
        m[nombre] = d.id;
        v.add(nombre);
      }
      v.sort();
      setState(() {
        _departamentosMap = m;
        _departamentosVisibles = v;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar departamentos: $e')));
      setState(() {
        _departamentosMap = {};
        _departamentosVisibles = [];
      });
    } finally {
      setState(() => _isLoadingDepartamentos = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_birthdayController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese su fecha de nacimiento')),
      );
      return;
    }

    DateTime? parsedBirthday;
    try {
      final parts = _birthdayController.text.split('/');
      parsedBirthday = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fecha inválida')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    if (_tipoUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un tipo de usuario')),
      );
      return;
    }

    if (_tipoUsuario == 'estudiante' && _selectedCarrera == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una carrera')),
      );
      return;
    }

    if (_tipoUsuario == 'profesor' && _selectedDepartamento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un departamento')),
      );
      return;
    }

    final carnetText = _carnetController.text.trim();
    final carnetInt = int.tryParse(carnetText);
    if (carnetInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El Nro. Carnet debe ser un número entero')),
      );
      return;
    }
    final existingCarnet = await _firestore
        .collection('usuarios')
        .where('uni_card', isEqualTo: carnetInt)
        .get();
    if (existingCarnet.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya existe un usuario con ese número de carnet')),
      );
      return;
    }

    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCred.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear usuario')),
        );
        return;
      }

      final now = DateTime.now();
      final userData = {
        'userId': user.uid,
        'fullName': '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
        'username': _emailController.text.split('@')[0],
        'email': _emailController.text.trim(),
        'birthday': parsedBirthday,
        'profileImageUrl': '',
        'role': _tipoUsuario == 'estudiante' ? 'student' : 'professor',
        'createdAt': now,
        'lastLoginAt': now,
        'uni_card': carnetInt,
        'phone': _telefonoController.text.trim(),
      };

      if (_tipoUsuario == 'estudiante') {
        final carreraCode = _carrerasMap[_selectedCarrera]!;
        userData['major'] = carreraCode;
        userData['dateOfEnrollment'] = now;
        userData['credits'] = 0;
      } else if (_tipoUsuario == 'profesor') {
        final deptCode = _departamentosMap[_selectedDepartamento]!;
        userData['department'] = deptCode;
        userData['assignedCourses'] = [];
        userData['dateOfHiring'] = now;
      }

      await _firestore.collection('usuarios').doc(user.uid).set(userData);

      if (_tipoUsuario == 'estudiante') {
        final carreraCode = _carrerasMap[_selectedCarrera]!;
        final fluId = carreraCode.replaceFirst(RegExp(r'^[A-Z]+'), 'FLU');
        final fluDoc = await _firestore.collection('flujogramas').doc(fluId).get();
        if (fluDoc.exists) {
          final orig = fluDoc.data();
          if (orig != null && orig.isNotEmpty) {
            final en = <String, dynamic>{};
            orig.forEach((k,v){
              if (v is Map<String,dynamic>) {
                en[k] = {...v, 'estado':'no_aprobada','nota':null};
              } else {
                en[k] = {'nombre':v.toString(),'estado':'no_aprobada','nota':null};
              }
            });
            await _firestore
                .collection('usuarios').doc(user.uid)
                .collection('flujogramas').doc(fluId).set(en);
            final reqs = await _firestore
                .collection('flujogramas').doc(fluId)
                .collection('requisitos_adicionales').get();
            for (final d in reqs.docs) {
              await _firestore
                  .collection('usuarios').doc(user.uid)
                  .collection('requisitos_adicionales').doc(d.id)
                  .set(d.data());
            }
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado exitosamente')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // LADO IZQUIERDO: FORMULARIO
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFFFD8305)),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LandingPage()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu cuenta',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa tus credenciales para empezar con tu nueva cuenta',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nombre
                        TextFormField(
                          controller: _nombreController,
                          decoration: _inputStyle('Nombre'),
                          style: GoogleFonts.poppins(color: Colors.black87),
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Ingrese su nombre' : null,
                        ),
                        const SizedBox(height: 16),

                        // Apellido
                        TextFormField(
                          controller: _apellidoController,
                          decoration: _inputStyle('Apellido'),
                          style: GoogleFonts.poppins(color: Colors.black87),
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Ingrese su apellido' : null,
                        ),
                        const SizedBox(height: 16),

                        // Correo institucional con validación de dominio
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputStyle('Correo institucional'),
                          style: GoogleFonts.poppins(color: Colors.black87),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese su email';
                            }
                            if (!(value.endsWith('@unimet.edu.ve') ||
                                value.endsWith('@correo.unimet.edu.ve'))) {
                              return 'Debe usar un correo académico';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Fecha de nacimiento
                        Text(
                          'Fecha de nacimiento',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Theme(
                          data: ThemeData.light().copyWith(
                            canvasColor: Colors.white,
                            inputDecorationTheme: const InputDecorationTheme(
                              fillColor: Colors.white,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<int>(
                                  decoration: _inputStyle('Día'),
                                  value: _selectedBirthday?.day,
                                  items: List.generate(31, (i) => i + 1)
                                      .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      if (_selectedBirthday != null) {
                                        _selectedBirthday = DateTime(
                                          _selectedBirthday!.year,
                                          _selectedBirthday!.month,
                                          val!,
                                        );
                                      } else {
                                        _selectedBirthday = DateTime(2000, 1, val!);
                                      }
                                      _updateBirthdayController();
                                    });
                                  },
                                  validator: (_) =>
                                  _selectedBirthday == null ? 'Selecciona una fecha' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<int>(
                                  decoration: _inputStyle('Mes'),
                                  value: _selectedBirthday?.month,
                                  items: List.generate(12, (i) => i + 1)
                                      .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      if (_selectedBirthday != null) {
                                        _selectedBirthday = DateTime(
                                          _selectedBirthday!.year,
                                          val!,
                                          _selectedBirthday!.day,
                                        );
                                      } else {
                                        _selectedBirthday = DateTime(2000, val!, 1);
                                      }
                                      _updateBirthdayController();
                                    });
                                  },
                                  validator: (_) =>
                                  _selectedBirthday == null ? 'Selecciona una fecha' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<int>(
                                  decoration: _inputStyle('Año'),
                                  value: _selectedBirthday?.year,
                                  items: List.generate(
                                      DateTime.now().year - 1900 - 10,
                                          (i) => DateTime.now().year - 10 - i)
                                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      if (_selectedBirthday != null) {
                                        _selectedBirthday = DateTime(
                                          val!,
                                          _selectedBirthday!.month,
                                          _selectedBirthday!.day,
                                        );
                                      } else {
                                        _selectedBirthday = DateTime(val!, 1, 1);
                                      }
                                      _updateBirthdayController();
                                    });
                                  },
                                  validator: (_) =>
                                  _selectedBirthday == null ? 'Selecciona una fecha' : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nro. Carnet
                        TextFormField(
                          controller: _carnetController,
                          decoration: _inputStyle('Nro. Carnet'),
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: Colors.black87),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese Nro. de Carnet';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Solo pueden ser números enteros';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Número de teléfono
                        TextFormField(
                          controller: _telefonoController,
                          decoration: _inputStyle('Número de teléfono'),
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.poppins(color: Colors.black87),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese su número de teléfono';
                            }
                            final phoneRegex = RegExp(r'^[0-9]+$');
                            if (!phoneRegex.hasMatch(value)) {
                              return 'Solo se aceptan números';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Contraseña
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePasswords,
                          decoration: _inputStyle('Contraseña').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePasswords ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () {
                                setState(() => _obscurePasswords = !_obscurePasswords);
                              },
                            ),
                          ),
                          style: GoogleFonts.poppins(color: Colors.black87),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese contraseña';
                            }
                            if (value.length < 8) {
                              return 'La contraseña debe tener al menos 8 caracteres';
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return 'Debe contener al menos una mayúscula';
                            }
                            if (!RegExp(r'[a-z]').hasMatch(value)) {
                              return 'Debe contener al menos una minúscula';
                            }
                            if (!RegExp(r'\d').hasMatch(value)) {
                              return 'Debe contener al menos un número';
                            }
                            if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                              return 'Debe contener al menos un carácter especial';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirmar contraseña
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscurePasswords,
                          decoration: _inputStyle('Confirmar contraseña'),
                          style: GoogleFonts.poppins(color: Colors.black87),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirme contraseña';
                            }
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        Theme(
                          data: ThemeData.light().copyWith(
                            canvasColor: Colors.white,
                            inputDecorationTheme: const InputDecorationTheme(
                              fillColor: Colors.white,
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _tipoUsuario,
                            decoration: _inputStyle('Tipo de usuario'),
                            style: GoogleFonts.poppins(color: Colors.black),
                            items: const [
                              DropdownMenuItem(value: 'estudiante', child: Text('Estudiante')),
                              DropdownMenuItem(value: 'profesor', child: Text('Profesor')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _tipoUsuario = val;
                                _selectedCarrera = null;
                                _selectedDepartamento = null;
                              });
                            },
                            validator: (value) =>
                            value == null ? 'Seleccione tipo de usuario' : null,
                          ),
                        ),

                        if (_tipoUsuario == 'estudiante') ...[
                          const SizedBox(height: 16),
                          _isLoadingCarreras
                              ? const Center(child: CircularProgressIndicator())
                              : Theme(
                            data: ThemeData.light().copyWith(
                              canvasColor: Colors.white,
                              inputDecorationTheme: const InputDecorationTheme(
                                fillColor: Colors.white,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedCarrera != null &&
                                  _carrerasVisibles.contains(_selectedCarrera)
                                  ? _selectedCarrera
                                  : null,
                              decoration: _inputStyle('Carrera'),
                              style: GoogleFonts.poppins(color: Colors.black),
                              items: _carrerasVisibles
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCarrera = val;
                                });
                              },
                              validator: (value) =>
                              value == null ? 'Seleccione carrera' : null,
                            ),
                          ),
                        ],

                        if (_tipoUsuario == 'profesor') ...[
                          const SizedBox(height: 16),
                          _isLoadingDepartamentos
                              ? const Center(child: CircularProgressIndicator())
                              : Theme(
                            data: ThemeData.light().copyWith(
                              canvasColor: Colors.white,
                              inputDecorationTheme: const InputDecorationTheme(
                                fillColor: Colors.white,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedDepartamento,
                              decoration: _inputStyle('Departamento'),
                              style: GoogleFonts.poppins(color: Colors.black),
                              items: _departamentosVisibles
                                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedDepartamento = val;
                                });
                              },
                              validator: (value) =>
                              value == null ? 'Seleccione departamento' : null,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFD8305),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Crear Cuenta',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "¿Ya tienes una cuenta?",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              child: Text(
                                "Inicia sesión aquí",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFFFD8305),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // LADO DERECHO: PANEL NARANJA
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFFFD8305),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade300.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/sign_up.png',
                        width: 400,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Gestiona tu progreso académico',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mantén un seguimiento detallado de\ntu avance con herramientas intuitivas\ny reportes personalizados',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
