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
// --- COPIÁ Y PEGÁ ESTA LÍNEA DE ABAJO ---
    print("DEBUG RECLAMO: $data");
    // --- LÓGICA PARA BUSCAR EL BARRIO CORRECTO ---
    final String barrioMostrado = data['barrio_vecino'] ??
        data['barrio'] ??
        data['Barrio'] ??
        'Sin barrio';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
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
            // 1. TIPO DE RECLAMO
            const Text("TIPO DE RECLAMO:",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text("${data['tipo'] ?? 'Sin tipo'}".toUpperCase(),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),

            const Divider(height: 30),

            // 2. BARRIO Y TELÉFONO
            _datoRenglon(Icons.home, "BARRIO", barrioMostrado),

            // --- PROBEMOS CON 'barrio' QUE SÍ ESTÁ EN TU FIREBASE ---
            _datoRenglon(Icons.location_on, "DIRECCIÓN",
                "${data['domicilio'] ?? data['barrio'] ?? 'No especificada'}"),

            _datoRenglon(Icons.phone, "TELÉFONO",
                "${data['numerodecelular'] ?? 'Sin número'}"),

            const Divider(height: 30),

            // 3. DATOS DEL VECINO (Ahora más abajo)
            const Text("VECINO:",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text("${data['nombre'] ?? 'Sin nombre'}",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 25),

            // 4. DETALLES
            const Text("DETALLE:",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text("${data['detalle'] ?? 'Sin detalle adicional'}",
                style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 30),

            // 5. BOTÓN GPS
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _abrirMapa(data['ubicacion'] as GeoPoint?),
                icon: const Icon(Icons.navigation),
                label: const Text("IR AL LUGAR (GPS)",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
