import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/widgets/navbar.dart';
import '../../../features/classes/widgets/evaluation_details.dart';  // Exporta `EvaluationDetails`
import '../../../core/widgets/footer.dart';

class EvaluationDetailsPage extends StatelessWidget {
  final String claseId;
  final String evalId;

  const EvaluationDetailsPage({
    Key? key,
    required this.claseId,
    required this.evalId,
  }) : super(key: key);

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
              EvaluationDetails(
                claseId: claseId,
                evalId: evalId,
              ),
              Footer(),
            ],
          ),
        );
      },
    );
  }
}
