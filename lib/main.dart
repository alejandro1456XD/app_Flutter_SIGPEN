import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importamos el núcleo de Firebase
import 'firebase_options.dart'; // Importamos el archivo 
import 'features/auth/login_screen.dart';


void main() async {
  // Le decimos a Flutter que espere a que los widgets estén listos para comunicarse con el sistema nativo
  WidgetsFlutterBinding.ensureInitialized();
  
  //Encendemos Firebase usando las credenciales exactas de SIGPEN-Cbba
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  
  runApp(const SigpenApp());
}

class SigpenApp extends StatelessWidget {
  const SigpenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGPEN-Cbba',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), 
        primaryColor: const Color(0xFF06B6D4), 
        fontFamily: 'Roboto', 
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06B6D4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}