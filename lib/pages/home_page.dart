import 'package:flutter/material.dart';
import '../core/models/user_record.dart';
import '../core/data/fake_data_generator.dart';
import '../core/services/session_cache_service.dart';
import '../core/bridge/native_state_bridge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<UserRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataSync();
  }

  void _loadDataSync() {
    // ⚡ Carga síncrona sin delays
    final records = FakeDataGenerator.generate20Records();

    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year.toString().substring(2)}';
  }

  Future<void> _handleLogout() async {
    // Limpiar todas las capas de cache
    await NativeStateBridge.clear();
    await SessionCacheService.clearSession();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Fondo oscuro
      appBar: AppBar(
        title: const Text('Transacciones'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDataSync),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
            )
          : ListView.separated(
              itemCount: _records.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFF2A2A2A),
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final record = _records[index];
                final amount =
                    (index * 7.5 + 5.0) % 100; // Generar monto variado

                return Container(
                  color: const Color(0xFF1A1A1A),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5), // Turquesa
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'S/',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      record.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Servicio  ${_formatDate(record.timestamp)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    trailing: Text(
                      '${amount.toStringAsFixed(2)} S/',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
