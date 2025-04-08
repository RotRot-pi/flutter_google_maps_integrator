import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maps_flutter/providers/api_key_provider.dart';
import 'package:maps_flutter/providers/project_selector_providers.dart';
import 'package:maps_flutter/utils/configure_android.dart';
import 'package:maps_flutter/utils/configure_ios.dart';

class ApiKeyInput extends ConsumerWidget {
  const ApiKeyInput({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKey = ref.watch(apiKeyProvider);
    final projectPath = ref.watch(projectPathProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Google Maps API Key:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'YOUR_API_KEY',

              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            obscureText: true,
            onChanged: (value) {
              ref.read(apiKeyProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Note: The key will be added to AndroidManifest.xml and AppDelegate.swift/Info.plist.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed:
                apiKey.isNotEmpty && projectPath != null
                    ? () async {
                      String key = ref.read(apiKeyProvider);

                      String? currentProjectPath = ref.read(
                        projectPathProvider,
                      );
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      if (currentProjectPath != null && key.isNotEmpty) {
                        try {
                          log('Manual Configuration: Starting Android...');
                          await configureAndroid(currentProjectPath, key);
                          log('Manual Configuration: Android Complete.');

                          log('Manual Configuration: Starting iOS...');
                          await configureIOS(currentProjectPath, key);
                          log('Manual Configuration: iOS Complete.');

                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                '✅ Platform configuration attempt successful!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          log('Manual Configuration Error: $e');
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '❌ Configuration failed: ${e.toString()}',
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          });
                        }
                      }
                    }
                    : null,
            child: const Text('Configure Platforms'),
          ),
        ],
      ),
    );
  }
}
