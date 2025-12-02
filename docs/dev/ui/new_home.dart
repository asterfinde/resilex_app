import 'package:flutter/material.dart';

void main() {
  runApp(const ResilexApp());
}

class ResilexApp extends StatelessWidget {
  const ResilexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), // Negro suave, no absoluto
        primaryColor: const Color(0xFF00E676), // Verde neón/teal de la imagen
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00E676),
          surface: Color(0xFF1A1A1A), // Color de las tarjetas
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// Modelo de datos simple
class Transaction {
  final String id;
  final String name;
  final String date;
  final double amount;
  final String monthHeader; // Para agrupar
  final double? monthTotal; // Total del mes (opcional para el header)

  Transaction({
    required this.id,
    required this.name,
    required this.date,
    required this.amount,
    required this.monthHeader,
    this.monthTotal,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos simulados (Mock Data)
    final List<Transaction> transactions = [
      Transaction(id: '1', name: 'Fritz Hardy Frantze', date: '02 dic 25', amount: 81.00, monthHeader: 'Diciembre 2025', monthTotal: 81.00),
      Transaction(id: '2', name: 'Inversiones Clara Na...', date: '13 ago 25', amount: 21.90, monthHeader: 'Agosto 2025', monthTotal: 68.90),
      Transaction(id: '3', name: 'Mauricio F. Frias G.', date: '13 ago 25', amount: 30.00, monthHeader: 'Agosto 2025'),
      Transaction(id: '4', name: 'Miguel A. Diaz M.', date: '04 ago 25', amount: 5.00, monthHeader: 'Agosto 2025'),
      Transaction(id: '5', name: 'Guzman D. Carrillo S.', date: '04 ago 25', amount: 12.00, monthHeader: 'Agosto 2025'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('RESILEX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF00E676)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final item = transactions[index];
          
          // Lógica simple para mostrar cabeceras solo cuando cambian
          bool showHeader = false;
          if (index == 0 || transactions[index - 1].monthHeader != item.monthHeader) {
            showHeader = true;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                const SizedBox(height: 20),
                _buildSectionHeader(item.monthHeader, item.monthTotal),
                const SizedBox(height: 12),
              ],
              _buildTransactionCard(context, item),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black, // Icono negro para alto contraste
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), // Squircle moderno
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionHeader(String title, double? total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF00E676), // Color de acento
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          if (total != null)
            Text(
              '${total.toStringAsFixed(2)} S/',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Transaction item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20), // Bordes más redondeados
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Acción al tocar
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Más espacio interno
            child: Row(
              children: [
                _buildAvatar(item.name),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Servicio • ${item.date}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.amount.toStringAsFixed(2)} S/',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  Widget _buildAvatar(String name) {
    // Extraer iniciales
    String initials = name.isNotEmpty ? name[0] : '?';
    if (name.contains(' ')) {
      List<String> parts = name.split(' ');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials += parts[1][0];
      }
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C), // Fondo del icono ligeramente más claro
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF00E676),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}