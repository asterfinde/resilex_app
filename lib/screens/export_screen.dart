import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt_record.dart';
import '../services/csv_exporter_service.dart';

/// Pantalla para exportar comprobantes a CSV
class ExportScreen extends StatefulWidget {
  final List<ReceiptRecord> receipts;

  const ExportScreen({super.key, required this.receipts});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final CsvExporterService _exporter = CsvExporterService();
  bool _isExporting = false;
  Map<String, dynamic>? _exportResult;

  @override
  void initState() {
    super.initState();
    _exportCsv();
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);

    final result = await _exporter.exportAndShare(widget.receipts);

    setState(() {
      _isExporting = false;
      _exportResult = result;
    });
  }

  Future<void> _shareCsv() async {
    if (_exportResult != null && _exportResult!['success'] == true) {
      try {
        await _exporter.shareCsvFile(_exportResult!['filePath']);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al compartir: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _exporter.getStatistics(widget.receipts);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Exportar CSV',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isExporting
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF22d3ee)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Success card
                  if (_exportResult?['success'] == true) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF22d3ee).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF22d3ee),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'CSV Generado',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _exportResult!['fileName'],
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Stats
                  _buildStatCard(
                    'Total de comprobantes',
                    '${stats['total']}',
                    Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Monto total',
                    NumberFormat.currency(
                      locale: 'en_US',
                      symbol: 'S/ ',
                      decimalDigits: 2,
                    ).format(stats['totalAmount']),
                    Icons.attach_money,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Promedio',
                    NumberFormat.currency(
                      locale: 'en_US',
                      symbol: 'S/ ',
                      decimalDigits: 2,
                    ).format(stats['avgAmount']),
                    Icons.analytics_outlined,
                  ),
                  const SizedBox(height: 32),

                  // Share button
                  if (_exportResult?['success'] == true)
                    ElevatedButton.icon(
                      onPressed: _shareCsv,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22d3ee),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text(
                        'Compartir CSV',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF22d3ee), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
