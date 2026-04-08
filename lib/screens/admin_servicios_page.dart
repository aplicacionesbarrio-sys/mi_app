import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminServiciosPage extends StatelessWidget {
  const AdminServiciosPage({super.key});

  // 🛡️ BLINDAJE: Función de llamada con protección anti-errores
  Future<void> _realizarLlamada(BuildContext context, String celular) async {
    if (celular.isEmpty) {
      _mostrarMensaje(context, "El número de celular está vacío.");
      return;
    }

    // Limpiamos el string por si viene con espacios o guiones raros
    final String cleanPhone = celular.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri tel = Uri.parse("tel:$cleanPhone");

    try {
      if (await canLaunchUrl(tel)) {
        await launchUrl(tel);
      } else {
        // --- PROTECCIÓN AQUÍ ---
        if (!context.mounted) return;

        _mostrarMensaje(context, "No se pudo abrir la aplicación de llamadas.");
      }
    } catch (e) {
      // --- Y OTRA AQUÍ ---
      if (!context.mounted) return;

      _mostrarMensaje(context, "Error al intentar llamar: $e");
    }
  }

  // 🛡️ BLINDAJE: Función auxiliar para avisar al usuario
  void _mostrarMensaje(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: Colors.redAccent),
    );
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
          // 🛡️ BLINDAJE: Control de errores de conexión
          if (snapshot.hasError) {
            return const Center(
                child: Text("Error al cargar servicios. Reintentando..."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay pedidos activos"));
          }

          return ListView(
            padding: const EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) {
              // 🛡️ BLINDAJE: Verificación de datos nulos para evitar el "red screen"
              final data = doc.data() as Map<String, dynamic>? ?? {};

              bool fueContactado = data['contactoIniciado'] ?? false;
              String estadoPago = data['estadoPago'] ?? "debe";
              Color colorBorde = fueContactado ? Colors.green : Colors.orange;

              // 🛡️ BLINDAJE: Aseguramos que los strings nunca sean nulos
              String numeroCelular = data['numerodecelular']?.toString() ?? "";
              String nombre =
                  data['nombre']?.toString() ?? "Usuario Desconocido";
              String tipo = data['tipo']?.toString() ?? "Servicio";

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
                          title: Text("$nombre - $tipo",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text("Cel: $numeroCelular"),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone_forwarded,
                                color: Colors.green, size: 30),
                            onPressed: () =>
                                _realizarLlamada(context, numeroCelular),
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
                              onPressed: () async {
                                // 🛡️ BLINDAJE: Try-catch para actualizaciones en la nube
                                try {
                                  await doc.reference.update(
                                      {'contactoIniciado': !fueContactado});
                                } catch (e) {
                                  if (!context.mounted) return;
                                  _mostrarMensaje(
                                      context, "Error al actualizar contacto");
                                }
                              },
                              child: Text(fueContactado
                                  ? "Contactado ✅"
                                  : "Marcar Contacto"),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                try {
                                  String nuevoEstado =
                                      (estadoPago == "debe") ? "pago" : "debe";
                                  await doc.reference
                                      .update({'estadoPago': nuevoEstado});
                                } catch (e) {
                                  if (!context.mounted) return;
                                  _mostrarMensaje(
                                      context, "Error al actualizar pago");
                                }
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
            onPressed: () async {
              try {
                await ref.delete();
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                _mostrarMensaje(context, "No se pudo borrar el documento");
              }
            },
            child: const Text("BORRAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
