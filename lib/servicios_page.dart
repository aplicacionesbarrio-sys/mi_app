import 'package:flutter/material.dart';

class ServiciosPage extends StatelessWidget {
  const ServiciosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Servicios"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Pantalla de servicios",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
