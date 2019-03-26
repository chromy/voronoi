/*
 * The author of this software is Steven Fortune.  Copyright (c) 1994 by AT&T
 * Bell Laboratories.
 * Permission to use, copy, modify, and distribute this software for any
 * purpose without fee is hereby granted, provided that this entire notice
 * is included in all copies of any software which is or includes a copy
 * or modification of this software and in all copies of the supporting
 * documentation for such software.
 * THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY.  IN PARTICULAR, NEITHER THE AUTHORS NOR AT&T MAKE ANY
 * REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY
 * OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
 */

library voronoi;

import 'dart:math';

part 'geom/circle.dart';
part 'geom/line_segment.dart';
part 'geom/polygon.dart';
part 'geom/winding.dart';

part 'voronoi/edge.dart';
part 'voronoi/edge_list.dart';
part 'voronoi/lr.dart';
part 'voronoi/vertex.dart';
part 'voronoi/half_edge.dart';
part 'voronoi/site.dart';
part 'voronoi/site_list.dart';
part 'voronoi/triangle.dart';
part 'voronoi/edge_reorderer.dart';
part 'voronoi/select_non_intersecting_edges.dart';
part 'voronoi/select_edges_for_site_point.dart';
part 'voronoi/delaunay_lines_for_edges.dart';
part 'voronoi/spanning_tree.dart';
part 'voronoi/visible_line_segments.dart';
part 'voronoi/halfedge_priority_queue.dart';

class BitmapData {}

class Voronoi {
  SiteList _sites;
  Map<Point, Site> _sitesIndexedByLocation;

  List<Edge> _edges;
  List<Edge> get edges => _edges;

  // TODO generalize this so it doesn't have to be a rectangle;
  // then we can make the fractal voronois-within-voronois
  Rectangle _plotBounds;
  get plotBounds => _plotBounds;

  Voronoi(List<Point> points, List<int> colors, Rectangle plotBounds) {
    _sites = SiteList();
    _sitesIndexedByLocation = Map();
    addSites(points, colors);
    _plotBounds = plotBounds;
    _edges = List<Edge>();
    fortunesAlgorithm();
  }

  void addSites(List<Point> points, List<int> colors) {
    var length = points.length;
    for (int i = 0; i < length; ++i) {
      addSite(points[i], colors != null ? colors[i] : 0, i);
    }
  }

  void addSite(Point p, int color, int index) {
    Random random = Random();
    num weight = random.nextDouble() * 100;
    Site site = Site(p, index, weight, color);
    _sites.add(site);
    _sitesIndexedByLocation[p] = site;
  }

  List<Point> region(Point p) {
    Site site = _sitesIndexedByLocation[p];
    if (site == null) {
      return [];
    }
    return site.region(_plotBounds);
  }

  // TODO: bug: if you call this before you call region(), something goes wrong :(
  List<Point> neighborSitesForSite(Point coord) {
    List<Point> points = [];
    Site site = _sitesIndexedByLocation[coord];
    if (site == null) {
      return points;
    }
    List<Site> sites = site.neighborSites();
    Site neighbor;
    for (neighbor in sites) {
      points.add(neighbor.coord);
    }
    return points;
  }

  List<Circle> circles() {
    return _sites.circles();
  }

  List<LineSegment> voronoiBoundaryForSite(Point coord) {
    return visibleLineSegments(selectEdgesForSitePoint(coord, _edges));
  }

  List<LineSegment> delaunayLinesForSite(Point coord) {
    return delaunayLinesForEdges(selectEdgesForSitePoint(coord, _edges));
  }

  List<LineSegment> voronoiDiagram() {
    return visibleLineSegments(_edges);
  }

  List<LineSegment> delaunayTriangulation({BitmapData keepOutMask = null}) {
    return delaunayLinesForEdges(
        selectNonIntersectingEdges(keepOutMask, _edges));
  }

