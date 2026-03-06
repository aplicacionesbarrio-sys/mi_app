import 'package:flutter/material.dart';

void main() {
  runApp(BarrioSeguroApp());
}

class BarrioSeguroApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barrio Seguro',
      home: InicioPage(),
    );
  }
}

class InicioPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barrio Seguro'),
      ),
body: Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Bienvenido a Barrio Seguro',
        style: TextStyle(fontSize: 24),
      ),
      SizedBox(height: 30),
      ElevatedButton(
        onPressed: () {
          print("Alerta enviada al barrio");
        },
        child: Text("Enviar Alerta"),
      ),
    ],
  ),
),
    );
  }
}