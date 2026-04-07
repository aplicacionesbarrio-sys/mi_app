import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
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

    String fechaHora = "";
    if (data['fecha'] != null) {
      fechaHora = DateFormat('dd/MM/yyyy HH:mm')
          .format((data['fecha'] as Timestamp).toDate());
    }

    final String barrioMostrado =
        data['barrio_vecino'] ?? data['barrio'] ?? 'Sin barrio';

    final String direccionMostrada = (data['domicilio'] != null &&
            data['domicilio'].toString().trim().isNotEmpty)
        ? data['domicilio']
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
            // 1. TIPO DE RECLAMO (CENTRADO Y EN ROJO)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "TIPO DE RECLAMO:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${data['tipo'] ?? 'Sin tipo'}".toUpperCase(),
                    textAlign: TextAlign.center, // Centra el texto si es largo
                    style: const TextStyle(
                      fontSize: 20, // Un poco más grande para que destaque
                      fontWeight: FontWeight.w900, // Más negrita
                      color: Colors.redAccent,
                      height: 1.1, // Ajusta el espacio entre líneas
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 20, thickness: 1.2),

            // 2. DATOS DE UBICACIÓN Y CONTACTO
            _datoRenglon(Icons.home, "BARRIO", barrioMostrado),
            _datoRenglon(Icons.location_on, "DIRECCIÓN", direccionMostrada),
            _datoRenglon(Icons.phone, "TELÉFONO",
                "${data['numerodecelular'] ?? 'Sin número'}"),

            const Divider(height: 20),

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
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. DETALLES
            Center(
              child: Column(
                children: [
                  const Text("DETALLE:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      data['detalle'] ?? 'Sin detalle',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5. REGISTRO Y BOTÓN GPS
            _datoRenglon(Icons.access_time, "REGISTRADO EL", fechaHora),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _abrirMapa(data['ubicacion'] as GeoPoint?),
                icon: const Icon(Icons.navigation, size: 24),
                label: const Text("IR AL LUGAR (GPS)",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoRenglon(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, color: Colors.black87),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              Text(valor,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
