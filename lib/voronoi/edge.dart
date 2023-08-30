part of voronoi;

/// The line segment connecting the two Sites is part of the Delaunay triangulation;
/// the line segment connecting the two Vertices is part of the Voronoi diagram
class Edge {
  static final Edge deleted = Edge();

  // the two input Sites for which this Edge is a bisector:
  late OrientedPair<Site<num>> sites;

  // the two Voronoi vertices that the edge connects (if one of them is null, the edge extends to infinity)
  OrientedPair<Vertex<num>?> vertices = OrientedPair<Vertex<num>?>(null, null);

  OrientedPair<Point<num>?> _clippedVertices = OrientedPair<Point<num>?>(null, null);

  Point<num>? get leftClippedEnd => _clippedVertices.left;

  Point<num>? get rightClippedEnd => _clippedVertices.right;

  // the equation of the edge: ax + by = c
  late num a, b, c;

  Edge();

  /// This is the only way to create a new Edge
  factory Edge.createBisectingEdge(Site<num> site0, Site<num> site1) {
    num dx, dy, absDx, absDy;
    num a, b, c;

    dx = site1.x - site0.x;
    dy = site1.y - site0.y;
    absDx = dx > 0 ? dx : -dx;
    absDy = dy > 0 ? dy : -dy;
    c = site0.x * dx + site0.y * dy + (dx * dx + dy * dy) * 0.5;
    if (absDx > absDy) {
      a = 1.0;
      b = dy / dx;
      c /= dx;
    } else {
      b = 1.0;
      a = dx / dy;
      c /= dy;
    }

    final Edge edge = Edge()
      ..sites = OrientedPair<Site<num>>(site0, site1)
      ..vertices.both = null
      ..a = a
      ..b = b
      ..c = c
      .._clippedVertices.both = null;

    site0.addEdge(edge);
    site1.addEdge(edge);

    return edge;
  }

  // draw a line connecting the input Sites for which the edge is a bisector:
  LineSegment<Point<num>> delaunayLine() => LineSegment<Point<num>>.fromOrientedPair(sites);

  // Return a LineSegment representing the edge, or null if the edge isn't visible
  LineSegment<Point<num>>? voronoiEdge() =>
      visible ? LineSegment<Point<num>>.fromOrientedPair(_clippedVertices as OrientedPair<Vertex<num>>) : null;

  bool isPartOfConvexHull() => !vertices.isDefined(Direction.both);

  num sitesDistance() => sites.left.distanceTo(sites.right);

  static int compareSitesDistances(Edge e1, Edge e2) => e1.sitesDistance().compareTo(e2.sitesDistance());

  // Once clipVertices() is called, this object will hold two Points
  // representing the clipped coordinates of the left and right ends...
  OrientedPair<Point<num>?> get clippedEnds => _clippedVertices;

  // The only edges that should be visible are those whose clipped vertices are both non-null.
  bool get visible => !_clippedVertices.isDefined(Direction.none);

  /// Set _clippedVertices to contain the two ends of the portion of the Voronoi edge that is visible
  /// within the bounds.  If no part of the Edge falls within the bounds, leave _clippedVertices null.
  /// @param bounds
  ///
  void clipVertices(math.Rectangle<num> bounds) {
    final num xMin = bounds.left;
    final num yMin = bounds.top;
    final num xMax = bounds.right;
    final num yMax = bounds.bottom;

    Vertex<num>? vertex0, vertex1;
    num x0, x1, y0, y1;

    _clippedVertices = OrientedPair<Point<num>?>(null, null);

    if (a == 1.0 && b >= 0.0) {
      vertex0 = vertices.right;
      vertex1 = vertices.left;
    } else {
      vertex0 = vertices.left;
      vertex1 = vertices.right;
    }

    if (a == 1.0) {
      y0 = yMin;
      if (vertex0 != null && vertex0.y > yMin) {
        y0 = vertex0.y;
      }
      if (y0 > yMax) {
        return;
      }
      x0 = c - b * y0;

      y1 = yMax;
      if (vertex1 != null && vertex1.y < yMax) {
        y1 = vertex1.y;
      }
      if (y1 < yMin) {
        return;
      }
      x1 = c - b * y1;

      if ((x0 > xMax && x1 > xMax) || (x0 < xMin && x1 < xMin)) {
        return;
      }

      if (x0 > xMax) {
        x0 = xMax;
        y0 = (c - x0) / b;
      } else if (x0 < xMin) {
        x0 = xMin;
        y0 = (c - x0) / b;
      }

      if (x1 > xMax) {
        x1 = xMax;
        y1 = (c - x1) / b;
      } else if (x1 < xMin) {
        x1 = xMin;
        y1 = (c - x1) / b;
      }
    } else {
      x0 = xMin;
      if (vertex0 != null && vertex0.x > xMin) {
        x0 = vertex0.x;
      }
      if (x0 > xMax) {
        return;
      }
      y0 = c - a * x0;

      x1 = xMax;
      if (vertex1 != null && vertex1.x < xMax) {
        x1 = vertex1.x;
      }
      if (x1 < xMin) {
        return;
      }
      y1 = c - a * x1;

      if ((y0 > yMax && y1 > yMax) || (y0 < yMin && y1 < yMin)) {
        return;
      }

      if (y0 > yMax) {
        y0 = yMax;
        x0 = (c - y0) / a;
      } else if (y0 < yMin) {
        y0 = yMin;
        x0 = (c - y0) / a;
      }

      if (y1 > yMax) {
        y1 = yMax;
        x1 = (c - y1) / a;
      } else if (y1 < yMin) {
        y1 = yMin;
        x1 = (c - y1) / a;
      }
    }

    if (vertex0 == vertices.left) {
      _clippedVertices
        ..left = Point<num>(x0, y0)
        ..right = Point<num>(x1, y1);
    } else {
      _clippedVertices
        ..right = Point<num>(x0, y0)
        ..left = Point<num>(x1, y1);
    }
  }
}
