import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VistaEntidadScreen extends StatelessWidget {
  const VistaEntidadScreen({super.key});

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
  Map<String, Marker> _markersMap = {};
  // Guardamos las suscripciones para cancelarlas al cerrar la pantalla
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _conectarFuentesDeDatos();
  }

  @override
  void dispose() {
    // Limpieza de memoria
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  void _conectarFuentesDeDatos() {
    // Escuchamos múltiples colecciones para tener un mapa completo
    _escucharColeccion('reclamos', BitmapDescriptor.hueBlue);
    _escucharColeccion('alertas', BitmapDescriptor.hueRed);
    _escucharColeccion('servicios', BitmapDescriptor.hueOrange);
  }

  void _escucharColeccion(String nombreColeccion, double colorHue) {
    final sub = FirebaseFirestore.instance
        .collection(nombreColeccion)
        .where('estado', isEqualTo: 'pendiente')
        .snapshots()
        .listen((snapshot) {
      // ESTA ES LA LÍNEA QUE CAMBIA:
      _procesarSnapshot(snapshot, colorHue, nombreColeccion);
    });
    _subscriptions.add(sub);
  }

  void _procesarSnapshot(
      QuerySnapshot snapshot, double colorHue, String coleccion) {
    // 1. Borramos del mapa solo los marcadores de la colección que se acaba de actualizar
    _markersMap.removeWhere((key, value) => key.startsWith('$coleccion-'));

    // 2. Agregamos los que están pendientes actualmente
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['ubicacion'] != null) {
        GeoPoint pos = data['ubicacion'];
        String markerId = '$coleccion-${doc.id}'; // ID único para no mezclar

        _markersMap[markerId] = Marker(
          markerId: MarkerId(markerId),
          position: LatLng(pos.latitude, pos.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(colorHue),
          infoWindow: InfoWindow(
            title: "${data['tipo'] ?? 'Aviso'}".toUpperCase(),
            snippet:
                'Vecino: ${data['nombre'] ?? "Anónimo"}\nDom: ${data['domicilio'] ?? ""}',
          ),
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text("MONITOREO EN TIEMPO REAL",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                setState(() => _markersMap.clear()), // Limpiar y recargar
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-29.4110, -66.8506), // La Rioja
              zoom: 13,
            ),
            markers: _markersMap.values.toSet(),
            myLocationEnabled: true,
            mapType: MapType.normal,
          ),
          _buildLeyenda(),
        ],
      ),
    );
  }

  Widget _buildLeyenda() {
    return Positioned(
      bottom: 20,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeyendaItem(color: Colors.red, texto: "Alertas"),
            _LeyendaItem(color: Colors.blue, texto: "Reclamos"),
            _LeyendaItem(color: Colors.orange, texto: "Servicios"),
          ],
        ),
      ),
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String texto;
  const _LeyendaItem({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.location_on, color: color, size: 18),
        const SizedBox(width: 5),
        Text(texto,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
