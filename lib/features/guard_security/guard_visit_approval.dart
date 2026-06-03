import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuardVisitApprovalScreen extends StatelessWidget {
  const GuardVisitApprovalScreen({super.key});

  Future<void> _cambiarEstadoVisita(BuildContext context, String docId, String nuevoEstado) async {
    // 1. Guardamos al mensajero ANTES de hacer la operación asíncrona
    final mensajero = ScaffoldMessenger.of(context);

    try {
      // 2. Hacemos el cambio en Firebase
      await FirebaseFirestore.instance.collection('visitas').doc(docId).update({
        'estado': nuevoEstado,
      });
      
      // 3. Usamos el mensajero guardado (ya no usamos el 'context' que se destruyó)
      mensajero.showSnackBar(
        SnackBar(
          content: Text(nuevoEstado == 'aprobado' ? '✅ Visita Aprobada' : '❌ Visita Rechazada'),
          backgroundColor: nuevoEstado == 'aprobado' ? Colors.green : Colors.redAccent,
        ),
      );
    } catch (e) {
      mensajero.showSnackBar(
        SnackBar(content: Text('Error al procesar: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1121),
        title: const Text('Aprobar Solicitudes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('visitas').where('estado', isEqualTo: 'pendiente').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, color: Colors.grey, size: 60),
                  SizedBox(height: 16),
                  Text('No hay solicitudes pendientes', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docId = docs[index].id;
              final data = docs[index].data() as Map<String, dynamic>;

              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Solicitante: ${data['familiar_nombre'] ?? 'Desconocido'}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.grey),
                      Text('Visitará a: ${data['interno_nombre'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text('Fecha programada: ${data['fecha_visita'] ?? '-'} a las ${data['hora_visita'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _cambiarEstadoVisita(context, docId, 'rechazado'),
                            icon: const Icon(Icons.close, color: Colors.redAccent),
                            label: const Text('Rechazar', style: TextStyle(color: Colors.redAccent)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _cambiarEstadoVisita(context, docId, 'aprobado'),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('APROBAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}