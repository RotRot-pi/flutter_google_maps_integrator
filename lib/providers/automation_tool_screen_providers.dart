import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maps_flutter/screens/automation_tool_screen.dart';

final automationStateProvider = StateProvider<AutomationState>(
  (ref) => AutomationState.idle,
);
final automationMessageProvider = StateProvider<String?>((ref) => null);

final skipApiKeyConfigProvider = StateProvider<bool>((ref) => false);
