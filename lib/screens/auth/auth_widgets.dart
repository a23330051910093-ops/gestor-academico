import 'package:flutter/material.dart';

class PasoIndicador extends StatelessWidget {
  final int numero;
  final bool activo;
  final String texto;

  const PasoIndicador({
    super.key,
    required this.numero,
    required this.activo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: activo ? const Color(0xFF1565C0) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$numero',
            style: TextStyle(
              color: activo ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          texto,
          style: TextStyle(
            fontSize: 11,
            color: activo ? const Color(0xFF1565C0) : Colors.grey,
          ),
        ),
      ],
    );
  }
}

class ErrorBox extends StatelessWidget {
  final String mensaje;
  const ErrorBox({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        mensaje,
        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}