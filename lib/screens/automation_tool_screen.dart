import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maps_flutter/providers/api_key_provider.dart';
import 'package:maps_flutter/providers/automation_tool_screen_providers.dart';
import 'package:maps_flutter/providers/project_selector_providers.dart';
import 'package:maps_flutter/utils/configure_android.dart';
import 'package:maps_flutter/utils/configure_ios.dart';
import 'dart:developer';

import '../widgets/project_selector.dart';
import '../widgets/api_key_input.dart';
import '../utils/add_google_map_dependicies.dart';
import '../utils/inject_map_demo_code.dart';

enum AutomationState {
  idle,
  projectSelected,
  apiKeyEntered,
  integratingDeps,
  runningPubGet,
  configuringAndroid,
  configuringIOS,
  injectingDemo,
  complete,
  error,
}

class AutomationToolScreen extends ConsumerWidget {
  const AutomationToolScreen({super.key});

  Future<void> _runFullAutomation(WidgetRef ref, BuildContext context) async {
    final projectPath = ref.read(projectPathProvider);
    final apiKey = ref.read(apiKeyProvider);

    final skipApiKeyConfig = ref.read(skipApiKeyConfigProvider);
    final notifier = ref.read(automationStateProvider.notifier);
    final messageNotifier = ref.read(automationMessageProvider.notifier);

    if (projectPath == null || (!skipApiKeyConfig && apiKey.isEmpty)) {
      messageNotifier.state =
          "Error: Project path is missing, or API key is missing and skipping is not selected.";
      notifier.state = AutomationState.error;
      log(
        "Automation Error: Project path missing, or API key missing and not skipping.",
      );
      _showCompletionDialog(context, "Error!", messageNotifier.state!);
      return;
    }

    messageNotifier.state = null;

    try {
      notifier.state = AutomationState.integratingDeps;
      messageNotifier.state = "Adding google_maps_flutter dependency...";
      log("Step 2a: Adding dependency...");
      bool depAdded = await addGoogleMapsDependency(projectPath);
      if (!depAdded) {
        throw Exception("Failed to add dependency to pubspec.yaml.");
      }

      notifier.state = AutomationState.runningPubGet;
      messageNotifier.state =
          "Running flutter pub get (this may take a moment)...";
      log("Step 2b: Running flutter pub get...");
      bool pubGetSuccess = await runFlutterPubGet(projectPath);
      if (!pubGetSuccess) throw Exception("Failed to run flutter pub get.");

      if (skipApiKeyConfig) {
        notifier.state = AutomationState.configuringAndroid;
        messageNotifier.state = "Skipping Android configuration...";
        log("Step 4a: Skipping Android configuration...");
        await Future.delayed(const Duration(milliseconds: 100));

        notifier.state = AutomationState.configuringIOS;
        messageNotifier.state = "Skipping iOS configuration...";
        log("Step 4b: Skipping iOS configuration...");
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        notifier.state = AutomationState.configuringAndroid;
        messageNotifier.state = "Configuring Android (AndroidManifest.xml)...";
        log("Step 4a: Configuring Android...");
        await configureAndroid(projectPath, apiKey);

        notifier.state = AutomationState.configuringIOS;
        messageNotifier.state = "Configuring iOS (AppDelegate.swift)...";
        log("Step 4b: Configuring iOS...");
        await configureIOS(projectPath, apiKey);
      }

      notifier.state = AutomationState.injectingDemo;
      messageNotifier.state =
          "Injecting demo map screen file (map_demo_screen.dart)...";
      log("Step 5: Injecting demo code file...");
      await injectMapDemoCode(projectPath);

      notifier.state = AutomationState.complete;
      final configStatus =
          skipApiKeyConfig
              ? "API key configuration was SKIPPED."
              : "API key configuration attempted.";
      final successMsg = """Automation Complete!
$configStatus
Check the target project: $projectPath""";
      messageNotifier.state = successMsg;
      log(
        "Automation successfully completed (manual main.dart update needed). Config skipped: $skipApiKeyConfig",
      );

      SchedulerBinding.instance.addPostFrameCallback((_) {
        _showCompletionDialog(
          context,
          "Success (Manual Step Required)",
          successMsg,
        );
      });
    } catch (e) {
      notifier.state = AutomationState.error;
      final errorMsg = "Error during automation: ${e.toString()}";
      messageNotifier.state = errorMsg;
      log("Automation Error: $e");
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _showCompletionDialog(context, "Error!", errorMsg);
      });
    }
  }

  void _showCompletionDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(shrinkWrap: true, children: [Text(content)]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectPath = ref.watch(projectPathProvider);
    final validationError = ref.watch(validationProvider);
    final apiKey = ref.watch(apiKeyProvider);
    final automationState = ref.watch(automationStateProvider);
    final automationMessage = ref.watch(automationMessageProvider);

    final skipApiKeyConfig = ref.watch(skipApiKeyConfigProvider);

    bool canRunAutomation =
        projectPath != null &&
        (apiKey.isNotEmpty || skipApiKeyConfig) &&
        (automationState == AutomationState.apiKeyEntered ||
            automationState == AutomationState.idle ||
            automationState == AutomationState.projectSelected ||
            automationState == AutomationState.complete ||
            automationState == AutomationState.error);

    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Google Maps Integrator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Step 1: Select Project",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ProjectSelector(),
            const SizedBox(height: 20),

            if (projectPath != null && validationError == null) ...[
              const Text(
                "Step 2: Enter API Key (or Skip)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ApiKeyInput(),

              CheckboxListTile(
                title: const Text("Skip API Key Configuration"),
                subtitle: const Text(
                  "Select this if API keys are already configured in the target project.",
                ),
                value: skipApiKeyConfig,
                onChanged: (bool? value) {
                  ref.read(skipApiKeyConfigProvider.notifier).state =
                      value ?? false;

                  if (value == true) {
                    ref.read(automationStateProvider.notifier).state =
                        AutomationState.apiKeyEntered;
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),

              const Text(
                "Step 3: Run Integration",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Center(
                child: ElevatedButton.icon(
                  icon:
                      automationState == AutomationState.complete
                          ? const Icon(Icons.check_circle_outline)
                          : const Icon(Icons.play_circle_fill),
                  label: Text(
                    automationState == AutomationState.complete
                        ? 'Run Again'
                        : 'Start Integration Process',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canRunAutomation ? Colors.green : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),

                  onPressed:
                      canRunAutomation
                          ? () => _runFullAutomation(ref, context)
                          : null,
                ),
              ),
              const SizedBox(height: 20),

              if (automationState != AutomationState.idle &&
                  automationState != AutomationState.projectSelected &&
                  automationState != AutomationState.apiKeyEntered) ...[
                const Text(
                  "Status:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (automationState != AutomationState.complete &&
                    automationState != AutomationState.error)
                  const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color:
                        automationState == AutomationState.error
                            ? Colors.red.shade50
                            : (automationState == AutomationState.complete
                                ? Colors.green.shade50
                                : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color:
                          automationState == AutomationState.error
                              ? Colors.red.shade200
                              : (automationState == AutomationState.complete
                                  ? Colors.green.shade200
                                  : Colors.blue.shade200),
                    ),
                  ),
                  child: Text(
                    automationMessage ??
                        "Current state: ${automationState.name}",
                    style: TextStyle(
                      color:
                          automationState == AutomationState.error
                              ? Colors.red.shade800
                              : Colors.black87,
                    ),
                  ),
                ),
              ],
            ] else if (validationError != null) ...[
              Text(
                validationError,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
