// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_final_locals

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

// AUTOGENERATED START
//
// Update these constants by running:
//
// dart pkg/vm_service/test/update_line_numbers.dart pkg/vm_service/test/step_through_for_each_sync_star_2_test.dart
//
const LINE_A = 21;
// AUTOGENERATED END

const String file = 'step_through_for_each_sync_star_2_test.dart';

void code() /* LINE_A */ {
  for (int datapoint in generator()) {
    print(datapoint);
  }
}

Iterable<dynamic> generator() sync* {
  var x = 3;
  var y = 4;
  yield x;
  yield x + y;
}

final stops = <String>[];
const expected = <String>[
  '$file:${LINE_A + 0}:10', // after 'code'
  '$file:${LINE_A + 1}:25', // on 'generator' (in 'for' line)

  '$file:${LINE_A + 6}:28', // after 'generator' (definition line)
  '$file:${LINE_A + 7}:9', // on '=' in 'x = 3'
  '$file:${LINE_A + 8}:9', // on '=' in 'y = 4'
  '$file:${LINE_A + 9}:3', // on yield

  '$file:${LINE_A + 1}:38', // on '{' in 'for' line
  '$file:${LINE_A + 1}:12', // on 'datapoint'
  '$file:${LINE_A + 2}:5', // on 'print'
  '$file:${LINE_A + 1}:25', // on 'generator' (in 'for' line)

  '$file:${LINE_A + 10}:11', // on '+' in 'x + y'
  '$file:${LINE_A + 10}:3', // on yield

  '$file:${LINE_A + 1}:38', // on '{' in 'for' line
  '$file:${LINE_A + 1}:12', // on 'datapoint'
  '$file:${LINE_A + 2}:5', // on 'print'
  '$file:${LINE_A + 1}:25', // on 'generator' (in 'for' line)

  '$file:${LINE_A + 11}:1', // on ending '}' of 'generator'

  '$file:${LINE_A + 4}:1', // on ending '}' of 'code''
];

final tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE_A),
  runStepIntoThroughProgramRecordingStops(stops),
  checkRecordedStops(
    stops,
    expected,
    debugPrint: true,
    debugPrintFile: file,
    debugPrintLine: LINE_A,
  ),
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'step_through_for_each_sync_star_2_test.dart',
      testeeConcurrent: code,
      pauseOnStart: true,
      pauseOnExit: true,
    );
