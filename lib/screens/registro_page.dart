import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'validacion_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin/admin_home.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  // Función para obtener el ID real del teléfono
  Future<String> _obtenerIdReal() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "desconocido_ios";
    }
    return "desconocido";
  }

  // Controladores
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _domicilioController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? barrioSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Vecino")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                      labelText: "Nombre y Apellido",
                      prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _dniController,
                  decoration: const InputDecoration(
                      labelText: "DNI (Opcional)",
                      prefixIcon: Icon(Icons.badge)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _domicilioController,
                  decoration: const InputDecoration(
                      labelText: "Domicilio", prefixIcon: Icon(Icons.home)),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: "Email", prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _celularController,
                  decoration: const InputDecoration(
                      labelText: "Número de Celular",
                      prefixIcon: Icon(Icons.phone_android)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // SELECTOR DE BARRIOS DESDE FIREBASE
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

                ElevatedButton(
                  onPressed: () async {
                    // 1. Validación inicial
                    if (barrioSeleccionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Por favor seleccioná un barrio")),
                      );
                      return;
                    }
                    if (_domicilioController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Por favor ingresá tu dirección")),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);

                    // 2. Persistencia local (SharedPreferences)
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                        'nombre', _nombreController.text.trim());
                    await prefs.setString(
                        'numerodecelular', _celularController.text.trim());
                    await prefs.setString(
                        'domicilio', _domicilioController.text.trim());
                    await prefs.setString('barrio', barrioSeleccionado ?? "");

                    debugPrint(
                        "✅ Memoria local actualizada: ${_nombreController.text}");

                    try {
                      String idReal = await _obtenerIdReal();
                      DateTime hoy = DateTime.now();

                      // // 3. Envío a Firebase (Ahora usando el DNI como ID)
                      await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(_dniController.text
                              .trim()) // <-- Definimos que el ID sea el DNI
                          .set({
                        // <-- Usamos .set para guardar
                        'nombre': _nombreController.text.trim(),
                        'dni': _dniController.text.trim(),
                        'domicilio': _domicilioController.text.trim(),
                        'email': _emailController.text.trim(),
                        'numerodecelular': _celularController.text.trim(),
                        'barrio': barrioSeleccionado,
                        'fechaRegistro': hoy,
                        'rol': _dniController.text.trim() == '27901290' ? 1 : 3,
                        'estado': 'pendiente',
                        'codigoActivacion': '',
                        'deviceId': idReal,
                      });

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                              '✅ Registro enviado. Aguarde 48hs por su código.'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // 4. LIMPIEZA DE CUADROS DE TEXTO
                      _nombreController.clear();
                      _dniController.clear();
                      _domicilioController.clear();
                      _emailController.clear();
                      _celularController.clear();

                      setState(() {
                        barrioSeleccionado = null;
                      });

                      // 5. Navegación

                      await Future.delayed(const Duration(seconds: 2));

                      // Forma segura que no tira error en rojo:
                      if (context.mounted) {
                        if (_dniController.text.trim() == '27901290') {
                          // CAMINO ADMIN: Entra directo al tablero de 6 botones
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminHomePage(),
                            ),
                          );
                        } else {
                          // CAMINO VECINO: Mantiene tu flujo original de validación
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ValidacionPage(),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('❌ Error al enviar registro: $e'),
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
