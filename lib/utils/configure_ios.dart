import 'dart:developer';
import 'dart:io';

Future<void> configureIOS(String projectPath, String key) async {
  final swiftAppDelegatePath = '$projectPath/ios/Runner/AppDelegate.swift';
  final objcAppDelegatePath = '$projectPath/ios/Runner/AppDelegate.m';
  final swiftFile = File(swiftAppDelegatePath);
  final objcFile = File(objcAppDelegatePath);

  log('Starting iOS configuration...');

  try {
    if (await swiftFile.exists()) {
      log('Found AppDelegate.swift. Attempting configuration...');
      await _configureSwiftAppDelegate(swiftFile, key);
    } else if (await objcFile.exists()) {
      log('Found AppDelegate.m. Attempting configuration...');
      await _configureObjcAppDelegate(objcFile, key);
    } else {
      log(
        '❌ Error: Neither AppDelegate.swift nor AppDelegate.m found in ios/Runner.',
      );
      log('  Checked paths:');
      log('  - $swiftAppDelegatePath');
      log('  - $objcAppDelegatePath');
      throw FileSystemException(
        'AppDelegate file not found',
        '$projectPath/ios/Runner/',
      );
    }
  } on FileSystemException catch (e) {
    log('❌ Error accessing AppDelegate file: ${e.message}');
    log('  Path: ${e.path}');
    rethrow;
  } catch (e) {
    log('❌ An unexpected error occurred during iOS configuration: $e');
    rethrow;
  }
}

Future<void> _configureSwiftAppDelegate(File file, String key) async {
  String content = await file.readAsString();
  final lines = content.split('\n');

  final importStatement = 'import GoogleMaps';
  final apiKeyLinePattern = RegExp(
    r'^\s*GMSServices\.provideAPIKey\s*\(\s*".*"\s*\)',
  );
  final apiKeyLineReplacement = '    GMSServices.provideAPIKey("$key")';

  final didFinishLaunchingPattern = RegExp(
    r'func\s+application\s*\(.*didFinishLaunchingWithOptions.*\)\s*->',
  );
  final openBracePattern = RegExp(r'\{\s*$');
  final returnPattern = RegExp(
    r'return\s+super\.application\s*\(.*didFinishLaunchingWithOptions.*\)|return\s+true',
    caseSensitive: false,
  );

  bool importExists = lines.any((line) => line.trim() == importStatement);
  int apiKeyLineIndex = lines.indexWhere(
    (line) => apiKeyLinePattern.hasMatch(line),
  );

  int didFinishLaunchingLineIndex = -1;
  for (int i = 0; i < lines.length; i++) {
    if (didFinishLaunchingPattern.hasMatch(lines[i])) {
      didFinishLaunchingLineIndex = i;
      break;
    }
  }

  int didFinishLaunchingEndIndex = -1;
  if (didFinishLaunchingLineIndex != -1) {
    for (int i = didFinishLaunchingLineIndex; i < lines.length; i++) {
      if (openBracePattern.hasMatch(lines[i])) {
        didFinishLaunchingEndIndex = i;
        break;
      }
    }
  }

  int returnLineIndex = -1;
  for (int i = 0; i < lines.length; i++) {
    if (returnPattern.hasMatch(lines[i])) {
      returnLineIndex = i;
      break;
    }
  }

  List<String> newLines = List.from(lines);

  if (!importExists) {
    log('Adding "$importStatement"...');

    int importInsertIndex = newLines.indexWhere(
      (line) => line.trim().startsWith('import '),
    );
    if (importInsertIndex == -1) importInsertIndex = 0;

    newLines.insert(importInsertIndex, importStatement);
    if (importInsertIndex == 0 &&
        newLines.length > 1 &&
        newLines[1].trim().isNotEmpty) {
      newLines.insert(importInsertIndex + 1, '');
    }
  }

  if (apiKeyLineIndex != -1) {
    log('Found existing API key line. Updating...');
    newLines[apiKeyLineIndex] = apiKeyLineReplacement;
  } else {
    log('API key line not found. Inserting...');

    if (didFinishLaunchingEndIndex != -1) {
      newLines.insert(didFinishLaunchingEndIndex + 1, apiKeyLineReplacement);
      log('Added API key after application method opening brace.');
    } else if (returnLineIndex != -1) {
      newLines.insert(returnLineIndex, apiKeyLineReplacement);
      log('Added API key before return statement.');
    } else {
      log(
        '❌ Warning: Could not find appropriate location to insert Google Maps API key.',
      );
      log(
        '          Please add the following line manually inside the application delegate method:',
      );
      log('          $apiKeyLineReplacement');
      return;
    }
  }

  await file.writeAsString(newLines.join('\n'));
  log('✅ iOS (Swift) configuration complete.');
}

