import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class ServiciosPage extends StatefulWidget {
  const ServiciosPage({super.key});

  @override
  State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {
  // --- SECCIÓN: CONFIGURACIÓN DE DATOS ---
  String servicioSeleccionado = "";
  bool enviando = false;
  String cartelConfirmacion = "";
  Timer? timerDesmarcar;
  Map<String, bool> serviciosBloqueados = {};

  // Variables que se muestran en la pantalla y se envían a gestión
  String nombreVecinoReal = "Cargando...";
  String telefonoVecinoReal = "...";
  String barrioReal = "No especificado";
  String domicilioReal = "No especificado";

  // --- LISTADO DE OFICIOS (MANTENGO TUS COLORES ORIGINALES) ---
  final List<Map<String, dynamic>> misOficios = [
    {
      "nombre": "Albañil",
      "icono": Icons.foundation,
      "colorBase": const Color.fromARGB(255, 250, 251, 250),
      "colorPresionado": const Color(0xFF97786D),
      "colorIcono": const Color.fromARGB(255, 62, 26, 145),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Gomeria",
      "icono": Icons.tire_repair,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color(0xFFD75BDB),
      "colorIcono": const Color.fromARGB(255, 179, 165, 41),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Jardinero",
      "icono": Icons.yard,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": Colors.green,
      "colorIcono": const Color.fromARGB(255, 163, 104, 104),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Plomero",
      "icono": Icons.plumbing,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color.fromARGB(255, 75, 115, 176),
      "colorIcono": const Color.fromARGB(255, 186, 129, 37),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Electricista",
      "icono": Icons.electrical_services,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color.fromARGB(255, 214, 125, 77),
      "colorIcono": const Color.fromARGB(255, 38, 122, 137),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Gasista",
      "icono": Icons.propane_tank,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color.fromARGB(255, 206, 92, 92),
      "colorIcono": const Color.fromARGB(255, 21, 156, 25),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Cerrajero",
      "icono": Icons.vpn_key,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color(0xFFA59210),
      "colorIcono": const Color.fromARGB(221, 156, 31, 31),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Herrero",
      "icono": Icons.precision_manufacturing,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color.fromARGB(255, 154, 96, 180),
      "colorIcono": const Color.fromARGB(255, 109, 15, 15),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Pintor",
      "icono": Icons.format_paint,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color.fromARGB(255, 151, 83, 120),
      "colorIcono": const Color.fromARGB(255, 37, 34, 187),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Otros",
      "icono": Icons.more_horiz,
      "colorBase": const Color.fromARGB(255, 252, 252, 252),
      "colorPresionado": const Color.fromARGB(221, 67, 44, 159),
      "colorIcono": const Color.fromARGB(255, 35, 29, 29),
      "colorLetra": const Color.fromARGB(221, 16, 12, 12)
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarEstadoBloqueos();
    obtenerDatosUsuario();
  }

  Future<void> obtenerDatosUsuario() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      String deviceIdOriginal = await _getDeviceId();
      String deviceIdLimpio = deviceIdOriginal;
      final match = RegExp(r'(STAS[\w\.\-]+)').firstMatch(deviceIdOriginal);
      if (match != null) deviceIdLimpio = match.group(0)!;
      deviceIdLimpio = deviceIdLimpio.trim().toUpperCase();

      var query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('deviceId', isEqualTo: deviceIdLimpio)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty && mounted) {
        var userDoc = query.docs.first.data();

        String n = userDoc['nombre'] ?? "Vecino";
        String t = userDoc['numerodecelular'] ?? "Sin Tel";
        String b = userDoc['barrio'] ?? "No especificado";
        String d = userDoc['domicilio'] ?? "No especificado";

        // Guardamos en memoria local
        await prefs.setString('nombre_local', n);
        await prefs.setString('tel_local', t);
        await prefs.setString('barrio_local', b);
        await prefs.setString('domicilio_local', d);

        setState(() {
          nombreVecinoReal = n;
          telefonoVecinoReal = t;
          barrioReal = b;
          domicilioReal = d;
        });
        return;
      }
    } catch (e) {
      debugPrint("Error: $e");
    }

    if (mounted) {
      setState(() {
        nombreVecinoReal = prefs.getString('nombre_local') ?? "Vecino";
        telefonoVecinoReal = prefs.getString('tel_local') ?? "Sin Tel";
        barrioReal = prefs.getString('barrio_local') ?? "No especificado";
        domicilioReal = prefs.getString('domicilio_local') ?? "No especificado";
      });
    }
  }

  Future<String> _getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model + androidInfo.id;
    } else {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "unknown_ios";
    }
  }

  void enviarPedido() async {
    if (servicioSeleccionado.isEmpty || enviando) return;

    setState(() {
      enviando = true;
      cartelConfirmacion = "Solicitud de $servicioSeleccionado enviada";
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      // Reparación de la vibración (Error naranja corregido)
      bool canVibrate = await Vibration.hasVibrator() ?? false;
      if (canVibrate) Vibration.vibrate(duration: 500);

      // Envío a Firebase con etiquetas exactas para el Tablero de Gestión
      await FirebaseFirestore.instance.collection('servicios').add({
        'tipo': servicioSeleccionado,
        'nombre': nombreVecinoReal,
        'numerodecelular': telefonoVecinoReal,
        'barrio': barrioReal,
        'domicilio': domicilioReal,
        'fecha': FieldValue.serverTimestamp(),
        'ubicacion': GeoPoint(position.latitude, position.longitude),
        'estado': 'pendiente',
      });

      if (mounted) {
        setState(() => serviciosBloqueados[servicioSeleccionado] = true);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("fecha_servicio_$servicioSeleccionado",
            DateTime.now().toIso8601String());
      }
    } catch (e) {
      debugPrint("Error al enviar: $e");
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
          servicioSeleccionado = "";
        });
        Timer(const Duration(seconds: 8), () {
          if (mounted) setState(() => cartelConfirmacion = "");
        });
      }
    }
  }

  void _iniciarTemporizador() {
    timerDesmarcar?.cancel();
    timerDesmarcar = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => servicioSeleccionado = "");
    });
  }

  Future<void> _cargarEstadoBloqueos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime ahora = DateTime.now();
    for (var oficio in misOficios) {
      String nombre = oficio['nombre'];
      String? fechaStr = prefs.getString("fecha_servicio_$nombre");
      if (fechaStr != null) {
        DateTime fechaGuardada = DateTime.parse(fechaStr);
        if (ahora.difference(fechaGuardada).inMinutes < 2) {
          setState(() => serviciosBloqueados[nombre] = true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 187, 233, 246),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text("Barrio Seguro",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 15),
              const Text("Seleccioná tu servicio",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 15),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    itemCount: misOficios.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.8,
                    ),
                    itemBuilder: (context, index) {
                      String nombre = misOficios[index]['nombre'];
                      bool estaBloqueado = serviciosBloqueados[nombre] ?? false;
                      bool estaSeleccionado = servicioSeleccionado == nombre;

                      return GestureDetector(
                        onTap: estaBloqueado
                            ? null
                            : () {
                                setState(() => servicioSeleccionado = nombre);
                                _iniciarTemporizador();
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            color: estaBloqueado
                                ? Colors.grey.shade400
                                : (estaSeleccionado
                                    ? misOficios[index]['colorPresionado']
                                    : misOficios[index]['colorBase']),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: estaSeleccionado
                                    ? Colors.black
                                    : Colors.white.withOpacity(0.3),
                                width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(misOficios[index]['icono'],
                                  size: 35,
                                  color: estaBloqueado
                                      ? Colors.grey
                                      : misOficios[index]['colorIcono']),
                              const SizedBox(width: 8),
                              Text(nombre,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: estaBloqueado
                                          ? Colors.grey
                                          : misOficios[index]['colorLetra'])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: servicioSeleccionado.isEmpty ||
                            enviando ||
                            nombreVecinoReal == "Cargando..."
                        ? null
                        : enviarPedido,
                    child: Text(enviando ? "ENVIANDO..." : "ENVIAR PEDIDO",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
          if (cartelConfirmacion.isNotEmpty)
            Positioned(
              top: 15,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade400, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(cartelConfirmacion,
                            style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 17,
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
