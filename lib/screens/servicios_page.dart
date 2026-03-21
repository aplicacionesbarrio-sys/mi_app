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
  // --- SECCIÓN: LÓGICA DE BLOQUEO (24 Horas) ---
  Map<String, bool> serviciosBloqueados = {};

  // --- SECCIÓN: LISTADO DE OFICIOS ---
  final List<Map<String, dynamic>> misOficios = [
    {
      "nombre": "Albañil",
      "icono": Icons.foundation,
      "color": const Color.fromARGB(255, 151, 120, 109)
    },
    {
      "nombre": "Gomeria",
      "icono": Icons.tire_repair,
      "color": const Color.fromARGB(255, 215, 91, 219)
    },
    {"nombre": "Jardinero", "icono": Icons.yard, "color": Colors.green},
    {"nombre": "Plomero", "icono": Icons.plumbing, "color": Colors.blue},
    {
      "nombre": "Electricista",
      "icono": Icons.electrical_services,
      "color": Colors.orange
    },
    {
      "nombre": "Gasista",
      "icono": Icons.propane_tank,
      "color": Colors.redAccent
    },
    {
      "nombre": "Cerrajero",
      "icono": Icons.vpn_key,
      "color": const Color.fromARGB(255, 225, 199, 25)
    },
    {
      "nombre": "Herrero",
      "icono": Icons.precision_manufacturing,
      "color": const Color.fromARGB(255, 89, 5, 128)
    },
    {
      "nombre": "Pintor",
      "icono": Icons.format_paint,
      "color": Colors.pinkAccent
    },
    {"nombre": "Otros", "icono": Icons.more_horiz, "color": Colors.blueGrey},
  ];

  // --- NUEVO: LECTOR DE LA LIBRETA AL INICIAR ---
  @override
  void initState() {
    super.initState();
    _cargarEstadoBloqueos(); // Lee la memoria apenas abre la pantalla
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
          // esto es para q la memoria guarde y al reiniciar el cel no se olvide
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

    // El cartel de arriba desaparece a los 5 segundos
    Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => cartelConfirmacion = "");
    });

    // Desbloqueo en  horas de boton servicio enviado
    Timer(const Duration(hours: 1), () {
      if (mounted) {
        setState(() {
          serviciosBloqueados[servicioSeleccionado] = false;
        });
      }
    });

    // Esto anota la hora del pedido en la memoria del celular
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("fecha_servicio_$servicioSeleccionado",
        DateTime.now().toIso8601String());

    setState(() {
      enviando = false;
      servicioSeleccionado = "";
    });
  }

  void _iniciarTemporizador() {
    timerDesmarcar
        ?.cancel(); // duracion de espera de boton enviar en pantalla 3
    timerDesmarcar = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          servicioSeleccionado = "";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text(
          "Barrio Seguro",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 15), // espacio arriba
              const Text(
                "Seleccioná tu servicio",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15), // espacio abajo
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
                                setState(() {
                                  servicioSeleccionado = nombre;
                                });
                                _iniciarTemporizador();
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            color: estaBloqueado
                                ? Colors.grey.shade400
                                : (estaSeleccionado
                                    ? misOficios[index]['color']
                                    : Colors.blue.shade50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: estaSeleccionado
                                  ? Colors.black
                                  : Colors.blue.shade200,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(misOficios[index]['icono'],
                                  color: estaBloqueado
                                      ? Colors.grey
                                      : (estaSeleccionado
                                          ? Colors.white
                                          : misOficios[index]['color'])),
                              const SizedBox(width: 8),
                              Text(nombre,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: estaBloqueado
                                          ? Colors.grey
                                          : (estaSeleccionado
                                              ? Colors.white
                                              : Colors.black87))),
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
                      disabledBackgroundColor:
                          Colors.grey.shade400.withOpacity(1.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: servicioSeleccionado.isEmpty || enviando
                        ? null
                        : enviarPedido,
                    child: Text(
                      enviando ? "ENVIANDO..." : "ENVIAR PEDIDO",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- CARTEL FLOTANTE (Solo el de arriba) ---
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
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cartelConfirmacion,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 17,
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
