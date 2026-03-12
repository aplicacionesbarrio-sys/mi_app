import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaAlertasScreen extends StatefulWidget {
  const MapaAlertasScreen({super.key});

  @override
  State<MapaAlertasScreen> createState() => _MapaAlertasScreenState();
}

class _MapaAlertasScreenState extends State<MapaAlertasScreen> {
  final Set<Marker> _marcadores = {};
  @override
  void initState() {
    super.initState();

    _marcadores.add(
      Marker(
        markerId: MarkerId("alerta1"),
        position: LatLng(-29.4131, -66.8558),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: "Robo",
          snippet: "Alerta reportada",
        ),
      ),
    );
  }

  static const CameraPosition posicionInicial = CameraPosition(
    target: LatLng(-29.4131, -66.8558),
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de Alertas"),
      ),
      body: GoogleMap(
        initialCameraPosition: posicionInicial,
        markers: _marcadores,
      ),
    );
  }
}
