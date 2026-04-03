import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'reclamo_detalle_page.dart';


class PanelReclamos extends StatelessWidget {
  const PanelReclamos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.green, // 🟢 COLOR VERDE
        title: const Text(
          "Gestión de Reclamos",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('reclamos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reclamos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reclamos.length,
            itemBuilder: (context, index) {
              final data = reclamos[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Container(), // 👈 TEMPORAL
                    ),
                  );
                },

                // 🔥 MANTENER PRESIONADO PARA BORRAR
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Eliminar reclamo"),
                      content: const Text("¿Seguro que querés eliminarlo?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar"),
                        ),
                        TextButton(
                          onPressed: () {
                            data.reference.delete();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Eliminar",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },

                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${data['tipo']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text("👤 ${data['nombre']}"),
                      Text("🏘 ${data['barrio_vecino'] ?? 'Sin barrio'}"),
                      Text("📞 ${data['numerodecelular']}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
