import 'package:get/get.dart';
import 'package:grpc/grpc.dart';
import 'package:remotecontrol_lib/client.dart';
import 'package:remotecontrol_lib/keyboard.dart';
import 'package:remotecontrol_lib/logger.dart';
import 'package:remotecontrol_lib/proto/input.pbgrpc.dart' as pb;
import 'package:remotecontrol_lib/virtualkeys.dart';
import 'package:remotecontrol/win32vk.dart';

import 'input_config.dart';
import 'win32_input_service.dart';

/// Provides implementation for protobuf [pb.InputMethodsServiceBase] methods
/// Delegates handling to [Win32InputService] using settings from [KeyboardInputConfig]
/// DI Dependencies: [KeyboardInputConfig]
class InputMethodsService extends pb.InputMethodsServiceBase {
  final Logger _logger;
  final KeyboardInputService keyboardInputService = Get.find<KeyboardInputService>();
  final KeyboardInputConfig config = Get.find<KeyboardInputConfig>();

  // TODO: implement modifiers
  final activeModifiers = <int>[];

  InputMethodsService(this._logger);

  /* region Behavior */
  @override
  Future<pb.Response> pressKey(ServiceCall call, pb.Key request) async {
    try {
      final actionType = pbToKeyActionType(request.type);
      final virtualKey = keyToVk(request.id);
      final options = request.hasOptions() ? KeyOptions.fromPb(request.options) : null;

      final result = await keyboardInputService.pressKey(virtualKey, actionType, options);
      _logger.info('Key ${keyToString(request.id)} ${request.type} ${options?.toString()}');

      return pb.Response()..message = result.toString();
    } catch (e) {
      _logger.error('Error pressing key '
          'kId: ${request.id} '
          'type: ${request.type} '
          'error: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<pb.Response> pressHotkey(ServiceCall call, pb.Hotkey request) async {
    final actionType = pbToKeyActionType(request.type);

    final hotkey = request.hotkey;
    final options = request.hasOptions() ? HotkeyOptions.fromPb(request.options) : null;

    final hotkeySteps = stepsFromString(hotkey, stringToVk);

    final result =
        await keyboardInputService.pressHotkey(hotkey, actionType, hotkeySteps, options);

    _logger.info('Hotkey ${request.type} $hotkey ${options?.toString()}');

    return pb.Response()..message = result.toString();
  }

  @override
  Future<pb.Response> moveMouse(ServiceCall call, pb.MouseMove request) async {
    var result = await keyboardInputService.moveMouse(request.x, request.y);

    return pb.Response()..message = result.toString();
  }

  @override
  Future<pb.Response> pressMouseKey(ServiceCall call, pb.MouseKey request) async {
    final buttonType = Button.values[request.id];
    final button = ButtonFlags.fromMouseButton(buttonType);
    final actionType = pbToButtonActionType(request.type);

    final result = await keyboardInputService.pressMouseButton(button, actionType);

    return pb.Response()..message = result.toString();
  }
  /* endregion Behavior */

  /* region Configuration */
  @override
  Future<pb.Config> getConfig(ServiceCall call, pb.Empty request) {
    return Future.value(
      pb.Config()
        ..cursorAcceleration = config.cursorAcceleration
        ..cursorSpeed = config.cursorSpeed,
    );
  }

  @override
  Future<pb.Config> setConfig(ServiceCall call, pb.Config request) async {
    if (request.hasCursorAcceleration()) {
      if (config.cursorAcceleration == request.cursorAcceleration) {
        _logger.trace('Cursor acceleration already set to ${request.cursorAcceleration}');
        return request;
      }
      if (await config.setCursorAcceleration(request.cursorAcceleration)) {
        _logger.trace('Mouse acceleration set to ${request.cursorAcceleration}');
        return request;
      } else {
        _logger
            .error('Failed to set mouse acceleration to ${request.cursorAcceleration}');
        return pb.Config()..cursorAcceleration = config.cursorAcceleration;
      }
    }

    if (request.hasCursorSpeed()) {
      if (config.cursorSpeed == request.cursorSpeed) {
        _logger.trace('Cursor speed already set to ${request.cursorSpeed}');
        return request;
      }
      if (await config.setCursorSpeed(request.cursorSpeed)) {
        _logger.trace('Mouse speed set to ${request.cursorSpeed}');
        return request;
      } else {
        _logger.error('Failed to set mouse speed to ${request.cursorSpeed}');
        return pb.Config()..cursorSpeed = config.cursorSpeed;
      }
    }

    _logger.error('setConfig: Unhandled config request: $request');

    return request;
  }
  /* endregion Configuration */

  @override
  Future<pb.Response> ping(ServiceCall call, pb.Empty request) async {
    return pb.Response()..message = 'Ok';
  }
}
