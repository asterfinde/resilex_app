/// Utilidad para medir performance de operaciones
class PerformanceTracker {
  static final Map<String, DateTime> _startTimes = {};

  static void start(String label) {
    _startTimes[label] = DateTime.now();
    print('⏱️ [Performance] Inicio: $label');
  }

  static int end(String label) {
    final start = _startTimes[label];
    if (start == null) {
      print('⚠️ [Performance] No se encontró inicio para: $label');
      return 0;
    }

    final duration = DateTime.now().difference(start).inMilliseconds;
    print('⏱️ [Performance] $label: ${duration}ms');
    _startTimes.remove(label);
    return duration;
  }

  static int? getDuration(String label) {
    final start = _startTimes[label];
    if (start == null) return null;
    return DateTime.now().difference(start).inMilliseconds;
  }
}
