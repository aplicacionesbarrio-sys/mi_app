// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inicio_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ValidacionPage extends StatefulWidget {
  const ValidacionPage({super.key});

  @override
  State<ValidacionPage> createState() => _ValidacionPageState();
}

class _ValidacionPageState extends State<ValidacionPage> {
  final TextEditingController _codigoController = TextEditingController();
  bool _cargando = false;

  Future<void> _verificarCodigo() async {
    String codigo = _codigoController.text.trim();
    if (codigo.length < 6) {
      _mostrarSnackBar("El código debe tener 6 dígitos", isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? dniRecuperado = prefs.getString('dni_usuario');

      if (dniRecuperado == null) {
        _mostrarSnackBar("No se encontró el DNI. Registrate de nuevo.",
            isError: true);
        setState(() => _cargando = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(dniRecuperado)
          .get();

      if (doc.exists && doc.data()?['codigoActivacion'] == codigo) {
        await doc.reference.update({
          'estado': 'validado',
          'codigoValidado': true,
        });

        await prefs.setBool('codigoValidado', true);
        await prefs.setString('estado_usuario', 'validado');

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const InicioPage()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        _mostrarSnackBar("Código incorrecto. Verificá y reintentá.",
            isError: true);
      }
    } catch (e) {
      _mostrarSnackBar("Error de conexión. Intentá de nuevo.");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarSnackBar(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), // El celeste de fondo de tu app
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_outlined,
                    size: 80, color: Color(0xFF007BFF)),
                const SizedBox(height: 20),
                const Text(
                  "VALIDACIÓN",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007BFF)), // Azul de tu AppBar
                ),
                const SizedBox(height: 10),
                const Text(
                  "Ingresá el código de 6 dígitos enviado por el administrador.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 40),

                // --- AQUÍ PEGAMOS TU NUEVO DISEÑO ---
                TextField(
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 42,
                      letterSpacing: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF007BFF)),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "000000",
                    hintStyle: TextStyle(
                        color: Colors.grey.withOpacity(0.3), letterSpacing: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                          color: Color(0xFF00BFFF), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          const BorderSide(color: Color(0xFF007BFF), width: 3),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                    ),
                    onPressed: _cargando ? null : _verificarCodigo,
                    child: _cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "ACTIVAR MI CUENTA",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
                // --- FIN DEL NUEVO DISEÑO ---

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Volver al registro",
                      style: TextStyle(color: Color(0xFF007BFF))),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
