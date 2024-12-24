import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:remotecontrol/services/win32_input.dart';
import 'package:remotecontrol_lib/client.dart';
import 'package:remotecontrol_lib/logger.dart';
import 'package:remotecontrol_lib/mixin/subscribable.dart';
import 'package:remotecontrol_lib/values/hotkey_steps.dart';
import 'package:remotecontrol_lib/virtualkeys.dart';
import 'package:synchronized/synchronized.dart';
import 'package:win32/win32.dart';

import 'input_config.dart';

/* region Events */
enum InputReceivedEvent {
  PressKey,
  MoveMouse,
  PressMouseKey,
}

/// Data class for trasporting input events
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
  final ButtonFlags key;
  final int interval;
  final ButtonActionType? state;

  const MouseButtonReceivedData(this.key, this.interval, {this.state})
      : super(InputReceivedEvent.PressMouseKey);
}

typedef InputEventHandler = void Function(
    InputReceivedEvent event, InputReceivedData data);
/* endregion */

class Win32InputService with Subscribable<InputReceivedEvent, InputReceivedData> {
  final Logger logger;

  bool isDebug = false;

  late final SendKeyWorkerIsolate _sendKeyWorkerIsolate;

  Win32InputService(this.logger) {
    _sendKeyWorkerIsolate = SendKeyWorkerIsolate((int a) {}, logger);
  }

  Future<int> sendVirtualKey(int virtualKeyCode, {int interval = 20}) async {
    dispatch(
      InputReceivedEvent.PressKey,
      KeyboardKeyReceivedData(virtualKeyCode, interval),
    );

    if (isDebug) return TRUE;

    await _sendKeyWorkerIsolate
        .doTask(SendVirtualKeyParams(virtualKeyCode: virtualKeyCode, interval: interval));

    return TRUE;
  }

  Future<int> sendKeyState(int virtualKeyCode, KeyActionType state) async {
    dispatch(
      InputReceivedEvent.PressKey,
      KeyboardKeyReceivedData(virtualKeyCode, 0, state: state),
    );

    if (isDebug) return TRUE;

    await _sendKeyWorkerIsolate
        .doTask(SendKeyStateParams(virtualKeyCode: virtualKeyCode, state: state));

    return TRUE;
  }

  Future<int> moveMouseRelative(double deltaX, double deltaY,
      {double speed = 1.0, double acceleration = 1.0}) async {
    double adjustedDeltaX = applyExponentialMouseCurve2(deltaX, speed, acceleration, 0);
    double adjustedDeltaY = applyExponentialMouseCurve2(deltaY, speed, acceleration, 1);

    dispatch(
      InputReceivedEvent.MoveMouse,
      MouseMoveReceivedData(
        deltaX,
        deltaY,
        adjustedDeltaX,
        adjustedDeltaY,
        speed,
        acceleration,
      ),
    );

    if (isDebug) return TRUE;

    await _sendKeyWorkerIsolate.doTask(
      MoveMouseRelativeParams(
        deltaX: adjustedDeltaX,
        deltaY: adjustedDeltaY,
        speed: speed,
        acceleration: acceleration,
      ),
    );

    return TRUE;
  }

  Future<int> pressMouseKey(ButtonFlags key, {int interval = 20}) async {
    dispatch(
      InputReceivedEvent.PressMouseKey,
      MouseButtonReceivedData(key, interval),
    );

    if (isDebug) return TRUE;

    await _sendKeyWorkerIsolate.doTask(MouseClickParams(key: key, interval: interval));

    return TRUE;
  }

  Future<int> sendMouseKeyState(ButtonFlags key, ButtonActionType state) async {
    dispatch(
      InputReceivedEvent.PressMouseKey,
      MouseButtonReceivedData(key, 0, state: state),
    );

    if (isDebug) return TRUE;

    await _sendKeyWorkerIsolate.doTask(SendMouseKeyStateParams(key: key, state: state));

    return TRUE;
  }

