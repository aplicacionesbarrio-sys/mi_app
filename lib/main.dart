import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'screens/registro_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'screens/inicio_page.dart';
import 'screens/seguridad_page.dart'; // <--- IMPORTANTE: Nueva página
import 'screens/admin_servicios_page.dart'; // <--- IMPORTANTE: Nueva página
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await pedirPermisos();
  runApp(const MyApp());
}

Future<Widget> verificarUsuario() async {
  // 1. Obtenemos el ID único del celular
  var build = await DeviceInfoPlugin().androidInfo;
  String idCelu = build.id;

  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint("✅ Auth: Sesión anónima iniciada: $idCelu");
    }
  } catch (e) {
    debugPrint("❌ Auth: Error: $e");
  }

  // 2. Buscamos en la colección 'usuarios'
  var usuarioQuery = await FirebaseFirestore.instance
      .collection('usuarios')
      .where('deviceId', isEqualTo: idCelu)
      .get();

  // 3. Decidimos a qué pantalla ir según el ROL
  if (usuarioQuery.docs.isNotEmpty) {
    var doc = usuarioQuery.docs.first;
    var datos = doc.data();

    // Extraemos el rol (si no existe, por defecto es 3)
    int rol = datos['rol'] ?? 3;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', datos['nombre'] ?? "Vecino");
    await prefs.setString(
        'numerodecelular', datos['numerodecelular'] ?? "Sin número");

    debugPrint("🛡️ ACCESO: Usuario reconocido con ROL: $rol");

    // 🚀 Lógica de redirección profesional
    if (rol == 2) {
      debugPrint("🛰️ Entrando como Admin de Servicios");
      return const AdminServiciosPage();
    } else if (rol == 4) {
      debugPrint("🚨 Entrando como Seguridad");
      return const SeguridadPage();
    } else {
      debugPrint("🏠 Entrando como Vecino");
      return const InicioPage();
    }
  } else {
    debugPrint("⚠️ Vecino nuevo, enviando a Registro.");
    return const RegistroPage();
  }
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
      home: FutureBuilder<Widget>(
        future: verificarUsuario(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data ?? const RegistroPage();
        },
      ),
    );
  }
}

Future<void> pedirPermisos() async {
  LocationPermission permission = await Geolocator.requestPermission();
}
