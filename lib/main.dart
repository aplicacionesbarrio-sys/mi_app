// [IMPORTACIONES - MANTENIDAS]
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'screens/reclamos_page.dart';
import 'widgets_personalizados.dart';
import 'package:vibration/vibration.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // --- OBTENER TOKEN PARA NOTIFICACIONES ---
  String? token = await FirebaseMessaging.instance.getToken();
  print("TOKEN DEL DISPOSITIVO: $token");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const InicioPage(),
    );
  }
}

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});
  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  // [CONFIGURACIÓN DE COLORES]
  final Color colorFondoPantalla1 = const Color.fromARGB(255, 187, 233, 246);

  int contadorAlertas = 5;
  double lat = 0;
  double lng = 0;
  String tipoAlertaSeleccionada = "";
  Timer? temporizadorAlerta;
  String mensajeConfirmacion = "";
  bool botonHabilitado = true;
  bool mostrarAvisoLlamada = false;

  @override
  void initState() {
    super.initState();
    obtenerUbicacion();
  }

  Future<void> obtenerUbicacion() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      lat = position.latitude;
      lng = position.longitude;
    });
  }

  // --- FUNCIÓN: ENVIAR ALERTA (REPARADA) ---
  void enviarAlerta() async {
    if (tipoAlertaSeleccionada == "" || botonHabilitado == false) return;
    List<String> paraQuien = [];

    if (tipoAlertaSeleccionada == "robo" ||
        tipoAlertaSeleccionada == "sospechoso") {
      paraQuien = ["comisaria", "911", "comunicaciones", "vecinos_100m"];
    } else if (tipoAlertaSeleccionada == "incendio") {
      paraQuien = [
        "911",
        "comisaria",
        "bomberos",
        "proteccion_ciudadana",
        "vecinos_100m"
      ];
    } else if (tipoAlertaSeleccionada == "siniestro") {
      paraQuien = [
        "911",
        "comisaria",
        "proteccion_ciudadana",
        "bomberos",
        "vecinos_100m"
      ];
    } else if (tipoAlertaSeleccionada == "ambulancia") {
      paraQuien = ["911", "107"];
    }

    setState(() {
      botonHabilitado = false;
      contadorAlertas++;
      mensajeConfirmacion =
          " Alerta por ${tipoAlertaSeleccionada.toUpperCase()} enviada";
      mostrarAvisoLlamada = false;
    });
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(
          duration: 500); // 500ms es medio segundo de vibración firme
    }
    // REPARACIÓN: Ahora el link lleva la posición REAL y sumamos tus datos
    FirebaseFirestore.instance.collection('alertas').add({
      'tipo': tipoAlertaSeleccionada,
      'nombre_vecino': 'Diego',
      'telefono': '3804521058',
      'fecha': FieldValue.serverTimestamp(),
      'ubicacion': GeoPoint(lat, lng),
      'link_mapa': 'https://www.google.com/maps?q=$lat,$lng',
      'destinatarios': paraQuien,
    });

    // --- TIEMPOS (MANTENIDOS) ---
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          mensajeConfirmacion = "";
          mostrarAvisoLlamada = true;
        });
      }
    });

    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() {
          mostrarAvisoLlamada = false;
        });
      }
    });

    Future.delayed(const Duration(seconds: 22), () {
      if (mounted) {
        setState(() {
          botonHabilitado = true;
        });
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
    bool estaSeleccionado = tipoAlertaSeleccionada == tipo;
    return BotonAlerta(
      texto: etiqueta,
      icono: icono,
      estaSeleccionado: estaSeleccionado,
      colorFondo: estaSeleccionado ? colorResaltado : colorBase,
      accion: () => alPresionarBoton(tipo),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      childAspectRatio: 1.05,
                      children: [
                        _crearBoton(
                            "robo",
                            Icons.local_police,
                            "Robo",
                            const Color.fromARGB(255, 250, 250, 249),
                            const Color.fromARGB(255, 41, 114, 18)),
                        _crearBoton(
                            "sospechoso",
                            Icons.psychology_alt_rounded,
                            "Sospechoso",
                            const Color.fromARGB(255, 250, 250, 249),
                            const Color.fromARGB(255, 229, 219, 30)),
                        _crearBoton(
                            "incendio",
                            Icons.local_fire_department,
                            "Incendio",
                            const Color.fromARGB(255, 250, 250, 249),
                            const Color.fromARGB(255, 215, 130, 27)),
                        _crearBoton(
                            "siniestro",
                            Icons.car_crash_rounded,
                            "Siniestro",
                            const Color.fromARGB(255, 250, 250, 249),
                            const Color.fromARGB(255, 50, 30, 229)),
                        _crearBoton(
                            "ambulancia",
                            Icons.medical_services_rounded,
                            "Ambulancia",
                            const Color.fromARGB(255, 250, 250, 249),
                            const Color.fromARGB(255, 87, 8, 110)),
                        _botonMasOpciones(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 65,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          foregroundColor: Colors.white,
                          elevation: 4,
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2),
                        ),
                      ),
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
            if (mostrarAvisoLlamada)
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_in_talk, color: Colors.white),
                      SizedBox(width: 10),
                      Text("Atento, ya recibirá una llamada",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
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
      colorFondo: const Color.fromARGB(255, 252, 250, 250),
      accion: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ReclamosPage()));
      },
    );
  }
}
