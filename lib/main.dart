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
  bool botonHabilitado = true;
  bool mostrarAvisoLlamada =
      false; // Controla el botón de "atento ya recibirá..."

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
    if (tipoAlertaSeleccionada == "" || botonHabilitado == false) return;

    setState(() {
      botonHabilitado = false;
      contadorAlertas++;
      mensajeConfirmacion = " Alerta por $tipoAlertaSeleccionada enviada";
      mostrarAvisoLlamada = false; // Nos aseguramos que empiece oculto
    });

    // Envío a Firebase
    FirebaseFirestore.instance.collection('alertas').add({
      'numero': contadorAlertas,
      'tipo': tipoAlertaSeleccionada,
      'fecha': DateTime.now(),
      'lat': lat,
      'lng': lng,
    });

    // --- TIEMPO 1: Cartel de ARRIBA (10 segundos) ---
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          mensajeConfirmacion = ""; // Desaparece el de arriba
          mostrarAvisoLlamada = true; // ¡AQUÍ APARECE EL DE ABAJO!
        });
      }
    });

    // --- TIEMPO 2: Cartel de ABAJO (¿Cuánto tiempo querés que se vea?) ---
    // Cambiá el 20 por los segundos que quieras que dure el aviso de la llamada
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() {
          mostrarAvisoLlamada = false; // Desaparece el de abajo solito
        });
      }
    });

    // --- TIEMPO 3: Bloqueo del botón enviar alerta
    Future.delayed(const Duration(seconds: 22), () {
      if (mounted) {
        setState(() {
          botonHabilitado = true; // El botón vuelve a estar rojo
        });
      }
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
      body: Stack(
        children: [
          // CAPA 1: Botones y títulos
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 15),
                const Text("Selecciona tu alerta",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed:
                          (tipoAlertaSeleccionada.isEmpty || !botonHabilitado)
                              ? null
                              : enviarAlerta,
                      child: Text(
                        botonHabilitado ? "ENVIAR ALERTA" : "ESPERE...",
                        style: const TextStyle(
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

          // CAPA 2: El cartel verde de ARRIBA
          if (mensajeConfirmacion.isNotEmpty)
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade400, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mensajeConfirmacion,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // CAPA 3: Aviso "Atento, ya recibirá una llamada" (ABAJO)
          if (mostrarAvisoLlamada)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.green.shade600, // <--- CAMBIÁ EL COLOR ACÁ
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 4))
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_in_talk, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Atento, ya recibirá una llamada",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
} // CIERRE DE LA CLASE _InicioPageState