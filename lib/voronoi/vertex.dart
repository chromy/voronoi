part of voronoi;

class Vertex<T extends num> extends Point<T> {
  static final Vertex<double> vertexAtInfinity = Vertex<double>(double.infinity, double.infinity);
  static int _vertexCount = 0;

  int _vertexIndex = 0;

  Vertex(super.x, super.y);

  @override
  String toString() => "Vertex($x, $y)";

  static Vertex<num>? intersect(Edge? edge0, Edge? edge1) {
    if (edge0 == null || edge1 == null || edge0.sites.right == edge1.sites.right) {
      return null;
    }

    final num determinant = edge0.equation.a * edge1.equation.b - edge0.equation.b * edge1.equation.a;
    if (determinant.abs() < 1.0e-10) {
      // the edges are parallel
      return null;
    }

    final Point<num> intersection = Point<num>(
        (edge0.equation.c * edge1.equation.b - edge1.equation.c * edge0.equation.b) / determinant,
        (edge1.equation.c * edge0.equation.a - edge0.equation.c * edge1.equation.a) / determinant);

    if (intersection.x.isNaN || intersection.y.isNaN) {
      return null;
    }

    final Edge edge = edge0.sites.right.compareTo(edge1.sites.right) < 0 ? edge0 : edge1;

    final bool rightOfSite = intersection.x >= edge.sites.right.x;
    if ((rightOfSite && edge.direction == Direction.left) || (!rightOfSite && edge.direction == Direction.right)) {
      return null;
    }

    return Vertex<num>(intersection.x, intersection.y);
  }

  int get vertexIndex => _vertexIndex;

  void setIndex() => _vertexIndex = _vertexCount++;
}
