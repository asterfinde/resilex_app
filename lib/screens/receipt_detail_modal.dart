import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt_record.dart';

/// Modal que muestra los detalles completos de un comprobante
class ReceiptDetailModal extends StatelessWidget {
  final ReceiptRecord receipt;

  const ReceiptDetailModal({super.key, required this.receipt});

  Color _getTicketColor() {
    switch (receipt.type) {
      case 'yape':
        return const Color(0xFF6B21A8); // Morado Yape
      case 'plin':
        return const Color(0xFF267a3e); // Verde Plin
      case 'boleta':
        return Colors.white; // Blanco Boleta
      default:
        return const Color(0xFF22d3ee); // Cyan por defecto
    }
  }

  String _getTypeLabel() {
    switch (receipt.type) {
      case 'yape':
        return 'Yape';
      case 'plin':
        return 'Plin';
      case 'boleta':
        return 'Boleta Electrónica';
      default:
        return 'Comprobante';
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';

    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          return DateFormat('dd MMMM yyyy', 'es_ES').format(date);
        }
      }
    } catch (e) {
      // Si falla el parseo, devolver el string original
    }

    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: "en_US",
      symbol: "S/ ",
      decimalDigits: 2,
    );

    final ticketColor = _getTicketColor();
    final typeLabel = _getTypeLabel();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header con ícono y tipo
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Ícono grande
                CircleAvatar(
                  radius: 40,
                  backgroundColor: ticketColor.withOpacity(0.15),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: ticketColor,
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tipo de comprobante
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: ticketColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),

                // Monto grande
                Text(
                  currencyFormat.format(receipt.amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(color: Colors.grey.shade800, thickness: 1, height: 1),

          // Detalles
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.store_outlined,
                  label: 'Comercio',
                  value: receipt.merchant,
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha',
                  value: _formatDate(receipt.date),
                ),
                if (receipt.time?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    icon: Icons.access_time_outlined,
                    label: 'Hora',
                    value: receipt.time ?? '',
                  ),
                ],
                if (receipt.operationNumber?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    icon: Icons.tag_outlined,
                    label: 'N° Operación',
                    value: receipt.operationNumber ?? '',
                  ),
                ],
                if (receipt.receiptId.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    icon: Icons.fingerprint_outlined,
                    label: 'ID Comprobante',
                    value: receipt.receiptId,
                  ),
                ],
                if (receipt.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    icon: Icons.description_outlined,
                    label: 'Descripción',
                    value: receipt.description ?? '',
                  ),
                ],
              ],
            ),
          ),

          // Botón cerrar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22d3ee),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF22d3ee), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
