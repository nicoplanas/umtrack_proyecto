import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/widgets/navbar.dart';
import '../../../features/profile/widgets/profile_settings_student.dart';
import '../../../core/widgets/footer.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final email = user?.email ?? 'Guest';

        return Scaffold(
          body: ListView(
            children: [
              Navbar(email: email),
              ProfileSettings(),
              Footer(),
            ],
          ),
        );
      },
    );
  }
}