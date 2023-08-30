import 'package:test/test.dart';
import 'package:voronoi/voronoi.dart';

void main() {
  test('lines have length', () {
    expect(LineSegment(const Point<int>(0, 0), const Point<int>(1, 0)).length, equals(1));
    expect(LineSegment(const Point<int>(0, 0), const Point<int>(0, 1)).length, equals(1));
    expect(LineSegment(const Point<int>(1, 0), const Point<int>(0, 0)).length, equals(1));
    expect(LineSegment(const Point<int>(0, 1), const Point<int>(0, 0)).length, equals(1));
    expect(LineSegment(const Point<int>(-5, 1), const Point<int>(3, 1)).length, equals(8));
    expect(LineSegment(const Point<int>(1, 1), const Point<int>(5, 4)).length, equals(5));
  });
  test('lines can be compared by length', () {
    final LineSegment short = LineSegment(const Point<int>(0, 0), const Point<int>(5, 0));
    final LineSegment long = LineSegment(const Point<int>(0, 0), const Point<int>(6, 0));
    expect(short.compareLength(long), lessThan(0));
    expect(long.compareLength(short), greaterThan(0));
    expect(long.compareLength(long), equals(0));
    expect(short.compareLength(short), equals(0));
  });
}
