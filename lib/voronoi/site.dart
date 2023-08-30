part of voronoi;

class Site<T extends num> extends Point<T> {
  // the edges that define this Site's Voronoi region:
  List<Edge> _edges = <Edge>[];

  List<Edge> get edges => _edges;

  // which end of each edge hooks up with the previous edge in _edges:
  List<Direction>? _edgeOrientations;

  // ordered list of points that define the region clipped to bounds:
  List<Point<num>>? _region;

  Site(super.x, super.y);

  void addEdge(Edge edge) {
    _edges.add(edge);
  }

  Edge nearestEdge() {
    _edges.sort(Edge.compareSitesDistances);
    return _edges[0];
  }

  List<Site<num>> neighborSites() {
    if (_edges.isEmpty) {
      return <Site<num>>[];
    }
    if (_edgeOrientations == null) {
      reorderEdges();
    }
    final List<Site<num>> list = <Site<num>>[];
    Edge edge;
    for (edge in _edges) {
      if (neighborSite(edge) != null) {
        list.add(neighborSite(edge)!);
      }
    }
    return list;
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
    if (_edges.isEmpty) {
      return <Point<num>>[];
    }
    if (_edgeOrientations == null) {
      reorderEdges();
      _region = clipToBounds(clippingBounds);
      if (Polygon<num>(_region!).winding == Winding.clockwise) {
        _region = List<Point<num>>.from(_region!.reversed);
      }
    }
    return _region!;
  }

  void reorderEdges() {
    final EdgeReorderer<Vertex<num>> reorderer = EdgeReorderer<Vertex<num>>(_edges);
    _edges = reorderer.edges.toList();
    _edgeOrientations = reorderer.edgeOrientations.toList();
  }

  List<Point<num>> clipToBounds(math.Rectangle<num> bounds) {
    final List<Point<num>> points = <Point<num>>[];
    final int n = _edges.length;
    int i = 0;
    Edge edge;
    while (i < n && !_edges[i].visible) {
      ++i;
    }

    if (i == n) {
      // no edges visible
      return <Point<num>>[];
    }
    edge = _edges[i];
    final Direction direction = _edgeOrientations![i];
    points
      ..add(edge.clippedVertices[direction]!)
      ..add(edge.clippedVertices[direction.other]!);

    for (int j = i + 1; j < n; ++j) {
      edge = _edges[j];
      if (!edge.visible) {
        continue;
      }
      connect(points, j, bounds);
    }
    // close up the polygon by adding another corner point of the bounds if needed:
    connect(points, i, bounds, closingUp: true);

    return points;
  }

  void connect(List<Point<num>> points, int j, math.Rectangle<num> bounds, {bool closingUp = false}) {
    final Point<num> rightPoint = points[points.length - 1];
    final Edge newEdge = _edges[j];
    final Direction newOrientation = _edgeOrientations![j];
    // the point that  must be connected to rightPoint:
    final Point<num> newPoint = newEdge.clippedVertices[newOrientation]!;
    if (rightPoint != newPoint) {
      // The points do not coincide, so they must have been clipped at the bounds;
      // see if they are on the same border of the bounds:
      if (rightPoint.x != newPoint.x && rightPoint.y != newPoint.y) {
        // They are on different borders of the bounds;
        // insert one or two corners of bounds as needed to hook them up:
        // (NOTE this will not be correct if the region should take up more than
        // half of the bounds rect, for then we will have gone the wrong way
        // around the bounds and included the smaller part rather than the larger)
        final int rightCheck = BoundsCheck.check(rightPoint, bounds);
        final int newCheck = BoundsCheck.check(newPoint, bounds);
        num px, py;
        if (rightCheck & BoundsCheck.right != 0) {
          px = bounds.right;
          if (newCheck & BoundsCheck.bottom != 0) {
            py = bounds.bottom;
            points.add(Point<num>(px, py));
          } else if (newCheck & BoundsCheck.top != 0) {
            py = bounds.top;
            points.add(Point<num>(px, py));
          } else if (newCheck & BoundsCheck.left != 0) {
            if (rightPoint.y - bounds.top + newPoint.y - bounds.top < bounds.height) {
              py = bounds.top;
            } else {
              py = bounds.bottom;
            }
            points
              ..add(Point<num>(px, py))
              ..add(Point<num>(bounds.left, py));
          }
        } else if (rightCheck & BoundsCheck.left != 0) {
          px = bounds.left;
          if (newCheck & BoundsCheck.bottom != 0) {
            py = bounds.bottom;
            points.add(Point<num>(px, py));
          } else if (newCheck & BoundsCheck.top != 0) {
            py = bounds.top;
            points.add(Point<num>(px, py));
          } else if (newCheck & BoundsCheck.right != 0) {
            if (rightPoint.y - bounds.top + newPoint.y - bounds.top < bounds.height) {
              py = bounds.top;
            } else {
              py = bounds.bottom;
            }
            points
              ..add(Point<num>(px, py))
              ..add(Point<num>(bounds.right, py));
          }
        } else if (rightCheck & BoundsCheck.top != 0) {
          py = bounds.top;
          if (newCheck & BoundsCheck.right != 0) {
            px = bounds.right;
            points.add(Point<num>(px, py));
          } else if (newCheck & BoundsCheck.left != 0) {
            px = bounds.left;
            points.add(Point<num>(px, py));
          } else if (newCheck & BoundsCheck.bottom != 0) {
            if (rightPoint.x - bounds.top + newPoint.x - bounds.top < bounds.width) {
              px = bounds.left;
            } else {
              px = bounds.right;
            }
            points
              ..add(Point<num>(px, py))
              ..add(Point<num>(px, bounds.bottom));
          }
        } else if (rightCheck & BoundsCheck.bottom != 0) {
          py = bounds.bottom;
          if (newCheck & BoundsCheck.right != 0) {
            px = bounds.right;
            points.add(Point<num>(px, py));
          } else if (newCheck & BoundsCheck.left != 0) {
            px = bounds.left;
            points.add(Point<num>(px, py));
          } else if (newCheck & BoundsCheck.top != 0) {
            if (rightPoint.x - bounds.top + newPoint.x - bounds.top < bounds.width) {
              px = bounds.left;
            } else {
              px = bounds.right;
            }
            points
              ..add(Point<num>(px, py))..add(Point<num>(px, bounds.top));
          }
        }
      }
      if (closingUp) {
        // newEdge's ends have already been added
        return;
      }
      points.add(newPoint);
    }
    final Point<num> newRightPoint = newEdge.clippedVertices[newOrientation.other]!;
    if (points[0] != newRightPoint) {
      points.add(newRightPoint);
    }
  }
}

class BoundsCheck {
  static const int top = 1;
  static const int bottom = 2;
  static const int left = 4;
  static const int right = 8;

  ///
  /// @param point
  /// @param bounds
  /// @return an int with the appropriate bits set if the Point lies on the corresponding bounds lines
  ///
  static int check(Point<num> point, math.Rectangle<num> bounds) {
    int value = 0;
    if (point.x == bounds.left) {
      value |= left;
    }
    if (point.x == bounds.right) {
      value |= right;
    }
    if (point.y == bounds.top) {
      value |= top;
    }
    if (point.y == bounds.bottom) {
      value |= bottom;
    }
    return value;
  }

  factory BoundsCheck() {
    //TODO: fix
    throw Error();
  }
}
