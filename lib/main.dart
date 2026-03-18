import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
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
      'fecha': DateTime.now(),
      'lat': lat,
      'lng': lng,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🚨 Alerta enviada: $tipoAlertaSeleccionada"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barrio Seguro"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // ROBO
                  botonAlerta("robo", "🚨", "Robo"),

                  // SOSPECHOSO
                  botonAlerta("sospechoso", "🔍", "Sospechoso"),

                  // INCENDIO
                  botonAlerta("incendio", "🔥", "Incendio"),

                  // SINIESTRO
                  botonAlerta("siniestro", "🚗", "Siniestro"),

                  // AMBULANCIA
                  botonAlerta("ambulancia", "🚑", "Ambulancia"),
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
      ),
    );
  }

  Widget botonAlerta(String tipo, String emoji, String texto) {
    return SizedBox(
      width: 150,
      height: 150,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: tipoAlertaSeleccionada == tipo ? Colors.red : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          setState(() {
            tipoAlertaSeleccionada = tipo;
          });

          temporizadorAlerta?.cancel();

          temporizadorAlerta = Timer(const Duration(seconds: 15), () {
            setState(() {
              tipoAlertaSeleccionada = "";
            });
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              texto,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
