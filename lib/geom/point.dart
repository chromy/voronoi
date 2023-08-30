part of voronoi;

class Point<T extends num> extends math.Point<T> implements Comparable<Point<T>> {
  const Point(super.x, super.y);

  @override
  int compareTo(Point<T> other) {
    final int yComparison = y.compareTo(other.y);
    return yComparison != 0 ? yComparison : x.compareTo(other.x);
  }
}
