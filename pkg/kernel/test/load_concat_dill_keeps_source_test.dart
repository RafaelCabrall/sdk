// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that 79cc54e51924cd5a6bdc2bd1771f2d0ee7af8899 works as intended.

import 'dart:convert';
import 'dart:typed_data';

import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart';

Uri uri1 = Uri.parse("foo://lib1.dart");
Uri uri2 = Uri.parse("foo://lib2.dart");

void main() {
  Library library1 = new Library(uri1, fileUri: uri1);
  Library library2 = new Library(uri2, fileUri: uri2);
  Procedure p1 = new Procedure(new Name("p1"), ProcedureKind.Method,
      new FunctionNode(new ReturnStatement()),
      fileUri: uri2);
  Procedure p2 = new Procedure(new Name("p2"), ProcedureKind.Method,
      new FunctionNode(new ReturnStatement()),
      fileUri: uri1);
  library1.addProcedure(p1);
  library2.addProcedure(p2);

  Component component = new Component(libraries: [library1, library2])
    ..setMainMethodAndMode(null, false);
  component.uriToSource[uri1] =
      new Source([42, 2 * 42], utf8.encode("source #1"), uri1, uri1);
  component.uriToSource[uri2] =
      new Source([43, 3 * 43], utf8.encode("source #2"), uri1, uri1);
  expectSource(serialize(component), true, true);

  Component cPartial1 = new Component(nameRoot: component.root)
    ..setMainMethodAndMode(null, false)
    ..libraries.add(library1);
  cPartial1.uriToSource[uri1] =
      new Source([42, 2 * 42], utf8.encode("source #1"), uri1, uri1);
  cPartial1.uriToSource[uri2] =
      new Source.emptySource([43, 3 * 43], uri1, uri1);
  Uint8List partial1Serialized = serialize(cPartial1);
  expectSource(partial1Serialized, true, false);

  Component cPartial2 = new Component(nameRoot: component.root)
    ..setMainMethodAndMode(null, false)
    ..libraries.add(library2);
  cPartial2.uriToSource[uri1] =
      new Source.emptySource([42, 2 * 42], uri1, uri1);
  cPartial2.uriToSource[uri2] =
      new Source([43, 3 * 43], utf8.encode("source #2"), uri1, uri1);
  Uint8List partial2Serialized = serialize(cPartial2);
  expectSource(partial2Serialized, false, true);

  Uint8List combined =
      new Uint8List.fromList([...partial1Serialized, ...partial2Serialized]);
  expectSource(combined, true, true);
}

void expectSource(Uint8List data, bool expect1, bool expect2) {
  BinaryBuilder builder = new BinaryBuilder(data);
  Component tmp = new Component();
  builder.readComponent(tmp);
  if (tmp.uriToSource[uri1] == null) throw "No data for $uri1";
  if (tmp.uriToSource[uri2] == null) throw "No data for $uri2";
  if (expect1 && tmp.uriToSource[uri1]!.source.isEmpty) {
    throw "No data for $uri1";
  }
  if (!expect1 && tmp.uriToSource[uri1]!.source.isNotEmpty) {
    throw "Unexpected data for $uri1";
  }
  if (expect2 && tmp.uriToSource[uri2]!.source.isEmpty) {
    throw "No data for $uri2";
  }
  if (!expect2 && tmp.uriToSource[uri2]!.source.isNotEmpty) {
    throw "Unexpected data for $uri2";
  }
}

Uint8List serialize(Component c) {
  SimpleSink sink = new SimpleSink();
  BinaryPrinter printerWhole = new BinaryPrinter(sink);
  printerWhole.writeComponentFile(c);
  return sink.builder.takeBytes();
}

class SimpleSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  @override
  void add(List<int> chunk) {
    builder.add(chunk);
  }

  @override
  void close() {}
}
