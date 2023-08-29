part of voronoi;

class Site {
  static const num EPSILON = 0.005;

  Point _coord;
  Point get coord => _coord;
  num get x => _coord.x;
  num get y => _coord.y;

  int color;
  num weight;

  int _siteIndex;

  // the edges that define this Site's Voronoi region:
  List<Edge> _edges = [];
  List<Edge> get edges => _edges;

  // which end of each edge hooks up with the previous edge in _edges:
  List<LR>? _edgeOrientations;

  // ordered list of points that define the region clipped to bounds:
  List<Point>? _region;

  Site(this._coord, this._siteIndex, this.weight, this.color);

  void addEdge(Edge edge) {
    _edges.add(edge);
  }

  Edge nearestEdge() {
    _edges.sort(Edge.compareSitesDistances);
    return _edges[0];
  }

  List<Site> neighborSites() {
    if (_edges.isEmpty) {
      return [];
    }
    if (_edgeOrientations == null) {
      reorderEdges();
    }
    List<Site> list = [];
    Edge edge;
    for (edge in _edges) {
      if (neighborSite(edge) != null) {
        list.add(neighborSite(edge)!);
      }
    }
    return list;
  }

  Site? neighborSite(Edge edge) {
    if (this == edge.leftSite) {
      return edge.rightSite;
    }
    if (this == edge.rightSite) {
      return edge.leftSite;
    }
    return null;
  }

  List<Point> region(Rectangle clippingBounds) {
    if (_edges.isEmpty) {
      return [];
    }
    if (_edgeOrientations == null) {
      reorderEdges();
      _region = clipToBounds(clippingBounds);
      if (Polygon(_region!).winding == Winding.CLOCKWISE) {
        _region = List.from(_region!.reversed);
      }
    }
    return _region!;
  }

  void reorderEdges() {
    EdgeReorderer reorderer = EdgeReorderer(_edges, "vertex");
    _edges = reorderer.edges;
    _edgeOrientations = reorderer.edgeOrientations;
  }

