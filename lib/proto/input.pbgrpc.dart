///
//  Generated code. Do not modify.
//  source: input.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'input.pb.dart' as $0;
export 'input.pb.dart';

class InputMethodsClient extends $grpc.Client {
  static final _$pressKey = $grpc.ClientMethod<$0.Key, $0.Response>(
      '/InputMethods/PressKey',
      ($0.Key value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Response.fromBuffer(value));
  static final _$pressMouseKey = $grpc.ClientMethod<$0.MouseKey, $0.Response>(
      '/InputMethods/PressMouseKey',
      ($0.MouseKey value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Response.fromBuffer(value));
  static final _$moveMouse = $grpc.ClientMethod<$0.MouseMove, $0.Response>(
      '/InputMethods/MoveMouse',
      ($0.MouseMove value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Response.fromBuffer(value));

  InputMethodsClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.Response> pressKey($0.Key request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$pressKey, request, options: options);
  }

  $grpc.ResponseFuture<$0.Response> pressMouseKey($0.MouseKey request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$pressMouseKey, request, options: options);
  }

  $grpc.ResponseFuture<$0.Response> moveMouse($0.MouseMove request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$moveMouse, request, options: options);
  }
}

abstract class InputMethodsServiceBase extends $grpc.Service {
  $core.String get $name => 'InputMethods';

  InputMethodsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Key, $0.Response>(
        'PressKey',
        pressKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Key.fromBuffer(value),
        ($0.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.MouseKey, $0.Response>(
        'PressMouseKey',
        pressMouseKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.MouseKey.fromBuffer(value),
        ($0.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.MouseMove, $0.Response>(
        'MoveMouse',
        moveMouse_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.MouseMove.fromBuffer(value),
        ($0.Response value) => value.writeToBuffer()));
  }

  $async.Future<$0.Response> pressKey_Pre(
      $grpc.ServiceCall call, $async.Future<$0.Key> request) async {
    return pressKey(call, await request);
  }

  $async.Future<$0.Response> pressMouseKey_Pre(
      $grpc.ServiceCall call, $async.Future<$0.MouseKey> request) async {
    return pressMouseKey(call, await request);
  }

  $async.Future<$0.Response> moveMouse_Pre(
      $grpc.ServiceCall call, $async.Future<$0.MouseMove> request) async {
    return moveMouse(call, await request);
  }

  $async.Future<$0.Response> pressKey($grpc.ServiceCall call, $0.Key request);
  $async.Future<$0.Response> pressMouseKey(
      $grpc.ServiceCall call, $0.MouseKey request);
  $async.Future<$0.Response> moveMouse(
      $grpc.ServiceCall call, $0.MouseMove request);
}
