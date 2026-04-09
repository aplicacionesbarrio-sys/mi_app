import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
      // AHORA ES INTELIGENTE: Si es usuarios, busca 'fechaRegistro', si no, busca 'fecha'
      stream: (coleccionActual == 'usuarios_pagos')
          ? FirebaseFirestore.instance
              .collection('usuarios')
              .where('rol', isEqualTo: 3)
              .snapshots()
          : FirebaseFirestore.instance
              .collection(coleccionActual)
              .orderBy(
                  coleccionActual == 'usuarios' ? 'fechaRegistro' : 'fecha',
                  descending: true)
              .snapshots(),
      builder: (context, snapshot) {
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

// 1. Usamos 'nombre_vecino' que es el que aparece en tu captura
                      _itemInfo(Icons.person_pin,
                          "${data['nombre_vecino'] ?? data['nombre'] ?? 'Vecino anónimo'}",
                          isBold: true),

// 2. Usamos 'barrio_vecino' según tu captura
                      _itemInfo(Icons.map,
                          "Barrio: ${data['barrio_vecino'] ?? data['barrio'] ?? 'No especificado'}"),

// 3. 'domicilio' parece estar bien, pero añadimos respaldo por si acaso
                      _itemInfo(Icons.home_work,
                          "Dom: ${data['domicilio'] ?? 'No especificado'}"),

// 4. 'numerodecelular' coincide, pero dejamos respaldo con 'telefono'
                      _itemInfo(Icons.phone_android,
                          "Tel: ${data['numerodecelular'] ?? data['telefono'] ?? 'Sin número'}"),

                      _itemInfo(Icons.event_note, "Recibido: $fechaFormateada"),
                      const SizedBox(height: 15),
                      _botonGestionar(docId, data['estado'], data),
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

  Widget _botonGestionar(
      String docId, String estadoActual, Map<String, dynamic> datos) {
    bool esUsuario = coleccionActual == 'usuarios';
    String telefono = datos['numerodecelular'] ?? '';

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => esUsuario
              ? _mostrarFabricaCodigo(docId, telefono)
              : _cambiarEstadoDialog(docId),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                esUsuario ? Colors.purple : const Color(0xFF4F1E98),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 45),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(esUsuario ? Icons.vpn_key : Icons.settings_suggest,
              size: 20),
          label: Text(esUsuario ? "GENERAR CÓDIGO" : "GESTIONAR ESTADO"),
        ),
        if (esUsuario) ...[
          // --- ESTE ES EL BOTÓN NUEVO ---

          const SizedBox(height: 10), // Un espacio entre los dos botones

          // --- ESTE ES TU BOTÓN DE WHATSAPP QUE YA TENÍAS (No se toca) ---
          ElevatedButton.icon(
            onPressed: () => _lanzarWhatsApp(telefono),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.chat, size: 20),
            label: const Text("WHATSAPP"),
          ),
        ],
      ],
    );
  }

  void _mostrarControlPago(String docId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("GESTIONAR PAGO",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 79, 30, 152))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📅 PLANES DE ACCESO",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _botonPlan(dialogContext, docId, "30 D", 30),
                  _botonPlan(dialogContext, docId, "60 D", 60),
                  _botonPlan(dialogContext, docId, "90 D", 90),
                ],
              ),
              const SizedBox(height: 20),
              const Text("💬 RECORDATORIOS WSP",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Divider(),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _botonWhatsApp(docId, "5 DÍAS"),
                  _botonWhatsApp(docId, "3 DÍAS"),
                  _botonWhatsApp(docId, "HOY"),
                ],
              ),
              const SizedBox(height: 20),
              const Text("🛡️ SEGURIDAD",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Divider(),
              _botonBloqueo(docId),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CERRAR"),
          ),
        ],
      ),
    );
  }

  void _lanzarWhatsApp(String telefono) {
    // Esta función es la que hace que el botón verde no de error
    debugPrint("Abriendo chat para: $telefono");
  }

  Widget _itemInfo(IconData icono, String texto,
      {bool isBold = false, Color? colorTexto}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icono,
              size: 18, color: const Color(0xFF4F1E98).withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 14,
                color: colorTexto ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
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
              _opcionEstado(
                  id, "finalizado", Icons.check_circle, Colors.green, "PAGÓ"),
              _opcionEstado(id, "pendiente", Icons.pending_actions,
                  Colors.orange, "PENDIENTE"),
              _opcionEstado(
                  id, "cancelado", Icons.cancel, Colors.red, "NO PAGÓ"),
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

  void _mostrarFabricaCodigo(String docId, String telefonoVecino) {
    // Generamos un código aleatorio de 6 dígitos basado en el tiempo actual
    final String nuevoCodigo = (100000 + (DateTime.now().millisecond * 899))
        .toString()
        .substring(0, 6);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("FABRICAR CÓDIGO",
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Se enviará este código de activación al vecino para que pueda ingresar:"),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                nuevoCodigo,
                style: const TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.purple),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Para que no ocupe toda la pantalla
              children: [
                // BOTÓN 1: GUARDAR
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(docId)
                          .update({
                        'codigoActivacion': nuevoCodigo,
                        'estado': 'activado'
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ Código guardado en Firebase"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Quitamos el Navigator.pop para que NO se cierre
                      }
                    },
                    child: const Text("1. GUARDAR EN FIREBASE",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),

                // BOTÓN 2: WHATSAPP
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.message, color: Colors.white),
                    label: const Text("2. ENVIAR POR WHATSAPP",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      String numLimpio =
                          telefonoVecino.replaceAll(RegExp(r'[^0-9]'), '');
                      final url =
                          "https://wa.me/549$numLimpio?text=${Uri.encodeComponent('Hola! Tu código de activación para Barrio Seguro es: $nuevoCodigo')}";

                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),

                // BOTÓN 3: SALIR
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("TERMINAR Y CERRAR",
                      style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonPlan(
      BuildContext context, String docId, String etiqueta, int dias) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 79, 30, 152),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      onPressed: () async {
        final nav = Navigator.of(context);

        // 1. Calculamos la fecha de hoy y la de vencimiento
        final ahora = DateTime.now();
        final fechaVencimiento = ahora.add(Duration(days: dias));

        try {
          // 2. Actualizamos Firebase con más información útil
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(docId)
              .update({
            'estadoPago': 'al_dia',
            'fechaVencimiento':
                fechaVencimiento, // Clave para el bloqueo automático
            'fechaUltimoPago': ahora, // Para saber cuándo te pagó
            'planContratado': dias, // Para saber si compró 30, 60 o 90
            'accesoPermitido':
                true, // Le devolvemos el acceso si estaba bloqueado
          });

          // 3. Cerramos el diálogo y avisamos que salió bien
          nav.pop();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("✅ Plan de $dias días activado con éxito"),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Si algo falla (ej: sin internet), avisamos
          print("Error al actualizar pago: $e");
        }
      },
      child: Text(etiqueta,
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }

  Widget _botonWhatsApp(String docId, String dias) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: () async {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(docId)
            .get();
        if (doc.exists) {
          String telefono = doc.data()?['telefono'] ?? "";
          String nombre = doc.data()?['nombre'] ??
              "Vecino"; // Borramos la línea de 'nombre' y el comentario
          if (telefono.isNotEmpty) {
            _abrirWhatsApp(telefono,
                "Hola $nombre, te recordamos del Barrio que tu plan de acceso vence en $dias. Por favor, realizá tu pago para evitar inconvenientes.");
          }
        }
      },
      icon: const Icon(Icons.message, size: 16, color: Colors.white),
      label: Text("AVISO $dias",
          style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Widget _botonBloqueo(String docId) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: () async {
        // Aquí podrías cambiar el estado a 'bloqueado' o similar
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(docId)
            .update({
          'estadoPago': 'vencido',
          'accesoPermitido': false, // Si tenés este campo en tu BD
        });
      },
      icon: const Icon(Icons.block, size: 16, color: Colors.white),
      label: const Text("BLOQUEAR ACCESO",
          style: TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Future<void> _abrirWhatsApp(String telefono, String mensaje) async {
    // Limpiamos el número por si tiene espacios o guiones
    final numeroLimpio = telefono.replaceAll(RegExp(r'[^\d]'), '');
    final url =
        "https://wa.me/$numeroLimpio?text=${Uri.encodeComponent(mensaje)}";

    // Intentamos lanzar la URL
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {}
  }
}
