import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SeguridadPage extends StatefulWidget {
  const SeguridadPage({super.key});

  @override
  State<SeguridadPage> createState() => _SeguridadPageState();
}

class _SeguridadPageState extends State<SeguridadPage> {
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? customIcon;

  final String darkMapStyle = '''


  [
    {"elementType":"geometry","stylers":[{"color":"#1d1d1d"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
    {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#1d1d1d"}]}
  ]
  ''';
// Línea 32: ''';
// Línea 33: PEGÁ ACÁ EL CÓDIGO:

  void _moverAlIncendio(double lat, double lng) {
    if (_mapController == null) {
      debugPrint("⚠️ Controller no inicializado");
      return;
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 17),
    );
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  // 📞 LLAMAR
  Future<void> llamar(String celular) async {
    if (celular.isEmpty) return;

    final Uri tel = Uri.parse("tel:$celular");

    if (await canLaunchUrl(tel)) {
      await launchUrl(tel);
    } else {
      debugPrint("No se pudo abrir llamada");
    }
  }

  // 🗺️ NAVEGAR
  Future<void> abrirMapa(double lat, double lng) async {
    final Uri uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final Uri fallback = Uri.parse(
          "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  // ICONO
  Future<void> cargarIcono(String tipo) async {
    customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(64, 64)),
      obtenerImagenAlerta(tipo),
    );
    if (mounted) setState(() {});
  }

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
        title: const Text("MONITOR DE EMERGENCIAS",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  style: TextStyle(color: Colors.white)),
            );
          }

          var doc = snapshot.data!.docs.first;
          Map<String, dynamic> alerta = doc.data() as Map<String, dynamic>;

          String tipo = alerta['tipo'] ?? 'Alerta';
          String nombre = alerta['nombre_vecino'] ?? 'Vecino';
          String celular = alerta['numerodecelular'] ?? '';

          GeoPoint pos = alerta['ubicacion'];
          double lat = pos.latitude;
          double lng = pos.longitude;

          return Stack(
            children: [
              // 🗺️ MAPA
              Positioned.fill(
                child: GoogleMap(
                  style: darkMapStyle,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(lat, lng),
                    zoom: 17,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('emergencia'),
                      position: LatLng(lat, lng),
                      icon: customIcon ?? BitmapDescriptor.defaultMarker,
                    ),
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;

                    // fuerza refresco en algunos dispositivos (Moto G22 incluido)
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (_mapController != null) {
                        _mapController!.moveCamera(
                          CameraUpdate.newLatLng(LatLng(lat, lng)),
                        );
                      }
                    });

                    cargarIcono(tipo);
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),

              // 🌑 CAPA OSCURA
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 🔥 ICONO + TEXTO
                      Column(
                        children: [
                          Image.asset(obtenerImagenAlerta(tipo), height: 120),
                          const SizedBox(height: 10),
                          Text(
                            tipo.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // 🔴 TARJETA ROJA
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.redAccent, width: 2),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading:
                                  const Icon(Icons.person, color: Colors.white),
                              title: Text(nombre,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 24)),
                            ),
                            ListTile(
                              leading: const Icon(Icons.phone,
                                  color: Colors.greenAccent),
                              title: Text(celular,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20)),
                              onTap: () => llamar(celular),
                            ),
                          ],
                        ),
                      ),

                      // 🚀 BOTON
                      SizedBox(
                        width: double.infinity,
                        height: 65,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                          ),
                          onPressed: () => _moverAlIncendio(lat, lng),
                          icon: const Icon(Icons.navigation),
                          label: const Text("NAVEGAR",
                              style: TextStyle(fontSize: 18)),
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
