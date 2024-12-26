import 'package:flutter_test/flutter_test.dart';
import 'package:win32/win32.dart' show VIRTUAL_KEY;
import 'package:remotecontrol_lib/virtualkeys.dart';

import 'virtualkeys.dart';

void main() {
  group('Virtual Key Tests', () {
    test('keyToVk', () {
      expect(keyToVk(Key.KEY_A), equals(VIRTUAL_KEY.VK_A));
      expect(keyToVk(Key.KEY_1), equals(VIRTUAL_KEY.VK_1));
      expect(keyToVk(Key.KEY_Q), equals(VIRTUAL_KEY.VK_Q));
      expect(keyToVk(Key.KEY_L), equals(VIRTUAL_KEY.VK_L));
      expect(keyToVk(Key.KEY_LSHIFT), equals(VIRTUAL_KEY.VK_LSHIFT));
      expect(keyToVk(Key.KEY_RSHIFT), equals(VIRTUAL_KEY.VK_RSHIFT));
      expect(keyToVk(Key.KEY_LSUPER), equals(VIRTUAL_KEY.VK_LWIN));
      expect(keyToVk(Key.KEY_TAB), equals(VIRTUAL_KEY.VK_TAB));
      expect(keyToVk(Key.KEY_TAB), equals(VIRTUAL_KEY.VK_TAB));
    });

    test('vkToKey', () {
      expect(vkToKey(VIRTUAL_KEY.VK_A), equals(Key.KEY_A));
      expect(vkToKey(VIRTUAL_KEY.VK_1), equals(Key.KEY_1));
      expect(vkToKey(VIRTUAL_KEY.VK_Q), equals(Key.KEY_Q));
      expect(vkToKey(VIRTUAL_KEY.VK_TAB), equals(Key.KEY_TAB));
    });

    test('stringToVk', () {
      expect(stringToVk('A'), equals(VIRTUAL_KEY.VK_A));
      expect(stringToVk('1'), equals(VIRTUAL_KEY.VK_1));
      expect(stringToVk('Q'), equals(VIRTUAL_KEY.VK_Q));
      expect(stringToVk('L'), equals(VIRTUAL_KEY.VK_L));
      expect(stringToVk('WIN'), equals(VIRTUAL_KEY.VK_LWIN));
      expect(stringToVk('TAB'), equals(VIRTUAL_KEY.VK_TAB));
    });

    test('vkToString', () {
      expect(vkToString(VIRTUAL_KEY.VK_A), equals('A'));
      expect(vkToString(VIRTUAL_KEY.VK_1), equals('1'));
      expect(vkToString(VIRTUAL_KEY.VK_TAB), equals('TAB'));
    });
  });
}
