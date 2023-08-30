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
import 'dart:math' as math;

part 'geom/circle.dart';
part 'geom/line_segment.dart';
part 'geom/point.dart';
part 'geom/polygon.dart';
part 'geom/triangle.dart';
part 'geom/winding.dart';
part 'voronoi/direction.dart';
part 'voronoi/edge.dart';
part 'voronoi/edge_list.dart';
part 'voronoi/edge_reorderer.dart';
part 'voronoi/half_edge.dart';

part 'voronoi/oriented_pair.dart';

part 'voronoi/site.dart';
part 'voronoi/site_list.dart';
part 'voronoi/vertex.dart';

class BitmapData {}

class Voronoi {
  final SiteList<num> _sites = SiteList<num>();

  List<Site<num>> get sites => _sites.toList();
  final Map<Point<num>, Site<num>> _sitesIndexedByLocation = <Point<num>, Site<num>>{};

  final List<Edge> _edges = <Edge>[];

  List<Edge> get edges => _edges;

  // TODO generalize this so it doesn't have to be a rectangle;
  // then we can make the fractal voronois-within-voronois
  final math.Rectangle<num> _plotBounds;

  math.Rectangle<num> get plotBounds => _plotBounds;

  Voronoi(Iterable<math.Point<num>> points, this._plotBounds) {
    addSites(points.map((math.Point<num> p) => Point<num>(p.x, p.y)));
    fortunesAlgorithm();
  }

  void addSites(Iterable<Point<num>> points) {
    int i = 0;
    for (final Point<num> point in points) {
      addSite(point, i++);
    }
  }

