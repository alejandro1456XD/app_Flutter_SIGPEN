import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  // --- NUEVO CONTROLADOR PARA VINCULACIÓN ---
  final _internoIdController = TextEditingController(); 
  
  String _selectedRole = 'Interno';
  bool _isLoading = false;

  final List<String> _roles = ['Interno', 'Guardia', 'Familiar', 'Administrador'];

  Future<void> _registerUser() async {
    if (_nombreController.text.isEmpty || _emailController.text.isEmpty || _passController.text.isEmpty) {
      _showSnackBar('Completa los campos básicos', Colors.orange);
      return;
    }

    // Validación extra: Si es Familiar, debe tener un ID de interno
    if (_selectedRole == 'Familiar' && _internoIdController.text.isEmpty) {
      _showSnackBar('Debes ingresar el ID del Interno para vincular al familiar', Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      final String uid = userCredential.user!.uid;

      // --- ESTRUCTURA DE DATOS VINCULADA ---
      Map<String, dynamic> userData = {
        'uid': uid,
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'rol': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      // Si es familiar, añadimos el "puente" hacia el interno
      if (_selectedRole == 'Familiar') {
        userData['id_interno_vinculado'] = _internoIdController.text.trim();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

      await secondaryApp.delete();

      if (!mounted) return;
      _showSnackBar('Usuario creado y vinculado con éxito', Colors.green);
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      _showSnackBar('Error: ${e.message}', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Alta de Usuarios", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B1121),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.person_add_alt_1, size: 70, color: Color(0xFF06B6D4)),
            const SizedBox(height: 20),
            _buildTextField(_nombreController, 'Nombre Completo', Icons.person),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'Correo Institucional', Icons.email),
            const SizedBox(height: 16),
            _buildTextField(_passController, 'PIN / Contraseña', Icons.lock, isPassword: true),
            const SizedBox(height: 16),
            _buildRoleDropdown(),
            
            // --- CAMPO CONDICIONAL ---
            if (_selectedRole == 'Familiar') ...[
              const SizedBox(height: 16),
              _buildTextField(
                _internoIdController, 
                'ID del Interno (UID de Firebase)', 
                Icons.link,
                helper: 'Copia el UID del interno desde la lista de usuarios.'
              ),
            ],

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4)),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('REGISTRAR Y VINCULAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, String? helper}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperStyle: const TextStyle(color: Color(0xFF06B6D4)),
        prefixIcon: Icon(icon, color: const Color(0xFF06B6D4)),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
      onChanged: (val) => setState(() => _selectedRole = val!),
      decoration: const InputDecoration(
        labelText: 'Rol',
        prefixIcon: Icon(Icons.badge, color: Color(0xFF06B6D4)),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: const Color(0xFF1E293B),
      ),
    );
  }
}