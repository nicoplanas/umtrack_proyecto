import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../features/classes/widgets/classes_details_professor.dart';
import '../../../core/widgets/footer.dart';

class ClassesDetailsProfessorPage extends StatelessWidget {
  final Map<String, dynamic> claseData;
  final String claseId;

  const ClassesDetailsProfessorPage({
    super.key,
    required this.claseData,
    required this.claseId,
  });

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
              ClassesDetailsProfessor(
                claseId: claseId,
                claseData: claseData,
              ),
              Footer(),
            ],
          ),
        );
      },
    );
  }
}
