// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';
import 'package:analyzer/source/source.dart';

/// An object with which an analysis result can be associated.
///
/// Clients may implement this class when creating new kinds of targets.
/// Instances of this type are used in hashed data structures, so subtypes are
/// required to correctly implement [==] and [hashCode].
@AnalyzerPublicApi(message: 'exposed by Element (superclass)')
@Deprecated('To be removed without replacement')
abstract class AnalysisTarget {
  /// If this target is associated with a library, return the source of the
  /// library's defining compilation unit; otherwise return `null`.
  Source? get librarySource;

  /// Return the source associated with this target, or `null` if this target is
  /// not associated with a source.
  Source? get source;
}
