import 'dart:convert';

import 'package:remotecontrol/components/server_status.dart';
import 'package:remotecontrol/logger.dart';
import 'dart:io';

class InputServer {
  HttpServer? _server;
  int _port;
  ServerStatus _status = ServerStatus.offline;
  final Logger? _logger;
  late InternetAddress _address;


  InputServer(this._port, this._logger, {InternetAddress? address}) {
    _address = address ?? InternetAddress.loopbackIPv4;
  }

  get status => _status;

  get address => _address;

  int get port => _port;

  set port(int port) {
    if (_server != null) {
      _logger?.warning('Cannot change port while server is running');
      throw Exception('Cannot change port while server is running');
    }
    _port = port;
  }

  Future<void> listen() async {
    HttpServer server = await HttpServer.bind(_address, _port);
    _server = server;
    _status = ServerStatus.online;

    _logger?.info('Remote input server listening on port ${_server?.port}');

    await for (HttpRequest request in server) {
      final response = request.response;
      final requestBody = await utf8.decodeStream(request);

      _logger?.info('Remote input request: $requestBody');

      response.write('OK');
      response.close();
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _status = ServerStatus.offline;
    _logger?.info('Remote input server stopped');
  }
}
