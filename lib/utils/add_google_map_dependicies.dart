import 'dart:developer';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

Future<bool> addGoogleMapsDependency(String projectPath) async {
  final pubspecPath = '$projectPath/pubspec.yaml';
  final pubspecFile = File(pubspecPath);

  if (!await pubspecFile.exists()) {
    log('Error: pubspec.yaml not found at $pubspecPath');
    return false;
  }

  try {
    final content = await pubspecFile.readAsString();
    final yamlEditor = YamlEditor(content);

    const packageName = 'google_maps_flutter';
    const packageVersion = '^2.5.3';

    final doc = loadYaml(content);
    bool alreadyExists = false;
    if (doc is Map && doc.containsKey('dependencies')) {
      final dependencies = doc['dependencies'];
      if (dependencies is Map && dependencies.containsKey(packageName)) {
        alreadyExists = true;
        log('$packageName already exists in dependencies.');
      }
    }

    if (!alreadyExists) {
      final node = ['dependencies', packageName];
      yamlEditor.update(node, packageVersion);
      log('Added $packageName: $packageVersion to dependencies.');
    }

    await pubspecFile.writeAsString(yamlEditor.toString());
    log('Successfully updated $pubspecPath');
    return true;
  } catch (e) {
    log('Error updating pubspec.yaml: $e');
    return false;
  }
}

Future<bool> runFlutterPubGet(String projectPath) async {
  log('Running "flutter pub get" in $projectPath...');
  try {
    final result = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: projectPath,
      runInShell: true,
    );

    if (result.exitCode == 0) {
      log('"flutter pub get" completed successfully.');
      log(result.stdout);
      return true;
    } else {
      log('"flutter pub get" failed with exit code ${result.exitCode}');
      log('Error Output:\n${result.stderr}');
      return false;
    }
  } catch (e) {
    log('Error running "flutter pub get": $e');
    return false;
  }
}
