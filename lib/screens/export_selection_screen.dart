import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt_record.dart';
import 'export_screen.dart';

/// Pantalla para seleccionar el mes/año a exportar
class ExportSelectionScreen extends StatefulWidget {
  final List<ReceiptRecord> allReceipts;

  const ExportSelectionScreen({super.key, required this.allReceipts});

  @override
  State<ExportSelectionScreen> createState() => _ExportSelectionScreenState();
}

class _ExportSelectionScreenState extends State<ExportSelectionScreen> {
  final Map<String, List<ReceiptRecord>> _groupedReceipts = {};
  String? _selectedMonth;

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

  void _exportMonth(String monthKey) {
    final receipts = _groupedReceipts[monthKey]!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExportScreen(receipts: receipts, monthFilter: monthKey),
      ),
    );
  }

  void _exportAll() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExportScreen(receipts: widget.allReceipts, monthFilter: null),
      ),
    );
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
          'Seleccionar período',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Botón para exportar todo
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
                  onTap: _exportAll,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.select_all,
                          color: Colors.black,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Exportar todos',
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

                return _buildMonthCard(monthKey, receipts.length, total);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCard(String monthKey, int count, double total) {
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
        border: Border.all(
          color: _selectedMonth == monthKey
              ? const Color(0xFF22d3ee)
              : const Color(0xFF2A2A2A),
          width: _selectedMonth == monthKey ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _exportMonth(monthKey),
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
                    Icons.calendar_month,
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
                        '$count comprobante${count != 1 ? 's' : ''}',
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
