import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_evaluation.dart'; // Ajusta la ruta según la ubicación de tu modelo Evaluacion

class Horario {
  final List<String> dias;
  final String horaInicio;
  final String horaFin;

  Horario({
    required this.dias,
    required this.horaInicio,
    required this.horaFin,
  });

  factory Horario.fromMap(Map<String, dynamic> map) {
    return Horario(
      dias: List<String>.from(map['dias'] as List<dynamic>? ?? []),
      horaInicio: map['horaInicio'] as String? ?? '',
      horaFin: map['horaFin'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dias': dias,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
    };
  }
}

class Clase {
  final String materiaId;
  final String nombreMateria;
  final int cantidadClases;
  final String profesorId;
  final String profesorNombre;
  final String periodo;
  final Horario horario;
  final String aula;
  final int capacidadMaxima;
  final String estado;
  final DateTime fechaCreacion;
  final Map<String, dynamic> estudiantes;
  final Map<String, Evaluacion> evaluaciones;
  final Map<String, dynamic> contenidos;
  final Map<String, Map<String, String>> infoClases;

  Clase({
    required this.materiaId,
    required this.nombreMateria,
    required this.cantidadClases,
    required this.profesorId,
    required this.profesorNombre,
    required this.periodo,
    required this.horario,
    required this.aula,
    required this.capacidadMaxima,
    required this.estado,
    required this.fechaCreacion,
    required this.estudiantes,
    required this.evaluaciones,
    required this.contenidos,
    required this.infoClases,
  });

  factory Clase.fromMap(String id, Map<String, dynamic> map) {
    // parse evaluaciones anidado
    final rawEvals = map['evaluaciones'] as Map<String, dynamic>? ?? {};
    final evals = rawEvals.map((key, value) =>
        MapEntry(key, Evaluacion.fromMap(key, value as Map<String, dynamic>))
    );

    // parse infoClases anidado
    final rawInfo = map['infoClases'] as Map<String, dynamic>? ?? {};
    final info = rawInfo.map((sem, clases) =>
        MapEntry(
          sem,
          (clases as Map<String, dynamic>).map(
                (clKey, date) => MapEntry(clKey, date as String),
          ),
        ),
    );

    return Clase(
      materiaId: map['materiaId'] as String? ?? '',
      nombreMateria: map['nombreMateria'] as String? ?? '',
      cantidadClases: (map['cantidadClases'] as num?)?.toInt() ?? 0,
      profesorId: map['profesorId'] as String? ?? '',
      profesorNombre: map['profesorNombre'] as String? ?? '',
      periodo: map['periodo'] as String? ?? '',
      horario: Horario.fromMap(map['horario'] as Map<String, dynamic>? ?? {}),
      aula: map['aula'] as String? ?? '',
      capacidadMaxima: (map['capacidadMaxima'] as num?)?.toInt() ?? 0,
      estado: map['estado'] as String? ?? '',
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      estudiantes: Map<String, dynamic>.from(map['estudiantes'] as Map? ?? {}),
      evaluaciones: evals,
      contenidos: Map<String, dynamic>.from(map['contenidos'] as Map? ?? {}),
      infoClases: info,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materiaId': materiaId,
      'nombreMateria': nombreMateria,
      'cantidadClases': cantidadClases,
      'profesorId': profesorId,
      'profesorNombre': profesorNombre,
      'periodo': periodo,
      'horario': horario.toMap(),
      'aula': aula,
      'capacidadMaxima': capacidadMaxima,
      'estado': estado,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'estudiantes': estudiantes,
      'evaluaciones': evaluaciones.map((k, v) => MapEntry(k, v.toMap())),
      'contenidos': contenidos,
      'infoClases': infoClases,
    };
  }
}