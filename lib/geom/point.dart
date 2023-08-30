part of voronoi;

class Point<T extends num> extends math.Point<T> implements Comparable<Point<T>> {
  /// This value is arbitrary, and chosen to allow for sufficiently large (in pixel count) space without losing "subpixel" resolution. Note that this is not an enforced maximum, but [x] and [y] values with a magnitude larger than this value may result in undesired behavior.
  static const int maxValue = 5000;

  /// For the purposes of sorting and equality, all [Point]s are considered to be bound to a lattice which has values [epsilon] pixels apart. This value is derived from the idea of wanting to be able to support a resolution of ±5000 (pixels) in each dimension. Constraints in mapping ℝ²→ℕ limits the unique values that can be used for each dimension to ±2^26, as a consequence of the fact that ±2^53 is the limit for ints in javascript. As a result, the number of distinct values that can be used per pixel is 2^26 / 5000 = ~13,400, with [epsilon] being defined as that number's inverse.
  static const num epsilon = .000075;

  /// A number for use in the [hashCode] method, precomputed to increase hashCode computation speed.
  static const num yScaling = maxValue / epsilon / epsilon;

  const Point(super.x, super.y);

  Point.fromMathPoint(math.Point<T> point) : super(point.x, point.y);

  @override
  int compareTo(Point<T> other) => this.hashCode - other.hashCode;

  @override

  /// [Point]s are considered to be equal if both components of their coordinates are close enough that they are within [epsilon] pixels of one another.
  bool operator ==(Object other) => other is Point<T> && hashCode == other.hashCode;

  @override
  int get hashCode => hashCoordinates(x, y);

  /// Calculates the hashCode for this object consistent with the idea that two [Point]s with coordinates that differ by no more than [epsilon] are considered equal, and with changes in value of [y] being more meaningful than changes in [x]. As a performance optimization, this is a static method to allow for other classes to also use this logic without having to fully instantiate a [Point] object.
  static int hashCoordinates<T extends num>(T x, T y) => (y * yScaling).floor() + (x / epsilon).floor();
}
