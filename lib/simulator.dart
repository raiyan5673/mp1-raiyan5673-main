import 'dart:math';
import 'package:yaml/yaml.dart';
import 'processes.dart';
import 'util/stats.dart';

/// Queueing system simulator.
class Simulator {
  final bool verbose;
  final List<Process> _processes = [];
  final List<Event> _processed = [];

  Simulator(YamlMap yamlData, {this.verbose = false}) {
    // Preserve the declaration order in the YAML by iterating over keys as given.
    for (final name in yamlData.keys) {
      final fields = yamlData[name] as YamlMap;
      final type = (fields['type'] as String).trim().toLowerCase();
      switch (type) {
        case 'singleton':
          _processes.add(
            SingletonProcess(
              name,
              duration: _asDouble(fields['duration'], 'duration'),
              arrival: _asDouble(fields['arrival'], 'arrival'),
            ),
          );
          break;
        case 'periodic':
          _processes.add(
            PeriodicProcess(
              name,
              duration: _asDouble(fields['duration'], 'duration'),
              interarrival: _asDouble(fields['interarrival-time'], 'interarrival-time'),
              firstArrival: _asDouble(fields['first-arrival'], 'first-arrival'),
              repetitions: _asInt(fields['num-repetitions'], 'num-repetitions'),
            ),
          );
          break;
        case 'stochastic':
          _processes.add(
            StochasticProcess(
              name,
              meanDuration: _asDouble(fields['mean-duration'], 'mean-duration'),
              meanInterarrival: _asDouble(fields['mean-interarrival-time'], 'mean-interarrival-time'),
              firstArrival: _asDouble(fields['first-arrival'], 'first-arrival'),
              endTime: _asDouble(fields['end'], 'end'),
              // Optional: deterministic seed support if user adds 'seed'
              seed: fields.containsKey('seed') ? _asInt(fields['seed'], 'seed') : null,
            ),
          );
          break;
        default:
          throw ArgumentError("Unknown process type '$type' for '$name'");
      }
    }
  }

  /// Runs the simulation by merging all events in arrival order
  /// and computing their actual start/wait times.
  void run() {
    // Generate all events with a stable index to break ties.
    int idx = 0;
    final List<_Indexed<Event>> queue = [];
    for (final p in _processes) {
      for (final e in p.generateEvents()) {
        queue.add(_Indexed(idx++, e));
      }
    }
    // Sort by arrival time, then declaration order (stable tie-breaker).
    queue.sort((a, b) {
      final c = a.value.arrival.compareTo(b.value.arrival);
      if (c != 0) return c;
      return a.index.compareTo(b.index);
    });

    double now = 0;
    for (final item in queue) {
      final e = item.value;
      // If CPU is idle until this arrival, start at arrival (no wait).
      final start = now < e.arrival ? e.arrival : now;
      e.start = start;
      e.wait = start - e.arrival;
      now = start + e.duration;

      if (verbose) {
        final waited = e.wait == 0 ? 'no wait' : 'waited ${_fmt(e.wait)}';
        print('t=${_fmt(e.start)}: ${e.processName}, duration ${_fmt(e.duration)} started '
              '(arrived @ ${_fmt(e.arrival)}, $waited)');
      }
      _processed.add(e);
    }
  }

  /// Prints the report (per-process stats and summary).
  void printReport() {
    if (verbose && _processed.isNotEmpty) {
      print('\n' + '-' * 62 + '\n');
    }

    // Per-process aggregation
    final Map<String, _Agg> agg = {};
    for (final e in _processed) {
      final a = agg.putIfAbsent(e.processName, () => _Agg());
      a.count += 1;
      a.totalWait += e.wait;
    }

    print('# Per-process statistics');
    for (final name in _processes.map((p) => p.name)) {
      final a = agg[name] ?? _Agg();
      final avg = a.count > 0 ? a.totalWait / a.count : 0.0;
      print('  $name:');
      print('    Events generated:  ${a.count}');
      print('    Total wait time:   ${_fmt(a.totalWait)}');
      print('    Average wait time: ${_fmt(avg)}\n');
    }

    print('-' * 62);
    // Summary
    final totalEvents = _processed.length;
    final totalWait = _processed.fold<double>(0.0, (s, e) => s + e.wait);
    final avgWait = totalEvents > 0 ? totalWait / totalEvents : 0.0;

    print('\n# Summary statistics');
    print('  Total num events:  $totalEvents');
    print('  Total wait time:   ${_fmt(totalWait)}');
    print('  Average wait time: ${_fmt(avgWait)}');
  }

  // Helpers for parsing numeric YAML values that might be int/double.
  static double _asDouble(Object? v, String field) {
    if (v is int) return v.toDouble();
    if (v is double) return v;
    throw ArgumentError("Expected numeric value for '$field', got $v");
  }

  static int _asInt(Object? v, String field) {
    if (v is int) return v;
    if (v is double) return v.round();
    throw ArgumentError("Expected integer value for '$field', got $v");
  }

  static String _fmt(num x) {
    // Print as int when whole, otherwise with up to 3 decimals trimmed.
    if (x == x.roundToDouble()) return x.toInt().toString();
    final s = x.toStringAsFixed(3);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _Agg {
  int count = 0;
  double totalWait = 0.0;
}

class _Indexed<T> {
  final int index;
  final T value;
  _Indexed(this.index, this.value);
}
