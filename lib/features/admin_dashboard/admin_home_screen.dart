import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'admin_register_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedMenuIndex = 0; // 0: Dashboard, 1: Internos, 2: Visitas, 3: Alertas

  Widget _buildMainContent(bool isMobile) {
    switch (_selectedMenuIndex) {
      case 0: return _buildDashboard(isMobile);
      case 1: return _buildInmatesList();
      case 2: return _buildVisitsList();
      case 3: return _buildAlertsList();
      default: return _buildDashboard(isMobile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF06B6D4), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminRegisterScreen())), child: const Icon(Icons.person_add, color: Colors.white)),
      appBar: isDesktop ? null : AppBar(backgroundColor: const Color(0xFF0B1121), title: const Text('Dashboard Admin', style: TextStyle(color: Colors.white, fontSize: 16)), iconTheme: const IconThemeData(color: Colors.white)),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
      body: isDesktop ? Row(children: [_buildSidebar(), Expanded(child: Column(children: [_buildTopBar(), Expanded(child: _buildMainContent(false))]))]) : _buildMainContent(true),
    );
  }

  Widget _buildDashboard(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Centro de Operaciones', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), const Text('Gestión penitenciaria en tiempo real.', style: TextStyle(color: Colors.grey)), const SizedBox(height: 24),
          _buildKPICards(isMobile: isMobile),
        ],
      ),
    );
  }

  // --- TARJETAS KPI (AHORA SON CLICKEABLES) ---
  Widget _buildKPICards({required bool isMobile}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('rol', isEqualTo: 'Interno').snapshots(),
      builder: (context, snapshotUsers) {
        final int totalInternos = snapshotUsers.hasData ? snapshotUsers.data!.docs.length : 0;
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('visitas').snapshots(),
          builder: (context, snapshotVisitas) {
            final visitas = snapshotVisitas.data?.docs ?? [];
            final pendientes = visitas.where((v) => (v.data() as Map<String, dynamic>)['estado'] == 'pendiente').length;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('alertas').snapshots(),
              builder: (context, snapshotAlertas) {
                final alertasActivas = snapshotAlertas.data?.docs.length ?? 0;

                final kpis = [
                  _buildSingleKPI('Población Penal', '$totalInternos', 'Ver internos', Icons.people, const Color(0xFF06B6D4), () => setState(() => _selectedMenuIndex = 1)),
                  _buildSingleKPI('Visitas Activas', '$pendientes', 'Ver solicitudes', Icons.contact_mail, Colors.orange, () => setState(() => _selectedMenuIndex = 2)),
                  _buildSingleKPI('Alertas', '$alertasActivas', 'Ver incidentes', Icons.warning, alertasActivas > 0 ? Colors.redAccent : Colors.green, () => setState(() => _selectedMenuIndex = 3), isAlert: alertasActivas > 0),
                ];

                return isMobile ? Column(children: kpis.map((kpi) => Padding(padding: const EdgeInsets.only(bottom: 16), child: kpi)).toList()) : Row(children: kpis.map((kpi) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: kpi))).toList());
              }
            );
          }
        );
      },
    );
  }

  Widget _buildSingleKPI(String title, String value, String subtitle, IconData icon, Color iconColor, VoidCallback onTap, {bool isAlert = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: isAlert ? Border.all(color: Colors.red.withOpacity(0.5)) : null),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)), Icon(icon, color: iconColor, size: 20)]), const SizedBox(height: 10), Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isAlert ? Colors.redAccent : Colors.white)), Text(subtitle, style: const TextStyle(color: Colors.blue, fontSize: 11, decoration: TextDecoration.underline))]),
      ),
    );
  }

  // --- LAS LISTAS INTERACTIVAS ---
  Widget _buildInmatesList() {
    return _buildGenericList('Listado de Internos', 'users', 'rol', 'Interno', Icons.person, (data) => data['nombre'] ?? 'Desconocido', (data) => 'Correo: ${data['email'] ?? 'N/A'}');
  }

  Widget _buildVisitsList() {
    return _buildGenericList('Gestión de Visitas', 'visitas', null, null, Icons.calendar_today, (data) => 'Visitante: ${data['familiar_nombre']} -> Interno: ${data['interno_nombre']}', (data) => 'Estado: ${(data['estado'] ?? 'pendiente').toString().toUpperCase()}');
  }

  Widget _buildAlertsList() {
    return _buildGenericList('Registro de Incidentes', 'alertas', null, null, Icons.warning_amber_rounded, (data) => data['descripcion'] ?? 'Alerta vacía', (data) => 'Estado: ${data['estado'] ?? 'activa'}', isAlert: true);
  }

  Widget _buildGenericList(String title, String collection, String? filterField, String? filterValue, IconData icon, String Function(Map<String, dynamic>) titleBuilder, String Function(Map<String, dynamic>) subtitleBuilder, {bool isAlert = false}) {
    Query query = FirebaseFirestore.instance.collection(collection);
    if (filterField != null && filterValue != null) query = query.where(filterField, isEqualTo: filterValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.all(24.0), child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('No hay registros', style: TextStyle(color: Colors.grey)));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24), itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return Card(color: const Color(0xFF1E293B), margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: Icon(icon, color: isAlert ? Colors.redAccent : Colors.teal), title: Text(titleBuilder(data), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text(subtitleBuilder(data), style: TextStyle(color: isAlert ? Colors.redAccent : Colors.grey))));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(width: 250, color: const Color(0xFF0B1121), child: Column(children: [const SizedBox(height: 50), const ListTile(leading: CircleAvatar(backgroundColor: Color(0xFF1E293B), child: Icon(Icons.shield, color: Colors.grey)), title: Text('Admin SIGPEN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text('San Sebastián', style: TextStyle(color: Colors.grey, fontSize: 11))), const SizedBox(height: 30), _buildSidebarItem(Icons.dashboard, 'Dashboard', 0), _buildSidebarItem(Icons.people, 'Internos', 1), _buildSidebarItem(Icons.calendar_today, 'Visitas', 2), _buildSidebarItem(Icons.warning_amber_rounded, 'Alertas', 3), const Spacer(), ListTile(leading: const Icon(Icons.logout, color: Colors.grey), title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.grey)), onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()))), const SizedBox(height: 20)]));
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    final isSelected = _selectedMenuIndex == index;
    return Container(color: isSelected ? const Color(0xFF06B6D4).withOpacity(0.1) : Colors.transparent, child: ListTile(leading: Icon(icon, color: isSelected ? const Color(0xFF06B6D4) : Colors.grey), title: Text(title, style: TextStyle(color: isSelected ? const Color(0xFF06B6D4) : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)), onTap: () { setState(() => _selectedMenuIndex = index); if (MediaQuery.of(context).size.width <= 800) Navigator.pop(context); }));
  }

  Widget _buildTopBar() { return Container(height: 70, padding: const EdgeInsets.symmetric(horizontal: 24), color: const Color(0xFF0F172A), child: Row(children: [Expanded(child: TextField(decoration: InputDecoration(hintText: 'Buscar interno...', hintStyle: const TextStyle(color: Colors.grey), prefixIcon: const Icon(Icons.search, color: Colors.grey), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)))), const SizedBox(width: 40), const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('22 Abr 2026', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text('15:47 Bolivia', style: TextStyle(color: Colors.grey, fontSize: 12))])])); }
}