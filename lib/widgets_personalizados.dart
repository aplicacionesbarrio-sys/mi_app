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
  final bool estaSeleccionado; // Mantenemos la variable para el cambio de color

  const BotonAlerta({
    super.key,
    required this.texto,
    this.rutaImagen,
    this.icono,
    required this.colorFondo,
    required this.accion,
    this.estaSeleccionado =
        false, // <--- IMPORTANTE: Al ser false por defecto, no da error en otras pantallas
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorFondo, // Ahora usará el color que mandamos desde main.dart
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
                      ? Image.asset(rutaImagen!,
                          height: 50, fit: BoxFit.contain)
                      : Icon(icono,
                          size: 50,
                          color:
                              estaSeleccionado ? Colors.white : Colors.black),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: estaSeleccionado ? Colors.white : Colors.black,
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
      width: double.infinity,
      height: 60, // Altura para que entre la flecha de la pág 3
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: colorFondo,
        borderRadius: BorderRadius.circular(15),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: accion,
          child: Stack(
            // 👈 Stack nos permite encimar cosas
            alignment: Alignment.center, // 👈 Centra todo lo que esté adentro
            children: [
              // 1. EL ICONO ANCLADO A LA IZQUIERDA
              Positioned(
                left: 20, // Distancia desde el borde izquierdo
                child: Icon(
                  icono,
                  size: 30,
                  color: iconoColor,
                ),
              ),

              // 2. EL TEXTO TOTALMENTE CENTRADO
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal:
                        60), // Margen para que el texto largo no pise el icono
                child: Text(
                  texto.toUpperCase(),
                  textAlign:
                      TextAlign.center, // Texto centrado en su propio bloque
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: estaSeleccionado ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
