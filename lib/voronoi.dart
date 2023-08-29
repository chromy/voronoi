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

import 'dart:collection';
import 'dart:math';

part 'geom/circle.dart';

part 'geom/line_segment.dart';

part 'geom/polygon.dart';

part 'geom/winding.dart';

part 'voronoi/edge.dart';

part 'voronoi/edge_list.dart';

part 'voronoi/direction.dart';

part 'voronoi/vertex.dart';

part 'voronoi/half_edge.dart';

part 'voronoi/site.dart';

part 'voronoi/site_list.dart';

part 'geom/triangle.dart';

part 'voronoi/edge_reorderer.dart';

part 'voronoi/halfedge_priority_queue.dart';

class BitmapData {}

class Voronoi {
  final SiteList<num> _sites = SiteList<num>();
  List<Site<num>> get sites => _sites.toList();
  final Map<Point<num>, Site<num>> _sitesIndexedByLocation = <Point<num>, Site<num>>{};

  final List<Edge> _edges = <Edge>[];

  List<Edge> get edges => _edges;

  // TODO generalize this so it doesn't have to be a rectangle;
  // then we can make the fractal voronois-within-voronois
  final Rectangle<num> _plotBounds;

  Rectangle<num> get plotBounds => _plotBounds;

  Voronoi(List<Point<num>> points, List<int> colors, this._plotBounds) {
    addSites(points, colors);
    fortunesAlgorithm();
  }

  void addSites(List<Point<num>> points, List<int> colors) {
    final int length = points.length;
    for (int i = 0; i < length; ++i) {
      addSite(points[i], colors.isNotEmpty ? colors[i] : 0, i);
    }
  }

  void addSite(Point<num> p, int color, int index) {
    final Random random = Random();
    final num weight = random.nextDouble() * 100;
    final Site<num> site = Site<num>(p.x, p.y, index, weight, color);
    _sites.add(site);
    _sitesIndexedByLocation[p] = site;
  }

  List<Point<num>> region(Point<num> p) {
    final Site<num>? site = _sitesIndexedByLocation[p];
    if (site == null) {
      return <Point<num>>[];
    }
    return site.region(_plotBounds);
  }

  // TODO: bug: if you call this before you call region(), something goes wrong :(
  List<Point<num>> neighborSitesForSite(Point<num> coord) {
    final List<Point<num>> points = <Point<num>>[];
    final Site<num>? site = _sitesIndexedByLocation[coord];
    if (site == null) {
      return points;
    }
    final List<Site<num>> sites = site.neighborSites();
    Site<num> neighbor;
    for (neighbor in sites) {
      points.add(neighbor);
    }
    return points;
  }

  Iterable<Circle> circles() => _sites.circles();

  Iterable<LineSegment> voronoiBoundaryForSite(Point<num> coord) =>
      visibleLineSegments(selectEdgesForSitePoint(coord, _edges));

  Iterable<LineSegment> delaunayLinesForSite(Point<num> coord) =>
      delaunayLinesForEdges(selectEdgesForSitePoint(coord, _edges));

  Iterable<LineSegment> voronoiDiagram() => visibleLineSegments(_edges);

  Iterable<LineSegment> delaunayTriangulation() => delaunayLinesForEdges(_edges);

  Iterable<LineSegment> hull() => delaunayLinesForEdges(hullEdges());

  Iterable<LineSegment> delaunayLinesForEdges(Iterable<Edge> edges) => edges.map((Edge edge) => edge.delaunayLine());

  Iterable<Edge> selectEdgesForSitePoint(Point<num> coord, Iterable<Edge> edgesToTest) =>
      edgesToTest.where((Edge edge) => edge.leftSite == coord || edge.rightSite == coord);

  Iterable<LineSegment> visibleLineSegments(Iterable<Edge> edges) => edges.map((Edge edge) {
        if (edge.visible) {
          final Point<num> p1 = edge.clippedEnds![Direction.left]!;
          final Point<num> p2 = edge.clippedEnds![Direction.right]!;
          return LineSegment(p1, p2);
        }
      }).whereType<LineSegment>();

  Iterable<Edge> hullEdges() => _edges.where((Edge edge) => edge.isPartOfConvexHull());

  List<Point<num>> hullPointsInOrder() {
    List<Edge> theHullEdges = hullEdges().toList();

    final List<Point<num>> points = <Point<num>>[];
    if (theHullEdges.isEmpty) {
      return points;
    }

    final EdgeReorderer reorderer = EdgeReorderer(theHullEdges, "site");
    theHullEdges = reorderer.edges;
    final List<Direction> orientations = reorderer.edgeOrientations;
    //reorderer.dispose();

    Direction orientation;

    final int n = theHullEdges.length;
    for (int i = 0; i < n; ++i) {
      final Edge edge = theHullEdges[i];
      orientation = orientations[i];
      points.add(edge.site(orientation));
    }
    return points;
  }

  Iterable<List<Point<num>>> regions() => _sites.regions(_plotBounds);

