import 'dart:ui';

import 'package:graphic/src/coord/coord.dart';
import 'package:graphic/src/dataflow/tuple.dart';
import 'package:graphic/src/graffiti/figure.dart';
import 'package:graphic/src/interaction/gesture.dart';
import 'package:graphic/src/util/math.dart';

import 'selection.dart';

/// The selection to select a continuous range of data values
///
/// A rectangle mark is shown to depict the extents of the interval.
class IntervalSelection extends Selection {
  /// Creates an interval selection.
  IntervalSelection({
    this.color,
    this.zIndex,
    int? dim,
    String? variable,
    Set<GestureType>? clear,
  }) : super(
          dim: dim,
          variable: variable,
          clear: clear,
        );

  /// The color of the interval mark.
  ///
  /// If null, a default `Color(0x10101010)` is set.
  Color? color;

  /// The z index of the interval mark.
  ///
  /// If null, a default 0 is set.
  int? zIndex;

  @override
  bool operator ==(Object other) =>
      other is IntervalSelection &&
      super == other &&
      color == other.color &&
      zIndex == other.zIndex;
}

/// The interval selector.
///
/// The [points] are `[start, end]`.
class IntervalSelector extends Selector {
  IntervalSelector(
    this.color,
    this.zIndex,
    String name,
    int? dim,
    String? variable,
    List<Offset> points,
  ) : super(
          name,
          dim,
          variable,
          points,
        );

  /// The color of the interval mark.
  final Color color;

  /// The z index of the interval mark.
  final int zIndex;

  @override
  Set<int>? select(
    AesGroups groups,
    List<Tuple> tuples,
    Set<int>? preSelects,
    CoordConv coord,
  ) {
    final start = coord.invert(points.first);
    final end = coord.invert(points.last);

    bool Function(Aes) test;
    if (dim == null) {
      final testRegion = Rect.fromPoints(start, end);
      test = (aes) {
        final p = aes.representPoint;
        return testRegion.contains(p);
      };
    } else {
      if (dim == 1) {
        test = (aes) {
          final p = aes.representPoint;
          return p.dx.between(start.dx, end.dx);
        };
      } else {
        test = (aes) {
          final p = aes.representPoint;
          return p.dx.between(start.dy, end.dy);
        };
      }
    }

    final rst = <int>{};
    for (var group in groups) {
      for (var aes in group) {
        if (test(aes)) {
          rst.add(aes.index);
        }
      }
    }

    if (rst.isEmpty) {
      return rst;
    }

    if (variable != null) {
      final values = Set();
      for (var index in rst) {
        values.add(tuples[index][variable]);
      }
      for (var i = 0; i < tuples.length; i++) {
        if (values.contains(tuples[i][variable])) {
          rst.add(i);
        }
      }
    }

    return rst;
  }
}

/// Renders interval selector.
List<Figure>? renderIntervalSelector(
  Offset start,
  Offset end,
  Color color,
) =>
    [
      PathFigure(
        Path()..addRect(Rect.fromPoints(start, end)),
        Paint()..color = color,
      )
    ];
