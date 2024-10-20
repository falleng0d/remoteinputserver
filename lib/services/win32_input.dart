import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:remotecontrol_lib/logger.dart';
import 'package:remotecontrol_lib/virtualkeys.dart';
import 'package:win32/win32.dart';

const kDebugMode = false;

Future<int> sendVirtualKey(int virtualKeyCode, {int interval = 20}) async {
  if (kDebugMode) return TRUE;

  final kbd = calloc<INPUT>();
  kbd.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
  kbd.ref.ki.wVk = virtualKeyCode;

  var result = SendInput(1, kbd, sizeOf<INPUT>());
  if (result != TRUE) {
    logger.error('[sendVirtualKey] Error: ${GetLastError()}');
    return result;
  }

  await Future.delayed(Duration(milliseconds: interval));

  kbd.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
  result = SendInput(1, kbd, sizeOf<INPUT>());
  if (result != TRUE) {
    logger.error('[sendVirtualKey] Error: ${GetLastError()}');
    return result;
  }

  free(kbd);
  return result;
}

Future<int> sendKeyState(int virtualKeyCode, KeyActionType state) async {
  if (kDebugMode) return TRUE;

  final kbd = calloc<INPUT>();
  kbd.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
  kbd.ref.ki.wVk = virtualKeyCode;
  kbd.ref.ki.dwFlags =
      state == KeyActionType.DOWN ? 0 : KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;

  final result = SendInput(1, kbd, sizeOf<INPUT>());
  if (result != TRUE) {
    logger.error('[sendKeyState] Error: ${GetLastError()}');
    return result;
  }

  free(kbd);
  return result;
}

Future<int> mouseClick(MouseButton key, {int interval = 20}) async {
  final mouse = calloc<INPUT>();

  mouse.ref.type = INPUT_TYPE.INPUT_MOUSE;
  mouse.ref.mi.dwFlags = key.keyDown;
  var result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) {
    if (kDebugMode) {
      logger.error('Error: ${GetLastError()}');
    }
    return result;
  }

  await Future.delayed(Duration(milliseconds: interval));

  mouse.ref.mi.dwFlags = key.keyUp;
  result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) {
    if (kDebugMode) {
      logger.error('Error: ${GetLastError()}');
    }
    return result;
  }

  free(mouse);
  return result;
}

Future<int> sendMouseKeyState(MouseButton key, ButtonActionType state) async {
  if (kDebugMode) return TRUE;

  final mouse = calloc<INPUT>();
  mouse.ref.type = INPUT_TYPE.INPUT_MOUSE;
  mouse.ref.mi.dwFlags = state == ButtonActionType.DOWN ? key.keyDown : key.keyUp;

  final result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) {
    logger.error('[sendMouseKeyState] Error: ${GetLastError()}');
    return result;
  }

  free(mouse);
  return result;
}

Future<int> moveMouseRelative(double deltaX, double deltaY,
    {double speed = 1.0, double acceleration = 1.0}) async {
  if (kDebugMode) return TRUE;

  final mouse = calloc<INPUT>();
  mouse.ref.type = INPUT_TYPE.INPUT_MOUSE;
  mouse.ref.mi.dwFlags = MOUSE_EVENT_FLAGS.MOUSEEVENTF_MOVE;
  mouse.ref.mi.dx = deltaX.toInt();
  mouse.ref.mi.dy = deltaY.toInt();

  final result = SendInput(1, mouse, sizeOf<INPUT>());
  if (result != TRUE) {
    logger.error('[moveMouseRelative] Error: ${GetLastError()}');
    return result;
  }

  free(mouse);
  return result;
}

base class SendInputParameters {}

final class SendVirtualKeyParams extends SendInputParameters {
  final int virtualKeyCode;
  final int interval;

  SendVirtualKeyParams({required this.virtualKeyCode, this.interval = 20});
}

final class SendKeyStateParams extends SendInputParameters {
  final int virtualKeyCode;
  final KeyActionType state;

  SendKeyStateParams({required this.virtualKeyCode, required this.state});
}

final class MouseClickParams extends SendInputParameters {
  final MouseButton key;
  final int interval;

  MouseClickParams({required this.key, this.interval = 20});
}

final class SendMouseKeyStateParams extends SendInputParameters {
  final MouseButton key;
  final ButtonActionType state;

  SendMouseKeyStateParams({required this.key, required this.state});
}

final class MoveMouseRelativeParams extends SendInputParameters {
  final double deltaX;
  final double deltaY;
  final double speed;
  final double acceleration;

  MoveMouseRelativeParams(
      {required this.deltaX,
      required this.deltaY,
      this.speed = 1.0,
      this.acceleration = 1.0});
}

class IsolateParams {
  final Logger logger;
  final SendPort sendPort;

  IsolateParams(this.logger, this.sendPort);
}

/// [SendKeyWorkerIsolate] is used to send virtual keys to a separate isolate
/// thread to avoid blocking the main thread in case of delays.
class SendKeyWorkerIsolate {
  final Logger logger;
  late final Isolate isolate;
  late final SendPort _sendPort;
  final Completer<void> _isolateReady = Completer.sync();
  final Function(int) _onResult;

  SendKeyWorkerIsolate(this._onResult, this.logger) {
    spawn();
  }

  Future<void> spawn() async {
    final receivePort = ReceivePort();
    receivePort.listen(_handleResponsesFromIsolate);
    await Isolate.spawn(_startRemoteIsolate, IsolateParams(logger, receivePort.sendPort));
  }

  void _handleResponsesFromIsolate(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
      _isolateReady.complete();
    } else if (message is int) {
      _onResult(message);
    }
  }

  static void _startRemoteIsolate(IsolateParams params) {
    final receivePort = ReceivePort();
    final port = params.sendPort;
    final logger = params.logger;

    port.send(receivePort.sendPort);

    receivePort.listen((dynamic message) async {
      int result = 0;

      if (message is SendVirtualKeyParams) {
        result = await sendVirtualKey(message.virtualKeyCode, interval: message.interval);
        logger.trace('[SendKeyWorkerIsolate] sendVirtualKey result: $result');
      } else if (message is SendKeyStateParams) {
        result = await sendKeyState(message.virtualKeyCode, message.state);
        logger.trace('[SendKeyWorkerIsolate] sendKeyState result: $result');
      } else if (message is MouseClickParams) {
        result = await mouseClick(message.key, interval: message.interval);
        logger.trace('[SendKeyWorkerIsolate] mouseClick result: $result');
      } else if (message is SendMouseKeyStateParams) {
        result = await sendMouseKeyState(message.key, message.state);
        logger.trace('[SendKeyWorkerIsolate] sendMouseKeyState result: $result');
      } else if (message is MoveMouseRelativeParams) {
        result = await moveMouseRelative(message.deltaX, message.deltaY,
            speed: message.speed, acceleration: message.acceleration);
        logger.trace('[SendKeyWorkerIsolate] moveMouseRelative result: $result');
      } else {
        logger.error('[SendKeyWorkerIsolate] Unknown message: $message');
      }

      port.send(result);
    });
  }

  Future<void> doTask(SendInputParameters message) async {
    await _isolateReady.future;
    _sendPort.send(message);
  }
}
