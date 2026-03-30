import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'screens/registro_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'screens/inicio_page.dart'; // Importante para poder saltar a las alertas

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

Future<Widget> verificarUsuario() async {
  // 1. Obtenemos el ID único del celular
  var build = await DeviceInfoPlugin().androidInfo;
  String idCelu = build.id;

  // 🔥 PASO NUEVO: Activamos la sesión oficial de Firebase
  // Esto hace que FirebaseAuth.instance.currentUser DEJE DE SER NULL
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint(
          "✅ Auth: Sesión anónima iniciada para el dispositivo: $idCelu");
    }
  } catch (e) {
    debugPrint("❌ Auth: Error al conectar con Firebase Auth: $e");
  }

  // 2. Buscamos en la colección 'usuarios' si ese ID ya existe
  var usuarioQuery = await FirebaseFirestore.instance
      .collection('usuarios')
      .where('deviceId', isEqualTo: idCelu)
      .get();

  // 3. Decidimos a qué pantalla ir
  if (usuarioQuery.docs.isNotEmpty) {
    debugPrint("✅ Vecino reconocido, entrando a Inicio.");
    return const InicioPage();
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

      // Volvemos a la configuración simple: entra directo a la pantalla de validación profesional
      home: FutureBuilder<Widget>(
        future: verificarUsuario(),
        builder: (context, snapshot) {
          // Mientras busca en Firebase, mostramos un círculo de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Cuando ya tiene la respuesta, muestra la pantalla que corresponde
          return snapshot.data ?? const RegistroPage();
        },
      ),
    );
  }
}
