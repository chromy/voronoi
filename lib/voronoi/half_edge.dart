part of voronoi;

class Halfedge {
  Halfedge? edgeListLeftNeighbor;
  Halfedge? edgeListRightNeighbor;
  Halfedge? nextInPriorityQueue;

  Edge? edge;
  LR? leftRight;
  Vertex? vertex;

  // the vertex's y-coordinate in the transformed Voronoi space V*
  num ystar = 0;

  Halfedge(this.edge, this.leftRight);

  factory Halfedge.createDummy() {
    return Halfedge(null, null);
  }

  String toString() {
    return "Halfedge(leftRight: $leftRight, vertex: $vertex)";
  }

  bool isLeftOf(Point<num> p) {
    if (edge == null) {
      throw ArgumentError.notNull("Halfedge.edge");
    }

    Site topSite;
    bool rightOfSite, above, fast;
    num dxp, dyp, dxs, t1, t2, t3, yl;

    topSite = edge!.rightSite;
    rightOfSite = p.x > topSite.x;

    if (rightOfSite && this.leftRight == LR.LEFT) {
      return true;
    }

    if (!rightOfSite && this.leftRight == LR.RIGHT) {
      return false;
    }

    if (edge!.a == 1.0) {
      dyp = p.y - topSite.y;
      dxp = p.x - topSite.x;
      fast = false;
      if ((!rightOfSite && edge!.b < 0.0) || (rightOfSite && edge!.b >= 0.0)) {
        above = dyp >= edge!.b * dxp;
        fast = above;
      } else {
        above = p.x + p.y * edge!.b > edge!.c;
        if (edge!.b < 0.0) {
          above = !above;
        }
        if (!above) {
          fast = true;
        }
      }
      if (!fast) {
        dxs = topSite.x - edge!.leftSite.x;
        above = edge!.b * (dxp * dxp - dyp * dyp) <
            dxs * dyp * (1.0 + 2.0 * dxp / dxs + edge!.b * edge!.b);
        if (edge!.b < 0.0) {
          above = !above;
        }
      }
    } else /* edge.b == 1.0 */ {
      yl = edge!.c - edge!.a * p.x;
      t1 = p.y - yl;
      t2 = p.x - topSite.x;
      t3 = yl - topSite.y;
      above = t1 * t1 > t2 * t2 + t3 * t3;
    }
    return this.leftRight == LR.LEFT ? above : !above;
  }
}
