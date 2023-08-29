part of voronoi;

class Vertex<T extends num> extends Point<T> {
  static final Vertex<double> vertexAtInfinity = Vertex<double>(double.nan, double.nan);
  static int _vertexCount = 0;

  int _vertexIndex = 0;

  Vertex(super.x, super.y);

  static Vertex<num> create<T extends num>(T x, T y) {
    if (x.isNaN || y.isNaN) {
      return vertexAtInfinity;
    }

    return Vertex<T>(x, y);
  }

  @override
  String toString() => "Vertex($x, $y)";

  static Vertex<num>? intersect(Halfedge halfEdge0, Halfedge halfEdge1) {
    Edge? edge0, edge1, edge;
    Halfedge halfEdge;
    num determinant, intersectionX, intersectionY;
    bool rightOfSite;

    edge0 = halfEdge0.edge;
    edge1 = halfEdge1.edge;

    if (edge0 == null || edge1 == null || edge0.rightSite == edge1.rightSite) {
      return null;
    }

    determinant = edge0.a * edge1.b - edge0.b * edge1.a;
    if (-1.0e-10 < determinant && determinant < 1.0e-10) {
      // the edges are parallel
      return null;
    }

    intersectionX = (edge0.c * edge1.b - edge1.c * edge0.b) / determinant;
    intersectionY = (edge1.c * edge0.a - edge0.c * edge1.a) / determinant;

    if (Voronoi.compareByYThenX(edge0.rightSite, edge1.rightSite) < 0) {
      halfEdge = halfEdge0;
      edge = edge0;
    } else {
      halfEdge = halfEdge1;
      edge = edge1;
    }
    rightOfSite = intersectionX >= edge.rightSite.x;
    if ((rightOfSite && halfEdge.leftRight == Direction.left) ||
        (!rightOfSite && halfEdge.leftRight == Direction.right)) {
      return null;
    }

    return Vertex.create(intersectionX, intersectionY);
  }

  int get vertexIndex => _vertexIndex;

  void setIndex() => _vertexIndex = _vertexCount++;
}
