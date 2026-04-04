import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Asegúrate de tener esta librería

class ReclamoDetallePage extends StatelessWidget {
  final QueryDocumentSnapshot reclamo;

  const ReclamoDetallePage({super.key, required this.reclamo});

  // Función para abrir el mapa
  Future<void> _abrirMapa(GeoPoint? ubicacion) async {
    if (ubicacion != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${ubicacion.latitude},${ubicacion.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = reclamo.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green, // El verde que te gusta
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Detalles del Reclamo",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("VECINO:",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text("${data['nombre'] ?? 'Sin nombre'}",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(height: 30),

            _datoRenglon(
                Icons.home, "BARRIO", "${data['barrio'] ?? 'Sin barrio'}"),
            _datoRenglon(Icons.phone, "TELÉFONO",
                "${data['numerodecelular'] ?? 'Sin número'}"),
            _datoRenglon(Icons.warning, "TIPO", "${data['tipo'] ?? 'Sin tipo'}",
                color: Colors.red),

            const SizedBox(height: 20),
            const Text("DETALLE:",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text("${data['detalle'] ?? 'Sin detalle adicional'}",
                style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 30),

            // BOTÓN GPS (Lo rescatamos de la otra pantalla)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _abrirMapa(data['ubicacion'] as GeoPoint?),
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

  Widget _datoRenglon(IconData icono, String etiqueta, String valor,
      {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 10),
          Text("$etiqueta: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(valor, style: TextStyle(color: color, fontSize: 16))),
        ],
      ),
    );
  }
}
