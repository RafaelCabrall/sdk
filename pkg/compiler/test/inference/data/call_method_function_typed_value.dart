// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test based on language/call_method_function_typed_value_test/04

import "package:expect/expect.dart";

/*member: f:[subclass=JSInt|powerset=0]*/
int f(
  int
  /*spec.[null|subclass=Object|powerset=1]*/
  /*prod.[subclass=JSInt|powerset=0]*/
  i,
) => 2 /*invoke: [exact=JSUInt31|powerset=0]*/ * i;

typedef int IntToInt(int x);

/*member: test:[null|powerset=1]*/
test(
  /*[null|subclass=Object|powerset=1]*/ a,
  /*[subclass=Closure|powerset=0]*/ b,
) => Expect.identical(a, b);

/*member: main:[null|powerset=1]*/
main() {
  // It is possible to use `.call` on a function-typed value (even though it is
  // redundant).  Similarly, it is possible to tear off `.call` on a
  // function-typed value (but it is a no-op).
  IntToInt f2 = f;

  test(f2. /*[subclass=Closure|powerset=0]*/ call, f);
}
