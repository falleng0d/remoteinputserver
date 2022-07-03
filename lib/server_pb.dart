import 'package:grpc/grpc.dart';
import 'package:remotecontrol/components/server_status.dart';
import 'package:remotecontrol/logger.dart';
import 'package:remotecontrol/proto/input.pb.dart' as pb;
import 'package:remotecontrol/proto/input.pbgrpc.dart' as pb;
import 'package:remotecontrol/proto/input.pbgrpc.dart';
import 'dart:io';

import 'package:shelf/shelf.dart' show Request;
import 'package:shelf/shelf_io.dart' as shelf_io;

class InputMethodsService extends InputMethodsServiceBase {
  @override
  Future<pb.Response> pressKey(ServiceCall call, pb.Key request) async {
    return pb.Response()..message = 'Ok';
  }
}

class InputServerPb {
  Server? _server;
  int _port;
  ServerStatus _status = ServerStatus.offline;
  final Logger _logger;
  late InternetAddress _address;

  InputServerPb(this._port, this._logger, {InternetAddress? address}) {
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
    //var handler = const Pipeline()
    //    .addMiddleware(logRequestsMiddleware(_logger))
    //    .addHandler(_echoRequest);
    _server = Server(
      [InputMethodsService()],
      <Interceptor>[middleware(_logger)],
      CodecRegistry(codecs: const [GzipCodec()]),
    );

    // _server = await shelf_io.serve(handler, _address, _port);
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

Interceptor middleware(Logger logger) {
  return (ServiceCall call, ServiceMethod method) {
    var msg = 'Called ${method.name}';

    logger.debug(msg);
    return null;
  };
}

