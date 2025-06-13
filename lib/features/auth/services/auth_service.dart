import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart'; // asegúrate de tener BaseUser, StudentUser y ProfessorUser aquí

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Registro con email/password para estudiante o profesor
  Future<UserCredential> registerWithEmail({
    required String role, // 'student' o 'professor'
    required String fullName,
    required String username,
    required String email,
    required String password,
    required DateTime birthday,
    String? major, // para estudiantes
    DateTime? dateOfEnrollment,// para estudiantes
    List<dynamic>? assignedCourses, // para profesores
    DateTime? dateOfHiring,// para profesores
    int? credits, // para estudiantes
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user!;
    final now = DateTime.now();

    Map<String, dynamic> userJson;

    if (role == 'student') {
      final student = StudentUser(
          userId: user.uid,
          fullName: fullName,
          username: username,
          email: email,
          birthday: birthday,
          profileImageUrl: '',
          role: 'student',
          createdAt: now,
          lastLoginAt: now,
          major: major ?? '',
          dateOfEnrollment: dateOfEnrollment ?? now,
          credits: credits ?? 0
      );
      userJson = _studentToJson(student);
    } else if (role == 'professor') {
      final professor = ProfessorUser(
        userId: user.uid,
        fullName: fullName,
        username: username,
        email: email,
        birthday: birthday,
        profileImageUrl: '',
        role: 'professor',
        createdAt: now,
        lastLoginAt: now,
        assignedCourses: assignedCourses ?? [],
        dateOfHiring: dateOfHiring ?? now,
      );
      userJson = _professorToJson(professor);
    } else {
      throw Exception('Rol desconocido: $role');
    }

    await _db.collection('users').doc(user.uid).set(userJson);
    return result;
  }

  /// Actualiza la fecha de último login
  Future<void> updateLastLogin(String uid) async {
    await _db
        .collection('users')
        .doc(uid)
        .update({'lastLoginAt': DateTime.now().toIso8601String()});
  }

  /// Obtiene el usuario correcto según el rol
  Future<BaseUser> getUserModelOnce(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return userFromDocument(doc);
  }

  /// Stream de usuario según el rol
  Stream<BaseUser> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().asyncMap(userFromDocument);
  }

  /// Métodos para serializar
  Map<String, dynamic> _studentToJson(StudentUser user) => {
    'userId': user.userId,
    'fullName': user.fullName,
    'username': user.username,
    'email': user.email,
    'birthday': user.birthday.toIso8601String(),
    'profileImageUrl': user.profileImageUrl,
    'role': user.role,
    'createdAt': user.createdAt.toIso8601String(),
    'lastLoginAt': user.lastLoginAt.toIso8601String(),
    'major': user.major,
    'dateOfEnrollment': user.dateOfEnrollment.toIso8601String(),
  };

  Map<String, dynamic> _professorToJson(ProfessorUser user) => {
    'userId': user.userId,
    'fullName': user.fullName,
    'username': user.username,
    'email': user.email,
    'birthday': user.birthday.toIso8601String(),
    'profileImageUrl': user.profileImageUrl,
    'role': user.role,
    'createdAt': user.createdAt.toIso8601String(),
    'lastLoginAt': user.lastLoginAt.toIso8601String(),
    'assignedCourses': user.assignedCourses,
    'dateOfHiring': user.dateOfHiring.toIso8601String(),
  };
}