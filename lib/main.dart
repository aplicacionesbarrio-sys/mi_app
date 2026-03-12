import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'mapa_alertas_screen.dart';

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
      home: MapaAlertasScreen(),
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
    setState(() {
      contadorAlertas++;
      historial.add("Alerta #$contadorAlertas enviada");
    });

    print("BOTON FUNCIONANDO");
    FirebaseFirestore.instance.collection('alertas').add({
      'numero': contadorAlertas,
      'tipo': 'robo',
      'barrio': 'centro',
      'nombre': 'vecino',
      'telefono': '000000000',
      'mensaje': '🚨 Robo reportado',
      'fecha': DateTime.now(),
      'lat': lat,
      'lng': lng,
      'mapa': 'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚨 Robo reportado"),
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
        title: const Text("Barrio Seguro"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Alertas en el barrio:",
            style: TextStyle(fontSize: 22),
          ),
          Text(
            "$contadorAlertas",
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text("Latitud: $lat"),
          ElevatedButton(
            onPressed: enviarAlerta,
            child: const Text("Enviar Alerta"),
          ),
          const SizedBox(height: 20),
          const Text(
            "Historial de alertas",
            style: TextStyle(fontSize: 18),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: obtenerAlertas(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var alertas = snapshot.data!.docs.toList();

                return ListView.builder(
                  itemCount: alertas.length,
                  itemBuilder: (context, index) {
                    var alerta = alertas[index];

                    return ListTile(
                      leading: const Icon(Icons.warning, color: Colors.red),
                      title: Text(alerta['mensaje']),
                      subtitle: Text("Tocar para abrir mapa"),
                      onTap: () async {
                        final url = Uri.parse(alerta['mapa']);

                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