  void addSite(Point<num> p, int index) {
    final math.Random random = math.Random();
    final num weight = random.nextDouble() * 100;
    final Site<num> site = Site<num>(p.x, p.y, weight);
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

  Iterable<LineSegment<Point<num>>> voronoiBoundaryForSite(Point<num> coord) =>
      visibleLineSegments(selectEdgesForSitePoint(coord, _edges));

  Iterable<LineSegment<Point<num>>> delaunayLinesForSite(Point<num> coord) =>
      delaunayLinesForEdges(selectEdgesForSitePoint(coord, _edges));

  Iterable<LineSegment<Point<num>>> voronoiDiagram() => visibleLineSegments(_edges);

  Iterable<LineSegment<Point<num>>> delaunayTriangulation() => delaunayLinesForEdges(_edges);

  Iterable<LineSegment<Point<num>>> hull() => delaunayLinesForEdges(hullEdges());

  Iterable<LineSegment<Point<num>>> delaunayLinesForEdges(Iterable<Edge> edges) =>
      edges.map((Edge edge) => edge.delaunayLine());

  Iterable<Edge> selectEdgesForSitePoint(Point<num> coord, Iterable<Edge> edgesToTest) =>
      edgesToTest.where((Edge edge) => edge.sites.left == coord || edge.sites.right == coord);

  Iterable<LineSegment<Point<num>>> visibleLineSegments(Iterable<Edge> edges) =>
      edges.map((Edge edge) => edge.voronoiEdge()).whereType<LineSegment<Point<num>>>();

  Iterable<Edge> hullEdges() => _edges.where((Edge edge) => edge.isPartOfConvexHull());

  List<Point<num>> hullPointsInOrder() {
    List<Edge> theHullEdges = hullEdges().toList();

    final List<Point<num>> points = <Point<num>>[];
    if (theHullEdges.isEmpty) {
      return points;
    }

    final EdgeReorderer<Site<num>> reorderer = EdgeReorderer<Site<num>>(theHullEdges);
    theHullEdges = reorderer.edges;
    final List<Direction> orientations = reorderer.edgeOrientations;

    Direction direction;

    final int n = theHullEdges.length;
    for (int i = 0; i < n; ++i) {
      final Edge edge = theHullEdges[i];
      direction = orientations[i];

      final Site<num>? site = edge.sites[direction];
      if (site != null) {
        points.add(site);
      }
    }
    return points;
  }

  Iterable<List<Point<num>>> regions() => _sites.regions(_plotBounds);

  void fortunesAlgorithm() {
    Site<num>? newSite, bottomSite, topSite, tempSite;
    Vertex<num>? v, vertex;
    Direction direction;
    HalfEdge lbnd, rbnd, llbnd, rrbnd, bisector;
    Edge edge;

    final math.Rectangle<num> dataBounds = _sites.getSitesBounds();

    final int sqrtNSites = math.sqrt(_sites.length + 4).round();
    final SplayTreeMap<int, HalfEdge> heap = SplayTreeMap<int, HalfEdge>();
    final EdgeList edgeList = EdgeList(dataBounds.left, dataBounds.width, sqrtNSites);
    final List<HalfEdge> halfEdges = <HalfEdge>[];
    final List<Vertex<num>> vertices = <Vertex<num>>[];

    final Site<num>? bottomMostSite = _sites.next();
    newSite = _sites.next();

    Site<num>? leftRegion(HalfEdge he) {
      final Edge? edge = he.edge;
      if (edge == null) {
        return bottomMostSite;
      }
      return edge.sites[he.direction];
    }

    Site<num>? rightRegion(HalfEdge he) {
      final Edge? edge = he.edge;
      if (edge == null) {
        return bottomMostSite;
      }
      return edge.sites[he.direction.other];
    }

    for (;;) {
      if (newSite != null && (heap.isEmpty || newSite.hashCode.compareTo(heap.firstKey()!) < 0)) {
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

        bisector = HalfEdge(edge, Direction.left);
        halfEdges.add(bisector);
        // inserting two Halfedges into edgeList constitutes Step 10:
        // insert bisector to the right of lbnd:
        edgeList.insertToRightOfHalfEdge(lbnd, bisector);

        // first half of Step 11:
        if ((vertex = Vertex.intersect(bisector, lbnd)) != null) {
          vertices.add(vertex!);
          heap.remove(lbnd.sortHash);
          lbnd
            ..vertex = vertex
            ..yStar = vertex.y + newSite.distanceTo(vertex);
          heap[lbnd.sortHash] = lbnd;
        }

        lbnd = bisector;
        bisector = HalfEdge(edge, Direction.right);
        halfEdges.add(bisector);
        // second Halfedge for Step 10:
        // insert bisector to the right of lbnd:
        edgeList.insertToRightOfHalfEdge(lbnd, bisector);

        // second half of Step 11:
        if ((vertex = Vertex.intersect(bisector, rbnd)) != null) {
          vertices.add(vertex!);
          bisector
            ..vertex = vertex
            ..yStar = vertex.y + newSite.distanceTo(vertex);
          heap[bisector.sortHash] = bisector;
        }

        newSite = _sites.next();
      } else if (heap.isNotEmpty) {
        /* intersection is smallest */
        lbnd = heap[heap.firstKey()]!;
        heap.remove(lbnd.sortHash);
        llbnd = lbnd.edgeListLeftNeighbor!;
        rbnd = lbnd.edgeListRightNeighbor!;
        rrbnd = rbnd.edgeListRightNeighbor!;
        bottomSite = leftRegion(lbnd);
        topSite = rightRegion(rbnd);
        // these three sites define a Delaunay triangle
        // (not actually using these for anything...)
        //_triangles.push(new Triangle(bottomSite, topSite, rightRegion(lbnd)));

        v = lbnd.vertex!..setIndex();
        lbnd.edge!.vertices[lbnd.direction] = v;
        rbnd.edge!.vertices[rbnd.direction] = v;
        edgeList.remove(lbnd);
        heap.remove(rbnd.sortHash);
        edgeList.remove(rbnd);
        direction = Direction.left;
        if (bottomSite!.y > topSite!.y) {
          tempSite = bottomSite;
          bottomSite = topSite;
          topSite = tempSite;
          direction = Direction.right;
        }
        edge = Edge.createBisectingEdge(bottomSite, topSite);
        _edges.add(edge);
        bisector = HalfEdge(edge, direction);
        halfEdges.add(bisector);
        edgeList.insertToRightOfHalfEdge(llbnd, bisector);
        edge.vertices[direction.other] = v;
        if ((vertex = Vertex.intersect(llbnd, bisector)) != null) {
          vertices.add(vertex!);
          heap.remove(llbnd.sortHash);
          llbnd
            ..vertex = vertex
            ..yStar = vertex.y + bottomSite.distanceTo(vertex);
          heap[llbnd.sortHash] = llbnd;
        }
        if ((vertex = Vertex.intersect(bisector, rrbnd)) != null) {
          vertices.add(vertex!);
          bisector
            ..vertex = vertex
            ..yStar = vertex.y + bottomSite.distanceTo(vertex);
          heap[bisector.sortHash] = bisector;
        }
      } else {
        break;
      }
    }

    halfEdges.length = 0;

    // we need the vertices to clip the edges
    for (final Edge edge in _edges) {
      edge.clipVertices(_plotBounds);
    }
    vertices.length = 0;
  }
}
