part of voronoi;

class Triangle<T extends num> extends Polygon<T> {
  final Point<T> a;
  final Point<T> b;
  final Point<T> c;

  Triangle(this.a, this.b, this.c) : super(<Point<T>>[a, b, c]);
}
