import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AdditionalRequirements extends StatelessWidget {
  final String carreraId;

  const AdditionalRequirements({super.key, required this.carreraId});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      color: Colors.white, // <=== Fondo blanco forzado
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('flujogramas')
            .doc(carreraId)
            .collection('requisitos_adicionales')
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final Map<String, List<QueryDocumentSnapshot>> categorias = {
            'Idiomas': [],
            'Servicio Comunitario': [],
            'Trabajo de Tesis': [],
          };

          for (var doc in docs) {
            final tipo = doc['categoria'] ?? 'Otros';
            if (categorias.containsKey(tipo)) {
              categorias[tipo]!.add(doc);
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requerimientos Adicionales',
                  style: GoogleFonts.poppins(
                    fontSize: 35,
                    fontWeight: FontWeight.w700, // w700 = bold
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestiona tus requisitos complementarios',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                _buildResumen(categorias),
                const SizedBox(height: 20),
                const Divider(),
                ...categorias.entries.map((entry) => _buildCategoria(entry.key, entry.value)).toList(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Actualizar Progreso'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Generar Reporte'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumen(Map<String, List<QueryDocumentSnapshot>> categorias) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: categorias.entries.map((entry) {
        final total = entry.value.length;
        final completados = entry.value.where((doc) => doc['completado'] == true).length;
        Color color = Colors.black;
        if (entry.key == 'Idiomas') color = Colors.blue;
        if (entry.key == 'Servicio Comunitario') color = Colors.orange;
        if (entry.key == 'Trabajo de Tesis') color = Colors.purple;

        return Column(
          children: [
            Text(
              '$completados/$total',
              style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text(
              'Completados/Total',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCategoria(String titulo, List<QueryDocumentSnapshot> requisitos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...requisitos.map((req) {
          final nombre = req['nombre'] ?? '';
          final descripcion = req['descripcion'] ?? '';
          final completado = req['completado'] ?? false;
          final creditos = req['creditos'];
          final horas = req['horas'];

          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Checkbox(value: completado, onChanged: null),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(descripcion, style: const TextStyle(fontSize: 12, color: Colors.black)),
                    ],
                  ),
                ),
                if (creditos != null)
                  Text('$creditos créditos', style: const TextStyle(color: Colors.black)),
                if (horas != null)
                  Text('$horas horas', style: const TextStyle(color: Colors.black)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}