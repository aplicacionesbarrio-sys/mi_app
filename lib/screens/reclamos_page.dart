import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../widgets_personalizados.dart';
import 'servicios_page.dart';

class ReclamosPage extends StatefulWidget {
  const ReclamosPage({super.key});
  @override
  State<ReclamosPage> createState() => _ReclamosPageState();
}

class _ReclamosPageState extends State<ReclamosPage> {
  String reclamoSeleccionado = "";
  Timer? _timer;
  String mensajeConfirmacion = "";
  String nombreVecinoReal = "Cargando...";
  String telefonoVecinoReal = "Cargando...";
  String barrioVecinoReal = "Cargando...";
  final TextEditingController _detalleController = TextEditingController();

  // FUNCIÓN PARA ENVIAR RECLAMO CON GPS REAL (MULTIDESTINO)
  Future<void> enviarReclamoAlFirebase(
      String tipoRecibido, String barrioVecinoReal) async {
    // 1. Usamos una variable dinámica para que acepte un nombre solo o una lista []
    dynamic empresasDestino;

    // 2. Lógica de destinos según tu pedido
    if (tipoRecibido == "pérdida de agua") {
      empresasDestino = "aguas de la rioja";
    } else if (tipoRecibido == "cable caído") {
      empresasDestino = ["edelar", "protección ciudadana"];
    } else if (tipoRecibido == "pérdida de gas") {
      empresasDestino = [
        "bomberos más cercanos",
        "sala de comunicaciones",
        "protección ciudadana"
      ];
    } else if (tipoRecibido == "daños en vía pública") {
      empresasDestino = [
        "sala de comunicaciones",
        "protección ciudadana",
        "bomberos"
      ];
    } else {
      empresasDestino = "comisaria cercana"; // Destino por defecto
    }

    if (tipoRecibido.isEmpty) {
      setState(() => mensajeConfirmacion = "Seleccioná un problema primero");
      return;
    }

    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => mensajeConfirmacion = "Falta permiso de GPS");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 2. Envío a Firebase (Copiando la estructura de Servicios que ya funciona)
      await FirebaseFirestore.instance.collection('reclamos').add({
        'tipo': tipoRecibido,
        'nombre': nombreVecinoReal, // <--- 'nombre' como en servicios
        'numerodecelular':
            telefonoVecinoReal, // <--- 'numerodecelular' como en servicios
        'fecha': FieldValue.serverTimestamp(),
        'ubicacion': GeoPoint(position.latitude, position.longitude),
        'estado': 'pendiente',
        'barrio_vecino': barrioVecinoReal,
        // Datos extra exclusivos de Reclamos
        'empresa_destino': empresasDestino,
        'detalle': _detalleController.text.trim(),
        'link_mapa':
            "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}",
      });
      _detalleController.clear();
    } catch (e) {
      setState(() => mensajeConfirmacion = "Error al enviar: $e");
    }
  }

  // Mapa de bloqueo actualizado con el nuevo botón
  Map<String, bool> reclamosBloqueados = {
    "pérdida de agua": false,
    "cable caído": false,
    "pérdida de gas": false,
    "daños en vía pública": false // <--- Nuevo en la lista
  };

  @override
  void initState() {
    super.initState();

    // Color de fondo solo para rol 5

    // Cargar bloqueos y datos de usuario
    _cargarEstadoBloqueos();
    _obtenerDatosUsuario();
  }

  Future<void> _cargarEstadoBloqueos() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime ahora = DateTime.now();

    setState(() {
      for (String tipo in [
        "pérdida de agua",
        "cable caído",
        "pérdida de gas",
        "daños en vía pública" // <--- Agregado aquí
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

  Future<void> _obtenerDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    String nombreLeido = prefs.getString('nombre') ?? "";
    String celularLeido = prefs.getString('numerodecelular') ?? "";
    String barrioLeido = prefs.getString('barrio') ?? "";
    if (!mounted) return;

    setState(() {
      nombreVecinoReal = nombreLeido.isNotEmpty ? nombreLeido : "Vecino";
      telefonoVecinoReal =
          celularLeido.isNotEmpty ? celularLeido : "Sin número";
      barrioVecinoReal = barrioLeido.isNotEmpty ? barrioLeido : "Sin barrio";
    });

    debugPrint("📖 DATOS CARGADOS: $nombreVecinoReal - $telefonoVecinoReal");
  }

  Future<void> _guardarBloqueo(String tipo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("fecha_$tipo", DateTime.now().toIso8601String());
  }

  void alPresionarBoton(String tipo) {
    _detalleController.clear();
    _mostrarCuadroDetalle(context);
    if (reclamosBloqueados[tipo] == true) return;
    setState(() => reclamoSeleccionado = tipo);

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 30), () {
      // boton de reclamos dura este tiempo marcado
      if (mounted) setState(() => reclamoSeleccionado = "");
    });
  }

  void enviarReclamoFinal() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await _obtenerDatosUsuario();
    if (reclamoSeleccionado.isEmpty) return;
    String tipoEnviado = reclamoSeleccionado;

    await enviarReclamoAlFirebase(tipoEnviado, barrioVecinoReal);

    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 500);
    }

    setState(() {
      reclamosBloqueados[tipoEnviado] = true;
      mensajeConfirmacion = "Reclamo de ${tipoEnviado.toUpperCase()} enviado";
      reclamoSeleccionado = "";
    });

    await _guardarBloqueo(tipoEnviado);

    Timer(const Duration(seconds: 10), () {
      // duracion del cartel verde de arriba
      if (mounted) setState(() => mensajeConfirmacion = "");
    });

    Timer(const Duration(minutes: 2), () {
      // bloqueo de un boton de reclamo enviada
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
                      // 1. Pérdida de Agua
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
                                    ? Colors.green
                                    : Colors.white),
                        estaSeleccionado:
                            reclamoSeleccionado == "pérdida de agua",
                        accion: () => alPresionarBoton("pérdida de agua"),
                      ),
                      const SizedBox(height: 10),

                      // 2. Cable Caído
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
                                ? Colors.deepPurple
                                : Colors.white),
                        estaSeleccionado: reclamoSeleccionado == "cable caído",
                        accion: () => alPresionarBoton("cable caído"),
                      ),
                      const SizedBox(height: 10),

                      // 3. Pérdida de Gas
                      BotonAlertaPro(
                        texto: (reclamosBloqueados["pérdida de gas"] ?? false)
                            ? "Reportado"
                            : "Pérdida de gas",
                        icono: Icons.warning_amber_rounded,
                        iconoColor:
                            (reclamosBloqueados["pérdida de gas"] ?? false)
                                ? Colors.grey
                                : Colors.brown,
                        colorFondo:
                            (reclamosBloqueados["pérdida de gas"] ?? false)
                                ? Colors.grey.shade400
                                : (reclamoSeleccionado == "pérdida de gas"
                                    ? Colors.yellow.shade700
                                    : Colors.white),
                        estaSeleccionado:
                            reclamoSeleccionado == "pérdida de gas",
                        accion: () => alPresionarBoton("pérdida de gas"),
                      ),
                      const SizedBox(height: 10),

                      // 4. NUEVO: DAÑOS EN VÍA PÚBLICA (CON TEXTO AJUSTADO)
                      BotonAlertaPro(
                        texto: (reclamosBloqueados["daños en vía pública"] ??
                                false)
                            ? "Reportado"
                            : "Daños en vía pública",
                        icono: Icons.construction_rounded,
                        iconoColor:
                            (reclamosBloqueados["daños en vía pública"] ??
                                    false)
                                ? Colors.grey
                                : Colors.blueGrey,
                        colorFondo:
                            (reclamosBloqueados["daños en vía pública"] ??
                                    false)
                                ? Colors.grey.shade400
                                : (reclamoSeleccionado == "daños en vía pública"
                                    ? Colors.orange.shade800
                                    : Colors.white),
                        estaSeleccionado:
                            reclamoSeleccionado == "daños en vía pública",
                        accion: () => alPresionarBoton("daños en vía pública"),
                      ),

                      const SizedBox(height: 40),
                      // BOTÓN ENVIAR FINAL
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: Material(
                          color: reclamoSeleccionado.isEmpty
                              ? Colors.grey.shade400
                              : const Color(0xFFFF0000), // Rojo puro y fuerte
                          borderRadius: BorderRadius.circular(15),
                          elevation: reclamoSeleccionado.isEmpty
                              ? 0
                              : 15, // Más sombra para que resalte
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
                          child: Text("Ver Servicios",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))),
                      Center(
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 25),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ServiciosPage())),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // CARTEL VERDE DE CONFIRMACIÓN
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

  void _mostrarCuadroDetalle(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Detalle del Reclamo",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Contanos brevemente qué sucede (máx. 50 caracteres):"),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _detalleController,
                    textAlign: TextAlign.center,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: "Ej: Frente al portón blanco",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                // BOTÓN CANCELAR
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _detalleController.clear();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "CANCELAR",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // IGUALADO
                      ),
                    ),
                  ),
                ),
                // BOTÓN GUARDAR
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // 1. Refresca la pantalla principal para que los botones cambien a gris
                      setState(() {});

                      // 2. Cierra el cuadro de diálogo
                      Navigator.pop(context);

                      // 3. Muestra el mensaje de éxito
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "✅ Detalle guardado. Ahora presioná ENVIAR RECLAMO.",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(
                              seconds:
                                  31), // el cartel datall... dura este tiempo
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: const Text(
                      "GUARDAR",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // IGUALADO
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
