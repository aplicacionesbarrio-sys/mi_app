import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

final List<String> barriosRioja = ["Los Caudillos", "Centro"];

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  // Función para obtener el ID real del teléfono (Pegala acá)
  Future<String> _obtenerIdReal() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // El ID único de Android
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "desconocido_ios";
    }
    return "desconocido";
  }

  // Controladores para capturar lo que escribe el vecino
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _domicilioController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  Future<void> cargarTodosLosBarrios() async {
    final coleccion = FirebaseFirestore.instance.collection('barrios');

    // Lista prolija con los nombres que querés
    List<String> misBarrios = ["Centro", "Los Caudillos"];

    for (String nombre in misBarrios) {
      await coleccion.doc(nombre).set({
        'nombre': nombre,
        'activo': true,
        'radioMetros': 100,
      });
    }
  }

  final _formKey = GlobalKey<FormState>();
  String? barrioSeleccionado;
  // Controladores para los otros datos

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Vecino")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // <--- Este es el "mago" que quita la línea amarilla
            child: Column(
              children: [
                // 1. NOMBRE
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                      labelText: "Nombre y Apellido",
                      prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 15),

                // 2. DNI
                TextFormField(
                  controller: _dniController,
                  decoration: const InputDecoration(
                      labelText: "DNI (Opcional)",
                      prefixIcon: Icon(Icons.badge)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),

                // 3. DOMICILIO
                TextFormField(
                  controller: _domicilioController,
                  decoration: const InputDecoration(
                      labelText: "Domicilio", prefixIcon: Icon(Icons.home)),
                ),
                const SizedBox(height: 15),

                // 4. EMAIL
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: "Email", prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                // 5. CELULAR
                TextFormField(
                  controller: _celularController,
                  decoration: const InputDecoration(
                      labelText: "Número de Celular",
                      prefixIcon: Icon(Icons.phone_android)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // --- SELECTOR DE BARRIOS ---
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('barrios')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return DropdownButtonFormField<String>(
                      value: barrioSeleccionado,
                      hint: const Text("Seleccioná tu Barrio"),
                      items: snapshot.data!.docs.map((doc) {
                        return DropdownMenuItem(
                          value: doc['nombre'] as String,
                          child: Text(doc['nombre']),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => barrioSeleccionado = val),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // BOTÓN FINAL ACTUALIZADO
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      // 1. Buscamos el ID real del celu
                      String idReal = await _obtenerIdReal();

                      DateTime hoy = DateTime.now();
                      DateTime vencimiento =
                          DateTime(hoy.year, hoy.month, hoy.day + 30, 23, 59);

                      // 2. Guardamos todo en Firebase
                      await FirebaseFirestore.instance
                          .collection('usuarios')
                          .add({
                        'nombre': _nombreController.text,
                        'dni': _dniController.text,
                        'domicilio': _domicilioController.text,
                        'email': _emailController.text,
                        'celular': _celularController.text,
                        'barrio': barrioSeleccionado,
                        'fechaRegistro': hoy,
                        'rol': 3,
                        'aprobado': false,
                        'suscripcionActiva': true,
                        'fechaVencimiento': vencimiento,
                        'deviceId': idReal,
                      });

                      messenger.showSnackBar(
                        const SnackBar(
                          content:
                              Text('✅ Registro enviado. Aguarde aprobación.'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // 3. Limpiamos los campos
                      _nombreController.clear();
                      _dniController.clear();
                      _domicilioController.clear();
                      _emailController.clear();
                      _celularController.clear();
                    } catch (e) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('❌ Error al guardar datos'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Finalizar Registro"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
