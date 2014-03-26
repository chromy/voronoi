import 'dart:math';
import 'package:unittest/unittest.dart';
import 'package:voronoi/voronoi.dart';

main() {
  test('lines have length', () {
    expect(new LineSegment(new Point(0,0), new Point(1,0)).length, equals(1));
    expect(new LineSegment(new Point(0,0), new Point(0,1)).length, equals(1));
    expect(new LineSegment(new Point(1,0), new Point(0,0)).length, equals(1));
    expect(new LineSegment(new Point(0,1), new Point(0,0)).length, equals(1));
    expect(new LineSegment(new Point(-5,1), new Point(3,1)).length, equals(8));
    expect(new LineSegment(new Point(1,1), new Point(5,4)).length, equals(5));
  });
  test('lines can be compared by length', () {
    var short = new LineSegment(new Point(0,0), new Point(5,0));
    var long = new LineSegment(new Point(0,0), new Point(6,0));
    expect(short.compareLength(long), lessThan(0));
    expect(long.compareLength(short), greaterThan(0));
    expect(long.compareLength(long), equals(0));
    expect(short.compareLength(short), equals(0));
  });
}