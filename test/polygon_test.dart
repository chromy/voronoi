import 'dart:math';
import 'package:test/test.dart';
import 'package:voronoi/voronoi.dart';

void main() {
  final Polygon smallSquare =
      Polygon(<Point<int>>[const Point<int>(0, 0), const Point<int>(1, 0), const Point<int>(1, 1), const Point<int>(0, 1)]);
  final Polygon bigSquare = Polygon(<Point<int>>[const Point<int>(0, 0), const Point<int>(0, 5), const Point<int>(5, 5), const Point<int>(5, 0)]);
  test('polygons have area', () {
    expect(smallSquare.area, equals(1));
    expect(bigSquare.area, equals(25));
  });
  test('polygons have winding', () {
    expect(smallSquare.winding, equals(Winding.counterclockwise));
    expect(bigSquare.winding, equals(Winding.clockwise));
  });
}
