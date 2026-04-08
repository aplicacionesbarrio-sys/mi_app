import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SeguridadPage extends StatefulWidget {
  const SeguridadPage({super.key});

  @override
  State<SeguridadPage> createState() => _SeguridadPageState();
}

class _SeguridadPageState extends State<SeguridadPage>
    with WidgetsBindingObserver {
  // Definimos el stream como una variable para evitar que se reconstruya innecesariamente
  late Stream<QuerySnapshot> _alertasStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _inicializarStream();
  }

  void _inicializarStream() {
    // Solo alertas de las últimas 4 horas
    DateTime limite4Horas = DateTime.now().subtract(const Duration(hours: 4));

    _alertasStream = FirebaseFirestore.instance
        .collection('alertas')
        .where('estado', isEqualTo: 'activa')
        .where('fecha', isGreaterThan: limite4Horas)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  // 📞 FUNCIÓN LLAMAR
  Future<void> llamar(String celular) async {
    if (celular.isEmpty) return;
    final Uri tel = Uri.parse("tel:$celular");
    try {
      if (await canLaunchUrl(tel)) {
        await launchUrl(tel);
      }
    } catch (e) {
      debugPrint("Error al llamar: $e");
    }
  }

  // 🗺️ FUNCIÓN NAVEGAR
  Future<void> abrirMapa(double lat, double lng) async {
    final Uri uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback a web si falla el esquema de app nativa
        final Uri httpsUri = Uri.parse(
            "https://www.google.com/maps/search/?api=1&query=$lat,$lng");
        await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error al abrir mapa: $e");
    }
  }

  // ✅ FUNCIÓN PARA FINALIZAR ALERTA
  Future<void> finalizarAlerta(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('alertas').doc(docId).update({
        'estado': 'resuelto',
        'fecha_resolucion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error al cerrar alerta: $e"),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  String obtenerImagenAlerta(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'robo':
        return 'assets/icons/robo.png';
      case 'incendio':
        return 'assets/icons/incendio.png';
      case 'ambulancia':
        return 'assets/icons/ambulancia.png';
      case 'siniestro':
        return 'assets/icons/siniestro.png';
      case 'sospechoso':
        return 'assets/icons/sospechoso.png';
      default:
        return 'assets/icons/logo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB71C1C),
      appBar: AppBar(
        title: const Text("MONITOR DE EMERGENCIAS",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18)),
        backgroundColor: Colors.red[900],
        centerTitle: true,
        elevation: 10,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _alertasStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text("Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.white)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("SIN ALERTAS ACTIVAS",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              Map<String, dynamic> alerta = doc.data() as Map<String, dynamic>;

              String tipo = alerta['tipo'] ?? 'Alerta';
              String nombre = alerta['nombre_vecino'] ?? 'Vecino';
              String celular = alerta['numerodecelular'] ?? '';
              String barrio = alerta['barrio_vecino'] ?? 'Barrio...';

              // Blindaje de ubicación
              GeoPoint? pos =
                  alerta['ubicacion'] is GeoPoint ? alerta['ubicacion'] : null;

              String fechaHoraStr = "";
              if (alerta['fecha'] != null) {
                DateTime f = (alerta['fecha'] as Timestamp).toDate();
                fechaHoraStr = DateFormat('HH:mm - dd/MM/yyyy').format(f);
              }

              return Card(
                color: Colors.black.withOpacity(0.5),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white24, width: 2)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Image.asset(obtenerImagenAlerta(tipo),
                              height: 70,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.warning,
                                      color: Colors.white, size: 50)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tipo.toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                Text(nombre,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 18)),
                                Text("$barrio • $fechaHoraStr",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor:
                                Colors.greenAccent.withOpacity(0.2),
                            child: IconButton(
                              icon: const Icon(Icons.phone,
                                  color: Colors.greenAccent),
                              onPressed: () => llamar(celular),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 25),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[800],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              onPressed: pos != null
                                  ? () => abrirMapa(pos.latitude, pos.longitude)
                                  : null,
                              icon: const Icon(Icons.navigation, size: 18),
                              label: const Text("MAPA"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[800],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              onPressed: () =>
                                  _confirmarResolucion(context, doc.id, nombre),
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text("RESUELTO"),
                            ),
                          ),
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

  void _confirmarResolucion(BuildContext context, String docId, String vecino) {
    showDialog(
      context: context,
      barrierDismissible: false, // Obliga a elegir una opción
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Finalizar Alerta?",
            style: TextStyle(color: Colors.white)),
        content: Text("¿Confirmas que la emergencia de $vecino fue atendida?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              finalizarAlerta(docId);
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
            },
            child: const Text("SÍ, FINALIZAR",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
