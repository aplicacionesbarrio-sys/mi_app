import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'vista_reclamo_screen.dart';
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

              // --- ZONA DE SEGURIDAD PARA QUE NO EXPLOTE ---
              String barrio = data.data().containsKey('barrio_vecino')
                  ? data['barrio_vecino']
                  : "Sin barrio";

              String nombre = data.data().containsKey('nombre')
                  ? data['nombre']
                  : "Vecino Anónimo";
              // ----------------------------------------------

              // --- LÓGICA DE COLORES PARA EL ESTADO ---
              String estado = data.data().containsKey('estado')
                  ? data['estado']
                  : 'pendiente';
              // Buscá esto y dejalo ASÍ:
              Color colorEstado =
                  (estado == 'solucionado') ? Colors.blue : Colors.green;
              String textoEstado =
                  (estado == 'solucionado') ? 'SOLUCIONADO' : 'PENDIENTE';

              return GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text("⚠️ ¿Eliminar Reclamo?"),
                      content: const Text(
                          "Esta acción borrará el reclamo permanentemente."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("CANCELAR"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () {
                            data.reference
                                .delete(); // 🔥 Esto borra de Firebase
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Reclamo eliminado")),
                            );
                          },
                          child: const Text("ELIMINAR",
                              style: TextStyle(color: Colors.white)),
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
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    (data['tipo'] ?? 'Sin tipo')
                                        .toString()
                                        .toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      nombre,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.touch_app,
                              color: Colors.grey, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("🏠 $barrio",
                          style: TextStyle(color: Colors.grey.shade700)),
                      Text(
                        "Cel: ${data['numerodecelular'] ?? 'Sin número'}",
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 1. Extraemos los datos una sola vez para que funcionen en ambos botones
                          (() {
                            final datosMapeados =
                                data.data() as Map<String, dynamic>;

                            return Expanded(
                              // Usamos Expanded para que se acomoden bien
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // --- BOTÓN DE ESTADO (CAMBIA COLOR) ---
                                  ElevatedButton(
                                    onPressed: () async {
                                      String nuevoEstado =
                                          (datosMapeados['estado'] ==
                                                  'solucionado')
                                              ? 'pendiente'
                                              : 'solucionado';

                                      await FirebaseFirestore.instance
                                          .collection(
                                              'reclamos') // <--- REVISÁ QUE SE LLAME ASÍ TU COLECCIÓN
                                          .doc(data.id)
                                          .update({'estado': nuevoEstado});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorEstado,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                    ),
                                    child: Text(textoEstado,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),

                                  // --- FLECHITA DE DETALLES ---
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios,
                                        size: 18, color: Colors.blueGrey),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              VistaReclamoScreen(
                                            // 1. Usamos 'nombre' que es el real en tu Firebase
                                            nombre: datosMapeados['nombre'] ??
                                                'Sin nombre',

                                            // 2. Corregimos el Barrio (fijate si en Firebase es 'barrio' o 'Barrio')
                                            barrio: datosMapeados['barrio'] ??
                                                datosMapeados['Barrio'] ??
                                                'Sin barrio',

                                            // 3. Usamos 'numerodecelular' que es el que vimos en tu inicio_page
                                            telefono: datosMapeados[
                                                    'numerodecelular'] ??
                                                'Sin número',

                                            tipo: datosMapeados['tipo'] ??
                                                'Sin tipo',
                                            detalle: datosMapeados['detalle'] ??
                                                'Sin detalle',
                                            ubicacion:
                                                datosMapeados['ubicacion'],
                                            fecha: datosMapeados['fecha'],
                                            direccion: datosMapeados
                                                    .containsKey('direccion')
                                                ? datosMapeados['direccion']
                                                : 'No especificada',
                                          ),
                                        ),
                                      );
                                    },
                                  ), // <--- Asegurate de que termine así, con coma o punto y coma según donde esté
                                ],
                              ),
                            );
                          })(),
                        ],
                      ),
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
