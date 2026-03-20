import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

// CONEXIONES ORGANIZADAS
import 'screens/denuncias_page.dart';
import 'screens/servicios_page.dart';
import 'widgets_personalizados.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  int contadorAlertas = 5;
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
    if (tipoAlertaSeleccionada == "") return;
    setState(() {
      contadorAlertas++;
      mensajeConfirmacion = "🚨 Alerta por $tipoAlertaSeleccionada enviada";
    });

    FirebaseFirestore.instance.collection('alertas').add({
      'numero': contadorAlertas,
      'tipo': tipoAlertaSeleccionada,
      'fecha': DateTime.now(),
      'lat': lat,
      'lng': lng,
    });

    Future.delayed(const Duration(minutes: 3), () {
      if (mounted) setState(() => mensajeConfirmacion = "");
    });
  }

  void alPresionarBoton(String tipo) {
    setState(() => tipoAlertaSeleccionada = tipo);
    temporizadorAlerta?.cancel();
    temporizadorAlerta = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => tipoAlertaSeleccionada = "");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Barrio Seguro"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (mensajeConfirmacion != "")
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(mensajeConfirmacion,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20,
                        color: Colors.red,
                        fontWeight: FontWeight.bold)),
              ),
            const Text("Selecciona tu alerta",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // --- LA NUEVA GRILLA PERFECTA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap:
                    true, // Permite que la grilla viva dentro del scroll
                physics:
                    const NeverScrollableScrollPhysics(), // Evita conflictos de scroll
                crossAxisCount: 2, // 2 columnas exactas
                mainAxisSpacing: 15, // Espacio arriba/abajo
                crossAxisSpacing: 15, // Espacio izquierda/derecha
                childAspectRatio:
                    1.05, // Ajusta esto para que sean más o menos altos
                children: [
                  BotonAlerta(
                    texto: "Robo",
                    rutaImagen: "assets/botones/robo.png",
                    colorFondo: tipoAlertaSeleccionada == "robo"
                        ? Colors.blue
                        : Colors.blue.shade100,
                    accion: () => alPresionarBoton("robo"),
                  ),
                  BotonAlerta(
                    texto: "Sospechoso",
                    rutaImagen: "assets/botones/sospechoso.png",
                    colorFondo: tipoAlertaSeleccionada == "sospechoso"
                        ? Colors.blue
                        : Colors.blue.shade100,
                    accion: () => alPresionarBoton("sospechoso"),
                  ),
                  BotonAlerta(
                    texto: "Incendio",
                    rutaImagen: "assets/botones/incendio.png",
                    colorFondo: tipoAlertaSeleccionada == "incendio"
                        ? Colors.blue
                        : Colors.blue.shade100,
                    accion: () => alPresionarBoton("incendio"),
                  ),
                  BotonAlerta(
                    texto: "Siniestro",
                    rutaImagen: "assets/botones/siniestro.png",
                    colorFondo: tipoAlertaSeleccionada == "siniestro"
                        ? Colors.blue
                        : Colors.blue.shade100,
                    accion: () => alPresionarBoton("siniestro"),
                  ),
                  BotonAlerta(
                    texto: "Ambulancia",
                    rutaImagen: "assets/botones/ambulancia.png",
                    colorFondo: tipoAlertaSeleccionada == "ambulancia"
                        ? Colors.blue
                        : Colors.blue.shade100,
                    accion: () => alPresionarBoton("ambulancia"),
                  ),
                  _botonMasOpciones(),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- BOTÓN LARGO ALINEADO CON LA GRILLA ---
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20), // El mismo padding que la grilla
              child: SizedBox(
                width: double
                    .infinity, // Esto lo estira para que sea igual de ancho que la grilla
                height: 65, // Altura cómoda para presionar
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          15), // Bordes iguales a los de arriba
                    ),
                  ),
                  onPressed:
                      tipoAlertaSeleccionada.isEmpty ? null : enviarAlerta,
                  child: const Text(
                    "ENVIAR ALERTA",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _botonMasOpciones() {
    return BotonAlerta(
      texto: "Más opciones",
      icono: Icons.keyboard_arrow_down,
      colorFondo: Colors.grey.shade200,
      accion: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DenunciasPage()),
        );
      },
    );
  }
}
