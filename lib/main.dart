import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/landing/views/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const UMTrackApp());
}

class UMTrackApp extends StatelessWidget {
  const UMTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UMTrack',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111111),
        primaryColor: const Color(0xFF0085FF),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      initialRoute: '/landing',
      routes: {
        '/landing': (context) => const LandingPage(), // sin login
      },
    );
  }
}