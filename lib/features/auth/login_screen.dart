import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../family_visits/family_home_screen.dart';
import '../education/student_home_screen.dart';
import '../guard_security/guard_home_screen.dart';
import '../admin_dashboard/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signInWithFirebase() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa correo y PIN'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() { _isLoading = true; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _fetchUserRoleAndNavigate(_emailController.text.trim());
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.redAccent),
      );
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _fetchUserRoleAndNavigate(String email) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String role = querySnapshot.docs.first['rol'];
        _navigateToRoleScreen(role);
      } else {
        throw Exception("Usuario no autorizado en el sistema.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de acceso: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
      setState(() { _isLoading = false; });
    }
  }

  void _navigateToRoleScreen(String role) {
    Widget nextScreen;
    // Quitamos espacios y lo pasamos a minúsculas
    String rolLimpio = role.trim().toLowerCase();
    
    switch (rolLimpio) {
      case 'administrador': 
        nextScreen = const AdminHomeScreen(); 
        break;
      case 'guardia': 
        nextScreen = const GuardHomeScreen(); 
        break;
      case 'interno': 
        nextScreen = const StudentHomeScreen(); 
        break;
      case 'familiar': 
        nextScreen = const FamilyHomeScreen(); 
        break;
      default: 
        // 🚨 CHIVATO ROJO: Si hay un error de tipeo en Firestore, te lo mostrará aquí
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Rol desconocido en la Base de Datos: "$role"'), 
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
        nextScreen = const AdminHomeScreen();
        break; 
    }
    
    // ✅ CHIVATO VERDE: Si todo va bien, te confirmará como quién estás entrando
    if (rolLimpio == 'administrador' || rolLimpio == 'guardia' || rolLimpio == 'interno' || rolLimpio == 'familiar') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Acceso correcto: Entrando como $role'), backgroundColor: Colors.green),
        );
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextScreen));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    return Scaffold(body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout());
  }

  Widget _buildForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController, 
          decoration: const InputDecoration(
            labelText: 'Correo', border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF1E293B)
          )
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController, 
          obscureText: true, 
          decoration: const InputDecoration(
            labelText: 'PIN', border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF1E293B)
          )
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity, height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signInWithFirebase,
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('Ingresar'),
          ),
        )
      ],
    );
  }

  Widget _buildMobileLayout() => Center(
    child: SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: _buildForm())
  );

  Widget _buildDesktopLayout() => Row(
    children: [
      Expanded(child: Container(color: Colors.blueGrey)), 
      Expanded(child: Padding(padding: const EdgeInsets.all(80.0), child: _buildForm()))
    ]
  );
}