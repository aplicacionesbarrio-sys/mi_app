import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: InicioPage(),
    );
  }
}

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  int alertas = 0;
  List<String> historial = [];

  void enviarAlerta() {
    setState(() {
      alertas++;
      historial.add("Alerta #$alertas enviada");
    });

    print("ALERTA ENVIADA");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚨 Alerta enviada al barrio"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barrio Seguro"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Alertas en el barrio:",
            style: TextStyle(fontSize: 22),
          ),
          Text(
            "$alertas",
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: enviarAlerta,
            child: const Text("Enviar Alerta"),
          ),
          const SizedBox(height: 20),
          const Text(
            "Historial de alertas",
            style: TextStyle(fontSize: 18),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: historial.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(historial[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
