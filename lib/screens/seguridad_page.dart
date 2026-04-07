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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable(); // Mantiene la pantalla encendida para el guardia
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
    if (await canLaunchUrl(tel)) {
      await launchUrl(tel);
    }
  }

  // 🗺️ FUNCIÓN NAVEGAR
  Future<void> abrirMapa(double lat, double lng) async {
    final Uri uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ✅ FUNCIÓN PARA FINALIZAR ALERTA (Cambia estado a 'resuelto')
  Future<void> finalizarAlerta(String docId) async {
    await FirebaseFirestore.instance.collection('alertas').doc(docId).update({
      'estado':
          'resuelto', // Al cambiar de 'activa' a 'resuelto', desaparece de la lista
      'fecha_resolucion': FieldValue.serverTimestamp(),
    });
  }

  // 🖼️ SELECCIÓN DE IMAGEN SEGÚN TIPO
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
    // Filtro de seguridad: solo mostrar alertas de las últimas 4 horas
    DateTime limite4Horas = DateTime.now().subtract(const Duration(hours: 4));

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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alertas')
            .where('estado', isEqualTo: 'activa')
            .where('fecha', isGreaterThan: limite4Horas)
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("SIN ALERTAS ACTIVAS",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
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
              GeoPoint pos = alerta['ubicacion'];

              // 🕒 Formatear FECHA Y HORA (Ej: 13:19 - 06/04/2026)
              String fechaHoraStr = "";
              if (alerta['fecha'] != null) {
                DateTime f = (alerta['fecha'] as Timestamp).toDate();
                fechaHoraStr = DateFormat('HH:mm - dd/MM/yyyy').format(f);
              }

              return Card(
                color: Colors.black.withOpacity(0.4),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white24)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Image.asset(obtenerImagenAlerta(tipo), height: 70),
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
                          IconButton(
                            icon: const Icon(Icons.phone,
                                color: Colors.greenAccent, size: 30),
                            onPressed: () => llamar(celular),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[900],
                                  foregroundColor: Colors.white),
                              onPressed: () =>
                                  abrirMapa(pos.latitude, pos.longitude),
                              icon: const Icon(Icons.navigation, size: 18),
                              label: const Text("MAPA"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // ✅ BOTÓN RESUELTO
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[800],
                                  foregroundColor: Colors.white),
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

  // 🛑 DIÁLOGO DE CONFIRMACIÓN
  void _confirmarResolucion(BuildContext context, String docId, String vecino) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("¿Finalizar Alerta?",
            style: TextStyle(color: Colors.white)),
        content: Text("¿Confirmas que la emergencia de $vecino fue atendida?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("NO")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              finalizarAlerta(docId);
              Navigator.pop(context);
              HapticFeedback.lightImpact(); // Pequeña vibración de éxito
            },
            child: const Text("SÍ, RESUELTO",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
