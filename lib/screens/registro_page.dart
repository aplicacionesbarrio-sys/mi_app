import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:math';
import 'validacion_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      return androidInfo.model + androidInfo.fingerprint;
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
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _domicilioController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    super.dispose();
  }

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
                    // 1. Validaciones de UI
                    if (barrioSeleccionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Seleccioná un barrio")),
                      );
                      return;
                    }
                    if (_dniController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Ingresá tu DNI")),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    final String dniIngresado = _dniController.text.trim();

                    // --- GENERAR CÓDIGO DE 6 DÍGITOS ---
                    String nuevoCodigo =
                        (Random().nextInt(900000) + 100000).toString();

                    try {
                      // --- ESCUDO: VERIFICAR SI EL DNI YA EXISTE ---
                      final docExistente = await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(dniIngresado)
                          .get();

                      if (docExistente.exists) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('❌ Este DNI ya está registrado.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      String idReal = await _obtenerIdReal();
                      DateTime hoy = DateTime.now();

                      // 2. Guardar en Firebase
                      await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(dniIngresado)
                          .set({
                        'nombre': _nombreController.text.trim(),
                        'dni': dniIngresado,
                        'domicilio': _domicilioController.text.trim(),
                        'email': _emailController.text.trim(),
                        'numerodecelular': _celularController.text.trim(),
                        'barrio': barrioSeleccionado,
                        'fechaRegistro': hoy,
                        'rol': dniIngresado == '27901290' ? 1 : 3,
                        'estado': 'pendiente',
                        'codigoActivacion': nuevoCodigo,
                        'deviceId': idReal,
                      });

                      // 3. Persistencia local UNIFICADA (SharedPreferences)
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                          'nombre', _nombreController.text.trim());
                      await prefs.setString(
                          'numerodecelular', _celularController.text.trim());
                      await prefs.setString(
                          'domicilio', _domicilioController.text.trim());
                      await prefs.setString('barrio', barrioSeleccionado ?? "");
                      await prefs.setString('dni_usuario', dniIngresado);
                      await prefs.setString('estado_usuario', 'pendiente');
                      await prefs.setString('codigoGenerado', nuevoCodigo);

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('✅ Registro enviado exitosamente.'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // 4. Limpieza de controladores
                      _nombreController.clear();
                      _dniController.clear();
                      _domicilioController.clear();
                      _emailController.clear();
                      _celularController.clear();

                      if (mounted) {
                        setState(() {
                          barrioSeleccionado = null;
                        });

                        // 5. Navegación con delay
                        await Future.delayed(const Duration(seconds: 2));
                        if (!mounted) return;
                        // 5. Navegación con delay
                        await Future.delayed(const Duration(seconds: 2));

                        // Esta es la forma que Flutter acepta sin protestar:
                        if (!context.mounted) return;

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const ValidacionPage(),
                          ),
                        );
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
