import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart'; // <-- El nuevo paquete
import '../auth/login_screen.dart';
import 'family_solicitar_visita.dart';

class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  void _mostrarQR(BuildContext context, String visitId, String interno, String fecha) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, // Fondo blanco para que el escáner lo lea bien
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Text("PASE DE INGRESO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Visita a: $interno\nFecha: $fecha", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          ],
        ),
        content: SizedBox(
          width: 250, height: 250,
          child: Center(
            child: QrImageView(
              data: visitId, // Este es el código secreto que el Guardia va a escanear
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CERRAR", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1121), elevation: 0,
        title: const Text('Portal de Familiares', style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async { await FirebaseAuth.instance.signOut(); if (!mounted) return; Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())); },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)));
          final String nombreFamiliar = (snapshot.data?.data() as Map<String, dynamic>?)?['nombre'] ?? 'Familiar';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(nombreFamiliar), const SizedBox(height: 30),
                _buildRequestVisitButton(context), const SizedBox(height: 30),
                const Text('Mis Solicitudes de Visita', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildVisitsHistory(), 
              ],
            ),
          );
        }
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0B1121), type: BottomNavigationBarType.fixed, selectedItemColor: const Color(0xFF06B6D4), unselectedItemColor: Colors.grey, currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'), BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Agendar'), BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Normativas')],
      ),
    );
  }

  Widget _buildWelcomeCard(String nombre) {
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.3))), child: Row(children: [const CircleAvatar(radius: 30, backgroundColor: Color(0xFF0B1121), child: Icon(Icons.family_restroom, color: Color(0xFF06B6D4), size: 30)), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hola, $nombre', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 4), const Text('Toca una visita APROBADA para ver tu código QR.', style: TextStyle(color: Colors.greenAccent, fontSize: 13))]))]));
  }

  Widget _buildRequestVisitButton(BuildContext context) {
    return SizedBox(width: double.infinity, height: 60, child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilySolicitarVisitaScreen())), icon: const Icon(Icons.add_circle_outline, color: Colors.white), label: const Text('NUEVA SOLICITUD DE VISITA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 5)));
  }

  Widget _buildVisitsHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('visitas').where('familiar_uid', isEqualTo: currentUser?.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)));
        final visitas = snapshot.data?.docs ?? [];
        if (visitas.isEmpty) return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)), child: const Column(children: [Icon(Icons.calendar_today, color: Colors.grey, size: 40), SizedBox(height: 16), Text('Aún no has solicitado ninguna visita.', style: TextStyle(color: Colors.grey))]));

        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: visitas.length,
          itemBuilder: (context, index) {
            final data = visitas[index].data() as Map<String, dynamic>;
            final estado = data['estado'] ?? 'pendiente';
            Color colorEstado = estado == 'aprobado' ? Colors.green : (estado == 'rechazado' ? Colors.redAccent : (estado == 'ingresado' ? Colors.blue : Colors.orange));
            IconData iconoEstado = estado == 'aprobado' ? Icons.qr_code : (estado == 'rechazado' ? Icons.cancel : (estado == 'ingresado' ? Icons.login : Icons.access_time_filled));

            return GestureDetector(
              onTap: () {
                if (estado == 'aprobado') {
                  _mostrarQR(context, visitas[index].id, data['interno_nombre'] ?? 'Interno', data['fecha_visita'] ?? 'Fecha');
                } else if (estado == 'ingresado') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esta visita ya se realizó.'), backgroundColor: Colors.blue));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('La visita debe estar aprobada para generar el QR.'), backgroundColor: Colors.orange));
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: estado == 'aprobado' ? Border.all(color: Colors.green) : null),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(backgroundColor: colorEstado.withOpacity(0.2), child: Icon(iconoEstado, color: colorEstado)),
                  title: Text('Visita a: ${data['interno_nombre'] ?? 'Interno'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Fecha: ${data['fecha_visita'] ?? '-'} • Turno: ${data['hora_visita'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: colorEstado.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: colorEstado.withOpacity(0.5))), child: Text(estado.toUpperCase(), style: TextStyle(color: colorEstado, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
              ),
            );
          },
        );
      },
    );
  }
}