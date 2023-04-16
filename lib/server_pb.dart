import 'dart:io';

import 'package:get/get.dart';
import 'package:grpc/grpc.dart';
import 'package:remotecontrol/components/server_status.dart';
import 'package:remotecontrol_lib/input/virtualkeys.dart';
import 'package:remotecontrol_lib/logger.dart';
import 'package:remotecontrol_lib/proto/input.pbgrpc.dart' as pb;

import 'input.dart';

/// Provides implementation for protobuf InputMethodsServiceBase methods
class InputMethodsService extends pb.InputMethodsServiceBase {
  final Logger _logger;
  final Win32InputService systemInputService;
  final InputConfig config = Get.find<InputConfig>();

  InputMethodsService(this._logger, this.systemInputService);

  @override
  Future<pb.Response> pressKey(ServiceCall call, pb.Key request) async {
    if (request.type == pb.Key_KeyActionType.PRESS) {
      var result = systemInputService.sendVirtualKey(
        request.id,
        interval: config.keyPressInterval,
      );
      _logger.trace('Key pressed: ${request.id}');
      return pb.Response()..message = result.toString();
    }

    _logger.error('Key press type not implemented: ${request.type}');
    throw UnimplementedError();
  }

  @override
  Future<pb.Response> moveMouse(ServiceCall call, pb.MouseMove request) async {
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
  Future<pb.Response> pressMouseKey(
      ServiceCall call, pb.MouseKey request) async {
    _logger.trace('Mouse key pressed: ${request.id}');
    if (request.type == pb.MouseKey_KeyActionType.PRESS) {
      MouseButton button = MouseButton.values[request.id];
      MBWrapper key = MBWrapper.fromMouseButton(button);
      var result = systemInputService.pressMouseKey(
        key,
        interval: config.keyPressInterval,
      );
      return pb.Response()..message = result.toString();
    }

    throw UnimplementedError();
  }

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
        return request;
      }
      if (await config.setCursorAcceleration(request.cursorAcceleration)) {
        _logger.log('Mouse acceleration set to ${request.cursorAcceleration}');
        return request;
      } else {
        _logger.error(
            'Failed to set mouse acceleration to ${request.cursorAcceleration}');
        return pb.Config()..cursorAcceleration = config.cursorAcceleration;
      }
    }

    if (request.hasCursorSpeed()) {
      if (config.cursorSpeed == request.cursorSpeed) {
        return request;
      }
      if (await config.setCursorSpeed(request.cursorSpeed)) {
        _logger.log('Mouse speed set to ${request.cursorSpeed}');
        return request;
      } else {
        _logger.error('Failed to set mouse speed to ${request.cursorSpeed}');
        return pb.Config()..cursorSpeed = config.cursorSpeed;
      }
    }

    return request;
  }

  @override
  Future<pb.Response> ping(ServiceCall call, pb.Empty request) async {
    return pb.Response()..message = 'Ok';
  }
}

/// Serves protobuf [InputMethodsService] over gRPC
/// Wraps the server with additional starting, stopping and logging functionality
class InputServerController {
  Server? _server;
  int _port;
  ServerStatus _status = ServerStatus.offline;
  final Logger _logger;
  late InternetAddress _address;

  InputServerController(this._port, this._logger, {InternetAddress? address}) {
    _address = address ?? InternetAddress.loopbackIPv4;
  }

  get status => _status;

  get address => _address;

  int get port => _port;

  set port(int port) {
    if (_server != null) {
      _logger.warning('Cannot change port while server is running');
      throw Exception('Cannot change port while server is running');
    }
    _port = port;
  }

  Future<void> listen() async {
    _server = Server(
      [InputMethodsService(_logger, Win32InputService())],
      <Interceptor>[buildLoggingMiddleware(_logger)],
      CodecRegistry(codecs: const [GzipCodec()]),
    );

    await _server?.serve(port: _port);

    _status = ServerStatus.online;
    _logger.info('Remote input server listening on port $_port');
  }

  Future<void> stop() async {
    await _server?.shutdown();
    _server = null;
    _status = ServerStatus.offline;
    _logger.info('Remote input server stopped');
  }
}

/// Builds and return a middleware for logging gRPC requests
Interceptor buildLoggingMiddleware(Logger logger) {
  return (ServiceCall call, ServiceMethod method) {
    // var msg = 'Called ${method.name}';
    // logger.trace(msg);
    return null;
  };
}
