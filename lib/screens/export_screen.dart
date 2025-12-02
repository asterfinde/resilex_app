// lib/screens/export_screen.dart

import 'package:flutter/material.dart';
import 'package:receipt_parser/receipt_parser.dart';
import 'package:intl/intl.dart';
import '../services/csv_exporter_service.dart';
import '../services/database_service.dart';

enum ExportFilter { all, month, dateRange }

/// Pantalla para exportar y compartir el archivo CSV generado
class ExportScreen extends StatefulWidget {
  final List<ReceiptData> receipts;

  const ExportScreen({super.key, required this.receipts});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final CsvExporterService _csvService = CsvExporterService();
  final DatabaseService _db = DatabaseService();

  ExportFilter _selectedFilter = ExportFilter.all;
  String? _selectedMonth;
  List<String> _availableMonths = [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableMonths();
  }

  void _loadAvailableMonths() {
    final Set<String> months = {};

    for (var receipt in widget.receipts) {
      if (receipt.date == null || receipt.date!.isEmpty) continue;

      try {
        final parts = receipt.date!.split('/');
        if (parts.length == 3) {
          final month = '${parts[1]}/${parts[2]}'; // "MM/YYYY"
          months.add(month);
        }
      } catch (e) {
        continue;
      }
    }

    setState(() {
      _availableMonths = months.toList()..sort((a, b) => b.compareTo(a));
      if (_availableMonths.isNotEmpty) {
        _selectedMonth = _availableMonths.first;
      }
    });
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
    });

    try {
      List<ReceiptData> receiptsToExport;

      switch (_selectedFilter) {
        case ExportFilter.all:
          receiptsToExport = widget.receipts;
          break;

        case ExportFilter.month:
          if (_selectedMonth == null) {
            throw Exception('Selecciona un mes');
          }
          receiptsToExport = await _db.getReceiptsByMonth(_selectedMonth!);
          break;

        case ExportFilter.dateRange:
          // TODO: Implementar selector de rango de fechas
          receiptsToExport = widget.receipts;
          break;
      }

      if (receiptsToExport.isEmpty) {
        throw Exception('No hay comprobantes para exportar con este filtro');
      }

      final result = await _csvService.exportAndShare(receiptsToExport);

      setState(() {
        _isExporting = false;
      });

      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CSV exportado: ${receiptsToExport.length} comprobantes',
            ),
            backgroundColor: Colors.green[600],
            action: SnackBarAction(
              label: 'Compartir',
              textColor: Colors.white,
              onPressed: () async {
                await _csvService.shareCsvFile(result['filePath']);
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Exportar CSV'),
        backgroundColor: const Color(0xFF0A0A0A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecciona qué exportar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Opción: Exportar todo
            _buildFilterOption(
              ExportFilter.all,
              'Todo',
              'Exportar todos los comprobantes (${widget.receipts.length})',
              Icons.select_all,
            ),

            const SizedBox(height: 16),

            // Opción: Exportar por mes
            _buildFilterOption(
              ExportFilter.month,
              'Por mes',
              'Exportar comprobantes de un mes específico',
              Icons.calendar_month,
            ),

            if (_selectedFilter == ExportFilter.month && _availableMonths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 56, top: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF22d3ee)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF22d3ee).withOpacity(0.3),
                      ),
                    ),
                  ),
                  items: _availableMonths.map((month) {
                    final parts = month.split('/');
                    final monthName = DateFormat('MMMM yyyy', 'es_PE').format(
                      DateTime(int.parse(parts[1]), int.parse(parts[0])),
                    );
                    return DropdownMenuItem(
                      value: month,
                      child: Text(monthName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value;
                    });
                  },
                ),
              ),

            const Spacer(),

            // Información del total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF22d3ee).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total a exportar:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${widget.receipts.length} comprobantes',
                    style: const TextStyle(
                      color: Color(0xFF22d3ee),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botón exportar
            ElevatedButton(
              onPressed: _isExporting ? null : _exportCsv,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22d3ee),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isExporting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Exportar CSV',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    ExportFilter filter,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedFilter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF22d3ee).withOpacity(0.1)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF22d3ee)
                : const Color(0xFF1A1A1A),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF22d3ee).withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF22d3ee) : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF22d3ee) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF22d3ee),
              ),
          ],
        ),
      ),
    );
  }
}
