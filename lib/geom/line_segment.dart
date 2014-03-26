part of voronoi;

class LineSegment {

  Point p0;
  Point p1;

  LineSegment(Point p0, Point p1) {
    this.p0 = p0;
    this.p1 = p1;
  }
  
  get length => (p0.distanceTo(p1)).abs();
  
  num compareLength(LineSegment other) {
    return length - other.length;
  }
}