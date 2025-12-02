// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:receipt_parser/receipt_parser.dart';
import 'package:intl/intl.dart';
import '../widgets/ticket_list_item.dart';
import '../services/database_service.dart';
import 'image_picker_screen.dart';
import 'export_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ReceiptData> _tickets = [];
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicketsFromDB();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Carga todos los comprobantes desde SQLite
  Future<void> _loadTicketsFromDB() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tickets = await _db.getAllReceipts();
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar comprobantes: $e'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  Map<String, List<ReceiptData>> _groupTicketsByMonth(
    List<ReceiptData> tickets,
  ) {
    final Map<String, List<ReceiptData>> grouped = {};

    for (var ticket in tickets) {
      if (ticket.date == null || ticket.date!.isEmpty) continue;

      try {
        DateTime? date;
        final dateStr = ticket.date!;

        // Parsear fecha dd/MM/yyyy
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
          // Formato simple sin localización: "Noviembre 2025"
          final months = [
            'Enero',
            'Febrero',
            'Marzo',
            'Abril',
            'Mayo',
            'Junio',
            'Julio',
            'Agosto',
            'Septiembre',
            'Octubre',
            'Noviembre',
            'Diciembre',
          ];
          final monthKey = '${months[date.month - 1]} ${date.year}';
          grouped.putIfAbsent(monthKey, () => []);
          grouped[monthKey]!.add(ticket);
        }
      } catch (e) {
        // Si falla el parseo, ignorar
        continue;
      }
    }

    return grouped;
  }

  void _showTicketDetails(ReceiptData ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Detalles del Ticket',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Cliente', ticket.merchant ?? 'N/A'),
            _buildDetailRow(
              'Monto',
              NumberFormat.currency(
                locale: 'en_US',
                symbol: 'S/ ',
                decimalDigits: 2,
              ).format(ticket.amount ?? 0),
            ),
            _buildDetailRow('Fecha', ticket.date ?? 'N/A'),
            _buildDetailRow('N° Operación', ticket.operationNumber ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFF22d3ee)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToImagePicker() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ImagePickerScreen()),
    );

    // Si se guardaron comprobantes, recargar desde DB
    if (result == true) {
      await _loadTicketsFromDB();
    }
  }

  void _navigateToExport() {
    if (_tickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay tickets para exportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExportScreen(receipts: _tickets)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedTickets = _groupTicketsByMonth(_tickets);
    final sortedMonths = groupedTickets.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RESILEX',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        actions: [
          if (_tickets.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Exportar CSV',
              onPressed: _navigateToExport,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadTicketsFromDB,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Lista agrupada por meses
                    ...sortedMonths.map((month) {
                      final monthTickets = groupedTickets[month]!;
                      final monthTotal = monthTickets.fold<double>(
                        0,
                        (sum, t) => sum + (t.amount ?? 0),
                      );

                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index == 0) {
                            // Header del mes
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 12.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    month,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF22d3ee),
                                    ),
                                  ),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'en_US',
                                      symbol: 'S/ ',
                                      decimalDigits: 2,
                                    ).format(monthTotal),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Item de ticket
                          final ticket = monthTickets[index - 1];
                          return TicketListItem(
                            ticket: ticket,
                            onTap: () => _showTicketDetails(ticket),
                          );
                        }, childCount: monthTickets.length + 1),
                      );
                    }),

                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToImagePicker,
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
          const SizedBox(height: 24),
          Text(
            'No hay tickets registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Presiona + para comenzar',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
