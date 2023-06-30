import 'package:get/get.dart';
import 'package:grpc/grpc.dart';
import 'package:remotecontrol_lib/logger.dart';
import 'package:remotecontrol_lib/proto/input.pbgrpc.dart' as pb;
import 'package:remotecontrol_lib/virtualkeys.dart';

import 'input_config.dart';
import 'win32_input_service.dart';

/// Provides implementation for protobuf [pb.InputMethodsServiceBase] methods
/// Delegates handling to [Win32InputService] using settings from [InputConfig]
/// DI Dependencies: [InputConfig]
class InputMethodsService extends pb.InputMethodsServiceBase {
  final Logger _logger;
  final Win32InputService systemInputService;
  final InputConfig config = Get.find<InputConfig>();

  get isDebug => config.isDebug;

  // TODO: implement modifiers
  final activeModifiers = <int>[];

  InputMethodsService(this._logger, this.systemInputService);

  /* region Behavior */
  @override
  Future<pb.Response> pressKey(ServiceCall call, pb.Key request) async {
    systemInputService.isDebug = config.isDebug;

    if (request.type == pb.Key_KeyActionType.PRESS) {
      var result = systemInputService.sendVirtualKey(
        request.id,
        interval: config.keyPressInterval,
      );
      return pb.Response()..message = result.toString();
    }

    _logger.error('Key press type not implemented: ${request.type}');
    throw UnimplementedError();
  }

  @override
  Future<pb.Response> moveMouse(ServiceCall call, pb.MouseMove request) async {
    systemInputService.isDebug = config.isDebug;

    // _logger.trace('Mouse moved: ${request.x}, ${request.y}');
    var result = systemInputService.moveMouseRelative(
      request.x,
      request.y,
      speed: config.cursorSpeed,
      acceleration: config.cursorAcceleration,
    );
    return pb.Response()..message = result.toString();
  }

  @override
  Future<pb.Response> pressMouseKey(ServiceCall call, pb.MouseKey request) async {
    systemInputService.isDebug = config.isDebug;

    if (request.type == pb.MouseKey_KeyActionType.PRESS) {
      MouseButtonType button = MouseButtonType.values[request.id];
      MBWrapper key = MBWrapper.fromMouseButton(button);
      var result = systemInputService.pressMouseKey(
        key,
        interval: config.keyPressInterval,
      );
      return pb.Response()..message = result.toString();
    }

    throw UnimplementedError();
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
