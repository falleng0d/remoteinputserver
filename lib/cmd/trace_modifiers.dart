import 'dart:io';

import 'package:remotecontrol/win32vk.dart';
import 'package:remotecontrol_lib/logger.dart';

import '../services/win32_input_service.dart';

main() {
  final win32InputService = Win32InputService(logger);

  while (true) {
    printModifierStates(win32InputService);

    sleep(const Duration(milliseconds: 100));

    // clear console
    print("\x1B[2J\x1B[0;0H");
  }
}

printModifierStates(Win32InputService service) {
  final Map<int, int> modifierStates = service.getModifierStates();

  for (var entry in modifierStates.entries) {
    final modifier = vkToString(entry.key);
    final state = entry.value;

    print("modifier: $modifier, state: $state");
  }
}
