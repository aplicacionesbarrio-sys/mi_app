import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapaAlertasScreen extends StatefulWidget {
  const MapaAlertasScreen({super.key});

  @override
  State<MapaAlertasScreen> createState() => _MapaAlertasScreenState();
}

class _MapaAlertasScreenState extends State<MapaAlertasScreen> {
  // 🛡️ Cambiamos a un mapa de marcadores para actualizaciones más eficientes
  final Map<MarkerId, Marker> _marcadores = {};

  // Posición inicial (La Rioja)
  static const CameraPosition posicionInicial = CameraPosition(
    target: LatLng(-29.4131, -66.8558),
    zoom: 14,
  );

  // Iconos pre-cargados
  BitmapDescriptor iconoRobo = BitmapDescriptor.defaultMarker;
  BitmapDescriptor iconoSiniestro = BitmapDescriptor.defaultMarker;
  BitmapDescriptor iconoSospechoso = BitmapDescriptor.defaultMarker;
  BitmapDescriptor iconoIncendio = BitmapDescriptor.defaultMarker;
  BitmapDescriptor iconoPolicia = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    cargarIconos();
  }

  // 🛡️ BLINDAJE: Manejo de errores en carga de assets
  Future<void> cargarIconos() async {
    try {
      const config = ImageConfiguration(size: Size(48, 48));

      // Cargamos en paralelo para mayor velocidad
      final iconos = await Future.wait([
        BitmapDescriptor.asset(config, "assets/icons/robo.png"),
        BitmapDescriptor.asset(config, "assets/icons/siniestro.png"),
        BitmapDescriptor.asset(config, "assets/icons/sospechoso.png"),
        BitmapDescriptor.asset(config, "assets/icons/incendio.png"),
        BitmapDescriptor.asset(config, "assets/icons/policia.png"),
      ]);

      if (mounted) {
        setState(() {
          iconoRobo = iconos[0];
          iconoSiniestro = iconos[1];
          iconoSospechoso = iconos[2];
          iconoIncendio = iconos[3];
          iconoPolicia = iconos[4];
        });
      }
    } catch (e) {
      debugPrint(
          "⚠️ Error cargando iconos personalizados: $e. Se usarán los de defecto.");
    }
  }

  BitmapDescriptor obtenerIcono(String tipo) {
    switch (tipo.toLowerCase()) {
      case "robo":
        return iconoRobo;
      case "incendio":
        return iconoIncendio;
      case "sospechoso":
        return iconoSospechoso;
      case "siniestro":
        return iconoSiniestro;
      case "policia":
        return iconoPolicia;
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de Alertas - ADMIN",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🛡️ BLINDAJE: Filtramos solo reclamos activos o recientes si fuera necesario
        stream: FirebaseFirestore.instance.collection('reclamos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text("Error de conexión con el servidor"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🛡️ PROCESAMIENTO EFICIENTE: Actualizamos el mapa de marcadores
          _actualizarMarcadores(snapshot.data?.docs ?? []);

          return GoogleMap(
            initialCameraPosition: posicionInicial,
            markers:
                Set<Marker>.of(_marcadores.values), // Convertimos el mapa a Set
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            compassEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              // Aquí podrías aplicar un estilo oscuro al mapa si quisieras
            },
          );
        },
      ),
    );
  }

  // 🛡️ LÓGICA DE PROCESAMIENTO FUERA DEL BUILD
  void _actualizarMarcadores(List<QueryDocumentSnapshot> docs) {
    // Usamos un set temporal de IDs para saber cuáles borrar si ya no están en Firebase
    final List<MarkerId> idsActuales = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final GeoPoint? pos = data['ubicacion'];

      if (pos != null) {
        final markerId = MarkerId(doc.id);
        idsActuales.add(markerId);

        final String tipo = data['tipo'] ?? "policia";
        final String nombre = data['nombre_vecino'] ?? 'Sin nombre';
        final String detalle = data['detalle'] ?? 'Sin detalles adicionales';

        _marcadores[markerId] = Marker(
          markerId: markerId,
          position: LatLng(pos.latitude, pos.longitude),
          icon: obtenerIcono(tipo),
          infoWindow: InfoWindow(
              title: "${tipo.toUpperCase()} - $nombre",
              snippet: detalle,
              onTap: () {
                // 🛡️ Podrías abrir un modal con más info del vecino aquí
              }),
        );
      }
    }

    // 🛡️ Limpieza: Si un documento se borró en Firebase, lo quitamos del mapa local
    _marcadores.removeWhere((key, value) => !idsActuales.contains(key));
  }
}
