import 'dart:ffi';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:remotecontrol/services/win32_input.dart';
import 'package:remotecontrol_lib/mixin/subscribable.dart';
import 'package:remotecontrol_lib/virtualkeys.dart';
import 'package:win32/win32.dart';

enum InputReceivedEvent {
  PressKey,
  MoveMouse,
  PressMouseKey,
}

/// Data class for tranaporting input events
abstract class InputReceivedData {
  final InputReceivedEvent event;

  const InputReceivedData(this.event);
}

class MouseMoveReceivedData extends InputReceivedData {
  final double deltaX;
  final double deltaY;
  final double ajustedDeltaX;
  final double ajustedDeltaY;
  final double speed;
  final double acceleration;

  const MouseMoveReceivedData(
    this.deltaX,
    this.deltaY,
    this.ajustedDeltaX,
    this.ajustedDeltaY,
    this.speed,
    this.acceleration,
  ) : super(InputReceivedEvent.MoveMouse);
}

class KeyboardKeyReceivedData extends InputReceivedData {
  final int virtualKeyCode;
  final int interval;
  final KeyActionType? state;

  const KeyboardKeyReceivedData(this.virtualKeyCode, this.interval, {this.state})
      : super(InputReceivedEvent.PressKey);
}

class MouseButtonReceivedData extends InputReceivedData {
  final MBWrapper key;
  final int interval;
  final ButtonActionType? state;

  const MouseButtonReceivedData(this.key, this.interval, {this.state})
      : super(InputReceivedEvent.PressMouseKey);
}

typedef InputEventHandler = void Function(
    InputReceivedEvent event, InputReceivedData data);

class Win32InputService with Subscribable<InputReceivedEvent, InputReceivedData> {
  bool isDebug = false;

  Future<int> sendVirtualKey(int virtualKeyCode, {int interval = 20}) async {
    if (isDebug) {
      var event = KeyboardKeyReceivedData(virtualKeyCode, interval);
      dispatch(InputReceivedEvent.PressKey, event);
      return TRUE;
    }

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
    double adjustedDeltaX = applyMouseCurve(deltaX, speed, acceleration, 0);
    double adjustedDeltaY = applyMouseCurve(deltaY, speed, acceleration, 1);

    if (isDebug) {
      var event = MouseMoveReceivedData(
          deltaX, deltaY, adjustedDeltaX, adjustedDeltaY, speed, acceleration);
      dispatch(InputReceivedEvent.MoveMouse, event);
      return TRUE;
    }

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
    if (isDebug) {
      var event = MouseButtonReceivedData(key, interval);
      dispatch(InputReceivedEvent.PressMouseKey, event);
      return TRUE;
    }

    return mouseClick(key, interval: interval);
  }

  Future<int> sendKeyState(int virtualKeyCode, KeyActionType state) async {
    if (isDebug) {
      var event = KeyboardKeyReceivedData(virtualKeyCode, 0, state: state);
      dispatch(InputReceivedEvent.PressKey, event);
      return TRUE;
    }

    final kbd = calloc<INPUT>();
    kbd.ref.type = INPUT_KEYBOARD;
    kbd.ref.ki.wVk = virtualKeyCode;
    kbd.ref.ki.dwFlags = state == KeyActionType.DOWN ? 0 : KEYEVENTF_KEYUP;

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

  Future<int> sendMouseKeyState(MBWrapper key, ButtonActionType state) async {
    if (isDebug) {
      var event = MouseButtonReceivedData(key, 0, state: state);
      dispatch(InputReceivedEvent.PressMouseKey, event);
      return TRUE;
    }

    final mouse = calloc<INPUT>();
    mouse.ref.type = INPUT_MOUSE;
    mouse.ref.mi.dwFlags = state == KeyActionType.DOWN ? key.keyDown : key.keyUp;

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

  /// [applyMouseCurve] applies a curve to smooth out mouse movement.
  /// the [axis] parameter is used to determine which axis to apply the curve to.
  /// 0 = X, 1 = Y
  double applyMouseCurve(double delta, double speed, double acceleration, int axis) {
    double adjustedDelta = delta * speed * (65535.0 / GetSystemMetrics(SM_CXSCREEN));
    adjustedDelta = adjustedDelta.sign * pow(adjustedDelta.abs(), acceleration);
    return adjustedDelta;
  }
}
