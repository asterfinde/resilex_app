import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt_record.dart';

class TicketListItem extends StatelessWidget {
  final ReceiptRecord ticket;
  final VoidCallback onTap;

  const TicketListItem({super.key, required this.ticket, required this.onTap});

  Color _getTicketColor() {
    // Colores específicos por tipo
    switch (ticket.type) {
      case 'yape':
        return const Color(0xFF6B21A8); // Morado Yape
      case 'plin':
        return const Color(0xFF267a3e); // Verde Plin
      case 'boleta':
        return Colors.white; // Blanco Boleta
      default:
        return const Color(0xFF00E5CC); // Cyan por defecto
    }
  }

  String _getCategory() {
    switch (ticket.type) {
      case 'yape':
        return 'Yape';
      case 'plin':
        return 'Plin';
      case 'boleta':
        return 'Boleta';
      default:
        return 'Comprobante';
    }
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
                      ticket.merchant,
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
                currencyFormat.format(ticket.amount),
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';

    try {
      // Formato dd/MM/yyyy
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          return DateFormat('dd MMM yy', 'es_PE').format(date);
        }
      }
    } catch (e) {
      // Si falla el parseo, devolver el string original
    }

    return dateStr;
  }
}