  void fortunesAlgorithm() {
    Site<num>? newSite, bottomSite, topSite, tempSite;
    Vertex<num>? v, vertex;
    Point<num>? newintstar;
    Direction leftRight;
    Halfedge lbnd, rbnd, llbnd, rrbnd, bisector;
    Edge edge;

    final Rectangle<num> dataBounds = _sites.getSitesBounds();

    final int sqrtNSites = sqrt(_sites.length + 4).round();
    final HalfedgePriorityQueue heap = HalfedgePriorityQueue(dataBounds.left, dataBounds.height, sqrtNSites);
    final EdgeList edgeList = EdgeList(dataBounds.left, dataBounds.width, sqrtNSites);
    final List<Halfedge> halfEdges = <Halfedge>[];
    final List<Vertex<num>> vertices = <Vertex<num>>[];

    final Site<num>? bottomMostSite = _sites.next();
    newSite = _sites.next();

    Site<num>? leftRegion(Halfedge he) {
      final Edge? edge = he.edge;
      if (edge == null) {
        return bottomMostSite;
      }
      return edge.site(he.leftRight);
    }

    Site<num>? rightRegion(Halfedge he) {
      final Edge? edge = he.edge;
      if (edge == null) {
        return bottomMostSite;
      }
      return edge.site(he.leftRight?.other);
    }

    for (;;) {
      if (!heap.empty()) {
        newintstar = heap.min();
      }

      if (newSite != null && (heap.empty() || compareByYThenX(newSite, newintstar) < 0)) {
        /* new site is smallest */

        // Step 8:
        lbnd = edgeList.edgeListLeftNeighbor(newSite); // the Halfedge just to the left of newSite
        rbnd = lbnd.edgeListRightNeighbor!; // the Halfedge just to the right
        bottomSite = rightRegion(lbnd); // this is the same as leftRegion(rbnd)
        // this Site determines the region containing the new site

        // Step 9:
        edge = Edge.createBisectingEdge(bottomSite!, newSite);
        //trace("new edge: " + edge);
        _edges.add(edge);

        bisector = Halfedge(edge, Direction.left);
        halfEdges.add(bisector);
        // inserting two Halfedges into edgeList constitutes Step 10:
        // insert bisector to the right of lbnd:
        edgeList.insert(lbnd, bisector);

        // first half of Step 11:
        if ((vertex = Vertex.intersect(bisector, lbnd)) != null) {
          vertices.add(vertex!);
          heap.remove(lbnd);
          lbnd
            ..vertex = vertex
            ..ystar = vertex.y + newSite.distanceTo(vertex);
          heap.insert(lbnd);
        }

        lbnd = bisector;
        bisector = Halfedge(edge, Direction.right);
        halfEdges.add(bisector);
        // second Halfedge for Step 10:
        // insert bisector to the right of lbnd:
        edgeList.insert(lbnd, bisector);

        // second half of Step 11:
        if ((vertex = Vertex.intersect(bisector, rbnd)) != null) {
          vertices.add(vertex!);
          bisector
            ..vertex = vertex
            ..ystar = vertex.y + newSite.distanceTo(vertex);
          heap.insert(bisector);
        }

        newSite = _sites.next();
      } else if (!heap.empty()) {
        /* intersection is smallest */
        lbnd = heap.extractMin();
        llbnd = lbnd.edgeListLeftNeighbor!;
        rbnd = lbnd.edgeListRightNeighbor!;
        rrbnd = rbnd.edgeListRightNeighbor!;
        bottomSite = leftRegion(lbnd);
        topSite = rightRegion(rbnd);
        // these three sites define a Delaunay triangle
        // (not actually using these for anything...)
        //_triangles.push(new Triangle(bottomSite, topSite, rightRegion(lbnd)));

        v = lbnd.vertex!..setIndex();
        lbnd.edge!.setVertex(lbnd.leftRight!, v);
        rbnd.edge!.setVertex(rbnd.leftRight!, v);
        edgeList.remove(lbnd);
        heap.remove(rbnd);
        edgeList.remove(rbnd);
        leftRight = Direction.left;
        if (bottomSite!.y > topSite!.y) {
          tempSite = bottomSite;
          bottomSite = topSite;
          topSite = tempSite;
          leftRight = Direction.right;
        }
        edge = Edge.createBisectingEdge(bottomSite, topSite);
        _edges.add(edge);
        bisector = Halfedge(edge, leftRight);
        halfEdges.add(bisector);
        edgeList.insert(llbnd, bisector);
        edge.setVertex(leftRight.other, v);
        if ((vertex = Vertex.intersect(llbnd, bisector)) != null) {
          vertices.add(vertex!);
          heap.remove(llbnd);
          llbnd
            ..vertex = vertex
            ..ystar = vertex.y + bottomSite.distanceTo(vertex);
          heap.insert(llbnd);
        }
        if ((vertex = Vertex.intersect(bisector, rrbnd)) != null) {
          vertices.add(vertex!);
          bisector
            ..vertex = vertex
            ..ystar = vertex.y + bottomSite.distanceTo(vertex);
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
    for (final Edge edge in _edges) {
      edge.clipVertices(_plotBounds);
    }
    // but we don't actually ever use them again!
    //for (Vertex vertex in vertices) {
    //vertex.dispose();
    //}
    vertices.length = 0;
  }

  static int compareByYThenX(Site<num> s1, Point<num>? s2) {
    if (s2 == null) {
      return 0;
    }
    if (s1.y < s2.y) {
      return -1;
    }
    if (s1.y > s2.y) {
      return 1;
    }
    if (s1.x < s2.x) {
      return -1;
    }
    if (s1.x > s2.x) {
      return 1;
    }
    return 0;
  }
}
