import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

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

  // --- SECCIÓN: LISTADO DE OFICIOS (Tu Tablero de Control) ---
  final List<Map<String, dynamic>> misOficios = [
    {
      "nombre": "Albañil",
      "icono": Icons.foundation,
      "colorBase": const Color.fromARGB(255, 250, 251, 250),
      "colorPresionado": const Color(0xFF97786D),
      "colorIcono": const Color.fromARGB(255, 62, 26, 145),
      "colorLetra": Colors.black87,
    },
    {
      "nombre": "Gomeria",
      "icono": Icons.tire_repair,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color(0xFFD75BDB),
      "colorIcono": Colors.yellow,
      "colorLetra": Colors.black87,
    },
    {
      "nombre": "Jardinero",
      "icono": Icons.yard,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": Colors.green,
      "colorIcono": const Color.fromARGB(255, 163, 104, 104),
      "colorLetra": Colors.black87,
    },
    {
      "nombre": "Plomero",
      "icono": Icons.plumbing,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color.fromARGB(255, 75, 115, 176),
      "colorIcono": const Color.fromARGB(255, 153, 194, 73),
      "colorLetra": Colors.black87,
    },
    {
      "nombre": "Electricista",
      "icono": Icons.electrical_services,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color.fromARGB(255, 214, 125, 77),
      "colorIcono": Color.fromARGB(255, 38, 122, 137),
      "colorLetra": Colors.black87,
    },
    {
      "nombre": "Gasista",
      "icono": Icons.propane_tank,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": Colors.red.shade900,
      "colorIcono": const Color.fromARGB(255, 21, 156, 25),
      "colorLetra": Colors.black87,
    },
    {
      "nombre": "Cerrajero",
      "icono": Icons.vpn_key,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color(0xFFA59210),
      "colorIcono": Colors.black87,
      "colorLetra": Colors.black87,
    },
    {
      "nombre": "Herrero",
      "icono": Icons.precision_manufacturing,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color.fromARGB(255, 154, 96, 180),
      "colorIcono": const Color.fromARGB(255, 109, 15, 15),
      "colorLetra": Colors.black87,
    },
    {
      "nombre": "Pintor",
      "icono": Icons.format_paint,
      "colorBase": const Color.fromARGB(255, 249, 248, 248),
      "colorPresionado": const Color.fromARGB(255, 151, 83, 120),
      "colorIcono": const Color.fromARGB(255, 31, 145, 19),
      "colorLetra": Colors.black87,
    },
    {
      "nombre": "Otros",
      "icono": Icons.more_horiz,
      "colorBase": const Color.fromARGB(255, 252, 252, 252),
      "colorPresionado": const Color.fromARGB(221, 67, 44, 159),
      "colorIcono": const Color.fromARGB(255, 35, 29, 29),
      "colorLetra": const Color.fromARGB(221, 16, 12, 12),
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarEstadoBloqueos();
  }

  Future<void> _cargarEstadoBloqueos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime ahora = DateTime.now();
    setState(() {
      for (var oficio in misOficios) {
        String nombre = oficio['nombre'];
        String? fechaStr = prefs.getString("fecha_servicio_$nombre");
        if (fechaStr != null) {
          DateTime fechaGuardada = DateTime.parse(fechaStr);
          if (ahora.difference(fechaGuardada).inHours < 24) {
            serviciosBloqueados[nombre] = true;
          } else {
            serviciosBloqueados[nombre] = false;
            prefs.remove("fecha_servicio_$nombre");
          }
        }
      }
    });
  }

  void enviarPedido() async {
    if (servicioSeleccionado.isEmpty || enviando) return;
    setState(() {
      enviando = true;
      cartelConfirmacion = "Solicitud de $servicioSeleccionado enviada";
    });

    await FirebaseFirestore.instance.collection('pedidos_servicios').add({
      'servicio': servicioSeleccionado,
      'fecha': DateTime.now(),
    });

    setState(() {
      serviciosBloqueados[servicioSeleccionado] = true;
    });

    Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => cartelConfirmacion = "");
    });

    Timer(const Duration(hours: 1), () {
      if (mounted)
        setState(() => serviciosBloqueados[servicioSeleccionado] = false);
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("fecha_servicio_$servicioSeleccionado",
        DateTime.now().toIso8601String());

    setState(() {
      enviando = false;
      servicioSeleccionado = "";
    });
  }

  void _iniciarTemporizador() {
    timerDesmarcar?.cancel();
    timerDesmarcar = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => servicioSeleccionado = "");
    });
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
                            // USA LOS COLORES DE TU LISTA
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
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                misOficios[index]['icono'],
                                // USA EL COLOR DE ICONO DE TU LISTA
                                color: estaBloqueado
                                    ? Colors.grey
                                    : misOficios[index]['colorIcono'],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                nombre,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  // USA EL COLOR DE LETRA DE TU LISTA
                                  color: estaBloqueado
                                      ? Colors.grey
                                      : misOficios[index]['colorLetra'],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // --- BOTÓN ENVIAR ---
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: servicioSeleccionado.isEmpty || enviando
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
          // --- CARTEL DE CONFIRMACIÓN (Este no lo tocamos) ---
          if (cartelConfirmacion.isNotEmpty)
            Positioned(
              top: 15,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade400, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
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