  Map<int, int> getModifierStates() {
    final modifiers = getVkModifiers();
    final modifierStates = <int, int>{};

    for (final vk in modifiers) {
      final result = GetKeyState(vk);
      modifierStates[vk] = result;
    }

    return modifierStates;
  }

  List<int> getActiveModifiers() {
    final modifierStates = getModifierStates();
    final activeModifiers = <int>[];

    for (final vk in modifierStates.keys) {
      final state = modifierStates[vk]!;
      if (state < 0) {
        activeModifiers.add(vk);
      }
    }

    return activeModifiers;
  }

  bool isModifierActive(int vk) {
    final modifierStates = getModifierStates();
    if (!modifierStates.containsKey(vk)) {
      return false;
    }

    return modifierStates[vk]! < 0;
  }

  /// [applyExponentialMouseCurve] applies a curve to smooth out mouse movement.
  /// the [axis] parameter is used to determine which axis to apply the curve to.
  /// 0 = X, 1 = Y
  double applyExponentialMouseCurve(
      double delta, double speed, double acceleration, int axis) {
    double adjustedDelta =
        delta * speed * (65535.0 / GetSystemMetrics(SYSTEM_METRICS_INDEX.SM_CXSCREEN));
    adjustedDelta = adjustedDelta.sign * pow(adjustedDelta.abs(), acceleration);
    return adjustedDelta;
  }

  /// [applyExponentialMouseCurve2] is an alternative implementation of the
  /// mouse curve function. It is more aggressive and has a different curve.
  ///
  /// TODO: Remove the commented code.
  double applyExponentialMouseCurve2(
      double delta, double speed, double acceleration, int axis) {
    // delta = delta * 2.1249999920837581659;
    // delta = (delta * 10).round() / 10;
    // final offsetType = axis == 0 ? SM_CXSCREEN : SM_CYSCREEN;
    // final offset = (65535.0 / GetSystemMetrics(offsetType));
    const offset = 2.1249999920837581659;
    double adjustedDeltaPreAccel = (delta) * 1 * offset;
    adjustedDeltaPreAccel += adjustedDeltaPreAccel.sign * (speed - 0.10);
    double adjustedDelta = adjustedDeltaPreAccel.sign *
        pow(adjustedDeltaPreAccel.abs(), 2 + ((acceleration - 0.10) * 2));
    // round to nearest multiple of .000X
    adjustedDelta = (adjustedDelta * 10).round() / 10;
    // logger.log(
    //     'adjustedDelta: $adjustedDelta->${adjustedDelta.round()}, adjustedDeltaPreAccel: $adjustedDeltaPreAccel, delta: $delta, offset: $offset');
    return adjustedDelta.abs() > 0
        ? adjustedDelta.sign * (adjustedDelta.abs() + 1)
        : adjustedDelta;
  }
}

class _KeyTracker {
  final int vk;

  KeyState state;
  bool suspended = false;

  DateTime? downSince;
  DateTime? lastKeepAlive;

  _KeyTracker(
      {required this.vk, required this.state, this.downSince, this.lastKeepAlive});
}

class _HotkeyTracker {
  final String hotkey;

  KeyState state;

  _HotkeyTracker({required this.hotkey, required this.state});
}

/// [KeyboardInputService] is a service that handles keyboard input.
/// It uses a [Win32InputService] to send input to the system while adding
/// extra functionality for handling:
/// - Modifier keys
/// - Key combinations (e.g. Ctrl + C)
/// - Key sequences (e.g. Ctrl + C, Ctrl + V)
/// - Key repeats
class KeyboardInputService extends GetxService {
  final Win32InputService _inputService;
  final KeyboardInputConfig _config;
  final Logger logger;

  Map<int, Timer> keyRepeatTimers = {};
  Map<int, _KeyTracker> keyStates = {};
  Map<int, _KeyTracker> modifierStates = {};
  Map<String, _HotkeyTracker> hotkeyStates = {};

  // Lock synchronizing key presses
  final _keyLock = Lock();

