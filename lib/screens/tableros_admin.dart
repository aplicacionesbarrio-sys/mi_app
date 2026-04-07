import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TablerosAdmin extends StatefulWidget {
  const TablerosAdmin({super.key});

  @override
  State<TablerosAdmin> createState() => _TablerosAdminState();
}

class _TablerosAdminState extends State<TablerosAdmin> {
  String coleccionActual = 'reclamos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("TABLEROS DE GESTIÓN",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 79, 30, 152),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSelectorDeTablero(),
          Expanded(child: _buildListaDeDatos()),
        ],
      ),
    );
  }

  Widget _buildSelectorDeTablero() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _botonFiltro("RECLAMOS", 'reclamos', Icons.assignment, Colors.blue),
          _botonFiltro("PÁNICOS", 'alertas', Icons.warning, Colors.red),
          _botonFiltro("SERVICIOS", 'servicios', Icons.build, Colors.orange),
        ],
      ),
    );
  }

  Widget _botonFiltro(
      String texto, String coleccion, IconData icono, Color color) {
    bool seleccionado = coleccionActual == coleccion;
    return GestureDetector(
      onTap: () => setState(() => coleccionActual = coleccion),
      child: Column(
        children: [
          Icon(icono, color: seleccionado ? color : Colors.grey, size: 30),
          Text(texto,
              style: TextStyle(
                  color: seleccionado ? color : Colors.grey,
                  fontWeight:
                      seleccionado ? FontWeight.bold : FontWeight.normal,
                  fontSize: 10)),
          // AQUÍ EL CAMBIO: Sin llaves y con una coma al final
          if (seleccionado) Container(height: 2, width: 40, color: color),
        ],
      ),
    );
  }

  Widget _buildListaDeDatos() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection(coleccionActual).snapshots(),
      builder: (context, snapshot) {
        // CORRECCIÓN LÍNEA 74-77: Agregamos llaves a los IF
        if (snapshot.hasError) {
          return const Center(child: Text("Error al cargar datos"));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text("No hay registros en $coleccionActual"));
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(10),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;
            String estado = data['estado'] ?? 'pendiente';

            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _colorEstado(estado),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text("${data['tipo'] ?? 'AVISO'}".toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    "Vecino: ${data['nombre'] ?? 'Sin nombre'}\nEstado: ${estado.toUpperCase()}"),
                trailing:
                    const Icon(Icons.touch_app, color: Colors.grey, size: 18),
                onTap: () => _cambiarEstadoDialog(docId),
              ),
            );
          },
        );
      },
    );
  }

  void _cambiarEstadoDialog(String id) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("GESTIONAR REGISTRO",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text("Marcar como FINALIZADO"),
                onTap: () {
                  FirebaseFirestore.instance
                      .collection(coleccionActual)
                      .doc(id)
                      .update({'estado': 'finalizado'});
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.orange),
                title: const Text("Poner en PENDIENTE"),
                onTap: () {
                  FirebaseFirestore.instance
                      .collection(coleccionActual)
                      .doc(id)
                      .update({'estado': 'pendiente'});
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _colorEstado(String est) {
    if (est == 'finalizado') {
      return Colors.green;
    } else if (est == 'pendiente') {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
