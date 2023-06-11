import 'dart:convert';

import 'package:remotecontrol_lib/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:stack_trace/stack_trace.dart';

Middleware logRequestsMiddleware(Logger logger) {
  return (handler) {
    return (request) {
      // var startTime = DateTime.now();
      var watch = Stopwatch()..start();

      return Future.sync(() => handler(request)).then((response) async {
        var msg = '${request.method} ${request.requestedUri} '
            '${response.statusCode} ${watch.elapsed.inMicroseconds}mic';

        logger.debug(msg);
        final requestBody = await request.readAsString(Encoding.getByName('UTF-8'));
        logger.trace('Request body: $requestBody');

        return response;
      }, onError: (Object error, StackTrace stackTrace) {
        if (error is HijackException) throw error;

        var chain = Chain.current();
        chain = Chain.forTrace(stackTrace)
            .foldFrames((frame) => frame.isCore || frame.package == 'shelf')
            .terse;

        var msg = '${request.method} ${request.requestedUri} '
            '${watch.elapsed} $error $chain';

        logger.error(msg);

        throw error;
      });
    };
  };
}
