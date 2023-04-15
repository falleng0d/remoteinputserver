import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

const VK_A = 0x41;

class SystemKey {
  final int keyDown;
  final int keyUp;
  const SystemKey(this.keyDown, this.keyUp);
}

const SK_MOUSE_LEFT = SystemKey(MOUSEEVENTF_LEFTDOWN, MOUSEEVENTF_LEFTUP);
const SK_MOUSE_RIGHT = SystemKey(MOUSEEVENTF_RIGHTDOWN, MOUSEEVENTF_RIGHTUP);
const SK_MOUSE_MIDDLE = SystemKey(MOUSEEVENTF_MIDDLEDOWN, MOUSEEVENTF_MIDDLEUP);

class MouseKeys {
  static const left = SK_MOUSE_LEFT;
  static const right = SK_MOUSE_RIGHT;
  static const middle = SK_MOUSE_MIDDLE;
}

enum ActionType { UP, DOWN, PRESS }

enum MouseActionType { UP, DOWN, MOVE, PRESS }

enum KeyState { UP, DOWN }

class KBAction {
  final ActionType type;
  final int value;

  const KBAction(this.type, {this.value = 1});
}

class MBAction {
  final ActionType type;
  final double x;
  final double y;

  const MBAction(this.type, {this.x = 0, this.y = 0});
}

Future<int> mouseClick(SystemKey key, {int interval = 50}) async {
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
  Future<int> sendVirtualKey(int virtualKeyCode, {int interval = 50}) async {
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

  Future<int> moveMouseRelative(double deltaX, double deltaY) async {
    final mouse = calloc<INPUT>();
    mouse.ref.type = INPUT_MOUSE;
    mouse.ref.mi.dwFlags = MOUSEEVENTF_MOVE;
    mouse.ref.mi.dx =
        (deltaX * (65535.0 / GetSystemMetrics(SM_CXSCREEN))).toInt();
    mouse.ref.mi.dy =
        (deltaY * (65535.0 / GetSystemMetrics(SM_CYSCREEN))).toInt();

    var result = SendInput(1, mouse, sizeOf<INPUT>());
    if (result != TRUE) {
      if (kDebugMode) {
        print('Error: ${GetLastError()}');
      }
      return result;
    }

    free(mouse);
    return result;
  }

  Future<int> pressMouseKey(SystemKey key, {int interval = 50}) async {
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

  Future<int> sendMouseKeyState(SystemKey key, KeyState state) async {
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
