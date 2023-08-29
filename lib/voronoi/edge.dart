part of voronoi;

/// The line segment connecting the two Sites is part of the Delaunay triangulation;
/// the line segment connecting the two Vertices is part of the Voronoi diagram
class Edge {
  static final Edge deleted = Edge();

  // the two input Sites for which this Edge is a bisector:
  late Site<num> leftSite;
  late Site<num> rightSite;

  // the two Voronoi vertices that the edge connects
  //    (if one of them is null, the edge extends to infinity)
  late Vertex<num>? leftVertex;
  late Vertex<num>? rightVertex;

  Point<num>? get leftClippedEnd => _clippedVertices?[Direction.left];

  Point<num>? get rightClippedEnd => _clippedVertices?[Direction.right];

  // the equation of the edge: ax + by = c
  late num a, b, c;

  late Map<Direction, Point<num>>? _clippedVertices;

  Edge();

  /// This is the only way to create a new Edge
  /// @param site0
  /// @param site1
  /// @return
  ///
  factory Edge.createBisectingEdge(Site<num> site0, Site<num> site1) {
    num dx, dy, absdx, absdy;
    num a, b, c;

    dx = site1.x - site0.x;
    dy = site1.y - site0.y;
    absdx = dx > 0 ? dx : -dx;
    absdy = dy > 0 ? dy : -dy;
    c = site0.x * dx + site0.y * dy + (dx * dx + dy * dy) * 0.5;
    if (absdx > absdy) {
      a = 1.0;
      b = dy / dx;
      c /= dx;
    } else {
      b = 1.0;
      a = dx / dy;
      c /= dy;
    }

    final Edge edge = Edge()
      ..leftSite = site0
      ..rightSite = site1
      ..leftVertex = null
      ..rightVertex = null
      ..a = a
      ..b = b
      ..c = c
      .._clippedVertices = null;

    site0.addEdge(edge);
    site1.addEdge(edge);

    return edge;
  }

  // draw a line connecting the input Sites for which the edge is a bisector:
  LineSegment delaunayLine() => LineSegment(leftSite, rightSite);

  LineSegment? voronoiEdge() {
    // Return null if the edge isn't visible, or its clippedVertices don't exist.
    if (!visible ||
        _clippedVertices == null ||
        _clippedVertices![Direction.left] == null ||
        _clippedVertices![Direction.right] == null) {
      return null;
    } else {
      return LineSegment(_clippedVertices![Direction.left]!, _clippedVertices![Direction.right]!);
    }
  }

  Vertex<num>? vertex(Direction leftRight) => (leftRight == Direction.left) ? leftVertex : rightVertex;

  void setVertex(Direction leftRight, Vertex<num> v) {
    if (leftRight == Direction.left) {
      leftVertex = v;
    } else {
      rightVertex = v;
    }
  }

  Site<num>? site(Direction direction) {
    if (direction == Direction.none) {
      return null;
    }

    return (direction == Direction.left) ? leftSite : rightSite;
  }

  bool isPartOfConvexHull() => leftVertex == null || rightVertex == null;

  num sitesDistance() => leftSite.distanceTo(rightSite);

  static int compareSitesDistances(Edge e1, Edge e2) => e1.sitesDistance().compareTo(e2.sitesDistance());

  // Once clipVertices() is called, this Dictionary will hold two Points
  // representing the clipped coordinates of the left and right ends...
  Map<Direction, Point<num>>? get clippedEnds => _clippedVertices;

  // unless the entire Edge is outside the bounds.
  // In that case visible will be false:
  bool get visible => _clippedVertices != null;

  /// Set _clippedVertices to contain the two ends of the portion of the Voronoi edge that is visible
  /// within the bounds.  If no part of the Edge falls within the bounds, leave _clippedVertices null.
  /// @param bounds
  ///
  void clipVertices(Rectangle<num> bounds) {
    final num xmin = bounds.left;
    final num ymin = bounds.top;
    final num xmax = bounds.right;
    final num ymax = bounds.bottom;

    Vertex<num>? vertex0, vertex1;
    num x0, x1, y0, y1;

    if (a == 1.0 && b >= 0.0) {
      vertex0 = rightVertex;
      vertex1 = leftVertex;
    } else {
      vertex0 = leftVertex;
      vertex1 = rightVertex;
    }

    if (a == 1.0) {
      y0 = ymin;
      if (vertex0 != null && vertex0.y > ymin) {
        y0 = vertex0.y;
      }
      if (y0 > ymax) {
        return;
      }
      x0 = c - b * y0;

      y1 = ymax;
      if (vertex1 != null && vertex1.y < ymax) {
        y1 = vertex1.y;
      }
      if (y1 < ymin) {
        return;
      }
      x1 = c - b * y1;

      if ((x0 > xmax && x1 > xmax) || (x0 < xmin && x1 < xmin)) {
        return;
      }

      if (x0 > xmax) {
        x0 = xmax;
        y0 = (c - x0) / b;
      } else if (x0 < xmin) {
        x0 = xmin;
        y0 = (c - x0) / b;
      }

      if (x1 > xmax) {
        x1 = xmax;
        y1 = (c - x1) / b;
      } else if (x1 < xmin) {
        x1 = xmin;
        y1 = (c - x1) / b;
      }
    } else {
      x0 = xmin;
      if (vertex0 != null && vertex0.x > xmin) {
        x0 = vertex0.x;
      }
      if (x0 > xmax) {
        return;
      }
      y0 = c - a * x0;

      x1 = xmax;
      if (vertex1 != null && vertex1.x < xmax) {
        x1 = vertex1.x;
      }
      if (x1 < xmin) {
        return;
      }
      y1 = c - a * x1;

      if ((y0 > ymax && y1 > ymax) || (y0 < ymin && y1 < ymin)) {
        return;
      }

      if (y0 > ymax) {
        y0 = ymax;
        x0 = (c - y0) / a;
      } else if (y0 < ymin) {
        y0 = ymin;
        x0 = (c - y0) / a;
      }

      if (y1 > ymax) {
        y1 = ymax;
        x1 = (c - y1) / a;
      } else if (y1 < ymin) {
        y1 = ymin;
        x1 = (c - y1) / a;
      }
    }

    _clippedVertices = <Direction, Point<num>>{};
    if (vertex0 == leftVertex) {
      _clippedVertices?[Direction.left] = Point<num>(x0, y0);
      _clippedVertices?[Direction.right] = Point<num>(x1, y1);
    } else {
      _clippedVertices?[Direction.right] = Point<num>(x0, y0);
      _clippedVertices?[Direction.left] = Point<num>(x1, y1);
    }
  }
}
