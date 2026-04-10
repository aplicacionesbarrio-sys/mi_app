// ignore_for_file: avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'screens/registro_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'screens/inicio_page.dart';
import 'screens/seguridad_page.dart';
import 'screens/admin_servicios_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'screens/panel_reclamos.dart';
import 'screens/validacion_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await pedirPermisos();
  } catch (e) {
    debugPrint("❌ Error crítico en inicialización: $e");
  }

  runApp(const MyApp());
}

Future<Widget> verificarUsuario() async {
  final prefs = await SharedPreferences.getInstance();
  // bool pendiente = prefs.getBool('registro_pendiente') ?? false;
  //if (pendiente) return const ValidacionPage();
  // 1. Intentamos obtener el ID del dispositivo
  String idCelu = "";
  try {
    var build = await DeviceInfoPlugin().androidInfo;
// CAMBIAMOS build.id por una combinación más segura:
    idCelu = build.model + build.fingerprint;
  } catch (e) {
    debugPrint("❌ Error obteniendo Device ID: $e");
    return const RegistroPage();
  }

  // 2. Auth Anónima silenciosa
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint("❌ Auth Error: $e");
  }

  // 3. Consultamos Firestore (Solo una vez para verificar estado y rol)
  try {
    var usuarioQuery = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('deviceId', isEqualTo: idCelu)
        .limit(1) // Optimización de consulta
        .get();

    if (usuarioQuery.docs.isNotEmpty) {
      var datos = usuarioQuery.docs.first.data();

      // Guardamos DNI para futuras consultas sin repetir este proceso
      await prefs.setString('dni_usuario', usuarioQuery.docs.first.id);

      // --- Lógica de Validación ---
      String estado = datos['estado'] ?? 'pendiente';
      if (estado == 'pendiente') {
        return const ValidacionPage();
      }

      // --- Lógica de Roles y Caché ---
      int rol = datos['rol'] ?? 3;
      await prefs.setString('nombre', datos['nombre'] ?? "Vecino");
      await prefs.setString('barrio', datos['barrio'] ?? "Sin barrio");
      await prefs.setInt('rol_usuario', rol);

      // Redirección según rol
      switch (rol) {
        case 2:
          return const AdminServiciosPage();
        case 4:
          return const SeguridadPage();
        case 5:
          return const PanelReclamos();
        default:
          return const InicioPage();
      }
    } else {
      return const RegistroPage();
    }
  } catch (e) {
    debugPrint("❌ Error en flujo de verificación: $e");
    return const RegistroPage();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Barrio Seguro',
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
          elevation: 0,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 187, 233, 246),
      ),
      home: FutureBuilder<Widget>(
        future: verificarUsuario(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          return snapshot.data ?? const RegistroPage();
        },
      ),
    );
  }
}

// Una pantalla de carga con más estilo
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: const Color.fromARGB(255, 187, 233, 246),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 20),
            Text("Iniciando Barrio Seguro...",
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}

Future<void> pedirPermisos() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
}
