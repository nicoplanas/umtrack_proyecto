import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _fromTimestampOrDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    return DateTime.parse(value);
  } else if (value is DateTime) {
    return value;
  } else {
    throw Exception('Tipo inesperado para fecha: $value');
  }
}

/// Clase base con campos comunes a todos los usuarios
abstract class BaseUser {
  final String userId;
  final String fullName;
  final String username;
  final String email;
  final DateTime birthday;
  final String profileImageUrl;
  final String role;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  BaseUser({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.birthday,
    required this.profileImageUrl,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
  });
}

/// Usuario tipo estudiante
class StudentUser extends BaseUser {
  final String major;
  final List<dynamic> passedCourses;
  final DateTime dateOfEnrollment;
  final int credits;

  StudentUser({
    required super.userId,
    required super.fullName,
    required super.username,
    required super.email,
    required super.birthday,
    required super.profileImageUrl,
    required super.role,
    required super.createdAt,
    required super.lastLoginAt,
    required this.major,
    required this.passedCourses,
    required this.dateOfEnrollment,
    required this.credits,
  });

  factory StudentUser.fromJson(Map<String, dynamic> json) => StudentUser(
    userId: json['userId'],
    fullName: json['fullName'],
    username: json['username'],
    email: json['email'],
    birthday: _fromTimestampOrDate(json['birthday']),
    profileImageUrl: json['profileImageUrl'],
    role: json['role'],
    createdAt: _fromTimestampOrDate(json['createdAt']),
    lastLoginAt: _fromTimestampOrDate(json['lastLoginAt']),
    major: json['major'],
    passedCourses: List<dynamic>.from(json['passedCourses']),
    dateOfEnrollment: _fromTimestampOrDate(json['dateOfEnrollment']),
    credits: json['credits'],
  );
}

/// Usuario tipo profesor
class ProfessorUser extends BaseUser {
  final List<dynamic> assignedCourses;
  final DateTime dateOfHiring;

  ProfessorUser({
    required super.userId,
    required super.fullName,
    required super.username,
    required super.email,
    required super.birthday,
    required super.profileImageUrl,
    required super.role,
    required super.createdAt,
    required super.lastLoginAt,
    required this.assignedCourses,
    required this.dateOfHiring,
  });

  factory ProfessorUser.fromJson(Map<String, dynamic> json) => ProfessorUser(
    userId: json['userId'],
    fullName: json['fullName'],
    username: json['username'],
    email: json['email'],
    birthday: _fromTimestampOrDate(json['birthday']),
    profileImageUrl: json['profileImageUrl'],
    role: json['role'],
    createdAt: _fromTimestampOrDate(json['createdAt']),
    lastLoginAt: _fromTimestampOrDate(json['lastLoginAt']),
    assignedCourses: List<dynamic>.from(json['assignedCourses']),
    dateOfHiring: _fromTimestampOrDate(json['dateOfHiring']),
  );
}

/// Método de fábrica para cargar desde un DocumentSnapshot
Future<BaseUser> userFromDocument(DocumentSnapshot doc) async {
  final json = doc.data() as Map<String, dynamic>;
  final role = json['role'];

  switch (role) {
    case 'student':
      return StudentUser.fromJson(json);
    case 'professor':
      return ProfessorUser.fromJson(json);
    default:
      throw Exception('Rol de usuario desconocido: $role');
  }
}