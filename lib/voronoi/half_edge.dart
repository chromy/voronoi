part of voronoi;

class HalfEdge {
  HalfEdge? edgeListLeftNeighbor;
  HalfEdge? edgeListRightNeighbor;

  Edge? edge;
  Direction direction;
  Vertex<num>? vertex;

  // the vertex's y-coordinate in the transformed Voronoi space V*
  num yStar = 0;

  /// The value used in sorting HalfEdges in the main SplayTreeMap used in Fortune's algorithm.
  int get sortHash => Point.hashCoordinates<num>(vertex?.x ?? 0, yStar);

  HalfEdge(this.edge, this.direction);

  factory HalfEdge.createDummy() => HalfEdge(null, Direction.none);

  @override
  String toString() => "Halfedge(direction: $direction, vertex: $vertex)";

  bool isLeftOf(Point<num> point) {
    if (edge == null) {
      throw ArgumentError.notNull("Halfedge.edge");
    }

    bool above;

    final Site<num> topSite = edge!.sites.right;
    final bool rightOfSite = point.x > topSite.x;

    if (rightOfSite && direction == Direction.left) {
      return true;
    }

    if (!rightOfSite && direction == Direction.right) {
      return false;
    }

    if (edge!.equation.a == 1) {
      bool fast = false;
      num dxP, dyP, dxS;

      dyP = point.y - topSite.y;
      dxP = point.x - topSite.x;
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
        dxS = topSite.x - edge!.sites.left.x;
        above = edge!.equation.b * (dxP * dxP - dyP * dyP) <
            dxS * dyP * (1 + 2 * dxP / dxS + edge!.equation.b * edge!.equation.b);
        if (edge!.equation.b < 0) {
          above = !above;
        }
      }
    } else /* edge.b == 1.0 */ {
      final num yl = edge!.equation.c - edge!.equation.a * point.x;
      final num t1 = point.y - yl;
      final num t2 = point.x - topSite.x;
      final num t3 = yl - topSite.y;
      above = t1 * t1 > t2 * t2 + t3 * t3;
    }

    return direction == Direction.left ? above : !above;
  }
}
