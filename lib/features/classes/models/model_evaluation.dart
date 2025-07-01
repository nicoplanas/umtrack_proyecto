import 'package:cloud_firestore/cloud_firestore.dart';

class Evaluacion {
  final String id;

  final String nombre;
  final DateTime fecha;            // Fecha y hora de la evaluación
  final DateTime fechaCreacion;    // Fecha en que se creó el registro
  final String tipo;               // parcial / quiz / taller / tarea / exposición
  final String modalidad;          // Presencial / Virtual

  // Duración
  final int duracionTiempo;        // solo enteros
  final String duracionUnidad;     // minutos / horas

  // Ponderación
  final int porcentaje;            // porcentaje entero
  final double puntos;             // calculado = porcentaje * 20 / 100

  final String temas;

  Evaluacion({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.fechaCreacion,
    required this.tipo,
    required this.modalidad,
    required this.duracionTiempo,
    required this.duracionUnidad,
    required this.porcentaje,
    required this.puntos,
    required this.temas,
  });

  /// Crear instancia desde Firestore
  factory Evaluacion.fromMap(String id, Map<String, dynamic> map) {
    return Evaluacion(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      fecha: (map['fecha'] as Timestamp).toDate(),
      fechaCreacion: (map['fechaDeCreacion'] as Timestamp).toDate(),
      tipo: map['tipo'] as String? ?? '',
      modalidad: map['modalidad'] as String? ?? '',
      duracionTiempo: (map['duracion']?['tiempo'] as num?)?.toInt() ?? 0,
      duracionUnidad: map['duracion']?['unidad'] as String? ?? '',
      porcentaje: (map['ponderacion']?['porcentaje'] as num?)?.toInt() ?? 0,
      puntos: (map['ponderacion']?['puntos'] as num?)?.toDouble() ?? 0.0,
      temas: map['temas'] as String? ?? '',
    );
  }

  /// Convertir a mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'fecha': Timestamp.fromDate(fecha),
      'fechaDeCreacion': Timestamp.fromDate(fechaCreacion),
      'tipo': tipo,
      'modalidad': modalidad,
      'duracion': {
        'tiempo': duracionTiempo,
        'unidad': duracionUnidad,
      },
      'ponderacion': {
        'porcentaje': porcentaje,
        'puntos': puntos,
      },
      'temas': temas,
    };
  }
}