  List<LineSegment> hull() {
    return delaunayLinesForEdges(hullEdges());
  }

  List<Edge> hullEdges() {
    bool myTest(Edge edge) {
      return edge.isPartOfConvexHull();
    }

    return _edges.where(myTest);
  }

  List<Point> hullPointsInOrder() {
    List<Edge> theHullEdges = hullEdges();

    List<Point> points = [];
    if (theHullEdges.length == 0) {
      return points;
    }

    EdgeReorderer reorderer = EdgeReorderer(theHullEdges, "site");
    theHullEdges = reorderer.edges;
    List<LR> orientations = reorderer.edgeOrientations;
    //reorderer.dispose();

    LR orientation;

    int n = theHullEdges.length;
    for (int i = 0; i < n; ++i) {
      Edge edge = theHullEdges[i];
      orientation = orientations[i];
      points.add(edge.site(orientation).coord);
    }
    return points;
  }

  // TODO: fix
  /*
  List<LineSegement> spanningTree({String type: "minimum", BitmapData keepOutMask : null}){
    List<Edge> edges = selectNonIntersectingEdges(keepOutMask, _edges);
    List<LineSegment> segments = delaunayLinesForEdges(edges);
    return kruskal(segments, type);
  }
  */

  List<List<Point>> regions() {
    return _sites.regions(_plotBounds);
  }

  // TODO: fix
  //List<int> siteColors({BitmapData referenceImage: null}) {
  //  return _sites.siteColors(referenceImage);
  //}

  // TODO: fix
  /*
  /**
   * 
   * @param proximityMap a BitmapData whose regions are filled with the site index values; see PlanePointsCanvas::fillRegions()
   * @param x
   * @param y
   * @return coordinates of nearest Site to (x, y)
   * 
   */
  Point nearestSitePoint(BitmapData proximityMap, num x, num y) {
    return _sites.nearestSitePoint(proximityMap, x, y);
  }
  */

  List<Point> siteCoords() {
    return _sites.siteCoords();
  }

