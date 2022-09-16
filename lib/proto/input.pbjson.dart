///
//  Generated code. Do not modify.
//  source: input.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use keyDescriptor instead')
const Key$json = const {
  '1': 'Key',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    const {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.Key.KeyActionType', '10': 'type'},
  ],
  '4': const [Key_KeyActionType$json],
};

@$core.Deprecated('Use keyDescriptor instead')
const Key_KeyActionType$json = const {
  '1': 'KeyActionType',
  '2': const [
    const {'1': 'UP', '2': 0},
    const {'1': 'DOWN', '2': 1},
  ],
};

/// Descriptor for `Key`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyDescriptor = $convert.base64Decode('CgNLZXkSDgoCaWQYASABKAVSAmlkEiYKBHR5cGUYAiABKA4yEi5LZXkuS2V5QWN0aW9uVHlwZVIEdHlwZSIhCg1LZXlBY3Rpb25UeXBlEgYKAlVQEAASCAoERE9XThAB');
@$core.Deprecated('Use mouseKeyDescriptor instead')
const MouseKey$json = const {
  '1': 'MouseKey',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    const {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.MouseKey.KeyActionType', '10': 'type'},
  ],
  '4': const [MouseKey_KeyActionType$json],
};

@$core.Deprecated('Use mouseKeyDescriptor instead')
const MouseKey_KeyActionType$json = const {
  '1': 'KeyActionType',
  '2': const [
    const {'1': 'UP', '2': 0},
    const {'1': 'DOWN', '2': 1},
  ],
};

/// Descriptor for `MouseKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mouseKeyDescriptor = $convert.base64Decode('CghNb3VzZUtleRIOCgJpZBgBIAEoBVICaWQSKwoEdHlwZRgCIAEoDjIXLk1vdXNlS2V5LktleUFjdGlvblR5cGVSBHR5cGUiIQoNS2V5QWN0aW9uVHlwZRIGCgJVUBAAEggKBERPV04QAQ==');
@$core.Deprecated('Use mouseMoveDescriptor instead')
const MouseMove$json = const {
  '1': 'MouseMove',
  '2': const [
    const {'1': 'x', '3': 1, '4': 1, '5': 2, '10': 'x'},
    const {'1': 'y', '3': 2, '4': 1, '5': 2, '10': 'y'},
    const {'1': 'relative', '3': 3, '4': 1, '5': 8, '10': 'relative'},
  ],
};

/// Descriptor for `MouseMove`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mouseMoveDescriptor = $convert.base64Decode('CglNb3VzZU1vdmUSDAoBeBgBIAEoAlIBeBIMCgF5GAIgASgCUgF5EhoKCHJlbGF0aXZlGAMgASgIUghyZWxhdGl2ZQ==');
@$core.Deprecated('Use responseDescriptor instead')
const Response$json = const {
  '1': 'Response',
  '2': const [
    const {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor = $convert.base64Decode('CghSZXNwb25zZRIYCgdtZXNzYWdlGAEgASgJUgdtZXNzYWdl');
@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = const {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor = $convert.base64Decode('CgVFbXB0eQ==');