  get isDebug => _config.isDebug;

  KeyboardInputService(this._inputService, this._config, this.logger);

  void _cancelKeyRepeat(int virtualKeyCode) {
    if (keyRepeatTimers.containsKey(virtualKeyCode)) {
      keyRepeatTimers[virtualKeyCode]?.cancel();
      keyRepeatTimers.remove(virtualKeyCode);
    }
  }

  void _keyPressed(int virtualKeyCode) {
    if (!keyStates.containsKey(virtualKeyCode)) {
      keyStates[virtualKeyCode] = _KeyTracker(
        vk: virtualKeyCode,
        state: KeyState.DOWN,
        downSince: DateTime.now(),
        lastKeepAlive: DateTime.now(),
      );

      if (EnIntKbMapper.isModifier(virtualKeyCode)) {
        modifierStates[virtualKeyCode] = keyStates[virtualKeyCode]!;
      }

      return;
    }

    final keyState = keyStates[virtualKeyCode]!;

    if (EnIntKbMapper.isModifier(virtualKeyCode)) {
      modifierStates[virtualKeyCode] = keyState;
    }

    if (keyState.state == KeyState.DOWN) {
      keyState.lastKeepAlive = DateTime.now();

      return;
    }

    keyState.state = KeyState.DOWN;
    keyState.downSince = DateTime.now();
    keyState.lastKeepAlive = DateTime.now();
  }

  void _keyReleased(int virtualKeyCode) {
    if (!keyStates.containsKey(virtualKeyCode)) {
      return;
    }

    final keyState = keyStates[virtualKeyCode]!;

    if (keyState.state == KeyState.DOWN) {
      keyState.state = KeyState.UP;
      keyState.lastKeepAlive = null;
      keyState.downSince = null;
    }

    if (EnIntKbMapper.isModifier(virtualKeyCode)) {
      modifierStates[virtualKeyCode] = keyStates[virtualKeyCode]!;
    }
  }

  bool isKeyPressed(int virtualKeyCode) {
    return keyStates.containsKey(virtualKeyCode) &&
        keyStates[virtualKeyCode]!.state == KeyState.DOWN;
  }

  Future<List<_KeyTracker>> _suspendModifierKeys(
      List<_KeyTracker> unwantedModifiers) async {
    return await Future.wait(modifierStates.entries
        .where((m) => m.value.state == KeyState.DOWN && !m.value.suspended)
        .map((entry) async {
      final keyState = entry.value;

      await _inputService.sendKeyState(entry.key, KeyActionType.UP);
      keyState.suspended = true;

      return keyState;
    }));
  }

  Future<List<_KeyTracker>> _resumeModifierKeys(List<_KeyTracker> modifiers) async {
    return await Future.wait(modifiers.map((keyState) async {
      if (keyState.suspended) {
        keyState.suspended = false;
      }

      if (keyState.state != KeyState.DOWN) {
        await _inputService.sendKeyState(keyState.vk, KeyActionType.DOWN);
        keyState.state = KeyState.DOWN;
      }

      return keyState;
    }));
  }

  Future<List<_KeyTracker>> _sendTemporaryModifiers(List<int> modifiers) async {
    return await Future.wait(modifiers.map((modifier) async {
      if (modifierStates.containsKey(modifier)) {
        final modifierState = modifierStates[modifier]!;
        if (modifierState.state == KeyState.DOWN) {
          modifierState.lastKeepAlive = DateTime.now();
          return modifierState;
        }
      }
      await _sendVirtualKey(modifier, KeyActionType.DOWN);
      return modifierStates[modifier]!;
    }));
  }

  Future<List<_KeyTracker>> _disableTemporaryModifiers(
      List<_KeyTracker> modifiers) async {
    return await Future.wait(modifiers.map((keyState) async {
      await _sendVirtualKey(keyState.vk, KeyActionType.UP);
      return keyState;
    }));
  }

