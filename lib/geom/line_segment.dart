part of voronoi;

class LineSegment {
  Point<num> p0;
  Point<num> p1;

  LineSegment(this.p0, this.p1);

  num get length => p0.distanceTo(p1).abs();

  num get squaredLength => p0.squaredDistanceTo(p1);

  num compareLength(LineSegment other) => squaredLength - other.squaredLength;
}
