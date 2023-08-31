part of voronoi;

/// The line segment connecting the two Sites is part of the Delaunay triangulation;
/// the line segment connecting the two Vertices is part of the Voronoi diagram
class Edge {
  static final Edge deleted = Edge();

  // the two input Sites for which this Edge is a bisector:
  late OrientedPair<Site<num>> sites;

  Direction direction = Direction.none;

  // the two Voronoi vertices that the edge connects (if one of them is null, the edge extends to infinity)
  OrientedPair<Vertex<num>?> vertices = OrientedPair<Vertex<num>?>(null, null);

  OrientedPair<Point<num>?> clippedVertices = OrientedPair<Point<num>?>(null, null);

  // the equation of the edge: ax + by = c
  late ({num a, num b, num c}) equation;

  Edge();

  Edge.fromOther(Edge edge) {
    sites = edge.sites;
    direction = edge.direction;
    vertices = edge.vertices;
    clippedVertices = edge.clippedVertices;
    equation = edge.equation;
  }

  /// This is the only way to create a new Edge
  factory Edge.createBisectingEdge(Site<num> site0, Site<num> site1) {
    ({num a, num b, num c}) equation;

    final num dx = site1.x - site0.x;
    final num dy = site1.y - site0.y;
    final num c = site0.x * dx + site0.y * dy + (dx * dx + dy * dy) / 2;
    if (dx.abs() > dy.abs()) {
      equation = (a: 1, b: dy / dx, c: c / dx);
    } else {
      equation = (a: dx / dy, b: 1, c: c / dy);
    }

    final Edge edge = Edge()
      ..sites = OrientedPair<Site<num>>(site0, site1)
      ..vertices.both = null
      ..clippedVertices.both = null
      ..equation = equation;

    site0.addEdge(edge);
    site1.addEdge(edge);

    return edge;
  }

  // draw a line connecting the input Sites for which the edge is a bisector:
  LineSegment<Point<num>> delaunayLine() => LineSegment<Point<num>>.fromOrientedPair(sites);

  // Return a LineSegment representing the edge, or null if the edge isn't visible
  LineSegment<Point<num>>? voronoiEdge() =>
      visible ? LineSegment<Point<num>>.fromOrientedPair(clippedVertices as OrientedPair<Vertex<num>>) : null;

  bool isPartOfConvexHull() => !vertices.isDefined(Direction.both);

  num sitesDistance() => sites.left.distanceTo(sites.right);

  // The only edges that should be visible are those whose clipped vertices are both non-null.
  bool get visible => !clippedVertices.isDefined(Direction.none);

  /// Set _clippedVertices to contain the two ends of the portion of the Voronoi edge that is visible
  /// within the bounds.  If no part of the Edge falls within the bounds, leave _clippedVertices null.
  void clipVertices(math.Rectangle<num> bounds) {
    final num xMin = bounds.left;
    final num yMin = bounds.top;
    final num xMax = bounds.right;
    final num yMax = bounds.bottom;

    Vertex<num>? vertex0, vertex1;

    if (equation.a == 1.0 && equation.b >= 0.0) {
      vertex0 = vertices.right;
      vertex1 = vertices.left;
    } else {
      vertex0 = vertices.left;
      vertex1 = vertices.right;
    }

    num x0, x1, y0, y1;
    if (equation.a == 1.0) {
      y0 = yMin;
      if (vertex0 != null && vertex0.y > yMin) {
        y0 = vertex0.y;
      }
      if (y0 > yMax) {
        return;
      }
      x0 = equation.c - equation.b * y0;

      y1 = yMax;
      if (vertex1 != null && vertex1.y < yMax) {
        y1 = vertex1.y;
      }
      if (y1 < yMin) {
        return;
      }
      x1 = equation.c - equation.b * y1;

      if ((x0 > xMax && x1 > xMax) || (x0 < xMin && x1 < xMin)) {
        return;
      }

      if (x0 > xMax) {
        x0 = xMax;
        y0 = (equation.c - x0) / equation.b;
      } else if (x0 < xMin) {
        x0 = xMin;
        y0 = (equation.c - x0) / equation.b;
      }

      if (x1 > xMax) {
        x1 = xMax;
        y1 = (equation.c - x1) / equation.b;
      } else if (x1 < xMin) {
        x1 = xMin;
        y1 = (equation.c - x1) / equation.b;
      }
    } else {
      x0 = xMin;
      if (vertex0 != null && vertex0.x > xMin) {
        x0 = vertex0.x;
      }
      if (x0 > xMax) {
        return;
      }
      y0 = equation.c - equation.a * x0;

      x1 = xMax;
      if (vertex1 != null && vertex1.x < xMax) {
        x1 = vertex1.x;
      }
      if (x1 < xMin) {
        return;
      }
      y1 = equation.c - equation.a * x1;

      if ((y0 > yMax && y1 > yMax) || (y0 < yMin && y1 < yMin)) {
        return;
      }

      if (y0 > yMax) {
        y0 = yMax;
        x0 = (equation.c - y0) / equation.a;
      } else if (y0 < yMin) {
        y0 = yMin;
        x0 = (equation.c - y0) / equation.a;
      }

      if (y1 > yMax) {
        y1 = yMax;
        x1 = (equation.c - y1) / equation.a;
      } else if (y1 < yMin) {
        y1 = yMin;
        x1 = (equation.c - y1) / equation.a;
      }
    }

    clippedVertices = OrientedPair<Point<num>?>(null, null);

    if (vertex0 == vertices.left) {
      clippedVertices
        ..left = Point<num>(x0, y0)
        ..right = Point<num>(x1, y1);
    } else {
      clippedVertices
        ..right = Point<num>(x0, y0)
        ..left = Point<num>(x1, y1);
    }
  }
}
