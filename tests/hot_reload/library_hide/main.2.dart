// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

import 'lib1.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/9f465e5b6eab0dc3af96140189d4f0190e0ff925/runtime/vm/isolate_reload_test.cc#L1123

void helper() {
  Expect.equals('a', importedFunc());
}

Future<void> main() async {
  helper();
  await hotReload(expectRejection: true);
  helper();
  await hotReload();
  helper();
}

/** DIFF **/
/*
 import 'package:expect/expect.dart';
 import 'package:reload_test/reload_test_utils.dart';
 
-import 'lib1.dart' hide importedFunc;
+import 'lib1.dart';
 
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/9f465e5b6eab0dc3af96140189d4f0190e0ff925/runtime/vm/isolate_reload_test.cc#L1123
*/
