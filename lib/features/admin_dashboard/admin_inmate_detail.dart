import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminInmateDetail extends StatefulWidget {
  final String inmateId;
  final Map<String, dynamic> inmateData;

  const AdminInmateDetail({super.key, required this.inmateId, required this.inmateData});

  @override
  State<AdminInmateDetail> createState() => _AdminInmateDetailState();
}

class _AdminInmateDetailState extends State<AdminInmateDetail> {
  late TextEditingController _nombreController;
  late TextEditingController _pabellonController;
  late TextEditingController _celdaController;
  
  // Valores para las barras de progreso (0.0 a 1.0)
  double _conducta = 0.5;
  double _educacion = 0.5;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.inmateData['nombre'] ?? '');
    _pabellonController = TextEditingController(text: widget.inmateData['pabellon'] ?? 'B');
    _celdaController = TextEditingController(text: widget.inmateData['celda'] ?? '0');
    
    // Cargamos progresos si existen, si no, por defecto 0.5
    _conducta = (widget.inmateData['progreso_conducta'] ?? 0.5).toDouble();
    _educacion = (widget.inmateData['progreso_educacion'] ?? 0.5).toDouble();
  }

  Future<void> _updateInmate() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.inmateId).update({
        'nombre': _nombreController.text.trim(),
        'pabellon': _pabellonController.text.trim(),
        'celda': _celdaController.text.trim(),
        'progreso_conducta': _conducta,
        'progreso_educacion': _educacion,
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Datos actualizados correctamente"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Editar Interno"),
        backgroundColor: const Color(0xFF0B1121),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.edit_note, size: 80, color: Color(0xFF06B6D4))),
            const SizedBox(height: 20),
            _buildSectionTitle("Información Básica"),
            _buildTextField(_nombreController, "Nombre Completo", Icons.person),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildTextField(_pabellonController, "Pabellón", Icons.business)),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField(_celdaController, "Celda", Icons.door_front_door)),
              ],
            ),
            const SizedBox(height: 30),
            _buildSectionTitle("Niveles de Rehabilitación"),
            _buildSliderLabel("Conducta", _conducta),
            Slider(
              value: _conducta,
              activeColor: const Color(0xFF06B6D4),
              onChanged: (val) => setState(() => _conducta = val),
            ),
            _buildSliderLabel("Educación / Talleres", _educacion),
            Slider(
              value: _educacion,
              activeColor: Colors.amber,
              onChanged: (val) => setState(() => _educacion = val),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateInmate,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4)),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("GUARDAR CAMBIOS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSliderLabel(String label, double val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        Text("${(val * 100).toInt()}%", style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF06B6D4)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: const OutlineInputBorder(),
      ),
    );
  }
}