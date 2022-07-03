import 'package:remotecontrol/components/server_status.dart';
import 'package:remotecontrol/logger.dart';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'middlewares.dart';

class InputServer {
  HttpServer? _server;
  int _port;
  ServerStatus _status = ServerStatus.offline;
  final Logger _logger;
  late InternetAddress _address;

  InputServer(this._port, this._logger, {InternetAddress? address}) {
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
    var handler =
    const Pipeline().addMiddleware(logRequestsMiddleware(_logger)).addHandler(_echoRequest);

    _status = ServerStatus.online;
    _logger.info('Remote input server listening on port $_port');

    _server = await shelf_io.serve(handler, _address, _port);
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _status = ServerStatus.offline;
    _logger.info('Remote input server stopped');
  }

  Response _echoRequest(Request request) {
    return Response.ok('Request for "${request.url}"');
  }
}
