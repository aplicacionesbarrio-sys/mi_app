import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TablerosAdmin extends StatefulWidget {
  final String categoriaInicial;

  const TablerosAdmin({super.key, this.categoriaInicial = 'reclamos'});

  @override
  State<TablerosAdmin> createState() => _TablerosAdminState();
}

class _TablerosAdminState extends State<TablerosAdmin> {
  late String coleccionActual;

  @override
  void initState() {
    super.initState();
    coleccionActual = widget.categoriaInicial;
  }

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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _botonFiltro("RECLAMOS", "reclamos", Icons.assignment, Colors.blue),
          _botonFiltro("ALERTAS", "alertas", Icons.warning, Colors.red),
          _botonFiltro("SERVICIOS", "servicios", Icons.build, Colors.green),
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
        if (snapshot.hasError) {
          return const Center(child: Text("Error al cargar datos"));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(10),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;
            String estado = data['estado'] ?? 'pendiente';

            // Formato de fecha corregido
            String fechaFormateada = "Sin fecha";
            if (data['fecha'] != null) {
              if (data['fecha'] is Timestamp) {
                DateTime dt = (data['fecha'] as Timestamp).toDate();
                fechaFormateada =
                    "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
              } else {
                fechaFormateada = data['fecha'].toString();
              }
            }

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${data['tipo'] ?? 'AVISO'}".toUpperCase(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _colorEstado(estado),
                                fontSize: 15),
                          ),
                        ),
                        _badgeEstado(estado),
                      ],
                    ),
                    const Divider(),
                    // USANDO LOS NOMBRES EXACTOS DE TU FIREBASE
                    _itemInfo(Icons.person,
                        "Vecino: ${data['nombre_vecino'] ?? data['nombre'] ?? 'No registrado'}"),
                    _itemInfo(Icons.location_on,
                        "Barrio: ${data['barrio_vecino'] ?? 'No especificado'}"),
                    _itemInfo(Icons.home,
                        "Domicilio: ${data['domicilio'] ?? 'No especificado'}"),
                    _itemInfo(Icons.phone,
                        "Celular: ${data['numerodecelular'] ?? 'Sin número'}"),
                    _itemInfo(
                        Icons.access_time, "Ficha/Hora: $fechaFormateada"),
                    const SizedBox(height: 15),
                    _botonGestionar(docId),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _badgeEstado(String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _colorEstado(estado).withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(estado.toUpperCase(),
          style: TextStyle(
              color: _colorEstado(estado),
              fontWeight: FontWeight.bold,
              fontSize: 10)),
    );
  }

  Widget _botonGestionar(String docId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _cambiarEstadoDialog(docId),
        icon: const Icon(Icons.edit, size: 18),
        label: const Text("GESTIONAR ESTADO"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 79, 30, 152),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _itemInfo(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icono, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
              child: Text(texto,
                  style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  void _cambiarEstadoDialog(String id) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
                padding: EdgeInsets.all(15),
                child: Text("GESTIONAR REGISTRO",
                    style: TextStyle(fontWeight: FontWeight.bold))),
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
        );
      },
    );
  }

  Color _colorEstado(String est) {
    if (est == 'finalizado') return Colors.green;
    if (est == 'pendiente') return Colors.orange;
    return Colors.red;
  }
}
