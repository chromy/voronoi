import 'dart:math';
import 'package:unittest/unittest.dart';
import 'package:diagram/voronoi.dart';

main() {
  var smallSquare = new Polygon([new Point(0,0), new Point(1,0), new Point(1,1), new Point(0,1)]);
  var bigSquare = new Polygon([new Point(0,0), new Point(0,5), new Point(5,5), new Point(5,0)]);
  test('polygons have area', () {
    expect(smallSquare.area, equals(1));
    expect(bigSquare.area, equals(25));
  });
  test('polygons have winding', () {
    expect(smallSquare.winding, equals(Winding.COUNTERCLOCKWISE));
    expect(bigSquare.winding, equals(Winding.CLOCKWISE));
  });
}