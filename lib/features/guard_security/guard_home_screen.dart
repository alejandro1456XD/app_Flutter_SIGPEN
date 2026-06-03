import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import 'guard_visit_approval.dart';

class GuardHomeScreen extends StatefulWidget {
  const GuardHomeScreen({super.key});

  @override
  State<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends State<GuardHomeScreen> {
  int _selectedIndex = 0;
  bool _isProcessingScan = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessingScan) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() => _isProcessingScan = true);
      Navigator.pop(context); // Cierra la cámara
      await _verificarVisitaEnFirestore(barcodes.first.rawValue!);
      setState(() => _isProcessingScan = false);
    }
  }

  Future<void> _verificarVisitaEnFirestore(String visitId) async {
    try {
      DocumentSnapshot visitDoc = await FirebaseFirestore.instance.collection('visitas').doc(visitId).get();
      if (!mounted) return;
      if (visitDoc.exists) {
        final data = visitDoc.data() as Map<String, dynamic>;
        String estado = data['estado'] ?? 'desconocido';

        if (estado == 'aprobado') {
          // AQUÍ ES DONDE PASA LA MAGIA: Cambia a ingresado automáticamente
          await visitDoc.reference.update({'estado': 'ingresado', 'hora_ingreso_real': FieldValue.serverTimestamp()});
          _showCustomDialog("ACCESO AUTORIZADO", "Visitante: ${data['familiar_nombre']}\nVisita a: ${data['interno_nombre']}", Colors.green, Icons.check_circle);
        } else if (estado == 'ingresado') {
          _showCustomDialog("ALERTA", "Este visitante ya registró su ingreso.", Colors.orange, Icons.warning);
        } else {
          _showCustomDialog("ACCESO DENEGADO", "Solicitud en estado: ${estado.toUpperCase()}", Colors.redAccent, Icons.cancel);
        }
      } else {
        _showCustomDialog("CÓDIGO INVÁLIDO", "Código no registrado en SIGPEN.", Colors.red, Icons.error);
      }
    } catch (e) {
      if (mounted) _showCustomDialog("ERROR", "Fallo de red.", Colors.grey, Icons.wifi_off);
    }
  }

  void _showCustomDialog(String title, String subtitle, Color color, IconData icon) {
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1E293B), title: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)))]), content: Text(subtitle, style: const TextStyle(color: Colors.white)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CERRAR", style: TextStyle(color: Colors.grey)))]));
  }

  // --- BOTONES ARREGLADOS Y CONECTADOS ---
  void _reportarIncidente() {
    final TextEditingController reporteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Reportar Incidente", style: TextStyle(color: Colors.orange)),
        content: TextField(controller: reporteController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Describa la emergencia...", hintStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Color(0xFF0F172A), border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (reporteController.text.isNotEmpty) {
                // Guarda la alerta en Firebase
                await FirebaseFirestore.instance.collection('alertas').add({
                  'descripcion': reporteController.text, 'fecha': FieldValue.serverTimestamp(), 'estado': 'activa'
                });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta enviada a Central.'), backgroundColor: Colors.orange));
              }
            },
            child: const Text("ENVIAR ALERTA", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1121), title: const Text('Interfaz de Seguridad', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () async { await FirebaseAuth.instance.signOut(); if (!mounted) return; Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())); }),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActiveShiftHeader((snapshot.data?.data() as Map<String, dynamic>?)?['nombre'] ?? 'Guardia'), const SizedBox(height: 20),
                _buildActionGrid(), const SizedBox(height: 20), _buildQRScannerButton(), const SizedBox(height: 30),
                _buildWaitingList(), const SizedBox(height: 30), _buildRecentActivity(),
              ],
            ),
          );
        }
      ),
      bottomNavigationBar: BottomNavigationBar(backgroundColor: const Color(0xFF0B1121), type: BottomNavigationBarType.fixed, selectedItemColor: const Color(0xFF06B6D4), unselectedItemColor: Colors.grey, currentIndex: _selectedIndex, onTap: (index) => setState(() => _selectedIndex = index), items: const [BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Control'), BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Bitácora'), BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Rondas'), BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes')]),
    );
  }

  Widget _buildActiveShiftHeader(String nombreGuardia) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF166534).withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.5))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.security, color: Colors.green, size: 32), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('TURNO ACTIVO', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)), Text('Oficial: $nombreGuardia', style: const TextStyle(color: Colors.white, fontSize: 12)), const Text('Puerta Principal', style: TextStyle(color: Colors.grey, fontSize: 11))])]), const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('ACTIVO', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text('Sistema en línea', style: TextStyle(color: Colors.grey, fontSize: 10))])]));
  }

  Widget _buildActionGrid() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _buildGridButton(Icons.person_add, 'Registrar\nIngreso', 'Staff', Colors.blue, () => _showCustomDialog("Staff", "Acerque tarjeta RFID.", Colors.blue, Icons.nfc))), 
          const SizedBox(width: 16), 
          Expanded(child: _buildGridButton(Icons.badge, 'Aprobar\nVisitas', 'Solicitudes', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GuardVisitApprovalScreen()))))
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildGridButton(Icons.warning_amber_rounded, 'Reportar\nIncidente', 'Emergencias', Colors.orange, _reportarIncidente)), 
          const SizedBox(width: 16), 
          Expanded(child: _buildGridButton(Icons.videocam, 'Ver CCTV', 'Cámaras', Colors.purple, () => _showCustomDialog("CCTV", "Conectando al servidor de cámaras locales...", Colors.purple, Icons.videocam)))
        ]),
      ],
    );
  }

  Widget _buildGridButton(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)), child: Column(children: [Icon(icon, color: color, size: 36), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, height: 1.2)), const SizedBox(height: 6), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 10))])));
  }

  Widget _buildQRScannerButton() {
    return SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.black, builder: (context) => SizedBox(height: MediaQuery.of(context).size.height * 0.7, child: Stack(children: [MobileScanner(onDetect: _onDetect), Positioned(top: 20, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))), const Center(child: Text("[ ENFOQUE EL QR AQUÍ ]", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 2)))]))), icon: const Icon(Icons.qr_code_scanner, color: Colors.white), label: const Text('ESCANEAR PASE QR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), side: const BorderSide(color: Color(0xFF06B6D4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))));
  }

  Widget _buildWaitingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('visitas').where('estado', isEqualTo: 'aprobado').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.hourglass_top, color: Colors.orange, size: 18), const SizedBox(width: 8), Text('En Espera (Por ingresar) (${docs.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]), const SizedBox(height: 16), if (docs.isEmpty) const Text('Nadie en espera.', style: TextStyle(color: Colors.grey, fontSize: 13)), ...docs.map((doc) => Padding(padding: const EdgeInsets.only(bottom: 12.0), child: _buildListCard((doc.data() as Map<String, dynamic>)['familiar_nombre'] ?? '', (doc.data() as Map<String, dynamic>)['interno_nombre'] ?? '', Icons.person, Colors.orange)))]);
      },
    );
  }

  Widget _buildRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('visitas').where('estado', isEqualTo: 'ingresado').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ingresos Recientes (Ya dentro)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 16), if (docs.isEmpty) const Text('Sin ingresos recientes.', style: TextStyle(color: Colors.grey, fontSize: 13)), ...docs.map((doc) => Padding(padding: const EdgeInsets.only(bottom: 12.0), child: _buildListCard((doc.data() as Map<String, dynamic>)['familiar_nombre'] ?? '', (doc.data() as Map<String, dynamic>)['interno_nombre'] ?? '', Icons.login, Colors.green)))]);
      },
    );
  }

  Widget _buildListCard(String name, String interno, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)), child: Row(children: [CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), Text('Visita a: $interno', style: const TextStyle(color: Colors.white70, fontSize: 12))]))]));
  }
}