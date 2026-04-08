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

  String nombreVecinoReal = "Cargando...";
  String telefonoVecinoReal = "...";
  String barrioReal = "No especificado";
  String domicilioReal = "No especificado";

  final List<Map<String, dynamic>> misOficios = [
    {
      "nombre": "Albañil",
      "icono": Icons.foundation,
      "colorBase": const Color(0xFFFAFBFA),
      "colorPresionado": const Color(0xFF97786D),
      "colorIcono": const Color(0xFF3E1A91),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Gomeria",
      "icono": Icons.tire_repair,
      "colorBase": const Color(0xFFF9F8F8),
      "colorPresionado": const Color(0xFFD75BDB),
      "colorIcono": const Color(0xFFB3A529),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Jardinero",
      "icono": Icons.yard,
      "colorBase": const Color(0xFFF9F8F8),
      "colorPresionado": Colors.green,
      "colorIcono": const Color(0xFFA36868),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Plomero",
      "icono": Icons.plumbing,
      "colorBase": const Color(0xFFF9F8F8),
      "colorPresionado": const Color(0xFF4B73B0),
      "colorIcono": const Color(0xFFBA8125),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Electricista",
      "icono": Icons.electrical_services,
      "colorBase": const Color(0xFFF9F8F8),
      "colorPresionado": const Color(0xFFD67D4D),
      "colorIcono": const Color(0xFF267A89),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Gasista",
      "icono": Icons.propane_tank,
      "colorBase": const Color(0xFFF9F8F8),
      "colorPresionado": const Color(0xFFCE5C5C),
      "colorIcono": const Color(0xFF159C19),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Cerrajero",
      "icono": Icons.vpn_key,
      "colorBase": const Color(0xFFF9F8F8),
      "colorPresionado": const Color(0xFFA59210),
      "colorIcono": const Color(0xDD9C1F1F),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Herrero",
      "icono": Icons.precision_manufacturing,
      "colorBase": const Color(0xFFF9F8F8),
      "colorPresionado": const Color(0xFF9A60B4),
      "colorIcono": const Color(0xFF6D0F0F),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Pintor",
      "icono": Icons.format_paint,
      "colorBase": const Color(0xFFF9F8F8),
      "colorPresionado": const Color(0xFF975378),
      "colorIcono": const Color(0xFF2522BB),
      "colorLetra": Colors.black87
    },
    {
      "nombre": "Otros",
      "icono": Icons.more_horiz,
      "colorBase": const Color(0xFFFCFCFC),
      "colorPresionado": const Color(0xDD432C9F),
      "colorIcono": const Color(0xFF231D1D),
      "colorLetra": const Color(0xDD100C0C)
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarEstadoBloqueos();
    obtenerDatosUsuario();
  }

  @override
  void dispose() {
    timerDesmarcar?.cancel();
    super.dispose();
  }

  Future<void> obtenerDatosUsuario() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Prioridad 1: Cargar lo que tengamos en SharedPreferences para respuesta instantánea
    setState(() {
      nombreVecinoReal = prefs.getString('nombre_local') ?? "Vecino";
      telefonoVecinoReal = prefs.getString('tel_local') ?? "Sin Tel";
      barrioReal = prefs.getString('barrio_local') ?? "No especificado";
      domicilioReal = prefs.getString('domicilio_local') ?? "No especificado";
    });

    try {
      String deviceIdLimpio = await _getDeviceIdLimpio();

      var query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('deviceId', isEqualTo: deviceIdLimpio)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty && mounted) {
        var userDoc = query.docs.first.data();
        setState(() {
          nombreVecinoReal = userDoc['nombre'] ?? nombreVecinoReal;
          telefonoVecinoReal = userDoc['numerodecelular'] ?? telefonoVecinoReal;
          barrioReal = userDoc['barrio'] ?? barrioReal;
          domicilioReal = userDoc['domicilio'] ?? domicilioReal;
        });

        // Actualizar caché
        await prefs.setString('nombre_local', nombreVecinoReal);
        await prefs.setString('tel_local', telefonoVecinoReal);
        await prefs.setString('barrio_local', barrioReal);
        await prefs.setString('domicilio_local', domicilioReal);
      }
    } catch (e) {
      debugPrint("Error sincronizando datos: $e");
    }
  }

  Future<String> _getDeviceIdLimpio() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String id = "";
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      id = androidInfo.model + androidInfo.id;
    } else {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      id = iosInfo.identifierForVendor ?? "unknown_ios";
    }
    final match = RegExp(r'(STAS[\w\.\-]+)').firstMatch(id);
    return (match != null ? match.group(0)! : id).trim().toUpperCase();
  }

  void enviarPedido() async {
    if (servicioSeleccionado.isEmpty || enviando) return;

    setState(() {
      enviando = true;
    });

    try {
      // 1. Obtener ubicación con timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      // 2. Feedback háptico
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 500);
      }

      // 3. Subir a Firebase
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

      // 4. Bloqueo preventivo (evita spam)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = "fecha_servicio_$servicioSeleccionado";
      await prefs.setString(key, DateTime.now().toIso8601String());

      if (mounted) {
        setState(() {
          serviciosBloqueados[servicioSeleccionado] = true;
          cartelConfirmacion = "Solicitud de $servicioSeleccionado enviada";
          servicioSeleccionado = "";
        });
      }
    } catch (e) {
      _mostrarError("No se pudo enviar. Reintenta.");
    } finally {
      if (mounted) {
        setState(() => enviando = false);
        Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => cartelConfirmacion = "");
        });
      }
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
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
        // Bloqueo por 2 minutos para evitar duplicados accidentales
        if (ahora.difference(fechaGuardada).inMinutes < 2) {
          setState(() => serviciosBloqueados[nombre] = true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBBE9F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[700],
        centerTitle: true,
        title: const Text("SERVICIOS DEL BARRIO",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              const Text("¿Qué servicio necesitás?",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A237E))),
              const SizedBox(height: 15),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: misOficios.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    var oficio = misOficios[index];
                    bool bloqueado =
                        serviciosBloqueados[oficio['nombre']] ?? false;
                    bool seleccionado =
                        servicioSeleccionado == oficio['nombre'];

                    return InkWell(
                      onTap: bloqueado
                          ? null
                          : () {
                              setState(() =>
                                  servicioSeleccionado = oficio['nombre']);
                              _iniciarTemporizador();
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: bloqueado
                              ? Colors.grey[300]
                              : (seleccionado
                                  ? oficio['colorPresionado']
                                  : oficio['colorBase']),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            if (seleccionado)
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                          ],
                          border: Border.all(
                            color: seleccionado
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(oficio['icono'],
                                size: 32,
                                color: bloqueado
                                    ? Colors.grey
                                    : (seleccionado
                                        ? Colors.white
                                        : oficio['colorIcono'])),
                            const SizedBox(height: 5),
                            Text(oficio['nombre'],
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: bloqueado
                                        ? Colors.grey
                                        : (seleccionado
                                            ? Colors.white
                                            : oficio['colorLetra']))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildBotonEnviar(),
            ],
          ),
          if (cartelConfirmacion.isNotEmpty) _buildCartelConfirmacion(),
        ],
      ),
    );
  }

  Widget _buildBotonEnviar() {
    bool desactivado = servicioSeleccionado.isEmpty ||
        enviando ||
        nombreVecinoReal == "Cargando...";
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 65,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 5,
          ),
          onPressed: desactivado ? null : enviarPedido,
          child: enviando
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("SOLICITAR SERVICIO NOW",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
        ),
      ),
    );
  }

  Widget _buildCartelConfirmacion() {
    return Positioned(
      top: 10,
      left: 15,
      right: 15,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Text(cartelConfirmacion,
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
