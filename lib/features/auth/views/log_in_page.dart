import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../landing/views/landing_page.dart';
import '/features/auth/views/sign_up_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _rememberMe = false;

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey),
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

  void resetPassword(BuildContext context,
      TextEditingController emailController) async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese su correo electrónico')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo de recuperación enviado')),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Error';
      if (e.code == 'user-not-found') {
        message = 'No existe un usuario con ese correo.';
      } else if (e.code == 'invalid-email') {
        message = 'Correo inválido.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)));
    }
  }

  Future<void> signInWithGoogleWeb(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar con Google: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // LADO IZQUIERDO: LOGIN FORM
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(
                              Icons.arrow_back, color: Color(0xFFFD8305)),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LandingPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inicia sesión',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accede a tu cuenta para continuar',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Google Sign-In Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Image.network(
                              'https://res.cloudinary.com/doyt5r47e/image/upload/v1746128729/google_dogxyt.webp',
                              height: 20,
                            ),
                            label: Text(
                              "Iniciar sesión con Google",
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFFD8305)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => signInWithGoogleWeb(context),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: Color(0xFFFD8305))),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              child: Text("o", style: GoogleFonts.poppins(
                                  color: Color(0xFFFD8305))),
                            ),
                            const Expanded(
                                child: Divider(color: Color(0xFFFD8305))),
                          ],
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: emailController,
                          decoration: _inputStyle('Correo institucional'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Ingrese su email';
                            final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!regex.hasMatch(value)) return 'Email inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: _inputStyle('Contraseña'),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Ingrese su contraseña';
                            if (value.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  activeColor: const Color(0xFFFD8305),
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value!;
                                    });
                                  },
                                ),
                                Text(
                                  'Recordarme',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    final emailResetController = TextEditingController();
                                    return AlertDialog(
                                      title: const Text('Recuperar contraseña'),
                                      content: TextField(
                                        controller: emailResetController,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: const InputDecoration(hintText: 'Ingrese su correo'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFD8305)),
                                          onPressed: () async {
                                            resetPassword(context, emailResetController);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Enviar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: const Text(
                                "¿Olvidaste tu contraseña?",
                                style: TextStyle(color: Color(0xFFFD8305)),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFD8305),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                try {
                                  final authResult = await FirebaseAuth.instance
                                      .signInWithEmailAndPassword(
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                  );
                                  final user = authResult.user;
                                  if (user == null) {
                                    throw FirebaseAuthException(
                                        code: 'user-not-found',
                                        message: 'Usuario no encontrado');
                                  }
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (
                                        context) => const LandingPage()),
                                  );
                                } on FirebaseAuthException catch (e) {
                                  String message = 'Error al iniciar sesión';
                                  if (e.code == 'user-not-found') {
                                    message =
                                    'No existe un usuario con ese correo.';
                                  } else if (e.code == 'wrong-password') {
                                    message = 'Contraseña incorrecta.';
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Ingresar',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "¿No tienes cuenta?",
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.black),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (context) => const SignUpPage()),
                                );
                              },
                              child: Text(
                                "Regístrate",
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
                    'Bienvenido de nuevo',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gestiona tu avance académico\ny mantente al tanto de tu progreso',
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