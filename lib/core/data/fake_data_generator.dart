import 'dart:math';
import '../models/user_record.dart';

/// Generador de datos fake para testing
class FakeDataGenerator {
  static final _random = Random();

  static final _firstNames = [
    'Ana',
    'Carlos',
    'María',
    'Juan',
    'Laura',
    'Pedro',
    'Sofia',
    'Diego',
    'Carmen',
    'Luis',
    'Elena',
    'Miguel',
    'Isabel',
    'Jorge',
    'Patricia',
    'Roberto',
    'Andrea',
    'Fernando',
    'Claudia',
    'Ricardo',
  ];

  static final _lastNames = [
    'García',
    'Rodríguez',
    'Martínez',
    'López',
    'González',
    'Pérez',
    'Sánchez',
    'Ramírez',
    'Torres',
    'Flores',
    'Rivera',
    'Gómez',
    'Díaz',
    'Cruz',
    'Morales',
    'Reyes',
    'Jiménez',
    'Hernández',
  ];

  static final _statuses = [
    '🙂 Fine',
    '🆘 SOS',
    '📅 Meeting',
    '✅ Ready',
    '🚶 Leave',
    '😊 Happy',
    '😢 Sad',
    '💼 Busy',
    '😴 Sleepy',
    '🎉 Excited',
    '🤔 Thinking',
    '😰 Worried',
  ];

  /// Generar lista de 20 registros fake
  static List<UserRecord> generate20Records() {
    final records = <UserRecord>[];
    final now = DateTime.now();

    for (int i = 0; i < 20; i++) {
      final firstName = _firstNames[_random.nextInt(_firstNames.length)];
      final lastName = _lastNames[_random.nextInt(_lastNames.length)];
      final status = _statuses[_random.nextInt(_statuses.length)];

      // Timestamps aleatorios en las últimas 2 horas
      final minutesAgo = _random.nextInt(120);
      final timestamp = now.subtract(Duration(minutes: minutesAgo));

      records.add(
        UserRecord(
          id: 'user_${i + 1}',
          name: '$firstName $lastName',
          status: status,
          timestamp: timestamp,
          avatarUrl: null, // Podríamos usar https://i.pravatar.cc/150?img=$i
        ),
      );
    }

    // Ordenar por timestamp descendente (más reciente primero)
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return records;
  }
}
