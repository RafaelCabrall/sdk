// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:async';
import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

// AUTOGENERATED START
//
// Update these constants by running:
//
// dart pkg/vm_service/test/update_line_numbers.dart pkg/vm_service/test/step_over_await_test.dart
//
const LINE_A = 28;
const LINE_B = 29;
const LINE_C = 31;
// AUTOGENERATED END

// This tests the asyncNext command.
Future<void> asyncFunction() async {
  debugger(); // LINE_A
  print('a'); // LINE_B
  await Future.delayed(Duration(seconds: 2));
  print('b'); // LINE_C
}

void testMain() {
  asyncFunction();
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  stepOver, // At Duration().
  stepOver, // At Future.delayed().
  stepOver, // At async.
  // Check that we are at the async statement
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id!);
    expect(isolate.pauseEvent!.atAsyncSuspension, true);
  },
  asyncNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  resumeIsolate,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'step_over_await_test.dart',
      testeeConcurrent: testMain,
    );
