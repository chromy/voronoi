part of voronoi;

class Point<T extends num> extends math.Point<T> implements Comparable<Point<T>> {
  /// This value is arbitrary, and chosen to allow for sufficiently large (in pixel count) space without losing "subpixel" resolution.
  static const int maxValue = 5000;

  /// For the purposes of sorting and equality, all [Point]s are considered to be bound to a lattice which has values [epsilon] pixels apart. This value is derived from the idea of wanting to be able to support a resolution of 5000 (pixels) in each dimension. Constraints in mapping ℝ²→ℕ limits the distinct coordinates that can be used per pixel to 2^26 / 5000 = ~13,400, with [epsilon] taking the value of that number's inverse.
  static const num epsilon = .000075;

  /// A number for use in the [hashCode] method, precomputed to increase hashCode computation speed.
  static const num yScaling = maxValue / epsilon / epsilon;

  const Point(super.x, super.y);

  @override
  int compareTo(Point<T> other) => this.hashCode - other.hashCode;

  @override

  /// [Point]s are considered to be equal if both components of their coordinates are close enough that they are within [epsilon] pixels of one another.
  bool operator ==(Object other) => other is Point<T> && hashCode == other.hashCode;

  @override
  //±2^53 is the limit for ints in javascript, so constrain the hash space to 2^26 for each of the x and y components.
  int get hashCode => (y * yScaling).floor() + (x / epsilon).floor();
}
