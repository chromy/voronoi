part of voronoi;

class LineSegment<T extends Point<num>> {
  T p0;
  T p1;

  LineSegment(this.p0, this.p1);

  LineSegment.fromOrientedPair(OrientedPair<T> pair) : this(pair.left, pair.right);

  num get length => p0.distanceTo(p1).abs();

  num get squaredLength => p0.squaredDistanceTo(p1);

  num compareLength(LineSegment<dynamic> other) => squaredLength - other.squaredLength;
}
