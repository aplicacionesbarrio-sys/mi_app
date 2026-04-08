import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ReclamoDetallePage extends StatelessWidget {
  final QueryDocumentSnapshot reclamo;

  const ReclamoDetallePage({super.key, required this.reclamo});

  // 🛡️ FUNCIÓN GPS BLINDADA
  Future<void> _abrirMapa(GeoPoint? ubicacion) async {
    if (ubicacion == null) return;

    // Corregido: Eliminado el '2' y agregadas las llaves ${}
    final url =
        'https://www.google.com/maps/search/?api=1&query=${ubicacion.latitude},${ubicacion.longitude}';

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("No se pudo abrir el mapa");
      }
    } catch (e) {
      debugPrint("Error al lanzar GPS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ Casteo seguro de datos
    final data = reclamo.data() as Map<String, dynamic>? ?? {};

    String fechaHora = "No disponible";
    if (data['fecha'] != null && data['fecha'] is Timestamp) {
      fechaHora = DateFormat('dd/MM/yyyy HH:mm')
          .format((data['fecha'] as Timestamp).toDate());
    }

    final String barrioMostrado =
        data['barrio_vecino'] ?? data['barrio'] ?? 'Sin barrio';

    final String direccionMostrada = (data['domicilio'] != null &&
            data['domicilio'].toString().trim().isNotEmpty)
        ? data['domicilio'].toString()
        : 'No especificada';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 1.2),
            const SizedBox(height: 10),

            // 2. BLOQUE DE DATOS PRINCIPALES
            _datoRenglon(Icons.home, "BARRIO", barrioMostrado),
            _datoRenglon(Icons.location_on, "DIRECCIÓN", direccionMostrada),
            _datoRenglon(Icons.phone, "TELÉFONO",
                "${data['numerodecelular'] ?? 'Sin número'}"),

            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 20),

            // 3. VECINO
            _datoCentrado("VECINO", "${data['nombre'] ?? 'Sin nombre'}", 22),

            const SizedBox(height: 25),

            // 4. DETALLE
            _datoCentrado("DETALLE DEL RECLAMO",
                data['detalle'] ?? 'Sin descripción adicional', 18,
                italico: true),

            const SizedBox(height: 30),

            // 5. FECHA Y BOTÓN
            _datoRenglon(Icons.access_time, "FECHA DE REGISTRO", fechaHora),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _abrirMapa(data['ubicacion'] as GeoPoint?),
                icon: const Icon(Icons.navigation, size: 24),
                label: const Text("INICIAR NAVEGACIÓN GPS",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para datos centrados
  Widget _datoCentrado(String etiqueta, String valor, double size,
      {bool italico = false}) {
    return Center(
      child: Column(
        children: [
          Text("$etiqueta: ",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 12)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              valor,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.bold,
                fontStyle: italico ? FontStyle.italic : FontStyle.normal,
                color: const Color(0xFF2D3142),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoRenglon(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 22, color: Colors.green.shade700),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.grey)),
                Text(valor,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
