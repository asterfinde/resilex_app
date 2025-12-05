import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt_record.dart';
import '../services/database_service.dart';
import '../widgets/ticket_list_item.dart';
import 'export_selection_screen.dart';
import 'backup_selection_screen.dart';
import 'image_selection_screen.dart';
import 'receipt_detail_modal.dart';

/// Pantalla principal que muestra la lista de comprobantes procesados
/// Diseño según pantalla1.png - Lista agrupada por meses
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();

  List<ReceiptRecord> _receipts = [];
  final Map<String, List<ReceiptRecord>> _groupedReceipts = {};
  final Map<String, double> _monthlyTotals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Cargar datos de forma asíncrona sin bloquear el renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReceipts();
    });
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);

    try {
      final receipts = await _db.getAllReceipts();
      _groupReceiptsByMonth(receipts);

      setState(() {
        _receipts = receipts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar comprobantes: $e')),
        );
      }
    }
  }

  void _groupReceiptsByMonth(List<ReceiptRecord> receipts) {
    _groupedReceipts.clear();
    _monthlyTotals.clear();

    for (final receipt in receipts) {
      final monthKey = _getMonthKey(receipt.date);
      if (monthKey.isNotEmpty) {
        _groupedReceipts.putIfAbsent(monthKey, () => []);
        _groupedReceipts[monthKey]!.add(receipt);

        _monthlyTotals.putIfAbsent(monthKey, () => 0.0);
        _monthlyTotals[monthKey] = _monthlyTotals[monthKey]! + receipt.amount;
      }
    }
  }

  String _getMonthKey(String dateStr) {
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
          // Formato: "Diciembre 2025"
          return DateFormat('MMMM yyyy', 'es_ES').format(date);
        }
      }
    } catch (e) {
      print('Error parseando fecha: $dateStr - $e');
    }
    return '';
  }

  void _navigateToImageSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImageSelectionScreen()),
    );

    // Si se procesaron imágenes, recargar
    if (result == true) {
      _loadReceipts();
    }
  }

  void _navigateToBackup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupSelectionScreen(allReceipts: _receipts),
      ),
    );
    // Recargar después de backup
    _loadReceipts();
  }

  void _navigateToExport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportSelectionScreen(allReceipts: _receipts),
      ),
    );
    // Recargar después de exportar para evitar pantalla vacía
    _loadReceipts();
  }

  void _showReceiptDetail(ReceiptRecord receipt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReceiptDetailModal(receipt: receipt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          'RESILEX',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (_receipts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.backup_outlined, color: Color(0xFF22d3ee)),
              onPressed: _navigateToBackup,
              tooltip: 'Crear Backup',
            ),
          if (_receipts.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.file_download_outlined,
                color: Color(0xFF22d3ee),
              ),
              onPressed: _navigateToExport,
              tooltip: 'Exportar CSV',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF22d3ee)),
            )
          : _receipts.isEmpty
          ? _buildEmptyState()
          : _buildGroupedList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToImageSelection,
        backgroundColor: const Color(0xFF22d3ee),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin comprobantes',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para comenzar',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final sortedKeys = _groupedReceipts.keys.toList()
      ..sort((a, b) {
        // Ordenar por fecha descendente (más reciente primero)
        try {
          final dateA = DateFormat('MMMM yyyy', 'es_ES').parse(a);
          final dateB = DateFormat('MMMM yyyy', 'es_ES').parse(b);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

    return RefreshIndicator(
      onRefresh: _loadReceipts,
      color: const Color(0xFF22d3ee),
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final monthKey = sortedKeys[index];
          final receipts = _groupedReceipts[monthKey]!;
          final total = _monthlyTotals[monthKey]!;

          return _buildMonthSection(monthKey, receipts, total);
        },
      ),
    );
  }

  Widget _buildMonthSection(
    String monthKey,
    List<ReceiptRecord> receipts,
    double total,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: "en_US",
      symbol: "S/ ",
      decimalDigits: 2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header del mes
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthKey,
                style: const TextStyle(
                  color: Color(0xFF22d3ee),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                currencyFormat.format(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // Lista de tickets del mes
        ...receipts.map((receipt) {
          return TicketListItem(
            ticket: receipt,
            onTap: () {
              _showReceiptDetail(receipt);
            },
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }
}
