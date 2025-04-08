import 'dart:developer';
import 'dart:io';

Future<void> injectMapDemoCode(String projectPath) async {
  log('Starting demo code injection...');
  final targetMainPath = '$projectPath/lib/main.dart';
  final targetMapScreenPath = '$projectPath/lib/map_demo_screen.dart';
  final mainImportLine = "import 'map_demo_screen.dart';";
  final mainHomeLineReplacement = 'home: const MapDemoScreen(),';

  const String mapDemoScreenContent = """
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapDemoScreen extends StatefulWidget {
  const MapDemoScreen({super.key});

  @override
  State<MapDemoScreen> createState() => _MapDemoScreenState();
}

class _MapDemoScreenState extends State<MapDemoScreen> {
  GoogleMapController? mapController;
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.4220, -122.0841), 
    zoom: 14.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Demo'),
        backgroundColor: Colors.amber[700],
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        mapType: MapType.normal,
        onMapCreated: (GoogleMapController controller) {
          setState(() {
            mapController = controller;
          });
          if (kDebugMode) {
            print("Map Created in Target Project!");
          }
        },
        markers: {
          Marker(
            markerId: MarkerId('googleplex'),
            position: _initialPosition.target,
            infoWindow: InfoWindow(title: 'Googleplex'),
          ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      ),
    );
  }
}
""";

  try {
    final mapScreenFile = File(targetMapScreenPath);

    await mapScreenFile.parent.create(recursive: true);
    await mapScreenFile.writeAsString(mapDemoScreenContent);
    log('Created $targetMapScreenPath');

    final mainFile = File(targetMainPath);
    if (!await mainFile.exists()) {
      throw FileSystemException('Target main.dart not found', targetMainPath);
    }
    List<String> mainLines = await mainFile.readAsLines();
    List<String> newMainLines = [];
    bool importAdded = false;
    bool homeReplaced = false;

    if (mainLines.any((line) => line.contains(mainImportLine)) &&
        mainLines.any((line) => line.contains(mainHomeLineReplacement))) {
      log('Target main.dart seems already modified for demo. Skipping.');
      return;
    }

    for (String line in mainLines) {
      String trimmedLine = line.trim();

      if (trimmedLine.startsWith('import ') && !importAdded) {
        newMainLines.add(line);

        if (!mainLines.any((l) => l.contains(mainImportLine))) {
          newMainLines.add(mainImportLine);
          log('Added import for MapDemoScreen in main.dart');
        }
        importAdded = true;
        continue;
      }

      if (line.contains('home:') &&
          line.contains('MaterialApp') &&
          !homeReplaced) {
        String indent = line.substring(0, line.indexOf('home:'));
        newMainLines.add('$indent$mainHomeLineReplacement');
        log('Replaced home: argument in main.dart');
        homeReplaced = true;
        continue;
      } else if (line.contains('home:') && !homeReplaced) {
        String indent = line.substring(0, line.indexOf('home:'));
        newMainLines.add('$indent$mainHomeLineReplacement');
        log('Replaced home: argument in main.dart (fallback)');
        homeReplaced = true;
        continue;
      }

      newMainLines.add(line);
    }

    if (!importAdded) {
      log(
        'Warning: Could not find place to add import in main.dart. Adding at top.',
      );
      newMainLines.insert(0, mainImportLine);
    }
    if (!homeReplaced) {
      log(
        'Warning: Could not find home: argument to replace in main.dart. Injection incomplete.',
      );
    }

    await mainFile.writeAsString(newMainLines.join('\n'));
    log('Modified $targetMainPath');
    log('Demo code injection complete.');
  } on FileSystemException catch (e) {
    log('Error during demo injection (File System): ${e.message}');
    rethrow;
  } catch (e) {
    log('An unexpected error occurred during demo injection: $e');
    rethrow;
  }
}
