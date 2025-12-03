import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_parser/receipt_parser.dart';
import '../models/receipt_record.dart';
import '../services/database_service.dart';
import '../widgets/ticket_list_item.dart';
import 'export_screen.dart';

/// Pantalla principal que muestra la lista de comprobantes procesados
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  final ReceiptParser _parser = ReceiptParser();

  List<ReceiptRecord> _receipts = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  @override
  void dispose() {
    _parser.dispose();
    super.dispose();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);

    try {
      final receipts = await _db.getAllReceipts();
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

  Future<void> _pickAndProcessImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isEmpty) return;

      setState(() => _isProcessing = true);

      int processed = 0;
      int saved = 0;

      for (final image in images) {
        try {
          // Procesar con OCR y parser
          final receiptData = await _parser.parseFromImage(image.path);

          // Convertir a ReceiptRecord
          final record = ReceiptRecord.fromReceiptData(receiptData);

          // Guardar en SQLite
          final id = await _db.insertReceipt(record);

          if (id > 0) {
            saved++;
          }
          processed++;
        } catch (e) {
          print('Error procesando imagen: $e');
        }
      }

      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$saved de $processed comprobantes guardados'),
            backgroundColor: saved > 0 ? Colors.green : Colors.orange,
          ),
        );
      }

      // Recargar lista
      await _loadReceipts();
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _navigateToExport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportScreen(receipts: _receipts),
      ),
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
          'Resilex',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
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
          : _buildReceiptsList(),
      floatingActionButton: _isProcessing
          ? const CircularProgressIndicator(color: Color(0xFF22d3ee))
          : FloatingActionButton.extended(
              onPressed: _pickAndProcessImages,
              backgroundColor: const Color(0xFF22d3ee),
              icon: const Icon(Icons.add_a_photo, color: Colors.black),
              label: const Text(
                'Procesar',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
            'Toca el botón para procesar imágenes',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsList() {
    return RefreshIndicator(
      onRefresh: _loadReceipts,
      color: const Color(0xFF22d3ee),
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receipts.length,
        itemBuilder: (context, index) {
          final receipt = _receipts[index];
          return TicketListItem(
            ticket: receipt,
            onTap: () {
              // TODO: Mostrar detalles
            },
          );
        },
      ),
    );
  }
}
