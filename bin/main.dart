import 'dart:io';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:queueing_simulator/simulator.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('conf', abbr: 'c', help: 'Path to YAML configuration file')
    ..addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false,
        help: 'Print a simulation trace before the report')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage');

  ArgResults results;
  try {
    results = parser.parse(args);
  } catch (e) {
    _usage(parser, error: e.toString());
    exit(64);
  }

  if (results['help'] == true || !results.wasParsed('conf')) {
    _usage(parser);
    exit(results['help'] == true ? 0 : 64);
  }

  final confPath = results['conf'] as String;
  final verbose = results['verbose'] as bool;

  final file = File(confPath);
  if (!file.existsSync()) {
    stderr.writeln('Config file not found: $confPath');
    exit(66);
  }

  final yamlString = file.readAsStringSync();
  final yamlData = loadYaml(yamlString) as YamlMap;

  final sim = Simulator(yamlData, verbose: verbose);
  if (verbose) {
    print('# Simulation trace');
  }
  sim.run();
  print('\n' + '-' * 62 + '\n');
  sim.printReport();
}

void _usage(ArgParser parser, {String? error}) {
  if (error != null) {
    stderr.writeln(error);
  }
  stderr.writeln('Usage: dart run bin/main.dart -c <config.yaml> [-v]');
  stderr.writeln(parser.usage);
}
