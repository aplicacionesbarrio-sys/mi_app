import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaAlertasScreen extends StatefulWidget {
  const MapaAlertasScreen({super.key});

  @override
  State<MapaAlertasScreen> createState() => _MapaAlertasScreenState();
}

class _MapaAlertasScreenState extends State<MapaAlertasScreen> {
  final Set<Marker> _marcadores = {};

  static const CameraPosition posicionInicial = CameraPosition(
    target: LatLng(-29.4131, -66.8558),
    zoom: 14,
  );

  BitmapDescriptor iconoRobo = BitmapDescriptor.defaultMarker;
  BitmapDescriptor iconoSiniestro = BitmapDescriptor.defaultMarker;
  BitmapDescriptor iconoSospechoso = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    cargarIconos();
    agregarMarcadorDemo();
  }

  Future cargarIconos() async {
    iconoRobo = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/icons/robo.png",
    );

    iconoSiniestro = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/icons/siniestro.png",
    );

    iconoSospechoso = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/icons/sospechoso.png",
    );
  }

  void agregarMarcadorDemo() {
    Future.delayed(const Duration(seconds: 2), () {
      final marcador = Marker(
        markerId: const MarkerId("robo_demo"),
        position: const LatLng(-29.4131, -66.8558),
        icon: iconoRobo,
        infoWindow: const InfoWindow(title: "Alerta de Robo"),
      );

      setState(() {
        _marcadores.add(marcador);
      });
    });
  }

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
