// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetAssistsTest);
  });
}

@reflectiveTest
class GetAssistsTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_has_assists() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
import 'dart:async';

var c = Completer();
''';
    writeFile(pathname, text);
    await standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);

    // expect at least one assist (add show combinator to the dart:async import)
    var result = await sendEditGetAssists(
      pathname,
      text.indexOf('dart:async'),
      0,
    );
    expect(result.assists, isNotEmpty);

    // apply it and make sure that the code analyzing cleanly
    var change = result.assists.singleWhere(
      (SourceChange change) =>
          change.message == "Add explicit 'show' combinator",
    );
    expect(change.edits, hasLength(1));
    expect(change.edits.first.edits, hasLength(1));
    var edit = change.edits.first.edits.first;
    text = text.replaceRange(edit.offset, edit.end, edit.replacement);
    writeFile(pathname, text);

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);
  }
}
