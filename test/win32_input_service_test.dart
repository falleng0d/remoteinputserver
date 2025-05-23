import 'package:flutter_test/flutter_test.dart';
import 'package:remotecontrol/services/win32_input_service.dart';
import 'package:remotecontrol/win32vk.dart';
import 'package:remotecontrol_lib/logger.dart';
import 'package:remotecontrol_lib/virtualkeys.dart';

main() {
  group("modifiers", () {
    final win32InputService = Win32InputService(logger);

    test("getActiveModifiers", () {
      final shiftKey = stringToVk("shift");

      // activate shift key
      win32InputService.sendKeyState(shiftKey, KeyActionType.DOWN);

      // get modifiers state
      final List<int> activeModifiersVks = win32InputService.getActiveModifiers();

      // release shift key
      win32InputService.sendKeyState(shiftKey, KeyActionType.UP);

      // check if shift key is active
      print("activeModifiersVks: ${activeModifiersVks.map((e) => vkToString(e)).toList()}");

      expect(activeModifiersVks.contains(shiftKey), true);
      expect(activeModifiersVks.length, 1);
    });

    test("isModifierActive", () {
      final shiftKey = stringToVk("shift");

      // activate shift key
      win32InputService.sendKeyState(shiftKey, KeyActionType.DOWN);

      // check if shift key is active
      final bool isShiftActive = win32InputService.isModifierActive(shiftKey);

      // release shift key
      win32InputService.sendKeyState(shiftKey, KeyActionType.UP);

      expect(isShiftActive, true);
    });
  });

  // after all
  tearDownAll(() {
    print("tearDownAll");
  });
}