Future<void> _configureObjcAppDelegate(File file, String key) async {
  String content = await file.readAsString();
  final lines = content.split('\n');

  final importStatement = '#import <GoogleMaps/GoogleMaps.h>';
  final apiKeyLinePattern = RegExp(
    r'^\s*\[\s*GMSServices\s+provideAPIKey\s*:\s*@".*"\s*\]\s*;',
  );
  final apiKeyLineReplacement = '  [GMSServices provideAPIKey:@"$key"];';
  final didFinishLaunchingSignature = '- (BOOL)application:';
  final didFinishLaunchingEndSignature = '{';
  final returnStatement = 'return YES;';

  bool importExists = lines.any((line) => line.trim() == importStatement);
  int apiKeyLineIndex = lines.indexWhere(
    (line) => apiKeyLinePattern.hasMatch(line),
  );
  int didFinishLaunchingLineIndex = lines.indexWhere(
    (line) =>
        line.contains(didFinishLaunchingSignature) &&
        line.contains('didFinishLaunchingWithOptions'),
  );
  int didFinishLaunchingEndIndex = -1;
  if (didFinishLaunchingLineIndex != -1) {
    didFinishLaunchingEndIndex = lines.indexWhere(
      (line) => line.trim() == didFinishLaunchingEndSignature,
      didFinishLaunchingLineIndex,
    );
  }
  int _ = lines.lastIndexWhere((line) => line.trim() == returnStatement);

  List<String> newLines = List.from(lines);

  if (!importExists) {
    log('Adding "$importStatement"...');

    int importInsertIndex = newLines.lastIndexWhere(
      (line) => line.trim().startsWith('#import '),
    );

    if (importInsertIndex == -1) {
      importInsertIndex = 0;
    } else {
      importInsertIndex++;
    }

    newLines.insert(importInsertIndex, importStatement);
    if (newLines.length > importInsertIndex + 1 &&
        newLines[importInsertIndex + 1].trim().isNotEmpty) {
      newLines.insert(importInsertIndex + 1, '');
    }
  }

  if (apiKeyLineIndex != -1) {
    log('Found existing API key line. Updating...');
    newLines[apiKeyLineIndex] = apiKeyLineReplacement;
  } else {
    log('API key line not found. Inserting...');
    if (didFinishLaunchingEndIndex != -1) {
      newLines.insert(didFinishLaunchingEndIndex + 1, apiKeyLineReplacement);

      if (newLines.length > didFinishLaunchingEndIndex + 2 &&
          newLines[didFinishLaunchingEndIndex + 2].trim().isNotEmpty) {
        newLines.insert(didFinishLaunchingEndIndex + 2, '');
      }
    } else {
      log(
        '❌ Warning: Could not find `-application:didFinishLaunchingWithOptions:` method signature or its opening brace correctly.',
      );
      log(
        '          Please add the following line manually inside the method:',
      );
      log('          $apiKeyLineReplacement');

      return;
    }
  }

  await file.writeAsString(newLines.join('\n'));
  log('✅ iOS (Objective-C) configuration complete.');
}
