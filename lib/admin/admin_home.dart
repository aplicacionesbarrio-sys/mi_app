import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/tableros_admin.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Tablero de Administrador',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 79, 30, 152),
        elevation: 4,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. MONITOR DE ALERTAS
          _buildSmartCard(
            context,
            title: '🚨 MONITOR DE ALERTAS',
            subtitleNormal: 'Ver alertas activas',
            subtitleAlert: 'EMERGENCIAS EN CURSO',
            icon: Icons.notification_important,
            baseColor: Colors.red.shade50,
            activeColor: Colors.red.shade700,
            iconColor: Colors.red,
            query: FirebaseFirestore.instance
                .collection('alertas')
                .where('estado', isEqualTo: 'activa'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const TablerosAdmin(categoriaInicial: 'alertas'),
                ),
              );
            },
          ),

          // 2. GESTIÓN DE RECLAMOS
          _buildSmartCard(
            context,
            title: '📋 GESTIÓN DE RECLAMOS',
            subtitleNormal: 'Ver lista de reclamos',
            subtitleAlert: 'RECLAMOS PENDIENTES',
            icon: Icons.assignment,
            baseColor: const Color(0xFFE1F5FE),
            activeColor: Colors.blue.shade800,
            iconColor: Colors.blue,
            query: FirebaseFirestore.instance
                .collection('reclamos')
                .where('estado', isEqualTo: 'pendiente'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const TablerosAdmin(categoriaInicial: 'reclamos'),
                ),
              );
            },
          ),

          // 3. AUDITORÍA DE SERVICIOS
          _buildSmartCard(
            context,
            title: '🔧 AUDITORÍA DE SERVICIOS',
            subtitleNormal: 'Pedidos a técnicos',
            subtitleAlert: 'TRABAJOS POR AUDITAR',
            icon: Icons.build,
            baseColor: const Color(0xFFFFF3E0),
            activeColor: Colors.orange.shade900,
            iconColor: Colors.orange,
            query: FirebaseFirestore.instance.collection('servicios'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const TablerosAdmin(categoriaInicial: 'servicios'),
                ),
              );
            },
          ),

          // 4. ESTADÍSTICAS RÁPIDAS
          _buildSmartCard(
            context,
            title: '📊 ESTADÍSTICAS RÁPIDAS',
            subtitleNormal: 'Actividad de hoy',
            subtitleAlert: 'RESUELTOS HOY',
            icon: Icons.bar_chart,
            baseColor: const Color(0xFFFFFDE7),
            activeColor: Colors.amber.shade700,
            iconColor: Colors.green,
            query: FirebaseFirestore.instance
                .collection('alertas')
                .where('estado', isEqualTo: 'resuelta'),
            onTap: () => debugPrint("Abrir Estadísticas"),
          ),

          // 5. FÁBRICA DE CÓDIGOS
          _buildSmartCard(
            context,
            title: '🔑 FÁBRICA DE CÓDIGOS',
            subtitleNormal: 'Gestionar usuarios',
            subtitleAlert: 'USUARIOS EN SISTEMA',
            icon: Icons.vpn_key,
            baseColor: const Color(0xFFF3E5F5),
            activeColor: Colors.purple.shade800,
            iconColor: Colors.purple,
            query: FirebaseFirestore.instance.collection('usuarios'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const TablerosAdmin(categoriaInicial: 'usuarios'),
                ),
              );
            },
          ),

          // 6. CONTROL DE PAGOS
          _buildSmartCard(
            context,
            title: '💳 CONTROL DE PAGOS',
            subtitleNormal: 'Estado de cuentas',
            subtitleAlert: 'VENCIDOS / AVISOS',
            icon: Icons.payments,
            baseColor: const Color(0xFFE8F5E9),
            activeColor: Colors.green.shade900,
            iconColor: Colors.green,
            query: FirebaseFirestore.instance
                .collection('usuarios')
                .where('estadoPago', isEqualTo: 'vencido'),
            onTap: () => debugPrint("Abrir Pagos"),
          ),
        ],
      ),
    );
  }

  // --- WIDGET DE TARJETA CON BLINDAJE ANTI-ERRORES ---
  Widget _buildSmartCard(
    BuildContext context, {
    required String title,
    required String subtitleNormal,
    required String subtitleAlert,
    required IconData icon,
    required Color baseColor,
    required Color activeColor,
    required Color iconColor,
    required Query query,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        // 🛡️ BLINDAJE: Manejo de errores de conexión o permisos
        if (snapshot.hasError) {
          return const SizedBox
              .shrink(); // Si hay error, la tarjeta se oculta para no romper la UI
        }

        // 🛡️ BLINDAJE: Mientras carga, mostramos la tarjeta en modo "base" pero sin datos
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _cardLayout(
            hasData: false,
            count: 0,
            title: title,
            subtitleNormal: "Cargando...",
            subtitleAlert: "",
            icon: icon,
            baseColor: baseColor,
            activeColor: activeColor,
            iconColor: iconColor.withOpacity(0.3),
            onTap: () {},
          );
        }

        // 🛡️ BLINDAJE: Aseguramos que data no sea nulo antes de contar
        int count = (snapshot.hasData && snapshot.data != null)
            ? snapshot.data!.docs.length
            : 0;
        bool hasData = count > 0;

        return _cardLayout(
          hasData: hasData,
          count: count,
          title: title,
          subtitleNormal: subtitleNormal,
          subtitleAlert: subtitleAlert,
          icon: icon,
          baseColor: baseColor,
          activeColor: activeColor,
          iconColor: iconColor,
          onTap: onTap,
        );
      },
    );
  }

  // 🛡️ BLINDAJE: Separamos el diseño para que sea más fácil de mantener y no se repita lógica
  Widget _cardLayout({
    required bool hasData,
    required int count,
    required String title,
    required String subtitleNormal,
    required String subtitleAlert,
    required IconData icon,
    required Color baseColor,
    required Color activeColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 110,
        decoration: BoxDecoration(
          color: hasData ? activeColor : baseColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 45,
                      color: hasData ? Colors.white : iconColor,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: hasData ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasData ? "$count $subtitleAlert" : subtitleNormal,
                            style: TextStyle(
                              color: hasData ? Colors.white70 : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasData)
              Positioned(
                top: 10,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 30, minHeight: 30),
                  child: Center(
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
