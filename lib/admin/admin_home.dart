import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero de Administrador'),
        backgroundColor: const Color.fromARGB(255, 79, 30, 152),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // BOTÓN 1: MONITOR DE PÁNICO
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.notification_important,
                  color: Colors.red, size: 40),
              title: const Text('🚨 MONITOR DE PÁNICO',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Ver alertas activas y ubicación en mapa'),
              onTap: () {
                debugPrint('Abriendo Monitor...');
              },
            ),
          ),

          // BOTÓN 2: RECLAMOS
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.assignment, color: Colors.blue, size: 40),
              title: const Text('📋 GESTIÓN DE RECLAMOS',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Ver lista de problemas reportados'),
              onTap: () {
                debugPrint('Abriendo Reclamos...');
              },
            ),
          ),

          // BOTÓN 3: AUDITORÍA DE SERVICIOS
          Card(
            child: ListTile(
              leading: const Icon(Icons.build_circle,
                  color: Colors.orange, size: 40),
              title: const Text('🔧 AUDITORÍA DE SERVICIOS',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Pedidos a técnicos y calidad'),
              onTap: () {
                debugPrint('Abriendo Auditoría...');
              },
            ),
          ),

          // BOTÓN 4: ESTADÍSTICAS
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.bar_chart, color: Colors.green, size: 40),
              title: const Text('📊 ESTADÍSTICAS RÁPIDAS',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Contador diario de actividad'),
              onTap: () {
                debugPrint('Abriendo Estadísticas...');
              },
            ),
          ),

          // BOTÓN 5: FÁBRICA DE CÓDIGOS
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.vpn_key, color: Colors.purple, size: 40),
              title: const Text('🔑 FÁBRICA DE CÓDIGOS',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Generar códigos de 6 dígitos'),
              onTap: () {
                debugPrint('Abriendo Generador...');
              },
            ),
          ),

          // BOTÓN 6: CONTROL DE PAGOS (ROL 3)
          Card(
            color: Colors.green.shade50,
            child: ListTile(
              leading: const Icon(Icons.monetization_on,
                  color: Colors.green, size: 40),
              title: const Text('💳 CONTROL DE PAGOS',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Lista de vecinos, avisos y bloqueo'),
              onTap: () {
                debugPrint('Abriendo Pagos...');
              },
            ),
          ),
        ],
      ),
    );
  }
}
