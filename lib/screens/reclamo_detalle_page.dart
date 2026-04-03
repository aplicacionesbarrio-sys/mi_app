import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReclamoDetallePage extends StatelessWidget {
  final QueryDocumentSnapshot reclamo;

  const ReclamoDetallePage({super.key, required this.reclamo});

  @override
  Widget build(BuildContext context) {
    final data = reclamo;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Detalle del Reclamo",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tipo: ${data['tipo']}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("👤 Nombre: ${data['nombre']}"),
            const SizedBox(height: 5),
            Text("🏘 Barrio: ${data['barrio_vecino'] ?? 'Sin dato'}"),
            const SizedBox(height: 5),
            Text("📞 Teléfono: ${data['numerodecelular']}"),
            const SizedBox(height: 10),
            Text("📝 Detalle: ${data['detalle']}"),
            const SizedBox(height: 10),
            Text("📅 Fecha: ${data['fecha'] ?? 'Sin fecha'}"),
          ],
        ),
      ),
    );
  }
}
