// lib/widgets/ticket_list_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipt_parser/receipt_parser.dart';

class TicketListItem extends StatelessWidget {
  final ReceiptData ticket;
  final VoidCallback onTap;

  const TicketListItem({super.key, required this.ticket, required this.onTap});

  Color _getTicketColor() {
    final merchant = ticket.merchant?.toLowerCase() ?? '';

    // Colores específicos por tipo
    if (merchant.contains('yape')) {
      return const Color(0xFF6B21A8); // Morado Yape
    } else if (merchant.contains('plin')) {
      return const Color(0xFF7C3AED); // Morado Plin
    } else if (merchant.contains('luz') ||
        merchant.contains('agua') ||
        merchant.contains('sedapal')) {
      return const Color(0xFF2563EB); // Azul servicios
    }

    return const Color(0xFF00E5CC); // Cyan por defecto
  }

  String _getCategory() {
    final merchant = ticket.merchant?.toLowerCase() ?? '';

    if (merchant.contains('yape')) return 'Yape';
    if (merchant.contains('plin')) return 'Plin';
    if (merchant.contains('luz')) return 'Luz';
    if (merchant.contains('agua') || merchant.contains('sedapal'))
      return 'Agua';

    return 'Servicio';
  }

  @override
  Widget build(BuildContext context) {
    // Formato peruano: S/ antes, punto para decimales, coma para miles
    final currencyFormat = NumberFormat.currency(
      locale: "en_US",
      symbol: "S/ ",
      decimalDigits: 2,
    );
    final ticketColor = _getTicketColor();
    final category = _getCategory();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          child: Row(
            children: [
              // Círculo de color
              CircleAvatar(
                radius: 22,
                backgroundColor: ticketColor.withOpacity(0.15),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: ticketColor,
                  child: const Text(
                    "S/",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Información del ticket
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.merchant ?? 'Desconocido',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$category • ${_formatDate(ticket.date)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Monto
              Text(
                currencyFormat.format(ticket.amount ?? 0),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';

    try {
      // Intentar parsear diferentes formatos
      DateTime? date;

      // Formato dd/MM/yyyy
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      if (date != null) {
        return DateFormat('dd MMM yy', 'es_PE').format(date);
      }
    } catch (e) {
      // Si falla el parseo, devolver el string original
    }

    return dateStr;
  }
}
