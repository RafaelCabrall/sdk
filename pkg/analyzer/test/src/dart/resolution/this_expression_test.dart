// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ThisExpressionResolutionTest);
  });
}

@reflectiveTest
class ThisExpressionResolutionTest extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  void f() {
    this;
  }
}
''');

    newFile(testFile.path, r'''
part 'a.dart';

class A {}
''');

    await resolveFile2(a);

    nodeTextConfiguration.withInterfaceTypeElements = true;

    var node = findNode.singleThisExpression;
    assertResolvedNodeText(node, r'''
ThisExpression
  thisKeyword: this
  staticType: A
    element: <testLibraryFragment>::@class::A
    element: <testLibrary>::@class::A
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_mixin_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment mixin M {
  void f() {
    this;
  }
}
''');

    newFile(testFile.path, r'''
part 'a.dart';

mixin M {}
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    nodeTextConfiguration.withInterfaceTypeElements = true;

    var node = findNode.singleThisExpression;
    assertResolvedNodeText(node, r'''
ThisExpression
  thisKeyword: this
  staticType: M
    element: <testLibraryFragment>::@mixin::M
    element: <testLibrary>::@mixin::M
''');
  }
}
