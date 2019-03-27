import 'dart:math';
import 'package:test/test.dart';
import 'package:voronoi/voronoi.dart';

main() {
  test('lines have length', () {
    expect(LineSegment(Point(0, 0), Point(1, 0)).length, equals(1));
    expect(LineSegment(Point(0, 0), Point(0, 1)).length, equals(1));
    expect(LineSegment(Point(1, 0), Point(0, 0)).length, equals(1));
    expect(LineSegment(Point(0, 1), Point(0, 0)).length, equals(1));
    expect(LineSegment(Point(-5, 1), Point(3, 1)).length, equals(8));
    expect(LineSegment(Point(1, 1), Point(5, 4)).length, equals(5));
  });
  test('lines can be compared by length', () {
    var short = LineSegment(Point(0, 0), Point(5, 0));
    var long = LineSegment(Point(0, 0), Point(6, 0));
    expect(short.compareLength(long), lessThan(0));
    expect(long.compareLength(short), greaterThan(0));
    expect(long.compareLength(long), equals(0));
    expect(short.compareLength(short), equals(0));
  });
}
