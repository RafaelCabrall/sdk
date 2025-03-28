// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'masks.dart';

/// A [SetTypeMask] is a [TypeMask] for a specific allocation site of a set
/// (currently only the internal Set class) that will get specialized once the
/// [TypeGraphInferrer] phase finds an element type for it.
class SetTypeMask extends AllocationTypeMask {
  /// Tag used for identifying serialized [SetTypeMask] objects in a debugging
  /// data stream.
  static const String tag = 'set-type-mask';

  @override
  final TypeMask forwardTo;

  final ir.Node? _allocationNode;
  @override
  ir.Node? get allocationNode => _allocationNode;

  @override
  final MemberEntity? allocationElement;

  // The element type of this set.
  final TypeMask elementType;

  const SetTypeMask(
    this.forwardTo,
    this._allocationNode,
    this.allocationElement,
    this.elementType,
  );

  /// Deserializes a [SetTypeMask] object from [source].
  factory SetTypeMask.readFromDataSource(
    DataSourceReader source,
    CommonMasks domain,
  ) {
    source.begin(tag);
    final forwardTo = TypeMask.readFromDataSource(source, domain);
    final allocationElement = source.readMemberOrNull();
    final elementType = TypeMask.readFromDataSource(source, domain);
    source.end(tag);
    return SetTypeMask(forwardTo, null, allocationElement, elementType);
  }

  /// Serializes this [SetTypeMask] to [sink].
  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(TypeMaskKind.set);
    sink.begin(tag);
    forwardTo.writeToDataSink(sink);
    sink.writeMemberOrNull(allocationElement);
    elementType.writeToDataSink(sink);
    sink.end(tag);
  }

  @override
  SetTypeMask withPowerset(Bitset powerset, CommonMasks domain) {
    if (powerset == this.powerset) return this;
    return SetTypeMask(
      forwardTo.withPowerset(powerset, domain),
      allocationNode,
      allocationElement,
      elementType,
    );
  }

  @override
  bool get isExact => true;

  @override
  TypeMask? _unionSpecialCases(
    TypeMask other,
    CommonMasks domain,
    Bitset powerset,
  ) {
    if (other is SetTypeMask) {
      TypeMask newElementType = elementType.union(other.elementType, domain);
      TypeMask newForwardTo = forwardTo.union(other.forwardTo, domain);
      return SetTypeMask(newForwardTo, null, null, newElementType);
    }
    return null;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SetTypeMask) return false;
    return super == other && elementType == other.elementType;
  }

  @override
  int get hashCode => Hashing.objectHash(elementType, super.hashCode);

  @override
  String toString() =>
      'Set($forwardTo, element: $elementType, '
      'powerset: ${TypeMask.powersetToString(powerset)})';
}
