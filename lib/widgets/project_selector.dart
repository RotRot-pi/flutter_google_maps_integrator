import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maps_flutter/providers/project_selector_providers.dart';

class ProjectSelector extends ConsumerWidget {
  const ProjectSelector({super.key});

  Future<void> _pickProjectDirectory(WidgetRef ref) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Flutter Project Directory',
      );

      if (selectedDirectory != null) {
        final pubspecPath = '$selectedDirectory/pubspec.yaml';
        final pubspecFile = File(pubspecPath);

        if (await pubspecFile.exists()) {
          ref.read(projectPathProvider.notifier).state = selectedDirectory;
          ref.read(validationProvider.notifier).state = null;
          log('Selected project path: $selectedDirectory');
        } else {
          ref.read(projectPathProvider.notifier).state = null;
          ref.read(validationProvider.notifier).state =
              'Error: pubspec.yaml not found in the selected directory.';
          log('Validation Error: pubspec.yaml not found.');
        }
      } else {
        log('Directory selection cancelled.');

        ref.read(projectPathProvider.notifier).state = null;
        ref.read(validationProvider.notifier).state = 'Selection cancelled.';
      }
    } catch (e) {
      log('Error picking directory: $e');
      ref.read(projectPathProvider.notifier).state = null;
      ref.read(validationProvider.notifier).state =
          'Error picking directory: $e';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPath = ref.watch(projectPathProvider);
    final validationMessage = ref.watch(validationProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ElevatedButton.icon(
            icon: Icon(Icons.folder_open),
            label: Text('Select Flutter Project Directory'),
            onPressed: () => _pickProjectDirectory(ref),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Selected Path:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          Text(
            selectedPath ?? 'No directory selected',
            style: TextStyle(
              color: selectedPath != null ? Colors.green : Colors.grey,
              fontFamily: 'monospace',
            ),
          ),
          SizedBox(height: 10),

          if (validationMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                validationMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