  void _scheduleKeyRepeat(
      int virtualKeyCode, Duration keyRepeatDelay, Duration keyRepeatInterval) {
    keyRepeatTimers[virtualKeyCode] = Timer(keyRepeatDelay, () async {
      keyRepeatTimers[virtualKeyCode] = Timer.periodic(keyRepeatInterval, (timer) async {
        await _inputService.sendVirtualKey(
          virtualKeyCode,
          interval: _config.keyPressInterval,
        );
      });
    });
  }

  /// Guarantees that when the action is executed only the modifiers in the
  /// modifiers list are pressed. All other modifiers are suspended and reenabled
  /// after the action is executed.
  Future<T> doWithModifiers<T>(List<int> modifiers, Future<T> Function() action) async {
    logger.log('doWithModifiers: ${modifiers.map((m) => EnIntKbMapper.keyToString(m)).toList()}');
    // unwantedModifiers are modifiers that are currently pressed but are not
    // in the modifiers list of the key action. They should be suspended.
    final unwantedModifiers = modifierStates.entries
        .map((m) => m.value)
        .where((m) => m.state == KeyState.DOWN && !modifiers.contains(m.vk))
        .toList();

    final unwantedSuspendedModifiers =
        unwantedModifiers.where((m) => m.suspended).toList();
    logger.log('unwantedSuspendedModifiers: '
        '${unwantedSuspendedModifiers.map((m) => EnIntKbMapper.keyToString(m.vk)).toList()}');
    logger.log('unwantedModifiers: '
        '${unwantedModifiers.map((m) => EnIntKbMapper.keyToString(m.vk)).toList()}');

    List<_KeyTracker> suspendedModifiers = [];
    if (unwantedModifiers.isNotEmpty) {
      suspendedModifiers = await _suspendModifierKeys(unwantedModifiers);
      logger.log('suspendedModifiers: '
          '${suspendedModifiers.map((m) => EnIntKbMapper.keyToString(m.vk)).toList()}');
    }

    /// temporaryModifiers are modifiers that are not currently pressed but are
    /// in the modifiers list of the key action. They should be pressed temporarily.
    List<int> temporaryModifiers = [];
    if (modifiers.isNotEmpty) {
      temporaryModifiers =
          modifiers.where((m) => !modifierStates.containsKey(m)).toList();
    }

    final enabledTemporaryModifiers = await _sendTemporaryModifiers(temporaryModifiers);

    final result = await action();

    if (suspendedModifiers.isNotEmpty) {
      await _resumeModifierKeys(suspendedModifiers);
    }

    if (enabledTemporaryModifiers.isNotEmpty) {
      await _disableTemporaryModifiers(enabledTemporaryModifiers);
    }

    return result;
  }

  Future<int> _sendVirtualKey(int virtualKeyCode, KeyActionType keyActionType,
      [KeyOptions? options]) async {
    int result = 1;

    if (keyActionType == KeyActionType.PRESS) {
      result = await _inputService.sendVirtualKey(
        virtualKeyCode,
        interval: options?.keyRepeatInterval ?? _config.keyPressInterval,
      );
      _keyReleased(virtualKeyCode);
    } else if (keyActionType == KeyActionType.UP) {
      result = await _inputService.sendKeyState(
        virtualKeyCode,
        keyActionType,
      );
      _keyReleased(virtualKeyCode);
    } else {
      result = await _inputService.sendKeyState(
        virtualKeyCode,
        keyActionType,
      );
      _keyPressed(virtualKeyCode);
    }

    return result;
  }

