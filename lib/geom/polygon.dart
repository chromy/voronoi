part of voronoi;

class Polygon {
  List<Point> vertices;

  Polygon(List<Point> this.vertices);

  num get area => (signedDoubleArea() * 0.5).abs();

  Winding get winding {
    num theSignedDoubleArea = signedDoubleArea();
    if (theSignedDoubleArea < 0) {
      return Winding.clockwise;
    }
    if (theSignedDoubleArea > 0) {
      return Winding.counterclockwise;
    }
    return Winding.none;
  }

  num signedDoubleArea() {
    int index;
    int nextIndex;
    int n = vertices.length;
    Point point;
    Point next;
    num signedDoubleArea = 0;
    for (index = 0; index < n; ++index) {
      nextIndex = (index + 1) % n;
      point = vertices[index];
      next = vertices[nextIndex];
      signedDoubleArea += point.x * next.y - next.x * point.y;
    }
    return signedDoubleArea;
  }
}
