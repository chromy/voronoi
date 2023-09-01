part of voronoi;

class Site<T extends num> extends Point<T> {
  // the edges that define this Site's Voronoi region:
  List<Edge> edges = <Edge>[];

  bool isOrdered = false;

  // ordered list of points that define the region clipped to bounds:
  List<Point<num>>? _region;

  Site(super.x, super.y);

  void addEdge(Edge edge) {
    edges.add(edge);
  }

  Edge nearestEdge() => edges
      .reduce((Edge nearestEdge, Edge edge) => edge.sitesDistance() < nearestEdge.sitesDistance() ? edge : nearestEdge);

  Iterable<Site<num>> neighborSites() {
    if (edges.isEmpty) {
      return const Iterable<Site<num>>.empty();
    }

    if (!isOrdered) {
      reorderEdges();
    }

    return edges.map(neighborSite).whereType<Site<num>>();
  }

  Site<num>? neighborSite(Edge edge) {
    if (this == edge.sites.left) {
      return edge.sites.right;
    }

    if (this == edge.sites.right) {
      return edge.sites.left;
    }

    return null;
  }

  List<Point<num>> region(math.Rectangle<num> clippingBounds) {
    if (edges.isEmpty) {
      return <Point<num>>[];
    }

    if (!isOrdered) {
      reorderEdges();
      _region = clipToBounds(clippingBounds);
      if (Polygon<num>(_region!).winding == Winding.clockwise) {
        _region = List<Point<num>>.from(_region!.reversed);
      }
    }

    return _region!;
  }

  void reorderEdges() {
    final EdgeReorderer reorderer = EdgeReorderer(edges, (Edge edge) => edge.vertices as OrientedPair<Point<num>>);
    edges = reorderer.orderedEdges.toList();
    isOrdered = true;
  }

  List<Point<num>> clipToBounds(math.Rectangle<num> bounds) {
    final Edge firstVisibleEdge = edges.firstWhere((Edge edge) => edge.visible);
    final List<Point<num>> points = <Point<num>>[
      firstVisibleEdge.clippedVertices[firstVisibleEdge.direction]!,
      firstVisibleEdge.clippedVertices[firstVisibleEdge.direction.other]!
    ];

    edges
        .where((Edge edge) => edge != firstVisibleEdge)
        .where((Edge edge) => edge.visible)
        .forEach((Edge edge) => connect(points, edge, bounds));

    // close up the polygon by adding another corner point of the bounds if needed:
    connect(points, firstVisibleEdge, bounds, closingUp: true);

    return points;
  }

  void connect(List<Point<num>> points, Edge newEdge, math.Rectangle<num> bounds, {bool closingUp = false}) {
    final Point<num> rightPoint = points.last;
    // the point that must be connected to rightPoint:
    final Point<num> newPoint = newEdge.clippedVertices[newEdge.direction]!;
    if (rightPoint != newPoint) {
      // The points do not coincide, so they must have been clipped at the bounds;
      // see if they are on the same border of the bounds:
      if (rightPoint.x != newPoint.x && rightPoint.y != newPoint.y) {
        // They are on different borders of the bounds;
        // insert one or two corners of bounds as needed to hook them up:
        // (NOTE this will not be correct if the region should take up more than
        // half of the bounds rect, for then we will have gone the wrong way
        // around the bounds and included the smaller part rather than the larger)
        final BoundsCheck rightCheck = BoundsCheck(rightPoint, bounds);
        final BoundsCheck newCheck = BoundsCheck(newPoint, bounds);

        if (rightCheck.right) {
          if (newCheck.bottom) {
            points.add(Point<num>(bounds.right, bounds.bottom));
          } else if (newCheck.top) {
            points.add(Point<num>(bounds.right, bounds.top));
          } else if (newCheck.left) {
            if (rightPoint.y - bounds.top + newPoint.y - bounds.top < bounds.height) {
              points
                ..add(Point<num>(bounds.right, bounds.top))
                ..add(Point<num>(bounds.left, bounds.top));
            } else {
              points
                ..add(Point<num>(bounds.right, bounds.bottom))
                ..add(Point<num>(bounds.left, bounds.bottom));
            }
          }
        } else if (rightCheck.left) {
          if (newCheck.bottom) {
            points.add(Point<num>(bounds.left, bounds.bottom));
          } else if (newCheck.top) {
            points.add(Point<num>(bounds.left, bounds.top));
          } else if (newCheck.right) {
            if (rightPoint.y - bounds.top + newPoint.y - bounds.top < bounds.height) {
              points
                ..add(Point<num>(bounds.left, bounds.top))
                ..add(Point<num>(bounds.right, bounds.top));
            } else {
              points
                ..add(Point<num>(bounds.left, bounds.bottom))
                ..add(Point<num>(bounds.right, bounds.bottom));
            }
          }
        } else if (rightCheck.top) {
          if (newCheck.right) {
            points.add(Point<num>(bounds.right, bounds.top));
          } else if (newCheck.left) {
            points.add(Point<num>(bounds.left, bounds.top));
          } else if (newCheck.bottom) {
            if (rightPoint.x - bounds.top + newPoint.x - bounds.top < bounds.width) {
              points
                ..add(Point<num>(bounds.left, bounds.top))
                ..add(Point<num>(bounds.left, bounds.bottom));
            } else {
              points
                ..add(Point<num>(bounds.right, bounds.top))
                ..add(Point<num>(bounds.right, bounds.bottom));
            }
          }
        } else if (rightCheck.bottom) {
          if (newCheck.right) {
            points.add(Point<num>(bounds.right, bounds.bottom));
          } else if (newCheck.left) {
            points.add(Point<num>(bounds.left, bounds.bottom));
          } else if (newCheck.top) {
            if (rightPoint.x - bounds.top + newPoint.x - bounds.top < bounds.width) {
              points
                ..add(Point<num>(bounds.left, bounds.bottom))
                ..add(Point<num>(bounds.left, bounds.top));
            } else {
              points
                ..add(Point<num>(bounds.right, bounds.bottom))
                ..add(Point<num>(bounds.right, bounds.top));
            }
          }
        }
      }
      if (closingUp) {
        // newEdge's ends have already been added
        return;
      }
      points.add(newPoint);
    }
    final Point<num> newRightPoint = newEdge.clippedVertices[newEdge.direction.other]!;
    if (points[0] != newRightPoint) {
      points.add(newRightPoint);
    }
  }
}

class BoundsCheck {
  late bool bottom;
  late bool left;
  late bool right;
  late bool top;

  BoundsCheck(Point<num> point, math.Rectangle<num> bounds) {
    bottom = point.y == bounds.bottom;
    left = point.x == bounds.left;
    right = point.x == bounds.right;
    top = point.y == bounds.top;
  }
}
