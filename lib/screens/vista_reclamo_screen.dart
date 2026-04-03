import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir el mapa

class VistaReclamoScreen extends StatelessWidget {
  final String nombre;
  final String barrio;
  final String telefono;
  final String tipo;
  final String detalle;
  final String direccion;
  final GeoPoint? ubicacion;
  final Timestamp? fecha;

  const VistaReclamoScreen({
    super.key,
    required this.nombre,
    required this.barrio,
    required this.telefono,
    required this.tipo,
    required this.detalle,
    required this.direccion,
    this.ubicacion,
    this.fecha,
  });

  // Función lógica para abrir Google Maps
  Future<void> _abrirMapa() async {
    if (ubicacion != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${ubicacion!.latitude},${ubicacion!.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles del Reclamo"),
        backgroundColor: const Color(0xFF2D3142),
      ),
      body: SingleChildScrollView(
        // Por si el texto es largo y hay que hacer scroll
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👤 VECINO: $nombre",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Text("🏠 BARRIO: $barrio"),
            Text("📍 DIRECCIÓN: $direccion"),
            Text("📞 TELÉFONO: $telefono"),
            const SizedBox(height: 10),
            Text("🚨 TIPO: $tipo",
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("📝 DETALLE:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(detalle),
            const SizedBox(height: 30),

            // BOTÓN DE NAVEGACIÓN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _abrirMapa,
                icon: const Icon(Icons.navigation),
                label: const Text("IR AL LUGAR (GPS)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
