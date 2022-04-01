import 'dart:convert';

import 'package:remotecontrol/logger.dart';
import 'dart:io';

startRemoteInputServer(int port, Logger logger) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  logger.info('Remote input server listening on port ${server.port}');

  await for (HttpRequest request in server) {
    final response = request.response;
    final requestBody = await utf8.decodeStream(request);

    logger.info('Remote input request: $requestBody');

    response.write('OK');
    response.close();
  }
}
