import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VistaEntidadScreen extends StatelessWidget {
  const VistaEntidadScreen({super.key}); // Esto quita el aviso de la línea 5

  @override
  Widget build(BuildContext context) {
    return const _MapaEntidad();
  }
}

class _MapaEntidad extends StatefulWidget {
  const _MapaEntidad();

  @override
  State<_MapaEntidad> createState() => _MapaEntidadState();
}

class _MapaEntidadState extends State<_MapaEntidad> {
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _escucharAlertas();
  }

  void _escucharAlertas() {
    FirebaseFirestore.instance
        .collection('reclamos')
        .snapshots()
        .listen((snapshot) {
      Set<Marker> nuevosMarkers = {};
      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data['ubicacion'] != null) {
          GeoPoint pos = data['ubicacion'];
          nuevosMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(pos.latitude, pos.longitude),
              infoWindow: InfoWindow(
                title: data['tipo'] ?? 'Alerta',
                snippet: 'Vecino: ${data['nombre_vecino'] ?? "Anónimo"}',
              ),
            ),
          );
        }
      }
      if (mounted) {
        setState(() {
          _markers = nuevosMarkers;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa de Comisaría")),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(-29.4110, -66.8506), // Centro de La Rioja
          zoom: 14,
        ),
        markers: _markers,
      ),
    );
  }
}
