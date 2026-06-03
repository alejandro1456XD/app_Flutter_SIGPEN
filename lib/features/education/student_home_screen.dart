import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'computer': return Icons.computer;
      case 'handyman': return Icons.handyman;
      case 'language': return Icons.language_rounded;
      case 'lightbulb': return Icons.lightbulb;
      case 'book': return Icons.menu_book;
      default: return Icons.book;
    }
  }

  // --- REPRODUCTOR DE CURSOS INTERACTIVO ---
  void _abrirCurso(BuildContext context, Map<String, dynamic> curso, List<dynamic> cursosActuales, List<dynamic> logrosActuales) {
    int paginaActual = 0;
    
    // Lecciones simuladas dependiendo del curso que se haya tocado
    List<Map<String, String>> contenido = [];
    if (curso['id'] == 'reglamento') {
      contenido = [
        {'titulo': 'Introducción', 'texto': 'Bienvenido al curso de Reglamento Interno.\n\nConocer las normas es el primer paso para garantizar una convivencia pacífica y segura dentro del recinto.'},
        {'titulo': 'Normas Básicas', 'texto': '1. Respeto absoluto al personal de seguridad y a tus compañeros.\n2. Cumplimiento estricto de los horarios de patio y encierro en celdas.\n3. Prohibición total de contrabando.'},
        {'titulo': 'Beneficios', 'texto': 'Mantener un expediente limpio y completar estos cursos te sumará puntos clave para solicitar visitas extraordinarias y acceder a mejores talleres de trabajo.'},
      ];
    } else {
      contenido = [
        {'titulo': 'Welcome!', 'texto': 'Saber inglés te abrirá muchas puertas en el futuro. Empecemos con lo más básico para que puedas comunicarte.'},
        {'titulo': 'Saludos / Greetings', 'texto': 'Aprende a saludar:\n\n• Hello = Hola\n• Good morning = Buenos días\n• How are you? = ¿Cómo estás?'},
        {'titulo': 'Despedidas / Farewells', 'texto': 'Aprende a despedirte:\n\n• Goodbye = Adiós\n• See you later = Hasta luego\n• Have a good day = Que tengas un buen día'},
        {'titulo': 'Práctica Final', 'texto': 'Repite en voz alta: "Hello, good morning!".\n\n¡Excelente! Has dominado tu primera lección de inglés básico.'},
      ];
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Obliga al usuario a usar los botones para salir
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          bool esUltimaPagina = paginaActual == contenido.length - 1;
          
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(_getIconFromName(curso['icono']), color: const Color(0xFF06B6D4)),
                const SizedBox(width: 10),
                Expanded(child: Text(curso['titulo'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de progreso de la lección
                  LinearProgressIndicator(
                    value: (paginaActual + 1) / contenido.length,
                    backgroundColor: const Color(0xFF0F172A),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF06B6D4)),
                  ),
                  const SizedBox(height: 20),
                  Text(contenido[paginaActual]['titulo']!, style: const TextStyle(color: Color(0xFFEAB308), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(contenido[paginaActual]['texto']!, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text("SALIR", style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: esUltimaPagina ? Colors.green : const Color(0xFF06B6D4)),
                onPressed: () async {
                  if (esUltimaPagina) {
                    Navigator.pop(ctx); // Cierra el modal
                    await _marcarCursoCompletado(curso['id'], cursosActuales, logrosActuales); // Actualiza Firebase
                  } else {
                    setStateModal(() => paginaActual++); // Avanza de página
                  }
                },
                child: Text(esUltimaPagina ? "FINALIZAR CURSO" : "SIGUIENTE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      ),
    );
  }

  // --- LÓGICA PARA GUARDAR EN FIREBASE ---
  Future<void> _marcarCursoCompletado(String cursoId, List<dynamic> cursosActuales, List<dynamic> logrosActuales) async {
    // 1. Modificamos el progreso del curso al 100%
    List<dynamic> nuevosCursos = cursosActuales.map((c) {
      if (c['id'] == cursoId) {
        return {'id': c['id'], 'titulo': c['titulo'], 'modulo': c['modulo'], 'progreso': 1.0, 'icono': c['icono']};
      }
      return c;
    }).toList();

    // 2. Desbloqueamos el logro si aún no lo tiene
    List<dynamic> nuevosLogros = List.from(logrosActuales);
    bool ganoLogro = false;
    if (!nuevosLogros.contains('curso_terminado')) {
      nuevosLogros.add('curso_terminado');
      ganoLogro = true;
    }

    // 3. Subimos los datos actualizados a Firebase
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).set({
        'cursos': nuevosCursos,
        'logros_desbloqueados': nuevosLogros,
      }, SetOptions(merge: true));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ganoLogro ? '🎉 ¡Felicidades! Desbloqueaste un nuevo logro.' : '✅ Curso completado al 100%.'), 
          backgroundColor: Colors.green, duration: const Duration(seconds: 4)
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1121), elevation: 0,
        title: const Row(children: [Icon(Icons.school, color: Color(0xFFEAB308)), SizedBox(width: 10), Text('Portal Educativo', style: TextStyle(color: Colors.white, fontSize: 16))]),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.grey), onPressed: () async { await FirebaseAuth.instance.signOut(); if (!mounted) return; Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())); }),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFEAB308)));
          
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final String userName = data['nombre'] ?? 'Estudiante';
          
          // Verificamos si tiene cursos. Si no, le inyectamos los 2 obligatorios por defecto.
          List<dynamic> cursosBD = data['cursos'] ?? [];
          if (cursosBD.isEmpty) {
            cursosBD = [
              {'id': 'reglamento', 'titulo': 'Reglamento Interno', 'modulo': 'Normas y Convivencia', 'progreso': 0.0, 'icono': 'book'},
              {'id': 'ingles', 'titulo': 'Inglés Básico', 'modulo': 'Vocabulario Inicial', 'progreso': 0.0, 'icono': 'language'}
            ];
          }
          
          List<dynamic> logrosBD = data['logros_desbloqueados'] ?? [];

          // El cuerpo de la pantalla cambia según la pestaña que selecciones abajo
          Widget bodyContent;
          switch (_selectedIndex) {
            case 0: bodyContent = _buildHomeView(userName, cursosBD, logrosBD); break;
            case 1: bodyContent = _buildAllCoursesView(cursosBD, logrosBD); break;
            case 2: bodyContent = _buildAllAchievementsView(logrosBD); break;
            case 3: bodyContent = const Center(child: Text("Pantalla de Perfil (Próximamente)", style: TextStyle(color: Colors.grey))); break;
            default: bodyContent = _buildHomeView(userName, cursosBD, logrosBD);
          }

          return bodyContent;
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0B1121), type: BottomNavigationBarType.fixed, selectedItemColor: const Color(0xFFEAB308), unselectedItemColor: Colors.grey, currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Cursos'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Logros'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  // --- PESTAÑA 0: INICIO ---
  Widget _buildHomeView(String userName, List<dynamic> cursos, List<dynamic> logros) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(userName), const SizedBox(height: 40),
          _buildSectionTitle('Tus Cursos', 'Ver todos', () => setState(() => _selectedIndex = 1)), // El botón "Ver todos" te salta a la pestaña 1
          const SizedBox(height: 20),
          _buildDynamicCoursesList(cursos, logros), const SizedBox(height: 40),
          _buildSectionTitle('Logros Recientes', null, null), const SizedBox(height: 20),
          _buildAchievementsSection(logros),
        ],
      ),
    );
  }

  // --- PESTAÑA 1: LISTA COMPLETA DE CURSOS ---
  Widget _buildAllCoursesView(List<dynamic> cursos, List<dynamic> logros) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Cursos Disponibles', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: cursos.length,
            itemBuilder: (context, index) {
              final curso = cursos[index] as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildCourseCard(curso, cursos, logros, isFullWidth: true),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- PESTAÑA 2: LISTA DE LOGROS ---
  Widget _buildAllAchievementsView(List<dynamic> logros) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Medallas y Logros', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2, padding: const EdgeInsets.symmetric(horizontal: 20), crossAxisSpacing: 20, mainAxisSpacing: 20,
            children: [
              _buildAchievementGridItem(Icons.star, 'Bienvenida', 'Iniciaste sesión por primera vez.', const Color(0xFF06B6D4), !logros.contains('bienvenida')),
              _buildAchievementGridItem(Icons.menu_book, 'Estudioso', 'Completaste tu primer curso al 100%.', const Color(0xFFEAB308), !logros.contains('curso_terminado')),
              _buildAchievementGridItem(Icons.handshake, 'Buena Conducta', 'Sin incidentes reportados en 30 días.', Colors.grey, true), // Este siempre se verá bloqueado por ahora
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGETS VISUALES SECUNDARIOS ---
  Widget _buildWelcomeBanner(String userName) {
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('¡Hola, $userName! 👋', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('La educación es tu mejor herramienta para el futuro.', style: TextStyle(color: Colors.grey, fontSize: 13))]));
  }

  Widget _buildSectionTitle(String title, String? actionText, VoidCallback? onActionTap) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const CircleAvatar(radius: 6, backgroundColor: Color(0xFFEAB308)), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]), if (actionText != null) GestureDetector(onTap: onActionTap, child: Text(actionText, style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 14)))]);
  }

  Widget _buildDynamicCoursesList(List<dynamic> cursos, List<dynamic> logros) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, itemCount: cursos.length,
        itemBuilder: (context, index) => _buildCourseCard(cursos[index], cursos, logros, isFullWidth: false),
      ),
    );
  }

  // Tarjeta de Curso (Funcional)
  Widget _buildCourseCard(Map<String, dynamic> curso, List<dynamic> cursosActuales, List<dynamic> logrosActuales, {required bool isFullWidth}) {
    double progress = (curso['progreso'] ?? 0.0).toDouble();
    bool isCompletado = progress == 1.0;
    
    return GestureDetector(
      onTap: () {
        if (isCompletado) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya completaste este curso. ¡Buen trabajo!'), backgroundColor: Colors.green));
        } else {
          _abrirCurso(context, curso, cursosActuales, logrosActuales);
        }
      },
      child: Container(
        width: isFullWidth ? double.infinity : 260, margin: EdgeInsets.only(right: isFullWidth ? 0 : 20),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: isCompletado ? Border.all(color: Colors.green.withOpacity(0.5)) : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 100, decoration: const BoxDecoration(color: Color(0xFF0B1121), borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))), child: Stack(children: [Center(child: Icon(_getIconFromName(curso['icono']), size: 50, color: isCompletado ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3))), Positioned(top: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isCompletado ? Colors.green : const Color(0xFFEAB308), borderRadius: BorderRadius.circular(12)), child: Text(isCompletado ? 'COMPLETADO' : 'EN PROGRESO ${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))))])),
            Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(curso['titulo'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(curso['modulo'], style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 20), LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFF0F172A), valueColor: AlwaysStoppedAnimation(isCompletado ? Colors.green : const Color(0xFF06B6D4)))]))
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(List<dynamic> logros) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildAchievementBadge(Icons.star, 'Bienvenida', const Color(0xFF06B6D4), !logros.contains('bienvenida')),
          _buildAchievementBadge(Icons.menu_book, 'Estudioso', const Color(0xFFEAB308), !logros.contains('curso_terminado')),
          _buildAchievementBadge(Icons.handshake, 'Conducta', Colors.grey, true), // Siempre bloqueado en demo
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(IconData icon, String label, Color color, bool isLocked) {
    return Padding(
      padding: const EdgeInsets.only(right: 30.0),
      child: Column(children: [Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isLocked ? Colors.transparent : color, width: 2)), child: CircleAvatar(radius: 30, backgroundColor: const Color(0xFF0B1121), child: Icon(isLocked ? Icons.lock : icon, size: 30, color: isLocked ? Colors.grey.withOpacity(0.5) : color))), const SizedBox(height: 12), Text(label, style: TextStyle(color: isLocked ? Colors.grey : Colors.white, fontSize: 12, fontWeight: isLocked ? FontWeight.normal : FontWeight.bold))]),
    );
  }

  Widget _buildAchievementGridItem(IconData icon, String title, String desc, Color color, bool isLocked) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: isLocked ? Colors.transparent : color.withOpacity(0.5))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isLocked ? Icons.lock : icon, size: 40, color: isLocked ? Colors.grey.withOpacity(0.5) : color), const SizedBox(height: 10), Text(title, textAlign: TextAlign.center, style: TextStyle(color: isLocked ? Colors.grey : Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 10))]),
    );
  }
}