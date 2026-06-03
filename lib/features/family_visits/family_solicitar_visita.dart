import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilySolicitarVisitaScreen extends StatefulWidget {
  const FamilySolicitarVisitaScreen({super.key});

  @override
  State<FamilySolicitarVisitaScreen> createState() => _FamilySolicitarVisitaScreenState();
}

class _FamilySolicitarVisitaScreenState extends State<FamilySolicitarVisitaScreen> {
  final TextEditingController _internoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  bool _isLoading = false;

  Future<void> _enviarSolicitud() async {
    if (_internoController.text.isEmpty || _fechaController.text.isEmpty || _horaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena todos los campos'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // 1. Buscamos el nombre real del familiar que está solicitando
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      String nombreFamiliar = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['nombre'] ?? 'Familiar' : 'Familiar';

      // 2. Guardamos la solicitud en la colección 'visitas' de Firebase
      await FirebaseFirestore.instance.collection('visitas').add({
        'familiar_uid': user?.uid,
        'familiar_nombre': nombreFamiliar,
        'interno_nombre': _internoController.text.trim(),
        'fecha_visita': _fechaController.text.trim(),
        'hora_visita': _horaController.text.trim(),
        'estado': 'pendiente', // IMPORTANTE: Entra como pendiente para que el admin la apruebe
        'fecha_solicitud': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Solicitud enviada correctamente'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Cierra esta pantalla y vuelve al panel del familiar
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e'), backgroundColor: Colors.redAccent),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _internoController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1121),
        title: const Text('Solicitar Visita', style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_calendar, color: Color(0xFF06B6D4), size: 28),
                    SizedBox(width: 10),
                    Text('Formulario de Solicitud', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Campo: Nombre del Interno
                TextField(
                  controller: _internoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre completo del Interno',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.person, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo: Fecha (Texto simple por ahora, ej: 25/10/2026)
                TextField(
                  controller: _fechaController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Fecha de visita (Ej: 25/10/2026)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo: Hora (Texto simple, ej: 14:30)
                TextField(
                  controller: _horaController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Hora aproximada (Ej: 14:30)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.access_time, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Botón de Enviar
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _enviarSolicitud,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ENVIAR SOLICITUD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}