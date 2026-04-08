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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 2,
        title: const Text("PANEL DE CONTROL",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1)),
        backgroundColor: const Color(0xFF4F1E98),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _botonFiltro(
              "RECLAMOS", "reclamos", Icons.assignment_late, Colors.blue),
          _botonFiltro("ALERTAS", "alertas", Icons.campaign, Colors.red),
          _botonFiltro("SERVICIOS", "servicios", Icons.handyman, Colors.green),
        ],
      ),
    );
  }

  Widget _botonFiltro(
      String texto, String coleccion, IconData icono, Color color) {
    bool seleccionado = coleccionActual == coleccion;
    return GestureDetector(
      onTap: () => setState(() => coleccionActual = coleccion),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icono,
                color: seleccionado ? color : Colors.grey[400], size: 28),
            const SizedBox(height: 4),
            Text(texto,
                style: TextStyle(
                    color: seleccionado ? color : Colors.grey[600],
                    fontWeight:
                        seleccionado ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildListaDeDatos() {
    return StreamBuilder<QuerySnapshot>(
      // ORDENAMOS POR FECHA DESCENDENTE (Lo más nuevo arriba)
      stream: FirebaseFirestore.instance
          .collection(coleccionActual)
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text("Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F1E98)));
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text("No hay registros en $coleccionActual",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16)),
              ],
            ),
          );
        }

        var docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;
            String estado = data['estado'] ?? 'pendiente';

            DateTime dt = (data['fecha'] is Timestamp)
                ? (data['fecha'] as Timestamp).toDate()
                : DateTime.now();

            String fechaFormateada =
                "${dt.day}/${dt.month} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}hs";

            return Card(
              elevation: 4,
              shadowColor: Colors.black26,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                        left:
                            BorderSide(color: _colorEstado(estado), width: 6)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${data['tipo'] ?? 'AVISO GENERAL'}"
                                  .toUpperCase(),
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _colorEstado(estado),
                                  fontSize: 16),
                            ),
                          ),
                          _badgeEstado(estado),
                        ],
                      ),
                      const Divider(height: 20),
                      _itemInfo(Icons.person_pin,
                          "${data['nombre'] ?? 'Vecino anónimo'}",
                          isBold: true),
                      _itemInfo(Icons.map,
                          "Barrio: ${data['barrio'] ?? 'No especificado'}"),
                      _itemInfo(Icons.home_work,
                          "Dom: ${data['domicilio'] ?? 'No especificado'}"),
                      _itemInfo(Icons.phone_android,
                          "Tel: ${data['numerodecelular'] ?? '---'}"),
                      _itemInfo(Icons.event_note, "Recibido: $fechaFormateada"),
                      const SizedBox(height: 15),
                      _botonGestionar(docId, estado),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _colorEstado(estado),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(estado.toUpperCase(),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
    );
  }

  Widget _botonGestionar(String docId, String estadoActual) {
    return ElevatedButton(
      onPressed: () => _cambiarEstadoDialog(docId),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F1E98),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_suggest, size: 20),
          SizedBox(width: 10),
          Text("GESTIONAR ESTADO",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _itemInfo(IconData icono, String texto, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icono,
              size: 18, color: const Color(0xFF4F1E98).withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(texto,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight:
                          isBold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  void _cambiarEstadoDialog(String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
              const Text("ACTUALIZAR ESTADO",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 10),
              _opcionEstado(id, "finalizado", Icons.check_circle, Colors.green,
                  "Marcar como Finalizado"),
              _opcionEstado(id, "pendiente", Icons.pending_actions,
                  Colors.orange, "Volver a Pendiente"),
              _opcionEstado(id, "cancelado", Icons.cancel, Colors.red,
                  "Cancelar / Rechazar"),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _opcionEstado(
      String id, String estado, IconData icono, Color color, String titulo) {
    return ListTile(
      leading: Icon(icono, color: color, size: 30),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        FirebaseFirestore.instance
            .collection(coleccionActual)
            .doc(id)
            .update({'estado': estado});
        Navigator.pop(context);
      },
    );
  }

  Color _colorEstado(String est) {
    switch (est.toLowerCase()) {
      case 'finalizado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}
