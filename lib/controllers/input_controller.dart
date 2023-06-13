import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:remotecontrol_lib/logger.dart';

import '../components/server_status.dart';
import '../services/input_service.dart';
import '../services/win32_input_service.dart';

/// Serves protobuf [InputMethodsService] over gRPC
/// Wraps the server with additional starting, stopping and logging functionality
class InputServerController {
  Server? _server;
  int _port;
  ServerStatus _status = ServerStatus.offline;
  final Win32InputService _inputService = Win32InputService();
  final Logger _logger;
  late InternetAddress _address;
  InputEventHandler? _debugEventHandler;

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
      [InputMethodsService(_logger, _inputService)],
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

  void setDebugEventHandler(InputEventHandler handler) {
    var events = InputReceivedEvent.values.toList();
    if (_debugEventHandler != null) {
      logger.error('Debug event handler already set');
      return;
    }
    _debugEventHandler = (t, e) => handler(t, e);
    _inputService.subscribeAll(events, _debugEventHandler!);
  }

  void clearDebugEventHandler() {
    if (_debugEventHandler == null) return;

    var events = InputReceivedEvent.values.toList();
    _inputService.unsubscribeAll(events, _debugEventHandler!);
    _debugEventHandler = null;
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
