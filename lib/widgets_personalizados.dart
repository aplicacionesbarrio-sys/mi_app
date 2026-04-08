import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------
// 1. EL MOLDE CUADRADO (Pantalla Principal / Home)
// ---------------------------------------------------------
class BotonAlerta extends StatelessWidget {
  final String texto;
  final String? rutaImagen;
  final IconData? icono;
  final Color colorFondo;
  final VoidCallback accion;
  final bool estaSeleccionado;

  const BotonAlerta({
    super.key,
    required this.texto,
    this.rutaImagen,
    this.icono,
    required this.colorFondo,
    required this.accion,
    this.estaSeleccionado = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.mediumImpact(); // 📳 Vibración táctil
            accion();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: rutaImagen != null
                        ? Image.asset(rutaImagen!, fit: BoxFit.contain)
                        : Icon(icono,
                            size: 45,
                            color: estaSeleccionado
                                ? Colors.white
                                : Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900, // Fuente más pesada para legibilidad
                    color: estaSeleccionado ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. EL MOLDE ANCHO (Listados / Reclamos / Servicios)
// ---------------------------------------------------------
class BotonAlertaPro extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color iconoColor;
  final Color colorFondo;
  final VoidCallback accion;
  final bool estaSeleccionado;

  const BotonAlertaPro({
    super.key,
    required this.texto,
    required this.icono,
    required this.iconoColor,
    required this.colorFondo,
    required this.accion,
    this.estaSeleccionado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: colorFondo,
        borderRadius: BorderRadius.circular(15),
        elevation: estaSeleccionado ? 6 : 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            HapticFeedback.lightImpact();
            accion();
          },
          child: Container(
            height: 70, // Un poco más alto para comodidad del pulgar
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Ícono dinámico
                Icon(icono,
                    size: 28,
                    color: estaSeleccionado ? Colors.white : iconoColor),

                // Espacio dinámico para que el texto esté centrado pero respete al ícono
                const SizedBox(width: 15),

                Expanded(
                  child: Text(
                    texto.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.bold,
                      color: estaSeleccionado ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                // Flecha indicadora (opcional, da feedback visual de que es clickeable)
                Icon(Icons.arrow_forward_ios,
                    size: 14,
                    color:
                        estaSeleccionado ? Colors.white54 : Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
