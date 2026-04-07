import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ IMPORTANTE: Para realizar la llamada

class AdminServiciosPage extends StatelessWidget {
  const AdminServiciosPage({super.key});

  // 📞 FUNCIÓN PARA REALIZAR LA LLAMADA
  Future<void> _realizarLlamada(String celular) async {
    if (celular.isEmpty) return;
    final Uri tel = Uri.parse("tel:$celular");
    if (await canLaunchUrl(tel)) {
      await launchUrl(tel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Servicios",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('servicios')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay pedidos activos"));
          }

          return ListView(
            padding: const EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              bool fueContactado = data['contactoIniciado'] ?? false;
              String estadoPago = data['estadoPago'] ?? "debe";
              Color colorBorde = fueContactado ? Colors.green : Colors.orange;
              String numeroCelular = data['numerodecelular'] ?? "";

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: colorBorde, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onLongPress: () => _confirmarBorrado(context, doc.reference),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("${data['nombre']} - ${data['tipo']}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text("Cel: $numeroCelular"),
                          // 📞 BOTÓN DE LLAMADA DIRECTA
                          trailing: IconButton(
                            icon: const Icon(Icons.phone_forwarded,
                                color: Colors.green, size: 30),
                            onPressed: () => _realizarLlamada(numeroCelular),
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: fueContactado
                                    ? Colors.green
                                    : Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => doc.reference
                                  .update({'contactoIniciado': !fueContactado}),
                              child: Text(fueContactado
                                  ? "Contactado ✅"
                                  : "Marcar Contacto"),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                String nuevoEstado =
                                    (estadoPago == "debe") ? "pago" : "debe";
                                doc.reference
                                    .update({'estadoPago': nuevoEstado});
                              },
                              icon: Icon(
                                estadoPago == "pago"
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: estadoPago == "pago"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              label: Text(
                                  estadoPago == "pago" ? "PAGÓ" : "DEBE",
                                  style: TextStyle(
                                      color: estadoPago == "pago"
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _confirmarBorrado(BuildContext context, DocumentReference ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar este pedido?"),
        content: const Text(
            "Si el trabajo ya se hizo y se pagó, podés borrarlo definitivamente."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.delete();
              Navigator.pop(context);
            },
            child: const Text("BORRAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
