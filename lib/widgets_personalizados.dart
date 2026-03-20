import 'package:flutter/material.dart';

// ---------------------------------------------------------
// 1. EL MOLDE CUADRADO (Para la Grilla de la Pantalla Principal)
// ---------------------------------------------------------
class BotonAlerta extends StatelessWidget {
  final String texto;
  final String? rutaImagen;
  final IconData? icono;
  final Color colorFondo;
  final VoidCallback accion;

  const BotonAlerta({
    super.key,
    required this.texto,
    this.rutaImagen,
    this.icono,
    required this.colorFondo,
    required this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorFondo,
      borderRadius: BorderRadius.circular(15),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: accion,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: rutaImagen != null
                      ? Image.asset(rutaImagen!, fit: BoxFit.contain)
                      : Icon(icono, size: 50, color: Colors.black),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. EL MOLDE ANCHO (Para Reclamos / Segunda Pantalla)
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
    return Container(
      width: double.infinity, // Ocupa todo el ancho disponible
      height: 75,
      margin:
          const EdgeInsets.symmetric(vertical: 10), // SEPARACIÓN ENTRE BOTONES
      child: Material(
        color: estaSeleccionado
            ? const Color(0xFF2196F3)
            : colorFondo, // Azul vibrante si selecciona
        borderRadius: BorderRadius.circular(15),
        elevation: 5, // SOMBRA
        shadowColor: Colors.black54,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: accion,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 25),
                  child: Icon(icono,
                      size: 35,
                      color: estaSeleccionado ? Colors.white : iconoColor),
                ),
              ),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 22, // Texto más legible
                  fontWeight: FontWeight.bold,
                  color: estaSeleccionado ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
