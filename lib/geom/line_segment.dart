part of voronoi;

class LineSegment {
  Point? p0;
  Point? p1;

  LineSegment(this.p0, this.p1);

  num? get length {
    if (p0 == null || p1 == null) {
      return null;
    }

    return (p0!.distanceTo(p1!)).abs();
  }

  num? compareLength(LineSegment other) {
    if (length == null || other.length == null) {
      return null;
    }

    return length! - other.length!;
  }
}
