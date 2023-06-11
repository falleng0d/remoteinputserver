import 'dart:ffi';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:remotecontrol_lib/input/virtualkeys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';

Future<int> mouseClick(MBWrapper key, {int interval = 20}) async {
  final mouse = calloc<INPUT>();

  mouse.ref.type = INPUT_MOUSE;
  mouse.ref.mi.dwFlags = key.keyDown;
  var result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) {
    if (kDebugMode) {
      print('Error: ${GetLastError()}');
    }
    return result;
  }

  await Future.delayed(Duration(milliseconds: interval));

  mouse.ref.mi.dwFlags = key.keyUp;
  result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) {
    if (kDebugMode) {
      print('Error: ${GetLastError()}');
    }
    return result;
  }

  free(mouse);
  return result;
}

void testMouseclick() {
  print('Sending a right-click mouse event.');
  final mouse = calloc<INPUT>();
  mouse.ref.type = INPUT_MOUSE;
  mouse.ref.mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
  var result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  Sleep(1000);
  mouse.ref.mi.dwFlags = MOUSEEVENTF_RIGHTUP;
  result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  free(mouse);
}

void testSendinput() {
  print('Switching to Notepad and going to sleep for a second.');
  ShellExecute(0, TEXT('open'), TEXT('notepad.exe'), nullptr, nullptr, SW_SHOW);
  Sleep(1000);

  print('Sending the "A" key and the Unicode character "€".');
  final kbd = calloc<INPUT>();
  kbd.ref.type = INPUT_KEYBOARD;
  kbd.ref.ki.wVk = VK_A;
  var result = SendInput(1, kbd, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  kbd.ref.ki.dwFlags = KEYEVENTF_KEYUP;
  result = SendInput(1, kbd, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  kbd.ref.ki.wVk = 0;
  kbd.ref.ki.wScan = 0x20AC; // euro sign
  kbd.ref.ki.dwFlags = KEYEVENTF_UNICODE;
  result = SendInput(1, kbd, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  kbd.ref.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
  result = SendInput(1, kbd, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  free(kbd);

  print('Sending a right-click mouse event.');
  final mouse = calloc<INPUT>();
  mouse.ref.type = INPUT_MOUSE;
  mouse.ref.mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
  result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  Sleep(1000);
  mouse.ref.mi.dwFlags = MOUSEEVENTF_RIGHTUP;
  result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) print('Error: ${GetLastError()}');

  free(mouse);
}

class Win32InputService {
  Future<int> sendVirtualKey(int virtualKeyCode, {int interval = 20}) async {
    final kbd = calloc<INPUT>();
    kbd.ref.type = INPUT_KEYBOARD;
    kbd.ref.ki.wVk = virtualKeyCode;

    var result = SendInput(1, kbd, sizeOf<INPUT>());
    if (result != TRUE) {
      if (kDebugMode) {
        print('Error: ${GetLastError()}');
      }
      return result;
    }

    await Future.delayed(Duration(milliseconds: interval));

    kbd.ref.ki.dwFlags = KEYEVENTF_KEYUP;
    result = SendInput(1, kbd, sizeOf<INPUT>());
    if (result != TRUE) {
      if (kDebugMode) {
        print('Error: ${GetLastError()}');
      }
      return result;
    }

    free(kbd);
    return result;
  }

  Future<int> moveMouseRelative(double deltaX, double deltaY,
      {double speed = 1.0, double acceleration = 1.0}) async {
    double adjustedDeltaX = deltaX * speed * (65535.0 / GetSystemMetrics(SM_CXSCREEN));
    double adjustedDeltaY = deltaY * speed * (65535.0 / GetSystemMetrics(SM_CYSCREEN));

    adjustedDeltaX = adjustedDeltaX.sign * pow(adjustedDeltaX.abs(), acceleration);
    adjustedDeltaY = adjustedDeltaY.sign * pow(adjustedDeltaY.abs(), acceleration);

    final mouse = calloc<INPUT>();
    mouse.ref.type = INPUT_MOUSE;
    mouse.ref.mi.dwFlags = MOUSEEVENTF_MOVE;
    mouse.ref.mi.dx = adjustedDeltaX.toInt();
    mouse.ref.mi.dy = adjustedDeltaY.toInt();

    final result = SendInput(1, mouse, sizeOf<INPUT>());
    if (result != TRUE) {
      if (kDebugMode) {
        print('Error: ${GetLastError()}');
      }
      return result;
    }

    free(mouse);
    return result;
  }

  Future<int> pressMouseKey(MBWrapper key, {int interval = 20}) async {
    return mouseClick(key, interval: interval);
  }

  Future<int> sendKeyState(int virtualKeyCode, KeyState state) async {
    final kbd = calloc<INPUT>();
    kbd.ref.type = INPUT_KEYBOARD;
    kbd.ref.ki.wVk = virtualKeyCode;
    kbd.ref.ki.dwFlags = state == KeyState.DOWN ? 0 : KEYEVENTF_KEYUP;

    final result = SendInput(1, kbd, sizeOf<INPUT>());
    if (result != TRUE) {
      if (kDebugMode) {
        print('Error: ${GetLastError()}');
      }
      return result;
    }

    free(kbd);
    return result;
  }

  Future<int> sendMouseKeyState(MBWrapper key, KeyState state) async {
    final mouse = calloc<INPUT>();
    mouse.ref.type = INPUT_MOUSE;
    mouse.ref.mi.dwFlags = state == KeyState.DOWN ? key.keyDown : key.keyUp;

    final result = SendInput(1, mouse, sizeOf<INPUT>());
    if (result != TRUE) {
      if (kDebugMode) {
        print('Error: ${GetLastError()}');
      }
      return result;
    }

    free(mouse);
    return result;
  }
}

class InputConfig extends GetxService {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool _initialized = false;

  double _cursorSpeed = 1.0;
  double _cursorAcceleration = 1.0;
  int _keyPressInterval = 50;

  double get cursorSpeed => _cursorSpeed;
  double get cursorAcceleration => _cursorAcceleration;
  int get keyPressInterval => _keyPressInterval;

  RxInt updateNotifier = RxInt(0);

  final _isDebug = false.obs;
  set isDebug(bool value) => _isDebug.value = value;
  bool get isDebug => _isDebug.value;

  InputConfig();

  /// Loads the configuration from the shared preferences.
  /// Must be called before using the configuration.
  Future<InputConfig> load() async {
    final prefs = await _prefs;
    _cursorSpeed = prefs.getDouble('cursorSpeed') ?? cursorSpeed;
    _cursorAcceleration = prefs.getDouble('cursorAcceleration') ?? cursorAcceleration;
    _keyPressInterval = prefs.getInt('keyPressInterval') ?? keyPressInterval;
    _initialized = true;
    return this;
  }

  void notify() {
    updateNotifier.value++;
  }

  Future<bool> setCursorSpeed(double speed) async {
    if (!(_initialized)) throw Exception('_prefs not initialized!');
    final prefs = await _prefs;
    if (await prefs.setDouble('cursorSpeed', speed)) {
      _cursorSpeed = speed;
      notify();

      return true;
    }

    return false;
  }

  Future<bool> setCursorAcceleration(double acceleration) async {
    if (!(_initialized)) throw Exception('_prefs not initialized!');
    final prefs = await _prefs;
    if (await prefs.setDouble('cursorAcceleration', acceleration)) {
      _cursorAcceleration = acceleration;
      notify();

      return true;
    }

    return false;
  }

  Future<bool> setKeyPressInterval(int interval) async {
    if (!(_initialized)) throw Exception('_prefs not initialized!');
    final prefs = await _prefs;
    if (await prefs.setInt('keyPressInterval', interval)) {
      _keyPressInterval = interval;
      notify();

      return true;
    }

    return false;
  }
}
