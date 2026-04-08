import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import '../widgets_personalizados.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:mi_app/screens/admin_servicios_page.dart';
import '../admin/admin_home.dart';
import 'reclamos_page.dart';
import 'validacion_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});
  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  final Color colorFondoPantalla1 = const Color.fromARGB(255, 187, 233, 246);

  int contadorAlertas = 5;
  double lat = 0;
  double lng = 0;
  String tipoAlertaSeleccionada = "";
  Timer? temporizadorAlerta;
  String mensajeConfirmacion = "";
  bool botonHabilitado = true;
  bool mostrarAvisoLlamada = false;
  List<String> alertasBloqueadas = [];
  String nombreVecinoReal = "Cargando...";
  String telefonoVecinoReal = "...";
  int rolUsuario = 3; // 🛡️ Ahora se actualizará correctamente
  String barrioReal = "Cargando...";
  bool cargando = true;
  String domicilioReal = "";

  @override
  void initState() {
    super.initState();
    obtenerUbicacionActual();
    obtenerDatosUsuario();
  }

  // 🛡️ OBTENCIÓN DE DATOS BLINDADA
  Future<void> obtenerDatosUsuario() async {
    try {
      var build = await DeviceInfoPlugin().androidInfo;
      String idCelu = build.id;

      var usuarioQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('deviceId', isEqualTo: idCelu)
          .get();

      if (usuarioQuery.docs.isNotEmpty) {
        final datos = usuarioQuery.docs.first.data();
        if (!mounted) return;

        int rol = datos['rol'] ?? 3;
        String estado = datos['estado'] ?? 'pendiente';

        final prefs = await SharedPreferences.getInstance();
        bool yaValidoCodigo = prefs.getBool('codigoValidado') ?? false;
        if (!mounted) return;
        // 🛡️ EL SEMÁFORO CORREGIDO
        if (rol == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomePage()),
          );
        } else if (estado == 'pendiente' && !yaValidoCodigo && rol == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ValidacionPage()),
          );
        } else {
          if (mounted) {
            setState(() {
              rolUsuario = rol; // ✅ FIX: Ahora el botón de servicios aparecerá
              domicilioReal = datos['domicilio'] ?? "";
              nombreVecinoReal = datos['nombre'] ?? "Sin nombre";
              barrioReal = datos['barrio'] ?? "Sin barrio";
              telefonoVecinoReal = datos['numerodecelular'] ?? "...";
              cargando = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => cargando = false);
      }
    } catch (e) {
      debugPrint("❌ Error al obtener datos: $e");
      if (mounted) setState(() => cargando = false);
    }
  }

  // 🛡️ GPS REFORZADO
  Future<void> obtenerUbicacionActual() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("⚠️ GPS desactivado en el equipo.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        if (mounted) {
          setState(() {
            lat = position.latitude;
            lng = position.longitude;
          });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error GPS: $e");
    }
  }

  // 🛡️ ENVÍO DE ALERTA BLINDADO
  void enviarAlerta() async {
    if (tipoAlertaSeleccionada == "" || !botonHabilitado) return;

    String alertaMandada = tipoAlertaSeleccionada;
    List<String> paraQuien = [];

    // Lógica de destinatarios
    if (alertaMandada == "robo" || alertaMandada == "sospechoso") {
      paraQuien = ["comisaria", "911", "comunicaciones", "vecinos_100m"];
    } else if (alertaMandada == "incendio" || alertaMandada == "siniestro") {
      paraQuien = [
        "911",
        "comisaria",
        "bomberos",
        "proteccion_ciudadana",
        "vecinos_100m"
      ];
    } else if (alertaMandada == "ambulancia") {
      paraQuien = ["911", "107"];
    }

    setState(() {
      botonHabilitado = false;
      mensajeConfirmacion = "Alerta por ${alertaMandada.toUpperCase()} enviada";
      mostrarAvisoLlamada = true;
      alertasBloqueadas.add(alertaMandada);
      tipoAlertaSeleccionada = "";
    });

    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 500);
    }

    try {
      // 🛡️ Link de Google Maps real con coordenadas actuales
      String googleMapsUrl = "https://www.google.com/maps?q=$lat,$lng";

      await FirebaseFirestore.instance.collection('alertas').add({
        'tipo': alertaMandada,
        'nombre_vecino': nombreVecinoReal,
        'numerodecelular': telefonoVecinoReal,
        'fecha': FieldValue.serverTimestamp(),
        'ubicacion': GeoPoint(lat, lng),
        'link_mapa': googleMapsUrl,
        'destinatarios': paraQuien,
        'estado': 'activa',
        'barrio_vecino': barrioReal.isEmpty ? "Sin barrio" : barrioReal,
        'domicilio': domicilioReal,
      });
    } catch (e) {
      debugPrint("❌ Error al subir alerta: $e");
    }

    // Timer cartel verde (10 seg)
    Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => mostrarAvisoLlamada = false);
    });

    // Timer reactivar botón (20 seg)
    Timer(const Duration(seconds: 20), () {
      if (mounted) setState(() => botonHabilitado = true);
    });

    // Timer desbloquear este tipo de alerta (3 min)
    Timer(const Duration(minutes: 3), () {
      if (mounted) {
        setState(() => alertasBloqueadas.remove(alertaMandada));
      }
    });
  }

  void alPresionarBoton(String tipo) {
    setState(() => tipoAlertaSeleccionada = tipo);
    temporizadorAlerta?.cancel();
    temporizadorAlerta = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => tipoAlertaSeleccionada = "");
    });
  }

  Widget _crearBoton(String tipo, IconData icono, String etiqueta,
      Color colorBase, Color colorResaltado) {
    bool bloqueado = alertasBloqueadas.contains(tipo);
    bool seleccionado = tipoAlertaSeleccionada == tipo;

    return BotonAlerta(
      texto: etiqueta,
      icono: icono,
      estaSeleccionado: seleccionado,
      colorFondo: bloqueado
          ? Colors.grey.shade400
          : (seleccionado ? colorResaltado : colorBase),
      accion: () {
        if (!bloqueado) {
          alPresionarBoton(tipo);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Scaffold(
          backgroundColor: colorFondoPantalla1,
          body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Barrio Seguro",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: colorFondoPantalla1,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  const Text("Selecciona tu alerta",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      children: [
                        _crearBoton("robo", Icons.local_police, "Robo",
                            const Color(0xFFFAFAF9), const Color(0xFF297212)),
                        _crearBoton(
                            "sospechoso",
                            Icons.psychology_alt_rounded,
                            "Sospechoso",
                            const Color(0xFFFAFAF9),
                            const Color(0xFFE5DB1E)),
                        _crearBoton(
                            "incendio",
                            Icons.local_fire_department,
                            "Incendio",
                            const Color(0xFFFAFAF9),
                            const Color(0xFFD7821B)),
                        _crearBoton(
                            "siniestro",
                            Icons.car_crash_rounded,
                            "Siniestro",
                            const Color(0xFFFAFAF9),
                            const Color(0xFF321EE5)),
                        _crearBoton(
                            "ambulancia",
                            Icons.medical_services_rounded,
                            "Ambulancia",
                            const Color(0xFFFAFAF9),
                            const Color(0xFF57086E)),
                        _botonMasOpciones(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🛡️ BOTÓN ADMIN DE SERVICIOS (Visible si rol <= 2)
                  if (rolUsuario <= 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.assignment_turned_in,
                              color: Colors.white),
                          label: const Text("VER PEDIDOS DE SERVICIOS",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminServiciosPage())),
                        ),
                      ),
                    ),

                  if (!botonHabilitado)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text("Alerta enviada. Espere el llamado.",
                          style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold)),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 65,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed:
                            (tipoAlertaSeleccionada.isEmpty || !botonHabilitado)
                                ? null
                                : enviarAlerta,
                        child: Text(
                            botonHabilitado ? "ENVIAR ALERTA" : "ESPERE...",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            if (mostrarAvisoLlamada)
              Positioned(
                top: 10,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF4),
                      border: Border.all(color: const Color(0xFFB9E9C3)),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF5BB568)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(mensajeConfirmacion,
                              style: const TextStyle(
                                  color: Color(0xFF357644),
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _botonMasOpciones() {
    return BotonAlerta(
      texto: "Más opciones",
      icono: Icons.keyboard_arrow_down,
      estaSeleccionado: false,
      colorFondo: const Color(0xFFFAFAF9),
      accion: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ReclamosPage())),
    );
  }
}
