import 'dart:developer';
import 'dart:io';

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
