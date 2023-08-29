import 'dart:math';
import 'package:test/test.dart';
import 'package:voronoi/voronoi.dart';

main() {
  var smallSquare =
      Polygon([Point(0, 0), Point(1, 0), Point(1, 1), Point(0, 1)]);
  var bigSquare = Polygon([Point(0, 0), Point(0, 5), Point(5, 5), Point(5, 0)]);
  test('polygons have area', () {
    expect(smallSquare.area, equals(1));
    expect(bigSquare.area, equals(25));
  });
  test('polygons have winding', () {
    expect(smallSquare.winding, equals(Winding.counterclockwise));
    expect(bigSquare.winding, equals(Winding.clockwise));
  });
}
