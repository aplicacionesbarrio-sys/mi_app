import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // LA LIBRETA: Esta herramienta permite que la app anote cosas en el disco del celular
import '../widgets_personalizados.dart';
import 'servicios_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- Pegá esta
import 'package:geolocator/geolocator.dart'; // <--- Y esta
import 'package:vibration/vibration.dart';

class ReclamosPage extends StatefulWidget {
  const ReclamosPage({super.key});

  @override
  State<ReclamosPage> createState() => _ReclamosPageState();
}

class _ReclamosPageState extends State<ReclamosPage> {
  String reclamoSeleccionado = "";
  Timer? _timer;
  String mensajeConfirmacion = "";

  // FUNCIÓN PARA ENVIAR RECLAMO CON GPS REAL
  Future<void> enviarReclamoAlFirebase(String tipoRecibido) async {
    String empresaDestino = "";

    if (tipoRecibido == "pérdida de agua") {
      empresaDestino = "aguas de la rioja";
    } else if (tipoRecibido == "cable caido") {
      empresaDestino = "edelar";
    } else if (tipoRecibido == "perdida de gas") {
      empresaDestino = "ecogas";
    }

    if (tipoRecibido.isEmpty) {
      setState(() => mensajeConfirmacion = "Seleccioná un problema primero");
      return;
    }

    try {
      // 1. Pedir permiso de GPS al vecino
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        setState(() => mensajeConfirmacion = "Falta permiso de GPS");
        return;
      }

      // 2. Obtener ubicación real
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 3. Mandar a la carpeta 'reclamos' de Firebase
      await FirebaseFirestore.instance.collection('reclamos').add({
        'tipo': tipoRecibido,
        'nombre_vecino': 'Diego',
        'telefono': '3804521058',
        'fecha': FieldValue.serverTimestamp(),
        'ubicacion': GeoPoint(position.latitude, position.longitude),
        'link_mapa':
            "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}",
        'empresa_destino': empresaDestino,
      });
    } catch (e) {
      setState(() => mensajeConfirmacion = "Error al enviar: $e");
    }
  }

  // Mapa de bloqueo: Es la lista que dice quién está gris (true) o azul (false)
  Map<String, bool> reclamosBloqueados = {
    "pérdida de agua": false,
    "cable caído": false,
    "pérdida de gas": false
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
      // Corregido para que busque los nombres nuevos en la libreta
      for (String tipo in [
        "pérdida de agua",
        "cable caído",
        "pérdida de gas"
      ]) {
        String? fechaGuardadaStr = prefs.getString("fecha_$tipo");
        if (fechaGuardadaStr != null) {
          DateTime fechaGuardada = DateTime.parse(fechaGuardadaStr);
          if (ahora.difference(fechaGuardada).inMinutes < 2) {
            reclamosBloqueados[tipo] = true;
          } else {
            reclamosBloqueados[tipo] = false;
            prefs.remove("fecha_$tipo");
          }
        }
      }
    });
  }

  // --- FUNCIÓN: ANOTAR EN LA LIBRETA ---
  Future<void> _guardarBloqueo(String tipo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("fecha_$tipo", DateTime.now().toIso8601String());
  }

  // --- FUNCIÓN: CUANDO TOCÁS UN BOTÓN ---
  void alPresionarBoton(String tipo) {
    if (reclamosBloqueados[tipo] == true) return;
    setState(() => reclamoSeleccionado = tipo);

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => reclamoSeleccionado = "");
    });
  }

  // --- FUNCIÓN: EL ENVÍO FINAL ---
  void enviarReclamoFinal() async {
    if (reclamoSeleccionado.isEmpty) return;
    String tipoEnviado = reclamoSeleccionado;

    // 1. Envía a Firebase
    await enviarReclamoAlFirebase(tipoEnviado);

    // 2. Hace vibrar el celu (Asegurate de tener el import arriba)
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 500);
    }

    // 3. Actualiza la pantalla
    setState(() {
      reclamosBloqueados[tipoEnviado] = true;
      mensajeConfirmacion = "Reclamo de ${tipoEnviado.toUpperCase()} enviado";
      reclamoSeleccionado = "";
    });

    // 4. Guarda en la libreta (SharedPreferences)
    await _guardarBloqueo(tipoEnviado);

    // 5. Quita el mensaje verde después de 10 segundos
    Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => mensajeConfirmacion = "");
    });

    // 6. Desbloquea el botón después de 2 minutos
    Timer(const Duration(minutes: 2), () {
      if (mounted) {
        setState(() {
          reclamosBloqueados[tipoEnviado] = false;
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
      backgroundColor: const Color.fromARGB(255, 187, 233, 246),
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
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // 1. Botón de Pérdida de Agua
                      BotonAlertaPro(
                        texto: (reclamosBloqueados["pérdida de agua"] ?? false)
                            ? "Reportado"
                            : "Pérdida de agua",
                        icono: Icons.water_drop,
                        iconoColor:
                            (reclamosBloqueados["pérdida de agua"] ?? false)
                                ? Colors.grey
                                : const Color.fromARGB(255, 140, 190, 231),
                        colorFondo:
                            (reclamosBloqueados["pérdida de agua"] ?? false)
                                ? Colors.grey.shade400
                                : (reclamoSeleccionado == "pérdida de agua"
                                    ? const Color.fromARGB(255, 41, 183, 26)
                                    : const Color.fromARGB(255, 253, 254, 254)),
                        estaSeleccionado:
                            reclamoSeleccionado == "pérdida de agua",
                        accion: () => alPresionarBoton("pérdida de agua"),
                      ),
                      const SizedBox(height: 10),

                      // 2. Botón de Cable Caído
                      BotonAlertaPro(
                        texto: (reclamosBloqueados["cable caído"] ?? false)
                            ? "Reportado"
                            : "Cable caído",
                        icono: Icons.electrical_services,
                        iconoColor: (reclamosBloqueados["cable caído"] ?? false)
                            ? Colors.grey
                            : Colors.orange,
                        colorFondo: (reclamosBloqueados["cable caído"] ?? false)
                            ? Colors.grey.shade400
                            : (reclamoSeleccionado == "cable caído"
                                ? const Color.fromARGB(255, 95, 71, 218)
                                : const Color.fromARGB(255, 253, 254, 254)),
                        estaSeleccionado: reclamoSeleccionado == "cable caído",
                        accion: () => alPresionarBoton("cable caído"),
                      ),
                      const SizedBox(height: 10),

                      // 3. Botón de Pérdida de Gas
                      BotonAlertaPro(
                        texto: (reclamosBloqueados["pérdida de gas"] ?? false)
                            ? "Reportado"
                            : "Pérdida de gas",
                        icono: Icons.warning_amber_rounded,
                        iconoColor:
                            (reclamosBloqueados["pérdida de gas"] ?? false)
                                ? Colors.grey
                                : const Color.fromARGB(255, 174, 73, 10),
                        colorFondo:
                            (reclamosBloqueados["pérdida de gas"] ?? false)
                                ? Colors.grey.shade400
                                : (reclamoSeleccionado == "pérdida de gas"
                                    ? const Color.fromARGB(255, 206, 218, 71)
                                    : const Color.fromARGB(255, 253, 254, 254)),
                        estaSeleccionado:
                            reclamoSeleccionado == "pérdida de gas",
                        accion: () => alPresionarBoton("pérdida de gas"),
                      ),

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
                              child: Text("Enviar Reclamo",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          "Ver Servicios",
                          style: TextStyle(
                              color: Color.fromARGB(255, 21, 20, 20),
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      Center(
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios,
                              color: Color.fromARGB(255, 21, 20, 20), size: 25),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ServiciosPage()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
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
