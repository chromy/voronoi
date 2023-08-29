part of voronoi;

class HalfEdge {
  HalfEdge? edgeListLeftNeighbor;
  HalfEdge? edgeListRightNeighbor;
  HalfEdge? nextInPriorityQueue;

  Edge? edge;
  Direction direction;
  Vertex<num>? vertex;

  // the vertex's y-coordinate in the transformed Voronoi space V*
  num yStar = 0;

  HalfEdge(this.edge, this.direction);

  factory HalfEdge.createDummy() => HalfEdge(null, Direction.none);

  @override
  String toString() => "Halfedge(direction: $direction, vertex: $vertex)";

  bool isLeftOf(Point<num> point) {
    if (edge == null) {
      throw ArgumentError.notNull("Halfedge.edge");
    }

    Site<num> topSite;
    bool rightOfSite, above, fast;
    num dxP, dyP, dxS, t1, t2, t3, yl;

    topSite = edge!.rightSite;
    rightOfSite = point.x > topSite.x;

    if (rightOfSite && direction == Direction.left) {
      return true;
    }

    if (!rightOfSite && direction == Direction.right) {
      return false;
    }

    if (edge!.a == 1.0) {
      dyP = point.y - topSite.y;
      dxP = point.x - topSite.x;
      fast = false;
      if ((!rightOfSite && edge!.b < 0.0) || (rightOfSite && edge!.b >= 0.0)) {
        above = dyP >= edge!.b * dxP;
        fast = above;
      } else {
        above = point.x + point.y * edge!.b > edge!.c;
        if (edge!.b < 0.0) {
          above = !above;
        }
        if (!above) {
          fast = true;
        }
      }
      if (!fast) {
        dxS = topSite.x - edge!.leftSite.x;
        above = edge!.b * (dxP * dxP - dyP * dyP) <
            dxS * dyP * (1.0 + 2.0 * dxP / dxS + edge!.b * edge!.b);
        if (edge!.b < 0.0) {
          above = !above;
        }
      }
    } else /* edge.b == 1.0 */ {
      yl = edge!.c - edge!.a * point.x;
      t1 = point.y - yl;
      t2 = point.x - topSite.x;
      t3 = yl - topSite.y;
      above = t1 * t1 > t2 * t2 + t3 * t3;
    }
    return direction == Direction.left ? above : !above;
  }
}
