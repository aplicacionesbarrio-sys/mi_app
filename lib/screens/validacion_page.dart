import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart'; // <--- Nuevo
import 'dart:io'; // <--- Nuevo
import 'inicio_page.dart';
import 'dart:developer' as dev;

class ValidacionPage extends StatefulWidget {
  const ValidacionPage({super.key});

  @override
  State<ValidacionPage> createState() => _ValidacionPageState();
}

class _ValidacionPageState extends State<ValidacionPage> {
  final TextEditingController _codigoController = TextEditingController();
  bool _cargando = false;

  Future<void> _verificarCodigo() async {
    String codigo = _codigoController.text.trim();
    if (codigo.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresá los 6 dígitos")),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      // --- PASO NUEVO: Obtener el ID de este teléfono ---
      String idActual = "";
      var deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        var build = await deviceInfo.androidInfo;
        idActual = build.id; // Este es el ID que comparamos
      }

      // --- PASO ACTUALIZADO: Buscamos con código Y con deviceId ---
      final snapshot = await FirebaseFirestore.instance
          .collection('codigos_activacion')
          .where('codigo', isEqualTo: codigo)
          .where('deviceId', isEqualTo: idActual) // <--- Seguridad extra
          .where('usado', isEqualTo: false)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        // 1. Quemamos el código de activación
        await snapshot.docs.first.reference.update({'usado': true});

        // 2. Buscamos al usuario para ponerlo "activo"
        final userSnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('deviceId', isEqualTo: idActual)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          await userSnapshot.docs.first.reference.update({'estado': 'activo'});
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const InicioPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Código inválido, usado o no autorizado para este equipo")),
        );
      }
    } catch (e) {
      dev.log("Error al verificar: $e");
    }

    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Lo centramos para que se vea mejor
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Bienvenido a\nBarrio Seguro",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
              const SizedBox(height: 30),
              // Aquí podrías poner el Logo si querés
              const Text("Ingresá tu código de activación",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: _codigoController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 35,
                    letterSpacing: 10,
                    fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: _cargando ? null : _verificarCodigo,
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ACTIVAR AHORA",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
