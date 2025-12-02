// lib/screens/export_screen.dart

import 'package:flutter/material.dart';
import 'package:receipt_parser/receipt_parser.dart';
import '../services/csv_exporter_service.dart';

/// Pantalla para exportar y compartir el archivo CSV generado
class ExportScreen extends StatefulWidget {
  final List<ReceiptData> receipts;

  const ExportScreen({super.key, required this.receipts});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final CsvExporterService _csvService = CsvExporterService();

  bool _isExporting = false;
  bool _exportCompleted = false;
  String? _filePath;
  String? _fileName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-generar CSV al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateCsv();
    });
  }

  Future<void> _generateCsv() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      final result = await _csvService.exportAndShare(widget.receipts);

      if (result['success'] == true) {
        setState(() {
          _exportCompleted = true;
          _filePath = result['filePath'];
          _fileName = result['fileName'];
          _isExporting = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Error desconocido';
          _isExporting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isExporting = false;
      });
    }
  }

  Future<void> _shareFile() async {
    if (_filePath == null) return;

    try {
      await _csvService.shareCsvFile(_filePath!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cyan = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_outlined, color: cyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Exportar CSV',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _isExporting
          ? _buildLoadingView()
          : _errorMessage != null
          ? _buildErrorView()
          : _buildSuccessView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Generando archivo CSV...',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final cyan = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error al generar CSV',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _generateCsv,
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text(
                'Reintentar',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cyan,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final cyan = Theme.of(context).colorScheme.primary;
    final cardBg = Theme.of(context).cardColor;
    final stats = _csvService.getStatistics(widget.receipts);
    final csvContent = _csvService.generateCsvContent(widget.receipts);
    final previewLines = csvContent.split('\n').take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cyan.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cyan,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 32,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡CSV Generado!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Archivo guardado exitosamente',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // File info
          _buildInfoCard(
            cardBg: cardBg,
            title: 'Información del Archivo',
            children: [
              _buildInfoRow(
                Icons.insert_drive_file_outlined,
                'Nombre',
                _fileName ?? 'N/A',
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.receipt_outlined,
                'Registros',
                '${stats['total']} tickets',
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.attach_money,
                'Total',
                'S/ ${stats['totalAmount'].toStringAsFixed(2)}',
                isCyan: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preview
          _buildInfoCard(
            cardBg: cardBg,
            title: 'Vista Previa',
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Primeras líneas del CSV:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...previewLines.map((line) {
                      final shortLine = line.length > 60
                          ? '${line.substring(0, 60)}...'
                          : line;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          shortLine,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      );
                    }),
                    if (csvContent.split('\n').length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '... y ${csvContent.split('\n').length - 5} líneas más',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white38,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _shareFile,
              icon: const Icon(Icons.share_outlined, color: Colors.black),
              label: const Text(
                'Compartir CSV',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cyan,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: Icon(Icons.home_outlined, color: cyan),
              label: Text(
                'Volver al Inicio',
                style: TextStyle(
                  color: cyan,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                side: BorderSide(color: cyan, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required Color cardBg,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isCyan = false,
  }) {
    final cyan = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white38),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isCyan ? cyan : Colors.white,
          ),
        ),
      ],
    );
  }
}
