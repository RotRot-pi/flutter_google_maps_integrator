import 'dart:developer';
import 'dart:io';

import 'package:xml/xml.dart';

Future<void> configureAndroid(String projectPath, String key) async {
  final androidManifestPath =
      '$projectPath/android/app/src/main/AndroidManifest.xml';
  const apiKeyName = 'com.google.android.geo.API_KEY';
  final metaDataNameAttribute = 'android:name';
  final metaDataValueAttribute = 'android:value';

  log('Starting Android configuration...');

  try {
    final androidManifestFile = File(androidManifestPath);
    if (!await androidManifestFile.exists()) {
      throw FileSystemException(
        'AndroidManifest.xml not found at path',
        androidManifestPath,
      );
    }
    String androidManifestContent = await androidManifestFile.readAsString();

    XmlDocument document;
    try {
      document = XmlDocument.parse(androidManifestContent);
    } catch (e) {
      throw FormatException('Failed to parse AndroidManifest.xml: $e');
    }

    XmlElement? applicationElement;
    try {
      applicationElement =
          document.rootElement.findElements('application').firstOrNull;
    } catch (e) {
      log(
        'Error finding application element, checking direct children of root.',
      );
      applicationElement = document.children.whereType<XmlElement>().firstWhere(
        (node) => node.name.local == 'application',
        orElse:
            () =>
                throw StateError(
                  '<application> tag not found in AndroidManifest.xml',
                ),
      );
    }

    if (applicationElement == null) {
      throw StateError('<application> tag not found in AndroidManifest.xml');
    }

    // Fix: Check if the meta-data element exists before trying to update it
    final existingMetaDataElements =
        applicationElement
            .findElements('meta-data')
            .where(
              (node) => node.getAttribute(metaDataNameAttribute) == apiKeyName,
            )
            .toList();

    if (existingMetaDataElements.isNotEmpty) {
      // Update existing meta-data element
      log('Found existing API key meta-data. Updating value...');
      existingMetaDataElements.first.setAttribute(metaDataValueAttribute, key);
    } else {
      // Create new meta-data element
      log('No existing API key meta-data found. Creating new element...');
      final metaDataBuilder = XmlBuilder();
      metaDataBuilder.element(
        'meta-data',
        nest: () {
          metaDataBuilder.attribute(metaDataNameAttribute, apiKeyName);
          metaDataBuilder.attribute(metaDataValueAttribute, key);
        },
      );
      final newMetaDataElement = metaDataBuilder.buildFragment();
      applicationElement.children.add(newMetaDataElement);
    }

    await androidManifestFile.writeAsString(
      document.toXmlString(pretty: true, indent: '  '),
    );

    log('✅ Android configuration complete.');
  } on FileSystemException catch (e) {
    log('❌ Error accessing AndroidManifest.xml: ${e.message}');
    log('  Path: ${e.path}');
    rethrow;
  } on FormatException catch (e) {
    log('❌ Error parsing AndroidManifest.xml: ${e.message}');
    rethrow;
  } on StateError catch (e) {
    log('❌ Error processing AndroidManifest.xml structure: ${e.message}');
    rethrow;
  } catch (e) {
    log('❌ An unexpected error occurred during Android configuration: $e');
    rethrow;
  }
}
