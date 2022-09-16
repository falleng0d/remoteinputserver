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

class MouseKeys {
  static const left = SystemKey(MOUSEEVENTF_LEFTDOWN, MOUSEEVENTF_LEFTUP);
  static const right = SystemKey(MOUSEEVENTF_RIGHTDOWN, MOUSEEVENTF_RIGHTUP);
}

enum ActionType {
  UP,
  DOWN,
  PRESS
}

enum MouseActionType {
  UP,
  DOWN,
  MOVE,
  PRESS
}

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
