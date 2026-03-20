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
  String mensajeConfirmacion = "";

  Map<String, bool> reclamosBloqueados = {
    "agua": false,
    "cable": false,
    "gas": false,
  };

  void alPresionarBoton(String tipo) {
    if (reclamosBloqueados[tipo] == true) return;

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

  void enviarReclamoFinal() {
    if (reclamoSeleccionado.isEmpty) return;

    String tipoEnviado = reclamoSeleccionado;

    setState(() {
      // cartel verde de reclamo enviado
      reclamosBloqueados[tipoEnviado] = true;
      mensajeConfirmacion = "Reclamo de ${tipoEnviado.toUpperCase()} enviado";
      reclamoSeleccionado = "";
    });

    Timer(const Duration(seconds: 10), () {
      // tiempo del cartel verde
      if (mounted) setState(() => mensajeConfirmacion = "");
    });

    Timer(const Duration(minutes: 2), () {
      // tiempo para activar reclamo
      if (mounted) {
        setState(() => reclamosBloqueados[tipoEnviado] = false);
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text("Selecciona tu reclamo",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // --- BOTÓN AGUA ---
                      BotonAlertaPro(
                        // Usamos un texto más simétrico para que no pise el icono
                        texto: reclamosBloqueados["agua"]!
                            ? "Reportado"
                            : "Pérdida de agua",
                        icono: Icons.water_drop,
                        iconoColor: reclamosBloqueados["agua"]!
                            ? Colors.grey
                            : Colors.blue,
                        colorFondo: Colors.white,
                        estaSeleccionado: reclamoSeleccionado == "agua",
                        accion: () => alPresionarBoton("agua"),
                      ),
                      const SizedBox(height: 10),

                      // --- BOTÓN CABLE ---
                      BotonAlertaPro(
                        texto: reclamosBloqueados["cable"]!
                            ? "Reportado"
                            : "Cable caído",
                        icono: Icons.electrical_services,
                        iconoColor: reclamosBloqueados["cable"]!
                            ? Colors.grey
                            : Colors.orange,
                        colorFondo: Colors.white,
                        estaSeleccionado: reclamoSeleccionado == "cable",
                        accion: () => alPresionarBoton("cable"),
                      ),
                      const SizedBox(height: 10),

                      // --- BOTÓN GAS ---
                      BotonAlertaPro(
                        texto: reclamosBloqueados["gas"]!
                            ? "Reportado"
                            : "Pérdida de gas",
                        icono: Icons.cloud,
                        iconoColor: reclamosBloqueados["gas"]!
                            ? Colors.grey
                            : Color.fromARGB(255, 228, 63, 12),
                        colorFondo: Colors.white,
                        estaSeleccionado: reclamoSeleccionado == "gas",
                        accion: () => alPresionarBoton("gas"),
                      ),

                      const SizedBox(height: 40),

                      // BOTÓN ENVIAR
                      SizedBox(
                        width: double.infinity,
                        height: 70,
                        child: Material(
                          color: reclamoSeleccionado.isEmpty
                              ? Colors.grey.shade400
                              : const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(15),
                          elevation: reclamoSeleccionado.isEmpty ? 0 : 5,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: reclamoSeleccionado.isEmpty
                                ? null
                                : enviarReclamoFinal,
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

          // CARTEL VERDE FLOTANTE (ARRIBA)
          if (mensajeConfirmacion.isNotEmpty)
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade400, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mensajeConfirmacion,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
