part of voronoi;

class Triangle<T extends num> {
  List<Point<T>> get points => <Point<T>>[a, b, c];
  final Point<T> a;
  final Point<T> b;
  final Point<T> c;

  const Triangle(this.a, this.b, this.c);
}