  void fortunesAlgorithm() {
    Site newSite, bottomSite, topSite, tempSite;
    Vertex v, vertex;
    Point newintstar;
    LR leftRight;
    Halfedge lbnd, rbnd, llbnd, rrbnd, bisector;
    Edge edge;

    Rectangle dataBounds = _sites.getSitesBounds();

    int sqrt_nsites = (sqrt(_sites.length + 4)).round();
    HalfedgePriorityQueue heap =
        HalfedgePriorityQueue(dataBounds.left, dataBounds.height, sqrt_nsites);
    EdgeList edgeList =
        EdgeList(dataBounds.left, dataBounds.width, sqrt_nsites);
    List<Halfedge> halfEdges = [];
    List<Vertex> vertices = [];

    Site bottomMostSite = _sites.next();
    newSite = _sites.next();

    Site leftRegion(Halfedge he) {
      Edge edge = he.edge;
      if (edge == null) {
        return bottomMostSite;
      }
      return edge.site(he.leftRight);
    }

    Site rightRegion(Halfedge he) {
      Edge edge = he.edge;
      if (edge == null) {
        return bottomMostSite;
      }
      return edge.site(he.leftRight.other);
    }

    for (;;) {
      if (!heap.empty()) {
        newintstar = heap.min();
      }

      if (newSite != null &&
          (heap.empty() || compareByYThenX(newSite, newintstar) < 0)) {
        /* new site is smallest */

        // Step 8:
        lbnd = edgeList.edgeListLeftNeighbor(
            newSite.coord); // the Halfedge just to the left of newSite
        rbnd = lbnd.edgeListRightNeighbor; // the Halfedge just to the right
        bottomSite = rightRegion(lbnd); // this is the same as leftRegion(rbnd)
        // this Site determines the region containing the new site

        // Step 9:
        edge = Edge.createBisectingEdge(bottomSite, newSite);
        //trace("new edge: " + edge);
        _edges.add(edge);

        bisector = Halfedge(edge, LR.LEFT);
        halfEdges.add(bisector);
        // inserting two Halfedges into edgeList constitutes Step 10:
        // insert bisector to the right of lbnd:
        edgeList.insert(lbnd, bisector);

        // first half of Step 11:
        if ((vertex = Vertex.intersect(bisector, lbnd)) != null) {
          vertices.add(vertex);
          heap.remove(lbnd);
          lbnd.vertex = vertex;
          lbnd.ystar = vertex.y + newSite.dist(vertex.coord);
          heap.insert(lbnd);
        }

        lbnd = bisector;
        bisector = Halfedge(edge, LR.RIGHT);
        halfEdges.add(bisector);
        // second Halfedge for Step 10:
        // insert bisector to the right of lbnd:
        edgeList.insert(lbnd, bisector);

        // second half of Step 11:
        if ((vertex = Vertex.intersect(bisector, rbnd)) != null) {
          vertices.add(vertex);
          bisector.vertex = vertex;
          bisector.ystar = vertex.y + newSite.dist(vertex.coord);
          heap.insert(bisector);
        }

        newSite = _sites.next();
      } else if (!heap.empty()) {
        /* intersection is smallest */
        lbnd = heap.extractMin();
        llbnd = lbnd.edgeListLeftNeighbor;
        rbnd = lbnd.edgeListRightNeighbor;
        rrbnd = rbnd.edgeListRightNeighbor;
        bottomSite = leftRegion(lbnd);
        topSite = rightRegion(rbnd);
        // these three sites define a Delaunay triangle
        // (not actually using these for anything...)
        //_triangles.push(new Triangle(bottomSite, topSite, rightRegion(lbnd)));

        v = lbnd.vertex;
        v.setIndex();
        lbnd.edge.setVertex(lbnd.leftRight, v);
        rbnd.edge.setVertex(rbnd.leftRight, v);
        edgeList.remove(lbnd);
        heap.remove(rbnd);
        edgeList.remove(rbnd);
        leftRight = LR.LEFT;
        if (bottomSite.y > topSite.y) {
          tempSite = bottomSite;
          bottomSite = topSite;
          topSite = tempSite;
          leftRight = LR.RIGHT;
        }
        edge = Edge.createBisectingEdge(bottomSite, topSite);
        _edges.add(edge);
        bisector = Halfedge(edge, leftRight);
        halfEdges.add(bisector);
        edgeList.insert(llbnd, bisector);
        edge.setVertex(leftRight.other, v);
        if ((vertex = Vertex.intersect(llbnd, bisector)) != null) {
          vertices.add(vertex);
          heap.remove(llbnd);
          llbnd.vertex = vertex;
          llbnd.ystar = vertex.y + bottomSite.dist(vertex.coord);
          heap.insert(llbnd);
        }
        if ((vertex = Vertex.intersect(bisector, rrbnd)) != null) {
          vertices.add(vertex);
          bisector.vertex = vertex;
          bisector.ystar = vertex.y + bottomSite.dist(vertex.coord);
          heap.insert(bisector);
        }
      } else {
        break;
      }
    }

    // heap should be empty now
    //heap.dispose();
    //edgeList.dispose();

    //for (Halfedge halfEdge in halfEdges) {
    //  halfEdge.reallyDispose();
    //}
    halfEdges.length = 0;

    // we need the vertices to clip the edges
    for (Edge edge in _edges) {
      edge.clipVertices(_plotBounds);
    }
    // but we don't actually ever use them again!
    //for (Vertex vertex in vertices) {
    //vertex.dispose();
    //}
    vertices.length = 0;
  }

  static num compareByYThenX(Site s1, var s2) {
    if (s1.y < s2.y) return -1;
    if (s1.y > s2.y) return 1;
    if (s1.x < s2.x) return -1;
    if (s1.x > s2.x) return 1;
    return 0;
  }
}
