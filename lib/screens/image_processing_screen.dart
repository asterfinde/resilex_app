import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:receipt_parser/receipt_parser.dart';
import '../models/receipt_record.dart';
import '../services/database_service.dart';

/// Pantalla 3: Procesamiento de tickets con preview
/// Diseño según pantalla3.png - Muestra imágenes seleccionadas y botón "Procesar X ticket(s)"
class ImageProcessingScreen extends StatefulWidget {
  final List<XFile> images;

  const ImageProcessingScreen({super.key, required this.images});

  @override
  State<ImageProcessingScreen> createState() => _ImageProcessingScreenState();
}

class _ImageProcessingScreenState extends State<ImageProcessingScreen> {
  final DatabaseService _db = DatabaseService();
  final ReceiptParser _parser = ReceiptParser();
  bool _isProcessing = false;
  int _currentProcessing = 0;

  @override
  void dispose() {
    _parser.dispose();
    super.dispose();
  }

  Future<void> _processImages() async {
    setState(() {
      _isProcessing = true;
      _currentProcessing = 0;
    });

    int saved = 0;

    for (int i = 0; i < widget.images.length; i++) {
      setState(() => _currentProcessing = i + 1);

      try {
        // Procesar con OCR y parser
        final receiptData = await _parser.parseFromImage(widget.images[i].path);

        // Convertir a ReceiptRecord
        final record = ReceiptRecord.fromReceiptData(receiptData);

        // Guardar en SQLite
        final id = await _db.insertReceipt(record);

        if (id > 0) {
          saved++;
        }
        // Si id == -1, es duplicado (no contamos como error)
      } catch (e) {
        print('Error procesando imagen ${i + 1}: $e');
        // Continuar con la siguiente imagen
      }
    }

    setState(() => _isProcessing = false);

    if (mounted) {
      // Mostrar resultado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved > 0
                ? '$saved comprobante${saved > 1 ? 's' : ''} guardado${saved > 1 ? 's' : ''}'
                : 'No se pudo procesar ningún comprobante',
          ),
          backgroundColor: saved > 0
              ? Colors.green.shade700
              : Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );

      // Volver al Home con señal de actualización
      if (saved > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      widget.images.removeAt(index);
    });

    if (widget.images.isEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _isProcessing ? 'Procesando...' : 'Seleccionar Tick...',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isProcessing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                widget.images.clear();
                Navigator.pop(context);
              },
              tooltip: 'Eliminar todas',
            ),
        ],
      ),
      body: Column(
        children: [
          // Contador de imágenes
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _isProcessing
                  ? 'Procesando $_currentProcessing de ${widget.images.length}...'
                  : '${widget.images.length} imagen${widget.images.length > 1 ? 'es' : ''} seleccionada${widget.images.length > 1 ? 's' : ''}',
              style: TextStyle(
                color: const Color(0xFF22d3ee),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Grid de imágenes
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return _buildImageCard(index);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Color(0xFF0A0A0A)),
        child: _isProcessing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LinearProgressIndicator(
                    color: Color(0xFF22d3ee),
                    backgroundColor: Color(0xFF1A1A1A),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Procesando $_currentProcessing de ${widget.images.length}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              )
            : ElevatedButton.icon(
                onPressed: _processImages,
                icon: const Icon(Icons.flash_on, color: Colors.black),
                label: Text(
                  'Procesar ${widget.images.length} ticket${widget.images.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22d3ee),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildImageCard(int index) {
    final image = widget.images[index];
    final isCurrentlyProcessing =
        _isProcessing && _currentProcessing == index + 1;

    return Stack(
      children: [
        // Imagen
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentlyProcessing
                  ? const Color(0xFF22d3ee)
                  : const Color(0xFF2A2A2A),
              width: isCurrentlyProcessing ? 3 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(image.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),

        // Badge con número
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22d3ee),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),

        // Botón eliminar (solo si no está procesando)
        if (!_isProcessing)
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),

        // Indicador de procesamiento
        if (isCurrentlyProcessing)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.6),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF22d3ee),
                strokeWidth: 3,
              ),
            ),
          ),
      ],
    );
  }
}