  List<Point> clipToBounds(Rectangle bounds) {
    List<Point> points = [];
    int n = _edges.length;
    int i = 0;
    Edge edge;
    while (i < n && !_edges[i].visible) {
      ++i;
    }

    if (i == n) {
      // no edges visible
      return [];
    }
    edge = _edges[i];
    LR orientation = _edgeOrientations![i];
    points.add(edge.clippedEnds![orientation]);
    points.add(edge.clippedEnds![orientation.other]);

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

  void connect(List<Point> points, int j, Rectangle bounds,
      {bool closingUp = false}) {
    Point rightPoint = points[points.length - 1];
    Edge newEdge = _edges[j];
    LR newOrientation = _edgeOrientations![j];
    // the point that  must be connected to rightPoint:
    Point newPoint = newEdge.clippedEnds![newOrientation];
    if (!closeEnough(rightPoint, newPoint)) {
      // The points do not coincide, so they must have been clipped at the bounds;
      // see if they are on the same border of the bounds:
      if (rightPoint.x != newPoint.x && rightPoint.y != newPoint.y) {
        // They are on different borders of the bounds;
        // insert one or two corners of bounds as needed to hook them up:
        // (NOTE this will not be correct if the region should take up more than
        // half of the bounds rect, for then we will have gone the wrong way
        // around the bounds and included the smaller part rather than the larger)
        int rightCheck = BoundsCheck.check(rightPoint, bounds);
        int newCheck = BoundsCheck.check(newPoint, bounds);
        num px, py;
        if (rightCheck & BoundsCheck.RIGHT != 0) {
          px = bounds.right;
          if (newCheck & BoundsCheck.BOTTOM != 0) {
            py = bounds.bottom;
            points.add(Point(px, py));
          } else if (newCheck & BoundsCheck.TOP != 0) {
            py = bounds.top;
            points.add(Point(px, py));
          } else if (newCheck & BoundsCheck.LEFT != 0) {
            if (rightPoint.y - bounds.top + newPoint.y - bounds.top <
                bounds.height) {
              py = bounds.top;
            } else {
              py = bounds.bottom;
            }
            points.add(Point(px, py));
            points.add(Point(bounds.left, py));
          }
        } else if (rightCheck & BoundsCheck.LEFT != 0) {
          px = bounds.left;
          if (newCheck & BoundsCheck.BOTTOM != 0) {
            py = bounds.bottom;
            points.add(Point(px, py));
          } else if (newCheck & BoundsCheck.TOP != 0) {
            py = bounds.top;
            points.add(Point(px, py));
          } else if (newCheck & BoundsCheck.RIGHT != 0) {
            if (rightPoint.y - bounds.top + newPoint.y - bounds.top <
                bounds.height) {
              py = bounds.top;
            } else {
              py = bounds.bottom;
            }
            points.add(Point(px, py));
            points.add(Point(bounds.right, py));
          }
        } else if (rightCheck & BoundsCheck.TOP != 0) {
          py = bounds.top;
          if (newCheck & BoundsCheck.RIGHT != 0) {
            px = bounds.right;
            points.add(Point(px, py));
          } else if (newCheck & BoundsCheck.LEFT != 0) {
            px = bounds.left;
            points.add(Point(px, py));
          } else if (newCheck & BoundsCheck.BOTTOM != 0) {
            if (rightPoint.x - bounds.top + newPoint.x - bounds.top <
                bounds.width) {
              px = bounds.left;
            } else {
              px = bounds.right;
            }
            points.add(Point(px, py));
            points.add(Point(px, bounds.bottom));
          }
        } else if (rightCheck & BoundsCheck.BOTTOM != 0) {
          py = bounds.bottom;
          if (newCheck & BoundsCheck.RIGHT != 0) {
            px = bounds.right;
            points.add(Point(px, py));
          } else if (newCheck & BoundsCheck.LEFT != 0) {
            px = bounds.left;
            points.add(Point(px, py));
          } else if (newCheck & BoundsCheck.TOP != 0) {
            if (rightPoint.x - bounds.top + newPoint.x - bounds.top <
                bounds.width) {
              px = bounds.left;
            } else {
              px = bounds.right;
            }
            points.add(Point(px, py));
            points.add(Point(px, bounds.top));
          }
        }
      }
      if (closingUp) {
        // newEdge's ends have already been added
        return;
      }
      points.add(newPoint);
    }
    Point newRightPoint = newEdge.clippedEnds![newOrientation.other];
    if (!closeEnough(points[0], newRightPoint)) {
      points.add(newRightPoint);
    }
  }

  num dist(Point p) {
    return _coord.distanceTo(p);
  }

  static bool closeEnough(Point p0, Point p1) {
    return p0.distanceTo(p1) < EPSILON;
  }

  static void sortSites(List<Site> sites) {
    sites.sort(Site.compare);
  }

  /// sort sites on y, then x, coord
  /// also change each site's _siteIndex to match its new position in the list
  /// so the _siteIndex can be used to identify the site for nearest-neighbor queries
  ///
  /// haha "also" - means more than one responsibility...
  ///
  static int compare(Site s1, Site s2) {
    int returnValue = Voronoi.compareByYThenX(s1, s2);

    // swap _siteIndex values if necessary to match new ordering:
    int tempIndex;
    if (returnValue < 0) {
      if (s1._siteIndex > s2._siteIndex) {
        tempIndex = s1._siteIndex;
        s1._siteIndex = s2._siteIndex;
        s2._siteIndex = tempIndex;
      }
    } else if (returnValue == 1) {
      if (s2._siteIndex > s1._siteIndex) {
        tempIndex = s2._siteIndex;
        s2._siteIndex = s1._siteIndex;
        s1._siteIndex = tempIndex;
      }
    }
    return returnValue;
  }
}

class BoundsCheck {
  static const TOP = 1;
  static const BOTTOM = 2;
  static const LEFT = 4;
  static const RIGHT = 8;

  ///
  /// @param point
  /// @param bounds
  /// @return an int with the appropriate bits set if the Point lies on the corresponding bounds lines
  ///
  static int check(Point point, Rectangle bounds) {
    int value = 0;
    if (point.x == bounds.left) {
      value |= LEFT;
    }
    if (point.x == bounds.right) {
      value |= RIGHT;
    }
    if (point.y == bounds.top) {
      value |= TOP;
    }
    if (point.y == bounds.bottom) {
      value |= BOTTOM;
    }
    return value;
  }

  factory BoundsCheck() {
    //TODO: fix
    throw Error();
  }
}
