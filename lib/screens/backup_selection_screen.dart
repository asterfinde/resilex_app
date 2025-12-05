import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/receipt_record.dart';
import '../services/backup_service.dart';

/// Pantalla para seleccionar el mes/año a respaldar
class BackupSelectionScreen extends StatefulWidget {
  final List<ReceiptRecord> allReceipts;

  const BackupSelectionScreen({super.key, required this.allReceipts});

  @override
  State<BackupSelectionScreen> createState() => _BackupSelectionScreenState();
}

class _BackupSelectionScreenState extends State<BackupSelectionScreen> {
  final BackupService _backupService = BackupService();
  final Map<String, List<ReceiptRecord>> _groupedReceipts = {};
  bool _isCreatingBackup = false;

  @override
  void initState() {
    super.initState();
    _groupReceiptsByMonth();
  }

  void _groupReceiptsByMonth() {
    for (final receipt in widget.allReceipts) {
      final monthKey = _getMonthKey(receipt.date);
      if (monthKey.isNotEmpty) {
        _groupedReceipts.putIfAbsent(monthKey, () => []);
        _groupedReceipts[monthKey]!.add(receipt);
      }
    }
  }

  String _getMonthKey(String dateStr) {
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          return DateFormat('MMMM yyyy', 'es_ES').format(date);
        }
      }
    } catch (e) {
      print('Error parseando fecha: $dateStr - $e');
    }
    return '';
  }

  double _getMonthTotal(List<ReceiptRecord> receipts) {
    return receipts.fold(0.0, (sum, receipt) => sum + receipt.amount);
  }

  Future<void> _createBackup(
    String monthKey,
    List<ReceiptRecord> receipts,
  ) async {
    setState(() => _isCreatingBackup = true);

    try {
      // Crear backup ZIP
      final result = await _backupService.createBackup(
        receipts: receipts,
        monthFilter: monthKey,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Compartir archivo ZIP
        final filePath = result['filePath'] as String;
        final file = File(filePath);

        if (await file.exists()) {
          await Share.shareXFiles(
            [XFile(filePath)],
            subject: 'Backup RESILEX - $monthKey',
            text:
                'Backup de ${result['receiptsCount']} comprobantes (${result['fileSizeMB']} MB)',
          );

          // Limpiar backups antiguos
          await _backupService.cleanOldBackups();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Backup creado: ${result['receiptsCount']} comprobantes',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al crear backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingBackup = false);
      }
    }
  }

  Future<void> _createFullBackup() async {
    await _createBackup('todos', widget.allReceipts);
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeys = _groupedReceipts.keys.toList()
      ..sort((a, b) {
        try {
          final dateA = DateFormat('MMMM yyyy', 'es_ES').parse(a);
          final dateB = DateFormat('MMMM yyyy', 'es_ES').parse(b);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

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
          'Crear Backup',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isCreatingBackup
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF22d3ee)),
                  SizedBox(height: 16),
                  Text(
                    'Creando backup...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Botón para respaldar todo
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF22d3ee),
                          const Color(0xFF22d3ee).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _createFullBackup,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.backup,
                                color: Colors.black,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Respaldar todos',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.allReceipts.length} comprobantes',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.black,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade800)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'O selecciona un mes',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade800)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Lista de meses
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final monthKey = sortedKeys[index];
                      final receipts = _groupedReceipts[monthKey]!;
                      final total = _getMonthTotal(receipts);

                      return _buildMonthCard(monthKey, receipts, total);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMonthCard(
    String monthKey,
    List<ReceiptRecord> receipts,
    double total,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: "en_US",
      symbol: "S/ ",
      decimalDigits: 2,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _createBackup(monthKey, receipts),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22d3ee).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder_zip,
                    color: Color(0xFF22d3ee),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthKey,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${receipts.length} comprobante${receipts.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(total),
                      style: const TextStyle(
                        color: Color(0xFF22d3ee),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
