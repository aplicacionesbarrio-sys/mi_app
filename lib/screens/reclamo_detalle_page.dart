import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Asegúrate de tener esta librería
import 'package:intl/intl.dart';

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
    debugPrint("DEBUG RECLAMO: $data");
    String fechaHora = DateFormat('dd/MM/yyyy HH:mm')
        .format((data['fecha'] as Timestamp).toDate());
    final String barrioMostrado = data['barrio_vecino'] ??
        data['barrio'] ??
        data['Barrio'] ??
        'Sin barrio';

    // Dirección considerando vacío o nulo
    final String direccionMostrada = (data['domicilio'] != null &&
            data['domicilio'].toString().trim().isNotEmpty)
        ? data['domicilio']
        : (data['barrio'] != null &&
                data['barrio'].toString().trim().isNotEmpty)
            ? data['barrio']
            : 'No especificada';

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
            Center(
              child: Column(
                children: [
                  const Text("TIPO DE RECLAMO:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(
                    "${data['tipo'] ?? 'Sin tipo'}".toUpperCase(),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                ],
              ),
            ),

            const Divider(height: 30),

            // 2. BARRIO Y DIRECCIÓN
            _datoRenglon(Icons.home, "BARRIO", barrioMostrado),
            _datoRenglon(Icons.location_on, "DIRECCIÓN", direccionMostrada),

            _datoRenglon(Icons.phone, "TELÉFONO",
                "${data['numerodecelular'] ?? 'Sin número'}"),

            const Divider(height: 30),

            // 3. DATOS DEL VECINO
            Center(
              child: Column(
                children: [
                  const Text("VECINO:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(
                    "${data['nombre'] ?? 'Sin nombre'}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 4. DETALLES

            // 4. DETALLES
            Center(
              child: Column(
                children: [
                  const Text("DETALLE:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(
                    // Lógica para cortar a 50 letras
                    data['detalle'] != null &&
                            data['detalle'].toString().length > 50
                        ? "${data['detalle'].toString().substring(0, 50)}..."
                        : "${data['detalle'] ?? 'Sin detalle'}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            _datoRenglon(Icons.access_time, "REGISTRADO EL", fechaHora),
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
      {Color color = Colors.black, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 10),
          Text("$etiqueta: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              valor,
              // AQUÍ ESTÁ EL CAMBIO:
              style: TextStyle(color: color, fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }
}
