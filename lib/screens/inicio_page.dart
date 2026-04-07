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
  int rolUsuario = 3; // Nivel de acceso (3 por defecto es vecino)
  String barrioReal = "Cargando...";
  bool cargando = true;
  String domicilioReal = "";

  @override
  void initState() {
    super.initState();
    obtenerUbicacionActual(); // <--- Le agregamos "Actual" al final
    obtenerDatosUsuario(); // ESTO NO SE TOCA, es tu configuración de ID
  }

  // --- TU FUNCIÓN ACTUAL (NO SE TOCA) ---
  Future<void> obtenerDatosUsuario() async {
    debugPrint("ENTRÓ A obtenerDatosUsuario");
    var build = await DeviceInfoPlugin().androidInfo;
    String idCelu = build.id;

    var usuarioQuery = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('deviceId', isEqualTo: idCelu)
        .get();

    if (usuarioQuery.docs.isNotEmpty) {
      final datos = usuarioQuery.docs.first.data();

      // Verificamos que la pantalla siga activa antes de seguir
      if (!mounted) return;

      int rol = datos['rol'] ?? 3;
      String estado = datos['estado'] ?? 'pendiente';

      // 1. Buscamos la memoria local
      final prefs = await SharedPreferences.getInstance();
      bool yaValidoCodigo = prefs.getBool('codigoValidado') ?? false;

      debugPrint("🛡️ ROL: $rol | ESTADO: $estado | VALIDADO: $yaValidoCodigo");

      // Verificamos de nuevo antes de navegar (seguridad de Flutter)
      if (!mounted) return;

      // 2. EL SEMÁFORO
      if (rol == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomePage()),
        );
      } else if (rol == 3) {
        // Si no está activo y nunca puso el código, va a validación
        if (estado == 'pendiente' && !yaValidoCodigo) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ValidacionPage()),
          );
        } else {
          debugPrint("✅ Usuario persistente. Se queda en inicio.");
          if (mounted) {
            setState(() {
              domicilioReal = datos['domicilio'] ?? "";
              nombreVecinoReal = datos['nombre'] ?? "Sin nombre";
              barrioReal = datos['barrio'] ?? "Sin barrio";
              telefonoVecinoReal = datos['numerodecelular'] ?? "...";
              cargando = false;
            });
          }
        }
      }
    } else {
      if (!mounted) return;
      {
        // <--- AGREGAR ESTA LÍNEA
        setState(() {
          cargando = false;
        });
      }
    }
  }

  // --- FUNCIÓN NUEVA: PARA EL GPS (AGREGALA ACÁ) ---
  Future<void> obtenerUbicacionActual() async {
    try {
      // 1. Pedimos permiso al celular (Esto abre el cartelito)
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // 2. Si nos dio permiso, buscamos la latitud y longitud
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        if (mounted) {
          // <--- AGREGAR ESTA LÍNEA
          setState(() {
            lat = position.latitude;
            lng = position.longitude;
          });
        }
        debugPrint("📍 Ubicación lista: $lat, $lng");
      }
    } catch (e) {
      debugPrint("⚠️ El GPS no respondió: $e");
    }
  }

  void enviarAlerta() async {
    if (tipoAlertaSeleccionada == "" || botonHabilitado == false) return;
    String alertaMandada = tipoAlertaSeleccionada;
    List<String> paraQuien = [];

    // Lógica de destinatarios
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
      mensajeConfirmacion = "Alerta por ${alertaMandada.toUpperCase()} enviada";
      mostrarAvisoLlamada = true; // Mostramos el cartel verde inmediatamente
      alertasBloqueadas.add(tipoAlertaSeleccionada);
      tipoAlertaSeleccionada = "";
    });

    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 500);
    }
    if (telefonoVecinoReal == "...") {
      await obtenerDatosUsuario();
    }
    // Guardado en Firebase
    FirebaseFirestore.instance.collection('alertas').add({
      'tipo': alertaMandada,
      'nombre_vecino': nombreVecinoReal,
      'numerodecelular': telefonoVecinoReal,
      'fecha': FieldValue.serverTimestamp(),
      'ubicacion': GeoPoint(lat, lng),
      'link_mapa': 'https://www.google.com/maps?q=$lat,$lng',
      'destinatarios': paraQuien,
      'estado': 'activa', // 👈 CLAVE
      'barrio_vecino': barrioReal.isEmpty ? "Sin barrio" : barrioReal,
      'domicilio': domicilioReal,
    });

    // TEMPORIZADOR: El cartel verde de arriba desaparece a los 10 segundos
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          mostrarAvisoLlamada = false;
        });
      }
    });

    // tiempo para cartel blanco
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() {
          botonHabilitado = true;
        });

        Timer(const Duration(seconds: 180), () {
          if (mounted) {
            setState(() {
              alertasBloqueadas.remove(alertaMandada);
            });
          }
        });
      }
    });
  }

  void alPresionarBoton(String tipo) {
    setState(() => tipoAlertaSeleccionada = tipo);
    temporizadorAlerta
        ?.cancel(); // tiempo que dura la alerta hasta q se desmarca
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
      colorFondo: alertasBloqueadas.contains(tipo)
          ? Colors.grey.shade400
          : (estaSeleccionado ? colorResaltado : colorBase),
      accion: () {
        if (!alertasBloqueadas.contains(tipo)) {
          // 1. Le avisamos a Flutter que la pantalla CAMBIÓ
          setState(() {
            tipoAlertaSeleccionada = tipo;
          });

          // 2. Ejecutamos tu lógica normal
          alPresionarBoton(tipo);
        }
      },
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
            // El contenido principal con Scroll
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
                  const SizedBox(
                      height:
                          30), // aqui cambie la distancia del boton era de 30
                  // BOTÓN EXCLUSIVO PARA ADMIN DE SERVICIOS (Nivel 2)
                  if (rolUsuario <= 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.assignment_turned_in,
                            color: Colors.white),
                        label: const Text("VER PEDIDOS DE SERVICIOS",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.orange, // Color Naranja para diferenciarlo
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AdminServiciosPage()),
                          );
                        },
                      ),
                    ),

                  if (!botonHabilitado)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.red.shade900, width: 1.5),
                        ),
                        child: Text(
                          "Alerta enviada. Por favor, quédese atento, ya lo van a llamar.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
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
                          elevation: 4,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: (tipoAlertaSeleccionada.isEmpty ||
                                !botonHabilitado ||
                                alertasBloqueadas
                                    .contains(tipoAlertaSeleccionada))
                            ? null
                            : enviarAlerta,
                        child: Text(
                            botonHabilitado ? "ENVIAR ALERTA" : "ESPERE...",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // 🟢 CARTEL VERDE (Flota arriba de todo cuando mostrarAvisoLlamada es true)
            if (mostrarAvisoLlamada)
              Positioned(
                top: 10,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    border:
                        Border.all(color: const Color(0xFFB9E9C3), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF5BB568), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          mensajeConfirmacion, // Usa el texto dinámico que ya tenías
                          style: const TextStyle(
                              color: Color(0xFF357644),
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
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
        debugPrint("👉 BOTON MAS OPCIONES PRESIONADO");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReclamosPage(),
          ),
        );
      },
    );
  }
}
