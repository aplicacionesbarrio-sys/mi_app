import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets_personalizados.dart';

class DenunciasPage extends StatefulWidget {
  const DenunciasPage({super.key});

  @override
  State<DenunciasPage> createState() => _DenunciasPageState();
}

class _DenunciasPageState extends State<DenunciasPage> {
  String reclamoSeleccionado = "";
  Timer? _timer;

  void alPresionarBoton(String tipo) {
    setState(() {
      reclamoSeleccionado = tipo;
    });

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          reclamoSeleccionado = "";
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Barrio Seguro",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text("Selecciona tu reclamo",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // CONTENEDOR CON PADDING PARA ALINEAR TODO EL ANCHO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  BotonAlertaPro(
                    texto: "Pérdida de agua",
                    icono: Icons.water_drop,
                    iconoColor: Colors.blue,
                    colorFondo:
                        Colors.white, // Fondo blanco para que luzca la sombra
                    estaSeleccionado: reclamoSeleccionado == "agua",
                    accion: () => alPresionarBoton("agua"),
                  ),
                  const SizedBox(height: 1), // Espacio entre botones
                  BotonAlertaPro(
                    texto: "Cable caído",
                    icono: Icons.electrical_services,
                    iconoColor: Colors.orange,
                    colorFondo: Colors.white,
                    estaSeleccionado: reclamoSeleccionado == "cable",
                    accion: () => alPresionarBoton("cable"),
                  ),
                  const SizedBox(height: 1), // Espacio entre botones
                  BotonAlertaPro(
                    texto: "Pérdida de gas",
                    icono: Icons.cloud,
                    iconoColor: Color.fromARGB(255, 150, 37, 2),
                    colorFondo: Colors.white,
                    estaSeleccionado: reclamoSeleccionado == "gas",
                    accion: () => alPresionarBoton("gas"),
                  ),

                  const SizedBox(height: 40),

                  // --- BOTÓN ENVIAR RECLAMO (ESTILO PRO E IGUAL ANCHO) ---
                  SizedBox(
                    width: double.infinity, // ANCHO TOTAL IGUAL A LOS DE ARRIBA
                    height: 70,
                    child: Material(
                      color: reclamoSeleccionado.isEmpty
                          ? Colors.grey.shade400
                          : const Color(0xFFEF4444), // Rojo
                      borderRadius: BorderRadius.circular(15),
                      elevation: reclamoSeleccionado.isEmpty
                          ? 0
                          : 5, // Sombra si está activo
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: reclamoSeleccionado.isEmpty
                            ? null
                            : () => print("Enviado: $reclamoSeleccionado"),
                        child: const Center(
                          child: Text(
                            "Enviar Reclamo",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
