// lib/screens/image_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_parser/receipt_parser.dart';
import '../services/database_service.dart';
import 'dart:io';

/// Pantalla para seleccionar y procesar imágenes de tickets
class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  final ImagePicker _picker = ImagePicker();
  final ReceiptParser _parser = ReceiptParser();
  final DatabaseService _db = DatabaseService();

  List<XFile> _selectedImages = [];
  bool _isProcessing = false;
  int _processedCount = 0;

  @override
  void dispose() {
    _parser.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imágenes: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showError('Error al capturar foto: $e');
    }
  }

  Future<void> _processImages() async {
    if (_selectedImages.isEmpty) {
      _showError('No hay imágenes seleccionadas');
      return;
    }

    setState(() {
      _isProcessing = true;
      _processedCount = 0;
    });

    final List<ReceiptData> results = [];
    final List<String> errors = [];
    int savedCount = 0;

    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        final result = await _parser.parseFromImage(_selectedImages[i].path);
        results.add(result);

        // Guardar en SQLite
        await _db.insertReceipt(result);
        savedCount++;

        setState(() {
          _processedCount = i + 1;
        });
      } catch (e) {
        errors.add('Imagen ${i + 1}: $e');
      }
    }

    setState(() {
      _isProcessing = false;
    });

    if (results.isEmpty) {
      _showError('No se pudo procesar ninguna imagen');
      return;
    }

    // Mostrar mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$savedCount comprobante${savedCount != 1 ? 's' : ''} guardado${savedCount != 1 ? 's' : ''}',
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Devolver a HomeScreen para que recargue la lista
    if (mounted) {
      Navigator.pop(context, true); // true indica que se guardaron comprobantes
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedImages = [];
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Seleccionar Tickets'),
        actions: [
          if (_selectedImages.isNotEmpty && !_isProcessing)
            IconButton(
              onPressed: _clearSelection,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Limpiar selección',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${_selectedImages.length} imagen${_selectedImages.length != 1 ? 'es' : ''} seleccionada${_selectedImages.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: _isProcessing ? _buildProcessingView() : _buildMainView(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProcessingView() {
    final progress = _selectedImages.isEmpty
        ? 0.0
        : _processedCount / _selectedImages.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white10,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  '$_processedCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Procesando tickets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$_processedCount de ${_selectedImages.length}',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView() {
    if (_selectedImages.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return _buildImageCard(index);
      },
    );
  }

  Widget _buildImageCard(int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(_selectedImages[index].path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).cardColor,
                  child: const Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.white24,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              border: Border.all(color: Colors.white10, width: 2),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'No hay imágenes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona desde tu galería\no toma una foto nueva',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _selectedImages.isEmpty
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _pickImagesFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galería'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isProcessing ? null : _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Cámara'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _processImages,
                  icon: const Icon(Icons.bolt),
                  label: Text(
                    'Procesar ${_selectedImages.length} ticket${_selectedImages.length != 1 ? 's' : ''}',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
      ),
    );
  }
}
