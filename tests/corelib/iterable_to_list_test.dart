// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

import "dart:collection" show Queue;
import "dart:typed_data" show Uint8List, Float32List;
import "package:expect/expect.dart";

main() {
  // testIterable takes an iterable and a list expected to be equal to
  // the iterable's toList result, including the type parameter of the list.
  testIterable(<dynamic>[], <dynamic>[]);
  testIterable(<dynamic?>[], <dynamic?>[]);
  testIterable(<int>[], <int>[], 0);
  testIterable(<int?>[], <int?>[]);
  testIterable(<String>[], <String>[], "");
  testIterable(<String?>[], <String?>[]);
  testIterable([1, 2, 3], [1, 2, 3], 0);
  testIterable(<int>[1, 2, 3], <int>[1, 2, 3], 0);
  testIterable(<int?>[1, 2, 3], <int?>[1, 2, 3]);
  testIterable(const [1, 2], [1, 2], 0);
  testIterable(const <int>[1, 2], <int>[1, 2], 0);
  testIterable(<dynamic, dynamic>{"x": 1, "y": 1}.keys, <dynamic>["x", "y"]);
  testIterable(<String, int>{"x": 1, "y": 1}.keys, <String>["x", "y"], "");
  testIterable(<String?, int>{"x": 1, "y": 1}.keys, <String?>["x", "y"]);
  testIterable(<dynamic, dynamic>{"x": 2, "y": 3}.values, <dynamic>[2, 3]);
  testIterable(<String, int>{"x": 2, "y": 3}.values, <int>[2, 3], 0);
  testIterable(<String, int?>{"x": 2, "y": 3}.values, <int?>[2, 3]);
  testIterable(new Iterable.generate(3), [0, 1, 2], 0);
  testIterable(new Iterable<int>.generate(3), <int>[0, 1, 2], 0);
  testIterable(new Iterable<int?>.generate(3), <int?>[0, 1, 2]);
  testIterable(new Iterable<String>.generate(3, (x) => "$x"),
      <String>["0", "1", "2"], "");
  testIterable(
      new Iterable<String?>.generate(3, (x) => "$x"), <String?>["0", "1", "2"]);
  testIterable(new Set.from([1, 2, 3]), [1, 2, 3], 0);
  testIterable(new Set<int>.from([1, 2, 3]), <int>[1, 2, 3], 0);
  testIterable(new Set<int?>.from([1, 2, 3]), <int?>[1, 2, 3]);
  testIterable(new Queue.from([1, 2, 3]), [1, 2, 3], 0);
  testIterable(new Queue<int>.from(<int>[1, 2, 3]), <int>[1, 2, 3], 0);
  testIterable(new Queue<int?>.from(<int?>[1, 2, 3]), <int?>[1, 2, 3]);
  testIterable(new Uint8List.fromList(<int>[1, 2, 3]), //    //# 01: ok
      <int>[1, 2, 3], 0); //                                 //# 01: continued
  testIterable(new Float32List.fromList([1.0, 2.0, 3.0]), // //# 01: continued
      <double>[1.0, 2.0, 3.0], 0.1); //                      //# 01: continued
  testIterable("abc".codeUnits, <int>[97, 98, 99], 99); //   //# 01: continued
  testIterable("abc".runes, <int>[97, 98, 99], 99);
}

testIterable(Iterable iterable, List expected, [element, int depth = 0]) {
  print(" " * depth + "${iterable.runtimeType} vs ${expected.runtimeType}");
  test(iterable, expected, element);
  test(iterable, expected, element, growable: true);
  test(iterable, expected, element, growable: false);
  if (depth < 2) {
    depth++;
    testIterable(
        iterable.map((x) => x), new List.from(expected), element, depth);
    testIterable(iterable.where((x) => true), expected, element, depth);
    testIterable(
        iterable.expand((x) => [x]), new List.from(expected), element, depth);
    testIterable(
        iterable.map((x) => x), new List.from(expected), element, depth);
    testIterable(iterable.skipWhile((x) => false), expected, element, depth);
    testIterable(iterable.takeWhile((x) => true), expected, element, depth);
    testIterable(iterable.skip(0), expected, element, depth);
    testIterable(iterable.take(expected.length * 2), expected, element, depth);
    testIterable(iterable.toSet(), expected, element, depth);
  }
}

test(Iterable iterable, List expected, element, {bool growable = true}) {
  var list = iterable.toList(growable: growable);
  Expect.listEquals(expected, list);
  Expect.equals(expected is List<int>, list is List<int>, "int");
  Expect.equals(expected is List<int?>, list is List<int?>, "int?");
  Expect.equals(expected is List<double>, list is List<double>, "double");
  Expect.equals(expected is List<String>, list is List<String>, "str");
  Expect.equals(expected is List<String?>, list is List<String?>, "str?");

  if (growable) {
    int length = list.length;
    list.add(element);
    Expect.equals(length + 1, list.length);
  } else {
    Expect.throws(() {
      list.add(element);
    });
  }
}