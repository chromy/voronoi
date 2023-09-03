part of voronoi;

/// The line segment connecting the two Sites is part of the Delaunay triangulation;
/// the line segment connecting the two Vertices is part of the Voronoi diagram
class Edge {
  // the two input Sites for which this Edge is a bisector:
  OrientedPair<Site<num>> sites;

  Direction direction = Direction.none;

  // the two Voronoi vertices that the edge connects (if one of them is null, the edge extends to infinity)
  OrientedPair<Point<num>?> vertices = OrientedPair<Point<num>?>(null, null);

  OrientedPair<Point<num>?> clippedVertices = OrientedPair<Point<num>?>(null, null);

  /// Whether or not this edge exists in the diagram's bounds (that is, its [clippedVertices] are not both null). This needs to be a field that is updated during clipping rather than a getter, otherwise it'll be needlessly recalculated during every render loop.
  bool isVisible = true;

  /// The equation of the Edge in the form ax + by = c. This form is used instead of y = mx + b because Edges are capable of being arbitrarily steep, which can lead to values of mx which overflow double.maxFinite, causing errors in calculations. By forcing a = 1 for Edges with a slope.abs() > 1 and b = 1 for Edges with a slope.abs <= 1, these overflow errors can be avoided altogether. The slope and intercept (for use in the form y = mx + b) are also provided for convenience, but should not be counted on for calculations except in cases where slope.abs() <= 1 (Edges which are primarily horizontal).
  ({num a, num b, num c, num slope, num intercept}) equation;

  Edge(
      {required this.sites,
      required this.equation,
      OrientedPair<Point<num>?>? vertices,
      OrientedPair<Point<num>?>? clippedVertices,
      this.direction = Direction.none}) {
    this.vertices = vertices ?? OrientedPair<Point<num>?>(null, null);
    this.clippedVertices = clippedVertices ?? OrientedPair<Point<num>?>(null, null);
  }

  Edge copy() => Edge(
      sites: sites, equation: equation, direction: direction, vertices: vertices, clippedVertices: clippedVertices);

  /// Creates a new Edge bisecting two sites.
  factory Edge.createBisectingEdge(OrientedPair<Site<num>> sites) {
    ({num a, num b, num c, num slope, num intercept}) equation;

    final num dx = sites.right.x - sites.left.x;
    final num dy = sites.right.y - sites.left.y;
    final num c = sites.left.x * dx + sites.left.y * dy + (dx * dx + dy * dy) / 2;
    final num slope = -dx / dy;
    final num intercept = c / dy;
    if (dx.abs() > dy.abs()) /* |slope| > 1 */ {
      // b is negative in the angles [0, 45) and (-180, -135), positive in (-45, 0] and [135, 180)
      equation = (a: 1, b: dy / dx, c: c / dx, slope: slope, intercept: intercept);
    } else /* |slope| <= 1 */ {
      // a is negative in the angles [45, 135], positive in [-135, -45]
      equation = (a: dx / dy, b: 1, c: c / dy, slope: slope, intercept: intercept);
    }

    final Edge edge = Edge(sites: OrientedPair<Site<num>>(sites.left, sites.right), equation: equation);

    sites.left.addEdge(edge);
    sites.right.addEdge(edge);

    return edge;
  }

  @override
  String toString() => "Edge(\n"
      "  sites: $sites,\n"
      "  equation: ${equation.a.toStringAsFixed(2)}x + ${equation.b.toStringAsFixed(2)}y = ${equation.c.toStringAsFixed(2)}\n"
      "${equation.slope.isFinite ? "  equation: y = ${equation.slope.toStringAsFixed(2)}x + ${equation.intercept.toStringAsFixed(2)}\n" : ""}"
      "  direction: $direction,\n"
      "  vertices: $vertices,\n"
      "  clippedVertices: $clippedVertices\n"
      ")";

  // draw a line connecting the input Sites for which the edge is a bisector:
  LineSegment<Point<num>> delaunayLine() => LineSegment<Point<num>>.fromOrientedPair(sites);

  // Return a LineSegment representing the edge, or null if the edge isn't visible
  LineSegment<Point<num>>? voronoiEdge() =>
      isVisible ? LineSegment<Point<num>>.fromOrientedPair(clippedVertices as OrientedPair<Point<num>>) : null;

  bool isPartOfConvexHull() => !vertices.isDefined(Direction.both) && clippedVertices.left != clippedVertices.right;

  num sitesDistance() => sites.left.distanceTo(sites.right);

  Point<num>? intersect(Edge edge) {
    if (sites.right == edge.sites.right) {
      return null;
    }

    final num determinant = equation.a * edge.equation.b - equation.b * edge.equation.a;
    if (determinant.abs() < 1E-10) /* The edges are parallel */ {
      return null;
    }

    final Point<num> intersection = Point<num>(
        (equation.c * edge.equation.b - edge.equation.c * equation.b) / determinant,
        (edge.equation.c * equation.a - equation.c * edge.equation.a) / determinant);

    if (intersection.x.isNaN || intersection.y.isNaN) {
      return null;
    }

    final Edge leftEdge = sites.right.compareTo(edge.sites.right) < 0 ? this : edge;

    final bool rightOfSite = intersection.x >= leftEdge.sites.right.x;
    if ((rightOfSite && leftEdge.direction == Direction.left) ||
        (!rightOfSite && leftEdge.direction == Direction.right)) {
      return null;
    }

    return Point<num>(intersection.x, intersection.y);
  }

  /// Set _clippedVertices to contain the two ends of the portion of the Voronoi edge that is visible
  /// within the bounds.  If no part of the Edge falls within the bounds, leave _clippedVertices null.
  void clipVertices(math.Rectangle<num> bounds) {
    Point<num> clipHorizontally(Point<num> point) {
      if (point.x < bounds.left || point.x > bounds.right) {
        final num clippedX = point.x.clamp(bounds.left, bounds.right);
        return Point<num>(clippedX, (equation.c - equation.a * clippedX) / equation.b);
      }
      return point;
    }

    Point<num> clipVertically(Point<num> point) {
      if (point.y < bounds.top || point.y > bounds.bottom) {
        final num clippedY = point.y.clamp(bounds.top, bounds.bottom);
        return Point<num>((equation.c - equation.b * clippedY) / equation.a, clippedY);
      }
      return point;
    }

    // The y value of the null cascade options for these points needs to be multiplied by equation.slope, since the Edge's slope dictates which of the 4 infinite corners the Edge is moving from or towards.
    Point<num> left = vertices.left ?? Point<num>(double.negativeInfinity, equation.slope * double.negativeInfinity);
    Point<num> right = vertices.right ?? Point<num>(double.infinity, equation.slope * double.infinity);

    // Completely clip away edges that start after the bounds or end before the bounds.
    if ((equation.slope < 0 && left.y < bounds.top) ||
        (equation.slope >= 0 && left.y > bounds.bottom) ||
        (equation.slope < 0 && right.y > bounds.bottom) ||
        (equation.slope >= 0 && right.y < bounds.top) ||
        left.x > bounds.right ||
        right.x < bounds.left) {
      isVisible = false;
      return;
    }

    left = clipHorizontally(clipVertically(left));
    right = clipHorizontally(clipVertically(right));

    clippedVertices = OrientedPair<Point<num>>(left, right);
  }
}
