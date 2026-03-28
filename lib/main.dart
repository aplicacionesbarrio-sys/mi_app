import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'screens/inicio_page.dart';
import 'screens/registro_page.dart';

// Borramos los duplicados que estaban aquí
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 5,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),

      // Volvemos a la configuración simple: entra directo a tus botones
      home: const RegistroPage(),
    );
  }
}

// --- PANTALLA DE ACTIVACIÓN (BLOQUEO PROFESIONAL CON SCROLL) ---
class PantallaActivacion extends StatefulWidget {
  const PantallaActivacion({super.key});

  @override
  State<PantallaActivacion> createState() => _PantallaActivacionState();
}

class _PantallaActivacionState extends State<PantallaActivacion> {
  // 🔴 A) DECLARACIÓN DEL CONTROLLER (Para que Flutter sepa qué es _codigoController)
  final TextEditingController _codigoController = TextEditingController();

  // 🔴 B) FUNCIÓN DE VALIDACIÓN (Para que el botón sepa qué hacer)
  void validarCodigo() {
    // Por ahora usamos el código de prueba, luego lo conectamos a Firebase
    if (_codigoController.text == "123456") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InicioPage()),
      );
    } else {
      // Si el código es mal, avisamos al vecino
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Código incorrecto o vencido. Contacte al Administrador."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Evita que el teclado rompa el diseño
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          // <-- El Scroll que arregla el error amarillo
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // TÍTULO
                const Text(
                  "Bienvenido a\nBarrio Seguro",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 30),

                // LOGO
                Image.asset(
                  'assets/icons/logo.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) =>
                      const FlutterLogo(size: 100),
                ),

                const SizedBox(height: 40),

                const Text(
                  "Ingresá tu código de activación",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),

                // CAMPO DE TEXTO
                // CAMPO DE TEXTO CON NÚMEROS GRANDES Y CENTRADOS
                TextField(
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center, // Centra el texto

                  // AQUÍ ESTÁ EL CAMBIO DE TAMAÑO:
                  style: const TextStyle(
                    fontSize: 32, // Tamaño bien grande
                    fontWeight: FontWeight.bold, // En negrita
                    letterSpacing:
                        8, // Espacio entre números para que no se peguen
                    color: Colors.blue, // Color azul para que combine
                  ),

                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "000000", // Guía visual para el vecino
                    hintStyle: TextStyle(color: Colors.grey, letterSpacing: 8),
                    labelText: 'Código de Activación',
                    floatingLabelBehavior: FloatingLabelBehavior
                        .always, // Mantiene la etiqueta arriba
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 25),

                // BOTÓN DE ACTIVACIÓN
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: validarCodigo, // Ya declarada arriba
                    child: const Text(
                      "ACTIVAR AHORA",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 30), // Espacio extra para el teclado
              ],
            ),
          ),
        ),
      ),
    );
  }
}
