import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

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

  // --- SECCIÓN: LÓGICA DE BLOQUEO (24 Horas) ---
  // Aquí se guardan los servicios que ya fueron pedidos para deshabilitarlos
  Map<String, bool> serviciosBloqueados = {};

  // --- SECCIÓN: LISTADO DE OFICIOS ---
  final List<Map<String, dynamic>> misOficios = [
    {"nombre": "Albañil", "icono": Icons.foundation, "color": Colors.brown},
    {"nombre": "Gomeria", "icono": Icons.tire_repair, "color": Colors.blueGrey},
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
    {"nombre": "Cerrajero", "icono": Icons.vpn_key, "color": Colors.amber},
    {
      "nombre": "Herrero",
      "icono": Icons.precision_manufacturing,
      "color": Colors.grey
    },
  ];

  // --- SECCIÓN: FUNCIÓN ENVIAR A FIREBASE ---
  void enviarPedido() async {
    if (servicioSeleccionado.isEmpty || enviando) return;

    setState(() {
      enviando = true;
      cartelConfirmacion = "Solicitud de $servicioSeleccionado enviada";
    });

    // Simulación de envío a Firebase (Aquí cargarás los datos del vecino luego)
    await FirebaseFirestore.instance.collection('pedidos_servicios').add({
      'servicio': servicioSeleccionado,
      'fecha': DateTime.now(),
      // Aquí irán Nombre, Celular, GPS del vecino registrado
    });

    // Bloqueamos el servicio seleccionado
    setState(() {
      serviciosBloqueados[servicioSeleccionado] = true;
    });

    // --- TIEMPO DEL CARTEL VERDE (5 segundos) ---
    Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => cartelConfirmacion = "");
    });

    // --- TIEMPO DE RE-ACTIVACIÓN (Aquí cambias las 24h) ---
    Timer(const Duration(hours: 24), () {
      if (mounted) {
        setState(() {
          serviciosBloqueados[servicioSeleccionado] = false;
        });
      }
    });

    setState(() {
      enviando = false;
      servicioSeleccionado = ""; // Limpiamos selección para el próximo
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
        // --- ESTA ES LA FLECHA de volver en la pantalla 3 ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white, size: 28), // Le puse 38 para que se note
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              Column(
          children: [
            const SizedBox(height: 20),
            
            // --- AQUÍ APARECE EL TÍTULO NUEVO ---
            const Text(
              "Seleccioná tu servicio",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            
            
              // --- SECCIÓN: GRILLA DE 2 COLUMNAS ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: GridView.builder(
                    itemCount: misOficios.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 Columnas
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.8, // Controla el ALTO de los botones
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
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            // Si está bloqueado es gris, si no, usa el color que elegiste
                            color: estaBloqueado
                                ? Colors.grey.shade300
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

              // --- SECCIÓN: BOTÓN ENVIAR ABAJO ---
              Padding(
                padding: const EdgeInsets.all(30),
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: servicioSeleccionado.isEmpty || enviando
                        ? null
                        : enviarPedido,
                    child: Text(enviando ? "ENVIANDO..." : "ENVIAR PEDIDO"),
                  ),
                ),
              ),
            ],
          ),

          // --- SECCIÓN: CARTEL VERDE DE ARRIBA ---
          if (cartelConfirmacion.isNotEmpty)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 5)
                  ],
                ),
                child: Text(
                  cartelConfirmacion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
