// lib/screens/results_screen.dart

import 'package:flutter/material.dart';
import 'package:receipt_parser/receipt_parser.dart';
import '../services/csv_exporter_service.dart';
import 'export_screen.dart';

/// Pantalla que muestra los resultados del procesamiento de tickets
class ResultsScreen extends StatefulWidget {
  final List<ReceiptData> receipts;
  final List<String> errors;

  const ResultsScreen({
    super.key,
    required this.receipts,
    this.errors = const [],
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final CsvExporterService _csvService = CsvExporterService();

  double get _totalAmount {
    return widget.receipts.fold<double>(
      0,
      (sum, receipt) => sum + (receipt.amount ?? 0),
    );
  }

  void _exportToCsv() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportScreen(receipts: widget.receipts),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          if (widget.errors.isNotEmpty) _buildErrorsCard(),
          Expanded(child: _buildReceiptsList()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSummaryCard() {
    final stats = _csvService.getStatistics(widget.receipts);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Procesamiento Completado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.receipts.length} ticket${widget.receipts.length != 1 ? 's' : ''} procesado${widget.receipts.length != 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.receipt,
                label: 'Total',
                value: '${stats['total']}',
              ),
              _buildStatItem(
                icon: Icons.attach_money,
                label: 'Monto Total',
                value: 'S/ ${stats['totalAmount'].toStringAsFixed(2)}',
              ),
              _buildStatItem(
                icon: Icons.show_chart,
                label: 'Promedio',
                value: 'S/ ${stats['avgAmount'].toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildErrorsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${widget.errors.length} imagen${widget.errors.length != 1 ? 'es' : ''} con errores',
              style: const TextStyle(color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: () => _showErrorsDialog(),
            child: const Text('Ver detalles'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.receipts.length,
      itemBuilder: (context, index) {
        return _buildReceiptCard(widget.receipts[index], index);
      },
    );
  }

  Widget _buildReceiptCard(ReceiptData receipt, int index) {
    final typeIcon = _getTypeIcon(receipt.description ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(typeIcon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          receipt.merchant ?? 'Comercio Desconocido',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('💰 S/ ${receipt.amount?.toStringAsFixed(2) ?? '0.00'}'),
            Text('📅 ${receipt.date ?? 'N/A'} ${receipt.time ?? ''}'),
            if (receipt.operationNumber != null)
              Text('#️⃣ ${receipt.operationNumber}'),
          ],
        ),
        trailing: Text(
          '#${index + 1}',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _showReceiptDetails(receipt),
      ),
    );
  }

  IconData _getTypeIcon(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('yape')) return Icons.phone_android;
    if (lower.contains('plin')) return Icons.smartphone;
    if (lower.contains('boleta')) return Icons.receipt_long;
    return Icons.description;
  }

  void _showReceiptDetails(ReceiptData receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(receipt.merchant ?? 'Detalles del Ticket'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Comercio', receipt.merchant ?? 'N/A'),
              _buildDetailRow(
                'Monto',
                'S/ ${receipt.amount?.toStringAsFixed(2) ?? '0.00'}',
              ),
              _buildDetailRow('Fecha', receipt.date ?? 'N/A'),
              _buildDetailRow('Hora', receipt.time ?? 'N/A'),
              _buildDetailRow('Operación', receipt.operationNumber ?? 'N/A'),
              _buildDetailRow('Descripción', receipt.description ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showErrorsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Errores de Procesamiento'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: widget.errors.map((error) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• $error'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Agregar Más'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _exportToCsv,
                icon: const Icon(Icons.file_download),
                label: const Text('Exportar CSV'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