  Future<int> pressKey(int virtualKeyCode, KeyActionType keyActionType,
      [KeyOptions? options]) async {
    _cancelKeyRepeat(virtualKeyCode);

    final int result;

    if (options != null &&
        options.modifiers != null &&
        options.disableUnwantedModifiers == true) {
      final modifiers = options.modifiers!;
      callback() async => await _sendVirtualKey(virtualKeyCode, keyActionType, options);

      result = await doWithModifiers(modifiers, callback);
    } else {
      // No options
      result = await _sendVirtualKey(virtualKeyCode, keyActionType, options);
    }

    if (options?.noRepeat == true) {
      return result;
    }

    Duration keyRepeatInterval = _config.keyRepeatInterval;
    if (options?.keyRepeatInterval != null) {
      keyRepeatInterval = Duration(milliseconds: options!.keyRepeatInterval!);
    }

    if (keyActionType == KeyActionType.DOWN) {
      _scheduleKeyRepeat(virtualKeyCode, _config.keyRepeatDelay, keyRepeatInterval);
    }

    return result;
  }

  Future<int> pressMouseButton(ButtonFlags key, ButtonActionType keyActionType) async {
    if (keyActionType == ButtonActionType.PRESS) {
      return _inputService.pressMouseKey(
        key,
        interval: _config.keyPressInterval,
      );
    }

    return _inputService.sendMouseKeyState(
      key,
      keyActionType,
    );
  }

  Future<int> moveMouse(double deltaX, double deltaY) async {
    return _inputService.moveMouseRelative(
      deltaX,
      deltaY,
      speed: _config.cursorSpeed,
      acceleration: _config.cursorAcceleration,
    );
  }

  // For reference:
  //
  // class HotkeyStep:
  // - final int keyCode
  //   /// UP, DOWN, PRESS (UP then DOWN)
  // - final KeyActionType actionType
  //   /// Wait before executing this step
  // - final Duration? wait
  //   /// The speed of the key press (only applicable for actionType == PRESS)
  // - final Duration? speed
  //
  // class HotkeyOptions:
  // - final bool? disableUnwantedModifiers
  //   /// The interval between key presses
  // - final int? speed

  Future<bool> doHotkeyStep(HotkeyStep step, [HotkeyOptions? options]) async {
    final wait = step.wait ?? options?.speed ?? _config.keyPressInterval;
    await Future.delayed(Duration(milliseconds: wait));
    const opt = KeyOptions(noRepeat: true);

    switch (step.actionType) {
      case KeyActionType.UP:
        await pressKey(step.keyCode, KeyActionType.UP, opt);
        break;
      case KeyActionType.DOWN:
        await pressKey(step.keyCode, KeyActionType.DOWN, opt);
        break;
      case KeyActionType.PRESS:
        await pressKey(step.keyCode, KeyActionType.DOWN, opt);
        await Future.delayed(Duration(milliseconds: _config.keyPressInterval));
        await pressKey(step.keyCode, KeyActionType.UP, opt);
        break;
    }

    logger.log('doHotkeyStep: ${EnIntKbMapper.keyToString(step.keyCode)} ${step.actionType}');

    return true;
  }

  Future<bool> pressHotkey(
      String id, KeyActionType keyActionType, List<HotkeyStep> hotkeySteps,
      [HotkeyOptions? options]) async {
    final result = await _keyLock.synchronized(() async {
      if (hotkeySteps.isEmpty || id.isEmpty) {
        return false;
      }

      final hotkeyState = hotkeyStates.containsKey(id) ? hotkeyStates[id] : null;

      if (keyActionType == KeyActionType.UP) {
        if (hotkeyState == null) {
          return false;
        }

        if (hotkeyState.state == KeyState.UP) {
          return false;
        }

        hotkeyState.state = KeyState.UP;
      }

      if (keyActionType == KeyActionType.DOWN) {
        if (hotkeyState != null) {
          if (hotkeyState.state == KeyState.DOWN) {
            return false;
          }

          hotkeyState.state = KeyState.DOWN;
        } else {
          hotkeyStates[id] = _HotkeyTracker(hotkey: id, state: KeyState.DOWN);
        }

        doSteps() async {
          for (final step in hotkeySteps) {
            await doHotkeyStep(step, options);
          }

          return true;
        }

        if (options != null && options.disableUnwantedModifiers == true) {
          return await doWithModifiers([], doSteps);
        }

        return await doSteps();
      }

      return true;
    });

    return result;
  }
}
