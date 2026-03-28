import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importante para leer datos

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
  BitmapDescriptor iconoIncendio = BitmapDescriptor.defaultMarker;
  BitmapDescriptor iconoPolicia = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    cargarIconos();
  }

  Future cargarIconos() async {
    iconoRobo = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/icons/robo.png",
    );
    iconoSiniestro = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/icons/siniestro.png",
    );
    iconoSospechoso = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/icons/sospechoso.png",
    );
    iconoIncendio = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/icons/incendio.png",
    );
    iconoPolicia = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/icons/policia.png",
    );
    setState(() {}); // Actualiza para mostrar iconos una vez cargados
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
        return BitmapDescriptor.defaultMarker;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de Alertas - ADMIN"),
        backgroundColor: Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Escuchamos la colección 'reclamos'
        stream: FirebaseFirestore.instance.collection('reclamos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error al conectar"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Cargando..."));
          }
          _marcadores.clear(); // Limpiamos para no duplicar

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final GeoPoint? pos = data['ubicacion'];
            final String tipo = data['tipo'] ?? "policia";

            if (pos != null) {
              _marcadores.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(pos.latitude, pos.longitude),
                  icon: obtenerIcono(tipo),
                  infoWindow: InfoWindow(
                    title: tipo.toUpperCase(),
                    snippet: "Vecino: ${data['nombre_vecino'] ?? 'Sin nombre'}",
                  ),
                ),
              );
            }
          }

          return GoogleMap(
            initialCameraPosition: posicionInicial,
            markers: _marcadores,
            myLocationEnabled: true,
          );
        },
      ),
    );
  }
}
