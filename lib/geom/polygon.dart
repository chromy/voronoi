part of voronoi;

class Polygon<T extends num> extends ListBase<Point<T>> {
  final List<Point<T>> _vertices;

  Polygon(this._vertices);

  num get area => (signedDoubleArea() * 0.5).abs();

  Winding get winding {
    final num theSignedDoubleArea = signedDoubleArea();
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
    final int n = length;
    Point<num> point;
    Point<num> next;
    num signedDoubleArea = 0;
    for (index = 0; index < n; ++index) {
      nextIndex = (index + 1) % n;
      point = this[index];
      next = this[nextIndex];
      signedDoubleArea += point.x * next.y - next.x * point.y;
    }
    return signedDoubleArea;
  }

  @override
  int get length => _vertices.length;

  @override
  set length(int newLength) => _vertices.length = newLength;

  @override
  Point<T> operator [](int index) => _vertices[index];

  @override
  void operator []=(int index, Point<T> value) => _vertices[index] = value;
}
