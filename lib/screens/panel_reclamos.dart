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
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          "Gestión de Reclamos",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reclamos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar datos"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reclamos = snapshot.data!.docs;

          if (reclamos.isEmpty) {
            return const Center(child: Text("No hay reclamos registrados"));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            itemCount: reclamos.length,
            itemBuilder: (context, index) {
              final doc = reclamos[index];
              final data = doc.data() as Map<String, dynamic>;

              // 🛡️ SEGURIDAD DE DATOS (Manejo de nulos)
              String barrio = data['barrio_vecino'] ?? "Sin barrio";
              String nombre = data['nombre'] ?? "Vecino Anónimo";
              String tipo =
                  (data['tipo'] ?? 'Sin tipo').toString().toUpperCase();
              String estado = data['estado'] ?? 'pendiente';
              String celular = data['numerodecelular'] ?? 'Sin número';

              // LÓGICA DE COLORES
              bool esSolucionado = estado == 'solucionado';
              Color colorEstado = esSolucionado ? Colors.blue : Colors.green;
              String textoEstado = esSolucionado ? 'SOLUCIONADO' : 'PENDIENTE';

              return _CardReclamo(
                doc: doc,
                tipo: tipo,
                nombre: nombre,
                barrio: barrio,
                celular: celular,
                estado: estado,
                textoEstado: textoEstado,
                colorEstado: colorEstado,
              );
            },
          );
        },
      ),
    );
  }
}

// 🛡️ COMPONENTE INTERNO PARA MANTENER EL CÓDIGO LIMPIO
class _CardReclamo extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String tipo, nombre, barrio, celular, estado, textoEstado;
  final Color colorEstado;

  const _CardReclamo({
    required this.doc,
    required this.tipo,
    required this.nombre,
    required this.barrio,
    required this.celular,
    required this.estado,
    required this.textoEstado,
    required this.colorEstado,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _confirmarEliminacion(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorEstado, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(nombre,
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.touch_app, color: Colors.grey, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text("🏠 $barrio", style: TextStyle(color: Colors.grey.shade700)),
            Text("📞 Cel: $celular",
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // BOTÓN CAMBIO DE ESTADO
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () => _cambiarEstado(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorEstado,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(textoEstado,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                // BOTÓN IR A DETALLES
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      size: 18, color: Colors.blueGrey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReclamoDetallePage(reclamo: doc),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _cambiarEstado() async {
    String nuevoEstado =
        (estado == 'solucionado') ? 'pendiente' : 'solucionado';
    await doc.reference.update({'estado': nuevoEstado});
  }

  void _confirmarEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("⚠️ ¿Eliminar Reclamo?"),
        content: const Text(
            "Esta acción borrará el reclamo permanentemente de la base de datos."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              doc.reference.delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reclamo eliminado")));
            },
            child:
                const Text("ELIMINAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
