import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';

class SeguridadPage extends StatefulWidget {
  const SeguridadPage({super.key});

  @override
  State<SeguridadPage> createState() => _SeguridadPageState();
}

class _SeguridadPageState extends State<SeguridadPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable(); // Mantiene la pantalla encendida
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  // 📞 FUNCIÓN LLAMAR
  Future<void> llamar(String celular) async {
    if (celular.isEmpty) return;
    final Uri tel = Uri.parse("tel:$celular");
    if (await canLaunchUrl(tel)) {
      await launchUrl(tel);
    }
  }

  // 🗺️ FUNCIÓN NAVEGAR (Abre Google Maps externo)
  Future<void> abrirMapa(double lat, double lng) async {
    final Uri uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // 🖼️ SELECCIÓN DE IMAGEN SEGÚN TIPO
  String obtenerImagenAlerta(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'robo':
        return 'assets/icons/robo.png';
      case 'incendio':
        return 'assets/icons/incendio.png';
      case 'ambulancia':
        return 'assets/icons/ambulancia.png';
      case 'siniestro':
        return 'assets/icons/siniestro.png';
      case 'sospechoso':
        return 'assets/icons/sospechoso.png';
      default:
        return 'assets/icons/logo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB71C1C),
      appBar: AppBar(
        title: const Text(
          "MONITOR DE EMERGENCIAS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18, // 👈 Ya te la puse más chica como querías
          ),
        ),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alertas')
            .where('estado', isEqualTo: 'activa')
            .orderBy('fecha', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("SIN ALERTAS ACTIVAS",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            );
          }

          var doc = snapshot.data!.docs.first;
          Map<String, dynamic> alerta = doc.data() as Map<String, dynamic>;

          String tipo = alerta['tipo'] ?? 'Alerta';
          String nombre = alerta['nombre_vecino'] ?? 'Vecino';
          String celular = alerta['numerodecelular'] ?? '';
          // 🏘️ El campo que el ingeniero va a agregar:
          String barrio = alerta['barrio_vecino'] ?? 'Cargando barrio...';

          GeoPoint pos = alerta['ubicacion'];
          double lat = pos.latitude;
          double lng = pos.longitude;

          return Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 🔥 ICONO CENTRAL + TIPO DE ALERTA
                      Column(
                        children: [
                          Image.asset(obtenerImagenAlerta(tipo), height: 160),
                          const SizedBox(height: 15),
                          Text(
                            tipo.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),

                      // 🔴 TARJETA ROJA (Información del Vecino)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person,
                                  color: Colors.white, size: 30),
                              title: Text(nombre,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold)),
                            ),
                            // 🏘️ NUEVO: Fila del Barrio
                            ListTile(
                              leading: const Icon(Icons.location_city,
                                  color: Colors.white70),
                              title: Text(barrio,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20)),
                            ),
                            ListTile(
                              leading: const Icon(Icons.phone,
                                  color: Colors.greenAccent),
                              title: Text(celular,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 22)),
                              onTap: () => llamar(celular),
                            ),
                          ],
                        ),
                      ),

                      // 🚀 BOTÓN NAVEGAR (Súper accesible)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 8,
                          ),
                          onPressed: () {
                            HapticFeedback
                                .heavyImpact(); // Vibración más fuerte al tocar
                            abrirMapa(lat, lng);
                          },
                          icon: const Icon(Icons.navigation,
                              color: Colors.white, size: 30),
                          label: const Text("NAVEGAR AL LUGAR",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
