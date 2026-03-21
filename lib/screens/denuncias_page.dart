import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // LA LIBRETA: Esta herramienta permite que la app anote cosas en el disco del celular
import '../widgets_personalizados.dart';
import 'servicios_page.dart';

class DenunciasPage extends StatefulWidget {
  const DenunciasPage({super.key});

  @override
  State<DenunciasPage> createState() => _DenunciasPageState();
}

class _DenunciasPageState extends State<DenunciasPage> {
  String reclamoSeleccionado = "";
  Timer? _timer;
  String mensajeConfirmacion = "";

  // Mapa de bloqueo: Es la lista que dice quién está gris (true) o azul (false)
  Map<String, bool> reclamosBloqueados = {
    "agua": false,
    "cable": false,
    "gas": false
  };

  @override
  void initState() {
    super.initState();
    // FUNCIÓN: Se ejecuta apenas entrás a la pantalla para "leer la libreta"
    _cargarEstadoBloqueos();
  }

  // --- FUNCIÓN: BUSCAR DATOS GUARDADOS ---
  // Sirve para que la app revise si el vecino ya hizo un reporte hace menos de 24h
  Future<void> _cargarEstadoBloqueos() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime ahora = DateTime.now();

    setState(() {
      for (String tipo in ["agua", "cable", "gas"]) {
        String? fechaGuardadaStr = prefs.getString("fecha_$tipo");
        if (fechaGuardadaStr != null) {
          DateTime fechaGuardada = DateTime.parse(fechaGuardadaStr);
          // Si la diferencia de tiempo es menor a 24 horas, lo dejamos bloqueado
          if (ahora.difference(fechaGuardada).inHours < 1) {
            reclamosBloqueados[tipo] = true;
          } else {
            // Si ya pasó el tiempo, borramos la nota de la libreta para que se libere
            reclamosBloqueados[tipo] = false;
            prefs.remove("fecha_$tipo");
          }
        }
      }
    });
  }

  // --- FUNCIÓN: ANOTAR EN LA LIBRETA ---
  // Sirve para guardar la fecha y hora exacta en la que se apretó "Enviar"
  Future<void> _guardarBloqueo(String tipo) async {
    final prefs = await SharedPreferences.getInstance();
    // Guardamos la hora actual como un texto (String) para que no se borre al cerrar la app
    await prefs.setString("fecha_$tipo", DateTime.now().toIso8601String());
  }

  // --- FUNCIÓN: CUANDO TOCÁS UN BOTÓN ---
  // Controla la selección y el reloj de 15 segundos antes de que se desmarque
  void alPresionarBoton(String tipo) {
    if (reclamosBloqueados[tipo] == true) return;
    setState(() => reclamoSeleccionado = tipo);

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => reclamoSeleccionado = "");
    });
  }

  // --- FUNCIÓN: EL ENVÍO FINAL ---
  // Aquí es donde sucede la magia: bloquea el botón, muestra el cartel y GUARDA en la memoria
  void enviarReclamoFinal() async {
    if (reclamoSeleccionado.isEmpty) return;
    String tipoEnviado = reclamoSeleccionado;

    setState(() {
      reclamosBloqueados[tipoEnviado] = true;
      mensajeConfirmacion = "Reclamo de ${tipoEnviado.toUpperCase()} enviado";
      reclamoSeleccionado = "";
    });

    // LLAMAMOS A LA FUNCIÓN DE GUARDADO PERMANENTE
    await _guardarBloqueo(tipoEnviado);

    Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => mensajeConfirmacion = "");
    });
  }

  @override
  void dispose() {
    // FUNCIÓN: Apaga el reloj cuando te vas de la pantalla para que no gaste batería
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // color de arriba de la pantalla secundaria
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Barrio Seguro", // zona de flecha
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
                const SizedBox(height: 30), // titulo
                const Text("Selecciona tu reclamo",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // 1. Botón de Pérdida de Agua
                      BotonAlertaPro(
                        texto: reclamosBloqueados["agua"]!
                            ? "Reportado"
                            : "Pérdida de agua",
                        icono: Icons.water_drop,
                        iconoColor: reclamosBloqueados["agua"]!
                            ? Colors.grey
                            : Colors.blue,
                        colorFondo: reclamoSeleccionado == "agua"
                            ? Colors.blue
                            : Colors.blue.shade100, // <--- CAMBIO AQUÍ
                        estaSeleccionado: reclamoSeleccionado == "agua",
                        accion: () => alPresionarBoton("agua"),
                      ),
                      const SizedBox(height: 10),
                      // 2. Botón de Cable Caído
                      BotonAlertaPro(
                        texto: reclamosBloqueados["cable"]!
                            ? "Reportado"
                            : "Cable caído",
                        icono: Icons.electrical_services,
                        iconoColor: reclamosBloqueados["cable"]!
                            ? Colors.grey
                            : Colors.orange,
                        colorFondo: reclamoSeleccionado == "cable"
                            ? Colors.blue
                            : Colors.blue.shade100, // <--- CAMBIO AQUÍ
                        estaSeleccionado: reclamoSeleccionado == "cable",
                        accion: () => alPresionarBoton("cable"),
                      ),
                      const SizedBox(height: 10),
                      // 3. Botón de Pérdida de Gas
                      BotonAlertaPro(
                        texto: reclamosBloqueados["gas"]!
                            ? "Reportado"
                            : "Pérdida de gas",
                        icono: Icons.cloud,
                        iconoColor: reclamosBloqueados["gas"]!
                            ? Colors.grey
                            : const Color.fromARGB(255, 150, 37, 2),
                        colorFondo: reclamoSeleccionado == "gas"
                            ? Colors.blue
                            : Colors.blue.shade100, // <--- CAMBIO AQUÍ
                        estaSeleccionado: reclamoSeleccionado == "gas",
                        accion: () => alPresionarBoton("gas"),
                      ), // boton para enviar reclamo
                      const SizedBox(height: 40),
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
                              // boton enviar reclamo
                              child: Text("Enviar Reclamo",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                      // --- TEXTO Y FLECHA PARA IR A SERVICIOS ---
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          "Ver Servicios",
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      Center(
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios,
                              color: Colors.grey, size: 25),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ServiciosPage()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                          height: 40), // Espacio final para que se vea bien
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
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
                        child: Text(mensajeConfirmacion,
                            style: const TextStyle(
                                color: Colors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
