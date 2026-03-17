import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'mapa_alertas_screen.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: InicioPage(),
    );
  }
}

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  int contadorAlertas = 5;
  List<String> historial = [];
  double lat = 0;
  double lng = 0;
  String tipoAlertaSeleccionada = "";
  Timer? temporizadorAlerta;
  String mensajeConfirmacion = "";

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

    print("Latitud: $lat");
    print("Longitud: $lng");
  }

  void enviarAlerta() {
    if (tipoAlertaSeleccionada == "") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Primero selecciona un tipo de alerta"),
        ),
      );
      return;
    }

    setState(() {
      contadorAlertas++;
      historial.add("Alerta $tipoAlertaSeleccionada enviada");
      mensajeConfirmacion = "🚨 Alerta por $tipoAlertaSeleccionada enviada";
    });

    Future.delayed(const Duration(minutes: 3), () {
      if (!mounted) return;
      setState(() {
        mensajeConfirmacion = "";
      });
    });

    FirebaseFirestore.instance.collection('alertas').add({
      'numero': contadorAlertas,
      'tipo': tipoAlertaSeleccionada,
      'barrio': 'centro',
      'nombre': 'vecino',
      'telefono': '000000000',
      'mensaje':
          '🚨 Alerta: $tipoAlertaSeleccionada\nUbicación: https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      'fecha': DateTime.now(),
      'lat': lat,
      'lng': lng,
      'mapa': 'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🚨 Alerta enviada: $tipoAlertaSeleccionada"),
      ),
    );
  }

  Stream<QuerySnapshot> obtenerAlertas() {
    return FirebaseFirestore.instance
        .collection('alertas')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Barrio Seguro"),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (mensajeConfirmacion != "")
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  mensajeConfirmacion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            const Text(
              "Selecciona tu alerta",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          tipoAlertaSeleccionada == "robo" ? Colors.red : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        tipoAlertaSeleccionada = "robo";
                      });

                      temporizadorAlerta?.cancel();

                      temporizadorAlerta =
                          Timer(const Duration(seconds: 15), () {
                        setState(() {
                          tipoAlertaSeleccionada = "";
                        });
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "🚨",
                          style: TextStyle(fontSize: 40),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Robo",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tipoAlertaSeleccionada == "sospechoso"
                          ? Colors.red
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        tipoAlertaSeleccionada = "sospechoso";
                      });

                      temporizadorAlerta?.cancel();

                      temporizadorAlerta =
                          Timer(const Duration(seconds: 15), () {
                        setState(() {
                          tipoAlertaSeleccionada = "";
                        });
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search, size: 40),
                        SizedBox(height: 8),
                        Text(
                          "Sospechoso",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tipoAlertaSeleccionada == "incendio"
                        ? Colors.red
                        : null,
                  ),
                  onPressed: () {
                    setState(() {
                      tipoAlertaSeleccionada = "incendio";
                    });

                    temporizadorAlerta?.cancel();

                    temporizadorAlerta = Timer(const Duration(seconds: 15), () {
                      setState(() {
                        tipoAlertaSeleccionada = "";
                      });
                    });
                  },
                  child: const Text("🔥 Incendio"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tipoAlertaSeleccionada == "siniestro"
                        ? Colors.red
                        : null,
                  ),
                  onPressed: () {
                    setState(() {
                      tipoAlertaSeleccionada = "siniestro";
                    });

                    temporizadorAlerta?.cancel();

                    temporizadorAlerta = Timer(const Duration(seconds: 15), () {
                      setState(() {
                        tipoAlertaSeleccionada = "";
                      });
                    });
                  },
                  child: const Text("🚗 Siniestro"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tipoAlertaSeleccionada == "ambulancia"
                        ? Colors.red
                        : null,
                  ),
                  onPressed: () {
                    setState(() {
                      tipoAlertaSeleccionada = "ambulancia";
                    });

                    temporizadorAlerta?.cancel();

                    temporizadorAlerta = Timer(const Duration(seconds: 15), () {
                      setState(() {
                        tipoAlertaSeleccionada = "";
                      });
                    });
                  },
                  child: const Text("🚑 Ambulancia"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: tipoAlertaSeleccionada.isEmpty
                  ? null
                  : () {
                      enviarAlerta();
                    },
              child: const Text("Enviar Alerta"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
