part of voronoi;

class HalfEdge {
  HalfEdge? edgeListLeftNeighbor;
  HalfEdge? edgeListRightNeighbor;

  Edge? edge;

  Point<num>? vertex;

  // the vertex's y-coordinate in the transformed Voronoi space V*
  num yStar = 0;

  /// The value used in sorting HalfEdges in the main SplayTreeMap used in Fortune's algorithm.
  int get sortHash => Point.hashCoordinates<num>(vertex?.x ?? 0, yStar);

  HalfEdge(this.edge);

  factory HalfEdge.createDummy() => HalfEdge(null);

  @override
  String toString() => "Halfedge(edge: $edge, vertex: $vertex)";

  bool isLeftOf(Point<num> point) {
    if (edge == null) {
      throw ArgumentError.notNull("Halfedge.edge");
    }

    bool above;

    final Site<num> topSite = edge!.sites.right;
    final bool rightOfSite = point.x > topSite.x;

    if (rightOfSite && edge!.direction == Direction.left) {
      return true;
    }

    if (!rightOfSite && edge!.direction == Direction.right) {
      return false;
    }

    if (edge!.equation.a == 1) /* The edge is more horizontal than it is vertical */ {
      bool fast = false;
      final num dyP = point.y - topSite.y;
      final num dxP = point.x - topSite.x;
      if ((!rightOfSite && edge!.equation.b < 0) || (rightOfSite && edge!.equation.b >= 0)) {
        above = dyP >= edge!.equation.b * dxP;
        fast = above;
      } else {
        above = point.x + point.y * edge!.equation.b > edge!.equation.c;
        if (edge!.equation.b < 0) {
          above = !above;
        }
        if (!above) {
          fast = true;
        }
      }
      if (!fast) {
        final num dxS = topSite.x - edge!.sites.left.x;
        above = edge!.equation.b * (dxP * dxP - dyP * dyP) <
            dxS * dyP * (1 + 2 * dxP / dxS + edge!.equation.b * edge!.equation.b);
        if (edge!.equation.b < 0) {
          above = !above;
        }
      }
    } else /* edge.equation.b == 1, the edge is more vertical than horizontal */ {
      final num yl = edge!.equation.c - edge!.equation.a * point.x; // Solving the edge's equation at point.x
      final num t1 = point.y - yl; // How far above the edge the point is vertically
      final num t2 = point.x - topSite.x; // How far to the right of topSite the point is
      final num t3 = yl - topSite.y; // How far above the topSite the edge is
      above = t1 * t1 > t2 * t2 + t3 * t3;
    }

    return edge!.direction == Direction.left ? above : !above;
  }
}
