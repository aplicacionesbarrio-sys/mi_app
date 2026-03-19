import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'servicios_page.dart';

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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  botonAlerta("robo", "🚨", "Robo"),
                  botonAlerta("sospechoso", "🔍", "Sospechoso"),
                  botonAlerta("incendio", "🔥", "Incendio"),
                  botonAlerta("siniestro", "🚗", "Siniestro"),
                  botonAlerta("ambulancia", "🚑", "Ambulancia"),
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DenunciasPage(),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 60,
                            color: Colors.black,
                          ),
                          SizedBox(height: 8),
                          Text("Más opciones"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Center(
                child: SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    onPressed: tipoAlertaSeleccionada.isEmpty
                        ? null
                        : () {
                            enviarAlerta();
                          },
                    child: const Text(
                      "Enviar Alerta",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 👇👇👇 FLECHA ACA (FUNCIONA)

              const SizedBox(height: 40),
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
          elevation: 12,
          backgroundColor: tipo == "robo"
              ? (tipoAlertaSeleccionada == tipo
                  ? Colors.blue
                  : Colors.blue.shade100)
              : tipo == "sospechoso"
                  ? (tipoAlertaSeleccionada == tipo
                      ? Colors.orange
                      : Colors.orange.shade100)
                  : tipo == "incendio"
                      ? (tipoAlertaSeleccionada == tipo
                          ? Colors.red
                          : Colors.red.shade100)
                      : tipo == "siniestro"
                          ? (tipoAlertaSeleccionada == tipo
                              ? Colors.yellow
                              : Colors.yellow.shade100)
                          : tipo == "ambulancia"
                              ? (tipoAlertaSeleccionada == tipo
                                  ? Colors.green
                                  : Colors.green.shade100)
                              : null,
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
            Image.asset(
              "assets/botones/$tipo.png",
              width: 70,
              height: 70,
            ),
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

class DenunciasPage extends StatefulWidget {
  const DenunciasPage({super.key});

  @override
  State<DenunciasPage> createState() => _DenunciasPageState();
}

class _DenunciasPageState extends State<DenunciasPage> {
  String urgenciaSeleccionada = "";
  Timer? temporizador;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        child: Column(
          children: [
            const Text(
              "Selecciona tu reclamo",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            boton(
              tipo: "agua",
              icono: Icons.water_drop,
              texto: "Pérdida de agua",
            ),

            boton(
              tipo: "cable",
              emoji: "⚡",
              texto: "Cable caído",
            ),

            boton(
              tipo: "gas",
              icono: Icons.cloud,
              texto: "Pérdida de gas",
            ),

            const SizedBox(height: 40),

            if (urgenciaSeleccionada != "")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    print("Reclamo enviado: $urgenciaSeleccionada");
                  },
                  child: const Text(
                    "Enviar reclamo",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // 🔥 FLECHA BIEN ABAJO DE TODO
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServiciosPage(),
                  ),
                );
              },
              child: const Icon(
                Icons.arrow_forward,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget boton({
    required String tipo,
    IconData? icono,
    String? emoji,
    required String texto,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          urgenciaSeleccionada = tipo;
        });

        temporizador?.cancel();

        temporizador = Timer(const Duration(seconds: 15), () {
          if (!mounted) return;
          setState(() {
            urgenciaSeleccionada = "";
          });
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: urgenciaSeleccionada == tipo ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Center(
                child: icono != null
                    ? Icon(
                        icono,
                        size: 28,
                        color: tipo == "agua" ? Colors.lightBlue : Colors.black,
                      )
                    : Text(
                        emoji ?? "",
                        style: const TextStyle(fontSize: 28),
                      ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: icono != null
                    ? Icon(
                        icono,
                        size: 28,
                        color: tipo == "agua" ? Colors.lightBlue : Colors.black,
                      )
                    : Text(
                        emoji ?? "",
                        style: const TextStyle(fontSize: 28),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
